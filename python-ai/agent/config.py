"""
agent/config.py — Centralised configuration.

All values are read from environment variables (or a .env file).
Set LLM_PROVIDER to switch between backends.  All other LLM_* vars are
shared across providers (temperature, max_tokens, timeout).
Provider-specific variables are only required when that provider is active.
"""
import os
from dotenv import load_dotenv

load_dotenv()

def _bool(key: str, default: str = "false") -> bool:
    return os.getenv(key, default).lower() in ("1", "true", "yes")

def _int(key: str, default: int) -> int:
    return int(os.getenv(key, str(default)))

def _float(key: str, default: float) -> float:
    return float(os.getenv(key, str(default)))

def _str(key: str, default: str = "") -> str:
    return os.getenv(key, default)


# ── LLM provider selection ────────────────────────────────────────────────────
# One of: ollama | openai | huggingface | openai_compatible | anthropic
LLM_PROVIDER: str = _str("LLM_PROVIDER", "ollama")

# Shared LLM settings (applied to whichever provider is active)
LLM_TEMPERATURE: float = _float("LLM_TEMPERATURE", 0.1)
LLM_MAX_TOKENS:  int   = _int("LLM_MAX_TOKENS",  2048)
LLM_TIMEOUT:     float = _float("LLM_TIMEOUT",    120.0)


# ── Ollama (default / local) ──────────────────────────────────────────────────
# Required when LLM_PROVIDER=ollama
OLLAMA_BASE_URL: str = _str("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL:    str = _str("OLLAMA_MODEL",    "llama3.1:8b")


# ── OpenAI ────────────────────────────────────────────────────────────────────
# Required when LLM_PROVIDER=openai
OPENAI_API_KEY: str = _str("OPENAI_API_KEY")
OPENAI_MODEL:   str = _str("OPENAI_MODEL", "gpt-4o-mini")


# ── HuggingFace Serverless Inference API ──────────────────────────────────────
# Required when LLM_PROVIDER=huggingface
HF_API_KEY:    str  = _str("HF_API_KEY")
HF_MODEL:      str  = _str("HF_MODEL", "meta-llama/Llama-3.1-8B-Instruct")
HF_USE_ROUTER: bool = _bool("HF_USE_ROUTER", "false")


# ── OpenAI-compatible endpoint (Groq, Together, Mistral, vLLM, …) ────────────
# Required when LLM_PROVIDER=openai_compatible
OPENAI_COMPATIBLE_BASE_URL:  str = _str("OPENAI_COMPATIBLE_BASE_URL")
OPENAI_COMPATIBLE_API_KEY:   str = _str("OPENAI_COMPATIBLE_API_KEY")
OPENAI_COMPATIBLE_MODEL:     str = _str("OPENAI_COMPATIBLE_MODEL")


# ── Anthropic ─────────────────────────────────────────────────────────────────
# Required when LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY: str = _str("ANTHROPIC_API_KEY")
ANTHROPIC_MODEL:   str = _str("ANTHROPIC_MODEL", "claude-3-5-haiku-20241022")


# ── Node middleware proxy ─────────────────────────────────────────────────────
MIDDLEWARE_BASE_URL: str = _str("MIDDLEWARE_BASE_URL", "http://localhost:3000/api")
TOOL_HTTP_TIMEOUT:   int = _int("TOOL_HTTP_TIMEOUT", 20)


# ── Agent behaviour ───────────────────────────────────────────────────────────
DEBUG_DATA:           bool = _bool("DEBUG_DATA")
LLM_MAX_CONTEXT_CHARS: int = _int("LLM_MAX_CONTEXT_CHARS", 12000)
