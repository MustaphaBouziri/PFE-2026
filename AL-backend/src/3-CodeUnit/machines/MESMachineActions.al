codeunit 50130 "MES Machine Actions"
{
    Access = Internal;

    local procedure JsonToText(J: JsonObject): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure JsonToTextArr(J: JsonArray): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure FetchMachines(workCenterNo: Text): Text
    var
        Machine: Record "Machine Center";
        MESMachineStatus: Record "MES Machine Status";
        MachineArr: JsonArray;

        /*
        means jason array will be like this : 
        [
      { machine1 },
      { machine2 },
      { machine3 }
    ]

        */
        MachineObj: JsonObject;
    /*
    {
  "machineNo": "MC-01",
  "machineName": "CNC 1",
  "status": "Running"
}
    
    */

    begin
        if workCenterNo = '' then Error('Work Center Number is required');
        //setRange = select * from machine center where workcenterNo = what user sent
        Machine.SetRange("Work Center No.", workCenterNo);

        if Machine.FindSet() then
            /*
            It fetches the filtered records as a set.

            It positions the record pointer on the first record.

            if machine.set range will return me a box the machine,findset it as saying:
            hey open the box if there is nothing return false 
            else return me true and point to the first record

            */
            repeat
                clear(MachineObj);
                // in case the Mes machine status have 0 rows api will return these default values
                MachineObj.Add('machineNo', Machine."No.");
                MachineObj.Add('machineName', Machine."Name");
                MachineObj.Add('status', 'Idle');
                MachineObj.Add('currentOrder', 'No operator yet');

                MESMachineStatus.Reset();
                MESMachineStatus.SetRange("Machine No.", Machine."No.");

                if MESMachineStatus.FindLast() then begin
                    // ok why findLast ? since the Mes Machine status is for real time data fetching we need to last record not the first record
                    MachineObj.Replace('status', Format(MESMachineStatus.Status));
                    MachineObj.Replace('currentOrder', MESMachineStatus."Current Prod. Order No.");
                end;

                MachineArr.Add(MachineObj);
            until Machine.Next() = 0;// go to next record
        exit(JsonToTextArr(MachineArr));
    end;

    //______________________________fetching machine orders _____________________________________

    procedure getMachineOrders(machineNo: Text): Text
    var
        ProductOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductOrderLine: Record "Prod. Order Line";
        ProductOrderRoutingLineArr: JsonArray;
        ProductOrderRoutingLineObj: JsonObject;
        MESExecution: Record "MES Operation Execution";
    begin
        if MachineNo = '' then Error('Machine Number is required');

        ProductOrderRoutingLine.SetRange(Type, ProductOrderRoutingLine.Type::"Machine Center");
        // the "::" used to acess the available options of the fild "Type" by options I mean enum values.
        ProductOrderRoutingLine.SetRange("No.", MachineNo);

        // setRange used for simple comperation , setFilter for complex comperation
        ProductOrderRoutingLine.SetFilter(Status, '%1|%2|%3',
                                          // %1|%2|%3 means get me orders where status = ? or ? or ?
                                          ProductOrderRoutingLine.Status::Planned,
                                          ProductOrderRoutingLine.Status::"Firm Planned",
                                          ProductOrderRoutingLine.Status::Released);

        if ProductOrderRoutingLine.FindSet() then
            repeat
                MESExecution.Reset();
                MESExecution.SetRange("Prod Order No", ProductOrderRoutingLine."Prod. Order No.");
                MESExecution.SetRange("Operation No", ProductOrderRoutingLine."Operation No.");
                MESExecution.SetRange("Machine No", MachineNo);

                // if this order/operation does not exist in the mes execution table enter the body
                if not MESExecution.FindFirst() then begin
                    Clear(ProductOrderRoutingLineObj);

                    ProductOrderLine.Reset();
                    ProductOrderLine.SetRange("Prod. Order No.", ProductOrderRoutingLine."Prod. Order No.");

                    if ProductOrderLine.FindFirst() then begin
                        //so the prod line is used for to know the order info and prod order routing line is used to know the operation details.
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

        exit(JsonToTextArr(ProductOrderRoutingLineArr));
    end;

    //____________________________________________________________________________________________________________

    procedure startOperation(
        prodOderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        ExecutionId: Code[50];
    begin
        ClearLastError();

        Success := TryStartOperation(prodOderNo, operationNo, machineNo);

        if Success then begin
            ExecutionId := InsertMESOperationExecution(prodOderNo, operationNo, machineNo);
            InsertMESOperation(ExecutionId);
            InsertMESOperationProgression(ExecutionId, prodOderNo, machineNo);
            InsertMESMachineStatus(prodOderNo, machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    [TryFunction]
    local procedure TryStartOperation(
        prodOderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    )
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PreviousProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
        TotalProducedQuantity: Decimal;
    begin
        //get current order routing line mainly to know what operation u on  10 20 30 
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", prodOderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", operationNo);

        if not ProdOrderRoutingLine.FindFirst() then
            Error('Routing line not found.');

        // now we prevent starting the same operation twice
        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", prodOderNo);
        MESExecution.SetRange("Operation No", operationNo);
        if MESExecution.FindFirst() then begin
            MESOperationStatus.Reset();
            MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
            MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Running);
            if MESOperationStatus.FindFirst() then
                Error('This operation is already running.');
        end;

        // we check if there is a curently worked on operation of a diferent order 
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        if MESExecution.FindSet() then
            repeat
                MESOperationStatus.Reset();
                MESOperationStatus.SetCurrentKey("Execution Id", "Last Updated At");
                MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
                MESOperationStatus.Ascending(false);
                if MESOperationStatus.FindFirst() then begin
                    if MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Running then
                        Error(
                            'Machine %1 is already running another operation (Order %2 - Operation %3). Pause or finish it first.',
                            MESExecution."Machine No",
                            MESExecution."Prod Order No",
                            MESExecution."Operation No"
                        );
                end;
            until MESExecution.Next() = 0;

        // now we find the previous order routing line 
        PreviousProdOrderRoutingLine.Reset();
        // again why setRange and not get if we used primary keys info ? Get() is used only when we know the FULL primary key and want one exact record. in our case we may return multiple rows so get is useless here
        PreviousProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status); // we use the status of the row the get returned 
        PreviousProdOrderRoutingLine.SetRange("Prod. Order No.", prodOderNo);
        PreviousProdOrderRoutingLine.SetFilter("Operation No.", '<%1', operationNo); // means where operation number < of the current operation number exemple operation number < 30
    end;

    local procedure InsertMESOperationExecution(
        prodOderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20]
    ): Code[50]
    var
        MESExecution: Record "MES Operation Execution";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // i need to do setRange otherwise i wont be able to know order details like quantity
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", prodOderNo);
        if not ProdOrderLine.FindFirst() then
            Error('Production order line not found.');

        MESExecution.Init();
        MESExecution."Machine No" := machineNo;
        MESExecution."Prod Order No" := prodOderNo;
        MESExecution."Operation No" := operationNo;
        MESExecution."Item No" := ProdOrderLine."Item No.";
        MESExecution."Item Description" := ProdOrderLine.Description;
        MESExecution."Order Quantity" := ProdOrderLine.Quantity;
        MESExecution.Insert(true);
        exit(MESExecution."Execution Id");
    end;

    local procedure InsertMESOperation(executionId: Code[50])
    var
        MESOperationStatus: Record "MES Operation Status";
    begin
        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := executionId;
        MESOperationStatus."Operation Status" := MESOperationStatus."Operation Status"::Running;
        MESOperationStatus."Operator Id" := UserId;
        MESOperationStatus.Insert(true);
    end;

    local procedure InsertMESMachineStatus(
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

    local procedure InsertMESOperationProgression(
        executionId: Code[50];
        prodOderNo: Code[20];
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
    end;

    //_____________progress + status merge___________________

    procedure fetchOperationsStatusAndProgress(machineNo: Code[20]; fetchFinished: Boolean): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
        MESOperationProgress: Record "MES Operation Progression";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
        ShouldInclude: Boolean;
        EndDateTime: DateTime;
        StartDateTime: DateTime;
        CurrentOperationStatus: Text;
        CurrentLastUpdatedAt: DateTime;
    begin
        Clear(MESOperationStatusArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);

        if MESExecution.FindSet() then
            repeat
                // get latest status for this execution
                MESOperationStatus.Reset();
                MESOperationStatus.SetCurrentKey("Execution Id", "Last Updated At");
                MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
                MESOperationStatus.Ascending(false);

                if MESOperationStatus.FindFirst() then begin
                    // fetchFinished= true -> include only Finished or cancelled, fetchFinished=false -> include only running or paused
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
                        CurrentLastUpdatedAt := MESOperationStatus."Last Updated At";

                        // find start time = oldest running record
                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Running);
                        if MESOperationStatus.FindLast() then
                            StartDateTime := MESOperationStatus."Last Updated At";

                        // find end time = newest finished record
                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Finished);
                        if MESOperationStatus.FindFirst() then
                            EndDateTime := MESOperationStatus."Last Updated At";

                        MESOperationStatus.SetRange("Operation Status", MESOperationStatus."Operation Status"::Cancelled);
                        if MESOperationStatus.FindFirst() then
                            EndDateTime := MESOperationStatus."Last Updated At";


                        MESOperationStatus.SetRange("Operation Status");

                        Clear(MESOperationStatusObj);

                        // adding status fields
                        MESOperationStatusObj.Add('prodOrderNo', MESExecution."Prod Order No");
                        MESOperationStatusObj.Add('machineNo', MESExecution."Machine No");
                        MESOperationStatusObj.Add('operationNo', MESExecution."Operation No");
                        MESOperationStatusObj.Add('operationStatus', CurrentOperationStatus);
                        MESOperationStatusObj.Add('startDateTime', Format(StartDateTime));
                        MESOperationStatusObj.Add('endDateTime', Format(EndDateTime));
                        MESOperationStatusObj.Add('lastUpdatedAt', Format(CurrentLastUpdatedAt));

                        /*
                        so basicly for status we don't know what's there, so we explore the whole table
                        thats why we loop and doing grouping to show me all operations / orders that r not finished
                        we need the grouping and the <> check to skip dupplicates.
                        as for progress no need cuz status loop provide us with a specific operation and order number
                        so we could just do set range with these values and return us the progress fields info of this specific operation.
                        */

                        MESOperationProgress.Reset();
                        MESOperationProgress.SetCurrentKey("Execution Id", "Last Updated At");
                        MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
                        MESOperationProgress.Ascending(false);

                        // FindFirst cuz we did ascending false so the newest row is on top
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

        /* _____________final json _____________
        [
          {
            "prodOrderNo":           "1011003",
            "operationNo":           "40",
            "operationStatus":       "Finished",
            "startDateTime":         "08:00",
            "endDateTime":           "16:00",
            "totalProducedQuantity": 50,
            "scrapQuantity":         2,
            "orderQuantity":         100,
            "progressPercent":       50.0
          }
        ]
        */

        exit(JsonToTextArr(MESOperationStatusArr));
    end;

    //______________________________________________________________________

    procedure fetchOperationLiveData(machineNo: Code[20]; prodOderNo: Code[20];
        operationNo: Code[10]): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
        MESOperationProgress: Record "MES Operation Progression";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
    begin
        Clear(MESOperationStatusArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if MESExecution.FindFirst() then begin
            MESOperationStatus.Reset();
            MESOperationStatus.SetCurrentKey("Execution Id", "Last Updated At");
            MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
            MESOperationStatus.Ascending(false);

            if MESOperationStatus.FindFirst() then begin
                if (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Running) or
                   (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Paused) then begin

                    Clear(MESOperationStatusObj);
                    MESOperationStatusObj.Add('operationStatus', Format(MESOperationStatus."Operation Status"));

                    MESOperationProgress.Reset();
                    MESOperationProgress.SetCurrentKey("Execution Id", "Last Updated At");
                    MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
                    MESOperationProgress.Ascending(false);

                    if MESOperationProgress.FindFirst() then begin
                        MESOperationStatusObj.Add('totalProducedQuantity', MESOperationProgress."Total Produced Quantity");
                        MESOperationStatusObj.Add('scrapQuantity', MESOperationProgress."Scrap Quantity");
                        if MESExecution."Order Quantity" <> 0 then
                            MESOperationStatusObj.Add('progressPercent',
                                (MESOperationProgress."Total Produced Quantity" / MESExecution."Order Quantity") * 100);
                    end;

                    MESOperationStatusArr.Add(MESOperationStatusObj);
                end;
            end;
        end;

        exit(JsonToTextArr(MESOperationStatusArr));
    end;

    // _____________________declaire production___________
    procedure declareProduction(
        machineNo: Code[20];
        prodOderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
    begin
        ClearLastError();

        Success := TryDeclareProduction(machineNo, prodOderNo, operationNo, input);

        if Success then begin
            InsertNewProgressionCycle(machineNo, prodOderNo, operationNo, input);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    [TryFunction]
    local procedure TryDeclareProduction(
        machineNo: Code[20];
        prodOderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationProgress: Record "MES Operation Progression";
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if not MESExecution.FindFirst() then
            Error('Operation execution record not found.');

        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey("Execution Id", "Last Updated At");
        MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
        MESOperationProgress.Ascending(false);

        if not MESOperationProgress.FindFirst() then
            Error('Operation progression record not found.');

        if input <= 0 then
            Error('Declared quantity must be greater than zero.');

        if (MESOperationProgress."Total Produced Quantity" + input) > MESExecution."Order Quantity" then
            Error('Declared quantity exceeds the remaining order quantity.');
    end;

    local procedure InsertNewProgressionCycle(
        machineNo: Code[20];
        prodOderNo: Code[20];
        operationNo: Code[10];
        input: Decimal
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationProgress: Record "MES Operation Progression";
        NewMESOperationProgress: Record "MES Operation Progression";
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOderNo);
        MESExecution.SetRange("Operation No", operationNo);
        MESExecution.FindFirst();

        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey("Execution Id", "Last Updated At");
        MESOperationProgress.SetRange("Execution Id", MESExecution."Execution Id");
        MESOperationProgress.Ascending(false);
        MESOperationProgress.FindFirst();

        NewMESOperationProgress.Init();
        NewMESOperationProgress."Execution Id" := MESExecution."Execution Id";
        NewMESOperationProgress."Operator Id" := UserId;
        NewMESOperationProgress."Cycle Quantity" := input;
        NewMESOperationProgress."Total Produced Quantity" := MESOperationProgress."Total Produced Quantity" + input;
        NewMESOperationProgress."Scrap Quantity" := 0;
        NewMESOperationProgress.Insert(true);
    end;

    //___________________________

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
    begin
        Clear(CycleArr);

        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if not MESExecution.FindFirst() then
            exit(JsonToTextArr(CycleArr));

        OperationCycle.Reset();
        OperationCycle.SetCurrentKey("Execution Id", "Last Updated At");
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
                CycleObj.Add('lastUpdatedAt', OperationCycle."Last Updated At");

                // wanna get the name so i need join  so basicaly this haul section is like inner join sql
                /*
                FROM "MES Operation Progression" op

                INNER JOIN "MES User" u 
                ON u."User Id" = op."Operator Id"

                INNER JOIN "Employee" e 
                ON e."No." = u."Employee ID"*/

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

        exit(JsonToTextArr(CycleArr));
    end;

    //_________________fetch bom________

    procedure fetchBom(
        prodOrderNo: Code[20];
        operationNo: Code[10]): Text

    var
        ProductOrderComponent: Record "Prod. Order Component";
        ProductOrderRoutingLine: Record "Prod. Order Routing Line";
        MESComponentConsumption: Record "MES Component Consumption";
        MESExecution: Record "MES Operation Execution";
        ExecutionId: Code[50];
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean;
        TotalConsumed: Decimal;

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
                    if ExecutionId <> '' then begin
                        MESComponentConsumption.Reset();
                        MESComponentConsumption.SetRange("Execution Id", ExecutionId);
                        MESComponentConsumption.SetRange("Item No", ProductOrderComponent."Item No.");
                        if MESComponentConsumption.FindSet() then
                            //if there is no record in mes Component json wil return consumed qte 0 
                            repeat
                    TotalConsumed += MESComponentConsumption.Quantity;
                            until MESComponentConsumption.Next() = 0;

                    end;
                    Clear(BomObj);
                    BomObj.Add('itemNo', ProductOrderComponent."Item No.");
                    BomObj.Add('itemDescription', ProductOrderComponent.Description);
                    BomObj.Add('plannedQuantity', ProductOrderComponent.Quantity);
                    BomObj.Add('unitOfMeasure', ProductOrderComponent."Unit of Measure Code");
                    BomObj.Add('consumedQuantity', TotalConsumed);
                    BomObj.Add('remainingQuantity', ProductOrderComponent.Quantity - TotalConsumed);
                    BomArr.Add(BomObj);
                end;

            until ProductOrderComponent.Next() = 0;

        exit(JsonToTextArr(BomArr));






    end;




    // ──────────────────────────────────────────────────────────────────────────
    // finishOperation  – called when progress = 100 %
    // cancelOperation  – called when progress < 100 %
    // ──────────────────────────────────────────────────────────────────────────

    procedure finishOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MESOperationStatus: Record "MES Operation Status";
    begin
        ClearLastError();
        Success := TryCloseOperation(machineNo, prodOrderNo, operationNo);

        if Success then begin
            InsertOperationStatus(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Finished);
            InsertIdleMachineStatus(machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    procedure cancelOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    ): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MESOperationStatus: Record "MES Operation Status";
    begin
        ClearLastError();
        Success := TryCloseOperation(machineNo, prodOrderNo, operationNo);

        if Success then begin
            InsertOperationStatus(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Cancelled);
            InsertIdleMachineStatus(machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    procedure pauseOperation(
    machineNo: Code[20];
    prodOrderNo: Code[20];
    operationNo: Code[10]): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MESOperationStatus: Record "MES Operation Status";
    begin
        ClearLastError();
        Success := TryPauseOperation(machineNo, prodOrderNo, operationNo);

        if Success then begin
            InsertOperationStatus(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Paused);
            InsertIdleMachineStatus(machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    procedure resumeOperation(
    machineNo: Code[20];
    prodOrderNo: Code[20];
    operationNo: Code[10]): Text
    var
        ResultJson: JsonObject;
        Success: Boolean;
        ErrorMessage: Text;
        MESOperationStatus: Record "MES Operation Status";
    begin
        ClearLastError();
        Success := TryResumeOperation(machineNo, prodOrderNo, operationNo);

        if Success then begin
            InsertOperationStatus(machineNo, prodOrderNo, operationNo, MESOperationStatus."Operation Status"::Running);
            InsertIdleMachineStatus(machineNo);
            ResultJson.Add('value', true);
        end else begin
            ErrorMessage := GetLastErrorText();
            ResultJson.Add('value', false);
            ResultJson.Add('message', ErrorMessage);
        end;

        exit(JsonToText(ResultJson));
    end;

    local procedure GetExecutionAndLatestStatus(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        var MESExecution: Record "MES Operation Execution";
        var MESOperationStatus: Record "MES Operation Status"
    )
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);

        if not MESExecution.FindFirst() then
            Error(
                'Operation execution record not found for Machine %1, Order %2, Operation %3.',
                machineNo,
                prodOrderNo,
                operationNo
            );

        MESOperationStatus.Reset();
        MESOperationStatus.SetCurrentKey("Execution Id", "Last Updated At");
        MESOperationStatus.SetRange("Execution Id", MESExecution."Execution Id");
        MESOperationStatus.Ascending(false);

        if not MESOperationStatus.FindFirst() then
            Error(
                'No operation status found for Machine %1, Order %2, Operation %3.',
                machineNo,
                prodOrderNo,
                operationNo
            );
    end;

    [TryFunction]
    local procedure TryPauseOperation(
    machineNo: Code[20];
    prodOrderNo: Code[20];
    operationNo: Code[10]
)
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
    begin
        GetExecutionAndLatestStatus(machineNo,prodOrderNo,operationNo,MESExecution,MESOperationStatus);
        if MESOperationStatus."Operation Status" <> MESOperationStatus."Operation Status"::Running then
            Error('Operation needs to be running to be paused.');
    end;

    [TryFunction]
    local procedure TryResumeOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
    begin
        GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, MESExecution, MESOperationStatus);
        if MESOperationStatus."Operation Status" <> MESOperationStatus."Operation Status"::Paused then
            Error('Operation needs to be paused to be resumed.');
    end;

    [TryFunction]
    local procedure TryCloseOperation(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10]
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
    begin
       GetExecutionAndLatestStatus(machineNo, prodOrderNo, operationNo, MESExecution, MESOperationStatus);
        if MESOperationStatus."Operation Status" in
           [
               MESOperationStatus."Operation Status"::Finished,
               MESOperationStatus."Operation Status"::Cancelled
           ]
        then
            Error('Operation is already finished or cancelled.');
    end;

    // Insert a new MES Operation Status row with status = status.
    local procedure InsertOperationStatus(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        status: Enum "MES Operation Status"
    )
    var
        MESExecution: Record "MES Operation Execution";
        MESOperationStatus: Record "MES Operation Status";
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Machine No", machineNo);
        MESExecution.SetRange("Prod Order No", prodOrderNo);
        MESExecution.SetRange("Operation No", operationNo);
        MESExecution.FindFirst();

        MESOperationStatus.Init();
        MESOperationStatus."Execution Id" := MESExecution."Execution Id";
        MESOperationStatus."Operation Status" := status;
        MESOperationStatus."Operator Id" := UserId;
        MESOperationStatus.Insert(true);

        // Stamp the end time on the execution record
        MESExecution."End Time" := CurrentDateTime();
        MESExecution.Modify(true);
    end;


    // Insert a new MES Machine Status row with status = Idle.
    local procedure InsertIdleMachineStatus(machineNo: Code[20])
    var
        MESMachineStatus: Record "MES Machine Status";
    begin
        MESMachineStatus.Init();
        MESMachineStatus."Machine No." := machineNo;
        MESMachineStatus.Status := MESMachineStatus.Status::Idle;
        MESMachineStatus."Current Prod. Order No." := '';
        MESMachineStatus.Insert(true);
    end;

}