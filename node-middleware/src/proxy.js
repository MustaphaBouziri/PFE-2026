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
const { BC_HOST, BC_TIMEOUT_MS, odataBase, apiBase, webServiceBase, companyParam, companyId } = require("./config");

// ─── Endpoint mappings ───────────────────────────────────────────────────────
const webServiceEndpoints = new Set([
  'Login', 'Me', 'ChangePassword', 'Logout', 'AdminSetPassword',
  'FetchMachines', 'getMachineOrders', 'fetchOngoingOperationsState',
  'fetchOperationsHistory', 'fetchOperationLiveData', 'fetchProductionCycles',
  'fetchBom', 'fetchAllItemBarcodes', 'resolveBarcode',
  'startOperation', 'declareProduction', 'finishOperation', 'cancelOperation',
  'pauseOperation', 'resumeOperation', 'declareScrap', 'insertScans',
  'AdminCreateUser', 'fetchAllMESUsers', 'fetchMESUsersByWC',
  'AdminSetActive', 'fetchActivityLog', 'fetchMachineDashboard',
  'AdminChangeUserRole'
]);

const apiBaseEndpoints = {
  scrapCodes: 'scrapCodes',
  employees: 'employees',
  workCenters: 'workCenters',
};

// ─── Header filtering ─────────────────────────────────────────────────────────
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
  const pathParts = req.path.split('/');
  if (pathParts.length === 3 && pathParts[1] === 'api') {
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

// ─── PowerShell runner ────────────────────────────────────────────────────────
/**
 * Builds and executes a PowerShell script that:
 *  1. Creates an HttpClientHandler with UseDefaultCredentials = true
 *  2. Sends the request with all forwarded headers + body
 *  3. Prints a JSON envelope: { status, headers, bodyBase64 }
 *
 * Returns that parsed envelope.
 */
function runPowerShell(psScript) {
  return new Promise((resolve, reject) => {
    // -NoProfile -NonInteractive keeps startup fast
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
    }, BC_TIMEOUT_MS + 2000); // extra 2 s over the HTTP timeout

    ps.on("close", (code) => {
      clearTimeout(timer);
      if (stderr.trim()) console.warn("[ps-stderr]", stderr.trim());
      if (code !== 0)
        return reject(new Error(`PowerShell exited ${code}: ${stderr.trim()}`));
      try {
        // The script prints exactly one JSON line to stdout
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

/**
 * Builds the PowerShell script string for a given request.
 * We pass everything as JSON inside a here-string so we never
 * have to worry about shell-escaping individual header values.
 */
function buildPsScript(method, url, headersObj, bodyBase64) {
  // Serialise the headers map and body as a JSON literal embedded in the script.
  // PowerShell will parse it back with ConvertFrom-Json.
  const headersJson = JSON.stringify(headersObj).replace(/'/g, "''"); // escape PS single-quotes
  const bodyArg = bodyBase64 ? `'${bodyBase64}'` : "$null";

  return `
$ErrorActionPreference = 'Stop'

# ── Deserialise inputs ──────────────────────────────────────────────────────
$headersMap = '${headersJson}' | ConvertFrom-Json
$method     = '${method}'
$url        = '${url.replace(/'/g, "''")}'
$bodyB64    = ${bodyArg}

# ── Build HttpClient with SSPI (UseDefaultCredentials) ─────────────────────
Add-Type -AssemblyName System.Net.Http
$handler                      = [System.Net.Http.HttpClientHandler]::new()
$handler.UseDefaultCredentials = $true
$handler.AllowAutoRedirect     = $true
$client                        = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout                = [TimeSpan]::FromMilliseconds(${BC_TIMEOUT_MS})

# ── Build request message ───────────────────────────────────────────────────
$req = [System.Net.Http.HttpRequestMessage]::new(
  [System.Net.Http.HttpMethod]::new($method), $url
)

# Forward headers (skip Content-Type — goes on the content object)
$contentType = $null
foreach ($prop in $headersMap.PSObject.Properties) {
  $name  = $prop.Name
  $value = $prop.Value
  if ($name -ieq 'content-type') { $contentType = $value; continue }
  try { [void]$req.Headers.TryAddWithoutValidation($name, $value) } catch {}
}

# Attach body if present
if ($bodyB64 -and $bodyB64 -ne '') {
  $bytes   = [Convert]::FromBase64String($bodyB64)
  $content = [System.Net.Http.ByteArrayContent]::new($bytes)
  if ($contentType) {
    $content.Headers.ContentType =
      [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($contentType)
  }
  $req.Content = $content
}

# ── Send & collect response ─────────────────────────────────────────────────
$resp    = $client.SendAsync($req).GetAwaiter().GetResult()
$bytes   = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
$b64Body = [Convert]::ToBase64String($bytes)

# Collect response headers (flatten multi-value to first value for simplicity)
$respHeaders = @{}
foreach ($h in $resp.Headers)          { $respHeaders[$h.Key] = ($h.Value | Select-Object -First 1) }
foreach ($h in $resp.Content.Headers)  { $respHeaders[$h.Key] = ($h.Value | Select-Object -First 1) }

$result = @{
  status      = [int]$resp.StatusCode
  headers     = $respHeaders
  bodyBase64  = $b64Body
}

# Print ONE JSON line — this is what Node parses
$result | ConvertTo-Json -Compress -Depth 5
`;
}

// ─── Main handler ─────────────────────────────────────────────────────────────
async function forwardRequest(req, res) {
  const url = buildTargetUrl(req);
  const headers = sanitizeRequestHeaders(req.headers);
  const method = req.method;

  // Serialise body to base64 so it survives the PS boundary cleanly
  let bodyBase64 = "";
  if (!["GET", "HEAD"].includes(method)) {
    const raw = req.is("application/json")
      ? JSON.stringify(req.body)
      : req.body
        ? String(req.body)
        : "";
    if (raw) bodyBase64 = Buffer.from(raw).toString("base64");
  }

  console.log(`[proxy] ▶  ${method} ${url}`);

  let result;
  try {
    const psScript = buildPsScript(method, url, headers, bodyBase64);
    result = await runPowerShell(psScript);
  } catch (err) {
    if (err.code === "ECONNABORTED") {
      return res
        .status(504)
        .json({ error: "Gateway timeout", message: err.message });
    }
    console.error("[proxy] PowerShell error:", err.message);
    return res.status(502).json({ error: "Bad gateway", message: err.message });
  }

  console.log(`[proxy] ◀  ${result.status} ${url}`);

  res.status(result.status);

  // Forward BC response headers
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
