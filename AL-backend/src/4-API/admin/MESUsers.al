// =============================================================================
// Page   : MES User API  (Read-only)
// ID     : 50101
// Domain : Admin / 4-API
// Purpose: Read-only API — exposes MES User accounts with linked Employee and
//          Work Center data joined in via OnAfterGetRecord (LEFT JOIN pattern).
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/mesUsers
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/mesUsers('<userId>')
//
// EMPLOYEE / WORK CENTER JOIN PATTERN
//   BC API pages don't support SQL JOINs.  Implemented via buffer variables
//   at page scope that are populated in OnAfterGetRecord.
//   Clear() before each lookup prevents stale data from the previous row.
//   "if Get(...) then;" absorbs a not-found return without raising an error
//   (handles deleted employees/work centers gracefully).
//
// WRITE OPERATIONS
//   Use MES Unbound Actions API for all writes — business rules are enforced there.
// =============================================================================
page 50101 "MES User API"
{
    PageType      = API;
    APIPublisher  = 'yourcompany';
    APIGroup      = 'v1';
    APIVersion    = 'v1.0';
    EntityName    = 'mesUser';
    EntitySetName = 'mesUsers';
    SourceTable   = "MES User";
    DelayedInsert = true;
    Editable      = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // MES User fields
                field(userId;         Rec."User Id")           { Caption = 'User Id';     }
                field(employeeId;     Rec."employee ID")       { Caption = 'Employee ID'; }
                field(role;           Rec.Role)                { Caption = 'Role';        }
                field(authId;         Rec."Auth ID")           { }
                field(workCenterNo;   Rec."Work Center No.")   { }
                field(isActive;       Rec."Is Active")         { }
                field(needToChangePw; Rec."Need To Change Pw") { }
                field(createdAt;      Rec."Created At")        { }

                // Joined Employee fields — blank when employee deleted or unlinked
                field(firstName;     EmployeeRec."First Name") { Caption = 'First Name'; }
                field(lastName;      EmployeeRec."Last Name")  { Caption = 'Last Name';  }
                field(email;         EmployeeRec."E-Mail")     { Caption = 'Email';      }

                // Joined Work Center name
                field(workCenterName; WorkCenterRec.Name) { }
            }
        }
    }

    var
        EmployeeRec:   Record Employee;
        WorkCenterRec: Record "Work Center";

    trigger OnAfterGetRecord()
    begin
        Clear(EmployeeRec);
        Clear(WorkCenterRec);
        if Rec."employee ID" <> '' then
            if EmployeeRec.Get(Rec."employee ID") then;
        if Rec."Work Center No." <> '' then
            if WorkCenterRec.Get(Rec."Work Center No.") then;
    end;
}
