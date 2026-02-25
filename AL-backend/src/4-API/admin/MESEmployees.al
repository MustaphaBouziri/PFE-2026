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
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'employee';
    EntitySetName = 'employees';
    SourceTable = Employee;
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."No.") { Caption = 'Id'; }
                field(firstName; Rec."First Name") { Caption = 'First Name'; }
                field(middleName; Rec."Middle Name") { Caption = 'Middle Name'; }
                field(lastName; Rec."Last Name") { Caption = 'Last Name'; }
                field(email; Rec."E-Mail") { Caption = 'Email'; }
                field(image; Rec.Image) { Caption = 'Image'; }
            }
        }
    }
}
