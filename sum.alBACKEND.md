# MES AL Backend — Comprehensive Module Reference

---

## Project Metadata

| Field | Value |
|---|---|
| App ID | bf9cafbf-fd90-4e55-992d-f2085333bb03 |
| Name | ALProject |
| Publisher | Default Publisher |
| Version | 1.0.0.0 |
| Platform | 21.0.0.0 |
| Application | 21.0.0.0 |
| Runtime | 10.0 |
| ID Range | 50100 – 50149 |
| Feature Flags | NoImplicitWith |
| Dependency | System Application 63ca2fa4 v21.0.0.0 (Microsoft) |
| AL Packages | Microsoft_Application_21.0.46256.46853, Microsoft_System_Application_21.0.46256.46853, Microsoft_System_21.0.46384.46844 |

---

## Directory Structure Overview

```
AL-backend/
├── app.json
├── WebServices.xml
├── docs/
│   ├── BC_Local_API_Setup.md
│   └── BUGS.md
└── src/
    ├── 1-Tables/
    │   ├── MES_settings.al
    │   ├── MES_UserWorkCenter.al
    │   ├── auth/
    │   │   ├── MES_AuthToken.al
    │   │   └── MES_USER.al
    │   ├── extensions/
    │   │   └── Mes_Item_Extension.al
    │   └── machines/
    │       ├── MES_MachineStatus.al
    │       ├── MES_Operation_Execution.al
    │       ├── MES_Operation_Progression.al
    │       ├── MES_Operation_Scan.al
    │       ├── MES_Operation_Scrap.al
    │       ├── MES_Operation_state.al
    │       └── MES_UserExecutionInteraction.al
    ├── 2-Enum/
    │   ├── auth/
    │   │   ├── MES_tokenState.al
    │   │   └── MES_UserRole.al
    │   └── machines/
    │       ├── Machine_Status.al
    │       └── operation_Status.al
    ├── 3-CodeUnit/
    │   ├── MESWebService.al
    │   ├── AI-endpoints/
    │   │   └── toolfunctions.al
    │   ├── auth/
    │   │   ├── MESAuthentificationActions.al
    │   │   ├── MESAuthMgt.al
    │   │   ├── MESAuthValidation.al
    │   │   └── MESPasswordMgt.al
    │   ├── dev-toberemoved/
    │   │   └── MESDevSetup.al
    │   ├── machines/
    │   │   ├── MESMachineFetch.al
    │   │   ├── MESMachineInsert.al
    │   │   ├── MESMachineValidation.al
    │   │   ├── MESMachineWrite.al
    │   │   └── barCodeGenerator/
    │   │       └── MES_Barcode_Generator.al
    │   ├── setup/
    │   │   ├── MESSetup.al
    │   │   └── settings.al
    │   └── shared/
    │       ├── MesErrors.al
    │       └── MESJsonHelper.al
    ├── 4-API/
    │   ├── MESScrapCode.al
    │   └── admin/
    │       ├── MESEmployees.al
    │       ├── MESUsers.al
    │       ├── MESUsersCreate.al
    │       ├── MesWorkCenter.al
    │       └── test.al
    ├── 5-Pages/
    │   ├── MESApiDebug.Page.al
    │   ├── MESComponentConsumption.Page.al
    │   ├── MESItemBarcodes.Page.al
    │   ├── MESMachineList.Page.al
    │   ├── MESOperation.Page.al
    │   ├── MESOperationExecution.Page.al
    │   ├── MESOperationProgress.Page.al
    │   ├── MESOperationScrapList.Page.al
    │   ├── MESUserCard.Page.al
    │   └── MESUserList.Page.al
    └── 6-workers/
        └── MESPasswordExpiryWorker.al
```

---

## Web Service Publication

**File:** `WebServices.xml`

Publishes exactly one OData V4 endpoint:

| Field | Value |
|---|---|
| ServiceName | MESWebService |
| CodeunitName | MES Web Service |
| ObjectID | 50126 |
| Published | true |

All public procedures on Codeunit 50126 are accessible as:
```
POST <baseUrl>/ODataV4/MESWebService_<ProcedureName>
```

---

## Section 1 — Tables

---

### Table 50100 — MES Settings
**File:** `src/1-Tables/MES_settings.al`

**Purpose:** Singleton configuration record for global MES settings.

**Fields:**

| # | Name | Type | Notes |
|---|---|---|---|
| 1 | PW change period | Duration | Password rotation interval in milliseconds. PK (Clustered). |
| 2 | TwoFA Enabled | Boolean | Global flag enabling two-factor authentication. |

**Keys:**
- `PK` on `PW change period` — Clustered.

**Triggers:** None.

**Consumers:**
- `MESAuthentificationActions.Login` — reads `TwoFA Enabled` to decide whether to issue Pending or Active token, and to include in login response.
- `MESPasswordExpiryWorker` — reads `PW change period` to compute cutoff datetime.
- `MESSettingsFunctions.GetMESSettings` — reads and returns both fields.
- `MESSettingsFunctions.UpdateMESSettings` — deletes and re-inserts the record with updated values.

---

### Table 50115 — MES User Work Center
**File:** `src/1-Tables/MES_UserWorkCenter.al`

**Purpose:** Junction table assigning MES users to work centers. Supports many-to-many: one user can belong to multiple work centers.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | User Id | Code[50] | MES User."User Id" | FK to MES User |
| 2 | Work Center No. | Code[20] | Work Center."No." | FK to Work Center |

**Keys:**
- `PK` on `(User Id, Work Center No.)` — Clustered.
- `UserKey` on `User Id`.

**Triggers:** None.

**Consumers:**
- `MESAuthentificationActions.Login` — reads to build `workCenters` array.
- `MESAuthentificationActions.Me` — reads to build `workCenters` array.
- `MESAuthentificationActions.fetchAllMESUsers` — reads to build per-user work center name array.
- `MESAuthentificationActions.fetchMESUsersByWC` — filters by `Work Center No.`.
- `MESAuthentificationActions.AdminCreateUser` — inserts rows from JSON array.
- `MESAuthentificationActions.AdminChangeUserRole` — deletes all rows for user, re-inserts from JSON array.
- `MESMachineValidation.TryValidateProxyDeclaration` — reads supervisor and operator WC rows to check overlap.
- `MESToolFunctions` — reads to scope users to work centers in multiple procedures.

---

### Table 50106 — MES Auth Token
**File:** `src/1-Tables/auth/MES_AuthToken.al`

**Purpose:** Stores per-device session tokens. Tokens are never physically deleted on logout — they are flagged with State = Revoked.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Token | Guid | — | PK |
| 2 | User Id | Code[50] | MES User."User Id" | FK |
| 3 | Device Id | Text[100] | — | Client device identifier |
| 4 | Issued At | DateTime | — | Token creation time |
| 5 | Expires At | DateTime | — | Expiry time (issued + 12 hours) |
| 6 | Last Seen At | DateTime | — | Updated on every `TouchToken` call |
| 7 | State | Enum "MES Token State" | — | Active / Revoked / Pending. Set on issue, revocation, and 2FA promotion. |

**Keys:**
- `PK` on `Token` — Clustered.
- `UserTokens` on `User Id` — enables batch revocation via SetRange.

**DataClassification:** SystemMetadata.

**Triggers:** None.

**Consumers:**
- `MESAuthMgt.IssueToken` — inserts new token with State = Active or Pending.
- `MESAuthMgt.ValidateToken` — reads by PK; checks State = Active.
- `MESAuthMgt.TouchToken` — modifies `Last Seen At`.
- `MESAuthMgt.Logout` — sets `State = Revoked`.
- `MESAuthMgt.CleanupExpiredTokens` — deletes where `Expires At < now`.
- `MESAuthValidation.RevokeAllTokensForUser` — sets `State = Revoked` on all tokens for a user, with optional token exclusion.
- `MESAuthMgt.VerifyBadge` — promotes token from Pending to Active on successful badge scan.
- `MESAuthentificationActions.fetchAllMESUsers` — iterates to compute `isOnline` and `lastSeenAt`.
- `MESToolFunctions.IsUserLoggedInNow`, `IsUserLoggedInAt` — reads to check for tokens with State = Active.

---

### Table 50101 — MES User
**File:** `src/1-Tables/auth/MES_USER.al`

**Purpose:** Central identity store for all MES users. Holds credentials, role, status, and badge secret.

**Fields:**

| # | Name | Type | Table Relation | DataClassification | Notes |
|---|---|---|---|---|---|
| 1 | User Id | Code[50] | — | EndUserIdentifiableInformation | PK. Auto-generated GUID substring if blank on insert. |
| 3 | Employee ID | Code[50] | Employee."No." | EndUserIdentifiableInformation | FK. Unique across all MES Users. OnValidate checks uniqueness. |
| 4 | Auth ID | Text[100] | — | EndUserIdentifiableInformation | Unique. Format AUTH-XXXXXXXX. Used as the login identifier. |
| 5 | Role | Enum "MES User Role" | — | CustomerContent | Operator / Supervisor / Admin |
| 6 | Is Active | Boolean | — | SystemMetadata | Account enabled flag |
| 7 | Need To Change Pw | Boolean | — | SystemMetadata | Forces password change on next login |
| 8 | Password Salt | Text[64] | — | CustomerContent | SHA-256 salt |
| 9 | Hashed Password | Text[128] | — | CustomerContent | SHA-256 hash |
| 10 | Created At | DateTime | — | SystemMetadata | Set on insert |
| 11 | Last Password Changed At | DateTime | — | SystemMetadata | Updated on password modification in OnModify |
| 12 | Badge Secret | Text[64] | — | CustomerContent | SHA-256 hex secret for QR badge auth. Generated on every insert. |

**Keys:**
- `PK` on `User Id` — Clustered.
- `AuthId` on `Auth ID` — Unique.
- `EmployeeId` on `Employee ID` — Unique.
- `UserRole` on `Role`.

**OnInsert trigger logic:**
1. If `User Id` is blank: generate GUID, take chars 2–36.
2. If `Auth ID` is blank: call `GenerateUniqueAuthId()`.
3. Set `Is Active = true`.
4. Set `Need To Change Pw = true`.
5. Set `Created At = CurrentDateTime()`.
6. Set `Password Salt = ''`, `Hashed Password = ''`.
7. Set `Last Password Changed At = 0DT`.
8. Set `Badge Secret = GenerateBadgeSecret()`.

**OnModify trigger logic:**
1. Call `ValidateRequiredFields()` — errors if `Employee ID` is blank.
2. If `Hashed Password` or `Password Salt` changed and `Hashed Password` is not blank: set `Last Password Changed At = CurrentDateTime()`.

**Local procedures:**

`GenerateUniqueAuthId(): Text[100]`
- Loop: generate GUID → `CandidateId = 'AUTH-' + chars 2–8 of GUID`.
- SetRange on `Auth ID = CandidateId`, loop until `IsEmpty()`.
- Return unique candidate.

`GenerateBadgeSecret(): Text[64]`
- Input = Format(GUID) + Format(GUID) + Format(CurrentDateTime).
- Return CopyStr(CryptographyMgt.GenerateHash(Input, 2), 1, 64). (SHA-256)
- Always generated on insert regardless of whether TwoFA Enabled is true.

`ValidateRequiredFields()`
- Error if `Employee ID = ''`.

**Employee ID OnValidate:**
- Error if `Employee ID = ''`.
- SetRange on other MES Users with same Employee ID, SetFilter excluding self — error if not empty.

**Consumers:** All auth codeunits read/write this table.

---

### TableExtension 50100 — MES Item Extension
**File:** `src/1-Tables/extensions/Mes_Item_Extension.al`

**Purpose:** Extends the standard `Item` table with two MES-specific barcode fields.

**Added Fields:**

| # | Name | Type | Notes |
|---|---|---|---|
| 50200 | MES Barcode Text | Text[250] | Full pipe-delimited DataMatrix encoded string |
| 50201 | MES Barcode Code | Code[20] | Short identifier, format MES-\<itemNo\>, registered in Item Identifier |

**Consumers:**
- `MES_Barcode_Generator.GenerateAndSaveBarcodeText` — writes both fields.
- `MESMachineFetch.fetchAllItemBarcodes` — reads `MES Barcode Text`.
- `MESMachineFetch.resolveBarcode` — reads `MES Barcode Code` when parsing DataMatrix prefix.
- `MESItemBarcodes` page — displays both fields.

---

### Table 50107 — MES Machine Status
**File:** `src/1-Tables/machines/MES_MachineStatus.al`

**Purpose:** Append-only real-time machine status log. Each row is an event. Current status = last row per machine.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Machine No. | Code[20] | Machine Center."No." | FK |
| 3 | Status | Enum "MES Machine Status" | — | Idle / Working |
| 4 | Current Prod. Order No. | Code[20] | — | No FK enforced (table relation commented out) |
| 5 | Updated At | DateTime | — | Set to CurrentDateTime() on insert |

