"""
agent/intent.py — Deterministic intent classification and tool-chain planning.

Design goal: ZERO LLM calls for tool selection.

The LLM is good at natural language but poor at consistently choosing which
tools to fire and in what order — that's a program's job.  We classify the
user's message with rules, then emit a pre-defined ToolChain describing
exactly which tool calls to make and with what argument sources.

A ToolChain is a list of ToolStep objects.  Each step may depend on the
output of a previous step (via a slot reference like "$machines[0].machineNo").
The executor resolves those slots at runtime.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional


class Intent(str, Enum):
    # Machine-level
    MACHINE_STATUS       = "machine_status"       # "what is MC-001 doing?"
    MACHINE_ORDERS       = "machine_orders"        # "what orders are on MC-001?"
    MACHINE_LIVE         = "machine_live"          # "live data / progress / scrap for MC-001"
    MACHINE_HISTORY      = "machine_history"       # "what did MC-001 finish today?"
    MACHINE_DASHBOARD    = "machine_dashboard"     # "show me machine KPIs / uptime"

    # Department-level
    DEPARTMENT_OVERVIEW  = "department_overview"   # "how is my department doing?"
    ACTIVITY_LOG         = "activity_log"          # "what happened in the last hour?"
    SCRAP_ANALYSIS       = "scrap_analysis"        # "where is scrap coming from?"

    # Operation-level
    OPERATION_LIVE       = "operation_live"        # "live data for order PO-001 op 10"
    OPERATION_BOM        = "operation_bom"         # "BOM / components for order …"
    PRODUCTION_CYCLES    = "production_cycles"     # "production cycles / declarations"

    # Generic
    GENERAL              = "general"               # fallback — fetch nothing, LLM answers


@dataclass
class ToolStep:
    """A single tool invocation in a chain."""
    tool: str                           # tool name from TOOL_MAP
    args: Dict[str, Any]                # static args (may contain slot refs like "$wc")
    result_key: str = ""                # key under which to store this result
    # If True, fire one call per work-center and merge results
    fan_out_work_centers: bool = False


@dataclass
class ToolChain:
    intent: Intent
    steps: List[ToolStep] = field(default_factory=list)
    # Human-readable description for the LLM context header
    description: str = ""
    # True if the message references multiple machines (composite executor used)
    is_composite: bool = False
    # Raw machine reference that needs name→ID resolution before execution
    # (set when the user referenced a machine by name / fuzzy ID, not canonical MC-NNN)
    unresolved_machine_ref: Optional[str] = None


# ── Slot reference syntax ─────────────────────────────────────────────────────
#
# Static args can reference prior results with "$<result_key>.<jsonpath>".
# The executor replaces these before calling the tool.  We keep it simple:
# only top-level keys and indexed arrays are supported.
#
# Examples:
#   "$machines[0].machineNo"   → results["machines"][0]["machineNo"]
#   "$ongoing[0].prodOrderNo"  → results["ongoing"][0]["prodOrderNo"]
#   "$ongoing[0].operationNo"  → results["ongoing"][0]["operationNo"]
#   "$ongoing[0].executionId"  → results["ongoing"][0]["executionId"]

SLOT_RE = re.compile(r'\$([a-zA-Z_]+)(?:\[(\d+)\])?\.([a-zA-Z_]+)')


def resolve_slot(ref: str, results: Dict[str, Any]) -> Any:
    """Resolve a single slot reference against accumulated results."""
    m = SLOT_RE.fullmatch(ref)
    if not m:
        return ref
    key, idx, attr = m.group(1), m.group(2), m.group(3)
    value = results.get(key)
    if value is None:
        return None
    if idx is not None:
        try:
            value = value[int(idx)]
        except (IndexError, TypeError):
            return None
    if isinstance(value, dict):
        return value.get(attr)
    return None


def resolve_args(args: Dict[str, Any], results: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively resolve slot references in an args dict."""
    out: Dict[str, Any] = {}
    for k, v in args.items():
        if isinstance(v, str) and v.startswith("$"):
            out[k] = resolve_slot(v, results)
        elif isinstance(v, list):
            out[k] = [resolve_slot(i, results) if isinstance(i, str) and i.startswith("$") else i for i in v]
        else:
            out[k] = v
    return out


# ── Keyword patterns ──────────────────────────────────────────────────────────

