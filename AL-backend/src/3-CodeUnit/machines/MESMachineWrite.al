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
    /// Returns empty string and sets errorMessage if validation fails.
    local procedure TryResolveUser(token: Text; var mesUserId: Code[50]; var errorMessage: Text): Boolean
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
    begin
        if not AuthMgt.ValidateToken(token, U, T, errorMessage) then begin
            //errorMessage := 'Unauthorized. Invalid or expired token.';
            exit(false);
        end;
        AuthMgt.TouchToken(T);
        mesUserId := U."User Id";
        exit(true);
    end;

    /// Builds a failure JSON response and returns it.
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
        ResultJson: JsonObject;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ClearLastError();

        if MachineValidation.TryStartOperation(prodOrderNo, operationNo, machineNo) then begin
            MachineInsert.InsertStartOperationRecords(prodOrderNo, operationNo, machineNo, operatorId);
            ResultJson.Add('value', true);
        end else begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', GetLastErrorText());
        end;

        exit(JsonHelper.JsonToText(ResultJson));
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
        ResultJson: JsonObject;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ClearLastError();

        if MachineValidation.TryDeclareProduction(machineNo, prodOrderNo, operationNo, input) then begin
            MachineInsert.InsertNewProgressionCycle(machineNo, prodOrderNo, operationNo, input, operatorId, declaredById);
            ResultJson.Add('value', true);
        end else begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', GetLastErrorText());
        end;

        exit(JsonHelper.JsonToText(ResultJson));
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
    begin
        if not TryResolveUser(token, MesUserId, ErrorMessage) then
            exit(BuildFailureResponse(ErrorMessage));

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
        input: Text;
    begin
        input := token + ' ||' + machineNo + ' ||' + prodOrderNo + ' ||' + operationNo;
        if not TryResolveUser(token, MesUserId, ErrorMessage) then begin
            ErrorMessage := ErrorMessage + input;
            exit(BuildFailureResponse(ErrorMessage));
        end;

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
        ResultJson: JsonObject;
        ScansArr: JsonArray;
        ScanToken: JsonToken;
        ScanObj: JsonObject;
        ItemNoToken: JsonToken;
        BarcodeToken: JsonToken;
        QtyScannedToken: JsonToken;
        ItemNo: Code[20];
        QtyScanned: Decimal;
    begin
        if not MESExecution.Get(executionId) then begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', 'Execution not found');
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        ScansArr.ReadFrom(scansJson);

        foreach ScanToken in ScansArr do begin
            Clear(MESConsumption);
            ScanObj := ScanToken.AsObject();

            ScanObj.Get('itemNo', ItemNoToken);
            ScanObj.Get('barcode', BarcodeToken);
            ScanObj.Get('quantityScanned', QtyScannedToken);

            ItemNo := CopyStr(ItemNoToken.AsValue().AsText(), 1, 20);
            QtyScanned := QtyScannedToken.AsValue().AsDecimal();

            MESConsumption.Init();
            MESConsumption."Execution Id" := executionId;
            MESConsumption."Prod Order No" := MESExecution."Prod Order No";
            MESConsumption."Item No" := ItemNo;
            MESConsumption.Barcode := BarcodeToken.AsValue().AsText();
            MESConsumption."Quantity Scanned" := QtyScanned;
            MESConsumption."Operator Id" := operatorId;
            MESConsumption."Declared By" := declaredById;
            MESConsumption.Insert(true);
        end;

        MachineInsert.EnsureUserExecutionInteraction(executionId, operatorId);

        ResultJson.Add('value', true);
        ResultJson.Add('message', 'Inserted successfully');
        exit(JsonHelper.JsonToText(ResultJson));
    end;

    procedure declareScrap(
       executionId: Code[50];
       description: Text;
       scrapCode: Code[10];
       quantity: Decimal;
       operatorId: Code[50];
       declaredById: Code[50]
   ): Text
    var
        ResultJson: JsonObject;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ClearLastError();

        if MachineValidation.TryDeclareScrap(executionId, scrapCode, quantity) then begin
            MachineInsert.InsertScrapRecord(executionId, scrapCode, description, quantity, operatorId, declaredById);
            ResultJson.Add('value', true);
        end else begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', GetLastErrorText());
        end;

        exit(JsonHelper.JsonToText(ResultJson));
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
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
        MESOperationStatus: Record "MES Operation State";
    begin
        ClearLastError();

        case targetStatus of
            MESOperationStatus."Operation Status"::Finished:
                Success := MachineValidation.TryCloseOperation(machineNo, prodOrderNo, operationNo);
            MESOperationStatus."Operation Status"::Cancelled:
                Success := MachineValidation.TryCloseOperation(machineNo, prodOrderNo, operationNo);
            MESOperationStatus."Operation Status"::Paused:
                Success := MachineValidation.TryPauseOperation(machineNo, prodOrderNo, operationNo);
            MESOperationStatus."Operation Status"::Running:
                Success := MachineValidation.TryResumeOperation(machineNo, prodOrderNo, operationNo);
        end;

        if Success then begin
            MachineInsert.InsertOperationStatus(machineNo, prodOrderNo, operationNo, targetStatus, mesUserId);
            if targetStatus = MESOperationStatus."Operation Status"::Running then
                MachineInsert.InsertStartMESMachineStatus(prodOrderNo, machineNo)
            else
                MachineInsert.InsertIdleMachineStatus(machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonHelper.JsonToText(ResultJson));
    end;
}
