// =============================================================================
// Page   : MES User API
// ID     : 50101
// Type   : API
// Purpose: Read-only API page that exposes MES User accounts with their
//          linked Employee data joined in at read time.
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/mesUsers
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/mesUsers('<userId>')
//
// USE CASES
//   - The MES admin panel reads this to display the user management list,
//     including employee name and email alongside MES role and status.
//   - Returns a flat record combining MES User fields with the linked
//     Employee's first name, last name, and email — no nested objects needed.
//
// EMPLOYEE JOIN PATTERN
//   Business Central API pages do not support native SQL-style JOINs.
//   Instead, the join is implemented using:
//     1. A module-level variable "EmployeeRec" of type Record Employee.
//     2. The OnAfterGetRecord trigger, which fires after each MES User row
//        is fetched, to look up and load the matching Employee record.
//     3. Direct field references to EmployeeRec in the repeater layout.
//   This is equivalent to: SELECT u.*, e.FirstName, e.LastName, e.Email
//                           FROM MESUser u LEFT JOIN Employee e ON e.No = u.EmployeeID
//
// API METADATA
//   Publisher : yourcompany
//   Group     : v1
//   Version   : v1.0
//   EntityName: mesUser      — singular form for single-record URL
//   EntitySetName: mesUsers  — plural form for collection URL
// =============================================================================
page 50101 "MES User API"
{
    PageType     = API;
    APIPublisher = 'yourcompany';
    APIGroup     = 'v1';
    APIVersion   = 'v1.0';
    EntityName   = 'mesUser';
    EntitySetName= 'mesUsers';
    SourceTable  = "MES User";
    DelayedInsert= true;
    Editable     = false;  // read-only: user management is done via MES Unbound Actions

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // MES User core fields — from the MES User table (SourceTable).

                // The MES login username.
                field(userId; Rec."User Id")
                {
                    Caption = 'User Id';
                }

                // Foreign key to the BC Employee table.
                // Blank if no employee is linked.
                field(employeeId; Rec."employee ID")
                {
                    Caption = 'Employee ID';
                }

                // Role enum value — returned as its string representation
                // (e.g. "Operator", "Supervisor", "Admin").
                field(role; Rec.Role)
                {
                    Caption = 'Role';
                }

                // Joined Employee fields — sourced from EmployeeRec, which is
                // populated by OnAfterGetRecord for each row.
                // If no employee is linked, these will be blank (EmployeeRec is Clear()-ed).

                field(firstName; EmployeeRec."First Name")
                {
                    Caption = 'First Name';
                }

                field(lastName; EmployeeRec."Last Name")
                {
                    Caption = 'Last Name';
                }

                field(email; EmployeeRec."E-Mail")
                {
                    Caption = 'Email';
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Module-level variable: EmployeeRec
    //
    // Holds the Employee record matched to the current MES User row.
    // This is loaded in OnAfterGetRecord and read in the repeater field
    // definitions above.  It acts as a "current row join buffer".
    //
    // A plain Record variable (not temporary) is used so that EmployeeRec.Get()
    // reads live data from the database on each call.
    // -------------------------------------------------------------------------
    var
        EmployeeRec: Record Employee;

    // -------------------------------------------------------------------------
    // Trigger: OnAfterGetRecord
    //
    // Fires once for each MES User row that the framework fetches from the
    // database.  This is the correct place to load data from related tables
    // (i.e. to perform the employee join).
    //
    // Pattern used:
    //   1. Clear(EmployeeRec) — reset the buffer so that a previous row's
    //      data does not leak into a row with no linked employee.
    //   2. If Rec."employee ID" is not blank, call EmployeeRec.Get() to load
    //      the matching Employee record into the buffer.
    //   3. The repeater fields (firstName, lastName, email) then read from
    //      EmployeeRec, which either holds the correct values or is blank.
    //
    // SQL equivalent:
    //   LEFT JOIN Employee ON Employee."No." = MESUser."employee ID"
    // -------------------------------------------------------------------------
    trigger OnAfterGetRecord()
    begin
        // Reset the join buffer for every row to prevent stale data carry-over.
        Clear(EmployeeRec);

        // Only attempt the lookup if an employee is actually linked.
        // EmployeeRec.Get() would raise an error on a blank key without this guard.
        if Rec."employee ID" <> '' then
            EmployeeRec.Get(Rec."employee ID");
        // If Get() finds no match (employee was deleted), EmployeeRec stays Clear().
        // The repeater fields will then return blank strings for this row.
    end;
}
*/

page 50101 "MES User API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'mesUser';
    EntitySetName = 'mesUsers';
    SourceTable = "MES User";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userId; Rec."User Id")
                {
                    Caption = 'User Id';
                }

                field(employeeId; Rec."employee ID")
                {
                    Caption = 'Employee ID';
                }

                field(role; Rec.Role)
                {
                    Caption = 'Role';
                }

                field(firstName; EmployeeRec."First Name")
                {
                    Caption = 'First Name';
                }

                field(lastName; EmployeeRec."Last Name")
                {
                    Caption = 'Last Name';
                }

                field(email; EmployeeRec."E-Mail")
                {
                    Caption = 'Email';
                }
            }
        }
    }

    var
        EmployeeRec: Record Employee;

    trigger OnAfterGetRecord()
    begin
        Clear(EmployeeRec);
        if Rec."employee ID" <> '' then
            if EmployeeRec.Get(Rec."employee ID") then;
    end;
}



page 50103 "MES User Create API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'mesUserCreate';
    EntitySetName = 'createMesUsers';
    SourceTable = "MES User";
    DelayedInsert = true; // important for POST

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userId; Rec."User Id") { }
                field(employeeId; Rec."employee ID") { }
                field(role; Rec.Role) { }
                field(firstName; EmployeeRec."First Name") { }
                field(lastName; EmployeeRec."Last Name") { }
                field(email; EmployeeRec."E-Mail") { }
            }
        }
    }

    var
        EmployeeRec: Record Employee;

    trigger OnAfterGetRecord()
    begin
        Clear(EmployeeRec);
        if Rec."employee ID" <> '' then
            EmployeeRec.Get(Rec."employee ID");
    end;
}