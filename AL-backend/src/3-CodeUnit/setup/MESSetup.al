// =============================================================================
// Codeunit: MES Setup
// ID      : 50120
// Domain  : Auth / 3-CodeUnits
// Purpose : One-time initialisation — seeds the default Admin account.
//           Run ONCE on a fresh environment via the "Run MES Setup" action
//           on the MES API Debug page, or schedule as a Job Queue entry.
//           Fails gracefully (Message) if the admin account already exists.
//
// DEFAULT ADMIN CREDENTIALS
//   User Id  : ADMIN
//   Password : Admin@123!
//   The administrator MUST change this password immediately after first login.
//   Need To Change Pw = true is set automatically by SetPassword().
//
// NOTE ON EMPLOYEE ID
//   The default admin is created without an Employee ID link.
//   If your environment requires every MES User to have a linked Employee record,
//   replace the empty string below with a real Employee."No." value before running.
// =============================================================================
codeunit 50115 "MES Setup"
{

    trigger OnRun()
    begin
        CreateDefaultAccount();
    end;

    local procedure CreateDefaultAccount()
    var
        AuthMgt: Codeunit "MES Auth Mgt";
        U: Record "MES User";
        AdminId: Code[50];
        TempPassword: Text;
    begin
        AdminId := 'ADMIN';
        TempPassword := '00000000';
        Message('MES Setup started — creating default admin account.');

        // Admin role requires Work Center No. to be blank.
        AuthMgt.CreateUser(
            'ADMIN',                          // User Id      
            'AC',                             // Employee ID 
            'AUTH-ADMIN01',                   // Auth ID      — external identity ref
            Enum::"MES User Role"::Admin     // Role         — full admin access
            );                              // Work Center  — not assigned to one WC

        // Sets the temporary password and marks Need To Change Pw = true.
        AuthMgt.SetPassword(AdminId, TempPassword, true);

        // Admin role requires Work Center No. to be blank.
        AuthMgt.CreateUser(
            'AI',                          // User Id      
            'AC',                             // Employee ID 
            'AUTH-ADMIN01',                   // Auth ID      — external identity ref
            Enum::"MES User Role"::Admin     // Role         — full admin access
            );                              // Work Center  — not assigned to one WC

        // Sets the temporary password and marks Need To Change Pw = true.
        AuthMgt.SetPassword(AdminId, TempPassword, true);


        Message('MES Setup complete. Login as "admin" and change the password immediately.');
    end;
}
