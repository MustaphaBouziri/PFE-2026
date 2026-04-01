codeunit 50133 "MES Machine Insert"
{
    Access = Internal;
    // here we put procedure that will be used multiple times 
    procedure InsertMESOperationExecution(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    ): Code[50]
    var
        MESExecution: Record "MES Operation Execution";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // i need to do setRange otherwise i wont be able to know order details like quantity
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

    procedure InsertMESOperation(executionId: Code[50])
    var
        MESOperationStatus: Record "MES Operation State";
    begin
        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := executionId;
        MESOperationStatus."Operation Status" := MESOperationStatus."Operation Status"::Running;
        MESOperationStatus."Operator Id" := UserId;
        MESOperationStatus.Insert(true);

        EnsureUserExecutionInteraction(executionId);
    end;

    procedure InsertStartMESMachineStatus(
        prodOrderNo: Code[20];
        machineNo: Code[20]
    )
    var
        MESMachineStatus: Record "MES Machine Status";
    begin
        MESMachineStatus.Init();
        MESMachineStatus."Machine No." := machineNo;
        MESMachineStatus.Status := MESMachineStatus.Status::Working;
        MESMachineStatus."Current Prod. Order No." := prodOrderNo;
        MESMachineStatus.Insert(true);
    end;

    procedure InsertMESOperationProgression(
        executionId: Code[50];
        prodOrderNo: Code[20];
        machineNo: Code[20]
    )
    var
        MESOperationProgress: Record "MES Operation Progression";
    begin
        MESOperationProgress.Init();
        MESOperationProgress."Execution Id" := executionId;
        MESOperationProgress."Cycle Quantity" := 0;
        MESOperationProgress."Scrap Quantity" := 0;
        MESOperationProgress."Total Produced Quantity" := 0;
        MESOperationProgress."Operator Id" := UserId;
        MESOperationProgress.Insert(true);
        EnsureUserExecutionInteraction(executionId);
    end;

    procedure InsertOperationStatus(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        status: Enum "MES Operation Status"
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation State";
    begin
        GetExecution(machineNo, prodOrderNo, operationNo, MESExecution);

        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := MESExecution."Execution Id";
        MESOperationStatus."Operation Status" := status;
        MESOperationStatus."Operator Id" := UserId;
        MESOperationStatus.Insert(true);
        EnsureUserExecutionInteraction(MESExecution."Execution Id");
        if status in [
            "MES Operation Status"::Finished,
            "MES Operation Status"::Cancelled
        ] then begin
            MESExecution."End Time" := CurrentDateTime();
            MESExecution.Modify(true);
        end;
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

    procedure InsertStartOperationRecords(prodOrderNo: Code[20]; operationNo: Code[10]; machineNo: Code[20]): Code[50]
    var
        ExecutionId: Code[50];
    begin
        ExecutionId := InsertMESOperationExecution(prodOrderNo, operationNo, machineNo);
        InsertMESOperation(ExecutionId);
        InsertMESOperationProgression(ExecutionId, prodOrderNo, machineNo);
        InsertStartMESMachineStatus(prodOrderNo, machineNo);
        exit(ExecutionId);
    end;

    procedure InsertNewProgressionCycle(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
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
        NewMESOperationProgress."Operator Id" := UserId;
        NewMESOperationProgress."Cycle Quantity" := input;
        NewMESOperationProgress."Total Produced Quantity" := MESOperationProgress."Total Produced Quantity" + input;
        NewMESOperationProgress."Scrap Quantity" := 0;
        NewMESOperationProgress.Insert(true);
        EnsureUserExecutionInteraction(MESExecution."Execution Id");
    end;


    procedure InsertScrapRecord(
    executionId: Code[50];
    scrapCode: Code[10];
    description: Text;
    quantity: Decimal
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
        MESScrap."Operator Id" := UserId;

        // Populate scrap description from BC Scrap table if code provided
        if scrapCode <> '' then
            if ScrapRec.Get(scrapCode) then
                MESScrap."scrap Description" := CopyStr(ScrapRec.Description, 1, 100);

        MESScrap.Insert(true);  // OnInsert auto-sets Id (GUID) and Declared At

        EnsureUserExecutionInteraction(executionId);
        GetLatestProgression(executionId, MESOperationProgress);

        NewMESOperationProgress.Init();
        NewMESOperationProgress."Execution Id" := executionId;
        NewMESOperationProgress."Operator Id" := UserId;
        NewMESOperationProgress."Cycle Quantity" := 0;
        NewMESOperationProgress."Scrap Quantity" := quantity;
        NewMESOperationProgress."Total Produced Quantity" := MESOperationProgress."Total Produced Quantity";
        // Total produced stays the same — scrap is not good output
        NewMESOperationProgress.Insert(true);
    end;

    procedure GetExecution(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; var MESExecution: Record "MES Operation Execution")
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        MESExecution.FindFirst();
    end;

    procedure GetLatestProgression(executionId: Code[50]; var MESOperationProgress: Record "MES Operation Progression")
    begin
        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey("Execution Id", "Last Updated At");
        MESOperationProgress.SetRange("Execution Id", executionId);
        MESOperationProgress.Ascending(false);
        MESOperationProgress.FindFirst();
    end;



    // Registers that the current BC session user touched this execution.
    // Uses Get + Insert pattern so duplicate PK rows are never created.
    procedure EnsureUserExecutionInteraction(executionId: Code[50])
    var
        MESUEI: Record "MES User Execution Interaction";
        CurrentUserId: Code[50];
    begin
        CurrentUserId := UserId;   // BC built-in; returns the current session user

        if MESUEI.Get(executionId, CurrentUserId) then
            exit;   // already recorded — nothing to do

        MESUEI.Init();
        MESUEI."Execution Id" := executionId;
        MESUEI."User Id" := CurrentUserId;
        MESUEI.Insert(true);
    end;
}
