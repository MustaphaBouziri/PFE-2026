"""
agent/resolver.py — Name and fuzzy-ID resolution for machines and work centres.

Problem: users say "Fraiseuse 3", "milling 3", "MC 1" (space), "MC-0O1" (typo),
"machine 42" (bare number), "lathe" (partial name), or just "001" (bare suffix).
We need to map these to canonical machineNo values before the tool chain runs.

Approach
────────
No external fuzzy-matching library needed.  We use a four-tier match cascade
against the machine catalogue (fetched from BC via list_machines):

  Tier 1 – Exact canonical match     "MC-001"      → MC-001
  Tier 2 – Normalised exact match    "mc 001"      → MC-001
  Tier 3 – Prefix / suffix match     "001", "MC-1" → MC-001 (if unique)
  Tier 4 – Token overlap score       "milling 3"   → best-scoring name match
  Tier 5 – Edit-distance (Levenshtein) on normalised ID strings (typo recovery)

A match below MIN_CONFIDENCE is treated as ambiguous and reported back to the
user for clarification rather than silently using the wrong machine.

Work-centre resolution follows the same cascade against workCenterNo / name.
"""
from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple


# ── Tuning constants ──────────────────────────────────────────────────────────

MIN_CONFIDENCE   = 0.45   # below this → ambiguous (ask user)
HIGH_CONFIDENCE  = 0.85   # above this → accept without asking
MAX_CANDIDATES   = 3      # how many alternatives to offer when ambiguous


# ── Data structures ───────────────────────────────────────────────────────────

@dataclass
class MachineEntry:
    machine_no:     str
    name:           str
    work_center_no: str
    work_center_name: str = ""
    status:         str = ""
    # Pre-computed normalised forms (set by _build_index)
    norm_no:   str = field(default="", repr=False)
    norm_name: str = field(default="", repr=False)
    no_digits: str = field(default="", repr=False)   # just the digit suffix, e.g. "001"


@dataclass
class ResolveResult:
    query:       str             # original user string
    resolved:    bool            # True = confident match found
    machine_no:  Optional[str]   # canonical ID if resolved
    confidence:  float           # 0–1
    # If ambiguous, alternatives to show the user
    candidates:  List[Dict[str, Any]] = field(default_factory=list)
    explanation: str = ""        # why we picked this (for debug / LLM context)


@dataclass
class WCResolveResult:
    query:      str
    resolved:   bool
    wc_no:      Optional[str]
    wc_name:    str = ""
    candidates: List[Dict[str, Any]] = field(default_factory=list)


# ── Text normalisation ────────────────────────────────────────────────────────

