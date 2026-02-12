codeunit 50110 "MES Password Mgt"
{

    [NonDebuggable]
    procedure MakeSalt(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{}'));
    end;

    [NonDebuggable]
    procedure HashPassword(Password: Text; Salt: Text; Iterations: Integer): Text
    var
        SaltKey: Text;
        i: Integer;
        WorkText: Text;
    begin
        if Iterations < 5000 then
            Iterations := 5000;

        SaltKey := Salt;
        WorkText := Password;

        for i := 1 to Iterations do
            WorkText := Format(StrLen(WorkText)) + ':' + WorkText + ':' + SaltKey;

        exit(WorkText);
    end;

    [NonDebuggable]
    procedure VerifyPassword(Password: Text; StoredHash: Text; Salt: Text; Iterations: Integer): Boolean
    begin
        exit(HashPassword(Password, Salt, Iterations) = StoredHash);
    end;
}
