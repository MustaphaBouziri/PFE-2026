"""
tools/mes_tools.py

Each tool:
  - Has a JSON schema definition (fed to Ollama as tool spec)
  - Has an async `execute(**kwargs)` method that calls the Node middleware
  - Returns a ToolResult

Tools are designed to be COMPOSABLE — the orchestrator can chain them:
  e.g.  get_machine_state(machine_name) needs:
          1. list_machines(work_center)  → find machineNo
          2. get_ongoing_operations(machineNo)  → find executionId
          3. get_operation_live_data(machineNo, prodOrderNo, operationNo)

BUG FIXES vs original:
  - _post() was prepending "MESWebService_" to the path before calling the Node
    middleware. The Node proxy's buildTargetUrl() already maps bare endpoint
    names (e.g. "FetchMachines") to webServiceBase URLs, so the prefix must NOT
    be included here.  Calling /api/FetchMachines is correct; calling
    /api/MESWebService_FetchMachines caused the fallback branch to fire and hit
    BC_HOST directly without authentication mapping.
  - All `import json` statements moved to module level (were repeated inline in
    every execute() method).
"""

from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

import httpx

from agent.config import MIDDLEWARE_BASE_URL, TOOL_HTTP_TIMEOUT, COMPANY_ID
from agent.models import ToolResult

logger = logging.getLogger("mes-ai.tools")


# ── HTTP helper ────────────────────────────────────────────────────────────────

async def _post(path: str, body: Dict[str, Any], token: str = "") -> Dict[str, Any]:
    """
    POST to the Node middleware which forwards to BC.

    FIX: URL is now /api/<endpoint> — the Node proxy's buildTargetUrl() maps
    this to webServiceBase + endpoint automatically.  The old code incorrectly
    called /api/MESWebService_<endpoint> which bypassed that mapping.
    """
    url = f"{MIDDLEWARE_BASE_URL}/{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["X-Auth-Token"] = token

    async with httpx.AsyncClient(timeout=TOOL_HTTP_TIMEOUT) as client:
        resp = await client.post(url, json=body, headers=headers)
        resp.raise_for_status()
        return resp.json()


# ── Individual tools ───────────────────────────────────────────────────────────

