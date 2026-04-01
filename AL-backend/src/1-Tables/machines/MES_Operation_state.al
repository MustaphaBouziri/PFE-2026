table 50108 "MES Operation State"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation Status';

    fields
    {
        field(1; "Id"; Code[50])
        {
            DataClassification = SystemMetadata;
        }

        field(2; "Execution Id"; Code[50])
        {
            TableRelation = "MES User Execution Interaction"."Execution Id";
        }

        field(3; "Operation Status"; Enum "MES Operation Status")
        {
            Caption = 'MES Operation Status';
        }

        field(4; "Operator Id"; Code[50])
        {
            TableRelation = "MES User Execution Interaction"."User Id";
        }

        field(5; "Declared At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }
        key(ExecutionTimeline; "Execution Id", "Declared At") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "Id" := CopyStr(GuidTxt, 2, 36);
        end;
        "Declared At" := CurrentDateTime();
    end;
}