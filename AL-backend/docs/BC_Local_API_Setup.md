# Business Central Local API/OData Setup (BC210)

This guide shows how to find the ports, change the server options, and test your URLs on a local on‑prem Business Central instance.

## 1) Find the server instance and ports

The settings live in `CustomSettings.config`.

```powershell
$config = "C:\Program Files\Microsoft Dynamics 365 Business Central\210\Service\CustomSettings.config"

# Show instance and key ports
Select-String -Path $config -Pattern "ServerInstance|ClientServicesPort|SOAPServicesPort|ODataServicesPort|DeveloperServicesPort|ManagementServicesPort|ApiServicesEnabled|ODataServicesEnabled"
```

Key entries to note:
- `ServerInstance` (e.g., `BC210`)
- `ODataServicesPort` (default `7048`)
- `ApiServicesEnabled` (must be `true` for `/api/...` endpoints)
- `ODataServicesEnabled` (must be `true` for `/ODataV4/...` endpoints)

## 2) Enable OData and API services

Run in **PowerShell as Administrator**:

```powershell
$config = "C:\Program Files\Microsoft Dynamics 365 Business Central\210\Service\CustomSettings.config"

# Enable OData
(Get-Content $config) -replace 'key="ODataServicesEnabled"\s+value="false"', 'key="ODataServicesEnabled" value="true"' | Set-Content $config

# Enable API
(Get-Content $config) -replace 'key="ApiServicesEnabled"\s+value="false"', 'key="ApiServicesEnabled" value="true"' | Set-Content $config

# Verify
Select-String -Path $config -Pattern "ODataServicesEnabled|ApiServicesEnabled"
```

## 3) Restart the BC service

```powershell
# Find the service name
Get-Service | Where-Object { $_.DisplayName -like "*Business Central*" } | Select-Object Name, DisplayName, Status

# Restart (replace with your exact Name from above)
Restart-Service -Name 'MicrosoftDynamicsNavServer$BC210'
```

## 4) Test ports are listening

```powershell
Test-NetConnection -ComputerName localhost -Port 7048
```

If `TcpTestSucceeded` is `True`, the port is open.

## 5) Test OData V4

```powershell
Invoke-WebRequest -Uri "http://localhost:7048/BC210/ODataV4/Company" `
  -Headers @{Accept="application/json"} `
  -UseDefaultCredentials
```

Expected: HTTP 200 with a JSON list of companies and `Id` values.

## 6) Test API v2.0 (system API)

```powershell
Invoke-WebRequest -Uri "http://localhost:7048/BC210/api/v2.0/companies?$top=1" `
  -Headers @{Accept="application/json"} `
  -UseDefaultCredentials
```

Expected: HTTP 200 with a `value` array containing the company `id`.

## 7) Test your custom API

Replace `<companyId>` with a real id from step 6.

```powershell
Invoke-WebRequest -Uri "http://localhost:7048/BC210/api/yourcompany/mes/v1.0/companies(<companyId>)/authActions/Login" `
  -Method Post `
  -Headers @{Accept="application/json"} `
  -ContentType "application/json" `
  -Body '{"userId":"admin","password":"Admin@123!","deviceId":"dev1"}' `
  -UseDefaultCredentials
```

Expected: HTTP 200 with a JSON body that includes a `value` field containing your API response.

## 8) Common errors

- **404 Not Found** on `/api/...`:
  - `ApiServicesEnabled` is still `false` or service not restarted.
- **Connection refused**:
  - Port not open, wrong instance name, or service not running.
- **Unauthorized**:
  - Windows credentials not accepted or missing `-UseDefaultCredentials`.

## 9) URLs quick reference

- OData V4:
  - `http://localhost:7048/BC210/ODataV4/Company`
- API v2.0:
  - `http://localhost:7048/BC210/api/v2.0/companies`
- Custom API:
  - `http://localhost:7048/BC210/api/yourcompany/mes/v1.0/companies(<companyId>)/authActions`
