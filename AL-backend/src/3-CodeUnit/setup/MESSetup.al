codeunit 50115 "MES Setup"
{

    trigger OnRun()
    begin
        CreateDefaultAccount();
        RegisterPasswordExpiryWorker();
    end;

    local procedure CreateDefaultAccount()
    var
        AuthMgt: Codeunit "MES Auth Mgt";
        U: Record "MES User";
        AdminId: Code[50];
        TempPassword: Text;
    begin
        AdminId := 'ADMIN';
        TempPassword := '00000000';
        Message('MES Setup started – creating default admin account.');

        AuthMgt.CreateUser(
            'ADMIN',                         // User Id
            'GB',                            // Employee ID
            'AUTH-ADMIN01',                  // Auth ID
            Enum::"MES User Role"::Admin     // Role
        );

        AuthMgt.SetPassword(AdminId, TempPassword, true,'');

        Message('MES Setup complete. Login as "admin" and change the password immediately.');
    end;

    /// <summary>
    /// Creates (or refreshes) the Job Queue Entry that runs the
    /// MES Password Expiry Worker once per day.
    ///
    /// Safe to call multiple times – it will not create duplicates.
    /// The entry is left in "Ready" status so the Job Queue scheduler
    /// picks it up automatically.
    /// </summary>
    local procedure RegisterPasswordExpiryWorker()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ExpiryWorkerCodeunitId: Integer;
        RunIntervalMinutes: Integer;
    begin
        ExpiryWorkerCodeunitId := Codeunit::"MES Password Expiry Worker";
        RunIntervalMinutes := 1440; // once every 24 hours

        // Check whether an entry for this codeunit already exists.
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", ExpiryWorkerCodeunitId);

        if JobQueueEntry.FindFirst() then begin
            // Entry already registered – ensure it is still active.
            if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold" then begin
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                JobQueueEntry.Modify(true);
            end;
            exit;
        end;

        // Create a new recurring job queue entry.
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := ExpiryWorkerCodeunitId;
        JobQueueEntry.Description := 'MES – Password Expiry Check';
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."No. of Minutes between Runs" := RunIntervalMinutes;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(true);
    end;
}
