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
        field(3; "employee ID"; Code[50])
        {
            Caption = 'employee ID';
            TableRelation = Employee."No.";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Auth ID"; Text[100])
        {
            Caption = 'Auth ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Role"; Enum "MES User Role")
        {
            Caption = 'Role';
            DataClassification = CustomerContent;
        }
        field(6; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation="Work Center"."No.";
            DataClassification = CustomerContent;
        }
        field(7; "Is Active"; Boolean)
        {
            Caption = 'Is Active'; // need to change technical term "an account is no longer active means he can not log in anymore" 
            DataClassification = SystemMetadata;
        }
        field(8; "Need To Change Pw"; Boolean)
        {
            Caption = 'Need To Change Password';
            DataClassification = SystemMetadata;
        }
        field(9; "Password Salt"; Text[50])
        {
            Caption = 'Password Salt';
            DataClassification = CustomerContent;
        }
        field(10; "Hashed Password"; Text[128])
        {
            Caption = 'Password Hash';
            DataClassification = CustomerContent;
        }
        field(11; "Password Iterations"; Integer)
        {
            Caption = 'Password Iterations'; // make it something small like 10 or 5
            DataClassification = SystemMetadata;
        }
        field(12; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "User Id")
        {
            Clustered = true; // need to know why
        }
        key(UserRole; "Role") { }
    }
}
