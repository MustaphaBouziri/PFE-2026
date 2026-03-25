// =============================================================================
// PermissionSet: MES AUTH API
// ID           : 50130
// Domain       : Auth / 5-PermissionSets
// Purpose      : Minimum permissions needed to call all MES auth and admin
//                endpoints.  Assign to any BC user or service account that
//                needs to call the MES APIs.
//
// PERMISSION LEGEND:  R=Read  I=Insert  M=Modify  D=Delete  X=Execute
// =============================================================================
permissionset 50130 "MES AUTH API"
{
    Assignable = true;
    Caption    = 'MES Authentication API';

    Permissions =
        // Table data — full CRUD required for auth operations
        tabledata "MES User"       = RIMD,
        tabledata "MES Auth Token" = RIMD,

        // Table object — allows calling table methods directly
        table "MES Auth Token"     = X,

        // Codeunit execution
        codeunit "MES Password Mgt"    = X,
        codeunit "MES Auth Mgt"        = X,
        codeunit "MES Setup"           = X,
        codeunit "MES Unbound Actions" = X,
        codeunit "MES Machine Actions" = X,
        codeunit "MES Web Service"     = X;
}
