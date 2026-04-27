"""
agent/llm_intent.py — LLM-based intent classification and tool-chain planning.

This module is the PRIMARY classifier.  It calls the LLM with a structured
prompt to produce a ToolChain JSON, then validates and converts it to the
same ToolChain dataclass used everywhere.

Fallback strategy
─────────────────
If the LLM call fails (timeout, bad JSON, invalid tool names, etc.) the
orchestrator falls back to the deterministic regex classifier in intent.py.

The LLM classification result — including the raw reasoning — is attached to
ChatResponse.thinking so operators / developers can inspect what the model
decided WITHOUT the user seeing it in the chat text.

Architecture
────────────
┌──────────────────────────────────────────────────┐
│  User message                                    │
│       ↓                                          │
│  LLM Identifier (this module)                    │
│       │  success → ToolChain                     │
│       │  failure ↓                               │
│  Regex Classifier (intent.py) → ToolChain        │
│       ↓                                          │
│  Orchestrator executes chain                     │
│       ↓                                          │
│  LLM Synthesiser (one call, existing)            │
└──────────────────────────────────────────────────┘

The identifier and the synthesiser are two separate LLM calls with distinct
purposes and system prompts.  The identifier ONLY produces a structured plan;
it never writes user-visible text.
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any, Dict, List, Optional, Tuple

from agent.intent import (
    Intent,
    ToolChain,
    ToolStep,
    classify as regex_classify,
)

logger = logging.getLogger("mes-ai.llm_intent")

# ── Tool catalogue exposed to the LLM identifier ─────────────────────────────
#
# Kept intentionally terse — the LLM does not need implementation details,
# only argument names so it can fill them correctly.

TOOL_CATALOGUE = """
Available tools (name → required args → description):
  list_machines         | work_center_no: str          | List machines for a work centre. Fan-out across all user WCs when no specific WC is needed.
  get_machine_orders    | machine_no: str               | Production order queue for a machine.
  get_ongoing_operations| machine_no: str               | Current/live operation on a machine.
  get_operation_live_data| machine_no, prod_order_no, operation_no: str | Live KPI data for a specific operation.
  get_production_cycles | machine_no, prod_order_no, operation_no: str | Cycle declarations for an operation.
  get_operations_history| machine_no: str               | Completed operations history for a machine.
  get_activity_log      | hours_back: float             | Activity / event log for the floor (last N hours).
  get_machine_dashboard | hours_back: float, work_center_nos: list[str] | KPI dashboard covering multiple machines.
  get_production_orders | status_filter, work_center_no, machine_no: str | Production orders with optional status, work centre, or machine filters.
  get_work_center_summary| work_center_nos: list[str], hours_back: float | Per-work-centre summary for machines, queues, operators, production, and scrap.
  get_operator_summary  | work_center_nos: list[str], hours_back: float | Operator activity, machine assignment, produced quantity, scrap, and operation counts.
  get_my_data           | hours_back: float             | Data scoped to the authenticated user: operations, production, scrap, and machine interactions.
  get_scrap_summary     | hours_back: float, prod_order_no, operation_no, machine_no, work_center_no, operator_id: str | Scrap records and totals with optional filters.
  get_delay_report      | work_center_nos: list[str], pause_threshold_minutes: float | Delayed and blocked operations ranked by delay severity.
  get_consumption_summary| prod_order_no, operation_no, machine_no: str, hours_back: float | Component consumption versus planned BOM quantity.
  get_supervisor_overview| work_center_nos: list[str], hours_back: float, pause_threshold_minutes: float | Supervisor overview of stopped machines, long pauses, idle operators, high scrap, delays, and totals.
  get_bom               | prod_order_no, operation_no: str | Bill of materials / component list.

Slot references (resolved at runtime):
  Use "$<result_key>[0].<field>" to reference data from a prior step.
  Examples:
    "$ongoing[0].prodOrderNo"  — prod order no from get_ongoing_operations result
    "$ongoing[0].operationNo"  — operation no from get_ongoing_operations result
    "$ongoing[0].executionId"  — execution id from get_ongoing_operations result
