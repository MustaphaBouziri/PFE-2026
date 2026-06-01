page 50142 "MES User Card"
{
    PageType        = Card;
    ApplicationArea = All;
    UsageCategory   = Administration;
    Caption         = 'MES User';
    SourceTable     = "MES User";
    Editable        = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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

                // ✅ NEW FIELD
                field("Work Centers"; GetWorkCentersText())
                {
                    ApplicationArea = All;
                    Caption = 'Work Centers';
                }
            }

            group(Status)
            {
                Caption = 'Status';

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

    // ✅ SAME FUNCTION
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