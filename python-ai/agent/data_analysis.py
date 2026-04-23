"""
agent/data_analysis.py

Pure-Python analysis functions that enrich raw MES data with derived insights
before handing it to the LLM. This reduces hallucination by pre-computing
the numbers the LLM would otherwise have to derive.

BUG FIX vs original:
  analyse_velocity() used `datetime.min` (naive) as a sort fallback alongside
  timezone-aware datetimes returned by _parse_dt().  Python raises:
      TypeError: can't compare offset-naive and offset-aware datetimes
  Fixed by using datetime.min.replace(tzinfo=timezone.utc) as the fallback.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional


def _parse_dt(s: Optional[str]) -> Optional[datetime]:
    if not s:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%d %H:%M:%S"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


# Sentinel used for sorting — timezone-aware so it can be compared safely.
_EPOCH_MIN = datetime.min.replace(tzinfo=timezone.utc)


# ── Deadline analysis ──────────────────────────────────────────────────────────

def analyse_deadlines(orders: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Enrich each order with:
      - is_overdue: bool
      - hours_until_deadline: float (negative = overdue)
      - risk_level: "on_track" | "at_risk" | "overdue"
    """
    now = now_utc()
    enriched = []
    for order in orders:
        o = dict(order)
        planned_end = _parse_dt(o.get("plannedEnd") or o.get("endDateTime"))

        if planned_end:
            delta_h = (planned_end - now).total_seconds() / 3600
            o["hours_until_deadline"] = round(delta_h, 1)
            o["is_overdue"] = delta_h < 0

            if delta_h < 0:
                o["risk_level"] = "overdue"
            elif delta_h < 4:
                o["risk_level"] = "at_risk"
            else:
                o["risk_level"] = "on_track"
        else:
            o["hours_until_deadline"] = None
            o["is_overdue"] = False
            o["risk_level"] = "unknown"

        enriched.append(o)
    return enriched


# ── Scrap analysis ─────────────────────────────────────────────────────────────

SCRAP_SPIKE_THRESHOLD = 0.05      # 5% scrap rate = warning
SCRAP_CRITICAL_THRESHOLD = 0.15   # 15% = critical


