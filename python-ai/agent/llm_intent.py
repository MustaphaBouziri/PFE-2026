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

import asyncio
from itertools import chain
import json
import logging
import re
from typing import Any, Dict, List, Optional, Tuple

import httpx

from agent.intent import (
    Intent,
    ToolChain,
    ToolStep
)

logger = logging.getLogger("mes-ai.llm_intent")

# ── Tool catalogue exposed to the LLM identifier ─────────────────────────────
#
# Kept intentionally terse — the LLM does not need implementation details,
# only argument names so it can fill them correctly.


TOOL_CATALOGUE = """
Available tools (name → required args → description):
  list_machines          | work_center_no: str                                                    | List machines for a work centre and state each machine STATE WORKING or not. Fan-out across all user WCs when no specific WC is needed.
  get_machine_orders     | machine_no: str                                                        | Production order queue for a single machine (not-yet-started ops only).
  get_ongoing_operations | machine_no: str                                                        | Current running/paused operation on a machine.
  get_operation_live_data| machine_no, prod_order_no, operation_no: str                           | Live KPI for a specific operation (progress %, scrap, produced qty).
  get_production_cycles  | machine_no, prod_order_no, operation_no: str                           | Cycle-by-cycle production declarations for an operation.
  get_operations_history | machine_no: str                                                        | Completed/cancelled operations history for a machine.
  get_activity_log       | hours_back: float                                                      | Chronological event log for the floor (status changes, production, scrap, scans).
  get_machine_dashboard  | hours_back: float, work_center_nos: list[str]                          | Per-machine KPI dashboard (uptime %, produced, scrap, ops finished).
  get_production_orders  | status_filter: str, work_center_no: str, machine_no: str               | Production orders; status_filter comma-separated e.g. "Released,Firm Planned"; empty = all.
  get_work_center_summary| work_center_nos: list[str], hours_back: float                          | Per-WC summary: machine counts, running ops, assigned operators, produced qty, scrap.
  get_operator_summary   | work_center_nos: list[str], hours_back: float                          | Per-operator summary: login status, machine assignment, produced qty, scrap, op counts.
  get_my_data            | hours_back: float                                                      | Personal data for the authenticated user: their ops, produced qty, scrap.
  get_scrap_summary      | hours_back: float, prod_order_no: str, operation_no: str, machine_no: str, work_center_no: str, operator_id: str | Scrap records with optional filters; any filter empty = all.
  get_delay_report       | work_center_nos: list[str], pause_threshold_minutes: float             | Overdue and abnormally-paused operations ranked by delay severity.
  get_consumption_summary| prod_order_no: str, operation_no: str, machine_no: str, hours_back: float | Component consumption vs planned BOM qty; flags over/under consumption.
  get_supervisor_overview| work_center_nos: list[str], hours_back: float, pause_threshold_minutes: float | Comprehensive shift overview: stopped machines, idle operators, high-scrap ops, delays.
  get_bom                | prod_order_no: str, operation_no: str                                  | Bill of materials / component list with scan progress.

Intent → tool mapping guidance:
  machine_status       → get_ongoing_operations
  machine_orders       → get_machine_orders
  machine_live         → get_ongoing_operations + get_operation_live_data [+ get_production_cycles if scrap/velocity asked]
  machine_history      → get_operations_history
  machine_dashboard    → get_machine_dashboard [+ list_machines if no specific machine]
  department_overview  → list_machines (fan-out)
  activity_log         → get_activity_log
  scrap_analysis       → get_scrap_summary (preferred over activity_log for scrap questions)
  work_center_summary  → get_work_center_summary
  operator_summary     → get_operator_summary
  supervisor_overview  → get_supervisor_overview  (use when: "what should I check", "shift briefing", "what's wrong on the floor")
  delay_report         → get_delay_report  (use when: "overdue", "delayed", "blocked", "late orders")
  production_orders    → get_production_orders  (use when: "list orders", "order status", "released orders")
  my_data              → get_my_data  (use when: "my production", "what did I do", "my shift")
  consumption_summary  → get_consumption_summary  (use when: "material usage", "component consumption", "BOM variance")
  operation_live       → get_ongoing_operations + get_operation_live_data (specific order+op, not just machine)
  operation_bom        → get_bom [preceded by get_ongoing_operations if order/op not known]
  production_cycles    → get_production_cycles [preceded by get_ongoing_operations if order/op not known]
  general              → (no tools — LLM answers from general knowledge)

Slot references (resolved at runtime):
  Use "$<result_key>[0].<field>" to reference a prior step's output.
  Examples:
    "$ongoing[0].prodOrderNo"  — prod order no from get_ongoing_operations
    "$ongoing[0].operationNo"  — operation no from get_ongoing_operations
    "$ongoing[0].executionId"  — execution id from get_ongoing_operations
"""

