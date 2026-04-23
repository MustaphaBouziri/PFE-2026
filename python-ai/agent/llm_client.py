"""
agent/llm_client.py

Thin async wrapper around the Ollama /api/chat endpoint.
Handles tool-call round-trips and message history.
"""

from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional, Tuple

import httpx

from agent.config import OLLAMA_BASE_URL, OLLAMA_MODEL, OLLAMA_TEMPERATURE

logger = logging.getLogger("mes-ai.llm")


class OllamaClient:
    def __init__(self):
        self.base_url = OLLAMA_BASE_URL
        self.model = OLLAMA_MODEL
        self.temperature = OLLAMA_TEMPERATURE

    async def chat(
        self,
        messages: List[Dict[str, Any]],
        tools: Optional[List[Dict[str, Any]]] = None,
    ) -> Dict[str, Any]:
        """
        Send a chat request to Ollama.
        Returns the full message dict from the response.
        """
        payload: Dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": self.temperature,
                "num_predict": 2048,
            },
        }
        if tools:
            payload["tools"] = tools

        async with httpx.AsyncClient(timeout=120) as client:
            try:
                resp = await client.post(
                    f"{self.base_url}/api/chat",
                    json=payload,
                )
                resp.raise_for_status()
                body = resp.json()
                return body.get("message", {})
            except httpx.HTTPStatusError as e:
                logger.error("Ollama HTTP error %s: %s", e.response.status_code, e.response.text)
                raise
            except Exception as e:
                logger.error("Ollama request failed: %s", e)
                raise

    def extract_tool_calls(self, message: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extract tool_calls from an Ollama message.
        Returns list of { "name": str, "arguments": dict }
        """
        raw = message.get("tool_calls", [])
        result = []
        for call in raw:
            fn = call.get("function", {})
            name = fn.get("name", "")
            args = fn.get("arguments", {})
            if isinstance(args, str):
                try:
                    args = json.loads(args)
                except json.JSONDecodeError:
                    args = {}
            if name:
                result.append({"name": name, "arguments": args})
        return result

    def has_tool_calls(self, message: Dict[str, Any]) -> bool:
        return bool(message.get("tool_calls"))

    async def simple_completion(self, prompt: str) -> str:
        """One-shot completion — used for intent classification and action extraction."""
        message = await self.chat([{"role": "user", "content": prompt}])
        return message.get("content", "").strip()