**Keys:**
- `PK` on `Id` — Clustered.
- `MachineKey` on `Machine No.`.
- `MachineTimeline` on `(Machine No., Updated At)` — used by FindLast / Ascending(false) queries.

**OnInsert trigger:**
1. If `Id` blank: generate GUID, take chars 2–36.
2. Set `Updated At = CurrentDateTime()`.

**Consumers:**
- `MESMachineInsert.InsertStartMESMachineStatus` — inserts Status=Working row.
- `MESMachineInsert.InsertIdleMachineStatus` — inserts Status=Idle row.
- `MESMachineFetch.FetchMachines` — reads latest row per machine via Ascending(false) + FindFirst on MachineTimeline.
- `MESToolFunctions.CalculateWorkCenterMachineSummary` — reads latest per machine.
- `MESToolFunctions.BuildStoppedMachinesOverview` — reads latest per machine.
- `MESMachineList` page — reads latest for display.

---

### Table 50110 — MES Operation Execution
**File:** `src/1-Tables/machines/MES_Operation_Execution.al`

**Purpose:** One row per started operation instance. The anchor record for an operation run.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Execution Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Machine No | Code[20] | — | No FK enforced (table relation commented out) |
| 3 | Prod Order No | Code[20] | Prod. Order Routing Line."Prod. Order No." | FK |
| 4 | Operation No | Code[10] | — | |
| 5 | Item No | Code[20] | — | |
| 6 | Item Description | Text[100] | — | |
| 7 | Order Quantity | Decimal | — | |
| 8 | Start Time | DateTime | — | Set to CurrentDateTime() on insert |
| 9 | End Time | DateTime | — | Stamped when operation finishes, cancels, or is interrupted |

**Keys:**
- `PK` on `Execution Id` — Clustered.
- `MachineKey` on `Machine No`.
- `OperationKey` on `(Prod Order No, Operation No)`.

**OnInsert trigger:**
1. If `Execution Id` blank: generate GUID, take chars 2–36.
2. Set `Start Time = CurrentDateTime()`.

**Consumers:**
- `MESMachineInsert.InsertMESOperationExecution` — inserts the row.
- `MESMachineInsert.GetExecution` — SetRange on `(Machine No, Prod Order No, Operation No)`, FindFirst.
- `MESMachineInsert.InsertOperationStatus` — reads to stamp `End Time` when finishing/cancelling/interrupting.
- `MESMachineFetch` — multiple procedures read this table.
- `MESMachineValidation.TryStartOperation` — reads to check for previous operation.
- `MESMachineWrite.cancelOperation` — checks existence via `ExecutionExists`.
- `MESToolFunctions` — read extensively.

---

### Table 50109 — MES Operation Progression
**File:** `src/1-Tables/machines/MES_Operation_Progression.al`

**Purpose:** Append-only production cycle log per execution. Each row is one production declaration. The latest row holds running totals.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Execution Id | Code[50] | MES User Execution Interaction."Execution Id" | FK |
| 3 | Cycle Quantity | Decimal | — | Quantity declared in this cycle |
| 5 | Total Produced Quantity | Decimal | — | Running total = previous total + cycle quantity |
| 6 | Operator Id | Code[50] | MES User Execution Interaction."User Id" | FK |
| 7 | Declared At | DateTime | — | Set to CurrentDateTime() on insert |
| 8 | Declared By | Code[50] | MES User Execution Interaction."User Id" | FK. Supervisor if proxy declaration. |

**Note:** Field 4 (`Scrap Quantity`) that existed in the old schema has been removed from this table. Scrap is tracked exclusively in MES Operation Scrap.

**Keys:**
- `PK` on `Id` — Clustered.
- `ExecutionTimeline` on `(Execution Id, Declared At)`.

**OnInsert trigger:**
1. If `Id` blank: generate GUID, take chars 2–36.
2. Set `Declared At = CurrentDateTime()`.

**Consumers:**
- `MESMachineInsert.InsertMESOperationProgression` — inserts zero-quantity initial row.
- `MESMachineInsert.InsertNewProgressionCycle` — reads latest via `GetLatestProgression`, inserts new row with cumulative total. Also calls `IncreaseItemInventory` when this is the last operation.
- `MESMachineInsert.GetLatestProgression` — SetCurrentKey ExecutionTimeline, SetRange ExecutionId, Ascending(false), FindFirst.
- `MESMachineValidation.TryDeclareProduction` — reads latest to validate quantity limits.
- `MESMachineFetch.fetchOperationsStatusAndProgress` — reads latest per execution.
- `MESMachineFetch.fetchOperationLiveData` — reads latest progression.
- `MESMachineFetch.fetchProductionCycles` — iterates all rows descending.
- `MESToolFunctions` — reads in multiple summary procedures.

---

### Table 50112 — MES Operation Scrap
**File:** `src/1-Tables/machines/MES_Operation_Scrap.al`

**Purpose:** Append-only scrap declaration log. Each row is one scrap event. Scrap quantity is computed live by summing rows — not stored in progression.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Execution Id | Code[50] | MES User Execution Interaction."Execution Id" | FK |
| 3 | Scrap Quantity | Decimal | — | |
| 4 | Scrap Code | Code[10] | Scrap.Code | FK |
| 5 | scrap Description | Text[100] | Scrap.Description | Resolved from Scrap table on insert |
| 6 | scrap notes | Text[256] | — | Free text |
| 7 | Operator Id | Code[50] | MES User Execution Interaction."User Id" | FK |
| 8 | Material Id | Code[20] | — | Empty = finished product scrap; non-empty = BOM component item No. |
| 9 | Declared At | DateTime | — | Set to CurrentDateTime() on insert |
| 10 | Declared By | Code[50] | MES User Execution Interaction."User Id" | FK |

**Keys:**
- `PK` on `Id` — Clustered.
- `ExecutionTimeline` on `(Execution Id, Declared At)`.

**OnInsert trigger:**
1. If `Id` blank: generate GUID, take chars 2–36.
2. Set `Declared At = CurrentDateTime()`.

**Consumers:**
- `MESMachineInsert.InsertScrapRecord` — inserts row including `Material Id`. Also calls `EnsureUserExecutionInteraction` for operator and (if different) declaredBy.
- `MESMachineFetch.fetchOperationLiveData` — sums rows WHERE `Material Id = ''` (finished product scrap only).
- `MESMachineFetch.fetchBom` — sums rows WHERE `Material Id = component Item No.` per component.
- `MESMachineFetch.fetchActivityLog` — reads scrap events.
- `MESToolFunctions.fetchScrapSummary` — iterates with filters.
- `MESToolFunctions.SumOperatorScrapForExecution` — sums by operator.
- `MESToolFunctions.BuildHighScrapOverview` — sums per execution.

---

### Table 50108 — MES Operation State
**File:** `src/1-Tables/machines/MES_Operation_state.al`

**Purpose:** Append-only operation state log (Running / Paused / Finished / Cancelled / Interrupted). Latest row = current state.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Execution Id | Code[50] | MES User Execution Interaction."Execution Id" | FK |
| 3 | Operation Status | Enum "MES Operation Status" | — | Running / Paused / Finished / Cancelled / Interrupted |
| 4 | Operator Id | Code[50] | MES User Execution Interaction."User Id" | FK |
| 5 | Declared At | DateTime | — | Set to CurrentDateTime() on insert |

**Keys:**
- `PK` on `Id` — Clustered.
- `ExecutionTimeline` on `(Execution Id, Declared At)`.

**OnInsert trigger:**
1. If `Id` blank: generate GUID, take chars 2–36.
2. Set `Declared At = CurrentDateTime()`.

**Consumers:**
- `MESMachineInsert.InsertMESOperation` — inserts Status=Running.
- `MESMachineInsert.InsertOperationStatus` — inserts any status.
- `MESMachineValidation.GetLatestOperationStatus` — SetCurrentKey, SetRange, Ascending(false), FindFirst.
- `MESMachineValidation.GetExecutionAndLatestStatus` — delegates to GetLatestOperationStatus.
- `MESMachineFetch.fetchOperationsStatusAndProgress` — reads latest per execution.
- `MESMachineFetch.fetchOperationLiveData` — checks latest state is Running or Paused.
- `MESMachineFetch.fetchActivityLog` — reads state change events.
- `MESToolFunctions.FindLatestExecutionState` — SetCurrentKey, SetRange, Ascending(false), FindFirst.

---

### Table 50113 — MES User Execution Interaction
**File:** `src/1-Tables/machines/MES_UserExecutionInteraction.al`

**Purpose:** Junction table. Tracks which MES users participated in which execution. Required as a FK target for Operator Id and Declared By fields in progression, scrap, state, and consumption tables.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Execution Id | Code[50] | MES Operation Execution."Execution Id" | FK, part of PK |
| 2 | User Id | Code[50] | MES User."User Id" | FK, part of PK |

**Keys:**
- `PK` on `(Execution Id, User Id)` — Clustered.
- `ByUser` on `User Id`.

**Triggers:** None.

**Consumers:**
- `MESMachineInsert.EnsureUserExecutionInteraction` — idempotent Get; inserts if not found.
- Called from: `InsertMESOperation`, `InsertMESOperationProgression`, `InsertNewProgressionCycle`, `InsertScrapRecord`, `insertScans`, and other insert procedures to register each participating user.

---

### Table 50111 — MES Operation Scan (Component Consumption)
**File:** `src/1-Tables/machines/MES_Operation_Scan.al`

**Purpose:** Append-only log of component barcode scans during production. Each row = one scan event. The AL table caption is "MES Component Consumption" though the object name is `MES Operation Scan`.

**Fields:**

| # | Name | Type | Table Relation | Notes |
|---|---|---|---|---|
| 1 | Id | Code[50] | — | PK. Auto-generated GUID substring on insert. |
| 2 | Execution Id | Code[50] | MES User Execution Interaction."Execution Id" | FK |
| 3 | Prod Order No | Code[20] | — | |
| 4 | Item No | Code[20] | — | |
| 5 | Barcode | Text[500] | — | Raw scanned barcode string |
| 6 | Quantity Scanned | Decimal | — | Number of units/packages scanned |
| 7 | Quantity per Unit of Measure | Decimal | — | Qty of base unit per scanned UOM |
| 8 | Unit of Measure | Code[10] | — | UOM of the scanned identifier |
| 9 | Operator Id | Code[50] | MES User Execution Interaction."User Id" | FK |
| 10 | Scanned At | DateTime | — | Set to CurrentDateTime() on insert |
| 11 | Declared By | Code[50] | MES User Execution Interaction."User Id" | FK |

**Keys:**
- `PK` on `Id` — Clustered.
- `ExecutionTimeline` on `(Execution Id, Scanned At)`.

**OnInsert trigger:**
1. If `Id` blank: generate GUID, take chars 2–36.
2. Set `Scanned At = CurrentDateTime()`.

**Consumers:**
- `MESMachineWrite.insertScans` — inserts rows and posts consumption journal lines via `Item Jnl.-Post Line`.
- `MESMachineFetch.fetchBom` — sums `numberScanned` and `totalQuantityScanned` per component.
- `MESMachineFetch.fetchActivityLog` — reads scan events.
- `MESToolFunctions.CalculateConsumedComponentQuantity` — sums `Quantity Scanned × Quantity per Unit of Measure`.

---

## Section 2 — Enumerations

---

### Enum 50100 — MES User Role
**File:** `src/2-Enum/auth/MES_UserRole.al`

| Value | Caption | Integer |
|---|---|---|
| Operator | Operator | 0 |
| Supervisor | Supervisor | 1 |
| Admin | Admin | 2 |

Extensible = true.

**Used in:** MES User.Role field, all auth/admin procedures, role-based checks in MESAuthMgt, MESAuthentificationActions, MESMachineValidation.

---

### Enum 50124 — MES Token State
**File:** `src/2-Enum/auth/MES_tokenState.al`

| Value | Caption | Integer |
|---|---|---|
| Active | Active | 0 |
| Revoked | Revoked | 1 |
| Pending | Pending | 2 |

Extensible = true.

**Used in:** MES Auth Token.State field. `Active` = valid session. `Revoked` = logged out or password changed. `Pending` = token issued but awaiting 2FA verification; cannot be used for protected endpoints until promoted to Active via `VerifyBadge`.

---

### Enum 50101 — MES Machine Status
**File:** `src/2-Enum/machines/Machine_Status.al`

| Value | Caption | Integer |
|---|---|---|
| Idle | Idle | 0 |
| Working | Working | 1 |

Extensible = true.

**Used in:** MES Machine Status.Status field, InsertStartMESMachineStatus, InsertIdleMachineStatus, FetchMachines response.

---

### Enum 50102 — MES Operation Status
**File:** `src/2-Enum/machines/operation_Status.al`

