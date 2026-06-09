# node-middleware — Module Reference Document

---

## Module Overview

**Directory:** `node-middleware/`
**Runtime:** Node.js (CommonJS)
**Framework:** Express 5.x
**Entry point:** `index.js`
**Purpose:** Acts as a reverse proxy layer sitting between two upstream consumers (Flutter mobile frontend and Python MES AI agent) and one downstream target (Business Central ERP). All Business Central communication is delegated to PowerShell subprocesses that use Windows SSPI (Negotiate/Kerberos/NTLM) credentials. The AI agent traffic is forwarded over plain HTTP fetch.

---

## File Inventory

```
node-middleware/
├── index.js          — Express app bootstrap, middleware stack, route mounting
├── package.json      — Dependencies and npm scripts
├── .env.example      — Environment variable template
└── src/
    ├── aiProxy.js    — Router: forwards /api/ai/* to Python AI agent
    ├── config.js     — Env loading, validation, computed URL constants
    ├── cors.js       — CORS options object
    └── proxy.js      — BC proxy: URL mapping, PowerShell runner, request forwarding
```

---

## `index.js`

### Role
Application entry point. Constructs and configures the Express app, applies global middleware in order, mounts routers, and starts the HTTP server.

### Middleware registration order
1. `trust proxy` flag (production only) — trusts `X-Forwarded-*` headers from nginx/load balancer.
2. Request logger — logs `[http] METHOD path` for any route that does NOT start with `/api/`. Routes starting with `/api/` emit their own structured logs from `proxy.js`.
3. `express.json({ limit: "10mb" })` — parses JSON request bodies, up to 10 MB.
4. `express.urlencoded({ extended: false })` — parses URL-encoded bodies.
5. `cors(corsOptions)` — applies CORS headers using the options from `src/cors.js`. Must run before route handlers.

### Routes mounted (in order)
| Path | Handler | Source |
|---|---|---|
| `GET /health` | Inline handler — returns `{ status, uptime, timestamp }` | `index.js` |
| `OPTIONS /api/{*path}` | `cors(corsOptions)` preflight handler | `index.js` |
| `* /api/ai/*` | `aiRouter` | `src/aiProxy.js` |
| `* /api/{*path}` | `forwardRequest` | `src/proxy.js` |
| `* *` (catch-all) | 404 JSON response | `index.js` |

### Error handlers (registered last)
- **Global error handler:** Catches errors passed via `next(err)`. Returns 403 for messages prefixed with `"CORS:"`, 500 for all others. Logs `[error] <message>`.

### Server startup
Calls `app.listen(config.PORT)`. Logs proxy port, BC forwarding target, and allowed origins on start.

### Imports
- `express` — framework
- `cors` — npm CORS middleware
- `./src/cors` — CORS options object
- `./src/proxy` → `forwardRequest` function
- `./src/aiProxy` → `aiRouter` Express Router
- `./src/config` — config constants (PORT, BC_HOST, ALLOWED_ORIGINS)

---

## `src/config.js`

### Role
Loads and validates all environment variables. Exports computed URL fragments used by `proxy.js` to construct target URLs.

### Environment variables consumed
| Variable | Required | Default | Description |
|---|---|---|---|
| `BC_HOST` | Yes | — | Base URL of the Business Central server (trailing slash stripped) |
| `BC_INSTANCE` | Yes | — | BC server instance name |
| `BC_COMPANY` | Yes | — | BC company GUID |
| `PROXY_PORT` | No | `3000` | Port the proxy listens on |
| `NODE_ENV` | No | `development` | Node environment |
| `ALLOWED_ORIGINS` | No | `""` | Comma-separated list of allowed CORS origins |
| `BC_TIMEOUT_MS` | No | `30000` | Timeout in ms for BC requests |
| `RATE_LIMIT_WINDOW_MS` | No | `900000` | Rate limit rolling window in ms |
| `RATE_LIMIT_MAX` | No | `200` | Max requests per window |

### `require_env(key)`
Internal helper. Throws `Error("Missing required env var: <key>")` if the variable is absent or empty.

