/**
 * proxy.js — forwards every request to BC using PowerShell's
 * Invoke-RestMethod -UseDefaultCredentials, which uses the Windows SSPI
 * stack (Negotiate/Kerberos/NTLM) exactly like a normal Windows client.
 *
 * Why PowerShell instead of an npm package:
 *   BC responds with "WWW-Authenticate: Negotiate", not plain "NTLM".
 *   Negotiate is SPNEGO-wrapped and requires the OS SSPI layer to handle
 *   the handshake.  Node has no native SSPI client.  PowerShell's
 *   System.Net.Http.HttpClient / WebClient DO have it, so we shell out.
 */

const { spawn } = require("child_process");
const {
  BC_HOST,
  BC_TIMEOUT_MS,
  odataBase,
  apiBase,
  webServiceBase,
  companyParam,
  companyId,
  BC_INSTANCE,
} = require("./config");

// ─── Endpoint mappings ──────────────────────────────────────────────────────
const webServiceEndpoints = new Set([
  "Login",
  "Me",
  "ChangePassword",
  "Logout",
  "AdminSetPassword",
  "FetchMachines",
  "getMachineOrders",
  "fetchOngoingOperationsState",
  "fetchOperationsHistory",
  "fetchOperationLiveData",
  "fetchProductionCycles",
  "fetchBom",
  "fetchAllItemBarcodes",
  "resolveBarcode",
  "startOperation",
  "declareProduction",
  "finishOperation",
  "cancelOperation",
  "pauseOperation",
  "resumeOperation",
  "declareScrap",
  "insertScans",
  "AdminCreateUser",
  "fetchAllMESUsers",
  "fetchMESUsersByWC",
  "AdminSetActive",
  "fetchActivityLog",
  "fetchMachineDashboard",
  "AdminChangeUserRole",
  "fetchProductionOrders",
  "fetchWorkCenterSummary",
  "fetchOperatorSummary",
  "fetchMyData",
  "fetchScrapSummary",
  "fetchDelayReport",
  "fetchConsumptionSummary",
  "fetchSupervisorOverview",
  "fetchAllEmployees"
]);

const apiBaseEndpoints = {
  scrapCodes: "scrapCodes",
  employees: "employees",
  workCenters: "workCenters",
};

// ─── Header filtering ────────────────────────────────────────────────────────
const HOP_BY_HOP = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailers",
  "transfer-encoding",
  "upgrade",
  "host",
  "accept-encoding",
  "authorization", // never forward Flutter's auth — SSPI sets its own
]);

const SKIP_RESPONSE = new Set([
  "access-control-allow-origin",
  "access-control-allow-credentials",
  "access-control-allow-methods",
  "access-control-allow-headers",
  "access-control-max-age",
  "transfer-encoding",
  "www-authenticate", // SSPI challenge — must not reach Flutter
]);

function buildTargetUrl(req) {
  const pathParts = req.path.split("/");
  if (pathParts.length === 3 && pathParts[1] === "api") {
    const endpoint = pathParts[2];
    if (webServiceEndpoints.has(endpoint)) {
      return `${webServiceBase}${endpoint}?${companyParam}`;
    } else if (apiBaseEndpoints[endpoint]) {
      return `${apiBase}/companies(${companyId})/${apiBaseEndpoints[endpoint]}`;
    }
  }
  // Fallback: strip /api and forward as before
  return `${BC_HOST}${req.originalUrl.replace(/^\/api/, "")}`;
}

function sanitizeRequestHeaders(headers) {
  const out = {};
  for (const [k, v] of Object.entries(headers)) {
    if (!HOP_BY_HOP.has(k.toLowerCase())) out[k] = v;
  }
  return out;
}

// ─── Logging helpers ─────────────────────────────────────────────────────────
// Derive a short host label from BC_HOST, e.g. "localhost:7048"
const bcHostLabel = (() => {
  try {
    return new URL(BC_HOST).host;
  } catch {
    return BC_HOST;
  }
})();
// Short company ID — first segment before the first dash
const companyShort = companyId.split("-")[0];

const STATUS_LABEL = (code) => {
  if (code >= 500) return `ERR ${code}`;
  if (code >= 400) return `BAD ${code}`;
  if (code >= 300) return `RDR ${code}`;
  return `OK  ${code}`;
};

function logContext() {
  console.log(
    `[proxy] ┌ BC instance : ${BC_INSTANCE}  host: ${bcHostLabel}  company: ${companyShort}…`,
  );
}

function logRequest(method, endpoint, clientIp, clientPort) {
  console.log(
    `[proxy] │ ▶  ${clientIp}:${clientPort} → BC   ${method.padEnd(6)} ${endpoint}`,
  );
}

function logResponse(
  method,
  endpoint,
  status,
  elapsedMs,
  clientIp,
  clientPort,
) {
  const label = STATUS_LABEL(status);
  console.log(
    `[proxy] └ ◀  BC → ${clientIp}:${clientPort}   ${label}    ${endpoint}   (${elapsedMs} ms)`,
  );
}

