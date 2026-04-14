codeunit 50100 "MES Barcode Generator"
{
    procedure GenerateItemBarcodeText(itemNo: Code[20]): Text
    var
        Item: Record Item;
        BarcodeText: Text;
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

    // generates barcode text, saves it on item, AND registers it in Item Identifier
    // uomCode = the unit of measure the user selected (e.g. BOX, PCS, PACKET)
    procedure GenerateAndSaveBarcodeText(itemNo: Code[20]; uomCode: Code[10])
    var
        Item: Record Item;
        ItemIdentifier: Record "Item Identifier";
        BarcodeText: Text;
        ShortCode: Code[20];
    begin
        BarcodeText := GenerateItemBarcodeText(itemNo);

        Item.Get(itemNo);
        Item."MES Barcode Text" := CopyStr(BarcodeText, 1, 250);

        // generate a short unique code for Item Identifier
        // format: MES- + item no truncated to 16 chars
        ShortCode := CopyStr('MES-' + itemNo, 1, 20);
        Item."MES Barcode Code" := ShortCode;
        Item.Modify();

        // insert or update Item Identifier so resolveBarcode works for our barcodes too
        // this means scanning our datamatrix goes through the same resolveBarcode path
        if not ItemIdentifier.Get(ShortCode) then begin
            ItemIdentifier.Init();
            ItemIdentifier.Code := ShortCode;
        end;

        ItemIdentifier."Item No." := itemNo;
        ItemIdentifier."Unit of Measure Code" := uomCode;
        ItemIdentifier."Variant Code" := '';

        if ItemIdentifier.Find() then
            ItemIdentifier.Modify()
        else
            ItemIdentifier.Insert();
    end;
 
}