### Exported constants
| Export | Value | Description |
|---|---|---|
| `BC_HOST` | env `BC_HOST` (trailing slash removed) | Raw BC server base URL |
| `BC_INSTANCE` | env `BC_INSTANCE` | Instance name |
| `BC_COMPANY` | env `BC_COMPANY` | Company GUID |
| `PORT` | `parseInt(PROXY_PORT \|\| "3000")` | Listening port |
| `NODE_ENV` | env or `"development"` | Environment flag |
| `ALLOWED_ORIGINS` | `string.split(",").map(trim)` | Array of allowed origins |
| `BC_TIMEOUT_MS` | `parseInt(...)` | Timeout in ms |
| `RATE_LIMIT_WINDOW` | `parseInt(...)` | Rate limit window ms |
| `RATE_LIMIT_MAX` | `parseInt(...)` | Rate limit max requests |
| `odataBase` | `BC_HOST/BC_INSTANCE/ODataV4` | OData v4 root URL |
| `apiBase` | `BC_HOST/BC_INSTANCE/api/yourcompany/v1/v1.0` | Custom API root URL |
| `webServiceBase` | `odataBase/MESWebService_` | Prefix for all AL web service endpoints |
| `companyParam` | `company=BC_COMPANY` | Query string appended to web service calls |
| `companyId` | `BC_COMPANY` | Raw company GUID (used in URL paths for apiBase) |

### Note on credentials
No credential exports. `proxy.js` uses Windows SSPI via PowerShell (`-UseDefaultCredentials`), so no username/password needs to be injected into HTTP headers.

---

## `src/cors.js`

### Role
Exports a plain options object consumed by the `cors` npm middleware in `index.js`.

### Exported object
| Option | Value | Effect |
|---|---|---|
| `origin` | Function that always calls `callback(null, true)` | Allows all origins unconditionally |
| `credentials` | `true` | Sends `Access-Control-Allow-Credentials: true` |
| `methods` | `['GET','POST','PUT','DELETE','PATCH','OPTIONS']` | Allowed HTTP methods |
| `allowedHeaders` | `['Content-Type','Authorization','X-Auth-Token']` | Headers clients may send |
| `exposedHeaders` | `['Content-Type']` | Headers exposed to browser JS |
| `optionsSuccessStatus` | `200` | Preflight response status (not 204, for older browsers) |
| `maxAge` | `3600` | Preflight cache duration in seconds |

---

## `src/proxy.js`

### Role
Handles all requests matched by `app.all("/api/{*path}")` in `index.js`. Determines the correct BC target URL, serializes the request body to base64, builds a PowerShell script, spawns a PowerShell subprocess to execute the HTTP call against BC using SSPI, parses the JSON result, and writes the response back to Express.

### Imports
- `child_process.spawn` — Node built-in for spawning PowerShell
- `./config` → `BC_HOST`, `BC_TIMEOUT_MS`, `odataBase`, `apiBase`, `webServiceBase`, `companyParam`, `companyId`, `BC_INSTANCE`

---

### Data: `webServiceEndpoints` (Set)
A `Set<string>` of AL codeunit web service endpoint names. These are the last path segment that triggers the `webServiceBase` URL prefix logic.

Current members (44 entries):
`Login`, `Me`, `ChangePassword`, `Logout`, `AdminSetPassword`, `FetchMachines`, `getMachineOrders`, `fetchOngoingOperationsState`, `fetchOperationsHistory`, `fetchOperationLiveData`, `fetchProductionCycles`, `fetchBom`, `fetchAllItemBarcodes`, `resolveBarcode`, `startOperation`, `declareProduction`, `finishOperation`, `cancelOperation`, `pauseOperation`, `resumeOperation`, `declareScrap`, `insertScans`, `AdminCreateUser`, `fetchAllMESUsers`, `fetchMESUsersByWC`, `AdminSetActive`, `fetchActivityLog`, `fetchMachineDashboard`, `AdminChangeUserRole`, `fetchProductionOrders`, `fetchWorkCenterSummary`, `fetchOperatorSummary`, `fetchMyData`, `fetchScrapSummary`, `fetchDelayReport`, `VerifyBadge`, `GetBadgeSecret`, `RegenerateBadgeSecret`, `fetchConsumptionSummary`, `fetchSupervisorOverview`, `fetchAllEmployees`, `updateSettings`, `fetchSettings`

### Data: `apiBaseEndpoints` (Object)
Maps path segment strings to BC Custom API resource names.
```
"scrapCodes"  → "scrapCodes"
"employees"   → "employees"
"workCenters" → "workCenters"
```

