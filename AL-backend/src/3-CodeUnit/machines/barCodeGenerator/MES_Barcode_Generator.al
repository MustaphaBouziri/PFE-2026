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
}