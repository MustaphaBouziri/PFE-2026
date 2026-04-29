"""
main.py — FastAPI entry point for the MES AI Agent.

Flow:
  Flutter → Node middleware → POST /chat → MES AI Agent
                                               ↓
                                     intent classifier (rules)
                                               ↓
                                   deterministic tool executor
                                     (access control enforced)
                                               ↓
                                     data analysis enrichment
                                               ↓
                                      LLM synthesis (1 call)
                                               ↓
  Flutter ← Node middleware ← JSON response (text + actions)
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agent.models import ChatRequest, ChatResponse
from agent.orchestrator import MESAgentOrchestrator

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("mes-ai")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("MES AI Agent starting up…")
    app.state.orchestrator = MESAgentOrchestrator()
    yield
    logger.info("MES AI Agent shutting down…")


app = FastAPI(
    title="MES AI Agent",
    version="2.0.0",
    description="Conversational AI layer for the MES Flutter app",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],     # tighten in production
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Main endpoint.

    Accepts:
        message:              user's natural-language question
        user_context:         { user_id, role, work_centers, token }
        conversation_history: previous turns [ {role, content} ]

    Returns:
        text:         markdown-safe assistant reply
        actions:      list of UI redirect buttons (0–4)
        data_fetched: tool names called (only when DEBUG_DATA=true)
    """
    try:
        orchestrator: MESAgentOrchestrator = app.state.orchestrator
        return await orchestrator.run(request)
    except Exception as exc:
        logger.exception("Unhandled error in /chat")
        raise HTTPException(status_code=500, detail=str(exc))
