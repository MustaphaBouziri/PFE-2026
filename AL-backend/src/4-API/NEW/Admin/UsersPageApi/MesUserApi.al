/*page 50101 "MES User API"
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
*/

page 50101 "MES User API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'mesUser';
    EntitySetName = 'mesUsers';
    SourceTable = "MES User";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userId; Rec."User Id") { }
                field(employeeId; Rec."employee ID") { }
                field(authId; Rec."Auth ID") { }
                field(role; Rec.Role) { }
                field(workCenterNo; Rec."Work Center No.") { }
                field(isActive; Rec."Is Active") { }
                field(needToChangePw; Rec."Need To Change Pw") { }
                field(createdAt; Rec."Created At") { }


                field(firstName; EmployeeRec."First Name") { }
                field(lastName; EmployeeRec."Last Name") { }
                field(email; EmployeeRec."E-Mail") { }


                field(workCenterName; WorkCenterRec.Name) { }
            }
        }
    }

    var
        EmployeeRec: Record Employee;
        WorkCenterRec: Record "Work Center";

    trigger OnAfterGetRecord()
    begin
        Clear(EmployeeRec);
        Clear(WorkCenterRec);

        if Rec."employee ID" <> '' then
            EmployeeRec.Get(Rec."employee ID");

        if Rec."Work Center No." <> '' then
            if WorkCenterRec.Get(Rec."Work Center No.") then;
    end;
}




page 50103 "MES User Create API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'mesUserCreate';
    EntitySetName = 'createMesUsers';
    SourceTable = "MES User";
    DelayedInsert = true; // important for POST

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(userId; Rec."User Id") { }
                field(employeeId; Rec."employee ID") { }
                field(authId; Rec."Auth ID") { }
                field(role; Rec.Role) { }
                field(workCenterNo; Rec."Work Center No.") { }
                field(isActive; Rec."Is Active") { }
                field(needToChangePw; Rec."Need To Change Pw") { }
                field(createdAt; Rec."Created At") { }


                field(firstName; EmployeeRec."First Name") { Editable = false; }
                field(lastName; EmployeeRec."Last Name") { Editable = false; }
                field(email; EmployeeRec."E-Mail") { Editable = false; }


                field(workCenterName; WorkCenterRec.Name) { Editable = false; }
            }
        }
    }

    var
        EmployeeRec: Record Employee;
        WorkCenterRec: Record "Work Center";

    trigger OnAfterGetRecord()
    begin
        Clear(EmployeeRec);
        Clear(WorkCenterRec);

        if (Rec."employee ID" <> '') then
            if not EmployeeRec.Get(Rec."employee ID") then
                Clear(EmployeeRec);

        if (Rec."Work Center No." <> '') then
            if not WorkCenterRec.Get(Rec."Work Center No.") then
                Clear(WorkCenterRec);
    end;

}