table 50108 "MES Operation Status"
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
            TableRelation = "MES Operation Execution"."Execution Id";
        }

        field(3; "Operation Status"; Enum "MES Operation Status")
        {
            Caption = 'MES Operation Status';
        }

        field(4; "Operator Id"; Code[50])
        {
            TableRelation = "MES User"."User Id";
        }

        field(5; "Last Updated At"; DateTime)
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
        key(ExecutionTimeline; "Execution Id", "Last Updated At") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "Id" := CopyStr(GuidTxt, 2, 36);
        end;
        "Last Updated At" := CurrentDateTime();
    end;
}