class ListMachinesTool:
    name = "list_machines"
    description = (
        "List all machines in one or more work centers with their current status "
        "(Idle/Working) and active order number. Use this to resolve a machine name "
        "to its machineNo, or to get an overview of a department."
    )
    parameters = {
        "type": "object",
        "properties": {
            "work_center_no": {
                "type": "string",
                "description": (
                    "Work center number (e.g. '100'). "
                    "Pass empty string to fetch all user work centers."
                ),
            }
        },
        "required": ["work_center_no"],
    }

    async def execute(self, work_center_no: str, token: str = "") -> ToolResult:
        try:
            data = await _post("FetchMachines", {"workCenterNo": work_center_no}, token)
            machines = data.get("value", [])
            if isinstance(machines, str):
                machines = json.loads(machines)
            return ToolResult(tool_name=self.name, success=True, data=machines)
        except Exception as e:
            logger.warning("list_machines failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetMachineOrdersTool:
    name = "get_machine_orders"
    description = (
        "Get all production orders assigned to a specific machine "
        "(Released, Planned, FirmPlanned). Includes item description, "
        "planned quantities, planned start/end dates."
    )
    parameters = {
        "type": "object",
        "properties": {
            "machine_no": {
                "type": "string",
                "description": "The machine identifier, e.g. 'MC-001'.",
            }
        },
        "required": ["machine_no"],
    }

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        try:
            data = await _post("getMachineOrders", {"machineNo": machine_no}, token)
            orders = data.get("value", [])
            if isinstance(orders, str):
                orders = json.loads(orders)
            return ToolResult(tool_name=self.name, success=True, data=orders)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOngoingOperationsTool:
    name = "get_ongoing_operations"
    description = (
        "Get the currently running or paused operations on a machine. "
        "Returns operation status, progress percent, produced qty, scrap qty, "
        "order quantity and execution ID. Use this to find what's happening NOW on a machine."
    )
    parameters = {
        "type": "object",
        "properties": {
            "machine_no": {
                "type": "string",
                "description": "Machine identifier.",
            }
        },
        "required": ["machine_no"],
    }

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        try:
            data = await _post("fetchOngoingOperationsState", {"machineNo": machine_no}, token)
            ops = data.get("value", [])
            if isinstance(ops, str):
                ops = json.loads(ops)
            return ToolResult(tool_name=self.name, success=True, data=ops)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOperationLiveDataTool:
    name = "get_operation_live_data"
    description = (
        "Get real-time live data for a specific operation: produced quantity, "
        "scrap quantity, progress percent, current status, execution ID. "
        "Use after get_ongoing_operations to drill into a specific operation."
    )
    parameters = {
        "type": "object",
        "properties": {
            "machine_no": {"type": "string"},
            "prod_order_no": {"type": "string", "description": "Production order number."},
            "operation_no": {"type": "string", "description": "Operation number, e.g. '10'."},
        },
        "required": ["machine_no", "prod_order_no", "operation_no"],
    }

    async def execute(
        self, machine_no: str, prod_order_no: str, operation_no: str, token: str = ""
    ) -> ToolResult:
        try:
            data = await _post(
                "fetchOperationLiveData",
                {
                    "machineNo": machine_no,
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                },
                token,
            )
            items = data.get("value", [])
            if isinstance(items, str):
                items = json.loads(items)
            live = items[0] if items else {}
            return ToolResult(tool_name=self.name, success=True, data=live)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetProductionCyclesTool:
    name = "get_production_cycles"
    description = (
        "Get the production cycle history for an operation: each declaration "
        "with cycle quantity, total produced so far, operator name, and timestamp. "
        "Use to detect production spikes, slowdowns, or operator patterns."
    )
    parameters = {
        "type": "object",
        "properties": {
            "machine_no": {"type": "string"},
            "prod_order_no": {"type": "string"},
            "operation_no": {"type": "string"},
        },
        "required": ["machine_no", "prod_order_no", "operation_no"],
    }

    async def execute(
        self, machine_no: str, prod_order_no: str, operation_no: str, token: str = ""
    ) -> ToolResult:
        try:
            data = await _post(
                "fetchProductionCycles",
                {
                    "machineNo": machine_no,
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                },
                token,
            )
            cycles = data.get("value", [])
            if isinstance(cycles, str):
                cycles = json.loads(cycles)
            return ToolResult(tool_name=self.name, success=True, data=cycles)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOperationsHistoryTool:
    name = "get_operations_history"
    description = (
        "Get finished and cancelled operations on a machine. "
        "Includes start/end times, produced quantities. "
        "Use to analyse historical performance or find a specific completed operation."
    )
    parameters = {
        "type": "object",
        "properties": {
            "machine_no": {"type": "string"},
        },
        "required": ["machine_no"],
    }

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        try:
            data = await _post("fetchOperationsHistory", {"machineNo": machine_no}, token)
            ops = data.get("value", [])
            if isinstance(ops, str):
                ops = json.loads(ops)
            return ToolResult(tool_name=self.name, success=True, data=ops)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetActivityLogTool:
    name = "get_activity_log"
    description = (
        "Fetch the activity log for the last N hours. Returns state changes, "
        "production declarations, scrap events, and scan events across all machines. "
        "Use to detect scrap spikes, anomalies, or recent operator activity."
    )
    parameters = {
        "type": "object",
        "properties": {
            "hours_back": {
                "type": "number",
                "description": (
                    "How many hours back to fetch. "
                    "Use 1 for recent, 24 for today, 168 for this week."
                ),
            }
        },
        "required": ["hours_back"],
    }

    async def execute(self, hours_back: float, token: str = "") -> ToolResult:
        try:
            data = await _post("fetchActivityLog", {"hoursBack": hours_back}, token)
            logs = data.get("value", [])
            if isinstance(logs, str):
                logs = json.loads(logs)
            return ToolResult(tool_name=self.name, success=True, data=logs)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetMachineDashboardTool:
    name = "get_machine_dashboard"
    description = (
        "Get aggregated dashboard stats for machines: operation count, uptime %, "
        "total produced, total scrap, for a given time window. "
        "Use for department-level overview or KPI questions."
    )
    parameters = {
        "type": "object",
        "properties": {
            "hours_back": {"type": "number", "description": "Time window in hours."},
            "work_center_nos": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of work center numbers to include.",
            },
        },
        "required": ["hours_back", "work_center_nos"],
    }

    async def execute(
        self, hours_back: float, work_center_nos: List[str], token: str = ""
    ) -> ToolResult:
        try:
            data = await _post(
                "fetchMachineDashboard",
                {
                    "hoursBack": hours_back,
                    "workCenterNoJson": json.dumps(work_center_nos),
                },
                token,
            )
            machines = data.get("value", [])
            if isinstance(machines, str):
                machines = json.loads(machines)
            return ToolResult(tool_name=self.name, success=True, data=machines)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetBomTool:
    name = "get_bom"
    description = (
        "Get the Bill of Materials (components) for an operation: "
        "each component's required quantity, scanned quantity, remaining quantity, scrap. "
        "Use to detect missing or low-stock components."
    )
    parameters = {
        "type": "object",
        "properties": {
            "prod_order_no": {"type": "string"},
            "operation_no": {"type": "string"},
        },
        "required": ["prod_order_no", "operation_no"],
    }

    async def execute(self, prod_order_no: str, operation_no: str, token: str = "") -> ToolResult:
        try:
            data = await _post(
                "fetchBom",
                {"prodOrderNo": prod_order_no, "operationNo": operation_no},
                token,
            )
            bom = data.get("value", [])
            if isinstance(bom, str):
                bom = json.loads(bom)
            return ToolResult(tool_name=self.name, success=True, data=bom)
        except Exception as e:
            return ToolResult(tool_name=self.name, success=False, error=str(e))


# ── Tool registry ──────────────────────────────────────────────────────────────

ALL_TOOLS = [
    ListMachinesTool(),
    GetMachineOrdersTool(),
    GetOngoingOperationsTool(),
    GetOperationLiveDataTool(),
    GetProductionCyclesTool(),
    GetOperationsHistoryTool(),
    GetActivityLogTool(),
    GetMachineDashboardTool(),
    GetBomTool(),
]

TOOL_MAP = {t.name: t for t in ALL_TOOLS}

# Tools that accept a machine_no argument and therefore need access-control checks.
MACHINE_SCOPED_TOOLS = {
    "get_machine_orders",
    "get_ongoing_operations",
    "get_operation_live_data",
    "get_production_cycles",
    "get_operations_history",
}


def get_tool_schemas() -> List[Dict[str, Any]]:
    """Return Ollama-compatible tool definitions for all tools."""
    return [
        {
            "type": "function",
            "function": {
                "name": t.name,
                "description": t.description,
                "parameters": t.parameters,
            },
        }
        for t in ALL_TOOLS
    ]