/// Orchestrates write operations for MES machine executions.
/// Every public procedure validates the incoming session token first,
/// resolves the MES User Id from it, then delegates to the insert layer.
codeunit 50132 "MES Machine Write"
{
    Access = Internal;

    var
        AuthMgt: Codeunit "MES Auth Mgt";

    // ──────────────────────────────────────────────
    // Token resolution helpers
    // ──────────────────────────────────────────────

    /// Validates the token and returns the authenticated MES User Id.
    /// Returns false and sets errorMessage if validation fails.
    local procedure TryResolveUser(token: Text; var mesUserId: Code[50]; var errorMessage: Text): Boolean
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
    begin
        if not AuthMgt.ValidateToken(token, U, T, errorMessage) then
            exit(false);
        AuthMgt.TouchToken(T);
        mesUserId := U."User Id";
        exit(true);
    end;

    // ──────────────────────────────────────────────
    // JSON response builders
    // ──────────────────────────────────────────────

    local procedure BuildSuccessResponse(): Text
    var
        ResultJson: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ResultJson.Add('value', true);
        exit(JsonHelper.JsonToText(ResultJson));
    end;

    local procedure BuildFailureResponse(message: Text): Text
    var
        ResultJson: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ResultJson.Add('value', false);
        ResultJson.Add('message', message);
        exit(JsonHelper.JsonToText(ResultJson));
    end;

    // ──────────────────────────────────────────────
    // Write procedures — each validates token first
    // ──────────────────────────────────────────────

    procedure startOperation(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20];
        operatorId: Code[50]
    ): Text
    var
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        ClearLastError();

        if not MachineValidation.TryStartOperation(prodOrderNo, operationNo, machineNo) then
            exit(BuildFailureResponse(GetLastErrorText()));

        MachineInsert.InsertStartOperationRecords(prodOrderNo, operationNo, machineNo, operatorId);
        exit(BuildSuccessResponse());
    end;

    procedure declareProduction(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        input: Decimal;
        operatorId: Code[50];
        declaredById: Code[50]
    ): Text
    var
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        ClearLastError();

        if not MachineValidation.TryDeclareProduction(machineNo, prodOrderNo, operationNo, input) then
            exit(BuildFailureResponse(GetLastErrorText()));

        MachineInsert.InsertNewProgressionCycle(machineNo, prodOrderNo, operationNo, input, operatorId, declaredById);
        exit(BuildSuccessResponse());
    end;

    procedure finishOperation(
        token: Text;
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
        MesUserId: Code[50];
        ErrorMessage: Text;
    begin
        if not TryResolveUser(token, MesUserId, ErrorMessage) then
            exit(BuildFailureResponse(ErrorMessage));

        exit(ExecuteOperationTransition(
            machineNo, prodOrderNo, operationNo,
            MESOperationStatus."Operation Status"::Finished,
            MesUserId));
    end;

    procedure cancelOperation(
        token: Text;
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
        MesUserId: Code[50];
        ErrorMessage: Text;
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        if not TryResolveUser(token, MesUserId, ErrorMessage) then
            exit(BuildFailureResponse(ErrorMessage));

        // If the operation was never started, bootstrap it directly as Cancelled.
        if not MachineInsert.ExecutionExists(machineNo, prodOrderNo, operationNo) then
            exit(ExecuteCancelUnstartedOperation(prodOrderNo, operationNo, machineNo, MesUserId));

        exit(ExecuteOperationTransition(
            machineNo, prodOrderNo, operationNo,
            MESOperationStatus."Operation Status"::Cancelled,
            MesUserId));
    end;

    procedure pauseOperation(
        token: Text;
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
        MesUserId: Code[50];
        ErrorMessage: Text;
    begin
        if not TryResolveUser(token, MesUserId, ErrorMessage) then
            exit(BuildFailureResponse(ErrorMessage));

        exit(ExecuteOperationTransition(
            machineNo, prodOrderNo, operationNo,
            MESOperationStatus."Operation Status"::Paused,
            MesUserId));
    end;

    procedure resumeOperation(
        token: Text;
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
        MesUserId: Code[50];
        ErrorMessage: Text;
    begin
        if not TryResolveUser(token, MesUserId, ErrorMessage) then
            exit(BuildFailureResponse(ErrorMessage));

        exit(ExecuteOperationTransition(
            machineNo, prodOrderNo, operationNo,
            MESOperationStatus."Operation Status"::Running,
            MesUserId));
    end;

    procedure insertScans(
        executionId: Code[50];
        scansJson: Text;
        operatorId: Code[50];
        declaredById: Code[50]
    ): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESConsumption: Record "MES Component Consumption";
        JsonHelper: Codeunit "MES Json Helper";
        MachineInsert: Codeunit "MES Machine Insert";
        ScansArr: JsonArray;
        ScanToken: JsonToken;
        ScanObj: JsonObject;
        ItemNoToken: JsonToken;
        BarcodeToken: JsonToken;
        QtyScannedToken: JsonToken;
        UnitOfMeasureToken: JsonToken;
        QuantityPerUnitOfMeasureToken: JsonToken;
    begin
        if not MESExecution.Get(executionId) then
            exit(BuildFailureResponse('Execution not found'));

        ScansArr.ReadFrom(scansJson);

        foreach ScanToken in ScansArr do begin
            Clear(MESConsumption);
            ScanObj := ScanToken.AsObject();

            ScanObj.Get('itemNo', ItemNoToken);
            ScanObj.Get('barcode', BarcodeToken);
            ScanObj.Get('quantityScanned', QtyScannedToken);
            ScanObj.Get('unitOfMeasure', UnitOfMeasureToken);
            ScanObj.Get('quantityPerUnitOfMeasure', QuantityPerUnitOfMeasureToken);

            MESConsumption.Init();
            MESConsumption."Execution Id" := executionId;
            MESConsumption."Prod Order No" := MESExecution."Prod Order No";
            MESConsumption."Item No" := CopyStr(ItemNoToken.AsValue().AsText(), 1, 20);
            MESConsumption.Barcode := BarcodeToken.AsValue().AsText();
            MESConsumption."Quantity Scanned" := QtyScannedToken.AsValue().AsDecimal();
            MESConsumption."Unit of Measure" := CopyStr(UnitOfMeasureToken.AsValue().AsText(), 1, 10);
            MESConsumption."Quantity per Unit of Measure" := QuantityPerUnitOfMeasureToken.AsValue().AsDecimal();
            MESConsumption."Operator Id" := operatorId;
            MESConsumption."Declared By" := declaredById;
            MESConsumption.Insert(true);
        end;

        MachineInsert.EnsureUserExecutionInteraction(executionId, operatorId);

        exit(BuildSuccessResponse());
    end;

    procedure declareScrap(
        executionId: Code[50];
        description: Text;
        scrapCode: Code[10];
        quantity: Decimal;
        operatorId: Code[50];
        declaredById: Code[50];
        materialId: Code[20]
    ): Text
    var
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
    begin
        ClearLastError();

        if not MachineValidation.TryDeclareScrap(executionId, scrapCode, quantity) then
            exit(BuildFailureResponse(GetLastErrorText()));

        MachineInsert.InsertScrapRecord(executionId, scrapCode, description, quantity, operatorId, declaredById, materialId);
        exit(BuildSuccessResponse());
    end;

    // ──────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────

    /// Shared state-transition logic for finish/cancel/pause/resume.
    local procedure ExecuteOperationTransition(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        targetStatus: Enum "MES Operation Status";
        mesUserId: Code[50]
    ): Text
    var
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        MESOperationStatus: Record "MES Operation State";
    begin
        ClearLastError();

        case targetStatus of
            MESOperationStatus."Operation Status"::Finished,
            MESOperationStatus."Operation Status"::Cancelled:
                if not MachineValidation.TryCloseOperation(machineNo, prodOrderNo, operationNo) then
                    exit(BuildFailureResponse(GetLastErrorText()));
            MESOperationStatus."Operation Status"::Paused:
                if not MachineValidation.TryPauseOperation(machineNo, prodOrderNo, operationNo) then
                    exit(BuildFailureResponse(GetLastErrorText()));
            MESOperationStatus."Operation Status"::Running:
                if not MachineValidation.TryResumeOperation(machineNo, prodOrderNo, operationNo) then
                    exit(BuildFailureResponse(GetLastErrorText()));
        end;

        MachineInsert.InsertOperationStatus(machineNo, prodOrderNo, operationNo, targetStatus, mesUserId);

        if targetStatus = MESOperationStatus."Operation Status"::Running then
            MachineInsert.InsertStartMESMachineStatus(prodOrderNo, machineNo)
        else
            MachineInsert.InsertIdleMachineStatus(machineNo);

        exit(BuildSuccessResponse());
    end;

    /// Bootstraps all records for an operation that was never started, then immediately cancels it.
    local procedure ExecuteCancelUnstartedOperation(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20];
        mesUserId: Code[50]
    ): Text
    var
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        MESOperationStatus: Record "MES Operation State";
    begin
        ClearLastError();

        if not MachineValidation.TryCancelOperationBeforeStart(prodOrderNo, operationNo, machineNo) then
            exit(BuildFailureResponse(GetLastErrorText()));

        MachineInsert.InsertStartOperationRecords(prodOrderNo, operationNo, machineNo, mesUserId);
        MachineInsert.InsertOperationStatus(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Cancelled, mesUserId);
        
        exit(BuildSuccessResponse());
    end;
}
