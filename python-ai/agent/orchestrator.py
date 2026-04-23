"""
agent/orchestrator.py

The brain of the MES AI agent.

Pipeline per request:
  1.  Classify intent  (fast single LLM call)
  2.  Build context-enriched system prompt
  3.  Run tool-call loop (LLM ↔ tools, up to MAX_TOOL_ROUNDS)
      3a. ACCESS CONTROL — block any machine-scoped tool call for a machineNo
          that does not belong to the user's work centers.  This is enforced in
          Python, not in the LLM prompt, so it cannot be bypassed by prompt
          injection or model misbehaviour.
      3b. NAME COLLISION — if the LLM resolves a machine name to multiple
          machineNos across the user's work centers, we inject a disambiguation
          message back into the conversation and do NOT execute the tool.
  4.  Enrich raw data with analysis (deadlines, scrap, velocity)
  5.  Get final LLM answer
  6.  Extract redirect actions from the answer + data
  7.  Return ChatResponse

Security model
--------------
- The user's work_centers list is the authoritative access scope.
- After the first list_machines call, we build a machineNo → workCenterNo map
  restricted to the user's work centers only.
- Any subsequent tool call with a machineNo that is not in that map is BLOCKED
  with a ToolResult error — the LLM never receives the data.
- The AI service-account token (MESAuthManager) is used as a fallback when the
  user has no token.  It authenticates the HTTP call but does NOT expand the
  user's data scope — the work-center filter is applied after data is returned.
"""

from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional, Set, Tuple

from agent.config import MAX_TOOL_ROUNDS, DEBUG_DATA
from agent.data_analysis import (
    analyse_deadlines,
    analyse_scrap,
    analyse_velocity,
    summarise_department,
)
from agent.llm_client import OllamaClient
from agent.mes_auth import mes_auth
from agent.models import (
    ActionType,
    ChatRequest,
    ChatResponse,
    ConversationTurn,
    RedirectAction,
    ToolResult,
)
from prompts.system_prompts import (
    ACTION_EXTRACTION_PROMPT,
    INTENT_CLASSIFICATION_PROMPT,
    SYSTEM_PROMPT,
)
from tools.mes_tools import TOOL_MAP, MACHINE_SCOPED_TOOLS, get_tool_schemas

logger = logging.getLogger("mes-ai.orchestrator")


