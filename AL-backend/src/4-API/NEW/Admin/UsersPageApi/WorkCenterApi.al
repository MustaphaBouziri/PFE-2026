// =============================================================================
// Page   : MES Department API
// ID     : 50102
// Type   : API
// Purpose: Read-only API page that exposes the Business Central Work Center
//          table as a JSON REST endpoint for the MES admin panel.
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/workCenters
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/workCenters('<No.>')
//
// USE CASES
//   - The MES admin panel calls this to populate the "Work Center No." dropdown
//     when creating or editing a MES User account.
//   - The MES frontend uses it to resolve a work center number to its display
//     name for the operator's home screen.
//
// WHY "Work Center" and NOT "Department"?
//   Work Centers (table "Work Center") represent production stations in BC
//   Manufacturing — they map directly to physical areas on a factory floor
//   (e.g. Assembly Line A, Welding Station 2).  These are the correct
//   entities for a Manufacturing Execution System.  The entity name is
//   "workCenter" (camelCase) to match BC naming conventions in custom APIs.
//
// API METADATA
//   Publisher   : yourcompany
//   Group       : v1
//   Version     : v1.0
//   EntityName  : workCenter    — singular form for single-record URL
//   EntitySetName: workCenters  — plural form for collection URL
//   SourceTable : Work Center   — standard BC manufacturing table
// =============================================================================
page 50102 "MES Department API"
{
    PageType     = API;
    APIPublisher = 'yourcompany';
    APIGroup     = 'v1';
    APIVersion   = 'v1.0';
    EntityName   = 'workCenter';
    EntitySetName= 'workCenters';
    SourceTable  = "Work Center";
    DelayedInsert= true;
    Editable     = false;  // read-only: work centers are managed in BC Manufacturing

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // Work center code — the primary identifier stored in
                // MES User."Work Center No." as a Code[20] foreign key.
                field(id; Rec."No.")
                {
                    Caption = 'Work Center Id';
                }

                // Human-readable work center name displayed in the MES UI
                // dropdowns and on the operator's home screen.
                field(departmentName; Rec.Name)
                {
                    Caption = 'Work Center Name';
                }
            }
        }
    }
}
