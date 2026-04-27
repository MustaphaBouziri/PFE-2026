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
)
from agent.intent import (
    Intent,
    ToolChain,
    ToolStep,
    classify as regex_classify,
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
        Each key maps to {raw: ..., analysis: ...}.
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
                for o in data:
                    status = str(o.get("status") or o.get("Status") or "unknown")
                    status_counts[status] = status_counts.get(status, 0) + 1

                enriched[key] = {
                    "orders": data,
                    "count": len(data),
                    "status_counts": status_counts,
                }

            elif key == "work_center_summary":
                enriched[key] = {
                    "summary": data,
                }

            elif key == "operator_summary":
                enriched[key] = {
                    "operators": data if isinstance(data, list) else data,
                    "count": len(data) if isinstance(data, list) else None,
                }

            elif key == "my_data":
                enriched[key] = {
                    "my_data": data,
                }

            elif key == "scrap_summary":
                enriched[key] = {
                    "scrap": data,
                }

            elif key == "delay_report" and isinstance(data, list):
                enriched[key] = {
                    "delays": data,
                    "count": len(data),
                }

            elif key == "consumption_summary" and isinstance(data, list):
                enriched[key] = {
                    "consumption": data,
                    "count": len(data),
                }

            elif key == "supervisor_overview":
                enriched[key] = {
                    "overview": data,
                }

            else:
                enriched[key] = {"data": data}

        return enriched

    # ── Context building ──────────────────────────────────────────────────────

    def _build_context(
        self, chain: ToolChain, enriched: Dict[str, Any]
    ) -> str:
        """
        Build a compact, structured context block to inject into the LLM prompt.
        Caps at LLM_MAX_CONTEXT_CHARS to avoid overflowing the model context.
        """
        lines = [
            f"## Data retrieved ({chain.description})",
            "",
        ]

        for key, data in enriched.items():
            lines.append(f"### {key}")
            interp = None
            if isinstance(data, dict):
                interp = (
                    (data.get("summary") or {}).get("interpretation")
                    or (data.get("scrap_analysis") or {}).get("interpretation")
                    or (data.get("velocity") or {}).get("interpretation")
                    or (data.get("fleet_summary") or {}).get("interpretation")
                )
            if interp:
                lines.append(f"**Summary:** {interp}")

            raw_json = json.dumps(data, default=str, ensure_ascii=False)
            if len(raw_json) > 3000:
                raw_json = raw_json[:3000] + "…(truncated)"
            lines.append(f"```json\n{raw_json}\n```")
            lines.append("")

        block = "\n".join(lines)
        if len(block) > LLM_MAX_CONTEXT_CHARS:
            block = block[:LLM_MAX_CONTEXT_CHARS] + "\n\n…(context truncated)"
        return block

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