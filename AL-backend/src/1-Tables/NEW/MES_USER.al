table 50101 "MES User"
{
    DataClassification = CustomerContent;
    Caption = 'MES User';

    fields
    {
        field(1; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Role"; Enum "MES User Role")
        {
            Caption = 'Role';
            DataClassification = CustomerContent;
        }
        field(4; "Department Code"; Code[20])
        {
            Caption = 'Department Code';
            DataClassification = CustomerContent;
        }
        field(5; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
        }
        field(6; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
            DataClassification = SystemMetadata;
        }
        field(7; "Need To Change Pw"; Boolean)
        {
            Caption = 'Need To Change Password';
            DataClassification = SystemMetadata;
        }
        field(8; "Password Salt"; Text[50])
        {
            Caption = 'Password Salt';
            DataClassification = CustomerContent;
        }
        field(9; "Password Hash"; Text[128])
        {
            Caption = 'Password Hash';
            DataClassification = CustomerContent;
        }
        field(10; "Password Iterations"; Integer)
        {
            Caption = 'Password Iterations';
            DataClassification = SystemMetadata;
        }
        field(11; "Failed Login Count"; Integer)
        {
            Caption = 'Failed Login Count';
            DataClassification = SystemMetadata;
        }
        field(12; "Lockout Until"; DateTime)
        {
            Caption = 'Lockout Until';
            DataClassification = SystemMetadata;
        }
        field(13; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "User Id")
        {
            Clustered = true;
        }
        key(UserRole; "Role") { }
    }
}
