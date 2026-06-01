page 50115 "MES Component Consumption"
{
    PageType = List;
    SourceTable = "MES Operation Scan";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'MES Component Consumption';

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

                field("Prod Order No"; Rec."Prod Order No")
                {
                    ApplicationArea = All;
                }

                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = All;
                }

                field("Barcode"; Rec."Barcode")
                {
                    ApplicationArea = All;
                }



                field("Quantity Scanned"; Rec."Quantity Scanned")
                {
                    ApplicationArea = All;
                }
                Field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                }
                Field("Quantity per Unit of Measure"; Rec."Quantity per Unit of Measure")
                {
                    ApplicationArea = All;
                }

                //field("Quantity Consumed"; Rec."Quantity Consumed")
                //{
                //    ApplicationArea = All;
                //}

                field("Operator Id"; Rec."Operator Id")
                {
                    ApplicationArea = All;
                }

                field("Scanned At"; Rec."Scanned At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}