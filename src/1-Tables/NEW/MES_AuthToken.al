table 50106 "MES Auth Token"
{
    DataClassification = SystemMetadata;
    Caption = 'MES Auth Token';

    fields
    {
        field(1; "Token"; Guid)
        {
            Caption = 'Token';
            DataClassification = SystemMetadata;
        }
        field(2; "User Id"; Code[50])
        {
            Caption = 'User Id';
            TableRelation = "MES User"."User Id";
            DataClassification = SystemMetadata;
        }
        field(3; "Device Id"; Text[100])
        {
            Caption = 'Device Id';
            DataClassification = SystemMetadata;
        }
        field(4; "Issued At"; DateTime)
        {
            Caption = 'Issued At';
            DataClassification = SystemMetadata;
        }
        field(5; "Expires At"; DateTime)
        {
            Caption = 'Expires At';
            DataClassification = SystemMetadata;
        }
        field(6; "Last Seen At"; DateTime)
        {
            Caption = 'Last Seen At';
            DataClassification = SystemMetadata;
        }
        field(7; "Revoked"; Boolean)
        {
            Caption = 'Revoked';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Token")
        {
            Clustered = true;
        }
        key(UserTokens; "User Id") { }
    }
}
