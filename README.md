[french version](README.fr.md)


[frontend summary](sum.flutterFRONTEND.md)
[backend summary](sum.alBACKEND.md)
[middleware summary](sum.nodeMIDDLEWARE.md)





# **producTiv**

Production Deployment Plan

_Full end-to-end deployment guide - BC Extension · Node Proxy · Python AI · Flutter_

June 2026

# **1\. Pre-Deployment Prerequisites**

## **1.1 Infrastructure Requirements**

| **Component**           | **Requirement**                                                                                                                        |
|-------------------- |----------------------------------------------------------------------------------------------------------------------------------- |
| Business Central Server | BC 21 (Platform 21.0.0.0) or later; OData V4 enabled; development license for AL extension installation                                |
|                     |                                                                                                                                    |
| Proxy Server (Windows)  | Windows Server 2019+ or Windows 10/11; Node.js 18+ installed; domain-joined for SSPI; PowerShell 5.1+; .NET Framework 4.7+             |
|                     |                                                                                                                                    |
| AI Agent Server         | Linux or Windows; Python 3.10+; pip; 4 GB RAM minimum (8 GB recommended for local LLM); network access to chosen LLM endpoint          |
|                     |                                                                                                                                    |
| Network                 | Proxy server must reach BC server on OData port (default 7048 or 443); Flutter clients reach proxy server on PROXY_PORT (default 3000) |
|                     |                                                                                                                                    |
| LLM Provider            | One of: local Ollama instance, OpenAI API key, HuggingFace token, Groq/Together/Mistral API key, or Anthropic API key                  |
|                     |                                                                                                                                    |
| BC Configuration        | Company GUID, instance name, OData V4 enabled in BC Server configuration                                                               |
|                     |                                                                                                                                    |

## **1.2 Critical Security Actions (Before ANY Deployment)**

⚠ These must be completed before going live: 1. Remove src/3-CodeUnit/dev-toberemoved/MESDevSetup.al from the AL project entirely 2. Set allow_origins in main.py to your actual Flutter domain/IP (not \*) 3. Wire express-rate-limit into index.js routes

# **2\. Phase 1 - Business Central AL Extension**

## **2.1 Prepare the AL Project**

- Open the AL project in Visual Studio Code with the AL Language extension installed
- Verify app.json: confirm runtime = '10.0', platform = '21.0.0.0', application = '21.0.0.0'
- Delete or exclude src/3-CodeUnit/dev-toberemoved/MESDevSetup.al from compilation

## **2.2 Configure launch.json**

{ "version": "0.2.0", "configurations": \[{ "type": "al", "request": "launch", "name": "producTiv Production", "server": "<https://your-bc-server.example.com>", "serverInstance": "YourBCInstance", "tenant": "default", "authentication": "Windows", "startupObjectType": "Page", "startupObjectId": 50140 }\]}

## **2.3 Deploy the Extension**

- Run Ctrl+Shift+B (or F5) to publish the extension to BC
- Ensure the MES Web Service is published in BC: Admin → Web Services → verify 'MESWebService' with ServiceName and ObjectID 50126 is Active
- Alternatively, publish from WebServices.xml by importing it in BC (Settings → Customization → Web Services → Import)

## **2.4 Initial Setup**

- In BC: open Page 50140 (MES API Debug)
- Click 'Run Setup' - creates ADMIN user (id: ADMIN, authId: AUTH-ADMIN01) with temporary password '00000000' and registers the password expiry job queue
- IMMEDIATELY change the admin password via or Flutter login on first use (force-change flag is set)
- Create employee records in BC for all MES users before using Admin Create User in Flutter
- Assign Work Centers to Machine Centers in BC - these drive the machine list in Flutter

# **3\. Phase 2 - Node.js Middleware Proxy**

## **3.1 Install Node.js**

- Download and install Node.js 18 LTS from nodejs.org on the proxy Windows server
- Verify: node --version and npm --version in PowerShell

## **3.2 Deploy Application Files**

\# Copy node-middleware/ to the server, e.g. C:\\Apps\\producTiv-proxy\\cd C:\\Apps\\producTiv-proxynpm install

