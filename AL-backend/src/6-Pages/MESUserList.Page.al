page 50141 "MES User List"
{
    PageType        = List;
    ApplicationArea = All;
    UsageCategory   = Administration;
    Caption         = 'MES Users';
    SourceTable     = "MES User";
    CardPageId      = "MES User Card";  
    Editable        = true;           

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

                // ✅ NEW FIELD (MULTI WORK CENTERS)
                field("Work Centers"; GetWorkCentersText())
                {
                    ApplicationArea = All;
                    Caption = 'Work Centers';
                }

                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                }

                field("Need To Change Pw"; Rec."Need To Change Pw")
                {
                    ApplicationArea = All;
                    Caption = 'Must Change Password';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    // ✅ FUNCTION
    local procedure GetWorkCentersText(): Text
    var
        UserWC: Record "MES User Work Center";
        WC: Record "Work Center";
        Result: Text;
    begin
        UserWC.SetRange("User Id", Rec."User Id");

        if UserWC.FindSet() then
            repeat
                if WC.Get(UserWC."Work Center No.") then begin
                    if Result <> '' then
                        Result += ', ';
                    Result += WC.Name;
                end;
            until UserWC.Next() = 0;

        exit(Result);
    end;
}