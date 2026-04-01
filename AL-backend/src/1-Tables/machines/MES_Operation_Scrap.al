table 50112 "MES Operation Scrap"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation Scrap';

    fields
    {
        field(1; "Id"; Code[50])
        {
            DataClassification = SystemMetadata;
        }

        // which operation this scrap belongs to
        field(2; "Execution Id"; Code[50])
        {
            TableRelation = "MES Operation Execution"."Execution Id";
            DataClassification = CustomerContent;
        }

        // how many units were scrapped
        field(3; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        // reason code from bc
        field(4; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code".Code;
            DataClassification = CustomerContent;
        }

        // description for the reason  from bc or manual
        field(5; "Reason Description"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Operator Id"; Code[50])
        {
            TableRelation = "MES User"."User Id";
            DataClassification = CustomerContent;
        }

        field(7; "Declared At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
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