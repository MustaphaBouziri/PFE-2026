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
            TableRelation = "MES User Execution Interaction"."Execution Id";
            DataClassification = CustomerContent;
        }

        field(3; "Prod Order No"; Code[20])
        {
             Caption = 'Prod Order No';
            DataClassification = CustomerContent;
        }

        field(4; "Item No"; Code[20])
        {
           
            DataClassification = CustomerContent;
        }

        field(5; "Barcode";Text[500] )
        {
            Caption = 'Barcode';
            DataClassification = CustomerContent;
        }
        field(6; "Quantity Scanned"; Decimal)
        {
            Caption = 'Quantity Scanned';
            DataClassification = CustomerContent;
        }
        //field(7; "Quantity Consumed"; Decimal)
       // {
        //    Caption = 'Quantity Consumed';
        //    DataClassification = CustomerContent;
        //}

        field(7; "Operator Id"; Code[50])
        {
            TableRelation = "MES User Execution Interaction"."User Id";
            DataClassification = CustomerContent;
        }

        field(8; "Scanned At"; DateTime)
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