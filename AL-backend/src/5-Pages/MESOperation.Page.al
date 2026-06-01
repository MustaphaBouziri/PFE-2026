page 50108 "MES Operations"
{
    PageType = List;
    SourceTable = "MES Operation State";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'MES Operations';

    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Id"; Rec."Id")
                {
                    ApplicationArea = All;
                    Editable = false; // Auto-generated GUID
                }

                field("Execution Id"; Rec."Execution Id")
                {
                    ApplicationArea = All;
                }

                field("Operation Status"; Rec."Operation Status")
                {
                    ApplicationArea = All;
                }

                field("Last Updated At"; Rec."Declared At")
                {
                    ApplicationArea = All;
                    Editable = false; // Updated automatically
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetRunning)
            {
                Caption = 'Set Running';
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec."Operation Status" := Rec."Operation Status"::Running;
                    Rec.Modify();
                end;
            }

            action(SetPaused)
            {
                Caption = 'Set Paused';
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec."Operation Status" := Rec."Operation Status"::Paused;
                    Rec.Modify();
                end;
            }

            action(SetFinished)
            {
                Caption = 'Set Finished';
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec."Operation Status" := Rec."Operation Status"::Finished;
                    Rec.Modify();
                end;
            }
        }
    }
}