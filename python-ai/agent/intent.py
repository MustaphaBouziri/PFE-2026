"""
agent/intent.py — tool-chain planning.

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
    
    WORK_CENTER_SUMMARY  = "work_center_summary"
    OPERATOR_SUMMARY     = "operator_summary"
    SUPERVISOR_OVERVIEW  = "supervisor_overview"

    # Personal
    MY_DATA              = "my_data"

    # Orders / delays / consumption
    PRODUCTION_ORDERS    = "production_orders"
    DELAY_REPORT         = "delay_report"
    CONSUMPTION_SUMMARY  = "consumption_summary"

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
