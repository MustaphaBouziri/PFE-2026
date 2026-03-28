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
        MESOperationStatus: Record "MES Operation State";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Finished));
    end;

    procedure cancelOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Cancelled));
    end;

    procedure pauseOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
    begin
        exit(ExecuteOperationTransition(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Paused));
    end;

    procedure resumeOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        MESOperationStatus: Record "MES Operation State";
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
        ScansArr: JsonArray;//[{}]the array that hold the array of scans objs from he input
        ScanToken: JsonToken;//used to iterate over the array,jsonTocken is a generic representation of any json element object array value... act like a cursor
        ScanObj: JsonObject;//{} jsonObkect we extract from each token to access the fields
       
       // imagin these like blank paper with no type
       //using a token allows us to later ask ''what type is this?'' and convert it
        ItemNoToken: JsonToken;
        BarcodeToken: JsonToken;
        UOMToken: JsonToken;
        QtyScannedToken: JsonToken;
        // variables that will hold the converted token into a jsonValue=> asText as DECIMAL...
        ItemNo: Code[20];
        QtyScanned: Decimal;
        LineNo: Integer;
    begin
         /**
         request look like :
            {
              "executionId": "EX123",
              "scansJson": "[{\"itemNo\":\"A1\",\"quantity\":5},{\"itemNo\":\"B2\",\"quantity\":10}]"
            }
         */

       //  first we check if the execution id exist
        if not MESExecution.Get(executionId) then begin
            ResultJson.Add('value', false);
            ResultJson.Add('message', 'Execution not found');
            exit(JsonHelper.JsonToText(ResultJson));
        end;
        //convert the string "[{\"itemNo\":\"A1\",\"quantity\":5},{\"itemNo\":\"B2\",\"quantity\":10}]"
        //to jsonArray [  { "itemNo": "A1", "quantity": 5 },{}]
        ScansArr.ReadFrom(scansJson);

        // we iterate over each scan in the array 
        foreach ScanToken in ScansArr do begin
            Clear(MESConsumption);

            //convert the scanToken into a jsonObject { "itemNo": "A1", "quantity": 5 }
            ScanObj := ScanToken.AsObject();

            //and as i said token bcz the json value could be of any type and then we decide what type the value will be .
            // get the value associated with the key into the json token = itemNo value insert it to ItemNoToken
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
            MESConsumption."Operator Id" := UserId;

            MESConsumption.Insert(true);
        end;

        ResultJson.Add('value', true);
        ResultJson.Add('message', 'Inserted successfully');

        exit(JsonHelper.JsonToText(ResultJson));
    end;

}
