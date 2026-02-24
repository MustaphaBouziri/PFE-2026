// =============================================================================
// Page   : MES Employee API
// ID     : 50100
// Domain : Admin / 4-API
// Purpose: Read-only API — exposes BC Employee table for the MES admin panel.
//          Used to populate the "Employee ID" dropdown when creating MES users.
//          Returns only fields needed for the MES UI — no payroll/HR data exposed.
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/employees
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/employees('<No.>')
// =============================================================================
page 50100 "MES Employee API"
{
    PageType      = API;
    APIPublisher  = 'yourcompany';
    APIGroup      = 'v1';
    APIVersion    = 'v1.0';
    EntityName    = 'employee';
    EntitySetName = 'employees';
    SourceTable   = Employee;
    DelayedInsert = true;
    Editable      = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id;         Rec."No.")          { Caption = 'Id';          }
                field(firstName;  Rec."First Name")   { Caption = 'First Name';  }
                field(middleName; Rec."Middle Name")  { Caption = 'Middle Name'; }
                field(lastName;   Rec."Last Name")    { Caption = 'Last Name';   }
                field(email;      Rec."E-Mail")       { Caption = 'Email';       }
                field(image;      Rec.Image)          { Caption = 'Image';       }
            }
        }
    }
}


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


// =============================================================================
// Page   : MES User Create API  (Write-enabled)
// ID     : 50103
// Domain : Admin / 4-API
// Purpose: Write-enabled API for creating new MES User records via HTTP POST.
//          Separated from the read-only page (50101) so read and write
//          permissions can be assigned to service accounts independently.
//
// ENDPOINT
//   POST  .../api/yourcompany/v1/v1.0/companies(<id>)/createMesUsers
//   GET   .../api/yourcompany/v1/v1.0/companies(<id>)/createMesUsers
//
// POST EXAMPLE
//   { "userId":"NEWOP", "employeeId":"E-0042", "role":"Operator", "workCenterNo":"WC-01" }
//
// NOTE: Password fields are intentionally omitted.  After POST, call
//       AdminSetPassword (MES Unbound Actions) to set a temporary password.
//
// DelayedInsert = true: all POST body fields are accumulated in memory before
// Insert() is called once — required for correct API POST behaviour.
// =============================================================================
page 50103 "MES User Create API"
{
    PageType      = API;
    APIPublisher  = 'yourcompany';
    APIGroup      = 'v1';
    APIVersion    = 'v1.0';
    EntityName    = 'mesUserCreate';
    EntitySetName = 'createMesUsers';
    SourceTable   = "MES User";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // Writable MES User fields
                field(userId;         Rec."User Id")           { }
                field(employeeId;     Rec."employee ID")       { }
                field(authId;         Rec."Auth ID")           { }
                field(role;           Rec.Role)                { }
                field(workCenterNo;   Rec."Work Center No.")   { }
                field(isActive;       Rec."Is Active")         { }
                field(needToChangePw; Rec."Need To Change Pw") { }
                field(createdAt;      Rec."Created At")        { }

                // Read-only joined fields — populated on GET, ignored on POST
                field(workCenterName; WorkCenterRec.Name)       { Editable = false; }
                field(firstName;      EmployeeRec."First Name") { Editable = false; }
                field(lastName;       EmployeeRec."Last Name")  { Editable = false; }
                field(email;          EmployeeRec."E-Mail")     { Editable = false; }
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
            if not EmployeeRec.Get(Rec."employee ID") then
                Clear(EmployeeRec);
        if Rec."Work Center No." <> '' then
            if not WorkCenterRec.Get(Rec."Work Center No.") then
                Clear(WorkCenterRec);
    end;
}


// =============================================================================
// Page   : MES Work Center API
// ID     : 50102
// Domain : Admin / 4-API
// Purpose: Read-only API — exposes BC Work Center table for the MES admin panel.
//          Used to populate the "Work Center No." dropdown when creating or
//          editing a MES User, and to resolve a work center code to its display
//          name for the operator's home screen.
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/workCenters
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/workCenters('<No.>')
// =============================================================================
page 50102 "MES Work Center API"
{
    PageType      = API;
    APIPublisher  = 'yourcompany';
    APIGroup      = 'v1';
    APIVersion    = 'v1.0';
    EntityName    = 'workCenter';
    EntitySetName = 'workCenters';
    SourceTable   = "Work Center";
    DelayedInsert = true;
    Editable      = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id;             Rec."No.")  { Caption = 'Work Center Id';   }
                field(workCenterName; Rec.Name)   { Caption = 'Work Center Name'; }
            }
        }
    }
}
