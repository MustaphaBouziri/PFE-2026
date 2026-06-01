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
        if status in ["MES Operation Status"::Finished, "MES Operation Status"::Cancelled,"MES Operation Status"::Interrupted] then begin
            MESExecution."End Time" := CurrentDateTime();
            MESExecution.Modify(true);
        end;
    end;



    // check if this is the first operation in the routing
    procedure IsFirstOperation(prodOrderNo: Code[20]; operationNo: Code[10]): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", operationNo);
        if not ProdOrderRoutingLine.FindFirst() then
            exit(false);

        // If previous pperation No. is empty, this is the first operation
        exit(ProdOrderRoutingLine."Previous Operation No." = '');
    end;

 // set order to finish in erp
      procedure SetErpOrderToFinish(
    prodOrderNo: Code[20];
    operationNo: Code[10];
    mesOperationStatus: Enum "MES Operation Status"
)
    var
        ProdOrder: Record "Production Order";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        // get the production order only if it is currently released
        ProdOrder.Reset();
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange("No.", prodOrderNo);

        if not ProdOrder.FindFirst() then
            exit; // order not found or not released 

        // rule 1:
        // if the first operation is cancelled -> finish the production order
        if IsFirstOperation(prodOrderNo, operationNo) and
           (mesOperationStatus in [
               "MES Operation Status"::Cancelled,
               "MES Operation Status"::Interrupted
           ])
        then begin
            ProdOrderStatusMgt.ChangeProdOrderStatus(
                ProdOrder,
                ProdOrder.Status::Finished,
                Today(),
                false
            );
            exit;
        end;

        // rule 2:
        // ff the last operation is finished or cancelled-> finish the production order
        if IsLastOperation(prodOrderNo, operationNo) and
           (mesOperationStatus in [
               "MES Operation Status"::Finished,
               "MES Operation Status"::Cancelled,
               "MES Operation Status"::Interrupted
           ])
        then begin
            ProdOrderStatusMgt.ChangeProdOrderStatus(
                ProdOrder,
                ProdOrder.Status::Finished,
                Today(),
                false
            );
            exit;
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
    procedure InsertMESOperationProgression(executionId: Code[50]; mesUserId: Code[50])
    var
        MESOperationProgress: Record "MES Operation Progression";
    begin
        MESOperationProgress.Init();
        MESOperationProgress."Execution Id" := executionId;
        MESOperationProgress."Cycle Quantity" := 0;
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
        NewMESOperationProgress.Insert(true);

        // if this is the last operation increase this item  inventory
        if IsLastOperation(prodOrderNo, operationNo) then
            IncreaseItemInventory(MESExecution."Item No", input, MESExecution."Execution Id");
//aizen twise ??
        EnsureUserExecutionInteraction(MESExecution."Execution Id", operatorId);
        EnsureUserExecutionInteraction(MESExecution."Execution Id", declaredById);
    end;

    // Check if this operation is the last one in the production order routing line 
    procedure IsLastOperation(prodOrderNo: Code[20]; operationNo: Code[10]): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", operationNo);
        if not ProdOrderRoutingLine.FindFirst() then
            exit(false);

        // if Next Operation No is empty this is the last operation
        exit(ProdOrderRoutingLine."Next Operation No." = '');// true false 
    end;

    // increase item inventory



procedure IncreaseItemInventory(
        itemNo: Code[20];
        quantity: Decimal;
        executionId: Code[50]
    )
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
        DocumentNo: Code[20];
        LineNo: Integer;
        TemplateNameToUse: Code[10];
        BatchNameToUse: Code[10];
    begin
        if not Item.Get(itemNo) then
            Error('Item %1 was not found in the Item table.', itemNo);

        // find the first available journal batch
        ItemJournalBatch.Reset();
        ItemJournalBatch.SetRange("Journal Template Name", 'ARTICLE');
        if not ItemJournalBatch.FindFirst() then
            Error('No Item Journal Batch found for template ARTICLE');

        TemplateNameToUse := ItemJournalBatch."Journal Template Name";
        BatchNameToUse := ItemJournalBatch.Name;

        // get the next document number from the batch's number series
        DocumentNo := NoSeriesManagement.GetNextNo(ItemJournalBatch."No. Series", Today(), false);

        // find the next available line number
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", TemplateNameToUse);
        ItemJournalLine.SetRange("Journal Batch Name", BatchNameToUse);
        if ItemJournalLine.FindLast() then
            LineNo := ItemJournalLine."Line No." + 10000
        else
            LineNo := 10000;

        // create item journal line
        Clear(ItemJournalLine);
        ItemJournalLine.Init();

        ItemJournalLine."Journal Template Name" := TemplateNameToUse;
        ItemJournalLine."Journal Batch Name" := BatchNameToUse;
        ItemJournalLine."Line No." := LineNo;
        ItemJournalLine."Posting Date" := Today();
        ItemJournalLine."Document No." := DocumentNo;
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt."; // ← Positive for finished goods
        ItemJournalLine."Item No." := itemNo;
        ItemJournalLine.Description := Item.Description;
        ItemJournalLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ItemJournalLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        ItemJournalLine."Inventory Posting Group" := Item."Inventory Posting Group";

        // set quantity and we need to validate it else wont work
        ItemJournalLine.Quantity := quantity;
        ItemJournalLine.Validate("Quantity");
        ItemJournalLine.Validate("Unit of Measure Code");

        ItemJournalLine.Insert(true);

        // post the journal line
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", TemplateNameToUse);
        ItemJournalLine.SetRange("Journal Batch Name", BatchNameToUse);
        ItemJournalLine.SetRange("Line No.", LineNo);

        if ItemJournalLine.FindSet() then
            ItemJournalPostBatch.Run(ItemJournalLine);
    end;