class MESAgentOrchestrator:
    def __init__(self):
        self.llm = OllamaClient()

    # ── Public entry point ─────────────────────────────────────────────────────

    async def run(self, request: ChatRequest) -> ChatResponse:
        # Prefer the user-supplied token; fall back to the AI service account.
        user_token = request.user_context.token
        ai_token = await mes_auth.get_token()
        token = user_token or ai_token or ""

        work_centers: List[str] = request.user_context.work_centers
        role: str = request.user_context.role

        # 1. Classify intent
        intent = await self._classify_intent(request.message)
        logger.info("Intent: %s | Message: %s", intent, request.message[:80])

        # 2. Build message history for the LLM
        system_content = self._build_system_prompt(role, work_centers)
        messages = self._build_messages(system_content, request)

        # 3. Tool-call loop
        all_tool_results: List[ToolResult] = []
        tools_called: List[str] = []
        final_message: Dict[str, Any] = {}

        # Access-control state: populated after the first list_machines call.
        # Maps machineNo (str) → workCenterNo (str) for machines the user can see.
        allowed_machines: Dict[str, str] = {}
        # True once we've fetched the user's machine list at least once.
        machine_list_fetched: bool = False

        for round_i in range(MAX_TOOL_ROUNDS):
            response_msg = await self.llm.chat(messages, tools=get_tool_schemas())

            if not self.llm.has_tool_calls(response_msg):
                final_message = response_msg
                break

            tool_calls = self.llm.extract_tool_calls(response_msg)
            messages.append(response_msg)

            for call in tool_calls:
                tool_name = call["name"]
                args = call["arguments"]
                logger.info("Tool requested: %s(%s)", tool_name, args)

                # ── Access-control: build allowed_machines after list_machines ──
                if tool_name == "list_machines":
                    result = await self._execute_list_machines(
                        args, token, work_centers, allowed_machines
                    )
                    machine_list_fetched = True

                # ── Access-control: gate machine-scoped tools ──────────────────
                elif tool_name in MACHINE_SCOPED_TOOLS:
                    machine_no = args.get("machine_no", "")

                    # If we haven't fetched the machine list yet, do it now so
                    # we have the authoritative allowed_machines map.
                    if not machine_list_fetched:
                        await self._pre_fetch_machine_list(
                            token, work_centers, allowed_machines
                        )
                        machine_list_fetched = True

                    # Block access if machineNo is not in the user's scope.
                    if machine_no and machine_no not in allowed_machines:
                        logger.warning(
                            "ACCESS DENIED: tool=%s machineNo=%s not in user work centers %s",
                            tool_name,
                            machine_no,
                            work_centers,
                        )
                        result = ToolResult(
                            tool_name=tool_name,
                            success=False,
                            error=(
                                f"Access denied: machine '{machine_no}' is not in your "
                                f"assigned work centers ({', '.join(work_centers)})."
                            ),
                        )
                    else:
                        tool = TOOL_MAP.get(tool_name)
                        if not tool:
                            result = ToolResult(
                                tool_name=tool_name,
                                success=False,
                                error=f"Unknown tool: {tool_name}",
                            )
                        else:
                            result = await tool.execute(**args, token=token)

                            # If BC returned 401, invalidate the AI token and retry once.
                            if not result.success and result.error and "401" in str(result.error):
                                await mes_auth.invalidate()
                                token = await mes_auth.get_token() or token
                                result = await tool.execute(**args, token=token)

                # ── All other tools (no machine_no scoping needed) ─────────────
                else:
                    tool = TOOL_MAP.get(tool_name)
                    if not tool:
                        result = ToolResult(
                            tool_name=tool_name,
                            success=False,
                            error=f"Unknown tool: {tool_name}",
                        )
                    else:
                        result = await tool.execute(**args, token=token)

                        if not result.success and result.error and "401" in str(result.error):
                            await mes_auth.invalidate()
                            token = await mes_auth.get_token() or token
                            result = await tool.execute(**args, token=token)

                all_tool_results.append(result)
                if result.success:
                    tools_called.append(tool_name)

                enriched_data = self._enrich_tool_result(result, all_tool_results)
                messages.append({
                    "role": "tool",
                    "content": json.dumps(enriched_data, default=str),
                })

            if round_i == MAX_TOOL_ROUNDS - 1:
                messages.append({
                    "role": "user",
                    "content": "Based on all the data you have, please give your final answer now.",
                })
                final_message = await self.llm.chat(messages)

        answer_text = final_message.get(
            "content", "I was unable to retrieve the requested information."
        )

        actions = await self._extract_actions(answer_text, all_tool_results)

        return ChatResponse(
            text=answer_text,
            actions=actions,
            data_fetched=tools_called if DEBUG_DATA else [],
        )

    # ── Access-control helpers ─────────────────────────────────────────────────

    async def _execute_list_machines(
        self,
        args: Dict[str, Any],
        token: str,
        user_work_centers: List[str],
        allowed_machines: Dict[str, str],
    ) -> ToolResult:
        """
        Execute list_machines and update the allowed_machines map.

        Only machines belonging to the user's work centers are added to the map,
        regardless of what the LLM passed as work_center_no.  This ensures the
        LLM cannot request machines from departments it has no access to.
        """
        tool = TOOL_MAP["list_machines"]

        # Always enforce the user's work centers at the query level too.
        requested_wc = args.get("work_center_no", "")
        if requested_wc and requested_wc not in user_work_centers and user_work_centers:
            logger.warning(
                "LLM requested list_machines for WC '%s' outside user scope %s — overriding.",
                requested_wc,
                user_work_centers,
            )
            # Fall back to fetching all user work centers.
            args = {**args, "work_center_no": ""}

        result = await tool.execute(**args, token=token)

        if result.success and isinstance(result.data, list):
            # Check for name collisions within the user's scope.
            collision_msg = self._check_name_collisions(
                result.data, user_work_centers, allowed_machines
            )
            if collision_msg:
                # Inject disambiguation request — return a synthetic "error"
                # that the LLM will read and relay to the user.
                return ToolResult(
                    tool_name="list_machines",
                    success=False,
                    data=result.data,       # keep data so caller can still map it
                    error=collision_msg,
                )

        return result

    def _check_name_collisions(
        self,
        machines: List[Dict[str, Any]],
        user_work_centers: List[str],
        allowed_machines: Dict[str, str],
    ) -> Optional[str]:
        """
        Update allowed_machines (machineNo → workCenterNo) restricted to the
        user's work centers.

        Returns a disambiguation message string if two or more machines in the
        user's scope share the same name, otherwise None.
        """
        # Filter to machines in the user's work centers only.
        scoped = [
            m for m in machines
            if not user_work_centers
            or str(m.get("workCenterNo", "")) in user_work_centers
        ]

        # Build / update the allowed set.
        for m in scoped:
            mno = m.get("machineNo") or m.get("no") or ""
            wc  = m.get("workCenterNo") or ""
            if mno:
                allowed_machines[str(mno)] = str(wc)

        # Detect name collisions.
        name_to_machines: Dict[str, List[Dict[str, Any]]] = {}
        for m in scoped:
            name = (m.get("name") or m.get("machineName") or "").strip().lower()
            if name:
                name_to_machines.setdefault(name, []).append(m)

        collisions = {
            name: entries
            for name, entries in name_to_machines.items()
            if len(entries) > 1
        }

        if not collisions:
            return None

        lines = [
            "Multiple machines share the same name in your work centers. "
            "Please clarify which machine you mean:"
        ]
        for name, entries in collisions.items():
            for m in entries:
                mno  = m.get("machineNo") or m.get("no") or "?"
                wc   = m.get("workCenterNo") or "?"
                desc = m.get("name") or m.get("machineName") or name
                lines.append(f'  • "{desc}" — Machine No: {mno}, Work Center: {wc}')

        return "\n".join(lines)

    async def _pre_fetch_machine_list(
        self,
        token: str,
        work_centers: List[str],
        allowed_machines: Dict[str, str],
    ) -> None:
        """
        Silently fetch the machine list to populate allowed_machines before
        enforcing access on a machine-scoped tool call.
        """
        tool = TOOL_MAP["list_machines"]
        for wc in (work_centers or [""]):
            result = await tool.execute(work_center_no=wc, token=token)
            if result.success and isinstance(result.data, list):
                for m in result.data:
                    mno = m.get("machineNo") or m.get("no") or ""
                    wc_no = m.get("workCenterNo") or wc or ""
                    if mno:
                        allowed_machines[str(mno)] = str(wc_no)

    # ── Private helpers ────────────────────────────────────────────────────────

    async def _classify_intent(self, message: str) -> str:
        prompt = INTENT_CLASSIFICATION_PROMPT.format(message=message)
        try:
            intent = await self.llm.simple_completion(prompt)
            return intent.split()[0].lower().strip(".,;:")
        except Exception:
            return "general"

    def _build_system_prompt(self, role: str, work_centers: List[str]) -> str:
        wc_str = ", ".join(work_centers) if work_centers else "all"
        context_block = (
            f"\n\n## Current user\n"
            f"- Role: {role}\n"
            f"- Work centers: {wc_str}\n"
            f"- When the user says 'my machines' or 'my department', "
            f"use these work center numbers.\n"
            f"- IMPORTANT: You may ONLY call tools for machines that belong to "
            f"the work centers listed above.  Never request data for machines "
            f"outside this scope.\n"
        )
        return SYSTEM_PROMPT + context_block

    def _build_messages(
        self, system_content: str, request: ChatRequest
    ) -> List[Dict[str, Any]]:
        messages: List[Dict[str, Any]] = [
            {"role": "system", "content": system_content}
        ]
        for turn in request.conversation_history[-10:]:
            messages.append({"role": turn.role, "content": turn.content})
        messages.append({"role": "user", "content": request.message})
        return messages

    def _enrich_tool_result(
        self,
        result: ToolResult,
        all_results: List[ToolResult],
    ) -> Any:
        if not result.success or result.data is None:
            return {"tool": result.tool_name, "error": result.error}

        data = result.data

        if result.tool_name == "list_machines" and isinstance(data, list):
            summary = summarise_department(data)
            return {
                "tool": result.tool_name,
                "machines": data,
                "department_summary": summary,
            }

        if result.tool_name == "get_machine_orders" and isinstance(data, list):
            enriched = analyse_deadlines(data)
            overdue  = [o for o in enriched if o.get("is_overdue")]
            at_risk  = [o for o in enriched if o.get("risk_level") == "at_risk"]
            return {
                "tool": result.tool_name,
                "orders": enriched,
                "deadline_summary": {
                    "total_orders":    len(enriched),
                    "overdue_count":   len(overdue),
                    "at_risk_count":   len(at_risk),
                    "overdue_orders":  [o.get("orderNo") for o in overdue],
                    "at_risk_orders":  [o.get("orderNo") for o in at_risk],
                },
            }

        if result.tool_name == "get_operation_live_data" and isinstance(data, dict):
            cycles = self._find_cached_data(all_results, "get_production_cycles")
            scrap_analysis = analyse_scrap(live_data=data, production_cycles=cycles)
            velocity = analyse_velocity(data, cycles or [])
            return {
                "tool": result.tool_name,
                "live_data": data,
                "scrap_analysis": scrap_analysis,
                "velocity_analysis": velocity,
            }

        if result.tool_name == "get_production_cycles" and isinstance(data, list):
            live = self._find_cached_data(all_results, "get_operation_live_data")
            scrap_analysis = analyse_scrap(live_data=live, production_cycles=data)
            return {
                "tool": result.tool_name,
                "cycles": data,
                "cycle_count": len(data),
                "scrap_analysis": scrap_analysis,
            }

        if result.tool_name == "get_activity_log" and isinstance(data, list):
            scrap_events = [e for e in data if e.get("type") == "scrap"]
            scrap_analysis = analyse_scrap(activity_logs=data)
            return {
                "tool": result.tool_name,
                "log_entries": data,
                "log_count": len(data),
                "scrap_event_count": len(scrap_events),
                "scrap_analysis": scrap_analysis,
            }

        if result.tool_name == "get_machine_dashboard" and isinstance(data, list):
            total_produced = sum(float(m.get("totalProduced") or 0) for m in data)
            total_scrap    = sum(float(m.get("totalScrap") or 0) for m in data)
            avg_uptime     = (
                sum(float(m.get("uptimePercent") or 0) for m in data) / len(data)
                if data else 0
            )
            denom = total_produced + total_scrap
            return {
                "tool": result.tool_name,
                "machines": data,
                "fleet_summary": {
                    "total_machines":    len(data),
                    "total_produced":    round(total_produced, 2),
                    "total_scrap":       round(total_scrap, 2),
                    "overall_scrap_rate": round(total_scrap / denom, 4) if denom > 0 else 0,
                    "avg_uptime_pct":    round(avg_uptime, 1),
                },
            }

        return {"tool": result.tool_name, "data": data}

    def _find_cached_data(
        self, all_results: List[ToolResult], tool_name: str
    ) -> Optional[Any]:
        for r in all_results:
            if r.tool_name == tool_name and r.success:
                return r.data
        return None

    async def _extract_actions(
        self,
        answer_text: str,
        tool_results: List[ToolResult],
    ) -> List[RedirectAction]:
        data_parts = []
        for r in tool_results:
            if r.success and r.data:
                snippet = json.dumps(r.data, default=str)[:800]
                data_parts.append(f"[{r.tool_name}]: {snippet}")
        data_summary = "\n".join(data_parts) if data_parts else "No data fetched."

        prompt = ACTION_EXTRACTION_PROMPT.format(
            response_text=answer_text,
            data_summary=data_summary,
        )

        try:
            raw = await self.llm.simple_completion(prompt)
            raw = raw.strip()
            if raw.startswith("```"):
                raw = "\n".join(raw.split("\n")[1:])
                raw = raw.rstrip("`").strip()

            actions_data = json.loads(raw)
            if not isinstance(actions_data, list):
                return []

            actions = []
            for item in actions_data:
                try:
                    action = RedirectAction(
                        action_type=item["action_type"],
                        label=item["label"],
                        payload=item.get("payload", {}),
                    )
                    actions.append(action)
                except Exception as e:
                    logger.warning("Skipping malformed action: %s — %s", item, e)

            return actions[:4]

        except json.JSONDecodeError as e:
            logger.warning("Could not parse action extraction response: %s", e)
            return []
        except Exception as e:
            logger.warning("Action extraction failed: %s", e)
            return []