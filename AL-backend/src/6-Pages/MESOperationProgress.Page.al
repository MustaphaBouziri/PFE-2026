page 50109 "MES Operation Progression"
{
    PageType = List;
    SourceTable = "MES Operation Progression";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'MES Operation Progression';

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
                    Editable = false;
                }

                field("Execution Id"; Rec."Execution Id")
                {
                    ApplicationArea = All;
                }

                field("Operator Id"; Rec."Operator Id")
                {
                    ApplicationArea = All;
                }

                field("Cycle Quantity"; Rec."Cycle Quantity")
                {
                    ApplicationArea = All;
                }

                field("Total Produced Quantity"; Rec."Total Produced Quantity")
                {
                    ApplicationArea = All;
                }

                field("Scrap Quantity"; Rec."Scrap Quantity")
                {
                    ApplicationArea = All;
                }

                field("Last Updated At"; Rec."Declared At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}