## **3.3 Configure Environment**

Copy .env.example to .env and populate all values:

BC_HOST=https://your-bc-server.example.comBC_INSTANCE=YourBCInstanceBC_COMPANY=YOUR-COMPANY-GUID-HEREPROXY_PORT=3000NODE_ENV=productionALLOWED_ORIGINS=<http://192.168.1.100,https://yourdomain.comBC_TIMEOUT_MS=30000RATE_LIMIT_WINDOW_MS=900000RATE_LIMIT_MAX=300AI_AGENT_URL=http://localhost:8000AI_TIMEOUT_MS=120000#> Windows service account that runs the Node process (for SSPI):# BC_DOMAIN=CONTOSO# BC_USERNAME=svc-mes-proxy# BC_PASSWORD=&lt;password&gt;

## **3.4 Wire Rate Limiting (Security Fix)**

In index.js, add the following before route mounting to activate rate limiting:

const rateLimit = require('express-rate-limit');const limiter = rateLimit({ windowMs: config.RATE_LIMIT_WINDOW, max: config.RATE_LIMIT_MAX, standardHeaders: true, legacyHeaders: false,});app.use('/api/', limiter);

## **3.5 Restrict CORS (Security Fix)**

In src/cors.js, replace the always-true origin function with a proper origin check:

