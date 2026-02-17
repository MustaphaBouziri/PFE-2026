page 50100 "MES Employee API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'employee';
    EntitySetName = 'employees';
    SourceTable = Employee;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."No.")
                {
                    Caption = 'Id';
                }

                field(firstName; Rec."First Name")
                {
                    Caption = 'First Name';
                }

                field("middleName"; Rec."Middle Name")
                {
                    Caption = 'middle Name';
                }

                field(lastName; Rec."Last Name")
                {
                    Caption = 'Last Name';
                }


                field(email; Rec."E-Mail")
                {
                    Caption = 'Email';
                }

                field(image; Rec.Image)
                {
                    Caption = 'Image';
                }
            }
        }
    }
}