// ─── PowerShell runner ───────────────────────────────────────────────────────
function runPowerShell(psScript) {
  return new Promise((resolve, reject) => {
    const ps = spawn("powershell.exe", [
      "-NoProfile",
      "-NonInteractive",
      "-Command",
      psScript,
    ]);

    let stdout = "";
    let stderr = "";
    ps.stdout.on("data", (d) => {
      stdout += d.toString();
    });
    ps.stderr.on("data", (d) => {
      stderr += d.toString();
    });

    const timer = setTimeout(() => {
      ps.kill();
      reject(
        Object.assign(new Error("PowerShell process timed out"), {
          code: "ECONNABORTED",
        }),
      );
    }, BC_TIMEOUT_MS + 2000);

    ps.on("close", (code) => {
      clearTimeout(timer);
      if (stderr.trim()) console.warn("[ps-stderr]", stderr.trim());
      if (code !== 0)
        return reject(new Error(`PowerShell exited ${code}: ${stderr.trim()}`));
      try {
        const jsonLine = stdout
          .trim()
          .split("\n")
          .findLast((l) => l.trim().startsWith("{"));
        resolve(JSON.parse(jsonLine));
      } catch (e) {
        reject(
          new Error(
            `Failed to parse PowerShell output: ${stdout.slice(0, 300)}`,
          ),
        );
      }
    });
  });
}

function buildPsScript(method, url, headersObj, bodyBase64) {
  const headersJson = JSON.stringify(headersObj).replace(/'/g, "''");
  const bodyArg = bodyBase64 ? `'${bodyBase64}'` : "$null";

  return `
$ErrorActionPreference = 'Stop'

$headersMap = '${headersJson}' | ConvertFrom-Json
$method     = '${method}'
$url        = '${url.replace(/'/g, "''")}'
$bodyB64    = ${bodyArg}

Add-Type -AssemblyName System.Net.Http
$handler                      = [System.Net.Http.HttpClientHandler]::new()
$handler.UseDefaultCredentials = $true
$handler.AllowAutoRedirect     = $true
$client                        = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout                = [TimeSpan]::FromMilliseconds(${BC_TIMEOUT_MS})

$req = [System.Net.Http.HttpRequestMessage]::new(
  [System.Net.Http.HttpMethod]::new($method), $url
)

$contentType = $null
foreach ($prop in $headersMap.PSObject.Properties) {
  $name  = $prop.Name
  $value = $prop.Value
  if ($name -ieq 'content-type') { $contentType = $value; continue }
  try { [void]$req.Headers.TryAddWithoutValidation($name, $value) } catch {}
}

if ($bodyB64 -and $bodyB64 -ne '') {
  $bytes   = [Convert]::FromBase64String($bodyB64)
  $content = [System.Net.Http.ByteArrayContent]::new($bytes)
  if ($contentType) {
    $content.Headers.ContentType =
      [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($contentType)
  }
  $req.Content = $content
}

$resp    = $client.SendAsync($req).GetAwaiter().GetResult()
$bytes   = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
$b64Body = [Convert]::ToBase64String($bytes)

$respHeaders = @{}
foreach ($h in $resp.Headers)         { $respHeaders[$h.Key] = ($h.Value | Select-Object -First 1) }
foreach ($h in $resp.Content.Headers) { $respHeaders[$h.Key] = ($h.Value | Select-Object -First 1) }

$result = @{
  status     = [int]$resp.StatusCode
  headers    = $respHeaders
  bodyBase64 = $b64Body
}

$result | ConvertTo-Json -Compress -Depth 5
`;
}

// ─── Main handler ────────────────────────────────────────────────────────────
async function forwardRequest(req, res) {
  const url = buildTargetUrl(req);
  const headers = sanitizeRequestHeaders(req.headers);
  const method = req.method;
  // Endpoint label: last path segment without query string
  const endpoint = req.path.split("/").filter(Boolean).pop() || req.path;

  let bodyBase64 = "";
  if (!["GET", "HEAD"].includes(method)) {
    const raw = req.is("application/json")
      ? JSON.stringify(req.body)
      : req.body
        ? String(req.body)
        : "";
    if (raw) bodyBase64 = Buffer.from(raw).toString("base64");
  }

  logContext();
  const clientIp = req.socket.remoteAddress || req.ip || "unknown";
  const clientPort = req.socket.remotePort || "?";
  logRequest(method, endpoint, clientIp, clientPort);

  const t0 = Date.now();

  let result;
  try {
    const psScript = buildPsScript(method, url, headers, bodyBase64);
    result = await runPowerShell(psScript);
  } catch (err) {
    const elapsed = Date.now() - t0;
    if (err.code === "ECONNABORTED") {
      logResponse(method, endpoint, 504, elapsed, clientIp, clientPort);
      return res
        .status(504)
        .json({ error: "Gateway timeout", message: err.message });
    }
    console.error(
      `[proxy] └ ✖  PowerShell error after ${elapsed} ms:`,
      err.message,
    );
    return res.status(502).json({ error: "Bad gateway", message: err.message });
  }

  logResponse(
    method,
    endpoint,
    result.status,
    Date.now() - t0,
    clientIp,
    clientPort,
  );

  res.status(result.status);

  if (result.headers && typeof result.headers === "object") {
    for (const [k, v] of Object.entries(result.headers)) {
      if (!SKIP_RESPONSE.has(k.toLowerCase())) {
        try {
          res.setHeader(k, v);
        } catch (_) {
          /* ignore malformed headers */
        }
      }
    }
  }

  res.send(Buffer.from(result.bodyBase64 || "", "base64"));
}

module.exports = { forwardRequest };
