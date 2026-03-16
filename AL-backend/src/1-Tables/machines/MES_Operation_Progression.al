table 50109 "MES Operation Progression"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation progression';

    fields
    {
        field(1; "Id"; Code[50])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Prod Order No"; Code[20])
        {
            TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
        }



        field(3; "Operation No"; Code[10])
        {
            TableRelation = "Prod. Order Routing Line"."Operation No.";

        }

        field(4; "Machine No"; Code[20])
        {
            TableRelation = "Machine Center"."No.";
        }

        field(5; "Operator Id"; Code[50])
        {
            TableRelation = "MES User"."User Id";
        }

        field(6; "Item No"; Code[20]) { }

        field(7; "Item Description"; Text[100]) { }

        field(8; "Order Quantity"; Decimal) { }

        field(9; "Cycle Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(10; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(11; "Total Produced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }



        field(12; "Last Updated At"; DateTime)
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

        key(StatusTimeline; "Prod Order No", "Operation No", "Machine No", "Last Updated At")
        {
        }
        key(MachineKey; "Machine No") { }
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