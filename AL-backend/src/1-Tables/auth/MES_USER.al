// =============================================================================
// Table  : MES User
// Changes: Added field 12 "Badge Secret" (Text[64]).
//          A cryptographically random 64-char hex secret is generated
//          automatically on every OnInsert, regardless of the TwoFA Enabled
//          setting in MES Settings. This means 2FA can be turned on at any
//          time without needing to touch individual user records.
//          The secret is embedded in the QR code shown on the Add User page.
//          It is stored in plain text (not hashed) because it must be
//          compared directly to the value scanned from the badge.
// =============================================================================
table 50101 "MES User"
{
    DataClassification = CustomerContent;
    Caption = 'MES User';

    fields
    {
        field(1; "User Id"; Code[50])
        {
            Caption            = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(3; "employee ID"; Code[50])
        {
            Caption       = 'Employee ID';
            TableRelation = Employee."No.";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                MESUser: Record "MES User";
            begin
                if "Employee ID" = '' then
                    Error('Employee ID is required.');

                MESUser.SetRange("Employee ID", "Employee ID");
                MESUser.SetFilter("User Id", '<>%1', "User Id");
                if not MESUser.IsEmpty() then
                    Error('Employee ID %1 is already assigned to another MES User.', "Employee ID");
            end;
        }

        field(4; "Auth ID"; Text[100])
        {
            Caption            = 'Auth ID';
            DataClassification = EndUserIdentifiableInformation;
        }

        field(5; "Role"; Enum "MES User Role")
        {
            Caption            = 'Role';
            DataClassification = CustomerContent;
        }

        field(6; "Is Active"; Boolean)
        {
            Caption            = 'Is Active';
            DataClassification = SystemMetadata;
        }

        field(7; "Need To Change Pw"; Boolean)
        {
            Caption            = 'Need To Change Password';
            DataClassification = SystemMetadata;
        }

        field(8; "Password Salt"; Text[64])
        {
            Caption            = 'Password Salt';
            DataClassification = CustomerContent;
        }

        field(9; "Hashed Password"; Text[128])
        {
            Caption            = 'Password Hash';
            DataClassification = CustomerContent;
        }

        field(10; "Created At"; DateTime)
        {
            Caption            = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(11; "Last Password Changed At"; DateTime)
        {
            Caption            = 'Last Password Changed At';
            DataClassification = SystemMetadata;
        }

        // ── Badge QR secret ───────────────────────────────────────────────────
        // Generated once on insert; never changes unless explicitly regenerated
        // via the RegenerateBadgeSecret procedure in MESAuthMgt.
        // Stored plain text — compared directly to the value scanned from QR.
        field(12; "Badge Secret"; Text[64])
        {
            Caption            = 'Badge QR Secret';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "User Id")          { Clustered = true; }
        key(AuthId; "Auth ID")      { Unique = true; }
        key(EmployeeId; "Employee ID") { Unique = true; }
        key(UserRole; "Role")       { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "User Id" = '' then begin
            GuidTxt   := Format(CreateGuid());
            "User Id" := CopyStr(GuidTxt, 2, 36);
        end;

        if "Auth ID" = '' then
            "Auth ID" := GenerateUniqueAuthId();

        "Is Active"                := true;
        "Need To Change Pw"        := true;
        "Created At"               := CurrentDateTime();
        "Password Salt"            := '';
        "Hashed Password"          := '';
        "Last Password Changed At" := 0DT;

        // Always generate a badge secret, even if TwoFA is currently disabled.
        "Badge Secret" := GenerateBadgeSecret();
    end;

    local procedure GenerateUniqueAuthId(): Text[100]
    var
        MESUser:     Record "MES User";
        CandidateId: Text[100];
        GuidTxt:     Text[50];
    begin
        repeat
            GuidTxt     := Format(CreateGuid());
            CandidateId := 'AUTH-' + CopyStr(GuidTxt, 2, 8);
            MESUser.SetRange("Auth ID", CandidateId);
        until MESUser.IsEmpty();
        exit(CandidateId);
    end;

    /// <summary>
    /// Generates a 64-character hex secret by hashing two random GUIDs.
    /// Uses the same Cryptography Management codeunit (SHA-256) already
    /// referenced by MES Password Mgt, so no new dependencies.
    /// </summary>
    local procedure GenerateBadgeSecret(): Text[64]
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        Input:           Text;
    begin
        Input := Format(CreateGuid()) + Format(CreateGuid()) + Format(CurrentDateTime());
        exit(CopyStr(CryptographyMgt.GenerateHash(Input, 2), 1, 64));
    end;

    trigger OnModify()
    begin
        ValidateRequiredFields();

        if ("Hashed Password" <> xRec."Hashed Password") or
           ("Password Salt"   <> xRec."Password Salt")
        then begin
            if "Hashed Password" <> '' then
                "Last Password Changed At" := CurrentDateTime();
        end;
    end;

    local procedure ValidateRequiredFields()
    begin
        if "Employee ID" = '' then
            Error('Employee ID is required.');
    end;
}
