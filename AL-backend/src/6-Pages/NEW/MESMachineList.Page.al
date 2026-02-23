page 50143 "MES Machine List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MES Machines';
    SourceTable = "Machine Center";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Machines)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }

                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = All;
                }

                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                }

                field(CurrentStatus; GetMachineStatus())
                {
                    ApplicationArea = All;
                    Caption = 'Current Status';
                    Editable = false;
                }

                field(CurrentOrder; GetCurrentOrder())
                {
                    ApplicationArea = All;
                    Caption = 'Current Prod. Order';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetStarting)
            {
                Caption = 'Set Starting';
                ApplicationArea = All;

                trigger OnAction()
                var
                    MESMachineStatus: Record "MES Machine Status";
                begin
                    MESMachineStatus.Init();
                    MESMachineStatus."Machine No." := Rec."No.";
                    MESMachineStatus.Status := MESMachineStatus.Status::Starting;
                    MESMachineStatus."Last Updated At" := CurrentDateTime();
                    MESMachineStatus.Insert(true);
                end;
            }

            action(SetIdle)
            {
                Caption = 'Set Idle';
                ApplicationArea = All;

                trigger OnAction()
                var
                    MESMachineStatus: Record "MES Machine Status";
                begin
                    MESMachineStatus.Init();
                    MESMachineStatus."Machine No." := Rec."No.";
                    MESMachineStatus.Status := MESMachineStatus.Status::Idle;
                    MESMachineStatus."Last Updated At" := CurrentDateTime();
                    MESMachineStatus.Insert(true);
                end;
            }

            action(SetOutOfOrder)
            {
                Caption = 'Set Out Of Order';
                ApplicationArea = All;

                trigger OnAction()
                var
                    MESMachineStatus: Record "MES Machine Status";
                begin
                    MESMachineStatus.Init();
                    MESMachineStatus."Machine No." := Rec."No.";
                    MESMachineStatus.Status := MESMachineStatus.Status::OutOfOrder;
                    MESMachineStatus."Last Updated At" := CurrentDateTime();
                    MESMachineStatus.Insert(true);
                end;
            }
        }
    }

    var
        MESMachineStatus: Record "MES Machine Status";

    local procedure GetMachineStatus(): Text
    begin
        MESMachineStatus.Reset();
        MESMachineStatus.SetRange("Machine No.", Rec."No.");

        if MESMachineStatus.FindLast() then
            exit(Format(MESMachineStatus.Status));

        exit('Idle');
    end;

    local procedure GetCurrentOrder(): Text
    begin
        MESMachineStatus.Reset();
        MESMachineStatus.SetRange("Machine No.", Rec."No.");

        if MESMachineStatus.FindLast() then
            exit(MESMachineStatus."Current Prod. Order No.");

        exit('');
    end;
}