"""
agent/llm_client.py — Multi-provider LLM client.

All backends expose a single async method:

    async def complete(messages: List[Dict[str, Any]]) -> str

The orchestrator calls this exactly once per request.  No tool-call support
is intentional — tool selection is done deterministically in Python.

Supported providers (set LLM_PROVIDER in .env):
────────────────────────────────────────────────
  ollama              Local Ollama server (default)
  openai              OpenAI API
  huggingface         HuggingFace Serverless Inference API
  openai_compatible   Any OpenAI-compatible endpoint (Groq, Together, vLLM…)
  anthropic           Anthropic Messages API
"""
from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from typing import Any, Dict, List

import httpx

logger = logging.getLogger("mes-ai.llm")


# ── Abstract base ─────────────────────────────────────────────────────────────

class LLMClient(ABC):
    """Common interface all backends must implement."""

    @abstractmethod
    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        """Send chat messages and return the assistant reply text."""

    def _log_req(self, provider: str, model: str, n: int) -> None:
        logger.info("LLM › provider=%s model=%s messages=%d", provider, model, n)

    def _log_res(self, provider: str, n: int) -> None:
        logger.info("LLM ‹ provider=%s chars=%d", provider, n)

    @staticmethod
    def _http_error(e: httpx.HTTPStatusError, provider: str) -> None:
        logger.error("%s HTTP %s: %s", provider, e.response.status_code, e.response.text[:300])
        raise e


# ── Ollama ────────────────────────────────────────────────────────────────────

class OllamaClient(LLMClient):
    """Local Ollama server — https://github.com/ollama/ollama/blob/main/docs/api.md"""

    def __init__(self, base_url: str, model: str,
                 temperature: float = 0.1, max_tokens: int = 2048, timeout: float = 120.0):
        self.base_url    = base_url.rstrip("/")
        self.model       = model
        self.temperature = temperature
        self.max_tokens  = max_tokens
        self.timeout     = timeout

    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        self._log_req("ollama", self.model, len(messages))
        payload = {
            "model": self.model, "messages": messages, "stream": False,
            "options": {"temperature": self.temperature, "num_predict": self.max_tokens},
        }
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            try:
                r = await c.post(f"{self.base_url}/api/chat", json=payload)
                r.raise_for_status()
            except httpx.HTTPStatusError as e:
                self._http_error(e, "ollama")
        text = (r.json().get("message") or {}).get("content", "").strip()
        self._log_res("ollama", len(text))
        return text


# ── OpenAI ────────────────────────────────────────────────────────────────────

class OpenAIClient(LLMClient):
    """
    OpenAI Chat Completions API — https://platform.openai.com/docs/api-reference/chat
    Models: gpt-4o, gpt-4o-mini, gpt-4-turbo, gpt-3.5-turbo, o1-mini …
    """
    URL = "https://api.openai.com/v1/chat/completions"

    def __init__(self, api_key: str, model: str = "gpt-4o-mini",
                 temperature: float = 0.1, max_tokens: int = 2048, timeout: float = 60.0):
        if not api_key:
            raise ValueError("OPENAI_API_KEY is required for the openai provider.")
        self.api_key     = api_key
        self.model       = model
        self.temperature = temperature
        self.max_tokens  = max_tokens
        self.timeout     = timeout

    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        self._log_req("openai", self.model, len(messages))
        payload = {"model": self.model, "messages": messages,
                   "temperature": self.temperature, "max_tokens": self.max_tokens}
        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            try:
                r = await c.post(self.URL, json=payload, headers=headers)
                r.raise_for_status()
            except httpx.HTTPStatusError as e:
                self._http_error(e, "openai")
        text = r.json().get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        self._log_res("openai", len(text))
        return text


# ── HuggingFace Inference API ─────────────────────────────────────────────────

class HuggingFaceClient(LLMClient):
    """
    HuggingFace Serverless Inference API (free tier + PRO).
    Docs: https://huggingface.co/docs/api-inference/tasks/chat-completion

    Uses the OpenAI-compatible /v1/chat/completions endpoint that HF exposes
    for chat/instruct models.  Recommended models:
        meta-llama/Llama-3.1-8B-Instruct
        mistralai/Mistral-7B-Instruct-v0.3
        microsoft/Phi-3.5-mini-instruct
        Qwen/Qwen2.5-7B-Instruct

    Set HF_USE_ROUTER=true to use the newer router endpoint (higher throughput).
    """

    _URL_STANDARD = "https://api-inference.huggingface.co/models/{model}/v1/chat/completions"
    _URL_ROUTER   = "https://router.huggingface.co/hf-inference/models/{model}/v1/chat/completions"

    def __init__(self, api_key: str, model: str = "meta-llama/Llama-3.1-8B-Instruct",
                 temperature: float = 0.1, max_tokens: int = 2048,
                 timeout: float = 120.0, use_router: bool = False):
        if not api_key:
            raise ValueError("HF_API_KEY is required for the huggingface provider.")
        self.api_key     = api_key
        self.model       = model
        self.temperature = temperature
        self.max_tokens  = max_tokens
        self.timeout     = timeout
        template         = self._URL_ROUTER if use_router else self._URL_STANDARD
        self.endpoint    = template.format(model=model)

    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        self._log_req("huggingface", self.model, len(messages))
        payload = {"model": self.model, "messages": messages, "stream": False,
                   "temperature": self.temperature, "max_tokens": self.max_tokens}
        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            try:
                r = await c.post(self.endpoint, json=payload, headers=headers)
                r.raise_for_status()
            except httpx.HTTPStatusError as e:
                self._http_error(e, "huggingface")
        text = r.json().get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        self._log_res("huggingface", len(text))
        return text


