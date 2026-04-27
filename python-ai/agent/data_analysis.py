"""
agent/data_analysis.py

Pure-Python analysis that pre-computes facts before the LLM sees any data.
Pre-computing prevents hallucination: the LLM is told the answer, not asked
to derive it from raw numbers it might misread.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

_EPOCH_MIN = datetime.min.replace(tzinfo=timezone.utc)

SCRAP_WARNING_RATE  = 0.05   # 5%
SCRAP_CRITICAL_RATE = 0.15   # 15%


# ── Datetime helpers ──────────────────────────────────────────────────────────

def _parse_dt(s: Optional[str]) -> Optional[datetime]:
    if not s:
        return None
    for fmt in (
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%d %H:%M:%S",
        "%m/%d/%Y %H:%M:%S",   # BC sometimes emits this
    ):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def _now() -> datetime:
    return datetime.now(timezone.utc)


# ── Deadline enrichment ───────────────────────────────────────────────────────

def enrich_deadlines(orders: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Add deadline fields to each order and return a summary.

    Added per-order fields:
        hours_until_deadline: float | None
        is_overdue:           bool
        risk_level:           "on_track" | "at_risk" | "overdue" | "unknown"
    """
    now = _now()
    enriched = []
    overdue, at_risk = [], []

    for raw in orders:
        o = dict(raw)
        planned_end = _parse_dt(o.get("plannedEnd") or o.get("endDateTime"))

        if planned_end:
            delta_h = (planned_end - now).total_seconds() / 3600
            o["hours_until_deadline"] = round(delta_h, 1)
            o["is_overdue"] = delta_h < 0
            if delta_h < 0:
                o["risk_level"] = "overdue"
                overdue.append(o.get("orderNo", "?"))
            elif delta_h < 4:
                o["risk_level"] = "at_risk"
                at_risk.append(o.get("orderNo", "?"))
            else:
                o["risk_level"] = "on_track"
        else:
            o["hours_until_deadline"] = None
            o["is_overdue"] = False
            o["risk_level"] = "unknown"

        enriched.append(o)

    return {
        "orders": enriched,
        "summary": {
            "total": len(enriched),
            "overdue_count": len(overdue),
            "at_risk_count": len(at_risk),
            "overdue_orders": overdue,
            "at_risk_orders": at_risk,
        },
    }


# ── Scrap analysis ────────────────────────────────────────────────────────────

