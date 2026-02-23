table 50107 "MES Machine Status"
{
    DataClassification = CustomerContent;
    Caption = 'MES Machine Status';

    fields
    {
        // ---------------------------------------------------------
        // Field 1 — Id (Primary Key)
        // GUID-derived string identifier.
        // Auto-generated if not provided.
        // ---------------------------------------------------------
        field(1; "Id"; Code[50])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }

        field(2; "Machine No."; Code[20])
        {
            Caption = 'Machine No.';
            TableRelation = "Machine Center"."No.";
            DataClassification = CustomerContent;
        }

        field(3; "Status"; Enum "MES Machine Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }

        field(4; "Current Prod. Order No."; Code[20])
        {
            Caption = 'Current Prod. Order No.';
            TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
            DataClassification = CustomerContent;
        }

        field(5; "Last Updated At"; DateTime)
        {
            Caption = 'Last Updated At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }

        key(MachineKey; "Machine No.")
        {
        }
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