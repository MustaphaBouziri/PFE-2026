"""
agent/orchestrator.py

Pipeline per request
────────────────────
1.  Classify intent with LLM identifier (primary).
    Fallback to deterministic regex classifier if LLM fails.
    → Internal reasoning stored in ThinkingBlock, never shown in chat.
2.  Build the allowed-machine map from the user's work centers.
3.  Execute the tool chain in order, resolving slot references between steps.
    Fan-out list_machines across all work centers (BC requires non-empty WC).
    Block any machine-scoped call for a machine outside the user's scope.
4.  Enrich raw tool results with pre-computed analysis.
5.  Build a compact context block for the LLM.
6.  Call the LLM ONCE for the final answer (no tool-call loop).
7.  Parse any ```actions``` block from the reply.
8.  Return ChatResponse  — with .thinking populated (hidden from chat).

Security model
──────────────
- allowed_machines is populated from the BC machine list filtered to the
  user's work_centers.  It is never modified by the LLM.
- Slot references in args are resolved in Python — the LLM never chooses
  which arguments to pass.
- A machine-scoped step with a machine_no not in allowed_machines is
  blocked and produces a ToolResult with success=False.
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any, Dict, List, Optional, Tuple

from agent.config import DEBUG_DATA, LLM_MAX_CONTEXT_CHARS
from agent.data_analysis import (
    analyse_scrap,
    analyse_velocity,
    enrich_deadlines,
    summarise_dashboard,
    summarise_machines,
    analyse_work_center_summary,
    analyse_operator_summary,
    analyse_scrap_summary,
    analyse_delay_report,
)
from agent.intent import (
    Intent,
    ToolChain,
    ToolStep,
    resolve_args,
)
from agent.composite import run_composite, build_composite_context
from agent.resolver import (
    HIGH_CONFIDENCE,
    MIN_CONFIDENCE,
    MachineEntry,
    ResolveResult,
    build_machine_index,
    format_candidates_for_llm,
    resolve_machine,
    resolve_work_center,
)
from agent.llm_client import LLMClient, build_llm_client
from agent.llm_intent import LLMIntentIdentifier, ThinkingBlock
from agent.models import (
    ActionType,
    ChatRequest,
    ChatResponse,
    RedirectAction,
    ToolResult,
)
from prompts.system_prompts import SYNTHESIS_SYSTEM, SYNTHESIS_USER_TEMPLATE
from tools.mes_tools import MACHINE_SCOPED_TOOLS, TOOL_MAP

logger = logging.getLogger("mes-ai.orchestrator")

# Matches the ```actions [...] ``` block the LLM may append
_ACTIONS_BLOCK_RE = re.compile(
    r"```actions\s*(\[.*?\])\s*```", re.DOTALL | re.IGNORECASE
)


def _substitute_machine_no(chain: "ToolChain", machine_no: str) -> "ToolChain":
    """
    Return a copy of chain with every "__RESOLVE__" placeholder in step args
    replaced by the resolved machine_no.
    """
    import copy
    new_chain = copy.deepcopy(chain)
    for step in new_chain.steps:
        for k, v in step.args.items():
            if isinstance(v, str) and "__RESOLVE__" in v:
                step.args[k] = v.replace("__RESOLVE__", machine_no)
    new_chain.unresolved_machine_ref = None
    return new_chain


class MESAgentOrchestrator:
    def __init__(self) -> None:
        self.llm: LLMClient = build_llm_client()
        # LLM-based intent identifier — uses same LLM client, separate prompt.
        # Falls back to regex classifier automatically on any failure.
        self.identifier = LLMIntentIdentifier(self.llm)
        
    # ── Public entry point ────────────────────────────────────────────────────

    async def run(self, request: ChatRequest) -> ChatResponse:
        token        = request.user_context.token
        work_centers = request.user_context.work_centers
        role         = request.user_context.role

        # 1. Classify intent + build tool chain
        #    Primary: LLM identifier  →  Fallback: regex classifier
        #    ThinkingBlock captures full internal reasoning (hidden from user).
        chain, thinking = await self.identifier.classify(
            message=request.message,
            role=role,
            work_centers=work_centers,
        )
        
        if thinking.method == "both_failed":
            return ChatResponse(
                text="The AI service is temporarily unavailable. Please try again in a moment.",
                actions=[],
                data_fetched=[],
                thinking=thinking.to_dict(),
            )

        logger.info(
            "Intent=%s | composite=%s | steps=%d | classifier=%s | msg=%s",
            chain.intent, chain.is_composite,
            len(chain.steps), thinking.method,
            request.message[:80],
        )

        # 2. Build allowed-machine map (populated lazily)
        allowed_machines: Dict[str, str] = {}  # machineNo → workCenterNo
        tools_called: List[str] = []

        # ── Composite path ───────────────────────────────────────────────────
        if chain.is_composite:
            return await self._run_composite(
                request, chain, thinking, allowed_machines, work_centers, role, token
            )

        # ── Normal single-machine / department path ───────────────────────────

        # 3. Name resolution — if the LLM or regex classifier flagged an
        #    unresolved machine reference, resolve it now.
        resolution_note = ""
        if chain.unresolved_machine_ref:
            machine_no, resolution_note = await self._resolve_machine_ref(
                chain.unresolved_machine_ref, allowed_machines, work_centers, token
            )
            if machine_no is None:
                return ChatResponse(
                    text=resolution_note,
                    actions=[],
                    data_fetched=[],
                    thinking=thinking.to_dict(),
                )
            chain = _substitute_machine_no(chain, machine_no)

        # 4. Execute tool chain
        results: Dict[str, Any] = {}
        tool_results: List[ToolResult] = []

        for step in chain.steps:
            step_results = await self._execute_step(
                step, results, allowed_machines, work_centers, token
            )
            for tr in step_results:
                tool_results.append(tr)
                if tr.success:
                    tools_called.append(tr.tool_name)
            if step_results:
                merged = self._merge_step_results(step, step_results)
                results[step.result_key] = merged

        # 5. Enrich raw results with analysis
        enriched = self._enrich(results)

        # 6. Build LLM context block
        context_block = self._build_context(chain, enriched)
        if resolution_note:
            context_block = f"**Resolution note:** {resolution_note}\n\n" + context_block

        # 7. Call LLM once for the synthesised answer
        answer_text = await self._synthesise(request, role, work_centers, context_block)

        # 8. Parse actions from answer
        actions, clean_text = self._parse_actions(answer_text)

        return ChatResponse(
            text=clean_text,
            actions=actions,
            data_fetched=tools_called if DEBUG_DATA else [],
            thinking=thinking.to_dict(),
        )

    # ── Composite runner ──────────────────────────────────────────────────────

    async def _run_composite(
        self,
        request: ChatRequest,
        chain: ToolChain,
        thinking: ThinkingBlock,
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        role: str,
        token: str,
    ) -> ChatResponse:
        """
        Handle composite multi-machine questions.

        1. Fan-out list_machines across all work centers → access-filter.
        2. Pass the filtered machine list to run_composite() which:
           a. Applies status/type filters (running, idle, etc.)
           b. Fan-outs the relevant per-machine tool in batches.
           c. Returns a CompositeResult.
        3. Build composite context → LLM → parse actions.
        """
        tools_called: List[str] = []

        # Fetch machine list (fan-out across work centers, access-filter)
        machines = await self._fetch_all_machines(allowed_machines, work_centers, token)
        tools_called.append("list_machines")

        composite_result = await run_composite(
            message=request.message,
            machines=machines,
            token=token,
            work_centers=work_centers,
        )
        if composite_result.per_machine:
            tools_called.append("(per-machine fan-out)")

        context_block = build_composite_context(composite_result)
        answer_text   = await self._synthesise(request, role, work_centers, context_block)
        actions, clean_text = self._parse_actions(answer_text)

        return ChatResponse(
            text=clean_text,
            actions=actions,
            data_fetched=tools_called if DEBUG_DATA else [],
            thinking=thinking.to_dict(),
        )

    # ── Name resolution ───────────────────────────────────────────────────────

    async def _resolve_machine_ref(
        self,
        ref: str,
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        token: str,
    ) -> tuple[Optional[str], str]:
        """
        Resolve a fuzzy machine reference to a canonical machineNo.

        Returns (machineNo, note) where:
          - machineNo is None if resolution failed (note contains clarification msg)
          - note is a human-readable assumption string if confidence < HIGH_CONFIDENCE
        """
        machines = await self._fetch_all_machines(allowed_machines, work_centers, token)
        index    = build_machine_index(machines)
        result   = resolve_machine(ref, index)

        logger.info(
            "Name resolution: '%s' → resolved=%s machine_no=%s confidence=%.2f",
            ref, result.resolved, result.machine_no, result.confidence,
        )

        if not result.resolved:
            return None, format_candidates_for_llm(result)

        note = ""
        if result.confidence < HIGH_CONFIDENCE:
            note = result.explanation

        return result.machine_no, note

    async def _fetch_all_machines(
        self,
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        token: str,
    ) -> List[Dict[str, Any]]:
        """
        Fetch machine list across all work centers and populate allowed_machines.
        Returns the merged list (access-filtered to user's work centers).
        """
        tool = TOOL_MAP["list_machines"]
        all_machines: List[Dict[str, Any]] = []

        for wc in (work_centers or []):
            r = await tool.execute(work_center_no=wc, token=token)
            if r.success and isinstance(r.data, list):
                for m in r.data:
                    mno  = m.get("machineNo") or m.get("no") or ""
                    wc_no = m.get("workCenterNo") or ""
                    if mno:
                        allowed_machines[str(mno)] = str(wc_no)
                all_machines.extend(r.data)

        return all_machines

    # ── Step execution ────────────────────────────────────────────────────────

    async def _execute_step(
        self,
        step: ToolStep,
        results: Dict[str, Any],
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        token: str,
    ) -> List[ToolResult]:
        """
        Execute one ToolStep and return a list of ToolResults.

        For fan_out_work_centers=True, fires one call per work center and
        returns all results.
        """
        if step.fan_out_work_centers:
            return await self._fan_out_list_machines(
                step, results, allowed_machines, work_centers, token
            )

        resolved_args = resolve_args(step.args, results)

        # Check whether any resolved arg is None (slot miss from prior step)
        if None in resolved_args.values():
            missing = [k for k, v in resolved_args.items() if v is None]
            logger.warning(
                "Step %s skipped — unresolved args: %s", step.tool, missing
            )
            return [ToolResult(
                tool_name=step.tool,
                success=False,
                error=f"Could not resolve required arguments: {missing}. "
                      f"A prior step may have returned no data.",
            )]

        if resolved_args.get("machine_no") == "__RESOLVE__":
            return [ToolResult(
                tool_name=step.tool,
                success=False,
                error="Machine reference was not resolved before execution. "
                    "This is an internal bug — unresolved_machine_ref should have been set.",
            )]

        # Access control for machine-scoped tools
        if step.tool in MACHINE_SCOPED_TOOLS:
            machine_no = resolved_args.get("machine_no", "")
            if machine_no and machine_no not in allowed_machines:
                if not allowed_machines:
                    await self._pre_fetch_machines(allowed_machines, work_centers, token)
                if machine_no not in allowed_machines:
                    logger.warning(
                        "ACCESS DENIED: tool=%s machine=%s wcs=%s",
                        step.tool, machine_no, work_centers,
                    )
                    return [ToolResult(
                        tool_name=step.tool,
                        success=False,
                        error=(
                            f"Access denied: machine '{machine_no}' is not in your "
                            f"assigned work centres ({', '.join(work_centers)})."
                        ),
                    )]

        tool = TOOL_MAP.get(step.tool)
        if not tool:
            return [ToolResult(
                tool_name=step.tool,
                success=False,
                error=f"Unknown tool: {step.tool}",
            )]

        result = await tool.execute(**resolved_args, token=token)
        logger.info(
            "Tool %s → success=%s data_len=%s",
            step.tool,
            result.success,
            len(result.data) if isinstance(result.data, list) else "scalar",
        )
        return [result]

    async def _fan_out_list_machines(
        self,
        step: ToolStep,
        results: Dict[str, Any],
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        token: str,
    ) -> List[ToolResult]:
        """
        Fire list_machines once per work center and merge all machines into
        a single ToolResult stored under step.result_key.
        """
        if not work_centers:
            logger.warning("fan_out_list_machines: no work centers — returning empty")
            return [ToolResult(tool_name="list_machines", success=True, data=[])]

        tool = TOOL_MAP["list_machines"]
        all_machines: List[Dict[str, Any]] = []
        any_success = False

        for wc in work_centers:
            r = await tool.execute(work_center_no=wc, token=token)
            if r.success and isinstance(r.data, list):
                any_success = True
                for m in r.data:
                    mno = m.get("machineNo") or m.get("no") or ""
                    wc_no = m.get("workCenterNo") or ""
                    if mno:
                        allowed_machines[str(mno)] = str(wc_no)
                all_machines.extend(r.data)

        merged = ToolResult(
            tool_name="list_machines",
            success=any_success,
            data=all_machines,
        )
        return [merged]

    async def _pre_fetch_machines(
        self,
        allowed_machines: Dict[str, str],
        work_centers: List[str],
        token: str,
    ) -> None:
        """Silently populate allowed_machines before an access-control check."""
        tool = TOOL_MAP["list_machines"]
        for wc in (work_centers or []):
            r = await tool.execute(work_center_no=wc, token=token)
            if r.success and isinstance(r.data, list):
                for m in r.data:
                    mno = m.get("machineNo") or m.get("no") or ""
                    wc_no = m.get("workCenterNo") or ""
                    if mno:
                        allowed_machines[str(mno)] = str(wc_no)

    def _merge_step_results(
        self, step: ToolStep, step_results: List[ToolResult]
    ) -> Any:
        """Return the data to store for this step's result_key."""
        successful = [r for r in step_results if r.success and r.data is not None]
        if not successful:
            return None
        if len(successful) == 1:
            return successful[0].data
        merged: List[Any] = []
        for r in successful:
            if isinstance(r.data, list):
                merged.extend(r.data)
            else:
                merged.append(r.data)
        return merged

    # ── Data enrichment ───────────────────────────────────────────────────────

    def _enrich(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run analysis functions over raw results and return an enriched dict.
        Every tool result key has a corresponding branch. Unknown keys are
        passed through as-is so new tools degrade gracefully.
        """
        enriched: Dict[str, Any] = {}

        for key, data in results.items():
            if data is None:
                enriched[key] = {"error": "No data returned"}
                continue

            if key == "machines" and isinstance(data, list):
                enriched[key] = {
                    "machines": data,
                    "summary": summarise_machines(data),
                }

            elif key == "orders" and isinstance(data, list):
                enriched[key] = enrich_deadlines(data)

            elif key == "ongoing" and isinstance(data, list):
                enriched[key] = {"operations": data, "count": len(data)}

            elif key == "live_data" and isinstance(data, dict):
                cycles = results.get("cycles") or []
                enriched[key] = {
                    "live": data,
                    "scrap_analysis": analyse_scrap(live_data=data, cycles=cycles),
                    "velocity":       analyse_velocity(data, cycles),
                }

            elif key == "cycles" and isinstance(data, list):
                live = results.get("live_data")
                enriched[key] = {
                    "cycles": data,
                    "count": len(data),
                    "scrap_analysis": analyse_scrap(
                        live_data=live if isinstance(live, dict) else None,
                        cycles=data,
                    ),
                }

            elif key == "activity" and isinstance(data, list):
                enriched[key] = {
                    "log": data,
                    "count": len(data),
                    "scrap_analysis": analyse_scrap(activity=data),
                }

            elif key == "dashboard" and isinstance(data, list):
                enriched[key] = {
                    "machines": data,
                    "fleet_summary": summarise_dashboard(data),
                }

            elif key == "history" and isinstance(data, list):
                enriched[key] = {"history": data, "count": len(data)}

            elif key == "bom" and isinstance(data, list):
                missing = [
                    b for b in data
                    if float(b.get("totalQuantityScanned") or 0) < float(b.get("quantityPerUnit") or 0)
                ]
                enriched[key] = {
                    "bom": data,
                    "component_count": len(data),
                    "missing_components": [b.get("itemNo") for b in missing],
                }
            elif key == "production_orders" and isinstance(data, list):
                status_counts: Dict[str, int] = {}
                total_produced = 0.0
                for o in data:
                    status = str(o.get("status") or o.get("Status") or "unknown")
                    status_counts[status] = status_counts.get(status, 0) + 1
                    total_produced += float(o.get("totalProducedQuantity") or 0)
                running = sum(
                    1 for o in data if o.get("hasRunningOperation")
                )
                enriched[key] = {
                    "orders": data,
                    "count": len(data),
                    "status_counts": status_counts,
                    "running_count": running,
                    "interpretation": (
                        f"{len(data)} order(s): "
                        + ", ".join(f"{v} {k}" for k, v in status_counts.items())
                        + f". {running} currently running."
                    ),
                }

            elif key == "work_center_summary" and isinstance(data, list):
                enriched[key] = {
                    "summary": data,
                    "analysis": analyse_work_center_summary(data),
                }

            elif key == "operator_summary" and isinstance(data, list):
                enriched[key] = {
                    "operators": data,
                    "count": len(data),
                    "analysis": analyse_operator_summary(data),
                }

            elif key == "my_data" and isinstance(data, dict):
                enriched[key] = {
                    "my_data": data,
                    "interpretation": (
                        f"You completed {data.get('completedOpsCount', 0)} operation(s), "
                        f"produced {data.get('totalProducedQty', 0)} units, "
                        f"scrapped {data.get('totalScrapQty', 0)} units. "
                        f"{data.get('runningOpsCount', 0)} op(s) currently running."
                    ),
                }

            elif key == "scrap_summary" and isinstance(data, dict):
                enriched[key] = {
                    "scrap": data,
                    "analysis": analyse_scrap_summary(data),
                }

            elif key == "delay_report" and isinstance(data, list):
                enriched[key] = {
                    "delays": data,
                    "count": len(data),
                    "analysis": analyse_delay_report(data),
                }

            elif key == "consumption_summary" and isinstance(data, list):
                over_consumed = [
                    ex for ex in data
                    if any(
                        comp.get("isOverConsumed")
                        for comp in (ex.get("components") or [])
                    )
                ]
                missing_consumption = [
                    ex for ex in data
                    if any(
                        comp.get("isMissingConsumption")
                        for comp in (ex.get("components") or [])
                    )
                ]
                enriched[key] = {
                    "consumption": data,
                    "count": len(data),
                    "over_consumed_executions": len(over_consumed),
                    "missing_consumption_executions": len(missing_consumption),
                    "interpretation": (
                        f"{len(data)} execution(s) checked. "
                        f"{len(over_consumed)} with over-consumption, "
                        f"{len(missing_consumption)} with missing consumption."
                    ),
                }

            elif key == "supervisor_overview" and isinstance(data, dict):
                enriched[key] = {
                    "overview": data,
                    "interpretation": (
                        f"Stopped machines: {data.get('stoppedMachineCount', 0)}, "
                        f"idle operators: {data.get('idleOperatorCount', 0)}, "
                        f"abnormal pauses: {data.get('abnormalPauseCount', 0)}, "
                        f"high-scrap ops: {data.get('highScrapOpsCount', 0)}, "
                        f"delayed ops: {data.get('delayedOpsCount', 0)}. "
                        f"Produced: {data.get('totalProducedQty', 0)}, "
                        f"scrapped: {data.get('totalScrapQty', 0)}."
                    ),
                }

            else:
                enriched[key] = {"data": data}

        return enriched

 # ── Context building ──────────────────────────────────────────────────────

    def _build_context(self, chain: ToolChain, enriched: Dict[str, Any]) -> str:
        """
        Build a compact, LLM-readable context block.

        Each result key is rendered in the most token-efficient format for its
        data type (markdown table, key-value list, or plain interpretation).
        Sections are added in order until the character budget is exhausted;
        remaining sections are replaced with their interpretation line only
        (emergency compression), ensuring the LLM always gets a coherent
        response rather than truncated JSON.
        """
        header = f"## Retrieved data — {chain.description}\n"
        sections: List[str] = []
        total_chars = len(header)
        budget = LLM_MAX_CONTEXT_CHARS

        for key, data in enriched.items():
            section = self._compress_section(key, data)
            if total_chars + len(section) > budget:
                # Try emergency-compressed version (interpretation only)
                remaining = budget - total_chars - 10
                section = self._emergency_compress(key, data, remaining)
            if section:
                sections.append(section)
                total_chars += len(section)
            if total_chars >= budget:
                break

        return header + "\n".join(sections)

    # ── Section compressor dispatcher ─────────────────────────────────────────

    def _compress_section(self, key: str, data: Any) -> str:
        """
        Choose the most token-efficient representation for one result key.
        Dispatches to a format helper based on the key name.
        """
        lines: List[str] = [f"### {key}"]

        # Pre-computed interpretation — always include first (free chars)
        interp = self._extract_interpretation(data)
        if interp:
            lines.append(f"**{interp}**")
        lines.append("")

        if key == "machines":
            machines = data.get("machines", []) if isinstance(data, dict) else []
            lines.append(self._fmt_machine_table(machines))

        elif key == "orders":
            orders = data.get("orders", data) if isinstance(data, dict) else data
            if isinstance(orders, list):
                lines.append(self._fmt_orders_table(orders))

        elif key == "dashboard":
            machines = (
                data.get("machines", []) if isinstance(data, dict) else []
            )
            lines.append(self._fmt_dashboard_table(machines))

        elif key == "ongoing":
            ops = data.get("operations", []) if isinstance(data, dict) else []
            lines.append(self._fmt_ongoing_table(ops))

        elif key == "history":
            rows = data.get("history", []) if isinstance(data, dict) else []
            lines.append(self._fmt_history_table(rows[:20]))

        elif key == "cycles":
            rows = data.get("cycles", []) if isinstance(data, dict) else []
            # Also include scrap analysis interpretation if present
            sa = data.get("scrap_analysis", {}) if isinstance(data, dict) else {}
            sa_interp = sa.get("interpretation", "")
            if sa_interp:
                lines.append(f"*Scrap: {sa_interp}*")
            lines.append(self._fmt_cycles_table(rows[:30]))

        elif key == "bom":
            rows = data.get("bom", []) if isinstance(data, dict) else []
            missing = data.get("missing_components", []) if isinstance(data, dict) else []
            if missing:
                lines.append(f"⚠ Missing/under-scanned components: {', '.join(str(m) for m in missing)}")
            lines.append(self._fmt_bom_table(rows))

        elif key == "live_data":
            lines.append(self._fmt_live_kv(data))

        elif key == "work_center_summary":
            wcs = data.get("summary", []) if isinstance(data, dict) else []
            lines.append(self._fmt_wc_table(wcs))

        elif key == "operator_summary":
            ops = data.get("operators", []) if isinstance(data, dict) else []
            lines.append(self._fmt_operator_table(ops))

        elif key == "scrap_summary":
            lines.append(self._fmt_scrap_summary_kv(data))

        elif key == "delay_report":
            delays = data.get("delays", []) if isinstance(data, dict) else []
            lines.append(self._fmt_delay_table(delays[:20]))

        elif key == "consumption_summary":
            items = data.get("consumption", []) if isinstance(data, dict) else []
            lines.append(self._fmt_consumption_table(items[:15]))

        elif key == "supervisor_overview":
            lines.append(self._fmt_supervisor_kv(data))

        elif key == "production_orders":
            orders = data.get("orders", []) if isinstance(data, dict) else []
            sc = data.get("status_counts", {}) if isinstance(data, dict) else {}
            if sc:
                lines.append(
                    "Status counts: "
                    + ", ".join(f"{v}× {k}" for k, v in sc.items())
                )
            lines.append(self._fmt_production_orders_table(orders[:25]))

        elif key == "activity":
            log = data.get("log", []) if isinstance(data, dict) else []
            lines.append(self._fmt_activity_table(log[:30]))

        elif key == "my_data":
            md = data.get("my_data", {}) if isinstance(data, dict) else {}
            lines.append(self._fmt_my_data_kv(md))

        else:
            # Unknown key — compact JSON capped at 600 chars
            raw = json.dumps(data, default=str, ensure_ascii=False)
            lines.append(raw[:600] + ("…" if len(raw) > 600 else ""))

        lines.append("")
        return "\n".join(lines)

    # ── Emergency fallback ────────────────────────────────────────────────────

    @staticmethod
    def _emergency_compress(key: str, data: Any, remaining: int) -> str:
        """
        When budget is nearly exhausted, emit interpretation only.
        If even that won't fit, emit nothing rather than a broken fragment.
        """
        if remaining < 40:
            return ""
        interp = MESAgentOrchestrator._extract_interpretation(data)
        if interp:
            snippet = interp[: remaining - 30]
            return f"### {key}\n**{snippet}**\n*(detail omitted — budget)*\n"
        return f"### {key}\n*(omitted — context budget exceeded)*\n"

    # ── Interpretation extractor ──────────────────────────────────────────────

    @staticmethod
    def _extract_interpretation(data: Any) -> str:
        """
        Pull the pre-computed interpretation string from any enriched block.
        Checks the top level and one level of nesting.
        """
        if not isinstance(data, dict):
            return ""
        # Direct key
        v = data.get("interpretation")
        if isinstance(v, str) and v:
            return v
        # Nested one level (e.g. data["summary"]["interpretation"])
        for sub in data.values():
            if isinstance(sub, dict):
                v2 = sub.get("interpretation")
                if isinstance(v2, str) and v2:
                    return v2
        return ""

    # ── Shared table builder ──────────────────────────────────────────────────

    @staticmethod
    def _md_table(headers: List[str], rows: List[List[Any]], max_cell: int = 38) -> str:
        """
        Render a compact markdown table.
        Cell content is truncated to max_cell chars to prevent runaway widths.
        Returns an empty-state message when rows is empty.
        """
        if not rows:
            return f"*No data ({', '.join(headers)})*"

        def cell(v: Any) -> str:
            s = str(v) if v is not None else "-"
            return (s[: max_cell - 1] + "…") if len(s) > max_cell else s

        sep = "| " + " | ".join("---" for _ in headers) + " |"
        header_row = "| " + " | ".join(headers) + " |"
        data_rows = [
            "| " + " | ".join(cell(c) for c in row) + " |"
            for row in rows
        ]
        return "\n".join([header_row, sep] + data_rows)

    # ── Per-type format helpers ───────────────────────────────────────────────

    def _fmt_machine_table(self, machines: List[Dict]) -> str:
        rows = [
            [
                m.get("machineNo", "-"),
                (m.get("machineName") or "-")[:22],
                m.get("status", "-"),
                m.get("workCenterNo", "-"),
                m.get("currentOrder", "-"),
            ]
            for m in machines
        ]
        return self._md_table(["MachineNo", "Name", "Status", "WC", "CurrentOrder"], rows)

    def _fmt_orders_table(self, orders: List[Dict]) -> str:
        rows = [
            [
                o.get("orderNo", "-"),
                o.get("risk_level", "-"),
                f"{round(float(o.get('hours_until_deadline') or 0), 1)}h",
                o.get("itemNo", "-"),
                o.get("OrderQuantity", "-"),
                o.get("status", "-"),
            ]
            for o in orders[:20]
        ]
        return self._md_table(
            ["OrderNo", "Risk", "HoursLeft", "Item", "Qty", "Status"], rows
        )

    def _fmt_dashboard_table(self, machines: List[Dict]) -> str:
        rows = [
            [
                m.get("machineNo", "-"),
                f"{float(m.get('uptimePercent') or 0):.1f}%",
                int(float(m.get("totalProduced") or 0)),
                int(float(m.get("totalScrap") or 0)),
                m.get("operationFinished", 0),
            ]
            for m in machines
        ]
        return self._md_table(
            ["Machine", "Uptime%", "Produced", "Scrap", "OpsFinished"], rows
        )

    def _fmt_ongoing_table(self, ops: List[Dict]) -> str:
        rows = [
            [
                op.get("prodOrderNo", "-"),
                op.get("operationNo", "-"),
                op.get("operationStatus", "-"),
                f"{round(float(op.get('progressPercent') or 0), 1)}%",
                op.get("totalProducedQuantity", "-"),
                op.get("orderQuantity", "-"),
            ]
            for op in ops
        ]
        return self._md_table(
            ["OrderNo", "OpNo", "Status", "Progress", "Produced", "OrderQty"], rows
        )

    def _fmt_history_table(self, history: List[Dict]) -> str:
        rows = [
            [
                h.get("prodOrderNo", "-"),
                h.get("operationNo", "-"),
                h.get("operationStatus", "-"),
                (h.get("startDateTime") or "-")[:16],
                (h.get("endDateTime") or "-")[:16],
            ]
            for h in history
        ]
        return self._md_table(
            ["OrderNo", "OpNo", "Status", "Start", "End"], rows
        )

    def _fmt_cycles_table(self, cycles: List[Dict]) -> str:
        rows = [
            [
                (c.get("declaredAt") or "-")[:16],
                c.get("operatorId", "-"),
                c.get("cycleQuantity", 0),
                c.get("totalProducedQuantity", 0),
            ]
            for c in cycles
        ]
        return self._md_table(
            ["Time", "Operator", "CycleQty", "TotalProduced"], rows
        )

    def _fmt_bom_table(self, bom: List[Dict]) -> str:
        rows = [
            [
                b.get("itemNo", "-"),
                (b.get("itemDescription") or "-")[:28],
                round(float(b.get("quantityPerUnit") or 0), 2),
                round(float(b.get("totalQuantityScanned") or 0), 2),
                (
                    "⚠ MISSING"
                    if float(b.get("totalQuantityScanned") or 0) == 0
                    else (
                        "⚠ LOW"
                        if float(b.get("totalQuantityScanned") or 0)
                        < float(b.get("quantityPerUnit") or 0)
                        else "✓"
                    )
                ),
            ]
            for b in bom
        ]
        return self._md_table(
            ["Item", "Description", "Required", "Scanned", "Status"], rows
        )

    @staticmethod
    def _fmt_live_kv(data: Dict) -> str:
        live = data.get("live", {}) if isinstance(data, dict) else {}
        sa   = data.get("scrap_analysis", {}) if isinstance(data, dict) else {}
        vel  = data.get("velocity", {}) if isinstance(data, dict) else {}
        lines = [
            f"- Status: {live.get('operationStatus', '-')}",
            f"- Produced: {live.get('totalProducedQuantity', '-')} "
            f"/ {live.get('orderQuantity', '-')} "
            f"({round(float(live.get('progressPercent') or 0), 1)}%)",
            f"- Scrap qty: {live.get('scrapQuantity', 0)}",
            f"- Scrap analysis: {sa.get('interpretation', 'n/a')}",
            f"- Velocity: {vel.get('interpretation', 'n/a')}",
        ]
        return "\n".join(lines)

    def _fmt_wc_table(self, wcs: List[Dict]) -> str:
        rows = [
            [
                w.get("workCenterNo", "-"),
                (w.get("workCenterName") or "-")[:18],
                f"{w.get('workingMachines', 0)}/{w.get('totalMachines', 0)}",
                w.get("runningOperationsCount", 0),
                int(float(w.get("totalProducedQty") or 0)),
                int(float(w.get("totalScrapQty") or 0)),
            ]
            for w in wcs
        ]
        return self._md_table(
            ["WC", "Name", "Working/Total", "RunningOps", "Produced", "Scrap"], rows
        )

    def _fmt_operator_table(self, ops: List[Dict]) -> str:
        rows = [
            [
                o.get("userId", "-"),
                (o.get("fullName") or "-")[:18],
                "✓" if o.get("isLoggedIn") else "-",
                o.get("currentMachineNo", "-") if o.get("isActiveOnMachine") else "idle",
                int(float(o.get("totalProducedQty") or 0)),
                int(float(o.get("totalScrapQty") or 0)),
            ]
            for o in ops
        ]
        return self._md_table(
            ["UserId", "Name", "LoggedIn", "Machine", "Produced", "Scrap"], rows
        )

    @staticmethod
    def _fmt_scrap_summary_kv(data: Dict) -> str:
        scrap    = data.get("scrap", {})    if isinstance(data, dict) else {}
        analysis = data.get("analysis", {}) if isinstance(data, dict) else {}
        lines = [
            f"- Total scrap: {scrap.get('totalScrapQty', 0)} units "
            f"({scrap.get('recordCount', 0)} records)",
        ]
        top_m = analysis.get("top_machines", [])
        if top_m:
            lines.append("- Top machines by scrap:")
            for t in top_m:
                lines.append(f"  - {t['machineNo']}: {t['scrap']} units")
        top_r = analysis.get("top_reasons", [])
        if top_r:
            lines.append("- Top scrap reasons:")
            for t in top_r:
                lines.append(f"  - {t['code']}: {t['scrap']} units")
        return "\n".join(lines)

    def _fmt_delay_table(self, delays: List[Dict]) -> str:
        rows = [
            [
                d.get("prodOrderNo", "-"),
                d.get("operationNo", "-"),
                d.get("machineNo", "-"),
                "✓" if d.get("isOverdue") else "-",
                "✓" if d.get("isPausedTooLong") else "-",
                f"{round(float(d.get('delayMinutes') or 0)):.0f}m",
            ]
            for d in delays
        ]
        return self._md_table(
            ["OrderNo", "OpNo", "Machine", "Overdue", "LongPause", "Delay"], rows
        )

    def _fmt_consumption_table(self, executions: List[Dict]) -> str:
        """Flattens execution→components into one row per component (capped)."""
        rows: List[List[Any]] = []
        for ex in executions:
            for comp in (ex.get("components") or [])[:6]:
                status = (
                    "OVER"    if comp.get("isOverConsumed")       else
                    "MISSING" if comp.get("isMissingConsumption") else
                    "LOW"     if comp.get("isUnderConsumed")      else
                    "OK"
                )
                rows.append([
                    ex.get("prodOrderNo", "-"),
                    comp.get("itemNo", "-"),
                    round(float(comp.get("plannedQty") or 0), 2),
                    round(float(comp.get("consumedQty") or 0), 2),
                    status,
                ])
            if len(rows) >= 25:
                break
        return self._md_table(
            ["OrderNo", "Item", "Planned", "Consumed", "Status"], rows
        )

    @staticmethod
    def _fmt_supervisor_kv(data: Dict) -> str:
        ov = data.get("overview", {}) if isinstance(data, dict) else {}
        lines = [
            f"- Produced: {ov.get('totalProducedQty', 0)} | "
            f"Scrap: {ov.get('totalScrapQty', 0)}",
            f"- Stopped machines:   {ov.get('stoppedMachineCount', 0)}",
            f"- Idle operators:     {ov.get('idleOperatorCount', 0)}",
            f"- Abnormal pauses:    {ov.get('abnormalPauseCount', 0)}",
            f"- High-scrap ops:     {ov.get('highScrapOpsCount', 0)}",
            f"- Delayed ops:        {ov.get('delayedOpsCount', 0)}",
        ]
        # Append the sub-arrays as compact tables if they exist and are non-empty
        stopped = ov.get("stoppedMachines") or []
        if stopped:
            lines.append("\nStopped machines:")
            for m in stopped[:5]:
                lines.append(
                    f"  - {m.get('machineNo')} ({m.get('machineName', '')}): "
                    f"idle {round(float(m.get('idleSinceMinutes') or 0))}min"
                )
        pauses = ov.get("abnormalPauses") or []
        if pauses:
            lines.append("\nAbnormal pauses:")
            for p in pauses[:5]:
                lines.append(
                    f"  - Order {p.get('prodOrderNo')} op {p.get('operationNo')} "
                    f"on {p.get('machineNo')}: "
                    f"{round(float(p.get('pausedSinceMinutes') or 0))}min"
                )
        return "\n".join(lines)

    def _fmt_production_orders_table(self, orders: List[Dict]) -> str:
        rows = [
            [
                o.get("orderNo", "-"),
                o.get("status", "-"),
                o.get("itemNo", "-"),
                round(float(o.get("orderQuantity") or 0)),
                f"{round(float(o.get('progressPercent') or 0), 1)}%",
                (o.get("dueDate") or "-")[:10],
                "✓" if o.get("hasRunningOperation") else "-",
            ]
            for o in orders
        ]
        return self._md_table(
            ["OrderNo", "Status", "Item", "Qty", "Progress", "DueDate", "Running"],
            rows,
        )

    def _fmt_activity_table(self, log: List[Dict]) -> str:
        rows = [
            [
                (e.get("timestamp") or "-")[:16],
                e.get("type", "-"),
                e.get("machineNo", "-"),
                (e.get("operatorName") or "-")[:14],
                (e.get("action") or "-")[:34],
            ]
            for e in log
        ]
        return self._md_table(
            ["Time", "Type", "Machine", "Operator", "Action"], rows
        )

    @staticmethod
    def _fmt_my_data_kv(md: Dict) -> str:
        lines = [
            f"- User: {md.get('userId', '-')} ({md.get('fullName', '')})",
            f"- Produced: {md.get('totalProducedQty', 0)} units",
            f"- Scrapped: {md.get('totalScrapQty', 0)} units",
            f"- Ops completed: {md.get('completedOpsCount', 0)}",
            f"- Ops running:   {md.get('runningOpsCount', 0)}",
            f"- Ops paused:    {md.get('pausedOpsCount', 0)}",
        ]
        ops = md.get("operations") or []
        if ops:
            lines.append(f"\nOperations ({min(len(ops), 5)} most recent):")
            for op in ops[:5]:
                lines.append(
                    f"  - Order {op.get('prodOrderNo')} op {op.get('operationNo')} "
                    f"on {op.get('machineNo')}: {op.get('latestStatus', '-')}"
                )
        return "\n".join(lines)
    # ── LLM synthesis ─────────────────────────────────────────────────────────

    async def _synthesise(
        self,
        request: ChatRequest,
        role: str,
        work_centers: List[str],
        context_block: str,
    ) -> str:
        wc_str = ", ".join(work_centers) if work_centers else "all"
        system = SYNTHESIS_SYSTEM.format(role=role, work_centers=wc_str)

        history_msgs = [
            {"role": t.role, "content": t.content}
            for t in request.conversation_history[-6:]
        ]

        user_content = SYNTHESIS_USER_TEMPLATE.format(
            message=request.message,
            context_block=context_block,
        )

        messages = [
            {"role": "system", "content": system},
            *history_msgs,
            {"role": "user", "content": user_content},
        ]

        try:
            return await self.llm.complete(messages)
        except httpx.HTTPStatusError as e:
            if e.response.status_code >= 500:
                logger.error("LLM synthesis 5xx: %s", e)
                return "The AI service is temporarily unavailable. Please try again shortly."
            raise
        except Exception as e:
            logger.exception("LLM synthesis failed")
            return f"I was unable to generate an answer due to an error: {e}"

    # ── Action parsing ────────────────────────────────────────────────────────

    def _parse_actions(self, answer_text: str) -> tuple[List[RedirectAction], str]:
        """
        Extract the optional ```actions [...] ``` block from the LLM reply.
        Returns (actions, cleaned_text).
        """
        match = _ACTIONS_BLOCK_RE.search(answer_text)
        if not match:
            return [], answer_text.strip()

        clean = _ACTIONS_BLOCK_RE.sub("", answer_text).strip()

        try:
            raw_actions = json.loads(match.group(1))
        except json.JSONDecodeError as e:
            logger.warning("Could not parse actions JSON: %s", e)
            return [], clean

        actions: List[RedirectAction] = []
        for item in raw_actions[:4]:
            try:
                action = RedirectAction(
                    action_type=item["action_type"],
                    label=item["label"],
                    payload=item.get("payload", {}),
                )
                actions.append(action)
            except Exception as e:
                logger.warning("Skipping malformed action %s: %s", item, e)

        return actions, clean