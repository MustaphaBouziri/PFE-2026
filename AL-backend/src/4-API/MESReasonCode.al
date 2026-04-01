page 50120 "MES Reason Code API"
{
    PageType = API;
    SourceTable = "Reason Code";
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'reasonCode';
    EntitySetName = 'reasonCodes';
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code) {}
                field(Description; Rec.Description) {}
            }
        }
    }
}