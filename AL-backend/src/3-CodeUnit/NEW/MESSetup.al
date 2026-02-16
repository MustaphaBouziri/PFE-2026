codeunit 50115 "MES Setup"
{
    /// this is a code unit to create the first user to access the application
    trigger OnRun()
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        Message('MES Setup started');
        AuthMgt.CreateUser('admin','employeeID','AD001', "MES User Role"::Admin, '');
        AuthMgt.SetPassword('admin', 'Admin@123!', true);
        Message('MES Setup ended');
    end;
}