| Value | Caption | Integer |
|---|---|---|
| Running | Running | 0 |
| Paused | Paused | 1 |
| Finished | Finished | 2 |
| Cancelled | Cancelled | 3 |
| Interrupted | Interrupted | 4 |

Extensible = true.

**Used in:** MES Operation State.Operation Status field, all validation and insert procedures for state transitions, ExecuteOperationTransition routing.

---

## Section 3 — Codeunits

---

### Codeunit 50110 — MES Password Mgt
**File:** `src/3-CodeUnit/auth/MESPasswordMgt.al`

**Access:** Public. **NonDebuggable on all procedures.**

**Purpose:** Pure cryptographic layer. No knowledge of users, tokens, or any other table.

**Procedures:**

`MakeSalt(): Text`
- Input: Format(CreateGuid()) + Format(CurrentDateTime()).
- Returns: CryptographyMgt.GenerateHash(Input, 2) → SHA-256 hex string (64 chars).

`HashPassword(Password: Text; Salt: Text): Text`
- Combined = Password + Salt.
- Returns: CryptographyMgt.GenerateHash(Combined, 2) → SHA-256 hex string.

`VerifyPassword(Password: Text; StoredHash: Text; Salt: Text): Boolean`
- Calls HashPassword(Password, Salt).
- Returns: ComputedHash = StoredHash.

**Dependencies:** Standard `Cryptography Management` codeunit.

**Consumed by:** `MESAuthMgt` — all password operations.

---

### Codeunit 50112 — MES Auth Validation
**File:** `src/3-CodeUnit/auth/MESAuthValidation.al`

**Access:** Internal.

**Purpose:** TryFunction wrappers for auth operations, plus shared auth utilities (password strength check, token revocation).

**Procedures:**

`IsPasswordStrong(Password: Text): Boolean`
- Checks StrLen ≥ 8.
- Iterates chars: sets HasUpper, HasLower, HasDigit, HasSpecial flags.
- Returns `exit(HasUpper and HasLower and HasDigit and HasSpecial)`.
- All four character-class requirements are enforced.

`RevokeAllTokensForUser(UserId: Code[50]; TokenToExclude: Text)`
- `T.SetRange("User Id", UserId)`.
- `T.FindSet(true)`.
- Loop: if `T.Token <> TokenToExclude` then `T.State := T.State::Revoked; T.Modify(true)`.
- The `TokenToExclude` parameter preserves the current session token during a self-service password change so the user is not immediately logged out.

`TryValidateCredentials(userId: Code[50]; password: Text)` — [TryFunction] [NonDebuggable]
- Delegates to `AuthMgt.ValidateCredentials`.

`TryValidateChangePassword(token: Text; oldPassword: Text; newPassword: Text; var OutUserId: Code[50])` — [TryFunction] [NonDebuggable]
- Delegates to `AuthMgt.ValidateChangePassword`.

`TryValidateAdminToken(token: Text; var OutAdminUserId: Code[50])` — [TryFunction]
- Delegates to `AuthMgt.ValidateAdminToken`.

**Dependencies:** `MESAuthMgt` (CU 50111), `MES Auth Token` table.

**Consumed by:** `MESAuthMgt.SetPassword`, `MESAuthMgt.ValidateChangePassword`, `MESSettingsFunctions.UpdateMESSettings`, `MESAuthentificationActions` (local TryFunction copies).

---

### Codeunit 50111 — MES Auth Mgt
**File:** `src/3-CodeUnit/auth/MESAuthMgt.al`

**Access:** Public.

**Purpose:** Core authentication business logic. Orchestrates user CRUD, login, token lifecycle, and admin guards.

**Dependencies:** `MESPasswordMgt` (CU 50110), `MESAuthValidation` (CU 50112), `MES User` table, `MES Auth Token` table.

---

#### Section 1 — User CRUD

`CreateUser(UserId, EmployeeID, AuthID, Role)`
- Error if UserId blank.
- U.Get(UserId) → error if already exists.
- U.Init(), set all fields, U.Insert(true).
- Note: Auth ID passed in is stored as-is (caller is responsible for uniqueness). If empty, `MES User.OnInsert` auto-generates.

`SetPassword(UserId, NewPw, ForceChangeOnNextLogin, UserToken)` — [NonDebuggable]
- U.Get(UserId) → error if not found.
- `AuthValidation.IsPasswordStrong(NewPw)` → error if false.
- Salt = PwMgt.MakeSalt().
- Hash = PwMgt.HashPassword(NewPw, Salt).
- CopyStr into `Password Salt` (1..64), `Hashed Password` (1..128).
- Set `Need To Change Pw = ForceChangeOnNextLogin`.
- U.Modify(true).
- `AuthValidation.RevokeAllTokensForUser(UserId, UserToken)` — passing UserToken excludes the current session from revocation during self-service password changes; passing `''` revokes all sessions (admin reset).

---

#### Section 2 — Login / Token

`ValidateCredentials(UserId, Password)` — [NonDebuggable]
- U.Get → error 'Invalid credentials.' if not found.
- Check IsActive → error 'Account is disabled.' if false.
- Check Hashed Password not blank → error 'Account setup incomplete.' if blank.
- PwMgt.VerifyPassword → error 'Invalid credentials.' if mismatch.

`IssueNewToken(UserId: Code[50]; DeviceId: Text; Pending: Boolean): Record "MES Auth Token"`
- Delegates to private `IssueToken`, passing the Pending flag.

`ValidateToken(TokenText, var U, var T, var errorMessage): Boolean`
- Clear U, T.
- If TokenText blank → exit false.
- Evaluate(TokenGuid, TokenText) → exit false if fails.
- T.Get(TokenGuid) → exit false if not found.
- T.State ≠ Active → exit false.
- T.Expires At ≤ CurrentDateTime() → exit false.
- U.Get(T.User Id) → exit false if not found.
- U.Is Active → exit false if false.
- Return true.

`TouchToken(var T)`
- T.Last Seen At = CurrentDateTime(); T.Modify(true).

`Logout(TokenText): Boolean`
- Evaluate GUID → false if fails.
- T.Get → false if not found.
- T.State = Revoked; T.Modify(true). Return true.

`ValidateChangePassword(token, oldPw, newPw, var OutUserId)` — [NonDebuggable]
- ValidateToken → error on failure.
- PwMgt.VerifyPassword(oldPw) → error 'Current password is incorrect.'
- AuthValidation.IsPasswordStrong(newPw) → error if false.
- OutUserId = U.User Id.

`ValidateAdminToken(token, var OutAdminUserId)`
- ValidateToken → error on failure.
- AdminUser.Role ≠ Admin → error 'Forbidden. Admin access required.'
- OutAdminUserId = AdminUser.User Id.

---

#### Section 3 — Admin Guards

`RequireAdmin(TokenText, var AdminUser)`
- ValidateToken → error on failure.
- Role ≠ Admin → error 'Forbidden. Admin access required.'
- TouchToken(T).

`SetActive(TargetUserId, Active): Boolean`
- U.Get → error if not found.
- U.Is Active = Active; U.Modify(true).
- If not Active: AuthValidation.RevokeAllTokensForUser(TargetUserId, '').
- Note: the self-check guard that was present in an earlier version has been removed; the self-check is now enforced in `MESAuthentificationActions.AdminSetActive` by comparing `AdminUserId = UserIdCode` before calling this procedure.

---

#### Section 4 — Maintenance

`CleanupExpiredTokens()`
- T.SetFilter("Expires At", '<\%1', CurrentDateTime()).
- T.DeleteAll(true) if not empty.

---

#### Section 5 — Private

`IssueToken(UserId, DeviceId, Pending): Record "MES Auth Token"` — local
- TTL = 12 × 60 × 60 × 1000 ms (12 hours).
- T.Init(), set Token=CreateGuid(), User Id, Device Id (CopyStr 1..100), Issued At, Expires At = now+TTL, Last Seen At = now.
- If Pending=true: T.State = Pending; else T.State = Active.
- T.Insert(true). Return T.

---

#### Badge Procedures

`VerifyBadge(ScannedSecret: Text; Token: Text): Boolean`
- T.Get(Token) → false if not found.
- U.Get(T."User Id") → false if not found.
- U.Badge Secret blank → false.
- result = (U.Badge Secret = CopyStr(ScannedSecret, 1, 64)).
- If result is true: calls TouchToken(T).
- **Bug:** `T.State := Active` and `T.Modify(true)` are missing `begin/end` after the `if result then` guard; they execute unconditionally regardless of whether the badge matched.

`RegenerateBadgeSecret(AdminToken, TargetUserId): Text`
- RequireAdmin(AdminToken, AdminUser).
- U.Get → BuildError if not found.
- NewSecret = CopyStr(CryptographyMgt.GenerateHash(GUID+GUID+DateTime, 2), 1, 64).
- U.Badge Secret = NewSecret; U.Modify(true).
- Return JSON {success:true, badgeSecret: NewSecret}.

`GetBadgeSecret(AdminToken, TargetUserId): Text`
- RequireAdmin.
- U.Get → BuildError if not found.
- Return JSON {success:true, badgeSecret: U.Badge Secret}.

---

### Codeunit 50125 — MES Authentication Actions
**File:** `src/3-CodeUnit/auth/MESAuthentificationActions.al`

**Access:** Internal.

**Purpose:** HTTP-facing auth and admin endpoints. Handles JSON building for all auth/user-management responses. Contains local TryFunction copies that mirror MESAuthValidation's public ones.

**Dependencies:** `MESAuthMgt` (CU 50111), `MESJsonHelper` (CU 50120), all related tables.

---

#### Section 1 — Auth

`Login(userId, password, deviceId): Text` — [NonDebuggable]
- If userId or password blank → BuildError.
- U.SetRange("Auth ID", userId); FindFirst → BuildError if not found.
- TryValidateCredentials(U.User Id, password) → BuildErrorFromLastError if fails.
- Read MES Settings → TwoFAEnabled.
- If TwoFAEnabled: TokenRec = AuthMgt.IssueNewToken(UserIdCode, deviceId, Pending=true). Else: IssueNewToken(..., Pending=false).
- Build WCArr from MES User Work Center.
- Build OutJ with: success, twoFAEnabled, workCenters, needToChangePw, userId (internal Code[50]), authId, employeeId, role, isActive, token, expiresAt.
- If Employee.Get: add fullName, email; if image HasValue → Base64Convert.ToBase64, add imageBase64; else imageBase64=''.
- Return JsonToText(OutJ).

`Logout(token): Text`
- AuthMgt.Logout → BuildError if fails.
- Return {success:true, message:'Logged out successfully'}.

`Me(token): Text`
- AuthMgt.ValidateToken → BuildError if fails.
- AuthMgt.TouchToken.
- Build WCArr from MES User Work Center.
- Build OutJ with: success, workCenters, needToChangePw, userId, authId, employeeId, role, isActive.
- If Employee.Get: add fullName, email, imageBase64.
- Return JsonToText(OutJ).

`ChangePassword(token, oldPassword, newPassword): Text` — [NonDebuggable]
- If either password blank → BuildError.
- TryValidateChangePassword → BuildErrorFromLastError if fails.
- AuthMgt.SetPassword(TargetUserId, newPassword, false, token) — passes the current token so it is excluded from revocation.
- Return {success:true, message:'Password changed successfully'}.

---

#### Section 2 — Admin

`AdminCreateUser(token, userId, employeeId, roleInt, workCenterListJson): Text`
- If userId blank → BuildError.
- Map roleInt → Role enum (0=Operator, 1=Supervisor, 2=Admin; else error).
- TryValidateAdminToken → BuildErrorFromLastError if fails.
- AuthMgt.CreateUser(UserIdCode, EmployeeIdCode, AuthIdCode='', Role). (AuthID left blank — auto-generated by MES User.OnInsert.)
- Parse workCenterListJson → foreach: insert MES User Work Center row.
- Return {success:true, message, userId}.

`AdminSetPassword(token, userId, newPassword): Text` — [NonDebuggable]
- Validate inputs.
- TryValidateAdminToken.
- AuthMgt.SetPassword(userId, newPassword, forceChange=true, '').
- Return {success:true, message}.

`AdminSetActive(token, userId, isActive): Text`
- Validate inputs.
- TryValidateAdminToken → OutAdminUserId.
- Self-check: if AdminUserId = UserIdCode → Error('Cannot modify your own account status.'). This guard is correctly enforced here.
- AuthMgt.SetActive(userId, isActive).
- Return {success:true, message}.

`fetchAllMESUsers(): Text`
- Sets CurrentKey to "Created At", Ascending(false) — returns users newest first.
- For each: build UserJson with userId, authId, employeeId, role, isActive.
- Employee.Get → add fullName, email, imageBase64.
- Loop MES Auth Token by UserId → compute isOnline (any State=Active and not expired), lastSeenAt (max Last Seen At).
- Loop MES User Work Center → resolve Work Center Name → build WorkCentersArray.
- Add isPendingSetup = (Hashed Password = '').
- Return JsonToTextArr.

