table 50111 "MES Component Consumption"
{
    DataClassification = CustomerContent;
    Caption = 'MES Component Consumption';

    fields
    {
        field(1; "Id"; Code[50])
        {
            DataClassification = SystemMetadata;
        }

        field(2; "Execution Id"; Code[50])
        {
            TableRelation = "MES Operation Execution"."Execution Id";
            DataClassification = CustomerContent;
        }

        field(3; "Prod Order No"; Code[50])
        {
            TableRelation = "Prod. Order Component"."Prod. Order No.";
            DataClassification = CustomerContent;
        }

        field(4; "Item No"; Code[50])
        {
            Caption = 'Item Number';
            DataClassification = CustomerContent;
        }

        field(5; "Barcode"; Code[50])
        {
            Caption = 'Barcode';
            DataClassification = CustomerContent;
        }

        field(6; "Unit of Measure"; Code[50])
        {
            Caption = 'Unit of Measure';
            DataClassification = CustomerContent;
        }

        field(7; "Quantity Scanned"; Decimal)
        {
            Caption = 'Quantity Scanned';
            DataClassification = CustomerContent;
        }
        field(8; "Quantity Consumed"; Decimal)
        {
            Caption = 'Quantity Consumed';
            DataClassification = CustomerContent;
        }

        field(9; "Operator Id"; Code[50])
        {
            TableRelation = "MES User"."User Id";
            DataClassification = CustomerContent;
        }

        field(10; "Scanned At"; DateTime)
        {
            Caption = 'Scanned At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }

        key(ExecutionTimeline; "Execution Id", "Scanned At") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "Id" := CopyStr(GuidTxt, 2, 36);
        end;
        "Scanned At" := CurrentDateTime();
    end;
}