def analyse_scrap(
    live_data: Optional[Dict[str, Any]] = None,
    activity_logs: Optional[List[Dict[str, Any]]] = None,
    production_cycles: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Returns a scrap analysis dict:
      - scrap_rate: float (0-1)
      - severity: "ok" | "warning" | "critical"
      - recent_scrap_events: count of scrap events in last hour
      - spike_detected: bool (recent rate >> overall rate)
    """
    result: Dict[str, Any] = {
        "scrap_rate": None,
        "severity": "ok",
        "recent_scrap_events": 0,
        "spike_detected": False,
    }

    # From live data
    if live_data:
        total = float(live_data.get("orderQuantity") or 0)
        scrap = float(live_data.get("scrapQuantity") or 0)
        produced = float(live_data.get("totalProducedQuantity") or 0)
        denominator = produced + scrap
        if denominator > 0:
            rate = scrap / denominator
            result["scrap_rate"] = round(rate, 4)
            if rate >= SCRAP_CRITICAL_THRESHOLD:
                result["severity"] = "critical"
            elif rate >= SCRAP_SPIKE_THRESHOLD:
                result["severity"] = "warning"

    # Count recent scrap events in activity logs
    if activity_logs:
        now = now_utc()
        recent = [
            e for e in activity_logs
            if e.get("type") == "scrap"
            and _parse_dt(e.get("timestamp")) is not None
            and (now - _parse_dt(e["timestamp"])).total_seconds() < 3600  # type: ignore[operator]
        ]
        result["recent_scrap_events"] = len(recent)

    # Spike detection from production cycles
    if production_cycles and len(production_cycles) >= 4:
        n = len(production_cycles)
        recent_n = max(2, n // 4)
        recent_cycles = production_cycles[:recent_n]
        older_cycles = production_cycles[recent_n:]

        def scrap_rate_from_cycles(cycles: List[Dict[str, Any]]) -> float:
            total_prod = sum(float(c.get("cycleQuantity") or 0) for c in cycles)
            total_scrap = sum(float(c.get("scrapQuantity") or 0) for c in cycles)
            denom = total_prod + total_scrap
            return total_scrap / denom if denom > 0 else 0.0

        recent_rate = scrap_rate_from_cycles(recent_cycles)
        older_rate = scrap_rate_from_cycles(older_cycles)

        if older_rate > 0 and recent_rate > older_rate * 2.5:
            result["spike_detected"] = True
        elif recent_rate > SCRAP_CRITICAL_THRESHOLD:
            result["spike_detected"] = True

    return result


# ── Production velocity analysis ───────────────────────────────────────────────

def analyse_velocity(
    live_data: Dict[str, Any],
    production_cycles: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Computes:
      - units_per_hour: recent production rate
      - required_rate: units/hour needed to finish on time
      - projected_end: estimated completion datetime string
      - velocity_status: "on_pace" | "behind" | "ahead" | "unknown"

    BUG FIX: sort key fallback changed from `datetime.min` (naive) to
    `_EPOCH_MIN` (timezone-aware) to avoid TypeError when mixing aware/naive
    datetimes during comparison.
    """
    result: Dict[str, Any] = {
        "units_per_hour": None,
        "required_rate": None,
        "projected_end": None,
        "velocity_status": "unknown",
    }

    if not production_cycles:
        return result

    # Compute actual rate from last N cycles
    sorted_cycles = sorted(
        production_cycles,
        # FIX: was `datetime.min` (naive) — replaced with timezone-aware sentinel
        key=lambda c: _parse_dt(c.get("declaredAt")) or _EPOCH_MIN,
    )

    if len(sorted_cycles) >= 2:
        recent = sorted_cycles[-min(6, len(sorted_cycles)):]
        first_ts = _parse_dt(recent[0].get("declaredAt"))
        last_ts = _parse_dt(recent[-1].get("declaredAt"))
        total_qty = sum(float(c.get("cycleQuantity") or 0) for c in recent)

        if first_ts and last_ts and last_ts > first_ts:
            hours = (last_ts - first_ts).total_seconds() / 3600
            if hours > 0:
                rate = total_qty / hours
                result["units_per_hour"] = round(rate, 2)

    # Required rate
    order_qty = float(live_data.get("orderQuantity") or 0)
    produced = float(live_data.get("totalProducedQuantity") or 0)
    remaining = order_qty - produced
    planned_end = _parse_dt(live_data.get("endDateTime"))

    if planned_end and remaining > 0:
        hours_left = (planned_end - now_utc()).total_seconds() / 3600
        if hours_left > 0:
            req_rate = remaining / hours_left
            result["required_rate"] = round(req_rate, 2)

            if result["units_per_hour"] is not None:
                actual = result["units_per_hour"]
                if actual >= req_rate * 1.1:
                    result["velocity_status"] = "ahead"
                elif actual >= req_rate * 0.9:
                    result["velocity_status"] = "on_pace"
                else:
                    result["velocity_status"] = "behind"

    # Projected end
    if result["units_per_hour"] and result["units_per_hour"] > 0 and remaining > 0:
        hours_to_finish = remaining / result["units_per_hour"]
        projected = now_utc().replace(microsecond=0) + timedelta(hours=hours_to_finish)
        result["projected_end"] = projected.isoformat()

    return result


# ── Department overview ────────────────────────────────────────────────────────

def summarise_department(machines: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Aggregate machine list into department-level summary."""
    total = len(machines)
    working = sum(1 for m in machines if (m.get("status") or "").lower() == "working")
    idle = total - working
    return {
        "total_machines": total,
        "working": working,
        "idle": idle,
        "utilization_pct": round(working / total * 100, 1) if total else 0,
    }