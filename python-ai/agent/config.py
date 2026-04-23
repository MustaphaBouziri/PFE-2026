"""
agent/config.py — centralised configuration.
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ── Ollama ────────────────────────────────────────────────────────────────────
OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL: str    = os.getenv("OLLAMA_MODEL", "llama3.1:8b")

# Temperature kept low to minimise hallucination on factual MES data
OLLAMA_TEMPERATURE: float = float(os.getenv("OLLAMA_TEMPERATURE", "0.1"))

# ── Node middleware proxy ─────────────────────────────────────────────────────
# The Python agent calls the Node proxy (not BC directly) so auth + SSPI is
# handled the same way Flutter does it.
MIDDLEWARE_BASE_URL: str = os.getenv("MIDDLEWARE_BASE_URL", "http://localhost:3000/api")

# Timeout for tool HTTP calls (seconds)
TOOL_HTTP_TIMEOUT: int = int(os.getenv("TOOL_HTTP_TIMEOUT", "20"))

# ── Agent behaviour ───────────────────────────────────────────────────────────
# Max rounds of tool-call → LLM before forcing a final answer
MAX_TOOL_ROUNDS: int = int(os.getenv("MAX_TOOL_ROUNDS", "4"))

# If True, raw fetched data is included in the response for debugging
DEBUG_DATA: bool = os.getenv("DEBUG_DATA", "false").lower() == "true"

# Company ID passed to BC endpoints
COMPANY_ID: str = os.getenv("BC_COMPANY", "")
