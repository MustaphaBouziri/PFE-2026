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
        field(2; "Prod Order No"; Code[20])
        {
            TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
        }

       

        field(3; "Operation No"; Code[10])
        {
            Caption = 'Operation No';
        }

        field(4; "Machine No"; Code[20])
        {
            TableRelation = "Machine Center"."No.";
        }

        field(5; "Operator Id"; Code[20])
        {
            TableRelation = "MES User"."User Id";
        }

        

        field(6; "Operation Status"; Enum "MES Operation Status")
        {
            Caption = 'MES Operation Status';
        }

        

        field(7; "Last Updated At"; DateTime)
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