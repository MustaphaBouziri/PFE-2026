"""
agent/composite.py — Composite and fan-out query handling.

Composite questions are queries that require data about MULTIPLE machines
or that ask for data across machines and then filter/correlate it.

Examples
────────
"Which machines are running right now?"
    → list_machines fan-out, filter status=Working

"Which machines are running and what orders are they on?"
    → list_machines fan-out → filter Working → get_machine_orders for each

"Which machines have overdue orders?"
    → list_machines fan-out → get_machine_orders for each → filter overdue

"Show me scrap and live data for all machines in WC 100"
    → list_machines(wc=100) → get_ongoing_operations for each

"What is the production status of all active machines?"
    → list_machines fan-out → filter Working → get_ongoing_operations for each

Detection
─────────
Composite intent is detected in intent.py by looking for:
  - "all machines", "every machine", "each machine"
  - "which machines" + filter verb (running, idle, working, overdue, scrap)
  - "machines that are …"
  - plural machine references with a status / data qualifier

The orchestrator calls `run_composite()` instead of the normal chain loop when
chain.is_composite=True.

Fan-out cap
───────────
To avoid hammering BC with 50 simultaneous requests, we cap the per-machine
fan-out at MAX_FANOUT_MACHINES.  Machines are sorted: Working first, then
by machineNo.  The LLM is told if results were capped.

Async concurrency
─────────────────
Per-machine calls are fired with asyncio.gather() in batches of BATCH_SIZE
to stay within the middleware's rate limit.
"""
from __future__ import annotations

import asyncio
import logging
import re
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple

from agent.data_analysis import enrich_deadlines, summarise_machines, analyse_scrap
from agent.models import ToolResult

logger = logging.getLogger("mes-ai.composite")

MAX_FANOUT_MACHINES = 12   # never fan-out to more than this many machines
BATCH_SIZE          = 4    # concurrent requests per batch


# ── Composite intent detection ────────────────────────────────────────────────

# Patterns that suggest the user wants data about MULTIPLE machines
_ALL_MACHINES_RE = re.compile(
    r'\b(all|every|each|any)\s+(machine|center|station|mc|the\s+machine)\b'
    r'|\ball\s+(the\s+)?machines\b'           # "all machines", "all the machines"
    r'|\bwhat\s+are\s+all\b'                  # "what are all the machines doing"
    r'|which\s+machine'
    r'|\bmachines\s+(that|which|are|with|have)\b'
    r'|\bmachines\b.{0,30}\b(running|working|idle|active|scrap|overdue|order)\b',
    re.I,
)

# Filter intent: what the user wants to do with the list
_FILTER_RUNNING  = re.compile(r'\b(running|working|active|busy|in.?progress)\b', re.I)
_FILTER_IDLE     = re.compile(r'\b(idle|stopped|free|not.?running|not.?working)\b', re.I)
_FILTER_OVERDUE  = re.compile(r'\b(overdue|late|behind.?schedule|delayed)\b', re.I)
_FILTER_SCRAP    = re.compile(r'\b(scrap|reject|defect|quality.?issue)\b', re.I)

# Cross-data intent: user wants machine status PLUS something else
_WANT_ORDERS     = re.compile(r'\b(order|queue|job|what.?running|what.?producing)\b', re.I)
_WANT_LIVE       = re.compile(r'\b(live|progress|percent|how.?far|produced)\b', re.I)


def is_composite(message: str) -> bool:
    """Return True if the message looks like a composite / multi-machine query."""
    return bool(_ALL_MACHINES_RE.search(message))


@dataclass
class CompositeResult:
    """Holds all data gathered by a composite query run."""
    machines:          List[Dict[str, Any]] = field(default_factory=list)
    machine_summary:   Dict[str, Any]       = field(default_factory=dict)
    per_machine:       Dict[str, Any]       = field(default_factory=dict)  # machineNo → data
    filters_applied:   List[str]            = field(default_factory=list)
    capped:            bool = False
    cap_count:         int  = 0
    description:       str  = ""


# ── Main composite runner ─────────────────────────────────────────────────────