`fetchMESUsersByWC(wcID): Text`
- Loop MES User Work Center filtered by wcID.
- For each: load MES User, build UserJson with userId, authId, employeeId, role, fullName, imageBase64.
- Return JsonToTextArr.

`AdminChangeUserRole(token, targetUserId, newRoleInt, workCenterListJson): Text`
- ValidateToken → BuildError if fails. TouchToken.
- Check CallerUser.Role = Admin → BuildError if not.
- TargetUser.Get → BuildError if not found.
- Map newRoleInt → NewRole enum.
- If NewRole ≠ Admin: parse workCenterListJson, validate count > 0, validate Operator count ≤ 1.
- TargetUser.Role = NewRole; Modify(true).
- Delete all MES User Work Center rows for target.
- If NewRole ≠ Admin: re-insert from JSON array (uses TrimStart/TrimEnd to strip surrounding quotes from WriteTo output).
- Return {"success":true,"message":"User role updated successfully."}.

`fetchAllEmployees(): Text`
- Loop all Employees.
- For each: if no MES User with matching Employee ID → include in result.
- Build EmployeesObj with id, firstName, middleName, lastName, email, imageBase64.
- Return JsonToTextArr.

---

#### Local TryFunctions (duplicate of AuthValidation's public ones, scoped to this codeunit)

`TryValidateCredentials(userId, password)` — [TryFunction] [NonDebuggable]
- Delegates to AuthMgt.ValidateCredentials.

`TryValidateChangePassword(token, oldPw, newPw, var OutUserId)` — [TryFunction] [NonDebuggable]
- Delegates to AuthMgt.ValidateChangePassword.

`TryValidateAdminToken(token, var OutAdminUserId)` — [TryFunction]
- Delegates to AuthMgt.ValidateAdminToken.

---

### Codeunit 50133 — MES Machine Insert
**File:** `src/3-CodeUnit/machines/MESMachineInsert.al`

**Access:** Internal.

**Purpose:** All direct table inserts for machine operations. No auth logic. No validation logic.

**Procedures:**

`InsertMESOperationExecution(prodOrderNo, operationNo, machineNo): Code[50]`
- SetRange + FindFirst on Prod. Order Line for the order.
- Build MES Operation Execution row from production order line data.
- Insert(true). Return ExecutionId.

`InsertMESOperation(executionId, mesUserId)`
- Insert MES Operation State row with Status=Running.
- Call EnsureUserExecutionInteraction(executionId, mesUserId).

`InsertOperationStatus(machineNo, prodOrderNo, operationNo, status, mesUserId)`
- GetExecution.
- Insert MES Operation State row.
- EnsureUserExecutionInteraction.
- If status = Finished, Cancelled, or Interrupted: stamp End Time on MES Operation Execution.

`InsertStartMESMachineStatus(prodOrderNo, machineNo)`
- Insert MES Machine Status row with Status=Working, Current Prod. Order No. = prodOrderNo.

`InsertIdleMachineStatus(machineNo)`
- Insert MES Machine Status row with Status=Idle.

`InsertMESOperationProgression(executionId, mesUserId)`
- Insert zero-quantity MES Operation Progression row.
- EnsureUserExecutionInteraction.

`InsertNewProgressionCycle(machineNo, prodOrderNo, operationNo, input, operatorId, declaredById)`
- GetExecution.
- GetLatestProgression.
- Insert new MES Operation Progression: CycleQty=input, TotalProduced=prev total+input.
- If IsLastOperation: call IncreaseItemInventory to post an Output journal line.
- EnsureUserExecutionInteraction for operatorId and declaredById.

`InsertScrapRecord(executionId, scrapCode, desc, qty, operatorId, declaredById, materialId)`
- EnsureUserExecutionInteraction for operatorId.
- If declaredById ≠ '' and ≠ operatorId: EnsureUserExecutionInteraction for declaredById.
- Insert MES Operation Scrap with all fields including Material Id.
- Resolve scrap description from Scrap table.

`InsertStartOperationRecords(prodOrderNo, operationNo, machineNo, mesUserId): Code[50]`
- Orchestrator:
  1. InsertMESOperationExecution → ExecutionId.
  2. InsertMESOperation(ExecutionId, mesUserId).
  3. InsertMESOperationProgression(ExecutionId, mesUserId).
  4. InsertStartMESMachineStatus(prodOrderNo, machineNo).
- Return ExecutionId.

`IsFirstOperation(prodOrderNo, operationNo): Boolean`
- Returns true if `ProdOrderRoutingLine."Previous Operation No." = ''`.

`IsLastOperation(prodOrderNo, operationNo): Boolean`
- Returns true if `ProdOrderRoutingLine."Next Operation No." = ''`.

`IncreaseItemInventory(itemNo, quantity, executionId)`
- Validates execution, production order (must be Released), and routing line.
- Uses journal batch 'ARTICLE'/'DEFAUT'.
- Cleans up existing lines in the batch before inserting.
- Posts an Output entry via `Item Jnl.-Post Line.RunWithCheck`.

`SetErpOrderToFinish(prodOrderNo, operationNo, mesOperationStatus)`
- Finds the Released production order.
- Rule 1: If first operation is Cancelled or Interrupted → finish the production order.
- Rule 2: If last operation is Finished, Cancelled, or Interrupted → finish the production order.
- Uses `Prod. Order Status Management.ChangeProdOrderStatus`.

`GetExecution(machineNo, prodOrderNo, operationNo, var MESExecution)`
- SetRange on Machine No, Prod Order No, Operation No.
- FindFirst.

`GetLatestProgression(executionId, var MESOperationProgress)`
- SetCurrentKey ExecutionTimeline.
- SetRange ExecutionId.
- Ascending(false). FindFirst.

`GetPreviousOperationProducedQuantity(executionId): Decimal`
- Reads total produced from latest progression for the given execution.

`GetLatestOperationStatus(executionId, var MESOperationState)`
- SetCurrentKey ExecutionTimeline. SetRange ExecutionId. Ascending(false). FindFirst.

`EnsureUserExecutionInteraction(executionId, mesUserId)`
- Attempt Get on PK (executionId, mesUserId).
- If exists: exit.
- Else: Init, set fields, Insert. Idempotent.

`ExecutionExists(machineNo, prodOrderNo, operationNo): Boolean`
- SetRange on three fields, return not IsEmpty.

---

### Codeunit 50134 — MES Machine Validation
**File:** `src/3-CodeUnit/machines/MESMachineValidation.al`

**Access:** Internal.

**Purpose:** Pure validation. All public procedures are [TryFunction]. No inserts, no auth logic.

**Dependencies:** `MESMachineInsert` (CU 50133) via GetExecution, GetLatestProgression, GetPreviousOperationProducedQuantity.

---

`TryStartOperation(prodOrderNo, operationNo, machineNo)` — [TryFunction]
- SetRange Released + prodOrderNo + operationNo on Prod. Order Routing Line.
- FindFirst → error 'Routing line not found or order is not in Released status.'
- EnsureNoRunningOperation.
- Read PreviousOperationNo from routing line.
- If PreviousOperationNo ≠ '':
  - Find previous routing line.
  - If previous type = Work Center → exit (skip check).
  - Find previous MES Execution.
  - If found: GetLatestOperationStatus for previous.
    - If previous status = Cancelled or Interrupted → exit.
    - If SendAheadQuantity = 0: previous must be Finished else error.
    - If SendAheadQuantity > 0: TotalProducedQuantity ≥ SendAheadQuantity else error.
  - If not found: error 'Previous operation has not started yet.'

`TryCancelOperationBeforeStart(prodOrderNo, operationNo, machineNo)` — [TryFunction]
- Find routing line. Error if not found. No other validation.

`TryDeclareProduction(machineNo, prodOrderNo, operationNo, input)` — [TryFunction]
- GetExecution → error if ExecutionId blank.
- GetLatestProgression → error if ExecutionId blank.
- input ≤ 0 → error.
- TotalProduced + input > OrderQuantity → error.

`TryPauseOperation(machineNo, prodOrderNo, operationNo)` — [TryFunction]
- GetExecutionAndLatestStatus.
- Status ≠ Running → error.

`TryResumeOperation(machineNo, prodOrderNo, operationNo)` — [TryFunction]
- GetExecutionAndLatestStatus.
- Status ≠ Paused → error.
- EnsureNoRunningOperation.

`TryCloseOperation(machineNo, prodOrderNo, operationNo)` — [TryFunction]
- GetExecutionAndLatestStatus.
- Status in [Finished, Cancelled] → error.

`TryDeclareScrap(executionId, scrapCode, quantity)` — [TryFunction]
- MESExecution.Get → error if not found.
- GetLatestOperationStatus.
- Status ≠ Running → error ('Cannot declare scrap on a non running operation.').
- Scrap.Get(scrapCode) → error if not found.
- quantity ≤ 0 → error.

`TryValidateProxyDeclaration(supervisorUserId, operatorUserId)` — [TryFunction]
- SupervisorUser.Get → error if not found.
- Role ≠ Supervisor → error.
- Iterate SupervisorWC rows.
  - For each: check if OperatorWC has same Work Center No.
  - If found: exit (success).
- If no shared WC found → error.

---

#### Non-TryFunction helpers (public)

`EnsureNoRunningOperation(machineNo, prodOrderNo, operationNo)`
- SetRange on Prod Order No + Operation No → FindFirst → check Running → error 'This operation is already running.'
- SetRange on Machine No → FindSet → for each: check Running → error with machine details.

`GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, var MESExecution, var MESOperationState)`
- MachineInsert.GetExecution → error if ExecutionId blank.
- GetLatestOperationStatus → error if Execution Id blank.

`GetLatestOperationStatus(executionId, var MESOperationState)`
- SetCurrentKey ExecutionTimeline.
- SetRange ExecutionId. Ascending(false). FindFirst.

---

### Codeunit 50132 — MES Machine Write
**File:** `src/3-CodeUnit/machines/MESMachineWrite.al`

**Access:** Internal.

**Purpose:** Orchestrates all write operations. Validates tokens for operations that require identity resolution. Routes between MESMachineValidation (guards) and MESMachineInsert (writes).

**Dependencies:** `MESAuthMgt` (CU 50111), `MESMachineValidation` (CU 50134), `MESMachineInsert` (CU 50133), `MESJsonHelper` (CU 50120).

---

#### Local helpers

`TryResolveUser(token, var mesUserId, var errorMessage): Boolean` — local
- AuthMgt.ValidateToken → return false if fails.
- AuthMgt.TouchToken.
- mesUserId = U.User Id. Return true.

`BuildSuccessResponse(): Text` — local
- Return `{value: true}`.

`BuildFailureResponse(message): Text` — local
- Return `{value: false, message: ...}`.

---

#### Public procedures

`startOperation(prodOrderNo, operationNo, machineNo, operatorId): Text`
- ClearLastError.
- MachineValidation.TryStartOperation → BuildFailureResponse if fails.
- MachineInsert.InsertStartOperationRecords(prodOrderNo, operationNo, machineNo, operatorId).
- BuildSuccessResponse.

`declareProduction(machineNo, prodOrderNo, operationNo, input, operatorId, declaredById): Text`
- ClearLastError.
- MachineValidation.TryDeclareProduction → BuildFailureResponse if fails.
- MachineInsert.InsertNewProgressionCycle.
- BuildSuccessResponse.

`finishOperation(token, machineNo, prodOrderNo, operationNo): Text`
- TryResolveUser → BuildFailureResponse if fails.
- ExecuteOperationTransition(Finished, mesUserId).

`cancelOperation(token, machineNo, prodOrderNo, operationNo): Text`
- TryResolveUser → BuildFailureResponse if fails.
- If MachineInsert.ExecutionExists = false → ExecuteCancelUnstartedOperation.
- Else: ExecuteOperationTransition(Interrupted, mesUserId).

`pauseOperation(token, machineNo, prodOrderNo, operationNo): Text`
- TryResolveUser → BuildFailureResponse if fails.
- ExecuteOperationTransition(Paused, mesUserId).

`resumeOperation(token, machineNo, prodOrderNo, operationNo): Text`
- TryResolveUser → BuildFailureResponse if fails.
- ExecuteOperationTransition(Running, mesUserId).

`insertScans(executionId, scansJson, operatorId, declaredById): Text`
- MESExecution.Get → BuildFailureResponse if not found.
- Find Production Order and Production Order Line.
- Parse ScansArr from scansJson.
- Find journal batch 'ARTICLE'/'DEFAUT' → BuildFailureResponse if not found.
- Get next document number from No. Series (or use 'MES-'+executionId if no series).
- Clean up existing lines in the batch.
- For each scan in ScansArr:
  - Parse: itemNo, barcode, quantityScanned, unitOfMeasure, quantityPerUnitOfMeasure.
  - Insert MES Operation Scan row.
  - Item.Get(itemNo) → if found: build Item Journal Line (Consumption type, validated fields). Post immediately via `Item Jnl.-Post Line.RunWithCheck`.
  - If Item not found → BuildFailureResponse.
