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

                field("Prod Order No"; Rec."Prod Order No")
                {
                    ApplicationArea = All;
                }

                field("Operation No"; Rec."Operation No")
                {
                    ApplicationArea = All;
                }

                field("Machine No"; Rec."Machine No")
                {
                    ApplicationArea = All;
                }

                field("Operator Id"; Rec."Operator Id")
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

                field("Produced Quantity"; Rec."Produced Quantity")
                {
                    ApplicationArea = All;
                }

                field("Scrap Quantity"; Rec."Scrap Quantity")
                {
                    ApplicationArea = All;
                }

                field("Last Updated At"; Rec."Last Updated At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}