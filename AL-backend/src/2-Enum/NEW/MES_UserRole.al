// =============================================================================
// Enum   : MES User Role
// ID     : 50100
// Purpose: Defines the access levels available to MES user accounts.
//          Used by the "MES User"."Role" field and enforced at runtime by
//          MESAuthMgt.RequireAdmin().
//
// ROLE DESCRIPTIONS
//   Operator   (0) — Floor-level production worker.
//                    Can log in, view their own work orders, and record
//                    production activity.  No administrative capability.
//
//   Supervisor (1) — Team leader or shift manager.
//                    Inherits Operator access plus the ability to view and
//                    approve work orders for their work center.
//
//   Admin      (2) — System administrator.
//                    Full access including user management (create, deactivate,
//                    reset passwords) via the AdminCreateUser, AdminSetPassword,
//                    and AdminSetActive API endpoints.
//                    Only Admin tokens pass the RequireAdmin() guard.
//
// EXTENSIBILITY
//   Extensible = true allows other AL extensions to add custom roles without
//   modifying this file.  If you add a role, also update the roleInt mapping
//   in MESUnboundActions.AdminCreateUser() and the documentation.
//
// CAPTIONS
//   Captions are displayed in Business Central UI pages (MES User List, Card).
//   Using the correct French characters here ensures they render correctly
//   in all BC clients without encoding issues.
// =============================================================================
enum 50100 "MES User Role"
{
    Extensible = true;

    // -------------------------------------------------------------------------
    // 0 — Operator
    // Standard floor worker.  This is the default role for new accounts.
    // -------------------------------------------------------------------------
    value(0; Operator)
    {
        Caption = 'Opérateur';
    }

    // -------------------------------------------------------------------------
    // 1 — Supervisor
    // Team lead / shift manager.  Higher trust than Operator.
    // -------------------------------------------------------------------------
    value(1; Supervisor)
    {
        Caption = 'Superviseur';
    }

    // -------------------------------------------------------------------------
    // 2 — Admin
    // Full system administrator.  Required for all user-management API calls.
    // Assign this role sparingly — every Admin can create and deactivate users.
    // -------------------------------------------------------------------------
    value(2; Admin)
    {
        Caption = 'Admin';
    }
}
