// =============================================================================
// Enum   : MES User Role
// ID     : 50100
// Domain : Auth / 2-Enums
// Purpose: Defines the access levels available to MES user accounts.
//          Referenced by "MES User"."Role" and enforced at runtime by
//          MESAuthMgt.RequireAdmin() (codeunit 50111).
//
// ROLES
//   Operator   (0) — floor-level worker; basic MES operations only
//   Supervisor (1) — team lead; view and approve work orders for their center
//   Admin      (2) — full access; user management via API endpoints
//
// EXTENSIBILITY
//   Extensible = true allows other AL extensions to add custom roles without
//   modifying this file.  If adding a role, also update the roleInt mapping
//   in MESUnboundActions.AdminCreateUser() and the app_constants.dart file
//   in the Flutter frontend.
// =============================================================================
enum 50100 "MES User Role"
{
    Extensible = true;

    value(0; Operator)
    {
        Caption = 'Opérateur';
    }

    value(1; Supervisor)
    {
        Caption = 'Superviseur';
    }

    value(2; Admin)
    {
        Caption = 'Admin';
    }
}
