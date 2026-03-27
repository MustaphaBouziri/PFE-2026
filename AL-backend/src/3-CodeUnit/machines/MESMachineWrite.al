codeunit 50132 "MES Machine Write"
{
    Access = Internal;

    procedure startOperation(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ClearLastError();

        Success := MachineValidation.TryStartOperation(prodOrderNo, operationNo, machineNo);

        if Success then begin
            MachineInsert.InsertStartOperationRecords(prodOrderNo, operationNo, machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonHelper.JsonToText(ResultJson));
    end;

    procedure declareProduction(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        ClearLastError();

        Success := MachineValidation.TryDeclareProduction(machineNo, prodOrderNo, operationNo, input);

        if Success then begin
            MachineInsert.InsertNewProgressionCycle(machineNo, prodOrderNo, operationNo, input);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonHelper.JsonToText(ResultJson));
    end;

    local procedure ExecuteOperationTransition(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; targetStatus: Enum "MES Operation Status"): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MachineValidation: Codeunit "MES Machine Validation";
        MachineInsert: Codeunit "MES Machine Insert";
        JsonHelper: Codeunit "MES Json Helper";
        MESOperationStatus: Record "MES Operation Status";
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
            MachineInsert.InsertOperationStatus(machineNo, prodOrderNo, operationNo, targetStatus);
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

    procedure finishOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation Status";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Finished));
    end;

    procedure cancelOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation Status";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Cancelled));
    end;

    procedure pauseOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation Status";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Paused));
    end;

    procedure resumeOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation Status";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Running));
    end;

    //insert scans into the mes Component table


    procedure insertScans(
     executionId: Code[50];
     scansJson: Text
 ): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESConsumption: Record "MES Component Consumption";
        JsonHelper: Codeunit "MES Json Helper";

        ResultJson: JsonObject;
        ScansArr: JsonArray;
        ScanToken: JsonToken;
        ScanObj: JsonObject;

        ItemNoToken: JsonToken;
        BarcodeToken: JsonToken;
        UOMToken: JsonToken;
        QtyScannedToken: JsonToken;

        ItemNo: Code[20];
        UOMCode: Code[10];
        QtyScanned: Decimal;
        LineNo: Integer;
    begin

        if not MESExecution.Get(executionId) then begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', 'Execution not found');
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        ScansArr.ReadFrom(scansJson);

        foreach ScanToken in ScansArr do begin
            ScanObj := ScanToken.AsObject();

            ScanObj.Get('itemNo', ItemNoToken);
            ScanObj.Get('barcode', BarcodeToken);
            ScanObj.Get('unitOfMeasure', UOMToken);
            ScanObj.Get('quantityScanned', QtyScannedToken);

            ItemNo := CopyStr(ItemNoToken.AsValue().AsText(), 1, 20);
            UOMCode := CopyStr(UOMToken.AsValue().AsText(), 1, 10);
            QtyScanned := QtyScannedToken.AsValue().AsDecimal();


            MESConsumption.Init();
            MESConsumption."Execution Id" := executionId;
            MESConsumption."Prod Order No" := MESExecution."Prod Order No";
            MESConsumption."Item No" := ItemNo;
            MESConsumption.Barcode := BarcodeToken.AsValue().AsText();
            MESConsumption."Unit of Measure" := UOMCode;
            MESConsumption."Quantity Scanned" := QtyScanned;
            MESConsumption."Operator Id" := UserId;

            MESConsumption.Insert(true);
        end;

        ResultJson.Add('value', true);
        ResultJson.Add('message', 'Inserted successfully');

        exit(JsonHelper.JsonToText(ResultJson));
    end;

}
