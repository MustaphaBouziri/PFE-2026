page 50112 "MES Item Barcodes"
{
    PageType = List;
    Caption = 'Item Data Matrix Barcodes';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Item;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(ItemLines)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Base UOM';
                }
                field("MES Barcode Text"; Rec."MES Barcode Text")
                {
                    ApplicationArea = All;
                    Caption = 'Datamatrix Encoded';
                    ToolTip = 'The encoded Data Matrix string stored for this item.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateAll)
            {
                ApplicationArea = All;
                Caption = 'Generate All Barcodes';
                ToolTip = 'Generate and save Data Matrix encoded text for all items.';
                Image = BarCode;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    BarcodeGen: Codeunit "MES Barcode Generator";

                begin
                    if not Confirm('Generate Data Matrix barcodes for ALL items. Continue?') then
                        exit;
                    BarcodeGen.GenerateAndSaveBarcodeText(Rec."No.");
                    CurrPage.Update(false);
                end;
            }

            action(GenerateSelected)
            {
                ApplicationArea = All;
                Caption = 'Generate for Selected';

                trigger OnAction()
                var
                    BarcodeGen: Codeunit "MES Barcode Generator";
                begin
                    BarcodeGen.GenerateAndSaveBarcodeText(Rec."No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}