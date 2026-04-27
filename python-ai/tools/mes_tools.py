"""
tools/mes_tools.py

Each class wraps one BC web service endpoint.

All calls go to the Node middleware, which handles SSPI auth to BC.
URL path matches the endpoint name exactly — the Node proxy's buildTargetUrl()
maps /api/<name> to the correct BC web service URL.

The BC AL code (FetchMachines) requires workCenterNo to be non-empty.
The tool therefore receives an explicit work_center_no and the executor
fans out one call per work center when needed.
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
    if token:
        headers["X-Auth-Token"] = token

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
        Fetch machines for a single work center.

        Note: BC requires workCenterNo to be non-empty (see MES Machine Fetch AL).
        The executor fans out across all user work centers and merges results.
        """
        try:
            raw = await _post("FetchMachines", {"workCenterNo": work_center_no}, token)
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
        try:
            raw = await _post("getMachineOrders", {"machineNo": machine_no}, token)
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
        try:
            raw = await _post("fetchOngoingOperationsState", {"machineNo": machine_no}, token)
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
        try:
            raw = await _post("fetchOperationLiveData", {
                "machineNo":   machine_no,
                "prodOrderNo": prod_order_no,
                "operationNo": operation_no,
            }, token)
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
        try:
            raw = await _post("fetchProductionCycles", {
                "machineNo":   machine_no,
                "prodOrderNo": prod_order_no,
                "operationNo": operation_no,
            }, token)
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
        try:
            raw = await _post("fetchOperationsHistory", {"machineNo": machine_no}, token)
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
        try:
            raw = await _post("fetchActivityLog", {"hoursBack": hours_back}, token)
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
        try:
            raw = await _post("fetchMachineDashboard", {
                "hoursBack":        hours_back,
                "workCenterNoJson": json.dumps(work_center_nos),
            }, token)
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
        Fetch production orders with optional filters.

        status_filter : comma-separated subset of Planned, Firm Planned, Released, Finished.
                        Empty string returns all statuses.
        work_center_no: limit to orders with at least one routing line in this WC.
        machine_no    : limit to orders with at least one routing line on this machine.

        Covers questions such as:
          - Show me all / active / planned / released production orders
          - Which orders are assigned to work center X?
          - Which orders are assigned to machine X?
          - What is the progress of production order X?
          - Which orders are behind schedule / urgent / ready to start?
        """
        try:
            raw = await _post(
                "fetchProductionOrders",
                {
                    "statusFilter": status_filter,
                    "workCenterNo": work_center_no,
                    "machineNo": machine_no,
                },
                token,
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
        Return per-work-center summary: machine counts, operation queue,
        operator count, produced quantity, and scrap for the time window.

        work_center_nos : list of work center numbers; empty list = all.
        hours_back      : lookback window for produced/scrap aggregation.

        Covers questions such as:
          - What is the status of work center X?
          - Which work centers have delayed operations?
          - Which work center has the most stopped machines?
          - Which work center has the highest scrap / best performance today?
          - Compare work center X and work center Y.
          - Are there pending / urgent orders in my work center?
        """
        try:
            raw = await _post(
                "fetchWorkCenterSummary",
                {
                    "workCenterNoJson": json.dumps(work_center_nos),
                    "hoursBack": hours_back,
                },
                token,
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
        Return one row per MES user with current activity, machine assignment,
        produced quantity, scrap, and completed/paused operation counts.

        work_center_nos : limit to users assigned to these work centers.
                          Empty list = all users regardless of WC.
        hours_back      : lookback window for produced/scrap aggregation.

        Covers questions such as:
          - Which operators are currently active / idle?
          - Which operators are working on which machines?
          - Which operator produced the most / has the most scrap today?
          - Which operators have paused operations?
          - Who is logged in yet not working on any machine?
          - Give me a supervisor summary for the current shift.
        """
        try:
            raw = await _post(
                "fetchOperatorSummary",
                {
                    "workCenterNoJson": json.dumps(work_center_nos),
                    "hoursBack": hours_back,
                },
                token,
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
        Return data scoped to the authenticated user (identified by token):
        operations, produced qty, scrap, and machine interactions for the window.

        hours_back : lookback window. Pass shift length for shift-scoped queries.
                     Use 8.0 for a standard shift, 24.0 for "today".

        Covers questions such as:
          - What did I produce today / this shift?
          - How many operations did I complete today?
          - What was my last operation / machine?
          - Do I have any paused or unfinished operations?
          - Did I record scrap today?
          - Show me my activity / production / scrap history.
        """
        try:
            raw = await _post(
                "fetchMyData",
                {"hoursBack": hours_back},
                token,
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
        Return scrap records with a total, filterable by any combination of
        order, operation, machine, work center, and operator.

        All filter arguments default to "" (no filter applied).

        Covers questions such as:
          - How much scrap was recorded today / this shift?
          - How much scrap was recorded for order X / on machine X / in WC X?
          - Which scrap code is most frequent?
          - Which machine / operation / operator has the highest scrap?
          - Show me scrap details / notes for order X.
          - What is the scrap percentage for order X?
          - Compare scrap between machines / work centers.
        """
        try:
            raw = await _post(
                "fetchScrapSummary",
                {
                    "hoursBack":    hours_back,
                    "prodOrderNo":  prod_order_no,
                    "operationNo":  operation_no,
                    "machineNo":    machine_no,
                    "workCenterNo": work_center_no,
                    "operatorId":   operator_id,
                },
                token,
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
        try:
            raw = await _post("fetchBom", {
                "prodOrderNo": prod_order_no,
                "operationNo": operation_no,
            }, token)
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
        Return delayed and blocked operations ranked by delay severity.

        An operation is flagged when EITHER:
          - Its planned end date-time is in the past and it is not finished.
          - It has been in Paused state longer than pause_threshold_minutes.

        work_center_nos         : scope to these work centers; empty = all.
        pause_threshold_minutes : minutes after which a paused op is flagged.
                                  Default 30 min.

        Covers questions such as:
          - Which orders / operations are delayed?
          - Which machines are delaying production?
          - What is the biggest bottleneck right now?
          - Which operation has been waiting / paused the longest?
          - Which work center has the largest backlog?
          - What is the queue for machine X / work center X?
        """
        try:
            raw = await _post(
                "fetchDelayReport",
                {
                    "workCenterNoJson":       json.dumps(work_center_nos),
                    "pauseThresholdMinutes":  pause_threshold_minutes,
                },
                token,
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
        Return component consumption vs. planned BOM quantity per execution,
        including over-consumption, under-consumption, and missing-consumption flags.

        All filter arguments default to "" / 0.0 (no filter).
        hours_back = 0 means no time filter (return all executions).

        Covers questions such as:
          - Is there over-consumption / under-consumption?
          - Did operation X consume more than expected?
          - Which operations have missing consumption data?
          - Show me consumption details for order X.
        """
        try:
            raw = await _post(
                "fetchConsumptionSummary",
                {
                    "prodOrderNo": prod_order_no,
                    "operationNo": operation_no,
                    "machineNo":   machine_no,
                    "hoursBack":   hours_back,
                },
                token,
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
        Return a comprehensive supervisor overview for a shift / time window:
          - Stopped machines
          - Abnormally long pauses
          - Idle operators (logged in but no active operation)
          - High-scrap operations (> 10 % scrap rate)
          - Delayed / unstarted overdue operations
          - Aggregate produced and scrap totals

        work_center_nos         : WC numbers the supervisor covers.
        hours_back              : lookback window; use shift length (e.g. 8.0).
        pause_threshold_minutes : paused ops longer than this are flagged.
                                  Default 30 min.

        Covers questions such as:
          - Give me the situation / what is wrong right now?
          - Which machines are stopped under my supervision?
          - Which operator needs attention / is idle?
          - What should I prioritize as a supervisor?
          - Give me a supervisor summary / shift handover.
          - Are there abnormal pauses?
          - Which problems require supervisor intervention?
          - Prepare a handover for the next supervisor.
        """
        try:
            raw = await _post(
                "fetchSupervisorOverview",
                {
                    "workCenterNoJson":       json.dumps(work_center_nos),
                    "hoursBack":              hours_back,
                    "pauseThresholdMinutes":  pause_threshold_minutes,
                },
                token,
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