# ── Intent labels (must match Intent enum values) ────────────────────────────

INTENT_LABELS = [
    # Machine-level
    "machine_status",
    "machine_orders",
    "machine_live",
    "machine_history",
    "machine_dashboard",
    # Department / floor
    "department_overview",
    "activity_log",
    "scrap_analysis",
    "work_center_summary",
    "operator_summary",
    "supervisor_overview",
    "delay_report",
    # Operation-level
    "operation_live",
    "operation_bom",
    "production_cycles",
    "consumption_summary",
    # Orders / personal
    "production_orders",
    "my_data",
    # Fallback
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
2. Choose the minimum set of tools needed. Never add a tool "just in case".
3. Use slot references ("$key[0].field") to chain steps when a later step
   needs output from an earlier one.
4. If the question involves MULTIPLE machines or "all machines / every machine /
   which machines", set "is_composite": true and include list_machines with
   fan_out_work_centers: true.
5. If the question is general and needs no MES data, return an empty steps array
   and use intent "general".
6. result_key must be a unique snake_case identifier per step.
7. Choose intent from EXACTLY this list (no other values are valid):
   {", ".join(INTENT_LABELS)}
8. For supervisor/manager queries ("what should I focus on", "shift overview",
   "what's wrong"), prefer supervisor_overview over combining multiple tools.
9. For personal queries ("my production", "what did I do today"), use my_data.
10. For scrap questions without a specific machine, use get_scrap_summary not
    get_activity_log.
11. If the user refers to a machine by a non-canonical name or partial name
    (e.g. "bruno", "the milling machine", "MC 1", "machine 42"),
    set "unresolved_machine_ref" to that raw string in the JSON output, and use
    the placeholder "__RESOLVE__" as the machine_no value in the step args.
    Do NOT invent or guess the canonical machine ID.
    Example: user says "history of machine bruno"
      → args: {{"machine_no": "__RESOLVE__"}}, unresolved_machine_ref: "bruno"

Output schema:
{{
  "intent": "<intent_label>",
  "description": "<one-line human summary>",
  "is_composite": false,
  "unresolved_machine_ref": "<raw user string or null>",
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

Common mistakes to avoid:
- Do NOT invent tool names. Only use names from the tool list above.
- Do NOT omit result_key on any step.
- Do NOT use duplicate result_key values.
- Do NOT wrap the JSON in markdown code fences.
- Do NOT add fields not in the schema.
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
        unresolved_machine_ref=plan.get("unresolved_machine_ref") or None,  # ADD THIS
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
        Attempt 1: ask the LLM for a JSON plan.
        Attempt 2: if attempt 1 fails, retry with the error injected into the prompt.
        If both fail: return a GENERAL intent with empty steps (no regex fallback).
        """
        thinking = ThinkingBlock(message=message)

        # ── Attempt 1 ────────────────────────────────────────────────────────
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
                {
                    "tool": s.tool,
                    "args": s.args,
                    "result_key": s.result_key,
                    "fan_out_work_centers": s.fan_out_work_centers,
                }
                for s in chain.steps
            ]
            thinking.retry_used = False
            logger.info(
                "LLM intent: %s | steps=%d | composite=%s",
                chain.intent, len(chain.steps), chain.is_composite,
            )
            return chain, thinking
        except httpx.HTTPStatusError as exc1:
            # Provider-level error — retry won't help for 5xx
            if exc1.response.status_code >= 500:
                logger.error("LLM provider 5xx (%s) — skipping retry", exc1.response.status_code)
                thinking.attempt1_error = str(exc1)
                thinking.method = "both_failed"
                thinking.fallback_used = True
                thinking.fallback_reason = f"Provider 5xx: {exc1}"
                chain = ToolChain(intent=Intent.GENERAL, steps=[], 
                                description="Provider unavailable", is_composite=False)
                thinking.intent = chain.intent.value
                return chain, thinking
        except Exception as exc1:
            logger.warning(
                "LLM intent attempt 1 failed (%s) — retrying with error context", exc1
            )
            thinking.attempt1_error = str(exc1)
        await asyncio.sleep(1.0)   
            

        # ── Attempt 2 — retry with error context ─────────────────────────────
        try:
            chain, raw_plan, raw_text = await self._llm_classify_retry(
                message, role, work_centers, error_hint=thinking.attempt1_error
            )
            thinking.method = "llm_retry"
            thinking.raw_response = raw_text
            thinking.parsed_plan = raw_plan
            thinking.reasoning = raw_plan.get("reasoning", "")
            thinking.intent = chain.intent.value
            thinking.steps = [
                {
                    "tool": s.tool,
                    "args": s.args,
                    "result_key": s.result_key,
                    "fan_out_work_centers": s.fan_out_work_centers,
                }
                for s in chain.steps
            ]
            thinking.retry_used = True
            logger.info(
                "LLM intent (retry): %s | steps=%d | composite=%s",
                chain.intent, len(chain.steps), chain.is_composite,
            )
            return chain, thinking

        except Exception as exc2:
            logger.error(
                "LLM intent both attempts failed. Attempt1=%s | Attempt2=%s",
                thinking.attempt1_error, exc2,
            )
            thinking.method = "both_failed"
            thinking.retry_used = True
            thinking.fallback_used = True
            thinking.fallback_reason = (
                f"Attempt 1: {thinking.attempt1_error} | Attempt 2: {exc2}"
            )
            # Return GENERAL with no steps — orchestrator will call LLM for
            # a plain-text answer with no data context.
            chain = ToolChain(
                intent=Intent.GENERAL,
                steps=[],
                description="Intent classification failed after two attempts",
                is_composite=False,
            )
            thinking.intent = chain.intent.value
            thinking.steps = []
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

 
    async def _llm_classify_retry(
        self,
        message: str,
        role: str,
        work_centers: List[str],
        error_hint: str,
    ) -> Tuple[ToolChain, Dict[str, Any], str]:
        """
        Second attempt at LLM classification.
        Injects the previous failure reason so the model can self-correct.
        The system prompt is unchanged; only the user turn is modified.
        Raises on any failure — caller handles the fallback to GENERAL.
        """
        wc_str = ", ".join(work_centers) if work_centers else "all"
        original_user = _IDENTIFIER_USER_TEMPLATE.format(
            message=message,
            role=role,
            work_centers=wc_str,
        )
        retry_instruction = (
            f"Your previous response could not be used because of this error:\n"
            f"  {error_hint}\n\n"
            f"Common causes and fixes:\n"
            f"  - Invalid JSON → ensure the output is a single JSON object, "
            f"no markdown fences, no trailing commas.\n"
            f"  - Unknown tool name → only use tool names listed in the catalogue.\n"
            f"  - Missing result_key → every step must have a non-empty, "
            f"unique snake_case result_key.\n"
            f"  - Unknown intent → intent must be one of the exact labels listed.\n\n"
            f"Produce the corrected JSON plan now. Output ONLY the JSON object."
        )
        messages = [
            {"role": "system",    "content": _IDENTIFIER_SYSTEM},
            {"role": "user",      "content": original_user},
            # Simulate the bad assistant turn so the model sees what went wrong
            {"role": "assistant", "content": "(previous response contained an error)"},
            {"role": "user",      "content": retry_instruction},
        ]

        raw_text = await self.llm.complete(messages)
        if not raw_text:
            raise ValueError("LLM returned empty response on retry")

        clean = _strip_json_fences(raw_text)
        try:
            plan = json.loads(clean)
        except json.JSONDecodeError as e:
            raise ValueError(
                f"Retry produced invalid JSON: {e}\nRaw: {raw_text[:300]}"
            )

        errors = _validate_plan(plan)
        if errors:
            raise ValueError(f"Retry plan still invalid: {errors}\nPlan: {plan}")

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
        self.retry_used: bool = False
        self.attempt1_error: str = ""

    def to_dict(self) -> Dict[str, Any]:
        d: Dict[str, Any] = {
            "classifier": self.method,
            "intent": self.intent,
            "fallback_used": self.fallback_used,
            "retry_used": self.retry_used,
            "steps_planned": self.steps,
        }
        if self.reasoning:
            d["reasoning"] = self.reasoning
        if self.attempt1_error:
            d["attempt1_error"] = self.attempt1_error
        if self.fallback_used and self.fallback_reason:
            d["fallback_reason"] = self.fallback_reason
        return d