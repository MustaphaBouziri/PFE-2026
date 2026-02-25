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
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'workCenter';
    EntitySetName = 'workCenters';
    SourceTable = "Work Center";
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."No.") { Caption = 'Work Center Id'; }
                field(workCenterName; Rec.Name) { Caption = 'Work Center Name'; }
            }
        }
    }
}
