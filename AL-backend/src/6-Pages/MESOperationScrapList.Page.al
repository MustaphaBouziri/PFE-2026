page 50149 "MES Operation Scrap List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MES Operation Scrap";
    Caption = 'MES Operation Scrap';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Id"; Rec."Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the scrap declaration.';
                }

                field("Execution Id"; Rec."Execution Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the execution this scrap belongs to.';
                }

                field("Scrap Quantity"; Rec."Scrap Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many units were scrapped.';
                }

                field("Scrap Code"; Rec."Scrap Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scrap code.';
                }

                field("scrap Description"; Rec."scrap Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scrap description.';
                }

                field("scrap notes"; Rec."scrap notes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies additional notes entered by the user.';
                }

                field("Operator Id"; Rec."Operator Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the operator who declared the scrap.';
                }

                field("Declared At"; Rec."Declared At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the scrap was declared.';
                }
            }
        }
    }
}