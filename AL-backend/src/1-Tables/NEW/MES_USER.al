table 50101 "MES User"
{
    DataClassification = CustomerContent;
    Caption = 'MES User';

    fields
    {
        field(1; "User Id"; Code[50]) { }
        field(3; "employee ID"; Code[50]) { TableRelation = Employee."No."; }
        field(4; "Auth ID"; Text[100]) { }
        field(5; "Role"; Enum "MES User Role") { }
        field(6; "Work Center No."; Code[20]) { TableRelation = "Work Center"."No."; }
        field(7; "Is Active"; Boolean) { }
        field(8; "Need To Change Pw"; Boolean) { }
        field(9; "Password Salt"; Text[50]) { }
        field(10; "Hashed Password"; Text[128]) { }
        field(11; "Password Iterations"; Integer) { }
        field(12; "Created At"; DateTime) { }
    }

    keys
    {
        key(PK; "User Id") { Clustered = true; }
        key(UserRole; "Role") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin

        if "User Id" = '' then
            "User Id" := Format(CreateGuid());


        GuidTxt := Format(CreateGuid());
        "Auth ID" := 'AUTH-' + CopyStr(GuidTxt, 1, 8);



        "Is Active" := true;
        "Need To Change Pw" := true;
        "Created At" := CurrentDateTime();


        "Password Salt" := '';
        "Hashed Password" := '';
        "Password Iterations" := 0;
    end;
}