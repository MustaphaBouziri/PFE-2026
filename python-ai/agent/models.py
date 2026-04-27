"""
agent/models.py — All Pydantic schemas used across the agent.
"""
from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


# ── Conversation ──────────────────────────────────────────────────────────────

class ConversationTurn(BaseModel):
    role: str   # "user" | "assistant"
    content: str


class UserContext(BaseModel):
    user_id: str
    role: str                   # "Operator" | "Supervisor" | "Admin"
    work_centers: List[str] = []
    token: str = ""             # MES auth token forwarded from Flutter


# ── Request ───────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    user_context: UserContext
    conversation_history: List[ConversationTurn] = []


# ── Actions (UI commands sent back to Flutter) ────────────────────────────────

class ActionType(str, Enum):
    REDIRECT_MACHINE       = "redirect_machine"
    REDIRECT_OPERATION     = "redirect_operation"
    REDIRECT_MACHINE_LIST  = "redirect_machine_list"
    REDIRECT_DASHBOARD     = "redirect_machine_dashboard"
    REDIRECT_HISTORY       = "redirect_history"


class RedirectAction(BaseModel):
    action_type: ActionType
    label: str
    payload: Dict[str, Any] = Field(default_factory=dict)

    class Config:
        use_enum_values = True


# ── Response ──────────────────────────────────────────────────────────────────

class ChatResponse(BaseModel):
    text: str
    actions: List[RedirectAction] = []
    data_fetched: List[str] = []    # tool names called (populated when DEBUG_DATA=true)
    error: Optional[str] = None

    # Internal classifier reasoning — never shown in the chat UI.
    # Contains: classifier method used (llm / regex_fallback), intent,
    # the planned tool steps, LLM reasoning text, and fallback details.
    # Flutter / the Node middleware can log or surface this in a dev panel.
    thinking: Optional[Dict[str, Any]] = None


# ── Internal tool result ──────────────────────────────────────────────────────

class ToolResult(BaseModel):
    tool_name: str
    success: bool
    data: Any = None
    error: Optional[str] = None