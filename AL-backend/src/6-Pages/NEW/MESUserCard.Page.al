// =============================================================================
// Page   : MES User Card
// ID     : 50142
// Type   : Card
// Purpose: Read-only detail view for a single MES User record.
//          Opened from the MES User List (CardPageId = "MES User Card") when
//          a user drills down on a row.
//
// READ-ONLY DESIGN
//   Editable = false at the page level prevents any field from being modified
//   directly in the BC client.  All user management (create, password reset,
//   activate/deactivate) is done through the MES Unbound Actions API
//   (MESUnboundActions.al) to ensure business rules and token revocation
//   are always enforced.
//
// LAYOUT
//   General group — identity and assignment fields:
//     User Id, Employee ID, Auth ID, Role, Work Center No.
//
//   Status group — operational state fields:
//     Is Active, Need To Change Password, Created At
//   These are separated into their own group so administrators can quickly
//   assess the account's current state without scrolling past identity fields.
// =============================================================================
page 50142 "MES User Card"
{
    PageType        = Card;
    ApplicationArea = All;
    UsageCategory   = Administration;
    Caption         = 'MES User';
    SourceTable     = "MES User";
    Editable        = false;  // all modifications go through the API

    layout
    {
        area(Content)
        {
            // -----------------------------------------------------------------
            // Group: General
            // Identity and assignment fields for this MES account.
            // -----------------------------------------------------------------
            group(General)
            {
                Caption = 'General';

                // The MES login username (primary key).
                field("User Id"; Rec."User Id")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The MES login username.  This is what the user types at the MES login screen.';
                }

                // The linked BC Employee record number, if any.
                field("employee ID"; Rec."employee ID")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The Business Central Employee No. linked to this MES account.  Blank if no HR record is associated.';
                }

                // External identity reference (e.g. AD UPN or OAuth subject).
                field("Auth ID"; Rec."Auth ID")
                {
                    ApplicationArea = All;
                    ToolTip         = 'External identity reference such as an Active Directory UPN.  Returned as the "name" field in API responses.';
                }

                // Access level — Operator, Supervisor, or Admin.
                field(Role; Rec.Role)
                {
                    ApplicationArea = All;
                    ToolTip         = 'The role that controls what this user can do in the MES application.';
                }

                // The production work center this user is assigned to.
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = All;
                    ToolTip         = 'The production work center assigned to this user.  The MES frontend scopes its UI to this work center on login.';
                }
            }

            // -----------------------------------------------------------------
            // Group: Status
            // Operational state of this account.
            // -----------------------------------------------------------------
            group(Status)
            {
                Caption = 'Status';

                // Whether this account can currently authenticate.
                // false = locked; use AdminSetActive API to change.
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                    ToolTip         = 'When false, the account is locked and the user cannot log in.  All active tokens are revoked when an account is deactivated.';
                }

                // Whether the user must change their password on next login.
                // true = a temporary password has been set; user must call ChangePassword.
                field("Need To Change Pw"; Rec."Need To Change Pw")
                {
                    ApplicationArea = All;
                    Caption         = 'Must Change Password';
                    ToolTip         = 'When true, the user must change their password before using the MES app.  Set automatically after AdminSetPassword.';
                }

                // Immutable creation timestamp.
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip         = 'UTC timestamp when this account was created.  Never modified after initial creation.';
                }
            }
        }
    }
}
