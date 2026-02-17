page 50102 "MES Department API"
{
    PageType = API;
    DelayedInsert = true;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'workCenter';
    EntitySetName = 'workCenters';
    SourceTable = "Work Center"; // Department table in BC

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."No.")
                {
                    Caption = 'Work Center id ';

                }

                field(departmentName; Rec.Name)
                {
                    Caption = 'Work Center name ';
                }
            }
        }
    }
}