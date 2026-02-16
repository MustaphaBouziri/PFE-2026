page 50142 "MES User Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MES User';
    SourceTable = "MES User";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("User Id"; Rec."User Id")
                {
                    ApplicationArea = All;
                }
                field("employee ID"; Rec."employee ID")
                {
                    ApplicationArea = All;
                }
                field("Auth ID"; Rec."Auth ID")
                {
                    ApplicationArea = All;
                }
                field(Role; Rec.Role)
                {
                    ApplicationArea = All;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = All;
                }
            }

            group(Status)
            {
                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                }
                field("Need To Change Pw"; Rec."Need To Change Pw")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