/*procedure IncreaseItemInventory(
    itemNo: Code[20];
    quantity: Decimal;
    executionId: Code[50]
)
var
    Item: Record Item;
    MESExecution: Record "MES Operation Execution";
    ProdOrder: Record "Production Order";
    ProdOrderLine: Record "Prod. Order Line";
    ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    ItemJournalLine: Record "Item Journal Line";
    ItemJournalBatch: Record "Item Journal Batch";
    ItemLedgerEntry: Record "Item Ledger Entry";
    ItemJournalPostLine: Codeunit "Item Jnl.-Post Line";
    LineNo: Integer;
    TemplateNameToUse: Code[10];
    BatchNameToUse: Code[10];
    ProdOrderNo: Code[20];
begin
    if quantity <= 0 then
        Error('Quantity must be greater than 0.');

    if not Item.Get(itemNo) then
        Error(
            'Item %1 was not found.',
            itemNo);

    if not MESExecution.Get(executionId) then
        Error(
            'Execution %1 was not found.',
            executionId);

    ProdOrderNo := MESExecution."Prod Order No";

    // production order
    ProdOrder.Reset();
    ProdOrder.SetRange("No.", ProdOrderNo);

    if not ProdOrder.FindFirst() then
        Error(
            'Production Order %1 was not found.',
            ProdOrderNo);

    if ProdOrder.Status <> ProdOrder.Status::Released then
        Error(
            'Production Order %1 must be Released.',
            ProdOrderNo);

    // batch
    if not ItemJournalBatch.Get('ARTICLE', 'MES') then begin
        ItemJournalBatch.Init();
        ItemJournalBatch."Journal Template Name" := 'ARTICLE';
        ItemJournalBatch.Name := 'MES';
        ItemJournalBatch.Description := 'MES Article Journal';
        ItemJournalBatch.Insert(true);
    end;

    TemplateNameToUse := 'ARTICLE';
    BatchNameToUse := 'MES';

    // cleanup old lines
    ItemJournalLine.Reset();

    ItemJournalLine.SetRange(
        "Journal Template Name",
        TemplateNameToUse);

    ItemJournalLine.SetRange(
        "Journal Batch Name",
        BatchNameToUse);

    if ItemJournalLine.FindSet() then
        ItemJournalLine.DeleteAll();

    // line no
    ItemJournalLine.Reset();

    ItemJournalLine.SetRange(
        "Journal Template Name",
        TemplateNameToUse);

    ItemJournalLine.SetRange(
        "Journal Batch Name",
        BatchNameToUse);

    if ItemJournalLine.FindLast() then
        LineNo := ItemJournalLine."Line No." + 10000
    else
        LineNo := 10000;

    // prod order line
    ProdOrderLine.Reset();

    ProdOrderLine.SetRange(
        Status,
        ProdOrder.Status);

    ProdOrderLine.SetRange(
        "Prod. Order No.",
        ProdOrderNo);

    ProdOrderLine.SetRange(
        "Item No.",
        itemNo);

    if not ProdOrderLine.FindFirst() then
        Error(
            'No production order line found for item %1.',
            itemNo);

    // routing
    ProdOrderRoutingLine.Reset();

    ProdOrderRoutingLine.SetRange(
        Status,
        ProdOrder.Status);

    ProdOrderRoutingLine.SetRange(
        "Prod. Order No.",
        ProdOrderNo);

    ProdOrderRoutingLine.SetRange(
        "Routing Reference No.",
        ProdOrderLine."Line No.");

    if not ProdOrderRoutingLine.FindFirst() then
        Error(
            'No routing line found for production order %1.',
            ProdOrderNo);

    // create line
    Clear(ItemJournalLine);

    ItemJournalLine.Init();

    ItemJournalLine."Journal Template Name" :=
        TemplateNameToUse;

    ItemJournalLine."Journal Batch Name" :=
        BatchNameToUse;

    ItemJournalLine."Line No." := LineNo;

    ItemJournalLine.Validate(
        "Posting Date",
        Today());

    ItemJournalLine.Validate(
        "Entry Type",
        ItemJournalLine."Entry Type"::Output);

    ItemJournalLine."Document No." := 'MES';

    ItemJournalLine.Validate(
        "Item No.",
        itemNo);

    ItemJournalLine.Validate(
        "Order Type",
        ItemJournalLine."Order Type"::Production);

    ItemJournalLine.Validate(
        "Order No.",
        ProdOrderNo);

    ItemJournalLine.Validate(
        "Order Line No.",
        ProdOrderLine."Line No.");

    ItemJournalLine.Validate(
        "Operation No.",
        ProdOrderRoutingLine."Operation No.");

    if ProdOrder."Location Code" <> '' then
        ItemJournalLine.Validate(
            "Location Code",
            ProdOrder."Location Code");

    // quantity
    ItemJournalLine.Validate(
        "Output Quantity",
        quantity);

    ItemJournalLine.Insert(true);

    // validations before posting
    if ItemJournalLine."Operation No." = '' then
        Error('Operation No is empty.');

    if ItemJournalLine."Order No." = '' then
        Error('Order No is empty.');

    if ItemJournalLine."Order Line No." = 0 then
        Error('Order Line No is empty.');

    if ItemJournalLine."Output Quantity" <= 0 then
        Error('Output quantity invalid.');

    // post line
    ItemJournalPostLine.RunWithCheck(ItemJournalLine);

    // verify ledger entry created
    ItemLedgerEntry.Reset();

    ItemLedgerEntry.SetRange(
        "Item No.",
        itemNo);

    if not ItemLedgerEntry.FindLast() then
        Error(
            'No Item Ledger Entry exists for item %1.',
            itemNo);

    Error(
        'SUCCESS\\' +
        'Entry No=%1\\' +
        'Quantity=%2\\' +
        'Remaining Quantity=%3',
        ItemLedgerEntry."Entry No.",
        ItemLedgerEntry.Quantity,
        ItemLedgerEntry."Remaining Quantity");
end;*/
    // ──────────────────────────────────────────────
    // Scrap records
    // ──────────────────────────────────────────────

    /// Records a scrap declaration against the execution.
    procedure InsertScrapRecord(
        executionId: Code[50];
        scrapCode: Code[10];
        description: Text;
        quantity: Decimal;
        operatorId: Code[50];
        declaredById: Code[50];
        materialId: Code[20]
    )
    var
        MESScrap: Record "MES Operation Scrap";
        ScrapRec: Record Scrap;
    begin
        EnsureUserExecutionInteraction(executionId, operatorId);
        if (declaredById <> '') and (declaredById <> operatorId) then
            EnsureUserExecutionInteraction(executionId, declaredById);

        MESScrap.Init();
        MESScrap."Execution Id" := executionId;
        MESScrap."Scrap Quantity" := quantity;
        MESScrap."Scrap Code" := scrapCode;
        MESScrap."scrap notes" := CopyStr(description, 1, 256);
        MESScrap."Operator Id" := operatorId;
        MESScrap."Declared By" := declaredById;
        MESScrap."Material Id" := materialId;

        if (scrapCode <> '') and ScrapRec.Get(scrapCode) then
            MESScrap."scrap Description" := CopyStr(ScrapRec.Description, 1, 100);

        MESScrap.Insert(true);
    end;

    // ──────────────────────────────────────────────
    // Composite helpers
    // ──────────────────────────────────────────────

    /// Orchestrates all inserts required to start a fresh operation. (inisual info working, default value etc )
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


// return thr total produced quantity used in the validation layer to check send ahead quanity =
    procedure GetPreviousOperationProducedQuantity(executionId: Code[50]): Decimal
    var
        MESOperationProgress: Record "MES Operation Progression";
    begin
        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey("Execution Id", "Declared At");
        MESOperationProgress.SetRange("Execution Id", executionId);
        MESOperationProgress.Ascending(false);

        if MESOperationProgress.FindFirst() then
            exit(MESOperationProgress."Total Produced Quantity")
        else
            exit(0);
    end;

    procedure GetLatestOperationStatus(executionId: Code[50]; var MESOperationState: Record "MES Operation State")
    begin
        MESOperationState.Reset();
        MESOperationState.SetCurrentKey("Execution Id", "Declared At");
        MESOperationState.SetRange("Execution Id", executionId);
        MESOperationState.Ascending(false);
        MESOperationState.FindFirst();
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

// aizen this check ig the execution already exist by not in validation
    procedure ExecutionExists(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Boolean
    var
        MESExecution: Record "MES Operation Execution";
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        exit(not MESExecution.IsEmpty());
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
