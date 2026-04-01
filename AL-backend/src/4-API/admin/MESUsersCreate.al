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
                //field(workCenterNo;   Rec."Work Center No.")   { }
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
       /* if Rec."Work Center No." <> '' then
            if not WorkCenterRec.Get(Rec."Work Center No.") then
                Clear(WorkCenterRec);*/
    end;
}
