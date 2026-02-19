// =============================================================================
// Page   : MES Employee API
// ID     : 50100
// Type   : API
// Purpose: Read-only API page that exposes the standard Business Central
//          Employee table as a JSON REST endpoint.
//
// ENDPOINT
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/employees
//   GET  .../api/yourcompany/v1/v1.0/companies(<id>)/employees('<No.>')
//
// USE CASES
//   - The MES frontend admin panel calls this to populate the "Employee ID"
//     dropdown when creating a new MES User account.
//   - Returns only the fields needed for the MES UI: Id, First Name, Last Name,
//     Email.  No payroll or HR-sensitive data is exposed.
//
// API METADATA
//   Publisher : yourcompany   — replace with your registered BC publisher name
//   Group     : v1            — logical API group for all MES admin endpoints
//   Version   : v1.0          — increment when breaking changes are introduced
//   EntityName: employee      — singular; used in single-record URLs:
//                               .../employees('E-0001')
//   EntitySetName: employees  — plural; used in collection URLs:
//                               .../employees
//
// REPEATER CONTROL
//   The "repeater" group marks the fields that form one entity record.
//   For a collection GET, the repeater body is serialised once per row.
//   For a single-record GET (by key), the repeater body is serialised once.
//
// FIELD → JSON KEY MAPPING
//   field(id;        Rec."No.")         → "id"
//   field(firstName; Rec."First Name")  → "firstName"
//   field(lastName;  Rec."Last Name")   → "lastName"
//   field(email;     Rec."E-Mail")      → "email"
//   The AL identifier before the semicolon becomes the JSON key name.
//   Caption is only shown in BC UI column headers — it has no effect on the API.
//
// WRITE OPERATIONS
//   DelayedInsert = true is required on API pages to allow the framework to
//   validate the full record before inserting.  This page is read-only in
//   practice (no INSERT/MODIFY actions are defined), but DelayedInsert must
//   still be set to comply with BC API page conventions.
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
    Editable = false;  // read-only: MES does not create or modify HR employees

    layout
    {
        area(content)
        {
            // The repeater defines which fields are returned per employee row.
            // Fields listed here map directly to JSON keys in the response body.
            repeater(Group)
            {
                // Employee number — the primary identifier used as the foreign
                // key in MES User."employee ID".
                field(id; Rec."No.")
                {
                    Caption = 'Id';
                }

                // Display name fields — shown in the MES admin user-creation UI.
                field(firstName; Rec."First Name")
                {
                    Caption = 'First Name';
                }

                field("middleName"; Rec."Middle Name")
                {
                    Caption = 'middle Name';
                }

                field(lastName; Rec."Last Name")
                {
                    Caption = 'Last Name';
                }

                // Contact email — used for password reset notifications if
                // that feature is added in a future release.
                field(email; Rec."E-Mail")
                {
                    Caption = 'Email';
                }

                field(image; Rec.Image)
                {
                    Caption = 'Image';
                }
            }
        }
    }
}
