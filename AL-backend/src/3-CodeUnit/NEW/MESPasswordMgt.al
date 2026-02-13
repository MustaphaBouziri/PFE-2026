codeunit 50110 "MES Password Mgt"
{
    // FIXED VERSION - Uses proper cryptographic hashing

    [NonDebuggable]
    procedure MakeSalt(): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
    begin
        // Generate cryptographically secure random salt
        exit(CryptographyMgt.GenerateHash(Format(CreateGuid()) + Format(CurrentDateTime()), 2)); // SHA256
    end;

    [NonDebuggable]
    procedure HashPassword(Password: Text; Salt: Text; Iterations: Integer): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        i: Integer;
        CurrentHash: Text;
        CombinedText: Text;
    begin
        // Enforce minimum iterations for security
        if Iterations < 10000 then
            Iterations := 10000;

        // Initial hash of password + salt
        CombinedText := Password + Salt;
        CurrentHash := CryptographyMgt.GenerateHash(CombinedText, 2); // SHA256

        // Perform PBKDF2-like iterations
        for i := 2 to Iterations do begin
            CombinedText := CurrentHash + Salt;
            CurrentHash := CryptographyMgt.GenerateHash(CombinedText, 2);
        end;

        exit(CurrentHash);
    end;

    [NonDebuggable]
    procedure VerifyPassword(Password: Text; StoredHash: Text; Salt: Text; Iterations: Integer): Boolean
    var
        ComputedHash: Text;
    begin
        ComputedHash := HashPassword(Password, Salt, Iterations);
        exit(ComputedHash = StoredHash);
    end;
}
