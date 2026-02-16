page 50100 "MES Employee API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'employee';//employees('11') means like return 1 record instead of many 

    EntitySetName = 'employees'; // endpoint /employees
    SourceTable = Employee;

    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group) // means like if u have 10 employees these fiels will repeat 10 times
            {
                field(id; Rec."No.") // means the key is value in json the key will be Id its value is the whataver value the record is recording  exemple 'id':"125"
                {
                    Caption = 'Id'; // not importent just for ui it's showen as column titles 
                }

                field(firstName; Rec."First Name")
                {
                    Caption = 'First Name';
                }

                field(lastName; Rec."Last Name")
                {
                    Caption = 'Last Name';
                }

                field(email; Rec."E-Mail")
                {
                    Caption = 'Email';
                }

                
            }
        }
    }
}