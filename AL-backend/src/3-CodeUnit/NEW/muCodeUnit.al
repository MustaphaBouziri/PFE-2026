codeunit 50103 MyCodeunit
{
    trigger OnRun()
    var
        num1: Integer;
        num2: Integer;
    begin
        num1 := 12;
        num2 := 10;
        add(num1, num2);
    end;
procedure add(num1: Integer; num2: Integer)
    var
        tot: Integer;
    begin
        tot := num1 + num2;
        Message('Sum of the two numbers is %1', tot);
    end;
}