- MachineInsert.EnsureUserExecutionInteraction(executionId, operatorId).
- BuildSuccessResponse.

`declareScrap(executionId, description, scrapCode, quantity, operatorId, declaredById, materialId): Text`
- ClearLastError.
- MachineValidation.TryDeclareScrap → BuildFailureResponse if fails.
- MachineInsert.InsertScrapRecord(executionId, scrapCode, description, quantity, operatorId, declaredById, materialId).
- BuildSuccessResponse.

---

#### Local orchestrators

`ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, targetStatus, mesUserId): Text` — local
- ClearLastError.
- Route to validation TryFunction based on targetStatus:
  - Finished / Cancelled / Interrupted → TryCloseOperation.
  - Paused → TryPauseOperation.
  - Running → TryResumeOperation.
- BuildFailureResponse if validation fails.
- MachineInsert.InsertOperationStatus.
- If Running: MachineInsert.InsertStartMESMachineStatus.
- Else: MachineInsert.InsertIdleMachineStatus.
- If Finished, Cancelled, or Interrupted: MachineInsert.SetErpOrderToFinish.
- BuildSuccessResponse.

`ExecuteCancelUnstartedOperation(prodOrderNo, operationNo, machineNo, mesUserId): Text` — local
- MachineValidation.TryCancelOperationBeforeStart → BuildFailureResponse if fails.
- MachineInsert.InsertMESOperationExecution → creates bare execution row (does NOT call InsertStartOperationRecords to avoid setting machine to Working).
- MachineInsert.InsertMESOperationProgression.
- MachineInsert.InsertOperationStatus(Cancelled).
- MachineInsert.SetErpOrderToFinish.
- BuildSuccessResponse.

---

### Codeunit 50131 — MES Machine Fetch
**File:** `src/3-CodeUnit/machines/MESMachineFetch.al`

**Access:** Internal.

**Purpose:** All read/query operations. No auth, no writes.

**Dependencies:** `MESMachineInsert` (CU 50133) for GetExecution and GetLatestProgression helpers.

---

`FetchMachines(workCenterNoJson: Text): Text`
- Parses workCenterNoJson as a JSON object with a `workCenterNos` array key → builds pipe-delimited filter.
- Filters Machine Center by Work Center No. filter.
- For each machine: joins Work Center name, reads latest MES Machine Status row (Ascending(false)+FindFirst).
- Also reads latest MES Operation Execution for current item/operation info.
- Returns JSON array.

`getMachineOrders(machineNo): Text`
- Filters Prod. Order Routing Line by machine No. (Type = Machine Center) + Status in [Planned, Firm Planned, Released].
- Skips rows that already have a corresponding MES Operation Execution.
- Joins Prod. Order Line for item/qty.
- Returns JSON array.

`fetchOperationsStatusAndProgress(machineNo, fetchFinished): Text`
- Loops MES Executions by machine.
- Gets latest status per execution via Ascending(false)+FindFirst.
- Filters by finished/active flag.
- Uses execution Start Time / End Time for timestamps.
- Joins latest progression for quantities.
- Returns JSON array.

`fetchOperationLiveData(machineNo, prodOderNo, operationNo): Text`
- GetExecution.
- Checks latest status = Running or Paused.
- Calculates scrapQuantity by summing MES Operation Scrap WHERE Material Id = '' (finished-product scrap only).
- Joins latest progression.
- Returns JSON array.

`fetchProductionCycles(machineNo, prodOrderNo, operationNo): Text`
- GetExecution.
- Loops MES Operation Progression descending by ExecutionTimeline.
- Joins MES User → Employee for operator names.
- Returns JSON array.

`fetchBom(prodOrderNo, operationNo): Text`
- GetExecution.
- Reads Routing Link Code from Prod. Order Routing Line.
- Loops Prod. Order Components filtered by Routing Link Code.
- For each component:
  - numberScanned = sum of Quantity Scanned from MES Operation Scan.
  - totalQuantityScanned = sum of (Quantity Scanned × Quantity per Unit of Measure).
  - scrapQuantity = sum of MES Operation Scrap WHERE Material Id = component Item No.
  - Resolves quantityPerUnit from ItemUnitOfMeasure × component Quantity per.
  - Also reads Item.Inventory (CalcFields), baseUOM, and baseUOMQuantityPerUnit.
- Returns JSON array.

`fetchAllItemBarcodes(): Text`
- Loops all Items filtered by MES Barcode Code ≠ ''.
- Returns JSON array with item fields + MES Barcode Text.

`fetchActivityLog(hoursBack): Text`
- Collects four event types from last N hours in descending chronological order (Ascending=false):
  1. State changes from MES Operation State.
  2. Production declarations from MES Operation Progression.
  3. Scrap events from MES Operation Scrap.
  4. Scan events from MES Operation Scan.
- Each event includes declaredById and declaredByName (resolved from MES User → Employee; '-' when same as operator or not applicable).
- Returns flat JSON array.

`fetchMachineDashboard(hoursBack, workCenterNoJson): Text`
- Parses workCenterNoJson as a plain JSON string array → builds pipe-delimited filter.
- Applies SetFilter on Machine."Work Center No." before iterating.
- Per-machine aggregation: operationFinished/Cancelled counts, TotalProduced (delta approach — subtracts baseline before cutoff), TotalScrap (filtered by Declared At within window), uptime %.
- Uptime calculation seeds PrevStatus from the last status record before the cutoff, then processes events within the window, then handles the tail to now.
- Returns JSON array.

`resolveBarcode(barcode): Text`
- Checks if barcode contains 'Item Number:' prefix (DataMatrix format):
  - Parses Item No. from string.
  - Looks up Item, reads Item."MES Barcode Code" as canonical barcode.
- Looks up ItemIdentifier by code (up to 20 chars).
- Resolves Item.
- Looks up ItemUnitOfMeasure for barcode UOM and base UOM quantity per unit.
- Returns JSON: resolved, itemNo, itemDescription, baseUOM, baseUOMQuantityPerUnit, unitOfMeasure, quantityPerUnitOfMeasure.

---

### Codeunit 50126 — MES Web Service
**File:** `src/3-CodeUnit/MESWebService.al`

**Access:** Public. Published as OData V4 web service.

**Purpose:** Thin facade. No business logic. All procedures delegate to one of four internal codeunits.

**Dependencies:** `MESAuthentificationActions` (CU 50125), `MESMachineFetch` (CU 50131), `MESMachineWrite` (CU 50132), `MESToolFunctions` (CU 50128), `MESAuthMgt` (CU 50111), `MESSettingsFunctions` (CU 50124).

---

#### Auth procedures (delegate to MESAuthentificationActions)

| Procedure | Delegate |
|---|---|
| `Login(userId, password, deviceId)` | UnboundActions.Login |
| `Logout(token)` | UnboundActions.Logout |
| `Me(token)` | UnboundActions.Me |
| `ChangePassword(token, oldPassword, newPassword)` | UnboundActions.ChangePassword |
| `AdminCreateUser(token, userId, employeeId, roleInt, workCenterListJson)` | UnboundActions.AdminCreateUser |
| `fetchAllMESUsers()` | UnboundActions.fetchAllMESUsers |
| `fetchMESUsersByWC(wcId)` | UnboundActions.fetchMESUsersByWC |
| `AdminSetPassword(token, userId, newPassword)` | UnboundActions.AdminSetPassword |
| `AdminSetActive(token, userId, isActive)` | UnboundActions.AdminSetActive |
| `fetchAllEmployees()` | UnboundActions.fetchAllEmployees |
| `AdminChangeUserRole(token, targetUserId, newRoleInt, workCenterListJson)` | UnboundActions.AdminChangeUserRole |

#### Fetch procedures (delegate to MachineFetch)

| Procedure | Delegate |
|---|---|
| `FetchMachines(workCenterNoJson)` | MachineFetch.FetchMachines |
| `getMachineOrders(machineNo)` | MachineFetch.getMachineOrders |
| `fetchOngoingOperationsState(machineNo)` | MachineFetch.fetchOperationsStatusAndProgress(machineNo, false) |
| `fetchOperationsHistory(machineNo)` | MachineFetch.fetchOperationsStatusAndProgress(machineNo, true) |
| `fetchOperationLiveData(machineNo, prodOrderNo, operationNo)` | MachineFetch.fetchOperationLiveData |
| `fetchProductionCycles(machineNo, prodOrderNo, operationNo)` | MachineFetch.fetchProductionCycles |
| `fetchBom(prodOrderNo, operationNo)` | MachineFetch.fetchBom |
| `fetchAllItemBarcodes()` | MachineFetch.fetchAllItemBarcodes |
| `fetchActivityLog(hoursBack)` | MachineFetch.fetchActivityLog |
| `fetchMachineDashboard(hoursBack, workCenterNoJson)` | MachineFetch.fetchMachineDashboard |
| `resolveBarcode(barcode)` | MachineFetch.resolveBarcode |

#### Write procedures (delegate to MachineWrite, with identity resolution via TryResolveIdentity)

`startOperation(prodOrderNo, operationNo, machineNo, token): Text`
- TryResolveIdentity(token, '', DeclaredById, OperatorId, ErrorResult) → return ErrorResult if fails.
- MachineWrite.startOperation(prodOrderNo, operationNo, machineNo, OperatorId).

`declareProduction(machineNo, prodOrderNo, operationNo, input, token, onBehalfOfUserId): Text`
- TryResolveIdentity(token, onBehalfOfUserId, DeclaredById, OperatorId, ErrorResult) → return ErrorResult if fails.
- MachineWrite.declareProduction(machineNo, prodOrderNo, operationNo, input, OperatorId, DeclaredById).

`finishOperation(machineNo, prodOrderNo, operationNo, token): Text`
- MachineWrite.finishOperation(token, machineNo, prodOrderNo, operationNo). (Token resolved inside MachineWrite.)

`cancelOperation(machineNo, prodOrderNo, operationNo, token): Text`
- MachineWrite.cancelOperation(token, ...).

`pauseOperation(machineNo, prodOrderNo, operationNo, token): Text`
- MachineWrite.pauseOperation(token, ...).

`resumeOperation(machineNo, prodOrderNo, operationNo, token): Text`
- MachineWrite.resumeOperation(token, ...).

`insertScans(executionId, scansJson, token): Text`
- TryResolveIdentity(token, '', DeclaredById, OperatorId, ErrorResult).
- MachineWrite.insertScans(executionId, scansJson, OperatorId, DeclaredById).

`declareScrap(executionId, description, scrapCode, quantity, token, onBehalfOfUserId, materialId): Text`
- TryResolveIdentity(token, onBehalfOfUserId, DeclaredById, OperatorId, ErrorResult).
- MachineWrite.declareScrap(executionId, description, scrapCode, quantity, OperatorId, DeclaredById, materialId).

#### Tool procedures (delegate to MESToolFunctions)

| Procedure | Delegate |
|---|---|
| `fetchProductionOrders(statusFilter, workCenterNo, machineNo)` | Tools.fetchProductionOrders |
| `fetchWorkCenterSummary(workCenterNoJson, hoursBack)` | Tools.fetchWorkCenterSummary |
| `fetchOperatorSummary(workCenterNoJson, hoursBack)` | Tools.fetchOperatorSummary |
| `fetchMyData(token, hoursBack)` | Tools.fetchMyData |
| `fetchScrapSummary(hoursBack, prodOrderNo, operationNo, machineNo, workCenterNo, operatorId)` | Tools.fetchScrapSummary |
| `fetchDelayReport(workCenterNoJson, pauseThresholdMinutes)` | Tools.fetchDelayReport |
| `fetchConsumptionSummary(prodOrderNo, operationNo, machineNo, hoursBack)` | Tools.fetchConsumptionSummary |
| `fetchSupervisorOverview(workCenterNoJson, hoursBack, pauseThresholdMinutes)` | Tools.fetchSupervisorOverview |

#### Badge procedures (delegate to AuthMgt)

| Procedure | Delegate |
|---|---|
| `VerifyBadge(scannedSecret, token)` | AuthMgt.VerifyBadge(scannedSecret, token). **Bug:** references undefined local `userId` variable in the CopyStr line — compile/runtime error. |
| `GetBadgeSecret(adminToken, targetUserId)` | AuthMgt.GetBadgeSecret |
| `RegenerateBadgeSecret(adminToken, targetUserId)` | AuthMgt.RegenerateBadgeSecret |

#### Settings procedures (delegate to MESSettingsFunctions)

| Procedure | Delegate |
|---|---|
| `fetchSettings()` | settings.GetMESSettings |
| `updateSettings(pwChangePeriodDays, twoFAEnabled, token)` | settings.UpdateMESSettings |

