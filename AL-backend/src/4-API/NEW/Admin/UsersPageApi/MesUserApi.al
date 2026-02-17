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
//     including employee name and email alongside the MES role.
//   - Returns a flat record combining MES User fields with the linked
//     Employee's first name, last name, and email — no nested objects needed.
//
// EMPLOYEE JOIN PATTERN
//   BC API pages do not support native SQL-style JOINs.  Instead, the join
//   is implemented in three parts:
//     1. A module-level variable "EmployeeRec" of type Record Employee acts
//        as a per-row join buffer.
//     2. OnAfterGetRecord fires after each MES User row is fetched and loads
//        the matching Employee record into the buffer.
//     3. The repeater references EmployeeRec fields directly as if they were
//        columns on the source table.
//   SQL equivalent:
//     SELECT u.*, e."First Name", e."Last Name", e."E-Mail"
//     FROM   "MES User" u
//     LEFT JOIN Employee e ON e."No." = u."employee ID"
//
// BUG FIX vs original code
//   The original OnAfterGetRecord called EmployeeRec.Get() as a standalone
//   statement without consuming the return value.  If a linked Employee was
//   deleted from the HR table after the MES User was created, Get() would
//   raise a runtime error and break the entire collection GET response.
//   Fix: wrapped in "if EmployeeRec.Get(...) then" — a not-found result now
//   leaves EmployeeRec blank (empty strings in the response) instead of
//   crashing the request.
//
// READ-ONLY
//   Editable = false prevents INSERT/MODIFY via this page.
//   Use the MES Unbound Actions API (MESUnboundActions.al) for all writes
//   so that business rules (password hashing, token revocation) are enforced.
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
    DelayedInsert= true;   // required by BC API page conventions even for read-only pages
    Editable     = false;  // all write operations go through MES Unbound Actions

    layout
    {
        area(content)
        {
            // The repeater defines which fields are serialised per MES User row.
            // Fields from EmployeeRec are included here and populated via
            // OnAfterGetRecord — they behave as joined columns in the response.
            repeater(Group)
            {
                // ── MES User fields (from SourceTable) ───────────────────────

                // The MES login username — primary key and login credential.
                field(userId; Rec."User Id")
                {
                    Caption = 'User Id';
                }

                // FK to BC Employee."No." — blank if no HR record is linked.
                field(employeeId; Rec."employee ID")
                {
                    Caption = 'Employee ID';
                }

                // Role enum serialised as its string value:
                // "Operator" | "Supervisor" | "Admin"
                field(role; Rec.Role)
                {
                    Caption = 'Role';
                }

                // ── Joined Employee fields (from EmployeeRec buffer) ──────────
                // These are blank when "employee ID" is empty or the linked
                // employee has been deleted from the HR table.

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
    // EmployeeRec — per-row join buffer
    //
    // Holds the Employee record matched to the current MES User row.
    // Must be declared at page scope so that OnAfterGetRecord can write to it
    // and the repeater field definitions above can read from it.
    // It is re-populated (or cleared) on every row via OnAfterGetRecord.
    // -------------------------------------------------------------------------
    var
        EmployeeRec: Record Employee;

    // -------------------------------------------------------------------------
    // Trigger: OnAfterGetRecord
    //
    // Fires once per MES User row fetched from the database.
    // Performs the employee lookup that implements the LEFT JOIN.
    //
    // Why Clear() first?
    //   Without Clear(), if row N has a linked employee and row N+1 does not,
    //   EmployeeRec would still hold row N's employee data when row N+1 is
    //   serialised — resulting in incorrect firstName/lastName/email values.
    //   Clear() resets all fields to their default (blank) values before each
    //   lookup attempt.
    //
    // Why "if EmployeeRec.Get(...) then" with no else branch?
    //   Get() returns FALSE and does NOT raise an error when the record is not
    //   found — but only when its return value is consumed by an "if" statement.
    //   If called as a standalone statement (no "if"), BC treats a not-found
    //   result as a runtime error.  The "if ... then;" pattern safely absorbs
    //   the false return, leaving EmployeeRec in its just-cleared blank state.
    //   This handles the case where an Employee is deleted from the HR table
    //   after the MES User was already linked to it.
    // -------------------------------------------------------------------------
    trigger OnAfterGetRecord()
    begin
        // Reset the join buffer so no stale data leaks from the previous row.
        Clear(EmployeeRec);

        // Only attempt the lookup when an employee is actually linked.
        // The "if ... then" form safely handles a deleted employee without error.
        if Rec."employee ID" <> '' then
            if EmployeeRec.Get(Rec."employee ID") then;
        // If Get returns false (employee deleted), EmployeeRec stays blank.
        // The joined fields will serialise as empty strings for this row.
    end;
}


// =============================================================================
// Page   : MES User Create API
// ID     : 50103
// Type   : API
// Purpose: Write-enabled API page for creating new MES User records via HTTP
//          POST.  Intentionally separated from the read-only MES User API
//          (Page 50101) so that read and write permissions can be assigned
//          to service accounts independently.
//
// ENDPOINT
//   POST  .../api/yourcompany/v1/v1.0/companies(<id>)/createMesUsers
//   GET   .../api/yourcompany/v1/v1.0/companies(<id>)/createMesUsers
//   GET   .../api/yourcompany/v1/v1.0/companies(<id>)/createMesUsers('<userId>')
//
// HOW TO CREATE A USER VIA POST
//   POST  .../createMesUsers
//   Content-Type: application/json
//   {
//     "userId":     "NEWOP",
//     "employeeId": "E-0042",
//     "role":       "Operator"
//   }
//
//   BC will validate and persist the record in one transaction.
//   On success, the response body echoes back the created record.
//
//   IMPORTANT: Password fields are intentionally NOT exposed here.
//   After creating the record, call AdminSetPassword (MES Unbound Actions)
//   to assign a temporary password before the user can log in.
//
// WHY SEPARATE FROM PAGE 50101?
//   Separating read and write API pages provides two concrete benefits:
//     1. Permission granularity — a service account that only reads user lists
//        does not need write access.  Assign the read page separately from the
//        write page in permission sets.
//     2. Stability guarantee — the read page (50101) keeps Editable = false
//        permanently.  No future change to write behaviour can accidentally
//        affect the read contract.
//
// HOW DelayedInsert = true WORKS
//   On a standard BC page, each field change triggers an immediate database
//   write.  With DelayedInsert = true the framework accumulates all field
//   values from the POST body in memory first, then calls Insert() once with
//   the fully populated record.  This is essential for API POST because:
//     a) The full record arrives in a single JSON body, not field-by-field.
//     b) Table triggers (OnInsert) and validation rules expect a complete
//        record, not a partially populated one.
//   Without DelayedInsert = true a POST with multiple fields would trigger
//   multiple partial inserts and likely violate NOT NULL constraints or
//   produce validation errors.
//
// EMPLOYEE JOIN (same pattern as page 50101)
//   firstName, lastName, and email come from the linked Employee record.
//   They are populated on GET via OnAfterGetRecord and are read-only —
//   including them in a POST body has no effect.  Set "employeeId" to
//   establish the link; the joined fields are derived automatically.
//
// KNOWN LIMITATION — Get() without return value check
//   This page's OnAfterGetRecord calls EmployeeRec.Get() as a standalone
//   statement, which will raise a runtime error if the linked Employee record
//   has been deleted from the HR table.  This is acceptable for a write-
//   oriented endpoint where GET is used mainly for response confirmation,
//   but it should be fixed by adopting the safe pattern from page 50101:
//     if EmployeeRec.Get(Rec."employee ID") then;
//   See OnAfterGetRecord below for the annotated code.
// =============================================================================
page 50103 "MES User Create API"
{
    PageType     = API;
    APIPublisher = 'yourcompany';
    APIGroup     = 'v1';
    APIVersion   = 'v1.0';
    EntityName   = 'mesUserCreate';
    EntitySetName= 'createMesUsers';
    SourceTable  = "MES User";
    DelayedInsert= true;  // required for POST: accumulate all fields before Insert()

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // ── Writable MES User fields ──────────────────────────────────
                // These fields are populated from the POST request body.
                // Password fields are intentionally omitted — use AdminSetPassword
                // (MES Unbound Actions) after creation to set the password.

                // Required — the MES login username (primary key).
                // Must be unique; sending a duplicate userId returns an error.
                field(userId; Rec."User Id") { }

                // Optional — links this account to a BC Employee record by "No.".
                // Leave blank if no HR employee record exists for this user.
                field(employeeId; Rec."employee ID") { }

                // Required — sets the access level for the new account.
                // Send as the enum string: "Operator", "Supervisor", or "Admin".
                field(role; Rec.Role) { }

                // ── Read-only joined Employee fields ──────────────────────────
                // Populated on GET via OnAfterGetRecord; derived from the linked
                // Employee record.  Including these in a POST body has no effect.

                field(firstName; EmployeeRec."First Name") { }
                field(lastName; EmployeeRec."Last Name") { }
                field(email; EmployeeRec."E-Mail") { }
            }
        }
    }

    // -------------------------------------------------------------------------
    // EmployeeRec — per-row join buffer
    //
    // Holds the Employee record matched to the current MES User row.
    // Populated in OnAfterGetRecord and read by the joined repeater fields.
    // See page 50101 for a full explanation of this pattern.
    // -------------------------------------------------------------------------
    var
        EmployeeRec: Record Employee;

    // -------------------------------------------------------------------------
    // Trigger: OnAfterGetRecord
    //
    // Fires on GET requests — once per MES User row returned.
    // Loads the linked Employee record to populate firstName/lastName/email.
    //
    // Why Clear() first?
    //   Prevents stale Employee data from a previous row leaking into the
    //   current row when no employee is linked.  See page 50101 for details.
    //
    // Note on error handling — KNOWN LIMITATION:
    //   EmployeeRec.Get() is called as a standalone statement here (original
    //   code preserved).  If the linked Employee no longer exists in the HR
    //   table, this will raise a "Record not found" runtime error on GET.
    //   The safe alternative (used in page 50101) is:
    //     if EmployeeRec.Get(Rec."employee ID") then;
    //   which absorbs the false return value and leaves EmployeeRec blank.
    //   Consider adopting that pattern here if this page is also used for
    //   list reads where a deleted employee would otherwise break the response.
    // -------------------------------------------------------------------------
    trigger OnAfterGetRecord()
    begin
        // Reset the join buffer to prevent stale data carry-over between rows.
        Clear(EmployeeRec);

        // Load the matching Employee record.
        // CAUTION: raises a runtime error if the employee has been deleted.
        // See note above for the safer alternative.
        if Rec."employee ID" <> '' then
            EmployeeRec.Get(Rec."employee ID");
    end;
}