def _norm(s: str) -> str:
    """
    Lowercase, strip accents, collapse whitespace, remove punctuation
    except hyphens between digits (MC-001 → mc-001, not mc001).
    """
    # NFD decomposition strips accents
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    # Replace common separators with space, then collapse
    s = re.sub(r"[_/\\|]+", " ", s)
    # Keep hyphens only between digits (preserve MC-001 structure)
    s = re.sub(r"(?<!\d)-(?!\d)", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _digits_only(s: str) -> str:
    """Extract only the digit portion: 'MC-042' → '042', '42' → '42'."""
    m = re.search(r"\d+$", s)
    return m.group(0) if m else ""


def _tokenise(s: str) -> List[str]:
    return [t for t in re.split(r"\W+", s.lower()) if t]


# ── Levenshtein edit distance (small strings only) ───────────────────────────

def _edit_distance(a: str, b: str) -> int:
    """Standard DP Levenshtein."""
    if len(a) > 30 or len(b) > 30:   # bail on very long strings
        return max(len(a), len(b))
    la, lb = len(a), len(b)
    dp = list(range(lb + 1))
    for i in range(1, la + 1):
        prev = dp[:]
        dp[0] = i
        for j in range(1, lb + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            dp[j] = min(dp[j] + 1, dp[j - 1] + 1, prev[j - 1] + cost)
    return dp[lb]


def _edit_similarity(a: str, b: str) -> float:
    """1 – normalised edit distance."""
    if not a and not b:
        return 1.0
    dist = _edit_distance(a, b)
    return 1.0 - dist / max(len(a), len(b))


# ── Token overlap score ───────────────────────────────────────────────────────

def _token_overlap(query_tokens: List[str], target_tokens: List[str]) -> float:
    """
    Score how well query_tokens match target_tokens.

    Uses a containment-biased formula:
      - If ALL query tokens appear in the target (e.g. "Presse" ⊆ "Presse hydraulique"),
        score is high (0.80 base) scaled by how much of the target is covered.
      - Otherwise falls back to symmetric Jaccard weighted by character length.
      - Generic/noise tokens ("machine", "center", "station", "mc") are ignored
        when scoring name matches to avoid false high scores.

    This means "Presse" → "Presse hydraulique" scores ~0.82 instead of ~0.35.
    """
    _NOISE = {"machine", "center", "station", "mc", "the", "de", "le", "la"}

    if not query_tokens or not target_tokens:
        return 0.0

    # Filter noise from query tokens for name matching
    qt_sig = [t for t in query_tokens if t not in _NOISE and (len(t) > 1 or t.isdigit())]
    if not qt_sig:
        qt_sig = query_tokens   # fallback: keep all if everything is noise

    qt = set(qt_sig)
    tt = set(target_tokens)
    # Also count query tokens that are a PREFIX of any target token
    # e.g. "auto" is a prefix of "automatique" → counts as matched
    prefix_matched: set = set()
    for qt_tok in qt:
        if qt_tok in tt:
            prefix_matched.add(qt_tok)
        elif len(qt_tok) >= 3 and any(tt_tok.startswith(qt_tok) for tt_tok in tt):
            prefix_matched.add(qt_tok)   # prefix match

    common = prefix_matched  # use prefix-aware common set

    if not common:
        return 0.0

    # Containment: are all significant query tokens found in the target (or as prefixes)?
    if common == qt:
        # Full containment: all query tokens matched
        # Score = 0.80 + 0.19 * (matched_chars / target_chars)
        # This rewards "Presse" → "Presse hydraulique" at ~0.83
        # and "Tour automatique" → "Tour automatique" at 0.99
        matched_chars = sum(len(t) for t in common)
        target_chars  = sum(len(t) for t in tt)
        coverage = matched_chars / target_chars if target_chars else 0.0
        return 0.80 + 0.19 * coverage

    # Partial containment: some query tokens matched.
    # Cap at 0.75 so that full-containment (≥0.80) always wins.
    matched_chars = sum(len(t) for t in common)
    total_chars   = sum(len(t) for t in qt | tt)
    raw = matched_chars / total_chars if total_chars else 0.0
    return min(raw, 0.75)


def _numeric_value(digit_str: str) -> int:
    """Return integer value of a digit string, stripping leading zeros."""
    try:
        return int(digit_str)
    except (ValueError, TypeError):
        return -1


# ── Machine catalogue index ───────────────────────────────────────────────────

def build_machine_index(machines: List[Dict[str, Any]]) -> List[MachineEntry]:
    """Build a searchable index from a list of raw machine dicts from BC."""
    entries: List[MachineEntry] = []
    for m in machines:
        mno  = str(m.get("machineNo") or m.get("no") or "").strip()
        name = str(m.get("machineName") or m.get("name") or "").strip()
        wc   = str(m.get("workCenterNo") or "").strip()
        wcn  = str(m.get("workCenterName") or "").strip()
        st   = str(m.get("status") or "").strip()
        if not mno:
            continue
        e = MachineEntry(
            machine_no=mno, name=name,
            work_center_no=wc, work_center_name=wcn, status=st,
        )
        e.norm_no   = _norm(mno)
        e.norm_name = _norm(name)
        e.no_digits = _digits_only(mno)
        entries.append(e)
    return entries


# ── Core resolution function ──────────────────────────────────────────────────

def resolve_machine(query: str, index: List[MachineEntry]) -> ResolveResult:
    """
    Try to map a free-text machine reference to a canonical machineNo.

    Returns a ResolveResult.  The caller should:
      - If resolved=True and confidence >= HIGH_CONFIDENCE: proceed silently.
      - If resolved=True and MIN_CONFIDENCE <= confidence < HIGH_CONFIDENCE:
        proceed but mention the assumption in the LLM context.
      - If resolved=False: surface candidates to the user for clarification.
    """
    if not index:
        return ResolveResult(query=query, resolved=False, machine_no=None,
                             confidence=0.0, explanation="Machine catalogue is empty.")

    q_norm   = _norm(query)
    q_tokens = _tokenise(q_norm)
    q_digits = _digits_only(query)

    scores: List[Tuple[float, MachineEntry, str]] = []  # (score, entry, tier)

    for e in index:
        score = 0.0
        tier  = ""

        # Tier 1: exact canonical match
        if query.upper() == e.machine_no.upper():
            score, tier = 1.0, "exact_id"

        # Tier 2: normalised exact match (handles "mc 001", "MC001", "mc-001")
        elif q_norm == e.norm_no or q_norm == e.norm_name:
            score, tier = 0.97, "normalised_exact"

        # Tier 3a: digit-suffix exact match (user says "001" or "1" → MC-001)
        elif q_digits and q_digits == e.no_digits and len(q_digits) >= 2:
            score, tier = 0.90, "digit_suffix"

        # Tier 3a2: digit-suffix numeric match (user says "42" → MC-042, or "0042" → MC-042)
        # Strips leading zeros from both sides and compares integer values
        elif q_digits and len(q_digits) >= 2 and _numeric_value(q_digits) == _numeric_value(e.no_digits):
            score, tier = 0.88, "digit_numeric"

        # Tier 3b: query is a prefix/suffix of the machine ID or vice versa
        elif q_norm and (e.norm_no.startswith(q_norm) or q_norm.startswith(e.norm_no)):
            ratio = min(len(q_norm), len(e.norm_no)) / max(len(q_norm), len(e.norm_no))
            score, tier = 0.75 * ratio, "id_prefix"

        else:
            # Tier 4: token overlap against name
            tok_score = _token_overlap(q_tokens, _tokenise(e.norm_name))
            # Tier 5: edit distance on normalised ID
            ed_score  = _edit_similarity(q_norm, e.norm_no) * 0.8  # downweight slightly

            score = max(tok_score, ed_score)
            tier  = "token_overlap" if tok_score >= ed_score else "edit_distance"

        if score > 0.0:
            scores.append((score, e, tier))

    if not scores:
        return ResolveResult(query=query, resolved=False, machine_no=None,
                             confidence=0.0, explanation="No machines in catalogue.")

    scores.sort(key=lambda x: -x[0])
    best_score, best_entry, best_tier = scores[0]

    # Check for a tie at the top (ambiguous)
    top_scores = [s for s in scores if s[0] >= best_score - 0.05]
    if len(top_scores) > 1 and best_score < HIGH_CONFIDENCE:
        candidates = [
            {
                "machineNo":     e.machine_no,
                "name":          e.name,
                "workCenterNo":  e.work_center_no,
                "workCenterName": e.work_center_name,
                "status":        e.status,
                "score":         round(sc, 3),
            }
            for sc, e, _ in top_scores[:MAX_CANDIDATES]
        ]
        return ResolveResult(
            query=query, resolved=False, machine_no=None,
            confidence=best_score, candidates=candidates,
            explanation=(
                f"Ambiguous: '{query}' matches {len(candidates)} machines with "
                f"similar confidence ({best_score:.0%})."
            ),
        )

    if best_score < MIN_CONFIDENCE:
        candidates = [
            {
                "machineNo":     e.machine_no,
                "name":          e.name,
                "workCenterNo":  e.work_center_no,
                "workCenterName": e.work_center_name,
                "status":        e.status,
            }
            for _, e, _ in scores[:MAX_CANDIDATES]
        ]
        return ResolveResult(
            query=query, resolved=False, machine_no=None,
            confidence=best_score, candidates=candidates,
            explanation=(
                f"No confident match for '{query}' "
                f"(best: {best_entry.machine_no} '{best_entry.name}' "
                f"at {best_score:.0%})."
            ),
        )

    assumption = best_score < HIGH_CONFIDENCE
    return ResolveResult(
        query=query,
        resolved=True,
        machine_no=best_entry.machine_no,
        confidence=best_score,
        explanation=(
            f"{'Assumed: ' if assumption else ''}"
            f"'{query}' → {best_entry.machine_no} '{best_entry.name}' "
            f"via {best_tier} ({best_score:.0%})"
        ),
    )


# ── Work-centre resolution ────────────────────────────────────────────────────

def resolve_work_center(
    query: str,
    machines: List[Dict[str, Any]],
) -> WCResolveResult:
    """
    Resolve a work-centre name or number from the machine catalogue.
    Returns the canonical workCenterNo.
    """
    q_norm = _norm(query)
    seen: Dict[str, Dict[str, Any]] = {}

    for m in machines:
        wc_no  = str(m.get("workCenterNo")   or "").strip()
        wc_name = str(m.get("workCenterName") or "").strip()
        if wc_no and wc_no not in seen:
            seen[wc_no] = {"wc_no": wc_no, "wc_name": wc_name}

    scores: List[Tuple[float, str, str]] = []  # (score, wc_no, wc_name)
    for wc_no, info in seen.items():
        wc_name = info["wc_name"]
        norm_no   = _norm(wc_no)
        norm_name = _norm(wc_name)

        if q_norm == norm_no or q_norm == norm_name:
            score = 0.99
        else:
            tok = _token_overlap(_tokenise(q_norm), _tokenise(norm_name))
            ed  = _edit_similarity(q_norm, norm_no) * 0.85
            score = max(tok, ed)

        if score > 0.0:
            scores.append((score, wc_no, wc_name))

    if not scores:
        return WCResolveResult(query=query, resolved=False, wc_no=None)

    scores.sort(key=lambda x: -x[0])
    best_score, best_no, best_name = scores[0]

    if best_score < MIN_CONFIDENCE:
        candidates = [
            {"wc_no": no, "wc_name": nm, "score": round(sc, 3)}
            for sc, no, nm in scores[:MAX_CANDIDATES]
        ]
        return WCResolveResult(query=query, resolved=False, wc_no=None,
                               candidates=candidates)

    return WCResolveResult(
        query=query, resolved=True, wc_no=best_no, wc_name=best_name,
    )


# ── Batch helpers ─────────────────────────────────────────────────────────────

def format_candidates_for_llm(result: ResolveResult) -> str:
    """
    Build a concise disambiguation message to inject into the LLM context
    when we can't resolve a machine reference confidently.
    """
    lines = [
        f"Could not confidently identify machine from '{result.query}'.",
        "Please ask the user to clarify which machine they mean.",
        "Options found:",
    ]
    for c in result.candidates:
        lines.append(
            f"  • {c['machineNo']} — {c.get('name', '')} "
            f"(WC {c.get('workCenterNo', '')}"
            + (f" {c.get('workCenterName', '')}" if c.get('workCenterName') else "")
            + f", status: {c.get('status', 'unknown')})"
        )
    return "\n".join(lines)