---

#### Local: TryResolveIdentity

`TryResolveIdentity(token, onBehalfOfUserId, var DeclaredById, var OperatorId, var ErrorResult): Boolean`
- AuthMgt.ValidateToken → BuildError('Unauthorized') if fails.
- AuthMgt.TouchToken.
- DeclaredById = CallerUser.User Id.
- If onBehalfOfUserId blank: OperatorId = DeclaredById. Return true.
- TargetUserId = CopyStr(onBehalfOfUserId, 1, 50).
- MachineValidation.TryValidateProxyDeclaration(DeclaredById, TargetUserId) → BuildError('Forbidden') if fails.
- OperatorId = TargetUserId. Return true.

---

### Codeunit 50128 — MES Tool Functions
**File:** `src/3-CodeUnit/AI-endpoints/toolfunctions.al`

**Access:** Public (no explicit Access = Internal).

**Purpose:** Analytics and reporting endpoints. All procedures return JSON. Read-only except for token validation in fetchMyData.

**Dependencies:** All MES tables, `MESAuthMgt` (CU 50111), `MESJsonHelper` (CU 50120).

---

#### Public procedures

`fetchOperatorSummary(workCenterNoJson, hoursBack): Text`
- BuildWorkCenterFilter.
- Loop all MES Users; IsUserInExactWorkCenterScope → skip if not in scope.
- For each user: loop MES User Execution Interaction → for each execution in cutoff window:
  - FindLatestOperatorProgress → TotalProduced += CycleQuantity.
  - SumOperatorScrapForExecution → TotalScrap.
  - FindLatestExecutionState → count Finished/Paused/Running.
  - If Running: set IsActiveOnMachine=true, CurrentMachineNo, CurrentOrderNo, CurrentOpStatus.
- Employee.Get → fullName, email.
- Build user object with all computed metrics.

`fetchProductionOrders(statusFilter, workCenterNo, machineNo): Text`
- ApplyProductionOrderStatusFilter.
- Loop production order headers; ProductionOrderMatchesRoutingFilters → skip if not matching.
- For each order: SumProductionOrderProducedQuantity, ProductionOrderHasRunningOperation.
- BuildProductionOrderRoutingSummary.
- ProdOrderLine.FindFirst → item/qty.
- Build order object with all fields including progressPercent and operations array.

`fetchWorkCenterSummary(workCenterNoJson, hoursBack): Text`
- Filter Work Center by built filter.
- For each WC: CalculateWorkCenterMachineSummary → TotalMachines, Working, Idle, TotalProduced, TotalScrap.
- Count pending routing lines (Firm Planned + Released).
- CountRunningOperationsForWorkCenter.
- Count MES User Work Center rows.
- Build WC object.

`fetchMyData(token, hoursBack): Text`
- AuthMgt.ValidateToken → return error JSON if fails.
- AuthMgt.TouchToken.
- Loop MES User Execution Interaction by caller UserId.
- For each execution in cutoff: compute LatestState, count status types.
- Loop MES Operation Progression filtered by Operator Id → TotalProduced.
- Loop MES Operation Scrap filtered by Operator Id → TotalScrap.
- Build operations array.
- Loop MES Operation Scrap by OperatorId + DeclaredAt filter → build scrapRecords array.
- Return summary object with all computed data.

`fetchScrapSummary(hoursBack, filterProdOrderNo, filterOperationNo, filterMachineNo, filterWorkCenterNo, filterOperatorId): Text`
- Filter MES Operation Scrap by DeclaredAt ≥ cutoff, optionally by OperatorId.
- For each scrap: MESExecution.Get → ScrapRecordMatchesFilters.
- Build detail objects, accumulate TotalScrap.
- Return {totalScrapQty, recordCount, details[]}.

`fetchDelayReport(workCenterNoJson, pauseThresholdMinutes): Text`
- Filter Released + Firm Planned routing lines by work center.
- For each routing line:
  - Find MES Execution → FindLatestExecutionState.
  - If Finished or Cancelled → skip.
  - If Paused and paused for ≥ threshold → IsPausedTooLong=true.
  - If EndingDateTime < now → IsOverdue=true.
  - If no execution and IsOverdue → include as not-started delayed.
- Build delay objects for overdue or excessively paused operations.

`fetchConsumptionSummary(filterProdOrderNo, filterOperationNo, filterMachineNo, hoursBack): Text`
- Filter MES Executions by provided filters (hoursBack=0 means all time).
- For each execution: FindLatestExecutionProgress, GetRoutingLinkCode, ProductionOrderHasAnyRoutingLink.
- BuildExecutionConsumptionComponents → loops Prod. Order Components, filters by routing link, calculates PlannedQty and ConsumedQty.
- Build execution objects with components array including varianceQty, isOverConsumed, isUnderConsumed, isMissingConsumption.

`fetchSupervisorOverview(workCenterNoJson, hoursBack, pauseThresholdMinutes): Text`
- BuildStoppedMachinesOverview → machines with latest status = Idle.
- BuildSupervisorDelayAndPauseOverview → overdue unstarted operations + paused too long.
- BuildIdleOperatorsOverview → logged-in users with no running operation.
- BuildHighScrapOverview → executions with scrap > 10% of produced.
- Aggregate TotalProduced, TotalScrap.
- Return summary object with all arrays and counters.

---

#### Local helper procedures

`GetCutoffTime(hoursBack): DateTime`
- CurrentDateTime() - (hoursBack × 3,600,000 ms).

`BuildWorkCenterFilter(workCenterNoJson): Text`
- Parse JSON string array → join with '|'.

`FindLatestExecutionState(MESExecution, var MESState): Boolean`
- SetCurrentKey ExecutionTimeline. SetRange ExecutionId. Ascending(false). FindFirst.

`FindLatestExecutionProgress(MESExecution, var MESProgress): Boolean`
- SetCurrentKey ExecutionTimeline. SetRange ExecutionId. Ascending(false). FindFirst.

`FindLatestOperatorProgress(MESExecution, MESUser, var MESProgress): Boolean`
- SetCurrentKey ExecutionTimeline. SetRange ExecutionId. SetRange OperatorId. Ascending(false). FindFirst.

`IsUserInExactWorkCenterScope(MESUser, WorkCenterFilter): Boolean`
- If filter blank → true.
- MES User Work Center: SetRange UserId, SetFilter WCNo by filter. FindFirst.

`IsUserInSupervisorWorkCenterScope(MESUser, WorkCenterFilter): Boolean`
- If filter blank → true.
- Loop all user WC rows; StrPos check against filter string.

`IsUserLoggedInNow(MESUser): Boolean`
- Loop MES Auth Token by UserId. Return true if any State = Active and Expires At > now.

`IsUserLoggedInAt(MESUser, AtDateTime): Boolean`  
- Same but checks Expires At > AtDateTime. (Called from BuildIdleOperatorsOverview passing `Now`.)

`UserHasRunningOperation(MESUser): Boolean`
- Loop MES User Execution Interaction. For each: FindLatestExecutionState. Return true if Running.

`SumOperatorScrapForExecution(MESExecution, MESUser): Decimal`
- Sum MES Operation Scrap by ExecutionId + OperatorId.

`GetOperatorName(OperatorId): Text`
- MES User.Get → Employee.Get → Employee.FullName(). Empty string if not found.

`ApplyProductionOrderStatusFilter(var ProdOrderHeader, StatusFilter)`
- If blank: set filter for Planned|FirmPlanned|Released|Finished.
- Else: check StrPos for each status keyword and set individual filter.

`ProductionOrderMatchesRoutingFilters(ProdOrderHeader, WorkCenterNo, MachineNo): Boolean`
- If WorkCenterNo set: check routing line exists for that WC.
- If MachineNo set: check routing line exists for that machine.

`SumProductionOrderProducedQuantity(ProdOrderHeader): Decimal`
- Loop MES Executions for order. Sum latest progression TotalProduced.

`ProductionOrderHasRunningOperation(ProdOrderHeader): Boolean`
- Loop MES Executions for order. FindLatestExecutionState. Return true if Running.

`BuildProductionOrderRoutingSummary(ProdOrderHeader, var RoutingArr)`
- Loop Prod. Order Routing Lines. Build routing objects.

`CalculateWorkCenterMachineSummary(WorkCenter, CutoffTime, var TotalMachines, var WorkingMachines, var IdleMachines, var TotalProduced, var TotalScrap)`
- Loop Machine Center by WC.
- Latest MES Machine Status → Working/Idle count.
- MES Executions in cutoff → sum TotalProduced from latest progression, sum TotalScrap from all scrap records.

`CountRunningOperationsForWorkCenter(WorkCenter): Integer`
- Loop machines in WC. Loop executions per machine. FindLatestExecutionState. Count Running.

`ScrapRecordMatchesFilters(MESScrap, MESExecution, filters..., var MachineWCNo): Boolean`
- Check each non-blank filter field. Machine.Get → resolve WC.

`GetRoutingLinkCode(MESExecution): Code[10]`
- Find Prod. Order Routing Line by ProdOrderNo + OperationNo. Return Routing Link Code.

`ProductionOrderHasAnyRoutingLink(ProdOrderNo): Boolean`
- Find any Prod. Order Component with non-blank Routing Link Code.

`BuildExecutionConsumptionComponents(MESExecution, CurrentRoutingLinkCode, HasAnyRoutingLink, var CompArr)`
- Loop Prod. Order Components. ComponentBelongsToExecutionRouting filter.
- CalculatePlannedComponentQuantity, CalculateConsumedComponentQuantity.
- Build component objects with varianceQty, isOverConsumed, isUnderConsumed, isMissingConsumption.

`ComponentBelongsToExecutionRouting(ProdOrderComponent, CurrentRoutingLinkCode, HasAnyRoutingLink): Boolean`
- Returns not (HasAnyRoutingLink AND component has routing link AND routing link ≠ current).

`CalculatePlannedComponentQuantity(ProdOrderComponent, MESExecution): Decimal`
- ItemUnitOfMeasure.Get → QtyPerUnit × component Quantity per × Order Quantity.

`CalculateConsumedComponentQuantity(ProdOrderComponent, MESExecution): Decimal`
- Sum MES Operation Scan by ExecutionId + ItemNo. ConsumedQty += QtyScanned × QtyPerUOM.

`BuildStoppedMachinesOverview(WorkCenterFilter, Now, var StoppedMachineCount, var StoppedMachinesArr)`
- Loop machines. Latest MES Machine Status = Idle → build object with idleSinceMinutes.

`BuildSupervisorDelayAndPauseOverview(WorkCenterFilter, Now, PauseThresholdMinutes, var AbnormalPausesArr, var DelayedOpsArr)`
- Loop Released/FirmPlanned routing lines.
- If execution found and Paused ≥ threshold → add to AbnormalPausesArr.
- If no execution and past planned end → add to DelayedOpsArr.

`BuildIdleOperatorsOverview(WorkCenterFilter, Now, var IdleOperatorsArr)`
- Loop MES Users. IsUserInSupervisorWorkCenterScope. IsUserLoggedInNow. Not UserHasRunningOperation → add to array.

`BuildHighScrapOverview(WorkCenterFilter, CutoffTime, var TotalProduced, var TotalScrap, var HighScrapOpsArr)`
- Loop machines. Loop executions in cutoff. Sum scrap. FindLatestExecutionProgress.
- If ScrapQty / TotalProduced > 10% → add to array with scrapRate.

---

### Codeunit 50120 — MES Json Helper
**File:** `src/3-CodeUnit/shared/MESJsonHelper.al`

**Access:** Internal.

**Purpose:** Utility codeunit. Shared JSON serialization and error building.

**Procedures:**

`JsonToText(J: JsonObject): Text`
- J.WriteTo(JsonText). Return JsonText.

`JsonToTextArr(J: JsonArray): Text`
- J.WriteTo(JsonText). Return JsonText.

`BuildError(ErrorCode: Text; Message: Text): Text`
- Build {success:false, error: ErrorCode, message: Message}. Return JsonToText.

`BuildErrorFromLastError(ErrorCode: Text): Text`
- Msg = GetLastErrorText(). ClearLastError(). Return BuildError(ErrorCode, Msg).

**Consumed by:** All codeunits that build JSON responses.

---

### Codeunit 50115 — MES Setup
**File:** `src/3-CodeUnit/setup/MESSetup.al`

**Access:** Public.

**Purpose:** Initial provisioning. Run once to create default admin account and register password expiry job queue entry.

**OnRun trigger:**
1. CreateDefaultAccount().
2. RegisterPasswordExpiryWorker().

**CreateDefaultAccount()** — local
- AuthMgt.CreateUser('ADMIN', 'GB', 'AUTH-ADMIN01', Admin).
- AuthMgt.SetPassword('ADMIN', '00000000', forceChange=true, '').
- Message calls for operator feedback.

