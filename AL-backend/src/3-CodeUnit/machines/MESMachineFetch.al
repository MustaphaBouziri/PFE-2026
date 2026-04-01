codeunit 50131 "MES Machine Fetch"
{
    Access = Internal;

    procedure FetchMachines(workCenterNo: Text): Text
    var
        Machine: Record "Machine Center";
        MESMachineStatus: Record "MES Machine Status";
        MachineArr: JsonArray;
        MachineObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
    begin
        if workCenterNo = '' then Error('Work Center Number is required');
        Machine.SetRange("Work Center No.", workCenterNo);

        if Machine.FindSet() then
            repeat
                clear(MachineObj);
                MachineObj.Add('machineNo', Machine."No.");
                MachineObj.Add('machineName', Machine."Name");
                MachineObj.Add('status', 'Idle');
                MachineObj.Add('currentOrder', 'No operator yet');

                MESMachineStatus.Reset();
                MESMachineStatus.SetCurrentKey("Machine No.", "Updated At");
                MESMachineStatus.SetRange("Machine No.", Machine."No.");
                MESMachineStatus.Ascending(false);  // most recent first

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
                            MESOperationStatusObj.Add('scrapQuantity', MESOperationProgress."Scrap Quantity");
                            MESOperationStatusObj.Add('orderQuantity', MESExecution."Order Quantity");
                            MESOperationStatusObj.Add('itemDescription', MESExecution."Item Description");
                            if MESExecution."Order Quantity" <> 0 then
                                MESOperationStatusObj.Add('progressPercent',
                                    (MESOperationProgress."Total Produced Quantity" / MESExecution."Order Quantity") * 100);
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

                    MESOperationProgress.Reset();
                    MESOperationProgress.SetCurrentKey("Execution Id", "Declared At");
                    MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
                    MESOperationProgress.Ascending(false);

                    if MESOperationProgress.FindFirst() then begin
                        MESOperationStatusObj.Add('totalProducedQuantity', MESOperationProgress."Total Produced Quantity");
                        MESOperationStatusObj.Add('executionId', MESOperationStatus."Execution Id");

                        MESOperationStatusObj.Add('scrapQuantity', MESOperationProgress."Scrap Quantity");
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
        ExecutionId: Code[50];
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean;
        TotalConsumed: Decimal;
        TotalScanned: Decimal;
        BelongsToThisOperation: Boolean;

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

                    TotalConsumed := 0;
                    TotalScanned := 0;

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
                                TotalScanned += MESComponentConsumption."Quantity Scanned";
                            // TotalConsumed += MESComponentConsumption."Quantity Consumed";
                            until MESComponentConsumption.Next() = 0;

                    end;
                    Clear(BomObj);
                    BomObj.Add('itemNo', ProductOrderComponent."Item No.");
                    BomObj.Add('prodorderid', ProductOrderComponent."Prod. Order No.");
                    BomObj.Add('lineNUmber', ProductOrderComponent."Line No.");
                    BomObj.Add('itemDescription', ProductOrderComponent.Description);
                    BomObj.Add('plannedQuantity', ProductOrderComponent.Quantity);
                    BomObj.Add('quantityScanned', TotalScanned);
                    //BomObj.Add('quantityConsumed', TotalConsumed);
                    //BomObj.Add('remainingQuantity', TotalScanned - TotalConsumed);
                    BomObj.Add('belongsToThisOperation', BelongsToThisOperation);
                    BomObj.Add('quantityPer', ProductOrderComponent."Quantity per");
                    BomArr.Add(BomObj);
                    /**
                     {
                     "plannedQuantity": 10,
                     "scannedQuantity": 5,
                     "consumedQuantity": 3,
                     "remainingQuantity": 2
                     belongsToThisOperation', true / false )
                     }
                    */

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



}

