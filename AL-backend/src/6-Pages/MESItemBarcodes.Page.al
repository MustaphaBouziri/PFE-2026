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
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GenerateSelected)
            {
                ApplicationArea = All;
                Caption = 'Generate Selected';
                Image = BarCode;

                trigger OnAction()
                var
                    BarcodeGen: Codeunit "MES Barcode Generator";
                begin
                    BarcodeGen.GenerateAndSaveBarcodeText(Rec."No.");
                    CurrPage.Update(false);
                end;
            }

            action(GenerateAll)
            {
                ApplicationArea = All;
                Caption = 'Generate All';
                Image = BarCode;

                trigger OnAction()
                var
                    BarcodeGen: Codeunit "MES Barcode Generator";
                begin
                    if not Confirm('Generate Data Matrix barcodes for ALL items. Continue?') then
                        exit;

                    BarcodeGen.GenerateAllBarcodesWithProgress();
                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            group(Generate)
            {
                actionref(GenerateSelectedRef; GenerateSelected) { }
                actionref(GenerateAllRef; GenerateAll) { }
            }
        }
    }
}