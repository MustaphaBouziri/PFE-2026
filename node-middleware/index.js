const express = require("express");
const cors = require("cors");
const corsOptions = require("./src/cors");
const { forwardRequest } = require("./src/proxy");
const config = require("./src/config");

const app = express();

// 1. Trust proxy headers if behind nginx/load balancer
if (config.NODE_ENV === "production") app.set("trust proxy", 1);

// 2. Minimal request logger — only for routes NOT handled by the proxy
//    (the proxy emits its own structured log lines)
app.use((req, _res, next) => {
  if (!req.path.startsWith("/api/")) {
    console.log(`[http]  ${req.method.padEnd(6)} ${req.originalUrl}`);
  }
  next();
});

// 3. Parse JSON bodies
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: false }));

// 4. CORS — must come BEFORE routes
app.use(cors(corsOptions));

// 5. Health check — no auth, no rate limiting, no forwarding
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// 6. Preflight handler
app.options("/api/{*path}", cors(corsOptions));

// 7. THE MAIN ROUTE — forward everything to BC
app.all("/api/{*path}", forwardRequest);

// 8. 404 for anything that isn't /api/* or /health
app.use((req, res) => {
  res.status(404).json({
    error: "Not found",
    message: `Route ${req.method} ${req.originalUrl} does not exist on this proxy.`,
  });
});

// 9. Global error handler
app.use((err, req, res, _next) => {
  console.error("[error]", err.message);
  if (err.message.startsWith("CORS:")) {
    return res.status(403).json({ error: "CORS", message: err.message });
  }
  res.status(500).json({ error: "Internal error", message: err.message });
});

app.listen(config.PORT, () => {
  console.log(`\n  MES proxy running on port ${config.PORT}`);
  console.log(`  Forwarding /api/{*path} → ${config.BC_HOST}`);
  console.log(`  Allowed origins: ${config.ALLOWED_ORIGINS.join(", ")}\n`);
});
