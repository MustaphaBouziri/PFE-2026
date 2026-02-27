table 50108 "MES Operation"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation';

    fields
    {
        field(1; "Prod Order No"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
        }

        field(2; "Operation No"; Code[10])
        {
            Caption = 'Operation No';
        }

        field(3; "Order Status"; Enum "Production Order Status")
        {
            Caption = 'Order Status';
        }

        field(4; "Machine No"; Code[20])
        {
            TableRelation = "Machine Center"."No.";
        }

        field(5; "Operator Id"; Code[20])
        {
            TableRelation = "MES User"."User Id";
        }

        field(6; "Item No"; Code[20]) { }

        field(7; "Item Description"; Text[100]) { }

        field(8; "Order Quantity"; Decimal) { }

        field(9; "Produced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(10; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
        }

        field(11; "Operation Status"; Enum "MES Operation Status")
        {
            Caption = 'MES Operation Status';
        }

        field(12; "Start DateTime"; DateTime) { }

        field(13; "End DateTime"; DateTime) { }

        field(14; "Last Updated At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Prod Order No", "Operation No")
        {
            Clustered = true;
        }

        key(MachineKey; "Machine No") { }
    }

    trigger OnInsert()
    begin
        "Last Updated At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        "Last Updated At" := CurrentDateTime();
    end;
}