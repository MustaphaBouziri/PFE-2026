/// Handles all direct table insertions for MES machine operations.
codeunit 50133 "MES Machine Insert"
{
    Access = Internal;

    // ──────────────────────────────────────────────
    // Execution record
    // ──────────────────────────────────────────────

    /// Creates a new MES Operation Execution row from the production order data.
    procedure InsertMESOperationExecution(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    ): Code[50]
    var
        MESExecution: Record "MES Operation Execution";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", prodOrderNo);
        if not ProdOrderLine.FindFirst() then
            Error('Production order line not found.');

        MESExecution.Init();
        MESExecution."Machine No" := machineNo;
        MESExecution."Prod Order No" := prodOrderNo;
        MESExecution."Operation No" := operationNo;
        MESExecution."Item No" := ProdOrderLine."Item No.";
        MESExecution."Item Description" := ProdOrderLine.Description;
        MESExecution."Order Quantity" := ProdOrderLine.Quantity;
        MESExecution.Insert(true);
        exit(MESExecution."Execution Id");
    end;

    // ──────────────────────────────────────────────
    // Operation status records
    // ──────────────────────────────────────────────

    /// Records the initial Running status for a new execution.
    procedure InsertMESOperation(executionId: Code[50]; mesUserId: Code[50])
    var
        MESOperationStatus: Record "MES Operation State";
    begin
        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := executionId;
        MESOperationStatus."Operation Status" := MESOperationStatus."Operation Status"::Running;
        MESOperationStatus."Operator Id" := mesUserId;
        MESOperationStatus.Insert(true);

        EnsureUserExecutionInteraction(executionId, mesUserId);
    end;

    /// Records a status transition (pause/resume/finish/cancel) for an existing execution.
    procedure InsertOperationStatus(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        status: Enum "MES Operation Status";
        mesUserId: Code[50]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation State";
    begin
        GetExecution(machineNo, prodOrderNo, operationNo, MESExecution);

        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := MESExecution."Execution Id";
        MESOperationStatus."Operation Status" := status;
        MESOperationStatus."Operator Id" := mesUserId;
        MESOperationStatus.Insert(true);

        EnsureUserExecutionInteraction(MESExecution."Execution Id", mesUserId);

        // Stamp the end time on the execution record when the operation closes.
        if status in ["MES Operation Status"::Finished, "MES Operation Status"::Cancelled] then begin
            MESExecution."End Time" := CurrentDateTime();
            MESExecution.Modify(true);
        end;
    end;

    // ──────────────────────────────────────────────
    // Machine status records
    // ──────────────────────────────────────────────

    procedure InsertStartMESMachineStatus(prodOrderNo: Code[20]; machineNo: Code[20])
    var
        MESMachineStatus: Record "MES Machine Status";
    begin
        MESMachineStatus.Init();
        MESMachineStatus."Machine No." := machineNo;
        MESMachineStatus.Status := MESMachineStatus.Status::Working;
        MESMachineStatus."Current Prod. Order No." := prodOrderNo;
        MESMachineStatus.Insert(true);
    end;

    procedure InsertIdleMachineStatus(machineNo: Code[20])
    var
        MESMachineStatus: Record "MES Machine Status";
    begin
        MESMachineStatus.Init();
        MESMachineStatus."Machine No." := machineNo;
        MESMachineStatus.Status := MESMachineStatus.Status::Idle;
        MESMachineStatus."Current Prod. Order No." := '';
        MESMachineStatus.Insert(true);
    end;

    // ──────────────────────────────────────────────
    // Progression records
    // ──────────────────────────────────────────────

    /// Creates the initial zero-quantity progression row when an operation starts.
    procedure InsertMESOperationProgression(
        executionId: Code[50];
        mesUserId: Code[50]
    )
    var
        MESOperationProgress: Record "MES Operation Progression";
    begin
        MESOperationProgress.Init();
        MESOperationProgress."Execution Id" := executionId;
        MESOperationProgress."Cycle Quantity" := 0;
        MESOperationProgress."Scrap Quantity" := 0;
        MESOperationProgress."Total Produced Quantity" := 0;
        MESOperationProgress."Operator Id" := mesUserId;
        MESOperationProgress.Insert(true);

        EnsureUserExecutionInteraction(executionId, mesUserId);
    end;

    /// Appends a new production cycle declaration to the execution history.
    procedure InsertNewProgressionCycle(
       machineNo: Code[20];
       prodOrderNo: Code[20];
       operationNo: Code[10];
       input: Decimal;
       operatorId: Code[50];
       declaredById: Code[50]
   )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationProgress: Record "MES Operation Progression";
        NewMESOperationProgress: Record "MES Operation Progression";
    begin
        GetExecution(machineNo, prodOrderNo, operationNo, MESExecution);
        GetLatestProgression(MESExecution."Execution Id", MESOperationProgress);

        NewMESOperationProgress.Init();
        NewMESOperationProgress."Execution Id" := MESExecution."Execution Id";
        NewMESOperationProgress."Operator Id" := operatorId;
        NewMESOperationProgress."Declared By" := declaredById;
        NewMESOperationProgress."Cycle Quantity" := input;
        NewMESOperationProgress."Total Produced Quantity" := MESOperationProgress."Total Produced Quantity" + input;
        NewMESOperationProgress."Scrap Quantity" := 0;
        NewMESOperationProgress.Insert(true);

        EnsureUserExecutionInteraction(MESExecution."Execution Id", operatorId);
        EnsureUserExecutionInteraction(MESExecution."Execution Id", declaredById);
    end;

    // ──────────────────────────────────────────────
    // Scrap records
    // ──────────────────────────────────────────────

    /// Records a scrap declaration and updates the running progression totals.
    procedure InsertScrapRecord(
       executionId: Code[50];
       scrapCode: Code[10];
       description: Text;
       quantity: Decimal;
       operatorId: Code[50];
       declaredById: Code[50]
   )
    var
        MESExecution: Record "MES Operation Execution";
        MESScrap: Record "MES Operation Scrap";
        ScrapRec: Record Scrap;
        MESOperationProgress: Record "MES Operation Progression";
        NewMESOperationProgress: Record "MES Operation Progression";
    begin
        MESExecution.Get(executionId);

        MESScrap.Init();
        MESScrap."Execution Id" := executionId;
        MESScrap."Scrap Quantity" := quantity;
        MESScrap."Scrap Code" := scrapCode;
        MESScrap."scrap notes" := CopyStr(description, 1, 256);
        MESScrap."Operator Id" := operatorId;
        MESScrap."Declared By" := declaredById;

        if scrapCode <> '' then
            if ScrapRec.Get(scrapCode) then
                MESScrap."scrap Description" := CopyStr(ScrapRec.Description, 1, 100);

        MESScrap.Insert(true);

        EnsureUserExecutionInteraction(executionId, operatorId);
        EnsureUserExecutionInteraction(executionId, declaredById);
        GetLatestProgression(executionId, MESOperationProgress);

        // Progression row that carries the scrap delta without changing produced quantity
        NewMESOperationProgress.Init();
        NewMESOperationProgress."Execution Id" := executionId;
        NewMESOperationProgress."Operator Id" := operatorId;
        NewMESOperationProgress."Declared By" := declaredById;
        NewMESOperationProgress."Cycle Quantity" := 0;
        NewMESOperationProgress."Scrap Quantity" := quantity;
        NewMESOperationProgress."Total Produced Quantity" := MESOperationProgress."Total Produced Quantity";
        NewMESOperationProgress.Insert(true);
    end;

    // ──────────────────────────────────────────────
    // Composite helpers
    // ──────────────────────────────────────────────

    /// Orchestrates all inserts required to start a fresh operation.
    procedure InsertStartOperationRecords(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20];
        mesUserId: Code[50]
    ): Code[50]
    var
        ExecutionId: Code[50];
    begin
        ExecutionId := InsertMESOperationExecution(prodOrderNo, operationNo, machineNo);
        InsertMESOperation(ExecutionId, mesUserId);
        InsertMESOperationProgression(ExecutionId, mesUserId);
        InsertStartMESMachineStatus(prodOrderNo, machineNo);
        exit(ExecutionId);
    end;

    // ──────────────────────────────────────────────
    // Query helpers
    // ──────────────────────────────────────────────

    procedure GetExecution(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        var MESExecution: Record "MES Operation Execution"
    )
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        MESExecution.FindFirst();
    end;

    procedure GetLatestProgression(
        executionId: Code[50];
        var MESOperationProgress: Record "MES Operation Progression"
    )
    begin
        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey("Execution Id", "Declared At");
        MESOperationProgress.SetRange("Execution Id", executionId);
        MESOperationProgress.Ascending(false);
        MESOperationProgress.FindFirst();
    end;

    /// Records that a MES user participated in this execution.
    /// Idempotent — safe to call multiple times for the same pair.
    procedure EnsureUserExecutionInteraction(executionId: Code[50]; mesUserId: Code[50])
    var
        MESUEI: Record "MES User Execution Interaction";
    begin
        if MESUEI.Get(executionId, mesUserId) then
            exit;

        MESUEI.Init();
        MESUEI."Execution Id" := executionId;
        MESUEI."User Id" := mesUserId;
        MESUEI.Insert(true);
    end;
}
