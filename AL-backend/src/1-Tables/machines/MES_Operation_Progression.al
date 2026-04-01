table 50109 "MES Operation Progression"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation Progression';

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

        field(3; "Cycle Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(4; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(5; "Total Produced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(6; "Operator Id"; Code[50])
        {
            TableRelation = "MES User Execution Interaction"."User Id";
        }

        field(7; "Declared At"; DateTime)
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