def analyse_scrap(
    live_data: Optional[Dict[str, Any]] = None,
    cycles:    Optional[List[Dict[str, Any]]] = None,
    activity:  Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Return a concise scrap analysis dict:
        scrap_rate:           float (0–1) | None
        severity:             "ok" | "warning" | "critical"
        recent_scrap_events:  int  (from activity log, last hour)
        spike_detected:       bool (recent rate >> historical rate)
        interpretation:       str  (plain-English summary for the LLM)
    """
    result: Dict[str, Any] = {
        "scrap_rate": None,
        "severity": "ok",
        "recent_scrap_events": 0,
        "spike_detected": False,
        "interpretation": "No scrap data available.",
    }

    # ── From live data ────────────────────────────────────────────────────────
    if live_data:
        produced = float(live_data.get("totalProducedQuantity") or 0)
        scrap    = float(live_data.get("scrapQuantity") or 0)
        denom    = produced + scrap
        if denom > 0:
            rate = scrap / denom
            result["scrap_rate"] = round(rate, 4)
            result["severity"] = (
                "critical" if rate >= SCRAP_CRITICAL_RATE else
                "warning"  if rate >= SCRAP_WARNING_RATE  else "ok"
            )

    # ── From activity log ─────────────────────────────────────────────────────
    if activity:
        now = _now()
        recent_scraps = [
            e for e in activity
            if e.get("type") == "scrap"
            and (dt := _parse_dt(e.get("timestamp"))) is not None
            and (now - dt).total_seconds() < 3600
        ]
        result["recent_scrap_events"] = len(recent_scraps)

    # ── Spike detection from cycles ───────────────────────────────────────────
    if cycles and len(cycles) >= 4:
        n = len(cycles)
        recent_n = max(2, n // 4)

        def _rate(cs: List[Dict]) -> float:
            tp = sum(float(c.get("cycleQuantity") or 0) for c in cs)
            ts = sum(float(c.get("scrapQuantity")  or 0) for c in cs)
            return ts / (tp + ts) if (tp + ts) > 0 else 0.0

        recent_rate = _rate(cycles[:recent_n])
        older_rate  = _rate(cycles[recent_n:])

        if older_rate > 0 and recent_rate > older_rate * 2.5:
            result["spike_detected"] = True
        elif recent_rate > SCRAP_CRITICAL_RATE:
            result["spike_detected"] = True

    # ── Plain-English interpretation ──────────────────────────────────────────
    rate = result["scrap_rate"]
    sev  = result["severity"]
    if rate is not None:
        pct = f"{rate * 100:.1f}%"
        if sev == "critical":
            result["interpretation"] = f"CRITICAL: scrap rate is {pct} (threshold 15%). Immediate attention required."
        elif sev == "warning":
            result["interpretation"] = f"WARNING: scrap rate is {pct} (threshold 5%). Monitor closely."
        else:
            result["interpretation"] = f"Scrap rate is {pct} — within acceptable range."
        if result["spike_detected"]:
            result["interpretation"] += " A recent spike has been detected."
        if result["recent_scrap_events"]:
            result["interpretation"] += f" {result['recent_scrap_events']} scrap event(s) in the last hour."

    return result


# ── Velocity / pace analysis ──────────────────────────────────────────────────

def analyse_velocity(
    live_data: Dict[str, Any],
    cycles:    List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Return production pace analysis:
        units_per_hour:   float | None  — actual recent rate
        required_rate:    float | None  — rate needed to finish on time
        projected_end:    str   | None  — ISO timestamp
        velocity_status:  "ahead" | "on_pace" | "behind" | "unknown"
        interpretation:   str           — plain-English summary
    """
    result: Dict[str, Any] = {
        "units_per_hour": None,
        "required_rate":  None,
        "projected_end":  None,
        "velocity_status": "unknown",
        "interpretation":  "Insufficient data to compute production pace.",
    }

    if not cycles:
        return result

    # ── Actual rate from last 6 cycles ────────────────────────────────────────
    sorted_cycles = sorted(
        cycles,
        key=lambda c: _parse_dt(c.get("declaredAt")) or _EPOCH_MIN,
    )
    recent = sorted_cycles[-min(6, len(sorted_cycles)):]
    if len(recent) >= 2:
        t0 = _parse_dt(recent[0].get("declaredAt"))
        t1 = _parse_dt(recent[-1].get("declaredAt"))
        qty = sum(float(c.get("cycleQuantity") or 0) for c in recent)
        if t0 and t1 and t1 > t0:
            h = (t1 - t0).total_seconds() / 3600
            if h > 0:
                result["units_per_hour"] = round(qty / h, 2)

    # ── Required rate ─────────────────────────────────────────────────────────
    order_qty  = float(live_data.get("orderQuantity") or 0)
    produced   = float(live_data.get("totalProducedQuantity") or 0)
    remaining  = max(0.0, order_qty - produced)
    planned_end = _parse_dt(live_data.get("endDateTime"))

    if planned_end and remaining > 0:
        h_left = (planned_end - _now()).total_seconds() / 3600
        if h_left > 0:
            result["required_rate"] = round(remaining / h_left, 2)

    # ── Status ────────────────────────────────────────────────────────────────
    actual   = result["units_per_hour"]
    required = result["required_rate"]
    if actual is not None and required is not None:
        if actual >= required * 1.1:
            result["velocity_status"] = "ahead"
        elif actual >= required * 0.9:
            result["velocity_status"] = "on_pace"
        else:
            result["velocity_status"] = "behind"

    # ── Projected end ─────────────────────────────────────────────────────────
    if actual and actual > 0 and remaining > 0:
        h_to_finish = remaining / actual
        result["projected_end"] = (
            _now().replace(microsecond=0) + timedelta(hours=h_to_finish)
        ).isoformat()

    # ── Interpretation ────────────────────────────────────────────────────────
    status = result["velocity_status"]
    if status == "ahead":
        result["interpretation"] = (
            f"Production is AHEAD of schedule at {actual} units/h "
            f"(need {required} units/h). "
            f"Projected finish: {result.get('projected_end', 'unknown')}."
        )
    elif status == "on_pace":
        result["interpretation"] = (
            f"Production is ON PACE at {actual} units/h "
            f"(need {required} units/h). "
            f"Projected finish: {result.get('projected_end', 'unknown')}."
        )
    elif status == "behind":
        result["interpretation"] = (
            f"Production is BEHIND schedule at {actual} units/h "
            f"(need {required} units/h). "
            f"Projected finish: {result.get('projected_end', 'unknown')}."
        )

    return result


# ── Department summary ────────────────────────────────────────────────────────

def summarise_machines(machines: List[Dict[str, Any]]) -> Dict[str, Any]:
    total   = len(machines)
    working = sum(1 for m in machines if (m.get("status") or "").lower() == "working")
    idle    = total - working
    orders  = [m.get("currentOrder") for m in machines if m.get("currentOrder") and m.get("currentOrder") != "No operator yet"]
    return {
        "total_machines":    total,
        "working":           working,
        "idle":              idle,
        "utilization_pct":   round(working / total * 100, 1) if total else 0,
        "active_orders":     orders,
        "interpretation": (
            f"{working} of {total} machines are working "
            f"({round(working/total*100, 1) if total else 0}% utilisation). "
            f"{idle} machine(s) are idle."
        ),
    }


# ── Fleet dashboard summary ───────────────────────────────────────────────────

def summarise_dashboard(machines: List[Dict[str, Any]]) -> Dict[str, Any]:
    if not machines:
        return {"interpretation": "No dashboard data available."}

    total_produced = sum(float(m.get("totalProduced") or 0) for m in machines)
    total_scrap    = sum(float(m.get("totalScrap")    or 0) for m in machines)
    avg_uptime     = sum(float(m.get("uptimePercent") or 0) for m in machines) / len(machines)
    denom          = total_produced + total_scrap
    scrap_rate     = round(total_scrap / denom, 4) if denom > 0 else 0

    sev = (
        "CRITICAL" if scrap_rate >= SCRAP_CRITICAL_RATE else
        "WARNING"  if scrap_rate >= SCRAP_WARNING_RATE  else "OK"
    )

    return {
        "total_machines":    len(machines),
        "total_produced":    round(total_produced, 2),
        "total_scrap":       round(total_scrap, 2),
        "overall_scrap_rate": scrap_rate,
        "avg_uptime_pct":    round(avg_uptime, 1),
        "scrap_severity":    sev,
        "interpretation": (
            f"Fleet: {len(machines)} machines, {round(total_produced)} units produced, "
            f"{round(total_scrap)} scrapped ({scrap_rate*100:.1f}% — {sev}), "
            f"average uptime {round(avg_uptime, 1)}%."
        ),
    }
