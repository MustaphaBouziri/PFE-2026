// =============================================================================
// Codeunit: MES Setup
// ID      : 50115
// Purpose : One-time bootstrap utility that seeds the first Admin account into
//           the MES User table.
//
// WHEN TO USE
//   Run this codeunit exactly ONCE after deploying the MES extension to a
//   new Business Central environment.  It creates the default "admin" user
//   with a temporary password.  The account is created with
//   Need To Change Pw = true, so the admin must call ChangePassword on first
//   login before using the MES API.
//
// HOW TO RUN
//   Option A — From the MES API Debug page:
//     Open the "MES API Debug" page (50140), find the "Run MES Setup" button
//     in the Setup group, and click it.
//
//   Option B — From the AL Debugger / Development environment:
//     Run the codeunit directly: Codeunit.Run(Codeunit::"MES Setup")
//
//   Option C — Via a Job Queue entry (automated post-deployment):
//     Create a Job Queue Entry with Object Type = Codeunit, Object ID = 50115.
//     Run once and then delete or disable the entry.
//
// DEFAULT CREDENTIALS CREATED
//   User Id  : admin
//   Password : Admin@123!  ← CHANGE THIS IMMEDIATELY after first login
//   Role     : Admin
//
// IDEMPOTENCY
//   CreateUser() in MES Auth Mgt raises an error if the user already exists,
//   so running this codeunit a second time will fail gracefully with a message.
//   It will NOT overwrite or duplicate the admin account.
//
// SECURITY WARNING
//   The hardcoded password "Admin@123!" is well-known.  Any attacker who
//   reads this source code knows it.  Change it immediately after setup by
//   calling the ChangePassword API endpoint or AdminSetPassword.
// =============================================================================
codeunit 50115 "MES Setup"
{
    trigger OnRun()
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        Message('MES Setup started — creating default admin account.');

        // Create the admin user record.
        // Parameters: UserId, EmployeeID, AuthID, Role, WorkCenterNo
        // EmployeeID is left blank — the admin account has no HR record link.
        // WorkCenterNo is left blank — the admin works across all work centers.
        AuthMgt.CreateUser(
            'ADMIN',                    // User Id      — login username
            '',                         // Employee ID  — no linked HR employee
            'AD001',                    // Auth ID      — external identity ref
            "MES User Role"::Admin,     // Role         — full admin access
            '');                        // Work Center  — not assigned to one WC

        // Set the initial temporary password.
        // ForceChangeOnNextLogin = true means the user must call ChangePassword
        // on their first successful login before they can use the system.
        AuthMgt.SetPassword(
            'ADMIN',        // User Id
            '00000000',   // Temporary password — CHANGE THIS IMMEDIATELY
            true);          // Force change on next login

        Message('MES Setup complete. Login as "admin" and change the password immediately.');
    end;
}