# ── OpenAI-compatible (Groq, Together, Mistral, vLLM, LM Studio …) ───────────

class OpenAICompatibleClient(LLMClient):
    """
    Any server that speaks the OpenAI /v1/chat/completions spec.

    Provider          OPENAI_COMPATIBLE_BASE_URL
    ──────────────────────────────────────────────────────────
    Groq              https://api.groq.com/openai/v1
    Together.ai       https://api.together.xyz/v1
    Mistral AI        https://api.mistral.ai/v1
    Anyscale          https://api.endpoints.anyscale.com/v1
    Fireworks         https://api.fireworks.ai/inference/v1
    vLLM (local)      http://localhost:8000/v1
    LM Studio         http://localhost:1234/v1
    """

    def __init__(self, base_url: str, api_key: str, model: str,
                 temperature: float = 0.1, max_tokens: int = 2048, timeout: float = 60.0):
        if not base_url:
            raise ValueError(
                "OPENAI_COMPATIBLE_BASE_URL is required for the openai_compatible provider."
            )
        self.endpoint    = base_url.rstrip("/") + "/chat/completions"
        self.api_key     = api_key
        self.model       = model
        self.temperature = temperature
        self.max_tokens  = max_tokens
        self.timeout     = timeout

    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        tag = f"openai_compatible({self.model})"
        self._log_req(tag, self.model, len(messages))
        payload = {"model": self.model, "messages": messages,
                   "temperature": self.temperature, "max_tokens": self.max_tokens}
        headers: Dict[str, str] = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            try:
                r = await c.post(self.endpoint, json=payload, headers=headers)
                r.raise_for_status()
            except httpx.HTTPStatusError as e:
                self._http_error(e, tag)
        text = r.json().get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        self._log_res(tag, len(text))
        return text


# ── Anthropic ─────────────────────────────────────────────────────────────────

class AnthropicClient(LLMClient):
    """
    Anthropic Messages API — https://docs.anthropic.com/en/api/messages
    Models: claude-3-5-haiku-20241022, claude-3-5-sonnet-20241022, claude-3-opus-20240229
    """

    URL         = "https://api.anthropic.com/v1/messages"
    API_VERSION = "2023-06-01"

    def __init__(self, api_key: str, model: str = "claude-3-5-haiku-20241022",
                 temperature: float = 0.1, max_tokens: int = 2048, timeout: float = 60.0):
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY is required for the anthropic provider.")
        self.api_key     = api_key
        self.model       = model
        self.temperature = temperature
        self.max_tokens  = max_tokens
        self.timeout     = timeout

    async def complete(self, messages: List[Dict[str, Any]]) -> str:
        self._log_req("anthropic", self.model, len(messages))

        # Anthropic puts the system prompt in a top-level field, not in messages[]
        system_parts: List[str] = []
        conversation: List[Dict[str, str]] = []
        for msg in messages:
            if msg.get("role") == "system":
                system_parts.append(msg.get("content", ""))
            else:
                conversation.append({"role": msg["role"], "content": msg.get("content", "")})

        payload: Dict[str, Any] = {
            "model":       self.model,
            "max_tokens":  self.max_tokens,
            "temperature": self.temperature,
            "messages":    conversation,
        }
        if system_parts:
            payload["system"] = "\n\n".join(system_parts)

        headers = {
            "x-api-key":         self.api_key,
            "anthropic-version": self.API_VERSION,
            "Content-Type":      "application/json",
        }
        async with httpx.AsyncClient(timeout=self.timeout) as c:
            try:
                r = await c.post(self.URL, json=payload, headers=headers)
                r.raise_for_status()
            except httpx.HTTPStatusError as e:
                self._http_error(e, "anthropic")

        blocks = r.json().get("content", [])
        text = "".join(b.get("text", "") for b in blocks if b.get("type") == "text").strip()
        self._log_res("anthropic", len(text))
        return text


# ── Factory ───────────────────────────────────────────────────────────────────

def build_llm_client() -> LLMClient:
    """
    Instantiate and return the correct LLMClient for the configured LLM_PROVIDER.
    Called once at startup.  Fails fast if required env vars are missing.
    """
    from agent.config import (
        LLM_PROVIDER, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT,
        OLLAMA_BASE_URL, OLLAMA_MODEL,
        OPENAI_API_KEY, OPENAI_MODEL,
        HF_API_KEY, HF_MODEL, HF_USE_ROUTER,
        OPENAI_COMPATIBLE_BASE_URL, OPENAI_COMPATIBLE_API_KEY, OPENAI_COMPATIBLE_MODEL,
        ANTHROPIC_API_KEY, ANTHROPIC_MODEL,
    )

    p = LLM_PROVIDER.lower().strip()
    logger.info("Building LLM client for provider '%s'", p)

    if p == "ollama":
        return OllamaClient(OLLAMA_BASE_URL, OLLAMA_MODEL, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT)
    if p == "openai":
        return OpenAIClient(OPENAI_API_KEY, OPENAI_MODEL, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT)
    if p == "huggingface":
        return HuggingFaceClient(HF_API_KEY, HF_MODEL, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT, HF_USE_ROUTER)
    if p == "openai_compatible":
        return OpenAICompatibleClient(OPENAI_COMPATIBLE_BASE_URL, OPENAI_COMPATIBLE_API_KEY,
                                      OPENAI_COMPATIBLE_MODEL, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT)
    if p == "anthropic":
        return AnthropicClient(ANTHROPIC_API_KEY, ANTHROPIC_MODEL, LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT)

    raise ValueError(
        f"Unknown LLM_PROVIDER='{p}'. "
        "Valid options: ollama, openai, huggingface, openai_compatible, anthropic"
    )
