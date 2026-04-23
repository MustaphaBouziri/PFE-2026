"""
MES AI Agent — FastAPI entry point.

Flow:
  Flutter  →  Node middleware  →  POST /chat  →  MES AI Agent (this)
                                                        ↓
                                               intent classifier
                                                        ↓
                                                tool orchestrator
                                                  (access control)
                                                        ↓
                                              Ollama LLM (llama3.1)
                                                        ↓
                                              structured response
                                                        ↓
  Flutter  ←  Node middleware  ←  JSON response (text + actions)
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from agent.mes_auth import mes_auth
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

    # Pre-warm the AI service-account MES session so the first real request
    # doesn't block on login.  Logs a warning (not an error) if credentials
    # are not configured — the agent still works using user-supplied tokens.
    await mes_auth.ensure_logged_in()

    app.state.orchestrator = MESAgentOrchestrator()
    yield
    logger.info("MES AI Agent shutting down…")


app = FastAPI(
    title="MES AI Agent",
    version="1.0.0",
    description="Conversational AI layer for the MES Flutter app",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # tighten in production
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
        - message: user's natural language question
        - user_context: { user_id, role, work_centers, token }
        - conversation_history: previous turns [ {role, content} ]

    Returns:
        - text: markdown-safe assistant reply
        - actions: list of UI action objects (redirect buttons, etc.)
        - data_fetched: tools called (only populated when DEBUG_DATA=true)
    """
    try:
        orchestrator: MESAgentOrchestrator = app.state.orchestrator
        response = await orchestrator.run(request)
        return response
    except Exception as exc:
        logger.exception("Unhandled error in /chat")
        raise HTTPException(status_code=500, detail=str(exc))