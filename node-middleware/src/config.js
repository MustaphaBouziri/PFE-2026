require("dotenv").config();

function require_env(key) {
  const val = process.env[key];
  if (!val) throw new Error(`Missing required env var: ${key}`);
  return val;
}

module.exports = {
  BC_HOST: require_env("BC_HOST").replace(/\/$/, ""), // strip trailing slash
  BC_INSTANCE: require_env("BC_INSTANCE"),
  BC_COMPANY: require_env("BC_COMPANY"),
  PORT: parseInt(process.env.PROXY_PORT || "3000", 10),
  NODE_ENV: process.env.NODE_ENV || "development",
  ALLOWED_ORIGINS: (process.env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((s) => s.trim()),
  BC_TIMEOUT_MS: parseInt(process.env.BC_TIMEOUT_MS || "30000", 10),
  RATE_LIMIT_WINDOW: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "900000", 10),
  RATE_LIMIT_MAX: parseInt(process.env.RATE_LIMIT_MAX || "200", 10),

  // No credential config needed — proxy.js shells out to PowerShell which uses
  // the Windows session's SSPI credentials (same as -UseDefaultCredentials).
};
