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
            TableRelation = "MES User Execution Interaction"."Execution Id";
            DataClassification = CustomerContent;
        }

        // how many units were scrapped
        field(3; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }

        // scrap code from bc
        field(4; "Scrap Code"; Code[10])
        {
            TableRelation = Scrap.Code;
            DataClassification = CustomerContent;
        }

        // description for the scrap code  from bc or manual
        field(5; "scrap Description"; Text[100])
        {
            TableRelation = Scrap.Description;
            DataClassification = CustomerContent;
        }
        // user supplied description to the error optional
        field(6; "scrap notes"; Text[256])
        {
            DataClassification = CustomerContent;
        }
        field(7; "Operator Id"; Code[50])
        {
            TableRelation = "MES User Execution Interaction"."User Id";
            DataClassification = CustomerContent;
        }

        field(8; "Declared At"; DateTime)
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