**RegisterPasswordExpiryWorker()** — local
- Check for existing Job Queue Entry for Codeunit "MES Password Expiry Worker".
- If found and On Hold → set Ready, Modify.
- If not found → create new recurring Job Queue Entry:
  - Object = Codeunit 50129.
  - Description = 'MES – Password Expiry Check'.
  - Run in User Session = false.
  - Recurring = true.
  - No. of Minutes between Runs = 1440 (24 hours).
  - Earliest Start = CurrentDateTime().
  - Status = Ready.

**Consumed by:** `MESApiDebug.Page.al` RunSetup action.

---

### Codeunit 50124 — MES Settings Functions
**File:** `src/3-CodeUnit/setup/settings.al`

**Access:** Public (no explicit Access = Internal).

**Dependencies:** `MESAuthValidation` (CU 50112), `MESJsonHelper` (CU 50120), `MES Settings` table.

**Procedures:**

`GetMESSettings(): Text`
- MESSettings.FindFirst.
- If not found: return {pwChangePeriod:'0', twoFAEnabled:false}.
- PwChangePeriodDays = MESSettings."PW change period" / 86,400,000.
- Return {pwChangePeriod: formatted days (1 decimal), twoFAEnabled: boolean}.

`UpdateMESSettings(PwChangePeriodDays, TwoFAEnabled, token): Text`
- AuthVal.TryValidateAdminToken → BuildErrorFromLastError if fails.
- PwChangePeriodDays < 0 → Error.
- Deletes the existing settings record if present (cannot modify PK field).
- Init + Insert new record with `PW change period = PwChangePeriodDays × 86,400,000`, `TwoFA Enabled = TwoFAEnabled`.
- Return {success:true}.

**Consumed by:** `MESWebService.fetchSettings`, `MESWebService.updateSettings`.

---

### Codeunit 50100 — MES Barcode Generator
**File:** `src/3-CodeUnit/machines/barCodeGenerator/MES_Barcode_Generator.al`

**Access:** Public.

**Purpose:** Generates and persists DataMatrix barcode data for items.

**Procedures:**

`GenerateItemBarcodeText(itemNo): Text`
- Item.Get → error if not found.
- Build pipe-delimited string: 'Item Number: %1|Item Description: %2|Base UOM: %3|Lot Size: %6|Flushing Method: %7'.
- Return string.

`GenerateAndSaveBarcodeText(itemNo, uomCode)`
- BarcodeText = GenerateItemBarcodeText(itemNo).
- Item.Get(itemNo).
- Item."MES Barcode Text" = CopyStr(BarcodeText, 1, 250).
- ShortCode = CopyStr('MES-' + itemNo, 1, 20).
- Item."MES Barcode Code" = ShortCode.
- Item.Modify().
- ItemIdentifier: Init if not exists; set Code=ShortCode, Item No.=itemNo, Unit of Measure Code=uomCode, Variant Code=''.
- If ItemIdentifier.Find → Modify; else Insert.

**Consumed by:** `MESItemBarcodes` page GenerateBarcode action.

---

### Codeunit 50127 — MES Dev Setup
**File:** `src/3-CodeUnit/dev-toberemoved/MESDevSetup.al`

**Access:** Public. **Flagged for removal — sandbox/dev only.**

**Purpose:** Provisions three development users with permanent tokens.

**OnRun trigger:**
1. Set fixed GUIDs for three tokens.
2. EnsureDevUser('DEV-OPERATOR', 'AC', 'AUTH-DEV-OP', Operator).
3. EnsureDevUser('DEV-SUPERVISOR', 'AF', 'AUTH-DEV-SV', Supervisor).
4. EnsureDevUser('DEV-ADMIN', 'CB', 'AUTH-DEV-AD', Admin).
5. EnsureOperatorWorkCenter('DEV-OPERATOR') — assigns first available WC.
6. EnsureSupervisorAllWorkCenters('DEV-SUPERVISOR') — assigns all WCs.
7. EnsureDevToken(OperatorTokenGuid, 'DEV-OPERATOR').
8. EnsureDevToken(SupervisorTokenGuid, 'DEV-SUPERVISOR').
9. EnsureDevToken(AdminTokenGuid, 'DEV-ADMIN').

**GetTokenSummary(): Text**
- Return JSON with three token GUIDs.

**EnsureDevUser(userId, employeeId, authId, role)** — local, idempotent
- If MES User.Get(userId) → exit (already exists).
- AuthMgt.CreateUser + SetPassword('Dev@1234!', false, '').

**EnsureOperatorWorkCenter(userId)** — local, idempotent
- If MES User Work Center rows exist for user → exit.
- WC.FindFirst → assign first WC.

**EnsureSupervisorAllWorkCenters(userId)** — local, idempotent
- If MES User Work Center rows exist → exit.
- WC.FindSet → assign all WCs.

**EnsureDevToken(tokenGuid, userId)** — local, idempotent
- Evaluate GUID. T.Get → exit if exists.
- Insert token with State=Active and Expires At = 9999-12-31 23:59:59 (permanent).

**Consumed by:** `MESApiDebug` page RunDevSetup action.

---

### Codeunit 50129 — MES Password Expiry Worker
**File:** `src/6-workers/MESPasswordExpiryWorker.al`

**Access:** Public.

**Purpose:** Scheduled job that flags users whose passwords have exceeded the configured expiry period.

**OnRun trigger:** Calls CheckAndFlagExpiredPasswords().

**Public procedures:**

`CheckAndFlagExpiredPasswords()`
- Calls RunInternal(false, Dummy). No output.

`CheckAndFlagExpiredPasswordsVerbose(): Text`
- Calls RunInternal(true, Report). Returns diagnostic text.

**RunInternal(Verbose, var Report)** — local
- EnsureSettingsExists → create default MES Settings if absent (30-day default).
- Read `PW change period` (Duration).
- If < 0: abort (feature disabled). (Note: check is `< 0` not `≤ 0` — a zero value does not disable.)
- CutoffDateTime = CurrentDateTime() - PwChangePeriodMs.
- Filter MES Users: IsActive=true, Hashed Password ≠ ''.
- FindSet.
- For each user: ShouldFlagUser → if true: set NeedToChangePw=true, Modify.
- Optional verbose TextBuilder output per user.

**ShouldFlagUser(MESUser, CutoffDateTime): Boolean** — local
- If LastPasswordChangedAt = 0DT → true.
- If LastPasswordChangedAt < CutoffDateTime → true.
- Else false.

**EnsureSettingsExists(var MESSettings, Verbose, var B)** — local
- MESSettings.FindFirst → exit if found.
- Else: Init, Validate "PW change period" = 30 × 86,400,000 ms, Insert.

**GetDefaultPwChangePeriod(): Duration** — local
- Return 30 × 86,400,000 ms.

---

## Section 4 — API Pages

---

### Page 50120 — MES Scrap Code API
**File:** `src/4-API/MESScrapCode.al`

**Type:** API. **SourceTable:** Scrap. **Editable:** false.
**Endpoint:** `scrapCodes` (EntitySetName).
**Publisher/Group/Version:** yourcompany / v1 / v1.0.

**Exposed fields:** Code, Description.

---

### Page 50100 — MES Employee API
**File:** `src/4-API/admin/MESEmployees.al`

**Type:** API. **SourceTable:** Employee. **Editable:** false.
**Endpoint:** `employees`.

**Exposed fields:** No. (as id), First Name, Middle Name, Last Name, E-Mail, Image.

**OnFindRecord trigger:**
- Filters out Employee records that already have a corresponding MES User (MES User.SetRange EmployeeID → IsEmpty check).
- Only returns employees not yet assigned to an MES User.

---

### Page 50101 — MES User API
**File:** `src/4-API/admin/MESUsers.al`

**Type:** API. **SourceTable:** MES User. **Editable:** false.
**Endpoint:** `mesUsers`.

**Exposed fields:** User Id, Employee ID, Role, Auth ID, Is Active, Need To Change Pw, Created At, First Name (from Employee), Last Name (from Employee), E-Mail (from Employee), Work Center Name (from Work Center — commented out FK).

**OnAfterGetRecord:** Employee.Get using Employee ID → populates EmployeeRec fields. WorkCenterRec join is commented out.

---

### Page 50103 — MES User Create API
**File:** `src/4-API/admin/MESUsersCreate.al`

**Type:** API. **SourceTable:** MES User. **Write-enabled.**
**Endpoint:** `createMesUsers`.

**Exposed fields:** Same as MESUsers plus writable fields. Employee and Work Center fields are read-only (Editable=false).

**OnAfterGetRecord:** Employee.Get → populate EmployeeRec. Work Center join commented out.

---

### Page 50102 — MES Work Center API
**File:** `src/4-API/admin/MesWorkCenter.al`

**Type:** API. **SourceTable:** Work Center. **Editable:** false.
**Endpoint:** `workCenters`.

**Exposed fields:** No. (as id), Name (as workCenterName).

---

### Page 50110 — MES Prod Order Component API
**File:** `src/4-API/admin/test.al`

**Type:** API. **SourceTable:** Prod. Order Component. **Editable:** false.
**Endpoint:** `prodOrderComponents`.

**Exposed fields:** Status, Prod. Order No., Prod. Order Line No., Line No., Item No., Description, Quantity, Remaining Quantity, Act. Consumption (Qty), Unit of Measure Code, Routing Link Code.

---

## Section 5 — Permission Set

### PermissionSet 50130 — MES AUTH API
**File:** `src/5-PermissionSet/auth/MESAuthApi.permissionset.al`

**Assignable:** true.

| Object | Permission |
|---|---|
| tabledata "MES User" | RIMD |
| tabledata "MES Auth Token" | RIMD |
| table "MES Auth Token" | X |
| codeunit "MES Password Mgt" | X |
| codeunit "MES Auth Mgt" | X |
| codeunit "MES Setup" | X |
| codeunit "MES Unbound Actions" | X |
| codeunit "MES Web Service" | X |

---

## Section 6 — UI Pages

---

### Page 50140 — MES API Debug
**File:** `src/5-Pages/MESApiDebug.Page.al`

**Type:** Card. **SourceTable:** Integer (temporary). Admin/debug tool.

**Input fields:** UserId, Password (masked), DeviceId, Token, OldPassword (masked), NewPassword (masked), EmployeeId, AuthId, RoleInt, WorkCenterNo, IsActive.

**Output field:** LastResponse (multi-line text).

**Actions:**
- `RunSetup` — Codeunit.Run(MES Setup).
- `RunDevSetup` — DevSetup.Run(); LastResponse = DevSetup.GetTokenSummary().
- `RunPasswordExpiryCheck` — LastResponse = Worker.CheckAndFlagExpiredPasswordsVerbose().
- `OpenUserList` — Page.Run(MES User List).
- `ClearResponse` — LastResponse = ''.

**OnOpenPage:** Builds ApiList text with endpoint reference.

---

### Page 50141 — MES User List / Page 50142 — MES User Card
**Files:** `src/5-Pages/MESUserList.Page.al`, `src/5-Pages/MESUserCard.Page.al`

**Type:** List / Card. **SourceTable:** MES User.

**List fields:** User Id, Employee ID, Auth ID, Role, Work Centers (computed), Is Active, Need To Change Pw, Has Password (computed), Last Password Changed At, Created At.

**Card fields:** User Id, Employee ID, Auth ID, Role, Work Centers (computed), Is Active, Need To Change Pw, Created At.

**GetWorkCentersText():** Loops MES User Work Center → Work Center.Get → comma-separated Name string.

**GetHasPasswordText():** Returns 'Yes' if Hashed Password ≠ '' else 'No'.

---

### Page 50143 — MES Machine List
**File:** `src/5-Pages/MESMachineList.Page.al`

**Type:** List. **SourceTable:** Machine Center.

**Fields:** No., Name, Work Center No., Blocked, Current Status (computed), Current Prod. Order (computed).

**GetMachineStatus():** MES Machine Status.SetRange, FindLast → Format(Status). Returns 'Idle' if no rows.

**GetCurrentOrder():** MES Machine Status.SetRange, FindLast → Current Prod. Order No.

**Actions:** SetStarting (insert Working status row), SetIdle (insert Idle status row).

---

### Page 50108 — MES Operations
**File:** `src/5-Pages/MESOperation.Page.al`

**Type:** List. **SourceTable:** MES Operation State. Full CRUD.

**Fields:** Id, Execution Id, Operation Status, Declared At.

**Actions:** SetRunning, SetPaused, SetFinished — directly modify the record's Operation Status.

---

### Page 50111 — MES Operation Execution
**File:** `src/5-Pages/MESOperationExecution.Page.al`

**Type:** List. **SourceTable:** MES Operation Execution. Full CRUD.

**Fields:** Execution Id, Machine No, Prod Order No, Operation No, Item No, Item Description, Order Quantity, Start Time, End Time.

---

### Page 50109 — MES Operation Progression
**File:** `src/5-Pages/MESOperationProgress.Page.al`

