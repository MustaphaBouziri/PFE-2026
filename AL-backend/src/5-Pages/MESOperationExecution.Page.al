page 50111 "MES Operation Execution"
{
    PageType = List;
    SourceTable = "MES Operation Execution";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'MES Operation Execution';

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
                field("Execution Id"; Rec."Execution Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Machine No"; Rec."Machine No")
                {
                    ApplicationArea = All;
                }

                field("Prod Order No"; Rec."Prod Order No")
                {
                    ApplicationArea = All;
                }

                field("Operation No"; Rec."Operation No")
                {
                    ApplicationArea = All;
                }

                

                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = All;
                }

                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                }

                field("Order Quantity"; Rec."Order Quantity")
                {
                    ApplicationArea = All;
                }

                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}