// =============================================================================
// PermissionSet: MES AUTH API
// Object ID    : 50130
// Purpose      : Grants the minimum permissions required to call every MES
//                authentication endpoint (both user-facing and admin).
//
// Assignable   : true  — assign this set to any Business Central user or
//                        service account that needs to call the MES APIs.
//
// PERMISSION LEGEND
//   R = Read    I = Insert    M = Modify    D = Delete    X = Execute
//
// MIGRATION NOTE
// ──────────────
// The old "MES Auth Actions" API page (50121) and "MES Auth API" codeunit
// (50120) have been removed.  The new "MES Unbound Actions" codeunit (50125)
// replaces both.  The permission set is updated accordingly.
// =============================================================================
permissionset 50130 "MES AUTH API"
{
    Assignable = true;
    Caption    = 'MES Authentication API';

    Permissions =
        // ── Table data permissions ────────────────────────────────────────────
        // MES User: full CRUD so the API can read, create, and update users.
        tabledata "MES User"       = RIMD,

        // MES Auth Token: full CRUD so the API can issue, update, and revoke tokens.
        tabledata "MES Auth Token" = RIMD,

        // ── Table object permissions ──────────────────────────────────────────
        // Execute (X) on the table object allows calling table methods directly.
        table "MES Auth Token"     = X,

        // ── Codeunit execute permissions ──────────────────────────────────────
        // Password hashing utilities (used internally by Auth Mgt).
        codeunit "MES Password Mgt"     = X,

        // Core business logic layer.
        codeunit "MES Auth Mgt"         = X,

        // ── NEW: Unbound Actions codeunit (replaces old API page + API codeunit)
        codeunit "MES Unbound Actions"  = X;
}
