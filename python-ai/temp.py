"""
tools/mes_tools.py

Each class wraps one BC web service endpoint.

All calls go to the Node middleware, which handles SSPI auth to BC.
URL path matches the endpoint name exactly — the Node proxy's buildTargetUrl()
maps /api/<name> to the correct BC web service URL.

IMPORTANT: BC OData maps POST body JSON keys to AL procedure parameter names
case-sensitively. Every key here must match the AL parameter name exactly.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

import httpx

from agent.config import MIDDLEWARE_BASE_URL, TOOL_HTTP_TIMEOUT
from agent.models import ToolResult

logger = logging.getLogger("mes-ai.tools")


# ── HTTP helpers ──────────────────────────────────────────────────────────────

async def _post(endpoint: str, body: Dict[str, Any], token: str = "") -> Any:
    """POST to /api/<endpoint> on the Node middleware."""
    url = f"{MIDDLEWARE_BASE_URL}/{endpoint}"
    headers: Dict[str, str] = {"Content-Type": "application/json"}

    async with httpx.AsyncClient(timeout=TOOL_HTTP_TIMEOUT) as client:
        resp = await client.post(url, json=body, headers=headers)
        resp.raise_for_status()
        return resp.json()


def _extract_value(raw: Any) -> Any:
    """
    BC web services wrap arrays in {"value": [...]} or return the JSON
    string directly.  Normalise to the inner list/dict.
    """
    if isinstance(raw, dict) and "value" in raw:
        v = raw["value"]
        if isinstance(v, str):
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return v
        return v
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw
    return raw


# ── Tool classes ──────────────────────────────────────────────────────────────

class ListMachinesTool:
    name = "list_machines"

    async def execute(self, work_center_no: str, token: str = "") -> ToolResult:
        """
        AL signature: FetchMachines(workCenterNoJson: Text)
        The AL procedure parses workCenterNoJson as a JSON object and reads
        the 'workCenterNos' key from it — so the value must be a JSON-encoded
        object string, not a bare array.
        """
        try:
            raw = await _post(
                "FetchMachines",
                {
                    "workCenterNoJson": json.dumps({"workCenterNos": [work_center_no]})
                },
            )
            machines = _extract_value(raw)
            if not isinstance(machines, list):
                machines = []
            return ToolResult(tool_name=self.name, success=True, data=machines)
        except Exception as e:
            logger.warning("list_machines(wc=%s) failed: %s", work_center_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetMachineOrdersTool:
    name = "get_machine_orders"

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        """
        AL signature: getMachineOrders(machineNo: Text)
        """
        try:
            raw = await _post(
                "getMachineOrders",
                {"machineNo": machine_no},
            )
            orders = _extract_value(raw)
            if not isinstance(orders, list):
                orders = []
            return ToolResult(tool_name=self.name, success=True, data=orders)
        except Exception as e:
            logger.warning("get_machine_orders(mc=%s) failed: %s", machine_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOngoingOperationsTool:
    name = "get_ongoing_operations"

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        """
        AL signature: fetchOngoingOperationsState(machineNo: Code[20])
        """
        try:
            raw = await _post(
                "fetchOngoingOperationsState",
                {"machineNo": machine_no},
            )
            ops = _extract_value(raw)
            if not isinstance(ops, list):
                ops = []
            return ToolResult(tool_name=self.name, success=True, data=ops)
        except Exception as e:
            logger.warning("get_ongoing_operations(mc=%s) failed: %s", machine_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOperationLiveDataTool:
    name = "get_operation_live_data"

    async def execute(
        self, machine_no: str, prod_order_no: str, operation_no: str, token: str = ""
    ) -> ToolResult:
        """
        AL signature: fetchOperationLiveData(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10])
        """
        try:
            raw = await _post(
                "fetchOperationLiveData",
                {
                    "machineNo":   machine_no,
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                },
            )
            items = _extract_value(raw)
            live = items[0] if isinstance(items, list) and items else (items or {})
            return ToolResult(tool_name=self.name, success=True, data=live)
        except Exception as e:
            logger.warning("get_operation_live_data(mc=%s) failed: %s", machine_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetProductionCyclesTool:
    name = "get_production_cycles"

    async def execute(
        self, machine_no: str, prod_order_no: str, operation_no: str, token: str = ""
    ) -> ToolResult:
        """
        AL signature: fetchProductionCycles(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10])
        """
        try:
            raw = await _post(
                "fetchProductionCycles",
                {
                    "machineNo":   machine_no,
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                },
            )
            cycles = _extract_value(raw)
            if not isinstance(cycles, list):
                cycles = []
            return ToolResult(tool_name=self.name, success=True, data=cycles)
        except Exception as e:
            logger.warning("get_production_cycles(mc=%s) failed: %s", machine_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOperationsHistoryTool:
    name = "get_operations_history"

    async def execute(self, machine_no: str, token: str = "") -> ToolResult:
        """
        AL signature: fetchOperationsHistory(machineNo: Code[20])
        """
        try:
            raw = await _post(
                "fetchOperationsHistory",
                {"machineNo": machine_no},
            )
            ops = _extract_value(raw)
            if not isinstance(ops, list):
                ops = []
            return ToolResult(tool_name=self.name, success=True, data=ops)
        except Exception as e:
            logger.warning("get_operations_history(mc=%s) failed: %s", machine_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetActivityLogTool:
    name = "get_activity_log"

    async def execute(self, hours_back: float, token: str = "") -> ToolResult:
        """
        AL signature: fetchActivityLog(hoursBack: Integer)
        Note: AL uses Integer, so we cast to int to avoid type mismatch.
        """
        try:
            raw = await _post(
                "fetchActivityLog",
                {"hoursBack": int(hours_back)},
            )
            logs = _extract_value(raw)
            if not isinstance(logs, list):
                logs = []
            return ToolResult(tool_name=self.name, success=True, data=logs)
        except Exception as e:
            logger.warning("get_activity_log(h=%s) failed: %s", hours_back, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetMachineDashboardTool:
    name = "get_machine_dashboard"

    async def execute(
        self, hours_back: float, work_center_nos: List[str], token: str = ""
    ) -> ToolResult:
        """
        AL signature: fetchMachineDashboard(hoursBack: Integer; workCenterNoJson: Text)
        workCenterNoJson must be a JSON-encoded array string e.g. '["100","200"]'
        hoursBack is Integer in AL so we cast.
        """
        try:
            raw = await _post(
                "fetchMachineDashboard",
                {
                    "hoursBack":        int(hours_back),
                    "workCenterNoJson": json.dumps(work_center_nos),
                },
            )
            machines = _extract_value(raw)
            if not isinstance(machines, list):
                machines = []
            return ToolResult(tool_name=self.name, success=True, data=machines)
        except Exception as e:
            logger.warning("get_machine_dashboard failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetProductionOrdersTool:
    name = "get_production_orders"

    async def execute(
        self,
        status_filter: str = "",
        work_center_no: str = "",
        machine_no: str = "",
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchProductionOrders(statusFilter: Text; workCenterNo: Text; machineNo: Text)
        """
        try:
            raw = await _post(
                "fetchProductionOrders",
                {
                    "statusFilter": status_filter,
                    "workCenterNo": work_center_no,
                    "machineNo":    machine_no,
                },
            )
            orders = _extract_value(raw)
            if not isinstance(orders, list):
                orders = []
            return ToolResult(tool_name=self.name, success=True, data=orders)
        except Exception as e:
            logger.warning("get_production_orders failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetWorkCenterSummaryTool:
    name = "get_work_center_summary"

    async def execute(
        self,
        work_center_nos: List[str],
        hours_back: float = 8.0,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchWorkCenterSummary(workCenterNoJson: Text; hoursBack: Decimal)
        workCenterNoJson must be a JSON-encoded array string e.g. '["100","200"]'
        """
        try:
            raw = await _post(
                "fetchWorkCenterSummary",
                {
                    "workCenterNoJson": json.dumps(work_center_nos),
                    "hoursBack":        float(hours_back),
                },
            )
            wcs = _extract_value(raw)
            if not isinstance(wcs, list):
                wcs = []
            return ToolResult(tool_name=self.name, success=True, data=wcs)
        except Exception as e:
            logger.warning("get_work_center_summary failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetOperatorSummaryTool:
    name = "get_operator_summary"

    async def execute(
        self,
        work_center_nos: List[str],
        hours_back: float = 8.0,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchOperatorSummary(workCenterNoJson: Text; hoursBack: Decimal)
        workCenterNoJson must be a JSON-encoded array string e.g. '["100","200"]'
        """
        try:
            raw = await _post(
                "fetchOperatorSummary",
                {
                    "workCenterNoJson": json.dumps(work_center_nos),
                    "hoursBack":        float(hours_back),
                },
            )
            users = _extract_value(raw)
            if not isinstance(users, list):
                users = []
            return ToolResult(tool_name=self.name, success=True, data=users)
        except Exception as e:
            logger.warning("get_operator_summary failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetMyDataTool:
    name = "get_my_data"

    async def execute(
        self,
        hours_back: float,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchMyData(token: Text; hoursBack: Decimal)
        Both parameter names must match exactly — 'token' and 'hoursBack'.
        """
        try:
            raw = await _post(
                "fetchMyData",
                {
                    "token":     token,
                    "hoursBack": float(hours_back),
                },
            )
            data = _extract_value(raw)
            return ToolResult(tool_name=self.name, success=True, data=data)
        except Exception as e:
            logger.warning("get_my_data failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetScrapSummaryTool:
    name = "get_scrap_summary"

    async def execute(
        self,
        hours_back: float = 8.0,
        prod_order_no: str = "",
        operation_no: str = "",
        machine_no: str = "",
        work_center_no: str = "",
        operator_id: str = "",
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchScrapSummary(
            hoursBack: Decimal;
            prodOrderNo: Code[20];
            operationNo: Code[10];
            machineNo: Code[20];
            workCenterNo: Code[20];
            operatorId: Code[50]
        )
        """
        try:
            raw = await _post(
                "fetchScrapSummary",
                {
                    "hoursBack":    float(hours_back),
                    "prodOrderNo":  prod_order_no,
                    "operationNo":  operation_no,
                    "machineNo":    machine_no,
                    "workCenterNo": work_center_no,
                    "operatorId":   operator_id,
                },
            )
            data = _extract_value(raw)
            return ToolResult(tool_name=self.name, success=True, data=data)
        except Exception as e:
            logger.warning("get_scrap_summary failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetBomTool:
    name = "get_bom"

    async def execute(
        self, prod_order_no: str, operation_no: str, token: str = ""
    ) -> ToolResult:
        """
        AL signature: fetchBom(prodOrderNo: Code[20]; operationNo: Code[10])
        """
        try:
            raw = await _post(
                "fetchBom",
                {
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                },
            )
            bom = _extract_value(raw)
            if not isinstance(bom, list):
                bom = []
            return ToolResult(tool_name=self.name, success=True, data=bom)
        except Exception as e:
            logger.warning("get_bom(order=%s) failed: %s", prod_order_no, e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetDelayReportTool:
    name = "get_delay_report"

    async def execute(
        self,
        work_center_nos: List[str],
        pause_threshold_minutes: float = 30.0,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchDelayReport(workCenterNoJson: Text; pauseThresholdMinutes: Decimal)
        workCenterNoJson must be a JSON-encoded array string e.g. '["100","200"]'
        """
        try:
            raw = await _post(
                "fetchDelayReport",
                {
                    "workCenterNoJson":      json.dumps(work_center_nos),
                    "pauseThresholdMinutes": float(pause_threshold_minutes),
                },
            )
            items = _extract_value(raw)
            if not isinstance(items, list):
                items = []
            return ToolResult(tool_name=self.name, success=True, data=items)
        except Exception as e:
            logger.warning("get_delay_report failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetConsumptionSummaryTool:
    name = "get_consumption_summary"

    async def execute(
        self,
        prod_order_no: str = "",
        operation_no: str = "",
        machine_no: str = "",
        hours_back: float = 0.0,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchConsumptionSummary(
            prodOrderNo: Code[20];
            operationNo: Code[10];
            machineNo: Code[20];
            hoursBack: Decimal
        )
        """
        try:
            raw = await _post(
                "fetchConsumptionSummary",
                {
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                    "machineNo":   machine_no,
                    "hoursBack":   float(hours_back),
                },
            )
            items = _extract_value(raw)
            if not isinstance(items, list):
                items = []
            return ToolResult(tool_name=self.name, success=True, data=items)
        except Exception as e:
            logger.warning("get_consumption_summary failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


class GetSupervisorOverviewTool:
    name = "get_supervisor_overview"

    async def execute(
        self,
        work_center_nos: List[str],
        hours_back: float = 8.0,
        pause_threshold_minutes: float = 30.0,
        token: str = "",
    ) -> ToolResult:
        """
        AL signature: fetchSupervisorOverview(
            workCenterNoJson: Text;
            hoursBack: Decimal;
            pauseThresholdMinutes: Decimal
        )
        workCenterNoJson must be a JSON-encoded array string e.g. '["100","200"]'
        """
        try:
            raw = await _post(
                "fetchSupervisorOverview",
                {
                    "workCenterNoJson":      json.dumps(work_center_nos),
                    "hoursBack":             float(hours_back),
                    "pauseThresholdMinutes": float(pause_threshold_minutes),
                },
            )
            data = _extract_value(raw)
            return ToolResult(tool_name=self.name, success=True, data=data)
        except Exception as e:
            logger.warning("get_supervisor_overview failed: %s", e)
            return ToolResult(tool_name=self.name, success=False, error=str(e))


# ── Registry ──────────────────────────────────────────────────────────────────

ALL_TOOLS = [
    ListMachinesTool(),
    GetMachineOrdersTool(),
    GetOngoingOperationsTool(),
    GetOperationLiveDataTool(),
    GetProductionCyclesTool(),
    GetOperationsHistoryTool(),
    GetActivityLogTool(),
    GetMachineDashboardTool(),
    GetProductionOrdersTool(),
    GetWorkCenterSummaryTool(),
    GetOperatorSummaryTool(),
    GetMyDataTool(),
    GetScrapSummaryTool(),
    GetDelayReportTool(),
    GetConsumptionSummaryTool(),
    GetSupervisorOverviewTool(),
    GetBomTool(),
]

TOOL_MAP: Dict[str, Any] = {t.name: t for t in ALL_TOOLS}

# Tools that accept machine_no and need access-control checks
MACHINE_SCOPED_TOOLS = {
    "get_machine_orders",
    "get_ongoing_operations",
    "get_operation_live_data",
    "get_production_cycles",
    "get_operations_history",
    "get_production_orders",
    "get_scrap_summary",
    "get_consumption_summary",
}