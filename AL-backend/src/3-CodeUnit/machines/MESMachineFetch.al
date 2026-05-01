codeunit 50131 "MES Machine Fetch"
{
    Access = Internal;

    procedure FetchMachines(workCenterNoJson: Text): Text
var
    Machine: Record "Machine Center";
    MESMachineStatus: Record "MES Machine Status";
    MachineArr: JsonArray;
    MachineObj: JsonObject;
    JsonHelper: Codeunit "MES Json Helper";
    WorkCenter: Record "Work Center";

    workCenterNoArr: JsonArray;
    workCenterNoObj: JsonObject;
    workCenterNoToken: JsonToken;

    workCenterNo: Code[20];
    workCenterFilter: Text;
begin
  Message(workCenterNoJson);

    if workCenterNoJson = '' then
        Error('Request body is required');
    
    // our data rn : {"workCenterNos": ["100", "200"]}
   // convert text into json object
    workCenterNoObj.ReadFrom(workCenterNoJson);
    // we extract the field workCenterNos
    // get honi first variable is key and 2nd paramiter is the variable that will have the result 
    // go inside the jsonObjuect find the value of the key and store it in this variable
    if not workCenterNoObj.Get('workCenterNos', workCenterNoToken) then
        Error('workCenterNos is required');
    // converted to asArray cuz its token type meaning is white it need a label type
    workCenterNoArr := workCenterNoToken.AsArray();

    workCenterFilter := '';
    foreach workCenterNoToken in workCenterNoArr do begin
        workCenterNo := CopyStr(workCenterNoToken.AsValue().AsText(), 1, 20);

        if workCenterFilter = '' then
            workCenterFilter := workCenterNo
        else
            workCenterFilter += '|' + workCenterNo;
    end;

    Machine.SetFilter("Work Center No.", workCenterFilter);

    if Machine.FindSet() then
        repeat
            Clear(MachineObj);

            MachineObj.Add('machineNo', Machine."No.");
            MachineObj.Add('machineName', Machine."Name");
            MachineObj.Add('status', 'Idle');
            MachineObj.Add('currentOrder', '-');
            MachineObj.Add('workCenterNo', Machine."Work Center No.");

            if WorkCenter.Get(Machine."Work Center No.") then
                MachineObj.Add('workCenterName', WorkCenter.Name)
            else
                MachineObj.Add('workCenterName', '');

            MESMachineStatus.Reset();
            MESMachineStatus.SetCurrentKey("Machine No.", "Updated At");
            MESMachineStatus.SetRange("Machine No.", Machine."No.");
            MESMachineStatus.Ascending(false);

            if MESMachineStatus.FindFirst() then begin
                MachineObj.Replace('status', Format(MESMachineStatus.Status));
                MachineObj.Replace('currentOrder', MESMachineStatus."Current Prod. Order No.");
            end;

            MachineArr.Add(MachineObj);
        until Machine.Next() = 0;

    exit(JsonHelper.JsonToTextArr(MachineArr));
end;

    procedure getMachineOrders(machineNo: Text): Text
    var
        ProductOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductOrderLine: Record "Prod. Order Line";
        ProductOrderRoutingLineArr: JsonArray;
        ProductOrderRoutingLineObj: JsonObject;
        MESExecution: Record "MES Operation Execution";
        JsonHelper: Codeunit "MES Json Helper";
    begin
        if MachineNo = '' then Error('Machine Number is required');

        ProductOrderRoutingLine.SetRange(Type, ProductOrderRoutingLine.Type::"Machine Center");
        ProductOrderRoutingLine.SetRange("No.", MachineNo);

        ProductOrderRoutingLine.SetFilter(Status, '%1|%2|%3',
                                          ProductOrderRoutingLine.Status::Planned,
                                          ProductOrderRoutingLine.Status::"Firm Planned",
                                          ProductOrderRoutingLine.Status::Released);

        if ProductOrderRoutingLine.FindSet() then
            repeat
                MESExecution.Reset();
                MESExecution.SetRange("Prod Order No", ProductOrderRoutingLine."Prod. Order No.");
                MESExecution.SetRange("Operation No", ProductOrderRoutingLine."Operation No.");
                MESExecution.SetRange("Machine No", MachineNo);

                if not MESExecution.FindFirst() then begin
                    Clear(ProductOrderRoutingLineObj);

                    ProductOrderLine.Reset();
                    ProductOrderLine.SetRange("Prod. Order No.", ProductOrderRoutingLine."Prod. Order No.");

                    if ProductOrderLine.FindFirst() then begin
                        ProductOrderRoutingLineObj.Add('orderNo', ProductOrderRoutingLine."Prod. Order No.");
                        ProductOrderRoutingLineObj.Add('status', Format(ProductOrderRoutingLine.Status));
                        ProductOrderRoutingLineObj.Add('operationNo', ProductOrderRoutingLine."Operation No.");
                        ProductOrderRoutingLineObj.Add('plannedStart', ProductOrderRoutingLine."Starting Date-Time");
                        ProductOrderRoutingLineObj.Add('plannedEnd', ProductOrderRoutingLine."Ending Date-Time");
                        ProductOrderRoutingLineObj.Add('itemNo', ProductOrderLine."Item No.");
                        ProductOrderRoutingLineObj.Add('ItemDescription', ProductOrderLine.Description);
                        ProductOrderRoutingLineObj.Add('OrderQuantity', ProductOrderLine.Quantity);
                        ProductOrderRoutingLineObj.Add('operationDescription', ProductOrderRoutingLine.Description);
                        ProductOrderRoutingLineArr.Add(ProductOrderRoutingLineObj);
                    end;
                end;
            until ProductOrderRoutingLine.Next() = 0;

        exit(JsonHelper.JsonToTextArr(ProductOrderRoutingLineArr));
    end;

    procedure fetchOperationsStatusAndProgress(machineNo: Code[20]; fetchFinished: Boolean): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation State";
        MESOperationProgress: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
        ShouldInclude: Boolean;
        EndDateTime: DateTime;
        StartDateTime: DateTime;
        CurrentOperationStatus: Text;
        CurrentDeclaredAt: DateTime;
        JsonHelper: Codeunit "MES Json Helper";

    begin
        Clear(MESOperationStatusArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);

        if MESExecution.FindSet() then
            repeat
                MESOperationStatus.Reset();
                MESOperationStatus.SetCurrentKey("Execution Id", "Declared At");
                MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
                MESOperationStatus.Ascending(false);

                if MESOperationStatus.FindFirst() then begin
                    if fetchFinished then
                        ShouldInclude := MESOperationStatus."Operation Status" in
                        [
                            MESOperationStatus."Operation Status"::Finished,
                            MESOperationStatus."Operation Status"::Cancelled
                        ]
                    else
                        ShouldInclude := MESOperationStatus."Operation Status" in
                        [
                            MESOperationStatus."Operation Status"::Running,
                            MESOperationStatus."Operation Status"::Paused
                        ];

                    if ShouldInclude then begin
                        Clear(StartDateTime);
                        Clear(EndDateTime);
                        CurrentOperationStatus := Format(MESOperationStatus."Operation Status");
                        CurrentDeclaredAt := MESOperationStatus."Declared At";

                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Running);
                        if MESOperationStatus.FindLast() then
                            StartDateTime := MESOperationStatus."Declared At";

                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Finished);
                        if MESOperationStatus.FindFirst() then
                            EndDateTime := MESOperationStatus."Declared At";

                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Cancelled);
                        if MESOperationStatus.FindFirst() then
                            EndDateTime := MESOperationStatus."Declared At";

                        MESOperationStatus.SetRange("Operation Status");

                        Clear(MESOperationStatusObj);

                        MESOperationStatusObj.Add('prodOrderNo', MESExecution."Prod Order No");
                        MESOperationStatusObj.Add('machineNo', MESExecution."Machine No");
                        MESOperationStatusObj.Add('operationNo', MESExecution."Operation No");
                        MESOperationStatusObj.Add('operationStatus', CurrentOperationStatus);
                        MESOperationStatusObj.Add('startDateTime', Format(StartDateTime));
                        MESOperationStatusObj.Add('endDateTime', Format(EndDateTime));
                        MESOperationStatusObj.Add('declaredAt', Format(CurrentDeclaredAt));


                        MESOperationProgress.Reset();
                        MESOperationProgress.SetCurrentKey("Execution Id", "Declared At");
                        MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
                        MESOperationProgress.Ascending(false);

                        if MESOperationProgress.FindFirst() then begin
                            MESOperationStatusObj.Add('totalProducedQuantity', MESOperationProgress."Total Produced Quantity");

                            MESOperationStatusObj.Add('orderQuantity', MESExecution."Order Quantity");
                            MESOperationStatusObj.Add('itemNo', MESExecution."Item No");
                            MESOperationStatusObj.Add('itemDescription', MESExecution."Item Description");


                            if MESExecution."Order Quantity" <> 0 then
                                MESOperationStatusObj.Add('progressPercent',
                                    (MESOperationProgress."Total Produced Quantity") / MESExecution."Order Quantity" * 100);
                        end;

                        MESOperationStatusArr.Add(MESOperationStatusObj);
                    end;
                end;
            until MESExecution.Next() = 0;

        exit(JsonHelper.JsonToTextArr(MESOperationStatusArr));
    end;

    procedure fetchOperationLiveData(machineNo: Code[20]; prodOderNo: Code[20];
        operationNo: Code[10]): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation State";
        MESOperationProgress: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
        scrapQuantity: Decimal;
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
        JsonHelper: Codeunit "MES Json Helper";
    begin
        Clear(MESOperationStatusArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if MESExecution.FindFirst() then begin
            MESOperationStatus.Reset();
            MESOperationStatus.SetCurrentKey("Execution Id", "Declared At");
            MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
            MESOperationStatus.Ascending(false);

            if MESOperationStatus.FindFirst() then begin
                if (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Running) or
                   (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Paused) then begin

                    Clear(MESOperationStatusObj);
                    MESOperationStatusObj.Add('operationStatus', Format(MESOperationStatus."Operation Status"));
                    // calculate scrap 
                    scrapQuantity := 0;
                    MESScrap.Reset();
                    MESScrap.SetRange("Execution Id", MESExecution."Execution Id");
                    MESScrap.SetRange("Material Id", ''); // to exclude scrap records with material id which are not related to the current operation
                    if MESScrap.FindSet() then begin
                        repeat
                            scrapQuantity += MESScrap."Scrap Quantity";
                        until MESScrap.Next() = 0;
                    end;
                    MESOperationProgress.Reset();
                    MESOperationProgress.SetCurrentKey("Execution Id", "Declared At");
                    MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
                    MESOperationProgress.Ascending(false);

                    if MESOperationProgress.FindFirst() then begin
                        MESOperationStatusObj.Add('totalProducedQuantity', MESOperationProgress."Total Produced Quantity");
                        MESOperationStatusObj.Add('executionId', MESOperationStatus."Execution Id");

                        MESOperationStatusObj.Add('scrapQuantity', scrapQuantity);
                        if MESExecution."Order Quantity" <> 0 then
                            MESOperationStatusObj.Add('progressPercent',
                                (MESOperationProgress."Total Produced Quantity" / MESExecution."Order Quantity") * 100);
                    end;

                    MESOperationStatusArr.Add(MESOperationStatusObj);
                end;
            end;
        end;

        exit(JsonHelper.JsonToTextArr(MESOperationStatusArr));
    end;

    procedure fetchProductionCycles(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]): Text
    var
        MESExecution: Record "MES Operation Execution";
        OperationCycle: Record "MES Operation Progression";
        MESUser: Record "MES User";
        Employee: Record Employee;
        CycleObj: JsonObject;
        CycleArr: JsonArray;
        JsonHelper: Codeunit "MES Json Helper";
    begin
        Clear(CycleArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if not MESExecution.FindFirst() then
            exit(JsonHelper.JsonToTextArr(CycleArr));

        OperationCycle.Reset();
        OperationCycle.SetCurrentKey("Execution Id", "Declared At");
        OperationCycle.SetRange("Execution Id", MESExecution."Execution Id");
        OperationCycle.Ascending(false);

        if OperationCycle.FindSet() then begin
            repeat
                Clear(CycleObj);

                CycleObj.Add('orderQuantity', MESExecution."Order Quantity");
                CycleObj.Add('cycleQuantity', OperationCycle."Cycle Quantity");
                CycleObj.Add('totalProducedQuantity', OperationCycle."Total Produced Quantity");
                CycleObj.Add('scrapQuantity', OperationCycle."Scrap Quantity");
                CycleObj.Add('operatorId', OperationCycle."Operator Id");
                CycleObj.Add('declaredAt', OperationCycle."Declared At");

                if MESUser.Get(OperationCycle."Operator Id") then begin
                    if Employee.Get(MESUser."Employee ID") then begin
                        CycleObj.Add('firstName', Employee."First Name");
                        CycleObj.Add('lastName', Employee."Last Name");
                    end else begin
                        CycleObj.Add('firstName', '');
                        CycleObj.Add('lastName', '');
                    end;
                end else begin
                    CycleObj.Add('firstName', '');
                    CycleObj.Add('lastName', '');
                end;

                CycleArr.Add(CycleObj);
            until OperationCycle.Next() = 0;
        end;

        exit(JsonHelper.JsonToTextArr(CycleArr));
    end;

    procedure fetchBom(
        prodOrderNo: Code[20];
        operationNo: Code[10]): Text

    var
        JsonHelper: Codeunit "MES Json Helper";
        ProductOrderComponent: Record "Prod. Order Component";
        ProductOrderRoutingLine: Record "Prod. Order Routing Line";
        MESComponentConsumption: Record "MES Component Consumption";
        MESExecution: Record "MES Operation Execution";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        MESScrap: Record "MES Operation Scrap";
        ExecutionId: Code[50];
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean;
        TotalQuantityScanned: Decimal; // scanned qte * quantity per unit of measure
        numberScanned: Decimal;
        QuantityPerUnit: Decimal;
        BelongsToThisOperation: Boolean;
        scrapQuantity: Decimal;

        BomObj: JsonObject;
        BomArr: JsonArray;
    begin
        Clear(BomArr);

        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        if MESExecution.FindFirst() then
            ExecutionId := MESExecution."Execution Id";

        // get routing link code of this operation this will return on row exemple :
        /*
        | Order | Operation | Routing Link |
        | ----- | --------- | ------------ |
        | 1001  | 10        | A            |
        */

        ProductOrderRoutingLine.Reset();
        ProductOrderRoutingLine.SetRange("Prod. Order No.", prodOrderNo);
        ProductOrderRoutingLine.SetRange("Operation No.", operationNo);
        if ProductOrderRoutingLine.FindFirst() then
            CurrentRoutingLinkCode := ProductOrderRoutingLine."Routing Link Code";


        // lets say the component we have routing link r : A,B and (empty)
        // next the <> filter will keep only records where the link code is not empty 
        //we do not loop bcz we only care about is there at least one component with routing link or not thats why we did find first
        //if we find at least one component with link code return true
        ProductOrderComponent.Reset();
        ProductOrderComponent.SetRange("Prod. Order No.", prodOrderNo);
        ProductOrderComponent.SetFilter("Routing Link Code", '<>%1', '');
        HasAnyRoutingLink := ProductOrderComponent.FindFirst();

        //loop all componenents of this order 
        ProductOrderComponent.Reset();
        ProductOrderComponent.SetRange("Prod. Order No.", prodOrderNo);
        if ProductOrderComponent.FindSet() then
            repeat
                // skip only component that belong to another routing
                // routing = A 
                /*
                true and A!= '' and A != A  ---> true ,true ,false = false not(false) = include it 
                routing = B
                true and B!= '' and B != A  ---> true ,true ,True = True not(True) = skip it it 
                routing = empty
                false + anything + anything = false not(false) = true so include it
                anyway end result need to be true to perform the filter
                without not it will include only component that belong to other operations
                */
                if not (HasAnyRoutingLink and
                   (ProductOrderComponent."Routing Link Code" <> '') and
                   (ProductOrderComponent."Routing Link Code" <> CurrentRoutingLinkCode)) then begin


                    numberScanned := 0;
                    TotalQuantityScanned := 0;


                    BelongsToThisOperation := false;
                    if ProductOrderComponent."Routing Link Code" <> '' then
                        if ProductOrderComponent."Routing Link Code" = CurrentRoutingLinkCode then
                            BelongsToThisOperation := true;

                    if ExecutionId <> '' then begin
                        MESComponentConsumption.Reset();
                        MESComponentConsumption.SetRange("Execution Id", ExecutionId);
                        MESComponentConsumption.SetRange("Item No", ProductOrderComponent."Item No.");
                        if MESComponentConsumption.FindSet() then
                            //if there is no record in mes Component json wil return consumed qte 0 
                            repeat
                                numberScanned += MESComponentConsumption."Quantity Scanned";//
                                TotalQuantityScanned += MESComponentConsumption."Quantity Scanned" * MESComponentConsumption."Quantity per Unit of Measure";// qte scanned * quantity per unit of measure, so if i scanned 1 box of nail and each box has 5 piece the total quantity scanned will be 5 piece of nail
                            until MESComponentConsumption.Next() = 0;


                    end;
                    // get this item from the item unit table where same number and with this code 
                    QuantityPerUnit := ProductOrderComponent."Quantity per";
                    ItemUnitOfMeasure.Reset();
                    ItemUnitOfMeasure.SetRange("Item No.", ProductOrderComponent."Item No.");
                    ItemUnitOfMeasure.SetRange(Code, ProductOrderComponent."Unit of Measure Code");
                    if ItemUnitOfMeasure.FindFirst() then
                        //  5 piece in 1 box * 10 box = 50 piece of nail per bike
                        QuantityPerUnit := ItemUnitOfMeasure."Qty. per Unit of Measure" * ProductOrderComponent."Quantity per";

                    Clear(BomObj);
                    scrapQuantity := 0;
                    MESScrap.Reset();
                    MESScrap.SetRange("Execution Id", MESExecution."Execution Id");
                    MESScrap.SetRange("Material Id", ProductOrderComponent."Item No."); // to get scrap related to this component
                    if MESScrap.FindSet() then begin
                        repeat
                            scrapQuantity += MESScrap."Scrap Quantity";
                        until MESScrap.Next() = 0;
                    end;

                    BomObj.Add('itemNo', ProductOrderComponent."Item No.");
                    BomObj.Add('prodorderid', ProductOrderComponent."Prod. Order No.");
                    BomObj.Add('itemDescription', ProductOrderComponent.Description);
                    BomObj.Add('scrapQuantity', scrapQuantity);
                    //BomObj.Add('plannedQuantity', ProductOrderComponent.Quantity);
                    BomObj.Add('numberScanned', numberScanned); // how much i scanned this qr code
                    BomObj.add('totalQuantityScanned', TotalQuantityScanned);

                    BomObj.Add('belongsToThisOperation', BelongsToThisOperation);
                    BomObj.Add('quantityPerUnit', QuantityPerUnit); // if the component is 1 box of nail and each box has 5 piece and i need to consume 10 box the quantity per unit will be 50 piece of nail per bike
                    BomArr.Add(BomObj);

                end;

            until ProductOrderComponent.Next() = 0;

        exit(JsonHelper.JsonToTextArr(BomArr));

    end;


    /**
        procedure fetchItemBarcode(ItemNo: Code[20]; var EncodedText: Text; var ItemDescription: Text; var BaseUOM: Code[10])
        var
            Item: Record Item;
            BarcodeGen: Codeunit "MES Barcode Generator";
        begin
            if not Item.Get(ItemNo) then
                Error('Item %1 not found.', ItemNo);
    
            if Item."MES Datamatrix Encoded" = '' then
                BarcodeGen.GenerateAndSaveBarcodeText(ItemNo);
    
            Item.Get(ItemNo);
            EncodedText := Item."MES Datamatrix Encoded";
            ItemDescription := Item.Description;
            BaseUOM := Item."Base Unit of Measure";
    
    
            /**
              "@odata.context": "...",
              "EncodedText": "0101234567890123",
              "ItemDescription": "Steel Bolt M8x40",
              "BaseUOM": "PCS"
            }
            
        end;
    */

    procedure fetchAllItemBarcodes(): Text
    var
        JsonHelper: Codeunit "MES Json Helper";
        Item: Record Item;
        BarcodeGen: Codeunit "MES Barcode Generator";
        ResultArray: JsonArray;
        ItemObj: JsonObject;
        ResultText: Text;
    begin
        Item.FindSet();
        repeat
            /**
                if Item."MES Barcode Text" = '' then
                    BarcodeGen.GenerateAndSaveBarcodeText(Item."No.");
                Item.Get(Item."No.");
            */

            Clear(ItemObj);
            ItemObj.Add('itemNo', Item."No.");
            ItemObj.Add('description', Item.Description);
            ItemObj.Add('baseUOM', Item."Base Unit of Measure");
            ItemObj.Add('inventory', Item.Inventory);
            ItemObj.Add('shelfNo', Item."Shelf No.");
            ItemObj.Add('lotSize', Item."Lot Size");
            ItemObj.Add('flushingMethod', Format(Item."Flushing Method"));
            ItemObj.Add('barcodeText', Item."MES Barcode Text");

            ResultArray.Add(ItemObj);
        until Item.Next() = 0;


        exit(JsonHelper.JsonToTextArr(ResultArray));
    end;




    procedure fetchActivityLog(hoursBack: Decimal): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        MESProgression: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
        MESConsumption: Record "MES Component Consumption";
        MESUser: Record "MES User";
        Employee: Record Employee;
        LogArr: JsonArray;
        LogObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        OperatorName: Text;
        DeclaredByName: Text;
    begin
        Clear(LogArr);
        CutoffTime := CurrentDateTime() - (hoursBack * 3600000.0);

        MESState.Reset();
        MESState.SetCurrentKey("Execution Id", "Declared At");
        MESState.Ascending(false);
        MESState.SetFilter("Declared At", '>=%1', CutoffTime);
        if MESState.FindSet() then
            repeat
                Clear(LogObj);

                // to get operator name
                OperatorName := '-';
                if MESUser.Get(MESState."Operator Id") then
                    if Employee.Get(MESUser."Employee ID") then
                        OperatorName := Employee."First Name" + ' ' + Employee."Last Name";

                // get machine and order from execution
                if MESExecution.Get(MESState."Execution Id") then begin
                    LogObj.Add('type', 'status_change');
                    LogObj.Add('operatorId', MESState."Operator Id");
                    LogObj.Add('operatorName', OperatorName);
                    LogObj.Add('declaredById', '-');
                    LogObj.Add('declaredByName', '-');
                    LogObj.Add('machineNo', MESExecution."Machine No");
                    LogObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    LogObj.Add('operationNo', MESExecution."Operation No");
                    LogObj.Add('action', Format(MESState."Operation Status"));
                    LogObj.Add('timestamp', Format(MESState."Declared At"));
                    LogArr.Add(LogObj);
                end;
            until MESState.Next() = 0;

        // operation(meaning production) log
        MESProgression.Reset();
        MESProgression.SetCurrentKey("Execution Id", "Declared At");
        MESProgression.Ascending(false);
        MESProgression.SetFilter("Declared At", '>=%1', CutoffTime);
        if MESProgression.FindSet() then
            repeat
                Clear(LogObj);

                OperatorName := '';
                if MESUser.Get(MESProgression."Operator Id") then
                    if Employee.Get(MESUser."Employee ID") then
                        OperatorName := Employee."First Name" + ' ' + Employee."Last Name";
                DeclaredByName := '-';
                if (MESProgression."Declared By" <> '') and
                   (MESProgression."Declared By" <> MESProgression."Operator Id") then
                    if MESUser.Get(MESProgression."Declared By") then
                        if Employee.Get(MESUser."Employee ID") then
                            DeclaredByName := Employee."First Name" + ' ' + Employee."Last Name";

                if MESExecution.Get(MESProgression."Execution Id") then begin
                    LogObj.Add('type', 'production');
                    LogObj.Add('operatorId', MESProgression."Operator Id");
                    LogObj.Add('operatorName', OperatorName);
                    LogObj.Add('declaredById', MESProgression."Declared By");
                    LogObj.Add('declaredByName', DeclaredByName);
                    LogObj.Add('machineNo', MESExecution."Machine No");
                    LogObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    LogObj.Add('operationNo', MESExecution."Operation No");
                    LogObj.Add('action', 'Declared ' + Format(MESProgression."Cycle Quantity") + ' units');
                    LogObj.Add('timestamp', Format(MESProgression."Declared At"));
                    LogArr.Add(LogObj);
                end;
            until MESProgression.Next() = 0;

        // scrap log
        MESScrap.Reset();
        MESScrap.SetCurrentKey("Execution Id", "Declared At");
        MESScrap.Ascending(false);
        MESScrap.SetFilter("Declared At", '>=%1', CutoffTime);
        if MESScrap.FindSet() then
            repeat
                Clear(LogObj);

                OperatorName := '';
                if MESUser.Get(MESScrap."Operator Id") then
                    if Employee.Get(MESUser."Employee ID") then
                        OperatorName := Employee."First Name" + ' ' + Employee."Last Name";

                DeclaredByName := '-';
                if (MESScrap."Declared By" <> '') and
                   (MESScrap."Declared By" <> MESScrap."Operator Id") then
                    if MESUser.Get(MESScrap."Declared By") then
                        if Employee.Get(MESUser."Employee ID") then
                            DeclaredByName := Employee."First Name" + ' ' + Employee."Last Name";



                if MESExecution.Get(MESScrap."Execution Id") then begin
                    LogObj.Add('type', 'scrap');
                    LogObj.Add('operatorId', MESScrap."Operator Id");
                    LogObj.Add('operatorName', OperatorName);
                    LogObj.Add('declaredById', MESScrap."Declared By");
                    LogObj.Add('declaredByName', DeclaredByName);
                    LogObj.Add('machineNo', MESExecution."Machine No");
                    LogObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    LogObj.Add('operationNo', MESExecution."Operation No");
                    LogObj.Add('action', 'Reported ' + Format(MESScrap."Scrap Quantity") + ' scrap (' + MESScrap."Scrap Code" + ')');
                    LogObj.Add('timestamp', Format(MESScrap."Declared At"));
                    LogArr.Add(LogObj);
                end;
            until MESScrap.Next() = 0;

        // scan log
        MESConsumption.Reset();
        MESConsumption.SetCurrentKey("Execution Id", "Scanned At");
        MESConsumption.Ascending(false);
        MESConsumption.SetFilter("Scanned At", '>=%1', CutoffTime);
        if MESConsumption.FindSet() then
            repeat
                Clear(LogObj);

                OperatorName := '';
                if MESUser.Get(MESConsumption."Operator Id") then
                    if Employee.Get(MESUser."Employee ID") then
                        OperatorName := Employee."First Name" + ' ' + Employee."Last Name";
                DeclaredByName := '-';
                if (MESConsumption."Declared By" <> '') and
                   (MESConsumption."Declared By" <> MESConsumption."Operator Id") then
                    if MESUser.Get(MESConsumption."Declared By") then
                        if Employee.Get(MESUser."Employee ID") then
                            DeclaredByName := Employee."First Name" + ' ' + Employee."Last Name";


                if MESExecution.Get(MESConsumption."Execution Id") then begin
                    LogObj.Add('type', 'scan');
                    LogObj.Add('operatorId', MESConsumption."Operator Id");
                    LogObj.Add('operatorName', OperatorName);
                    LogObj.Add('declaredById', MESConsumption."Declared By");
                    LogObj.Add('declaredByName', DeclaredByName);
                    LogObj.Add('machineNo', MESExecution."Machine No");
                    LogObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    LogObj.Add('operationNo', MESExecution."Operation No");
                    LogObj.Add('action', 'Scanned item ' + MESConsumption."Item No");
                    LogObj.Add('timestamp', Format(MESConsumption."Scanned At"));
                    LogArr.Add(LogObj);
                end;
            until MESConsumption.Next() = 0;

        exit(JsonHelper.JsonToTextArr(LogArr));
    end;

    procedure fetchMachineDashboard(hoursBack: Decimal; workCenterNoJson: Text): Text
var
    Machine: Record "Machine Center";
    MESMachineStatus: Record "MES Machine Status";
    MESOperationState: Record "MES Operation State";
    MESExecution: Record "MES Operation Execution";
    PrevStatus: Enum "MES Machine Status";
    MESProgression: Record "MES Operation Progression";
    MESScrap: Record "MES Operation Scrap";
    MachineArr: JsonArray;
    MachineObj: JsonObject;
    JsonHelper: Codeunit "MES Json Helper";
    CutoffTime: DateTime;
    TotalMinutes: Decimal;
    RunningMinutes: Decimal;
    OperationFinished: Integer;
    OperationCancelled: Integer;
    TotalProduced: Decimal;
    TotalScrap: Decimal;
    UptimePercent: Decimal;
    PrevTime: DateTime;
    workCenterNoArr: JsonArray;
    workCenterNoToken: JsonToken;
    workCenterNo: Code[20];
    // store the list of work center no to filter machine in format of a list
    workCenterFilter: Text;
begin
    Clear(MachineArr);
    CutoffTime := CurrentDateTime() - (hoursBack * 3600000.0);
    TotalMinutes := hoursBack * 60;

    // workCenterNoJson is a simple string array: ["100","200"]
    workCenterFilter := '';
    workCenterNoArr.ReadFrom(workCenterNoJson);
    foreach workCenterNoToken in workCenterNoArr do begin
        workCenterNo := CopyStr(workCenterNoToken.AsValue().AsText(), 1, 20);

        if workCenterFilter = '' then
            workCenterFilter := workCenterNo
        else
            workCenterFilter += '|' + workCenterNo; // | to make it add OR for set range  WC1|WC2|WC3
    end;

    Machine.Reset();
    Machine.SetFilter("Work Center No.", workCenterFilter);//Machine.SetFilter("Work Center No.", 'WC1|WC2|WC3');

    if Machine.FindSet() then
        repeat
            Clear(MachineObj);
            RunningMinutes := 0;
            OperationFinished := 0;
            OperationCancelled := 0;
            TotalProduced := 0;
            TotalScrap := 0;
            UptimePercent := 0;

            MESExecution.Reset();
            MESExecution.SetRange("Machine No", Machine."No.");
            MESExecution.SetFilter("Start Time", '>=%1', CutoffTime);
            OperationFinished := 0;
            OperationCancelled := 0;
            if MESExecution.FindSet() then
                repeat
                    MESOperationState.Reset();
                    MESOperationState.SetRange("Execution Id", MESExecution."Execution Id");
                    MESOperationState.SetCurrentKey("Execution Id", "Declared At");
                    MESOperationState.Ascending(false);
                    // count canceled and finished operations
                    if MESOperationState.FindFirst() then begin
                        if MESOperationState."Operation Status" = MESOperationState."Operation Status"::Finished then
                            OperationFinished += 1
                        else if MESOperationState."Operation Status" = MESOperationState."Operation Status"::Cancelled then
                            OperationCancelled += 1;
                    end;

                    // sum qte produced for all progressions of this execution
                    MESProgression.Reset();
                    MESProgression.SetRange("Execution Id", MESExecution."Execution Id");
                    MESProgression.SetCurrentKey("Execution Id", "Declared At");
                    MESProgression.Ascending(false);
                    // no loop cuz the latest progression record will have the total produced quantity for this execution
                    if MESProgression.FindFirst() then
                        TotalProduced += MESProgression."Total Produced Quantity";

                    MESScrap.Reset();
                    MESScrap.SetRange("Execution Id", MESExecution."Execution Id");
                    // here we do need to loop and sum all
                    if MESScrap.FindSet() then
                        repeat
                            TotalScrap += MESScrap."Scrap Quantity";
                        until MESScrap.Next() = 0;

                until MESExecution.Next() = 0;

            // calculate uptime from machine status log
            MESMachineStatus.Reset();
            MESMachineStatus.SetRange("Machine No.", Machine."No.");
            MESMachineStatus.SetCurrentKey("Machine No.", "Updated At");
            MESMachineStatus.Ascending(true);
            Clear(PrevTime);

            if MESMachineStatus.FindSet() then
                repeat
                    if MESMachineStatus."Updated At" >= CutoffTime then begin

                        if PrevTime <> 0DT then begin
                            if PrevStatus = PrevStatus::Working then begin

                                if PrevTime < CutoffTime then
                                    RunningMinutes += (MESMachineStatus."Updated At" - CutoffTime) / 60000.0
                                else
                                    RunningMinutes += (MESMachineStatus."Updated At" - PrevTime) / 60000.0;

                            end;
                        end;
                        PrevTime := MESMachineStatus."Updated At";
                        PrevStatus := MESMachineStatus.Status;
                    end;
                until MESMachineStatus.Next() = 0;
            if (PrevStatus = PrevStatus::Working) and (PrevTime <> 0DT) then begin

                if PrevTime < CutoffTime then
                    RunningMinutes += (CurrentDateTime() - CutoffTime) / 60000.0
                else
                    RunningMinutes += (CurrentDateTime() - PrevTime) / 60000.0;

            end;
            if TotalMinutes > 0 then
                UptimePercent := Round((RunningMinutes / TotalMinutes) * 100, 0.1)
            else
                UptimePercent := 0;

            MachineObj.Add('machineNo', Machine."No.");
            MachineObj.Add('machineName', Machine."Name");
            MachineObj.Add('workCenterNo', Machine."Work Center No.");
            MachineObj.Add('operationFinished', OperationFinished);
            MachineObj.Add('operationCancelled', OperationCancelled);
            MachineObj.Add('uptimePercent', UptimePercent);
            MachineObj.Add('runningMinutes', RunningMinutes);
            MachineObj.Add('totalProduced', TotalProduced);
            MachineObj.Add('totalScrap', TotalScrap);
            MachineArr.Add(MachineObj);

        until Machine.Next() = 0;

    exit(JsonHelper.JsonToTextArr(MachineArr));
end;

    procedure resolveBarcode(barcode: Text): Text
    var
        Item: Record Item;
        ItemIdentifier: Record "Item Identifier";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        quantityPerUnitOfMeasure: Decimal;
        ResultJson: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        ItemNo: Code[20];
        startPos: Integer;
        endPos: Integer;
    begin
        // we check if the barcode contain item number in the string if yes we will extact the item number from the string
        if StrPos(barcode, 'Item Number:') > 0 then begin

            startPos := StrPos(barcode, 'Item Number: ');
            startPos := startPos + StrLen('Item Number: ');

            endPos := StrPos(barcode, '|');
            if endPos = 0 then
                endPos := StrLen(barcode) + 1;

            ItemNo := CopyStr(barcode, startPos, endPos - startPos);
            // we search the item table and  get from the "item table new column extension mes barcode code" value  "mes-1100" using the item number that we extracted from the barcode
            if Item.Get(ItemNo) then
                // we override the barcode with the MES Barcode Code from the item table to be used in the next step : check if this barcode exist in the identifier table
                barcode := Item."MES Barcode Code"
            else begin
                //if not found it means the item number we extracted does not exist in the item table or its fake or its correpted 
                ResultJson.Add('resolved', false);
                ResultJson.Add('message', 'Item not found from DataMatrix');
                exit(JsonHelper.JsonToText(ResultJson));
            end;
        end;

        ItemIdentifier.Reset();
        ItemIdentifier.SetRange(Code, CopyStr(barcode, 1, 20));
        // we check if the barcode code  exist in the item identifier table if not found it means this is a random barcode /not yet to be registered 
        if not ItemIdentifier.FindFirst() then begin
            ResultJson.Add('resolved', false);
            ResultJson.Add('message', 'Barcode not recognized');
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        ItemNo := ItemIdentifier."Item No.";
        //looks like we have the same validation  the diferent is the sourse one from item id extracted from barcode string one item no from table identifier
        // this just to ensure the item linked to this barcdoe is still valid in the system and not deleted or soemthing 
        if not Item.Get(ItemNo) then begin
            ResultJson.Add('resolved', false);
            ResultJson.Add('message', 'Item ' + ItemNo + ' not found');
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        ItemUnitOfMeasure.Reset();
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetRange(Code, ItemIdentifier."Unit of Measure Code");
        if ItemUnitOfMeasure.FindFirst() then
            quantityPerUnitOfMeasure := ItemUnitOfMeasure."Qty. per Unit of Measure";

        ResultJson.Add('resolved', true);
        ResultJson.Add('itemNo', Item."No.");
        ResultJson.Add('itemDescription', Item.Description);
        ResultJson.Add('baseUOM', Item."Base Unit of Measure");
        ResultJson.Add('unitOfMeasure', ItemIdentifier."Unit of Measure Code");
        ResultJson.Add('quantityPerUnitOfMeasure', quantityPerUnitOfMeasure);

        exit(JsonHelper.JsonToText(ResultJson));
    end;




}

