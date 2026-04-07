// MESMachineValidation.al
// Pure validation layer — no inserts, no side effects.
// Every public procedure is a [TryFunction] so callers can branch on success/failure.
codeunit 50134 "MES Machine Validation"
{
    Access = Internal;

    [TryFunction]
    procedure TryStartOperation(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    )
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", operationNo);

        if not ProdOrderRoutingLine.FindFirst() then
            Error('Routing line not found or order is not in Released status.');

        EnsureNoRunningOperation(machineNo, prodOrderNo, operationNo);
    end;

    [TryFunction]
    procedure TryDeclareProduction(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationProgress: Record "MES Operation Progression";
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        MachineInsert.GetExecution(machineNo, prodOrderNo, operationNo, MESExecution);
        if MESExecution."Execution Id" = '' then
            Error('Operation execution record not found.');

        MachineInsert.GetLatestProgression(MESExecution."Execution Id", MESOperationProgress);
        if MESOperationProgress."Execution Id" = '' then
            Error('Operation progression record not found.');

        if input <= 0 then
            Error('Declared quantity must be greater than zero.');

        if (MESOperationProgress."Total Produced Quantity" + input) > MESExecution."Order Quantity" then
            Error('Declared quantity exceeds the remaining order quantity.');
    end;

    [TryFunction]
    procedure TryPauseOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationState: Record "MES Operation State";
    begin
        GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, MESExecution, MESOperationState);
        if MESOperationState."Operation Status" <> MESOperationState."Operation Status"::Running then
            Error('Operation needs to be running to be paused.');
    end;

    [TryFunction]
    procedure TryResumeOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation State";
    begin
        GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, MESExecution, MESOperationStatus);
        if MESOperationStatus."Operation Status" <> MESOperationStatus."Operation Status"::Paused then
            Error('Operation needs to be paused to be resumed.');

        EnsureNoRunningOperation(machineNo, prodOrderNo, operationNo);
    end;

    [TryFunction]
    procedure TryCloseOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationState: Record "MES Operation State";
    begin
        GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, MESExecution, MESOperationState);
        if MESOperationState."Operation Status" in
           [MESOperationState."Operation Status"::Finished, MESOperationState."Operation Status"::Cancelled]
        then
            Error('Operation is already finished or cancelled.');
    end;

    [TryFunction]
    procedure TryDeclareScrap(
        executionId: Code[50];
        scrapCode: Code[10];
        quantity: Decimal
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationState: Record "MES Operation State";
        ScrapRec: Record Scrap;
    begin
        if not MESExecution.Get(executionId) then
            Error('Execution %1 not found.', executionId);

        GetLatestOperationStatus(executionId, MESOperationState);
        if MESOperationState."Operation Status" in [
            MESOperationState."Operation Status"::Finished,
            MESOperationState."Operation Status"::Cancelled,
            MESOperationState."Operation Status"::Paused
        ] then
            Error('Cannot declare scrap on a finished, cancelled or paused operation.');

        if not ScrapRec.Get(scrapCode) then
            Error('Scrap code %1 does not exist.', scrapCode);

        if quantity <= 0 then
            Error('Scrap quantity must be greater than zero.');
    end;

    // Validates that a supervisor is allowed to submit records on behalf of an operator.
    // Rules: supervisor must have Supervisor role; both must share at least one work center.
    [TryFunction]
    procedure TryValidateProxyDeclaration(
        supervisorUserId: Code[50];
        operatorUserId: Code[50]
    )
    var
        SupervisorUser: Record "MES User";
        SupervisorWC: Record "MES User Work Center";
        OperatorWC: Record "MES User Work Center";
        SharedWorkCenterFound: Boolean;
    begin
        if not SupervisorUser.Get(supervisorUserId) then
            Error('Supervisor user %1 not found.', supervisorUserId);

        if SupervisorUser.Role <> SupervisorUser.Role::Supervisor then
            Error('User %1 does not have the Supervisor role required for proxy declarations.', supervisorUserId);

        // Walk all work centers the supervisor belongs to and check for overlap with the operator
        SharedWorkCenterFound := false;
        SupervisorWC.Reset();
        SupervisorWC.SetRange("User Id", supervisorUserId);
        if SupervisorWC.FindSet() then
            repeat
                OperatorWC.Reset();
                OperatorWC.SetRange("User Id", operatorUserId);
                OperatorWC.SetRange("Work Center No.", SupervisorWC."Work Center No.");
                if not OperatorWC.IsEmpty() then begin
                    SharedWorkCenterFound := true;
                    exit; // TryFunction exits on first shared work center found
                end;
            until SupervisorWC.Next() = 0;

        if not SharedWorkCenterFound then
            Error(
                'Supervisor %1 and operator %2 do not share any work center. Proxy declaration is not permitted.',
                supervisorUserId,
                operatorUserId
            );
    end;

    // ── Shared helpers ────────────────────────────────────────────────────────

    procedure EnsureNoRunningOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10])
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationState: Record "MES Operation State";
    begin
        // Block if this specific order+operation is already running
        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        if MESExecution.FindFirst() then begin
            GetLatestOperationStatus(MESExecution."Execution Id", MESOperationState);
            if MESOperationState."Operation Status" = MESOperationState."Operation Status"::Running then
                Error('This operation is already running.');
        end;

        // Block if the machine itself is running any operation
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        if MESExecution.FindSet() then
            repeat
                GetLatestOperationStatus(MESExecution."Execution Id", MESOperationState);
                if MESOperationState."Operation Status" = MESOperationState."Operation Status"::Running then
                    Error(
                        'Machine %1 is already running another operation (Order %2 - Operation %3). Pause or finish it first.',
                        MESExecution."Machine No",
                        MESExecution."Prod Order No",
                        MESExecution."Operation No"
                    );
            until MESExecution.Next() = 0;
    end;

    procedure GetExecutionAndLatestStatus(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        var MESExecution: Record "MES Operation Execution";
        var MESOperationState: Record "MES Operation State"
    )
    var
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        MachineInsert.GetExecution(machineNo, prodOrderNo, operationNo, MESExecution);

        if MESExecution."Execution Id" = '' then
            Error(
                'Operation execution record not found for Machine %1, Order %2, Operation %3.',
                machineNo, prodOrderNo, operationNo
            );

        GetLatestOperationStatus(MESExecution."Execution Id", MESOperationState);

        if MESOperationState."Execution Id" = '' then
            Error(
                'No operation status found for Machine %1, Order %2, Operation %3.',
                machineNo, prodOrderNo, operationNo
            );
    end;

    procedure GetLatestOperationStatus(executionId: Code[50]; var MESOperationState: Record "MES Operation State")
    begin
        MESOperationState.Reset();
        MESOperationState.SetCurrentKey("Execution Id", "Declared At");
        MESOperationState.SetRange("Execution Id", executionId);
        MESOperationState.Ascending(false);
        MESOperationState.FindFirst();
    end;
}