### Data: `HOP_BY_HOP` (Set)
Headers removed from incoming requests before forwarding to BC. Includes: `connection`, `keep-alive`, `proxy-authenticate`, `proxy-authorization`, `te`, `trailers`, `transfer-encoding`, `upgrade`, `host`, `accept-encoding`, `authorization`. The `authorization` header is explicitly dropped so that Flutter's auth token never reaches BC — SSPI sets its own.

### Data: `SKIP_RESPONSE` (Set)
Headers from BC that are not forwarded back to the client. Includes all `access-control-*` headers (Express CORS middleware re-adds its own), `transfer-encoding`, and `www-authenticate` (SSPI challenge must not be seen by Flutter).

---

### `buildTargetUrl(req)` → `string`
**Input:** Express `req` object.
**Logic:**
1. Splits `req.path` by `/`.
2. If `pathParts.length === 3` and `pathParts[1] === "api"`, extracts `endpoint = pathParts[2]`.
   - If `endpoint` is in `webServiceEndpoints` → returns `webServiceBase + endpoint + "?" + companyParam`.
     - Resulting shape: `<BC_HOST>/<BC_INSTANCE>/ODataV4/MESWebService_<endpoint>?company=<BC_COMPANY>`
   - Else if `endpoint` is in `apiBaseEndpoints` → returns `apiBase + "/companies(" + companyId + ")/" + apiBaseEndpoints[endpoint]`.
     - Resulting shape: `<BC_HOST>/<BC_INSTANCE>/api/yourcompany/v1/v1.0/companies(<GUID>)/<resource>`
3. Fallback: strips `/api` prefix from `req.originalUrl` and appends to `BC_HOST`.

### `sanitizeRequestHeaders(headers)` → `object`
**Input:** Raw headers object from `req.headers`.
**Logic:** Returns a new object with all keys in `HOP_BY_HOP` removed (case-insensitive match).

### `runPowerShell(psScript)` → `Promise<object>`
**Input:** A PowerShell script string.
**Logic:**
1. Spawns `powershell.exe -NoProfile -NonInteractive -Command <psScript>`.
2. Collects `stdout` and `stderr` string buffers.
3. Sets a kill timer at `BC_TIMEOUT_MS + 2000` ms. On trigger: kills process, rejects with `{ code: "ECONNABORTED" }`.
4. On process close with non-zero exit code: rejects with the stderr content.
5. On success: takes the last line of stdout that starts with `{`, parses it as JSON, and resolves with the parsed object.
6. On JSON parse failure: rejects with an error containing the first 300 chars of stdout.

**Returned object shape (from PowerShell):**
```json
{
  "status": <int HTTP status code>,
  "headers": { "<header-name>": "<first-value>", ... },
  "bodyBase64": "<base64-encoded response body>"
}
```

### `buildPsScript(method, url, headersObj, bodyBase64)` → `string`
**Input:** HTTP method string, target URL string, sanitized headers object, base64-encoded body string (may be empty).
**Output:** A PowerShell script string that:
1. Sets `$ErrorActionPreference = 'Stop'`.
2. Deserializes `headersObj` from JSON into a PS object.
3. Creates `System.Net.Http.HttpClientHandler` with `UseDefaultCredentials = $true` and `AllowAutoRedirect = $true`.
4. Creates `System.Net.Http.HttpClient` with the handler. Sets `.Timeout` from `BC_TIMEOUT_MS`.
5. Builds an `HttpRequestMessage` for the given method and URL.
6. Iterates over headers: adds all except `content-type` to `$req.Headers`; saves `content-type` separately.
7. If `bodyBase64` is non-empty: decodes from base64 to `byte[]`, creates `ByteArrayContent`, sets `ContentType` header, assigns to `$req.Content`.
8. Calls `$client.SendAsync($req).GetAwaiter().GetResult()`.
9. Reads response body as `byte[]`, encodes to base64 string.
10. Collects both `$resp.Headers` and `$resp.Content.Headers` into a hashtable (first value per key).
11. Outputs a JSON object with `status`, `headers`, `bodyBase64` via `ConvertTo-Json -Compress -Depth 5`.

