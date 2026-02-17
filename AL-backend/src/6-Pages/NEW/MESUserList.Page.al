// =============================================================================
// Page   : MES User List
// ID     : 50141
// Type   : List
// Purpose: Read-only list view of all MES User accounts.
//          Provides administrators with a quick overview of all registered
//          MES accounts, their roles, work center assignments, and current status.
//
// NAVIGATION
//   Drilling down on any row opens MES User Card (Page 50142) for the full
//   detail view.  CardPageId = "MES User Card" wires this automatically.
//
// READ-ONLY DESIGN
//   Editable = false at the page level.  All account management is performed
//   through the MES Unbound Actions API — this ensures business rules such
//   as token revocation and password hashing are always applied, and that
//   no field can be set to an inconsistent state via direct UI editing.
//
// HOW TO ACCESS
//   - Search "MES Users" in the BC search bar.
//   - Click the "Open MES User List" action on the MES API Debug page.
//
// COLUMNS
//   The list displays the most operationally relevant fields at a glance:
//   User Id, Employee ID, Auth ID, Role, Work Center — identity and assignment.
//   Is Active, Need To Change Pw, Created At — current state and history.
// =============================================================================
page 50141 "MES User List"
{
    PageType        = List;
    ApplicationArea = All;
    UsageCategory   = Administration;
    Caption         = 'MES Users';
    SourceTable     = "MES User";
    CardPageId      = "MES User Card";  // drill-down opens the detail card
    Editable        = false;            // all modifications go through the API

    layout
    {
        area(Content)
        {
            repeater(Users)
            {
                // The MES login username.
                field("User Id"; Rec."User Id")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The MES login username (primary key).';
                }

                // The linked BC Employee record number.
                field("employee ID"; Rec."employee ID")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The BC Employee No. linked to this account.  Blank if no HR record is associated.';
                }

                // External identity reference.
                field("Auth ID"; Rec."Auth ID")
                {
                    ApplicationArea = All;
                    ToolTip         = 'External identity reference (e.g. Active Directory UPN).  Returned as "name" in API responses.';
                }

                // Role — Operator, Supervisor, or Admin.
                field(Role; Rec.Role)
                {
                    ApplicationArea = All;
                    ToolTip         = 'The access role for this account.';
                }

                // Production work center assignment.
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The work center this user is assigned to.';
                }

                // Account lock status — false means the user cannot log in.
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip         = 'When false, the account is locked.  Use the AdminSetActive API endpoint to change this.';
                }

                // Forced-change flag — indicates a temporary password is in place.
                field("Need To Change Pw"; Rec."Need To Change Pw")
                {
                    ApplicationArea = All;
                    Caption         = 'Must Change Password';
                    ToolTip         = 'When true, the user must change their password on next login.';
                }

                // Immutable creation timestamp.
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip         = 'UTC timestamp when the account was first created.';
                }
            }
        }
    }
}
