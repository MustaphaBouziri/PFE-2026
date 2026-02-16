page 50104 MyPage
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

actions
    {
        area(Processing)
        {
            action(Addition)
            {
                ApplicationArea = All;
                Caption = 'Add Numbers';
                trigger OnAction()
                begin
                    MyCode.Run();
                end;
            }
        }
    }
var
        MyCode: Codeunit MyCodeunit;
}