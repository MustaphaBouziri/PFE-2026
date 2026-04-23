/**
 * src/aiProxy.js
 *
 * Express router that proxies /api/ai/* requests to the Python MES AI agent.
 *
 * Mount in index.js with:
 *   const { aiRouter } = require('./src/aiProxy');
 *   app.use('/api/ai', aiRouter);
 *
 * The Python agent lives at AI_AGENT_URL (default http://localhost:8000).
 * This router:
 *   1. Validates required fields
 *   2. Forwards the full payload to the Python agent
 *   3. Returns the structured ChatResponse to Flutter
 *
 * BUG FIX: original used `require('node-fetch')` which is not listed in
 * package.json and would crash at startup.  Node 18+ ships native fetch —
 * no import needed.  If you must support Node < 18, add node-fetch@3 to
 * package.json and uncomment the dynamic import below.
 */

const express = require("express");

const AI_AGENT_URL = process.env.AI_AGENT_URL || "http://localhost:8000";
const AI_TIMEOUT_MS = parseInt(process.env.AI_TIMEOUT_MS || "60000", 10);

const aiRouter = express.Router();

// Uncomment if running Node < 18:
// let fetch;
// (async () => { fetch = (await import('node-fetch')).default; })();

/**
 * POST /api/ai/chat
 *
 * Body (from Flutter):
 * {
 *   "message": "What is the status of machine MC-001?",
 *   "user_context": {
 *     "user_id": "USR-001",
 *     "role": "Supervisor",
 *     "work_centers": ["100", "200"],
 *     "token": "<MES auth token>"
 *   },
 *   "conversation_history": [
 *     { "role": "user", "content": "..." },
 *     { "role": "assistant", "content": "..." }
 *   ]
 * }
 *
 * Response (to Flutter): ChatResponse schema from the Python agent.
 */
aiRouter.post("/chat", async (req, res) => {
  const { message, user_context, conversation_history } = req.body;

  if (!message || !user_context) {
    return res.status(400).json({
      error: "Bad request",
      message: "message and user_context are required",
    });
  }

  const payload = {
    message,
    user_context,
    conversation_history: conversation_history || [],
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

  try {
    console.log(`[ai-proxy] ▶  POST /chat — "${message.slice(0, 60)}…"`);

    const agentRes = await fetch(`${AI_AGENT_URL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!agentRes.ok) {
      const errText = await agentRes.text();
      console.error(`[ai-proxy] Agent returned ${agentRes.status}: ${errText}`);
      return res.status(502).json({
        error: "AI agent error",
        message: `Agent returned status ${agentRes.status}`,
      });
    }

    const data = await agentRes.json();
    console.log(
      `[ai-proxy] ◀  ${data.actions?.length || 0} actions, ${data.text?.length || 0} chars`,
    );
    return res.json(data);
  } catch (err) {
    clearTimeout(timeout);
    if (err.name === "AbortError") {
      console.error("[ai-proxy] AI agent timed out");
      return res.status(504).json({
        error: "Gateway timeout",
        message: "AI agent did not respond in time.",
      });
    }
    console.error("[ai-proxy] Error forwarding to AI agent:", err.message);
    return res.status(502).json({ error: "Bad gateway", message: err.message });
  }
});

/**
 * GET /api/ai/health
 * Proxies health check to the Python agent.
 */
aiRouter.get("/health", async (req, res) => {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    const r = await fetch(`${AI_AGENT_URL}/health`, {
      signal: controller.signal,
    });
    clearTimeout(timeout);
    const data = await r.json();
    res.json({ node_proxy: "ok", python_agent: data });
  } catch (err) {
    res
      .status(503)
      .json({
        node_proxy: "ok",
        python_agent: "unreachable",
        error: err.message,
      });
  }
});

module.exports = { aiRouter };