### `forwardRequest(req, res)` (async) — Main Express handler
**Registered on:** `app.all("/api/{*path}")` in `index.js`.
**Logic:**
1. Calls `buildTargetUrl(req)` to get `url`.
2. Calls `sanitizeRequestHeaders(req.headers)` to get `headers`.
3. For non-GET/HEAD methods: serializes `req.body` to JSON string (or raw string), then encodes to base64 as `bodyBase64`. Empty string if no body.
4. Logs context with `logContext()`, client IP/port, method, and endpoint label.
5. Calls `buildPsScript(method, url, headers, bodyBase64)`.
6. Calls `runPowerShell(psScript)`.
7. On success: sets `res.status(result.status)`, iterates `result.headers` and calls `res.setHeader(k, v)` for each key not in `SKIP_RESPONSE`, then sends `Buffer.from(result.bodyBase64, "base64")`.
8. On `ECONNABORTED`: responds 504 with `{ error: "Gateway timeout" }`.
9. On other errors: responds 502 with `{ error: "Bad gateway" }`.

### Logging helpers
| Function | Output format |
|---|---|
| `logContext()` | `[proxy] ┌ BC instance: <BC_INSTANCE>  host: <host>  company: <short>…` |
| `logRequest(method, endpoint, ip, port)` | `[proxy] │ ▶  <ip>:<port> → BC   <METHOD> <endpoint>` |
| `logResponse(method, endpoint, status, ms, ip, port)` | `[proxy] └ ◀  BC → <ip>:<port>   <label>    <endpoint>   (<ms> ms)` |
| `STATUS_LABEL(code)` | `"OK  <code>"` / `"RDR <code>"` / `"BAD <code>"` / `"ERR <code>"` |

`bcHostLabel` — derived from `new URL(BC_HOST).host` (falls back to raw string on parse error).
`companyShort` — first segment of `companyId` before the first `-`.

---

## `src/aiProxy.js`

### Role
Express Router mounted at `/api/ai` in `index.js`. Proxies requests to the Python FastAPI MES AI agent. Has no BC involvement. Uses native `fetch` (Node 18+).

### Constants
| Constant | Source | Default |
|---|---|---|
| `AI_AGENT_URL` | `process.env.AI_AGENT_URL` | `http://localhost:8000` |
| `AI_TIMEOUT_MS` | `process.env.AI_TIMEOUT_MS` | `60000` |

### Routes

#### `POST /chat`
**Full path when mounted:** `POST /api/ai/chat`

**Expected request body (from Flutter):**
```json
{
  "message": "string",
  "user_context": {
    "user_id": "string",
    "role": "string",
    "work_centers": ["string"],
    "token": "string"
  },
  "conversation_history": [
    { "role": "user|assistant", "content": "string" }
  ]
}
```

**Validation:** Returns 400 if `message` or `user_context` is absent.

**Forwarding logic:**
1. Constructs `payload = { message, user_context, conversation_history: conversation_history || [] }`.
2. Creates an `AbortController`. Sets a `setTimeout` for `AI_TIMEOUT_MS` that calls `controller.abort()`.
3. Calls `fetch(AI_AGENT_URL + "/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload), signal })`.
4. Clears the timeout on response.
5. If `agentRes.ok` is false: reads body as text, logs error, returns 502 `{ error: "AI agent error" }`.
6. If successful: parses JSON, logs action count and text length, returns JSON to caller.
7. On `AbortError`: returns 504 `{ error: "Gateway timeout" }`.
8. On other fetch errors: returns 502 `{ error: "Bad gateway" }`.

**Response to Flutter:** Whatever the Python agent returns (pass-through JSON).

#### `GET /health`
**Full path when mounted:** `GET /api/ai/health`

**Logic:**
1. Creates an `AbortController` with a 3000 ms timeout.
2. Fetches `AI_AGENT_URL + "/health"`.
3. On success: returns `{ node_proxy: "ok", python_agent: <agent's response JSON> }`.
4. On error: returns 503 `{ node_proxy: "ok", python_agent: "unreachable", error: <message> }`.

---

## `package.json`

### Scripts
| Script | Command | Purpose |
|---|---|---|
| `start` | `node index.js` | Production start |
| `dev` | `nodemon index.js` | Development start with auto-reload |
| `test` | `node -e "require('./src/config')" && echo 'Config OK'` | Validates all required env vars are set |

### Dependencies
| Package | Version | Usage |
|---|---|---|
| `cors` | ^2.8.6 | CORS middleware in `index.js` |
| `dotenv` | ^17.4.2 | Env loading in `config.js` |
| `express` | ^5.2.1 | HTTP framework |
| `express-rate-limit` | ^8.3.2 | Imported in package but not yet wired into any route |
| `morgan` | ^1.10.1 | Imported in package but not yet wired in |

