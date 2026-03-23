table 50110 "MES Operation Execution"
{
    DataClassification = CustomerContent;
    Caption = 'MES Operation Execution';

    fields
    {
        field(1; "Execution Id"; Code[50])
        {
            DataClassification = SystemMetadata;
        }

        field(2; "Machine No"; Code[20])
        {
            TableRelation = "Machine Center"."No.";
        }

        field(3; "Prod Order No"; Code[20])
        {
            TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
        }

        field(4; "Operation No"; Code[10]) { }

        

        field(5; "Item No"; Code[20]) { }

        field(6; "Item Description"; Text[100]) { }

        field(7; "Order Quantity"; Decimal) { }

        field(8; "Start Time"; DateTime)
        {
            DataClassification = SystemMetadata;
        }

        field(9; "End Time"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Execution Id")
        {
            Clustered = true;
        }
        key(MachineKey; "Machine No") { }
        key(OperationKey; "Prod Order No", "Operation No") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "Execution Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "Execution Id" := CopyStr(GuidTxt, 2, 36);
        end;
        "Start Time" := CurrentDateTime();
    end;
}