_MACHINE_MENTION = re.compile(
    r'\b(machine|mc[-\s]?\d+|center|station)\b', re.I
)
_ORDER_MENTION = re.compile(
    r'\borders?\b|po[-\s]?\d+|prod\.?\s*order|queued', re.I
)
_LIVE_KEYWORDS = re.compile(
    r'\b(live|real.?time|progress|scrap|produced|current(ly)?|now|running|active|ongoing)\b', re.I
)
_HISTORY_KEYWORDS = re.compile(
    r'\b(history|finished|finish|complet|done|past|yesterday)\b|last\s+(shift|day|hour|week)', re.I
)
_DASHBOARD_KEYWORDS = re.compile(
    r'\b(dashboard|kpi|uptime|utiliz|overview|summary|stats|efficiency)\b', re.I
)
_DEPT_KEYWORDS = re.compile(
    r'\b(department|dept|all machines|my machines|work.?center|floor|plant)\b', re.I
)
_ACTIVITY_KEYWORDS = re.compile(
    r'\b(activity|log|event|happened|recent|last hour|alert|notification)\b', re.I
)
_SCRAP_KEYWORDS = re.compile(
    r'\b(scrap|reject|defect|waste|quality|spike|anomal)\b', re.I
)
_BOM_KEYWORDS = re.compile(
    r'\b(bom|bill of material|component|part|material|ingredient|consum)\b', re.I
)
_CYCLE_KEYWORDS = re.compile(
    r'(cycle|declar|who.?produc|shift.?produc)', re.I
)


def _extract_machine_no(text: str) -> Optional[str]:
    """
    Try to pull a canonical machine number (MC-NNN) from the message.
    Returns None if nothing resembling an ID is found — the caller will
    then check _extract_machine_ref() for a name-based reference.
    """
    m = re.search(r'\bMC[-\s]?(\d+)\b', text, re.I)
    if m:
        return f"MC-{m.group(1).zfill(3)}"
    return None


def _extract_machine_ref(text: str) -> Optional[str]:
    """
    Extract a non-canonical machine reference that needs fuzzy resolution:
      - bare numbers:          "machine 42", "station 5", "center 3"
      - names:                 "Fraiseuse 3", "milling machine", "lathe"
      - work-center scoped:    "machine in WC 100"
    Returns the raw phrase (not normalised) so the resolver can compare
    it against the full machine catalogue.
    """
    # "machine 42" / "station 5" / "center 3" — bare-number references
    m = re.search(r'\b(?:machine|station|center|mc)\s+(\d+)\b', text, re.I)
    if m:
        return m.group(0).strip()

    # A word + digits pattern that isn't a production order (avoids PO-001 false positives)
    # e.g. "Fraiseuse 3", "Tour 12", "Presse 001"
    m = re.search(
        r'\b(?!(?:po|op|wc|last|next)[-\s])([A-Za-zÀ-ÿ]{3,})[-\s]+(\d{1,4})\b',
        text, re.I
    )
    if m and not re.match(r'(hour|day|week|minute|shift)', m.group(1), re.I):
        return m.group(0).strip()

    # A quoted name: "Fraiseuse numéro 3" → strip quotes
    m = re.search(r'[\"\'](.*?)[\"\']', text)
    if m:
        return m.group(1).strip()

    return None


def _extract_order_no(text: str) -> Optional[str]:
    """Try to pull a production order number like PO-00123."""
    m = re.search(r'\b(PO[-\s]?\d+|P\d{5,})\b', text, re.I)
    if m:
        return m.group(0).replace(" ", "-").upper()
    return None


def _extract_hours(text: str, default: float = 8.0) -> float:
    """Extract 'last N hours/days' from text."""
    m = re.search(r'last\s+(\d+)\s+(hour|hr|day|week)', text, re.I)
    if not m:
        return default
    n = int(m.group(1))
    unit = m.group(2).lower()
    if unit.startswith("day"):
        return n * 24.0
    if unit.startswith("week"):
        return n * 168.0
    return float(n)


def _extract_op_no(text: str) -> Optional[str]:
    """Try to pull an operation number like 'op 10' or 'operation 20'."""
    m = re.search(r'\bop(?:eration)?\s*(\d+)\b', text, re.I)
    if m:
        return m.group(1)
    return None


# ── Main classifier ───────────────────────────────────────────────────────────