### Dev dependencies
| Package | Version | Usage |
|---|---|---|
| `nodemon` | ^3.1.14 | Auto-reload in dev mode |

---

## `.env.example`

Documents all expected environment variables. Full variable list:

| Variable | Example value | Notes |
|---|---|---|
| `BC_HOST` | `https://your-bc-server.example.com` | No trailing slash |
| `BC_INSTANCE` | `YourBCInstance` | BC server instance |
| `BC_COMPANY` | `YourCompanyGUID` | Company GUID string |
| `PROXY_PORT` | `3000` | Listening port |
| `NODE_ENV` | `development` | `production` enables trust proxy |
| `ALLOWED_ORIGINS` | `http://localhost:8080,...` | Comma-separated list |
| `BC_TIMEOUT_MS` | `30000` | BC request timeout |
| `RATE_LIMIT_WINDOW_MS` | `900000` | 15 minutes |
| `RATE_LIMIT_MAX` | `200` | Max requests per window |
| `BC_DOMAIN` | `CONTOSO` | Windows domain for SSPI (used by PowerShell session, not directly by config.js) |
| `BC_USERNAME` | `svc-mes-proxy` | Windows service account |
| `BC_PASSWORD` | — | Service account password |

**Note:** `BC_DOMAIN`, `BC_USERNAME`, `BC_PASSWORD` appear in `.env.example` but are not read by `config.js`. They document the Windows identity the Node process should run under so that SSPI negotiation in PowerShell picks up the correct credentials automatically.

---

## Cross-file Call Graph

```
index.js
├── requires src/config.js          (PORT, BC_HOST, ALLOWED_ORIGINS)
├── requires src/cors.js            (corsOptions object)
├── requires src/proxy.js           (forwardRequest function)
└── requires src/aiProxy.js         (aiRouter Express.Router)

src/proxy.js
└── requires src/config.js          (BC_HOST, BC_TIMEOUT_MS, odataBase, apiBase,
                                      webServiceBase, companyParam, companyId, BC_INSTANCE)

src/aiProxy.js
└── reads process.env directly      (AI_AGENT_URL, AI_TIMEOUT_MS)
    (no require of config.js)

src/cors.js
└── no requires — pure config object

src/config.js
└── requires dotenv                 (loads .env into process.env)
```

---

## Request Routing Decision Tree

```
Incoming request
│
├── GET /health
│   └── Handled inline in index.js → { status, uptime, timestamp }
│
├── OPTIONS /api/*
│   └── CORS preflight → 200
│
├── * /api/ai/chat     (POST)
│   └── aiProxy.js: validate → fetch Python agent /chat → return agent JSON
│
├── * /api/ai/health   (GET)
│   └── aiProxy.js: fetch Python agent /health → return combined JSON
│
├── * /api/<endpoint>
│   └── proxy.js buildTargetUrl:
│       ├── endpoint in webServiceEndpoints?
│       │   └── URL = webServiceBase + endpoint + "?company=<GUID>"
│       ├── endpoint in apiBaseEndpoints?
│       │   └── URL = apiBase + "/companies(<GUID>)/" + resource
│       └── fallback: BC_HOST + originalUrl (stripped /api prefix)
│       └── runPowerShell → PowerShell HttpClient SSPI → return response
│
└── * (anything else)
    └── 404 JSON
```

---

## BC URL Construction Examples

Given:
- `BC_HOST = https://bc.contoso.local:7048`
- `BC_INSTANCE = MyBC`
- `BC_COMPANY = 00000000-0000-0000-0000-000000000001`

| Incoming path | Resolved BC URL |
|---|---|
| `/api/FetchMachines` | `https://bc.contoso.local:7048/MyBC/ODataV4/MESWebService_FetchMachines?company=00000000-0000-0000-0000-000000000001` |
| `/api/getMachineOrders` | `https://bc.contoso.local:7048/MyBC/ODataV4/MESWebService_getMachineOrders?company=00000000-0000-0000-0000-000000000001` |
| `/api/scrapCodes` | `https://bc.contoso.local:7048/MyBC/api/yourcompany/v1/v1.0/companies(00000000-0000-0000-0000-000000000001)/scrapCodes` |
| `/api/employees` | `https://bc.contoso.local:7048/MyBC/api/yourcompany/v1/v1.0/companies(00000000-0000-0000-0000-000000000001)/employees` |
| `/api/anything-else/foo` | `https://bc.contoso.local:7048/anything-else/foo` (fallback) |