"""
agent/mes_auth.py

Manages a dedicated MES service-account session for the AI agent.

Why a separate session?
  The Flutter app forwards its own user token via X-Auth-Token for every
  request, but some internal tool calls (e.g. list_machines across all work
  centers at startup, background lookups) may be made without a live user
  session.  This manager holds a long-lived AI service-account token so those
  calls always have valid credentials.

  It also means that if logging is ever added to the BC web services, the AI
  shows up as its own named user rather than piggybacking on a real operator.

Usage (from orchestrator or startup lifespan):

    auth = MESAuthManager()
    await auth.ensure_logged_in()          # idempotent – only logs in once
    token = await auth.get_token()         # auto-refreshes on 401

The token is exposed via get_token() so the orchestrator can inject it as a
fallback when the user-supplied token is empty.
"""

from __future__ import annotations

import logging
import os
import asyncio
from typing import Optional

import httpx

from agent.config import MIDDLEWARE_BASE_URL, TOOL_HTTP_TIMEOUT

logger = logging.getLogger("mes-ai.auth")

# Service-account credentials loaded from env.  These MUST be set in .env /
# environment variables — never hard-code them here.
_AI_USERNAME: str = os.getenv("MES_AI_USERNAME", "")
_AI_PASSWORD: str = os.getenv("MES_AI_PASSWORD", "")
_AI_DOMAIN: str   = os.getenv("MES_AI_device_id", "")

# How long (seconds) before we proactively refresh the token.
# BC sessions typically expire after 8 hours; refresh at 7.
_REFRESH_AFTER_SECONDS: int = int(os.getenv("MES_AI_TOKEN_TTL", str(7 * 3600)))


class MESAuthManager:
    """
    Thread-safe (asyncio) manager for the AI service-account MES token.

    Lifecycle
    ---------
    1. On first call to get_token() (or explicit ensure_logged_in()), the
       manager calls POST /api/Login on the Node middleware.
    2. The returned token is cached.
    3. After _REFRESH_AFTER_SECONDS the next get_token() call triggers a
       background re-login.
    4. On any 401 from a tool call, the orchestrator can call invalidate() to
       force an immediate re-login on the next get_token().
    """

    def __init__(self) -> None:
        self._token: Optional[str] = None
        self._lock: asyncio.Lock = asyncio.Lock()
        self._logged_in_at: float = 0.0   # epoch seconds

    # ── Public API ─────────────────────────────────────────────────────────────

    async def ensure_logged_in(self) -> None:
        """Call once at startup to pre-warm the session."""
        if not _AI_USERNAME or not _AI_PASSWORD:
            logger.warning(
                "MES_AI_USERNAME / MES_AI_PASSWORD not set — "
                "AI service-account login disabled.  "
                "Tool calls will rely solely on the user-supplied token."
            )
            return
        await self._login()

    async def get_token(self) -> Optional[str]:
        """
        Return a valid AI service-account token, refreshing if needed.
        Returns None if credentials are not configured.
        """
        if not _AI_USERNAME or not _AI_PASSWORD:
            return None

        import time
        async with self._lock:
            age = time.monotonic() - self._logged_in_at
            if self._token is None or age > _REFRESH_AFTER_SECONDS:
                await self._login_locked()

        return self._token

    async def invalidate(self) -> None:
        """Force re-login on the next get_token() call (e.g. after a 401)."""
        async with self._lock:
            logger.info("MES AI token invalidated — will re-login on next use.")
            self._token = None
            self._logged_in_at = 0.0

    # ── Private ────────────────────────────────────────────────────────────────

    async def _login(self) -> None:
        async with self._lock:
            await self._login_locked()

    async def _login_locked(self) -> None:
        """Must be called while self._lock is held."""
        import time
        url = f"{MIDDLEWARE_BASE_URL}/Login"
        payload = {
            "username": _AI_USERNAME,
            "password": _AI_PASSWORD,
            "domain":   _AI_DOMAIN,
        }
        logger.info("MES AI service-account login → %s (user: %s)", url, _AI_USERNAME)
        try:
            async with httpx.AsyncClient(timeout=TOOL_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    url,
                    json=payload,
                    headers={"Content-Type": "application/json"},
                )
                resp.raise_for_status()
                body = resp.json()

            # BC / MES Login responses typically return the token in a "value"
            # field or at the top level.  Adjust key names to match your actual
            # Login web service response schema.
            token = (
                body.get("token")
                or body.get("value")
                or body.get("authToken")
                or body.get("sessionToken")
            )
            if not token:
                logger.error(
                    "MES Login succeeded (HTTP %s) but no token found in response: %s",
                    resp.status_code,
                    str(body)[:200],
                )
                return

            self._token = str(token)
            self._logged_in_at = time.monotonic()
            logger.info("MES AI service-account login successful.")

        except httpx.HTTPStatusError as e:
            logger.error(
                "MES AI login failed HTTP %s: %s",
                e.response.status_code,
                e.response.text[:300],
            )
        except Exception as e:
            logger.error("MES AI login error: %s", e)


# Module-level singleton — import and use this everywhere.
mes_auth = MESAuthManager()