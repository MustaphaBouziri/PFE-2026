codeunit 50100 "MES Barcode Generator"
{
    procedure GenerateItemBarcodeText(itemNo: Code[20]): Text
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        BarcodeText: Text;
        QtyPerUOM: Decimal;
    begin
        if not Item.Get(itemNo) then
            Error('Item %1 not found.', itemNo);

        BarcodeText := StrSubstNo(
     'Item Number: %1|Item Description: %2|Base UOM: %3|Inventory: %4|Shelf No: %5|Lot Size: %6|Flushing Method: %7',
     Item."No.",
     Item.Description,
     Item."Base Unit of Measure",
     Item.Inventory,
     Item."Shelf No.",
     Item."Lot Size",
     Item."Flushing Method"
 );

        exit(BarcodeText);
    end;

    procedure GenerateAndSaveBarcodeText(itemNo: Code[20])
    var
        Item: Record Item;
        BarcodeText: Text;
    begin
        BarcodeText := GenerateItemBarcodeText(itemNo);

        Item.Get(itemNo);
        Item."MES Barcode Text" := CopyStr(BarcodeText, 1, 250);
        Item.Modify();
    end;

    procedure GenerateAllBarcodesWithProgress()
var
    Item: Record Item;
    TotalCount: Integer;
    CurrentCount: Integer;
    Dialog: Dialog;
    Percent: Integer;
begin
   
    Item.Reset();
    TotalCount := Item.Count();

    if TotalCount = 0 then
        exit;

    Dialog.Open('Generating Barcodes...\\Progress: #1####% (#2####/#3####)');

    CurrentCount := 0;

    if Item.FindSet() then begin
        repeat
            CurrentCount += 1;

            GenerateAndSaveBarcodeText(Item."No.");

            Percent := Round(CurrentCount * 100 / TotalCount, 1);

            Dialog.Update(1, Percent);
            Dialog.Update(2, CurrentCount);
            Dialog.Update(3, TotalCount);

        until Item.Next() = 0;
    end;

    Dialog.Close();

    Message('All barcodes generated successfully!');
end;
}