**Type:** List. **SourceTable:** MES Operation Progression. Full CRUD.

**Fields:** Id, Execution Id, Operator Id, Cycle Quantity, Total Produced Quantity, Declared At.

---

### Page 50149 — MES Operation Scrap List
**File:** `src/5-Pages/MESOperationScrapList.Page.al`

**Type:** List. **SourceTable:** MES Operation Scrap. Read-only display.

**Fields:** Id, Execution Id, Scrap Quantity, Scrap Code, scrap Description, scrap notes, Operator Id, Declared At.

---

### Page 50115 — MES Component Consumption
**File:** `src/5-Pages/MESComponentConsumption.Page.al`

**Type:** List. **SourceTable:** MES Operation Scan. Full CRUD.

**Fields:** Id, Execution Id, Prod Order No, Item No, Barcode, Quantity Scanned, Unit of Measure, Quantity per Unit of Measure, Operator Id, Scanned At.

---

### Page 50112 — MES Item Barcodes / Page 50113 — MES Select UOM Dialog
**File:** `src/5-Pages/MESItemBarcodes.Page.al`

**MES Item Barcodes (50112):**
**Type:** List. **SourceTable:** Item. Read-only. Filtered to items where MES Barcode Code ≠ ''.

**Fields:** No., Description, Base Unit of Measure, MES Barcode Code, MES Barcode Text.

**GenerateBarcode action:**
- Open MES Select UOM Dialog (50113) modal for selected item.
- On OK: get SelectedUOM; call BarcodeGen.GenerateAndSaveBarcodeText(Rec.No., SelectedUOM). CurrPage.Update. Message.

**MES Select UOM Dialog (50113):**
**Type:** StandardDialog.

**Fields:** SelectedUOMCode (editable, with lookup against Item Units of Measure filtered to item), QtyPerUOM (read-only, auto-populates on selection).

**SetItemNo(itemNo):** Sets ItemNoFilter.

**GetSelectedUOM(): Code[10]:** Returns SelectedUOMCode.

**UpdateQty():** Finds ItemUnitOfMeasure by ItemNoFilter + SelectedUOMCode → sets QtyPerUOM.

**SelectedUOMCode OnLookup:** Opens Item Units of Measure page in lookup mode filtered to item. On OK: sets SelectedUOMCode, Text, UpdateQty, CurrPage.Update.

---

## Section 7 — Call Trace Summary

### Top-Level Entry Point

```
OData Client
  → POST /ODataV4/MESWebService_<ProcedureName>
    → CU 50126: MES Web Service
```

### Auth Call Chain

```
MES Web Service (50126)
  → MES Authentication Actions (50125)
    → MES Auth Mgt (50111)
      → MES Password Mgt (50110)      [crypto]
      → MES Auth Validation (50112)   [TryFunctions + RevokeAllTokens]
    → MES Json Helper (50120)         [JSON building]
    → [tables: MES User, MES Auth Token, MES User Work Center, Employee, MES Settings]
```

### Fetch Call Chain

```
MES Web Service (50126)
  → MES Machine Fetch (50131)
    → MES Machine Insert (50133)      [GetExecution, GetLatestProgression]
    → [tables: MES Operation Execution, MES Operation State, MES Operation Progression,
               MES Operation Scrap, MES Operation Scan (Component Consumption),
               MES Machine Status, Prod. Order Routing Line, Prod. Order Line,
               Prod. Order Component, Machine Center, Work Center, Item, Item Identifier,
               Item Unit of Measure, Scrap, MES User, Employee]
```

### Write Call Chain

```
MES Web Service (50126)
  → TryResolveIdentity [local]
    → MES Auth Mgt (50111)            [ValidateToken, TouchToken]
    → MES Machine Validation (50134)  [TryValidateProxyDeclaration]
  → MES Machine Write (50132)
    → MES Auth Mgt (50111)            [ValidateToken, TouchToken — for finish/cancel/pause/resume]
    → MES Machine Validation (50134)  [all TryXxx guards]
    → MES Machine Insert (50133)      [all table writes]
      → Item Jnl.-Post Line           [output posting on last operation; consumption posting on scans]
      → Prod. Order Status Management [ERP order finish on close/cancel]
    → MES Json Helper (50120)
```

### Tool/Analytics Call Chain

```
MES Web Service (50126)
  → MES Tool Functions (50128)
    → MES Auth Mgt (50111)            [fetchMyData only]
    → [tables: MES User, MES Operation Execution, MES Operation State,
               MES Operation Progression, MES Operation Scrap, MES Operation Scan,
               MES User Execution Interaction, MES User Work Center,
               MES Auth Token, Prod. Order Routing Line, Machine Center, Work Center, Employee]
```

### Settings Call Chain

```
MES Web Service (50126)
  → MES Settings Functions (50124)
    → MES Auth Validation (50112)     [TryValidateAdminToken — for update]
    → [table: MES Settings]
```

### Badge / 2FA Call Chain

```
MES Web Service (50126)
  → MES Auth Mgt (50111) — VerifyBadge(scannedSecret, token)
    → [table: MES Auth Token]  [validates token, promotes State Pending → Active]
    → [table: MES User]        [reads Badge Secret for comparison]
```

### Password Expiry Worker Chain

```
Job Queue (scheduled, 24h interval)
  → MES Password Expiry Worker (50129)
    → [tables: MES Settings, MES User]
```

### Barcode Generation Chain

```
MES Item Barcodes page (50112)
  → MES Select UOM Dialog (50113)
  → MES Barcode Generator (50100)
    → [tables: Item (via MES Item Extension), Item Identifier, Item Unit of Measure]
```

---

## Section 8 — Known Issues (from docs/BUGS.md)

1. If barcodes are regenerated multiple times (for multiple items at once), the process does not work correctly.
2. If the Flutter app refreshes using the R action, the user is redirected to the login page; if they refresh again, they are redirected to the correct path — the session is still live and not expired.

---

## Section 9 — Known Code-Level Issues (from code inspection)

### MESAuthMgt.VerifyBadge — Missing begin/end on Conditional Block
**File:** `src/3-CodeUnit/auth/MESAuthMgt.al`

The `if result then` block that guards token promotion lacks `begin/end`. Only `TouchToken(T)` is conditionally executed. The subsequent `T.State := T.State::Active` and `T.Modify(true)` statements run unconditionally on every call, so a failed badge scan still promotes the token from Pending to Active.

### MESWebService.VerifyBadge — Undefined userId Variable
**File:** `src/3-CodeUnit/MESWebService.al`

The `VerifyBadge(scannedSecret, token)` procedure contains a `CopyStr(userId, 1, 50)` reference where `userId` is not declared as a local variable or parameter. This will cause a compile error or runtime failure. The line is a leftover from a prior version of the signature that accepted a userId parameter.

### MESAuthMgt.CreateUser — AuthID Not Guaranteed Unique
**File:** `src/3-CodeUnit/auth/MESAuthMgt.al`

The `AuthID` parameter is stored as-is. When called from `AdminCreateUser`, an empty string `AuthIdCode` is passed in, relying entirely on `MES User.OnInsert.GenerateUniqueAuthId()` for uniqueness. When called from `MESSetup.CreateDefaultAccount`, the literal 'AUTH-ADMIN01' is passed. There is no uniqueness pre-check in `CreateUser` itself.

### MESDevSetup — Flagged for Removal
**File:** `src/3-CodeUnit/dev-toberemoved/MESDevSetup.al`

Directory name `dev-toberemoved` and code structure indicate this codeunit should not be deployed to production. It creates users with weak passwords and permanently non-expiring tokens.

### MES Operation Progression — Scrap Quantity Field Absent
**Table:** MES Operation Progression.

Field 4 (`Scrap Quantity`) that existed in earlier documentation is no longer present in the table definition. Scrap is tracked exclusively in MES Operation Scrap and computed via live summation. The `fetchProductionCycles` procedure previously commented it out (`//CycleObj.Add('scrapQuantity', ...)`), consistent with this.

---

## Section 10 — Data Flow: Key Operations

### Login Flow

1. Client POSTs userId (= Auth ID), password, deviceId.
2. `MESWebService.Login` → `MESAuthentificationActions.Login`.
3. Lookup MES User by Auth ID (SetRange + FindFirst).
4. `TryValidateCredentials` → `MESAuthMgt.ValidateCredentials` → verify hash.
5. Read MES Settings → TwoFAEnabled flag.
6. If TwoFAEnabled: `MESAuthMgt.IssueNewToken(..., Pending=true)` → token State = Pending. Else: IssueNewToken(..., Pending=false) → token State = Active.
7. Read MES User Work Center → workCenters array.
8. Read Employee → fullName, email, imageBase64.
9. Return JSON with token GUID, twoFAEnabled flag, user fields, work centers.

### Badge / 2FA Verification Flow

1. Client POSTs scannedSecret (badge QR content), token (Pending token from Login).
2. `MESWebService.VerifyBadge` → `MESAuthMgt.VerifyBadge(scannedSecret, token)`.
3. T.Get(token) → resolve user via T."User Id".
4. Compare scannedSecret to U."Badge Secret".
5. If match: TouchToken(T). T.State := Active; T.Modify → token promoted to Active.
6. Return {success:true} or BuildError.
7. **Note:** Due to the missing begin/end bug, T.State := Active executes even on mismatch (see Section 9). Also note the undefined `userId` variable in MESWebService.VerifyBadge causes a compile error before this flow can be reached.

### Start Operation Flow

1. Client POSTs prodOrderNo, operationNo, machineNo, token.
2. `MESWebService.startOperation` → TryResolveIdentity → DeclaredById/OperatorId resolved from token.
3. `MESMachineWrite.startOperation` → `MESMachineValidation.TryStartOperation`:
   - Check routing line Released.
   - EnsureNoRunningOperation (same order/operation, same machine).
   - Check previous operation completion (with SendAheadQuantity logic).
4. `MESMachineInsert.InsertStartOperationRecords`:
   - InsertMESOperationExecution → new execution row.
   - InsertMESOperation → state row (Running) + EnsureUserExecutionInteraction.
   - InsertMESOperationProgression → zero-qty progression row.
   - InsertStartMESMachineStatus → machine status Working.
5. Return {value: true}.

### Declare Production Flow

1. Client POSTs machineNo, prodOrderNo, operationNo, input, token, onBehalfOfUserId.
2. `MESWebService.declareProduction` → `TryResolveIdentity`:
   - ValidateToken → DeclaredById = caller.
   - If onBehalfOfUserId set: TryValidateProxyDeclaration (supervisor/operator WC overlap check). OperatorId = target.
3. `MESMachineWrite.declareProduction` → `TryDeclareProduction`:
   - GetExecution. GetLatestProgression. input > 0. Total + input ≤ OrderQuantity.
4. `InsertNewProgressionCycle`: new progression row with CycleQty=input, TotalProduced=prev+input.
5. If IsLastOperation: IncreaseItemInventory posts an Output journal line.
6. Return {value: true}.

### Declare Scrap Flow

1. Client POSTs executionId, description, scrapCode, quantity, token, onBehalfOfUserId, materialId.
2. `MESWebService.declareScrap` → TryResolveIdentity.
3. `MESMachineWrite.declareScrap` → `TryDeclareScrap`:
   - Execution.Get. GetLatestOperationStatus → must be Running.
   - Scrap.Get(scrapCode). quantity > 0.
4. `InsertScrapRecord`: new scrap row with Material Id.
5. Return {value: true}.

### Insert Scans Flow

1. Client POSTs executionId, scansJson, token.
2. `MESWebService.insertScans` → TryResolveIdentity (no onBehalfOf).
3. `MESMachineWrite.insertScans`:
   - Execution.Get. ProdOrder.Get. ProdOrderLine.Get.
   - Find journal batch 'ARTICLE'/'DEFAUT'. Get document no.
   - Clean existing lines.
   - For each scan: insert MES Operation Scan row; build Item Journal Line (Consumption type); post immediately via `Item Jnl.-Post Line.RunWithCheck`.
   - EnsureUserExecutionInteraction.
4. Return {value: true}.

### Operation State Transition Flow (Finish/Cancel/Pause/Resume)

1. Client POSTs machineNo, prodOrderNo, operationNo, token.
2. `MESWebService.<action>` → `MESMachineWrite.<action>`.
3. `TryResolveUser` → ValidateToken + TouchToken. MesUserId set.
4. `ExecuteOperationTransition(targetStatus, mesUserId)`:
   - Route to TryCloseOperation / TryPauseOperation / TryResumeOperation.
   - `InsertOperationStatus` → new state row. End Time stamped on Finished/Cancelled/Interrupted.
   - If Running: `InsertStartMESMachineStatus`; else `InsertIdleMachineStatus`.
   - If Finished/Cancelled/Interrupted: `SetErpOrderToFinish` → may finish the ERP production order.
5. Return {value: true}.