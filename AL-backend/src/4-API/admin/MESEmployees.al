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
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec."No.") { Caption = 'Id'; }
                field(firstName; Rec."First Name") { Caption = 'First Name'; }
                field(middleName; Rec."Middle Name") { Caption = 'Middle Name'; }
                field(lastName; Rec."Last Name") { Caption = 'Last Name'; }
                field(email; Rec."E-Mail") { Caption = 'Email'; }
                field(image; Rec.Image) { Caption = 'Image'; }
            }
        }
    }

    var
        MESUser: Record "MES User";

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not Rec.Find(Which) then
            exit(false);

        // Loop until we find an employee WITHOUT MES user
        while true do begin
            MESUser.Reset();
            MESUser.SetRange("Employee ID", Rec."No.");

            if MESUser.IsEmpty() then
                exit(true); // ✅ valid record → return it

            // Otherwise go to next record
            if Rec.Next() = 0 then
                exit(false);
        end;
    end;
}