const { ALLOWED_ORIGINS } = require('./config');module.exports = { origin: function(origin, callback) { if (!origin || ALLOWED_ORIGINS.includes(origin)) { callback(null, true); } else { callback(new Error('CORS: origin ' + origin + ' not allowed')); } }, // ... rest of options unchanged};

## **3.6 Run as a Windows Service**

- Install pm2 globally: npm install -g pm2

pm2 start index.js --name producTiv-proxypm2 savepm2 startup windowsservice# Follow the command output to register as a Windows service# Verify:pm2 statuscurl <http://localhost:3000/health>

## **3.7 Validate Configuration**

npm test # Validates all required env vars are loaded correctly

## 3.7 Recreate the communication layer

Based on the login schema of the installation of the business central you may need to recreate a portion of the code to use that schema which will be more secure than the current version that uses the current account of the logged in windows session which is susceptible to cyber threats

# **4\. Phase 3 - Python AI Agent**

## **4.1 Environment Setup**

\# Python 3.10+ requiredcd python-ai/python -m venv .venvsource .venv/bin/activate # Linux/macOS.venv\\Scripts\\activate # Windowspip install -r requirements.txt

## **4.2 Configure Environment**

Copy env.example to .env and set values based on chosen LLM provider:

\# Choose ONE provider:LLM_PROVIDER=anthropic # or ollama / openai / huggingface / openai_compatibleLLM_TEMPERATURE=0.1LLM_MAX_TOKENS=2048LLM_TIMEOUT=120# For Anthropic:ANTHROPIC_API_KEY=sk-ant-...ANTHROPIC_MODEL=claude-3-5-haiku-20241022# For Ollama (local, no cost):# LLM_PROVIDER=ollama# OLLAMA_BASE_URL=<http://localhost:11434#> OLLAMA_MODEL=llama3.1:8bMIDDLEWARE_BASE_URL=<http://localhost:3000/apiBC_COMPANY=YOUR-COMPANY-GUID-HERETOOL_HTTP_TIMEOUT=20LLM_MAX_CONTEXT_CHARS=12000DEBUG_DATA=false>

## **4.3** Configure **CORS**

In main.py, update allow_origins to restrict to the Node proxy server only:

app.add_middleware( CORSMiddleware, allow_origins=\["<http://localhost:3000>", "<http://YOUR-PROXY-SERVER-IP:3000"\>], allow_methods=\["POST", "GET", "OPTIONS"\], allow_headers=\["\*"\],)

## **4.4 Start the Agent**

\# Development:uvicorn main:app --reload --host 0.0.0.0 --port 8000# Production (with process manager):pip install gunicorngunicorn main:app -w 2 -k uvicorn.workers.UvicornWorker \\ --bind 0.0.0.0:8000 --timeout 150# On Linux - register with systemd (recommended):# See systemd service template below

## **4.5 Systemd Service (Linux)**

\[Unit\]Description=producTiv AI AgentAfter=network.target\[Service\]Type=simpleUser=mesaiWorkingDirectory=/opt/producTiv/python-aiEnvironmentFile=/opt/producTiv/python-ai/.envExecStart=/opt/producTiv/python-ai/.venv/bin/gunicorn main:app \\ -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --timeout 150Restart=on-failureRestartSec=5\[Install\]WantedBy=multi-user.target

## **4.6 Verify Agent**

curl <http://localhost:8000/health#> Expected: {"status": "ok"}# Via the Node proxy:curl <http://localhost:3000/api/ai/health#> Expected: {"node_proxy": "ok", "python_agent": {"status": "ok"}}

# **5\. Phase 4 - Flutter Application Build & Distribution**

## **5.1 Pre-Build Fixes**

- Set AppConstants.devToken = null
- Set AppConstants.aiDebug = false

## **5.2 Environment Configuration**

The host URL is runtime-configurable via the ParingPage (first-launch setup screen). However, for enterprise deployment where the proxy URL is known, you may hardcode the default in AppConstants:

// lib/core/app_constants.dart// Option A: Leave host empty - users scan/type proxy URL on first launch (default)static String host = '';// Option B: Hardcode for enterprise (comment out loadHost() in main.dart init)static String host = '<http://YOUR-PROXY-SERVER:3000/api/>';

## **5.3 Android Build**

flutter build apk --release# Output: build/app/outputs/flutter-apk/app-release.apk# Or for Play Store:flutter build appbundle --release# Output: build/app/outputs/bundle/release/app-release.aab# Distribute via:# - Direct APK install (sideload) - simplest for enterprise# - Firebase App Distribution# - Google Play Store (App Bundle)

## **5.4 iOS Build**

\# Requires macOS with Xcode 15+flutter build ipa --release# Output: build/ios/ipa/pfe_mes.ipa# Distribute via:# - Apple Business Manager (enterprise)# - TestFlight (testing)# - App Store

## **5.5 Web Build (Admin Dashboard)**

flutter build web --release# Output: build/web/# Serve with Nginx or any static server:# nginx.conf example - serve build/web/ on port 80/443# Add proxy_pass if needed to reach Node proxy on port 3000

## **5.6 Windows Desktop Build**

flutter build windows --release# Output: build/windows/x64/runner/Release/# Distribute as a ZIP or use Inno Setup / NSIS to create an installer

**6\. Phase 5 - Post-Deployment & Go-Live Checklist**

## **6.1 Admin Configuration (via Flutter Admin Panel)**

- Log in as ADMIN (AUTH-ADMIN01) - forced password change will trigger
- Set a secure admin password (minimum 8 chars, upper + lower + digit + special)
- Navigate to Settings → set Password Change Period (e.g. 90 days) and toggle 2FA on if QR badges are deployed
- Navigate to Users & Roles → create accounts for all supervisors and operators
- For each user: generate a temporary password, share it securely, instruct them to change on first login
- If 2FA is enabled: use 'View Badge' to export QR PDF for each user; distribute badges

## **6.2 Smoke Tests**

| **#** | **Test**                                       | **Expected Result**                                                       |
|-- |------------------------------------------- |---------------------------------------------------------------------- |
| 1     | GET /health on Node proxy                      | {status: 'ok', uptime: N, timestamp: ...}                                 |
|   |                                            |                                                                       |
| 2     | GET /api/ai/health on Node proxy               | {node_proxy: 'ok', python_agent: {status: 'ok'}}                          |
|   |                                            |                                                                       |
| 3     | Flutter login with ADMIN credentials           | Forced password change screen appears                                     |
|   |                                            |                                                                       |
| 4     | Create a Supervisor user, assign a work center | User appears in list, pending setup badge shown                           |
|   |                                            |                                                                       |
| 5     | Log in as Operator, view machine list          | Machines from assigned work center appear with status                     |
|   |                                            |                                                                       |
| 6     | Start an operation on a Released order         | Machine status changes to Working; Tab 1 shows Running operation          |
|   |                                            |                                                                       |
| 7     | Declare production quantity                    | Progress % updates; label print button appears at 100%                    |
|   |                                            |                                                                       |
| 8     | Scan a component barcode                       | Component consumed; BOM remaining qty decreases                           |
|   |                                            |                                                                       |
| 9     | Declare scrap (Finished Product)               | Scrap qty appears in live data; scrap rate computed                       |
|   |                                            |                                                                       |
| 10    | Supervisor finishes operation                  | Machine goes Idle; BC production order status updates                     |
|   |                                            |                                                                       |
| 11    | AI chat: 'Which machines are running?'         | Composite query result listing Working machines                           |
|   |                                            |                                                                       |
| 12    | Password expiry job queue                      | Verify in BC Job Queue Entries - MES Password Expiry Check status = Ready |
|   |                                            |                                                                       |

## **6.3 Monitoring & Maintenance**

- Node proxy logs: pm2 logs producTiv-proxy - watch for 502/504 errors indicating BC connectivity issues
- Python agent logs: journalctl -u producTiv-ai -f (Linux systemd) - monitor LLM timeout and tool failure rates
- BC Job Queue: ensure MES Password Expiry Check runs daily (every 1440 minutes)
- Token cleanup: MESAuthMgt.CleanupExpiredTokens() is not scheduled - configure a job queue entry for weekly cleanup

# **7\. Production Environment Reference**

| **Service**          | **Default Endpoint**                                                                                      | **Notes**                                                       |
|----------------- |------------------------------------------------------------------------------------------------------ |------------------------------------------------------------ |
| BC OData Web Service | https://&lt;bc-host&gt;/&lt;instance&gt;/ODataV4/MESWebService\_&lt;endpoint&gt;?company=&lt;GUID&gt;     | SSPI auth only; never expose directly to Flutter clients        |
|                  |                                                                                                       |                                                             |
| BC Custom API        | https://&lt;bc-host&gt;/&lt;instance&gt;/api/yourcompany/v1/v1.0/companies(&lt;GUID&gt;)/&lt;resource&gt; | scrapCodes, workCenters, employees                              |
|                  |                                                                                                       |                                                             |
| Node.js Proxy        | http://&lt;proxy-server&gt;:3000/api/&lt;endpoint&gt;                                                     | Flutter clients point here; proxy handles all BC authentication |
|                  |                                                                                                       |                                                             |
| Python AI Agent      | <http://localhost:8000/chat> (internal)                                                                   | Accessed only by Node proxy; not exposed externally             |
|                  |                                                                                                       |                                                             |
| AI Chat (via proxy)  | http://&lt;proxy-server&gt;:3000/api/ai/chat                                                              | Flutter calls this; proxy forwards to Python agent              |
|                  |                                                                                                       |                                                             |
| Flutter App Host URL | http://&lt;proxy-server&gt;:3000/api/                                                                     | Set by user on ParingPage or hardcoded for enterprise builds    |
|                  |                                                                                                       |                                                             |

## **7.1 Required Firewall Rules**

| **Source**      | **Destination**      | **Port/Protocol**          | **Purpose**                                             |
|------------ |----------------- |----------------------- |---------------------------------------------------- |
| Flutter clients | Node Proxy           | TCP 3000 (or 443 with TLS) | App → Proxy communication                               |
|             |                  |                        |                                                     |
| Node Proxy      | BC Server            | TCP 7048 (OData) or 443    | Proxy → BC (SSPI authenticated)                         |
|             |                  |                        |                                                     |
| Node Proxy      | AI Agent (localhost) | TCP 8000                   | Internal - same host or private network                 |
|             |                  |                        |                                                     |
| AI Agent        | LLM Provider         | TCP 443                    | AI → external LLM API (if not Ollama local)             |
|             |                  |                        |                                                     |
| BC Server       | Node Proxy           | N/A                        | No inbound required - BC never initiates calls to proxy |
|             |                  |                        |                                                     |