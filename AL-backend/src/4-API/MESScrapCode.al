page 50120 "MES scrap Code API"
{
    PageType = API;
    SourceTable = "scrap";
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'scrapCode';
    EntitySetName = 'scrapCodes';
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(code; Rec.Code) { }
                field(description; Rec.Description) { }
            }
        }
    }
}