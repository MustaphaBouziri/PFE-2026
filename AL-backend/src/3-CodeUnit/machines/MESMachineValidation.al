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
        PreviousProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        //get current order routing line mainly to know what operation u on  10 20 30 
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", operationNo);

        if not ProdOrderRoutingLine.FindFirst() then
            Error('Routing line not found.');

        EnsureNoRunningOperation(machineNo, prodOrderNo, operationNo);

        // now we find the previous order routing line 
        PreviousProdOrderRoutingLine.Reset();
        PreviousProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status);
        PreviousProdOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        PreviousProdOrderRoutingLine.SetFilter("Operation No.", '<%1', operationNo);
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
           [
               MESOperationState."Operation Status"::Finished,
               MESOperationState."Operation Status"::Cancelled
           ]
        then
            Error('Operation is already finished or cancelled.');
    end;

    procedure EnsureNoRunningOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10])
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationState: Record "MES Operation State";
    begin
        // prevent starting the same operation twice
        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        if MESExecution.FindFirst() then begin
            GetLatestOperationStatus(MESExecution."Execution Id", MESOperationState);
            if MESOperationState."Operation Status" = MESOperationState."Operation Status"::Running then
                Error('This operation is already running.');
        end;

        // check if there is a currently worked on operation
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
                machineNo,
                prodOrderNo,
                operationNo
            );

        GetLatestOperationStatus(MESExecution."Execution Id", MESOperationState);

        if MESOperationState."Execution Id" = '' then
            Error(
                'No operation status found for Machine %1, Order %2, Operation %3.',
                machineNo,
                prodOrderNo,
                operationNo
            );
    end;

    procedure GetLatestOperationStatus(executionId: Code[50]; var MESOperationState: Record "MES Operation State")
    begin
        MESOperationState.Reset();
        MESOperationState.SetCurrentKey("Execution Id", "Last Updated At");
        MESOperationState.SetRange("Execution Id", executionId);
        MESOperationState.Ascending(false);
        MESOperationState.FindFirst();
    end;
}