async def run_composite(
    message: str,
    machines: List[Dict[str, Any]],     # already fetched + access-filtered
    token: str,
    work_centers: List[str],
) -> CompositeResult:
    """
    Given an already-fetched, access-filtered machine list, determine what
    additional per-machine data to fetch, fetch it in batches, and return
    a CompositeResult.
    """
    from tools.mes_tools import TOOL_MAP   # avoid circular import at module level

    result = CompositeResult()
    result.machines = machines

    summary = summarise_machines(machines)
    result.machine_summary = summary

    # ── Determine filter ──────────────────────────────────────────────────────
    want_running = bool(_FILTER_RUNNING.search(message))
    want_idle    = bool(_FILTER_IDLE.search(message))
    want_overdue = bool(_FILTER_OVERDUE.search(message))
    want_scrap   = bool(_FILTER_SCRAP.search(message))
    want_orders  = bool(_WANT_ORDERS.search(message))
    want_live    = bool(_WANT_LIVE.search(message))

    # Determine the filtered working set
    if want_running:
        working_set = [m for m in machines if (m.get("status") or "").lower() == "working"]
        result.filters_applied.append("status=Working")
    elif want_idle:
        working_set = [m for m in machines if (m.get("status") or "").lower() != "working"]
        result.filters_applied.append("status=Idle")
    else:
        working_set = machines

    if not working_set:
        result.description = (
            f"No machines match the filter ({', '.join(result.filters_applied) or 'none'})."
        )
        return result

    # Cap and sort: Working first, then alphabetically by machineNo
    working_set.sort(key=lambda m: (
        0 if (m.get("status") or "").lower() == "working" else 1,
        m.get("machineNo") or "",
    ))
    if len(working_set) > MAX_FANOUT_MACHINES:
        result.capped    = True
        result.cap_count = len(working_set)
        working_set      = working_set[:MAX_FANOUT_MACHINES]

    # ── Decide what per-machine tool to call ──────────────────────────────────
    #
    # Priority:
    #   1. If user wants live progress    → get_ongoing_operations
    #   2. If user wants orders / jobs    → get_machine_orders  (includes overdue check)
    #   3. If user wants overdue check    → get_machine_orders
    #   4. If user wants scrap            → get_ongoing_operations (has scrap qty)
    #   5. Default (just "which running") → no per-machine call, use machine list
    #
    per_machine_tool: Optional[str] = None
    if want_live:
        per_machine_tool = "get_ongoing_operations"
        result.filters_applied.append("data=live_operations")
    elif want_orders or want_overdue:
        per_machine_tool = "get_machine_orders"
        result.filters_applied.append("data=orders")
    elif want_scrap:
        per_machine_tool = "get_ongoing_operations"
        result.filters_applied.append("data=ongoing_ops_for_scrap")

    result.description = (
        f"Composite query over {len(working_set)} machine(s)"
        + (f" (capped from {result.cap_count})" if result.capped else "")
        + (f" — filters: {', '.join(result.filters_applied)}" if result.filters_applied else "")
    )

    if per_machine_tool is None:
        # No per-machine data needed — the machine list + summary is enough
        return result

    # ── Fan-out in batches ────────────────────────────────────────────────────
    tool = TOOL_MAP[per_machine_tool]
    machine_nos = [m.get("machineNo") or m.get("no") or "" for m in working_set]

    for batch_start in range(0, len(machine_nos), BATCH_SIZE):
        batch = machine_nos[batch_start : batch_start + BATCH_SIZE]
        tasks = [
            tool.execute(machine_no=mno, token=token)
            for mno in batch
            if mno
        ]
        if not tasks:
            continue
        batch_results: List[ToolResult] = await asyncio.gather(*tasks, return_exceptions=False)

        for mno, tr in zip(batch, batch_results):
            if tr.success and tr.data is not None:
                result.per_machine[mno] = tr.data

    # ── Post-process per-machine data ─────────────────────────────────────────
    if per_machine_tool == "get_machine_orders" and want_overdue:
        # Run deadline enrichment on each machine's orders and flag overdue ones
        enriched_per_machine: Dict[str, Any] = {}
        for mno, orders in result.per_machine.items():
            if isinstance(orders, list):
                enriched = enrich_deadlines(orders)
                enriched_per_machine[mno] = enriched
                # Attach overdue flag to the machine entry
                for m in result.machines:
                    if (m.get("machineNo") or "") == mno:
                        m["overdue_orders"] = enriched["summary"]["overdue_orders"]
                        m["at_risk_orders"] = enriched["summary"]["at_risk_orders"]
                        m["has_overdue"]    = enriched["summary"]["overdue_count"] > 0
        result.per_machine = enriched_per_machine

    elif per_machine_tool == "get_ongoing_operations" and want_scrap:
        # Annotate machines with scrap info from their ongoing operations
        for mno, ops in result.per_machine.items():
            if isinstance(ops, list):
                for op in ops:
                    scrap = float(op.get("scrapQuantity") or 0)
                    prod  = float(op.get("totalProducedQuantity") or 0)
                    denom = scrap + prod
                    if denom > 0:
                        op["scrap_rate"] = round(scrap / denom, 4)
                for m in result.machines:
                    if (m.get("machineNo") or "") == mno:
                        total_scrap = sum(float(op.get("scrapQuantity") or 0) for op in ops)
                        m["total_scrap_current_ops"] = total_scrap

    return result


# ── Context builder for composite results ────────────────────────────────────

def build_composite_context(result: CompositeResult) -> str:
    """
    Build the LLM context block for a composite result.
    Keeps it compact: summary first, then per-machine details.
    """
    import json

    lines = [
        f"## Composite query result",
        f"**{result.description}**",
        "",
        "### Fleet overview",
        f"```json",
        json.dumps(result.machine_summary, default=str, ensure_ascii=False),
        "```",
        "",
    ]

    if result.capped:
        lines.append(
            f"⚠ Results capped at {MAX_FANOUT_MACHINES} machines "
            f"(total matching: {result.cap_count})."
        )
        lines.append("")

    # Machine list (compact — status, order, overdue flags)
    compact_machines = []
    for m in result.machines:
        cm: Dict[str, Any] = {
            "machineNo": m.get("machineNo"),
            "name":      m.get("machineName") or m.get("name"),
            "status":    m.get("status"),
            "wc":        m.get("workCenterNo"),
        }
        if m.get("currentOrder"):
            cm["currentOrder"] = m["currentOrder"]
        if m.get("has_overdue"):
            cm["⚠ overdueOrders"] = m.get("overdue_orders")
        if m.get("total_scrap_current_ops"):
            cm["currentScrap"] = m["total_scrap_current_ops"]
        compact_machines.append(cm)

    lines += [
        "### Machines",
        "```json",
        json.dumps(compact_machines, default=str, ensure_ascii=False),
        "```",
        "",
    ]

    # Per-machine detail (truncated per machine to keep context manageable)
    if result.per_machine:
        lines.append("### Per-machine details")
        for mno, data in result.per_machine.items():
            snippet = json.dumps(data, default=str, ensure_ascii=False)
            if len(snippet) > 800:
                snippet = snippet[:800] + "…"
            lines += [f"**{mno}:**", f"```json", snippet, "```", ""]

    return "\n".join(lines)