def classify(message: str, work_centers: List[str]) -> ToolChain:
    """
    Return a ToolChain for the given message.

    Rules are checked in priority order — most specific first.
    No LLM call is made here.

    Composite questions ("which machines are running?") are flagged with
    is_composite=True and routed to the composite executor.

    Name-based machine references ("Fraiseuse 3", "milling machine") are
    flagged with unresolved_machine_ref=<raw phrase> so the orchestrator
    can run the resolver before executing the tool chain.
    """
    # ── Composite detection (must come before single-machine rules) ───────────
    from agent.composite import is_composite as _is_composite
    if _is_composite(message):
        return ToolChain(
            intent=Intent.DEPARTMENT_OVERVIEW,
            description=f"Composite multi-machine query",
            is_composite=True,
            steps=[ToolStep("list_machines", {}, "machines", fan_out_work_centers=True)],
        )

    t = message.lower()
    machine_no  = _extract_machine_no(message)
    machine_ref = None if machine_no else _extract_machine_ref(message)
    order_no    = _extract_order_no(message)
    op_no       = _extract_op_no(message)
    hours       = _extract_hours(message)

    # If we have a name/fuzzy ref but no canonical ID, set unresolved flag.
    # The orchestrator will resolve it to a machineNo before running steps.
    # For the purpose of chain-building, treat it as if machine_no were set.
    effective_machine_no = machine_no or (machine_ref and "__RESOLVE__") or None

    has_machine  = bool(effective_machine_no or _MACHINE_MENTION.search(t))
    has_order    = bool(order_no or _ORDER_MENTION.search(t))
    has_live     = bool(_LIVE_KEYWORDS.search(t))
    has_history  = bool(_HISTORY_KEYWORDS.search(t))
    has_dash     = bool(_DASHBOARD_KEYWORDS.search(t))
    has_dept     = bool(_DEPT_KEYWORDS.search(t))
    has_activity = bool(_ACTIVITY_KEYWORDS.search(t))
    has_scrap    = bool(_SCRAP_KEYWORDS.search(t))
    has_bom      = bool(_BOM_KEYWORDS.search(t))
    has_cycles   = bool(_CYCLE_KEYWORDS.search(t))

    # Placeholder used in ToolStep args when the real ID needs resolution
    _MNO = machine_no or "__RESOLVE__"

    # ── BOM / components ──────────────────────────────────────────────────────
    if has_bom and (has_order or has_machine):
        if order_no and op_no:
            return ToolChain(
                intent=Intent.OPERATION_BOM,
                description=f"Bill of materials for order {order_no} op {op_no}",
                steps=[ToolStep("get_bom", {"prod_order_no": order_no, "operation_no": op_no}, "bom")],
            )
        if effective_machine_no:
            # Need to find the active order first
            return ToolChain(
                intent=Intent.OPERATION_BOM,
                description=f"BOM for current operation on {machine_no}",
                steps=[
                    ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing"),
                    ToolStep("get_bom", {
                        "prod_order_no": "$ongoing[0].prodOrderNo",
                        "operation_no":  "$ongoing[0].operationNo",
                    }, "bom"),
                ],
            )

    # ── Production cycles / declarations ──────────────────────────────────────
    if has_cycles and has_machine:
        if effective_machine_no:
            if order_no and op_no:
                return ToolChain(
                    intent=Intent.PRODUCTION_CYCLES,
                    description=f"Production cycles for {machine_no} order {order_no}",
                    steps=[
                        ToolStep("get_production_cycles", {
                            "machine_no": _MNO,
                            "prod_order_no": order_no,
                            "operation_no": op_no or "10",
                        }, "cycles"),
                    ],
                )
            return ToolChain(
                intent=Intent.PRODUCTION_CYCLES,
                description=f"Production cycles for current operation on {machine_no}",
                steps=[
                    ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing"),
                    ToolStep("get_production_cycles", {
                        "machine_no":     machine_no,
                        "prod_order_no":  "$ongoing[0].prodOrderNo",
                        "operation_no":   "$ongoing[0].operationNo",
                    }, "cycles"),
                ],
            )

    # ── Live operation data ───────────────────────────────────────────────────
    if has_live and has_machine and effective_machine_no:
        steps = [ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing")]
        if has_cycles or has_scrap:
            # Also fetch cycles for velocity/scrap analysis
            steps.append(ToolStep("get_operation_live_data", {
                "machine_no":    _MNO,
                "prod_order_no": "$ongoing[0].prodOrderNo",
                "operation_no":  "$ongoing[0].operationNo",
            }, "live_data"))
            steps.append(ToolStep("get_production_cycles", {
                "machine_no":    _MNO,
                "prod_order_no": "$ongoing[0].prodOrderNo",
                "operation_no":  "$ongoing[0].operationNo",
            }, "cycles"))
        else:
            steps.append(ToolStep("get_operation_live_data", {
                "machine_no":    _MNO,
                "prod_order_no": "$ongoing[0].prodOrderNo",
                "operation_no":  "$ongoing[0].operationNo",
            }, "live_data"))
        return ToolChain(
            intent=Intent.MACHINE_LIVE,
            description=f"Live operation data for {machine_no}",
            steps=steps,
            unresolved_machine_ref=machine_ref,
        )

    # ── Machine history ───────────────────────────────────────────────────────
    if has_history and effective_machine_no:
        return ToolChain(
            intent=Intent.MACHINE_HISTORY,
            description=f"Operation history for {machine_no}",
            steps=[ToolStep("get_operations_history", {"machine_no": _MNO}, "history")],
            unresolved_machine_ref=machine_ref,
        )

    # ── Production cycles (declarations / who produced what) ─────────────────
    if has_cycles and effective_machine_no:
        if order_no and op_no:
            return ToolChain(
                intent=Intent.PRODUCTION_CYCLES,
                description=f"Production cycles for {machine_no} order {order_no}",
                steps=[ToolStep("get_production_cycles", {
                    "machine_no": _MNO, "prod_order_no": order_no, "operation_no": op_no,
                }, "cycles")],
            )
        return ToolChain(
            intent=Intent.PRODUCTION_CYCLES,
            description=f"Production cycles for current operation on {machine_no}",
            steps=[
                ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing"),
                ToolStep("get_production_cycles", {
                    "machine_no": _MNO,
                    "prod_order_no": "$ongoing[0].prodOrderNo",
                    "operation_no": "$ongoing[0].operationNo",
                }, "cycles"),
            ],
            unresolved_machine_ref=machine_ref,
        )

    # ── Machine orders (queue) ────────────────────────────────────────────────
    if (has_order or _ORDER_MENTION.search(t)) and effective_machine_no and not has_live:
        return ToolChain(
            intent=Intent.MACHINE_ORDERS,
            description=f"Production order queue for {machine_no}",
            steps=[ToolStep("get_machine_orders", {"machine_no": _MNO}, "orders")],
            unresolved_machine_ref=machine_ref,
        )

    # ── Machine-level KPI / dashboard ────────────────────────────────────────
    if effective_machine_no and has_dash:
        return ToolChain(
            intent=Intent.MACHINE_DASHBOARD,
            description=f"KPI / dashboard for {machine_no} over last {hours:.0f}h",
            steps=[
                ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing"),
                ToolStep("get_machine_dashboard", {
                    "hours_back": hours,
                    "work_center_nos": work_centers if work_centers else [],
                }, "dashboard"),
            ],
            unresolved_machine_ref=machine_ref,
        )

    # ── Machine status (what is this machine doing?) ──────────────────────────
    if effective_machine_no:
        return ToolChain(
            intent=Intent.MACHINE_STATUS,
            description=f"Current status of {machine_no}",
            steps=[ToolStep("get_ongoing_operations", {"machine_no": _MNO}, "ongoing")],
            unresolved_machine_ref=machine_ref,
        )

    # ── Scrap analysis (department-wide) ─────────────────────────────────────
    if has_scrap:
        return ToolChain(
            intent=Intent.SCRAP_ANALYSIS,
            description=f"Scrap analysis across work centers for last {hours:.0f}h",
            steps=[ToolStep("get_activity_log", {"hours_back": min(hours, 24.0)}, "activity")],
        )

    # ── Activity log ──────────────────────────────────────────────────────────
    if has_activity:
        return ToolChain(
            intent=Intent.ACTIVITY_LOG,
            description=f"Activity log for last {hours:.0f}h",
            steps=[ToolStep("get_activity_log", {"hours_back": min(hours, 24.0)}, "activity")],
        )

    # ── Dashboard / KPI ───────────────────────────────────────────────────────
    if has_dash:
        wc_list = work_centers if work_centers else []
        return ToolChain(
            intent=Intent.MACHINE_DASHBOARD,
            description=f"Machine dashboard for WCs {wc_list} over last {hours:.0f}h",
            steps=[
                ToolStep("list_machines", {}, "machines", fan_out_work_centers=True),
                ToolStep("get_machine_dashboard", {
                    "hours_back": hours,
                    "work_center_nos": wc_list,
                }, "dashboard"),
            ],
        )

    # ── Department overview ───────────────────────────────────────────────────
    if has_dept or has_machine:
        return ToolChain(
            intent=Intent.DEPARTMENT_OVERVIEW,
            description="Overview of all machines in the user's work centers",
            steps=[ToolStep("list_machines", {}, "machines", fan_out_work_centers=True)],
        )

    # ── Fallback — no MES data needed ─────────────────────────────────────────
    return ToolChain(
        intent=Intent.GENERAL,
        description="General question — no data needed",
        steps=[],
    )
