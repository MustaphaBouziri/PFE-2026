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
                field("MES Barcode Code"; Rec."MES Barcode Code")
                {
                    ApplicationArea = All;
                    Caption = 'Barcode Code';
                }
                field("MES Barcode Text"; Rec."MES Barcode Text")
                {
                    ApplicationArea = All;
                    Caption = 'Datamatrix Encoded Text';
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
                Caption = 'Generate Barcode';
                Image = BarCode;

                trigger OnAction()
                var
                    BarcodeGen: Codeunit "MES Barcode Generator";
                    UOMDialog: Page "MES Select UOM Dialog";
                    SelectedUOM: Code[10];
                begin
                    UOMDialog.SetItemNo(Rec."No.");

                    if UOMDialog.RunModal() = Action::OK then begin
                        SelectedUOM := UOMDialog.GetSelectedUOM();

                        if SelectedUOM = '' then begin
                            Message('Please select a unit of measure.');
                            exit;
                        end;

                        BarcodeGen.GenerateAndSaveBarcodeText(Rec."No.", SelectedUOM);
                        CurrPage.Update(false);
                        Message('Barcode generated successfully for item %1 with UOM %2.', Rec."No.", SelectedUOM);
                    end;
                end;
            }
        }

        area(Promoted)
        {
            group(Generate)
            {
                actionref(GenerateSelectedRef; GenerateSelected) { }
            }
        }
    }
}

page 50113 "MES Select UOM Dialog"
{
    PageType = StandardDialog;
    Caption = 'Select Unit of Measure';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                field(SelectedUOMCode; SelectedUOMCode)
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure';
                    Editable = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemUOM: Record "Item Unit of Measure";
                        ItemUOMPage: Page "Item Units of Measure";
                    begin
                        ItemUOM.SetRange("Item No.", ItemNoFilter);

                        ItemUOMPage.SetTableView(ItemUOM);
                        ItemUOMPage.LookupMode(true);

                        if ItemUOMPage.RunModal() = Action::LookupOK then begin
                            ItemUOMPage.GetRecord(ItemUOM);

                            SelectedUOMCode := ItemUOM.Code;
                            Text := ItemUOM.Code;

                            UpdateQty();
                            CurrPage.Update(true);

                            exit(true);
                        end;

                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateQty();
                    end;
                }

                field(QtyPerUOM; QtyPerUOM)
                {
                    ApplicationArea = All;
                    Caption = 'Qty. per Unit of Measure';
                    Editable = false;
                }
            }
        }
    }

    var
        ItemNoFilter: Code[20];
        SelectedUOMCode: Code[10];
        QtyPerUOM: Decimal;

    procedure SetItemNo(itemNo: Code[20])
    begin
        ItemNoFilter := itemNo;
    end;

    procedure GetSelectedUOM(): Code[10]
    begin
        exit(SelectedUOMCode);
    end;

    local procedure UpdateQty()
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        QtyPerUOM := 0;

        if SelectedUOMCode = '' then
            exit;

        ItemUOM.SetRange("Item No.", ItemNoFilter);
        ItemUOM.SetRange(Code, SelectedUOMCode);

        if ItemUOM.FindFirst() then
            QtyPerUOM := ItemUOM."Qty. per Unit of Measure";
    end;
}