"""

# ── Intent labels (must match Intent enum values) ────────────────────────────

INTENT_LABELS = [
    "machine_status",
    "machine_orders",
    "machine_live",
    "machine_history",
    "machine_dashboard",
    "department_overview",
    "activity_log",
    "scrap_analysis",
    "operation_live",
    "operation_bom",
    "production_cycles",
    "general",
]

# ── Identifier system prompt ──────────────────────────────────────────────────

_IDENTIFIER_SYSTEM = f"""\
You are a Manufacturing Execution System (MES) query planner.
Your ONLY job is to analyse the user's question and output a JSON plan
describing which tools to call to answer it.

{TOOL_CATALOGUE}

Rules:
1. Output ONLY a valid JSON object — no prose, no markdown fences, no explanation.
2. Choose the minimum set of tools needed.
3. Use slot references ("$key[0].field") to chain steps when a later step
   needs output from an earlier one.
4. If the question involves MULTIPLE machines or "all machines / every machine /
   which machines", set "is_composite": true and include list_machines with
   fan_out_work_centers: true.
5. If the question is general and needs no MES data, return an empty steps array.
6. result_key must be a unique snake_case identifier per step.
7. Choose intent from this exact list:
   {", ".join(INTENT_LABELS)}

Output schema:
{{
  "intent": "<intent_label>",
  "description": "<one-line human summary>",
  "is_composite": false,
  "steps": [
    {{
      "tool": "<tool_name>",
      "args": {{ "<arg>": "<value_or_slot_ref>" }},
      "result_key": "<snake_case_key>",
      "fan_out_work_centers": false
    }}
  ],
  "reasoning": "<brief explanation of why you chose these tools>"
}}
"""

_IDENTIFIER_USER_TEMPLATE = """\
User question: {message}

User context:
  Role: {role}
  Work centres: {work_centers}

