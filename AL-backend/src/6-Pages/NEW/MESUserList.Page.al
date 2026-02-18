page 50141 "MES User List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MES Users';
    SourceTable = "MES User";
    CardPageId = "MES User Card";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Users)
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
