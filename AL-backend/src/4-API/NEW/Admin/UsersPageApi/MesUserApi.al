page 50101 "MES User API"
{
    PageType = API;
    DelayedInsert=true;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'mesUser';
    EntitySetName = 'mesUsers';
    SourceTable = "MES User";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userId; Rec."User Id")
                {
                    Caption = 'User Id';
                }

                field(employeeId; Rec."employee ID")
                {
                    Caption = 'Employee ID';
                }

                field(role; Rec.Role)
                {
                    Caption = 'Role';
                }

                field(firstName; EmployeeRec."First Name")
                {
                    Caption = 'First Name';
                }

                field(lastName; EmployeeRec."Last Name")
                {
                    Caption = 'Last Name';
                }

                field(email; EmployeeRec."E-Mail")
                {
                    Caption = 'Email';
                }
            }
        }
    }

    var
        EmployeeRec: Record Employee; // basicaly its like sating select * from eployee where no = 0001

    trigger OnAfterGetRecord() // for each record meaning row it fetches from mes user, it will  trigger it 
    begin
        Clear(EmployeeRec);

        if Rec."employee ID" <> '' then // if the mes user has an employee id stored then do this
        // in sql this the join line  "find employe where employee.no=mesUser.employee id "
            EmployeeRec.Get(Rec."employee ID"); // basicaly its like saying EmployeeRec.Get('E0001') so now the employee rec have all infos  firstname last name email etc 

    end;
}
