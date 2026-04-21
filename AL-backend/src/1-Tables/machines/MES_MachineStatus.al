// =============================================================================
// Table  : MES Machine Status
// ID     : 50107
// Domain : Machines / 1-Tables
// Purpose: Real-time status log for each machine on the factory floor.
//          Multiple rows may exist per machine (historical log).
//          MESMachineActions.FetchMachines() uses FindLast() to retrieve
//          only the most recent record per machine — this is intentional.
//
// KEYS
//   PK         (Id)         — clustered; lookups by generated GUID-derived Id
//   MachineKey (Machine No.)— non-clustered; filter by machine without full scan
// =============================================================================
table 50107 "MES Machine Status"
{
    DataClassification = CustomerContent;
    Caption = 'MES Machine Status';

    fields
    {
        // Auto-generated GUID-derived string identifier (braces stripped).
        field(1; "Id"; Code[50])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }

        // FK → Machine Center."No." — the physical machine this status belongs to.
        field(2; "Machine No."; Code[20])
        {
            Caption = 'Machine No.';
            TableRelation = "Machine Center"."No.";
            DataClassification = CustomerContent;
        }

        // Current operational state.  See Machine_Status.al for enum values.
        field(3; "Status"; Enum "MES Machine Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }

        // Production order currently being processed on this machine (if any).
        field(4; "Current Prod. Order No."; Code[20])
        {
            Caption = 'Current Prod. Order No.';
            //TableRelation = "Prod. Order Routing Line"."Prod. Order No.";
            DataClassification = CustomerContent;
        }

        // UTC timestamp — set on every insert to track when the status was recorded.
        field(5; "Updated At"; DateTime)
        {
            Caption = 'Updated At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Id")
        {
            Clustered = true;
        }
        key(MachineKey; "Machine No.") { }
        key(MachineTimeline; "Machine No.", "Updated At") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        if "Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "Id" := CopyStr(GuidTxt, 2, 36);
        end;
        "Updated At" := CurrentDateTime();
    end;
}


