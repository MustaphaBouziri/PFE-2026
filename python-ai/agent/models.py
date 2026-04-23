"""
agent/models.py — All Pydantic schemas used across the agent.
"""

from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


# ── Conversation ──────────────────────────────────────────────────────────────

class ConversationTurn(BaseModel):
    role: str                     # "user" | "assistant"
    content: str


class UserContext(BaseModel):
    user_id: str
    role: str                     # "Operator" | "Supervisor" | "Admin"
    work_centers: List[str] = []
    token: str = ""               # MES auth token forwarded from Flutter


# ── Request ───────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    user_context: UserContext
    conversation_history: List[ConversationTurn] = []


# ── Actions (UI commands sent back to Flutter) ────────────────────────────────

class ActionType(str, Enum):
    REDIRECT_MACHINE       = "redirect_machine"          # → MachineMainPage
    REDIRECT_OPERATION     = "redirect_operation"        # → OperationDetailPage
    REDIRECT_MACHINE_LIST  = "redirect_machine_list"     # → Machinelistpage
    REDIRECT_DASHBOARD     = "redirect_machine_dashboard"
    REDIRECT_HISTORY       = "redirect_history"


class RedirectAction(BaseModel):
    """
    A UI action the Flutter frontend should render as a tappable button.

    Flutter reads `action_type` to decide which page to push, then uses
    `payload` as the named constructor arguments.
    """
    action_type: ActionType
    label: str                               # button label shown to user
    payload: Dict[str, Any] = Field(         # page constructor arguments
        description="Named args for the target Flutter page constructor"
    )

    class Config:
        use_enum_values = True


# ── Response ──────────────────────────────────────────────────────────────────

class ChatResponse(BaseModel):
    text: str                                    # markdown assistant reply
    actions: List[RedirectAction] = []           # 0-N redirect buttons
    data_fetched: List[str] = []                 # which tools were called (for debug)
    error: Optional[str] = None


# ── Internal tool result wrapper ──────────────────────────────────────────────

class ToolResult(BaseModel):
    tool_name: str
    success: bool
    data: Any = None
    error: Optional[str] = None