Produce the JSON plan now.
"""

# ── Validation helpers ────────────────────────────────────────────────────────

_VALID_TOOLS = {
    "list_machines",
    "get_machine_orders",
    "get_ongoing_operations",
    "get_operation_live_data",
    "get_production_cycles",
    "get_operations_history",
    "get_activity_log",
    "get_machine_dashboard",
    "get_production_orders",
    "get_work_center_summary",
    "get_operator_summary",
    "get_my_data",
    "get_scrap_summary",
    "get_delay_report",
    "get_consumption_summary",
    "get_supervisor_overview",
    "get_bom",
}

_INTENT_MAP: Dict[str, Intent] = {i.value: i for i in Intent}


def _strip_json_fences(text: str) -> str:
    """Remove ```json … ``` or ``` … ``` wrappers if present."""
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.I)
    text = re.sub(r"\s*```$", "", text)
    return text.strip()


def _validate_plan(plan: Dict[str, Any]) -> List[str]:
    """
    Return a list of validation errors.  Empty list = plan is valid.
    """
    errors: List[str] = []

    intent_str = plan.get("intent", "")
    if intent_str not in _INTENT_MAP:
        errors.append(f"Unknown intent '{intent_str}'")

    steps = plan.get("steps", [])
    if not isinstance(steps, list):
        errors.append("'steps' must be a list")
        return errors

    seen_keys: set = set()
    for i, step in enumerate(steps):
        tool = step.get("tool", "")
        if tool not in _VALID_TOOLS:
            errors.append(f"Step {i}: unknown tool '{tool}'")
        rk = step.get("result_key", "")
        if not rk:
            errors.append(f"Step {i}: missing result_key")
        elif rk in seen_keys:
            errors.append(f"Step {i}: duplicate result_key '{rk}'")
        else:
            seen_keys.add(rk)

    return errors


def _plan_to_tool_chain(plan: Dict[str, Any]) -> ToolChain:
    """Convert a validated LLM plan dict to a ToolChain dataclass."""
    intent_str = plan.get("intent", "general")
    intent = _INTENT_MAP.get(intent_str, Intent.GENERAL)

    steps = []
    for s in plan.get("steps", []):
        steps.append(ToolStep(
            tool=s["tool"],
            args=s.get("args", {}),
            result_key=s.get("result_key", ""),
            fan_out_work_centers=bool(s.get("fan_out_work_centers", False)),
        ))

    return ToolChain(
        intent=intent,
        steps=steps,
        description=plan.get("description", ""),
        is_composite=bool(plan.get("is_composite", False)),
    )


# ── Public API ────────────────────────────────────────────────────────────────

class LLMIntentIdentifier:
    """
    Uses the LLM to classify intent and plan tool calls.

    Usage:
        identifier = LLMIntentIdentifier(llm_client)
        chain, thinking = await identifier.classify(message, role, work_centers)

    Returns:
        chain    — ToolChain (from LLM or fallback)
        thinking — ThinkingBlock with full internal reasoning for ChatResponse.thinking
    """

    def __init__(self, llm_client: Any) -> None:
        self.llm = llm_client

    async def classify(
        self,
        message: str,
        role: str,
        work_centers: List[str],
    ) -> Tuple[ToolChain, "ThinkingBlock"]:
        """
        Primary: ask LLM for a JSON plan.
        Fallback: use regex classifier from intent.py.
        """
        thinking = ThinkingBlock(message=message)

        try:
            chain, raw_plan, raw_text = await self._llm_classify(
                message, role, work_centers
            )
            thinking.method = "llm"
            thinking.raw_response = raw_text
            thinking.parsed_plan = raw_plan
            thinking.reasoning = raw_plan.get("reasoning", "")
            thinking.intent = chain.intent.value
            thinking.steps = [
                {"tool": s.tool, "args": s.args, "result_key": s.result_key,
                 "fan_out_work_centers": s.fan_out_work_centers}
                for s in chain.steps
            ]
            thinking.fallback_used = False
            logger.info(
                "LLM intent: %s | steps=%d | composite=%s",
                chain.intent, len(chain.steps), chain.is_composite,
            )
            return chain, thinking

        except Exception as exc:
            logger.warning(
                "LLM intent identification failed (%s) — falling back to regex", exc
            )
            thinking.fallback_used = True
            thinking.fallback_reason = str(exc)

            chain = regex_classify(message, work_centers)
            thinking.method = "regex_fallback"
            thinking.intent = chain.intent.value
            thinking.steps = [
                {"tool": s.tool, "args": s.args, "result_key": s.result_key,
                 "fan_out_work_centers": s.fan_out_work_centers}
                for s in chain.steps
            ]
            logger.info(
                "Regex fallback intent: %s | steps=%d", chain.intent, len(chain.steps)
            )
            return chain, thinking

    async def _llm_classify(
        self,
        message: str,
        role: str,
        work_centers: List[str],
    ) -> Tuple[ToolChain, Dict[str, Any], str]:
        """
        Call the LLM and parse/validate the JSON plan.
        Raises on any failure so the caller can fall back to regex.
        """
        wc_str = ", ".join(work_centers) if work_centers else "all"
        user_msg = _IDENTIFIER_USER_TEMPLATE.format(
            message=message,
            role=role,
            work_centers=wc_str,
        )
        messages = [
            {"role": "system", "content": _IDENTIFIER_SYSTEM},
            {"role": "user",   "content": user_msg},
        ]

        raw_text = await self.llm.complete(messages)
        if not raw_text:
            raise ValueError("LLM returned empty response")

        clean = _strip_json_fences(raw_text)
        try:
            plan = json.loads(clean)
        except json.JSONDecodeError as e:
            raise ValueError(f"LLM returned invalid JSON: {e}\nRaw: {raw_text[:300]}")

        errors = _validate_plan(plan)
        if errors:
            raise ValueError(f"LLM plan validation failed: {errors}\nPlan: {plan}")

        chain = _plan_to_tool_chain(plan)
        return chain, plan, raw_text


# ── ThinkingBlock ─────────────────────────────────────────────────────────────

class ThinkingBlock:
    """
    Internal reasoning and tool-selection trace for a single request.
    Serialised into ChatResponse.thinking — never shown in the chat text.
    """

    def __init__(self, message: str) -> None:
        self.message: str = message
        self.method: str = ""               # "llm" | "regex_fallback"
        self.intent: str = ""
        self.steps: List[Dict] = []
        self.reasoning: str = ""
        self.raw_response: str = ""
        self.parsed_plan: Dict = {}
        self.fallback_used: bool = False
        self.fallback_reason: str = ""

    def to_dict(self) -> Dict[str, Any]:
        d: Dict[str, Any] = {
            "classifier": self.method,
            "intent": self.intent,
            "fallback_used": self.fallback_used,
            "steps_planned": self.steps,
        }
        if self.reasoning:
            d["reasoning"] = self.reasoning
        if self.fallback_used and self.fallback_reason:
            d["fallback_reason"] = self.fallback_reason
        return d