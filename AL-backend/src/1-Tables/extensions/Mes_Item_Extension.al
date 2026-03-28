tableextension 50100 "MES Item Extension" extends Item
{
    fields
    {
        field(50200; "MES Barcode Text"; Text[250])
        {
            Caption = 'MES Barcode Text';
            DataClassification = CustomerContent;
        }
    }
}