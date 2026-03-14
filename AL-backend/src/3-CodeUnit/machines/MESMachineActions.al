codeunit 50130 "MES Machine Actions"
{
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
        MESOperation: Record "MES Operation Status";
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
                                          ProductOrderRoutingLine.Status::Released
                                         );

        if ProductOrderRoutingLine.FindSet() then
            repeat
                MESOperation.Reset();
                MESOperation.SetRange("Prod Order No", ProductOrderRoutingLine."Prod. Order No.");
                MESOperation.SetRange("Operation No", ProductOrderRoutingLine."Operation No.");
                MESOperation.SetRange("Machine No", MachineNo);

                // if this order/operation does not exist in the mes operation table enter the body
                // why cuz we wanna fetch only from erp if it exist in mes it means that the operation is currently worken on or paused or finished so useless to fetch them on planned order tab

                if not MESOperation.FindFirst() then begin

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
    // you need to explain this why did you remove the arrtotext func just to replace it with another func that does thhe same thing

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
    begin
        ClearLastError();

        Success := TryStartOperation(prodOderNo, operationNo, machineNo);

        if Success then begin
            InsertMESOperation(prodOderNo, operationNo, machineNo);
            InsertMESOperationProgression(prodOderNo, operationNo, machineNo);
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
        MESOperation: Record "MES Operation Status";
        PreviousMESOperation: Record "MES Operation Status";
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

        MESOperation.Reset();
        MESOperation.SetRange("Prod Order No", prodOderNo);
        MESOperation.SetRange("Operation No", operationNo);
        MESOperation.SetRange("Operation Status", MESOperation."Operation Status"::Running);

        if MESOperation.FindFirst() then
            Error('This operation is already running.');

        // we check if there is a curently worked on operation of a diferent order 
        MESOperation.Reset();
        MESOperation.SetCurrentKey("Machine No", "Last Updated At");
        MESOperation.SetRange("Machine No", machineNo);

        if MESOperation.FindLast() then begin
            if MESOperation."Operation Status" = MESOperation."Operation Status"::Running then
                Error(
                    'Machine %1 is already running another operation (Order %2 - Operation %3). Pause or finish it first.',
                    MESOperation."Machine No",
                    MESOperation."Prod Order No",
                    MESOperation."Operation No"
                );
        end;


        // now we find the previous order routing line 
        PreviousProdOrderRoutingLine.Reset();
        // again why setRange and not get if we used primary keys info ? Get() is used only when we know the FULL primary key and want one exact record. in our case we may return multiple rows so get is useless here
        PreviousProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status); // we use the status of the row the get returned 
        PreviousProdOrderRoutingLine.SetRange("Prod. Order No.", prodOderNo);
        PreviousProdOrderRoutingLine.SetFilter("Operation No.", '<%1', operationNo); // means where operation number < of the current operation number exemple operation number < 30

        if PreviousProdOrderRoutingLine.FindLast() then begin // why FindLast ? let say the filter return 10 20  and our curent operation is 30  we need to use find last since we wanna the 20 not the 10 cuz our goal is to get the previous operation.

            /* now we need to do validation:
            there is 2 type of factories flow : 
            1/ the privious operation need to be fully done to move on to the next operation
            */

            /*   if PreviousProdOrderRoutingLine."Send-Ahead Quantity" = 0 then begin // means must finish the previous operation to move in the next one  (if the privious operation didnt send a ahead quantity = to u gotta wait until its fully done )
                                                                                   // we r in findLast thats why its named PreviousMesOpration + we do need to know the previous operation info from mes table

                  PreviousMESOperation.Reset();
                  //We check PreviousMESOperation because we need to validate that the previous step has actually finished or at least started before starting the current operation. PreviousRouitng line is just a plan the actual info to use to verrify is in PreviousMESOperation

                  PreviousMESOperation.SetRange("Prod Order No", prodOderNo);
                  PreviousMESOperation.SetRange("Operation No", PreviousProdOrderRoutingLine."Operation No.");
                  PreviousMESOperation.SetRange("Operation Status", PreviousMESOperation."Operation Status"::Finished);

                  if not PreviousMESOperation.FindFirst() then // i dont think findFirst or findLast matter here cuz our goal is to find any record thar show a previous operation is finished 
                      Error('Previous operation must be fully finished before starting this one.');


              end */ /*else begin
                  // 2/ no need to wait for the previous operation to be done to move on to the next one 
                  PreviousMESOperation.Reset();
                  PreviousMESOperation.SetRange("Prod Order No", prodOderNo);
                  PreviousMESOperation.SetRange("Operation No", PreviousProdOrderRoutingLine."Operation No.");
                  // no need to do PreviousMESOperation.SetRange("Operation Status",PreviousMESOperation."Operation Status"::Finished); // cuz it do not need ot be finished 

                  if not PreviousMESOperation.FindSet() then Error('Previous operation has not started yet.');
                  TotalProducedQuantity := 0;
                  repeat TotalProducedQuantity += PreviousMESOperation."Produced Quantity"; until PreviousMESOperation.Next() = 0;
                  if TotalProducedQuantity < PreviousProdOrderRoutingLine."Send-Ahead Quantity" then Error('You must produce at least %1 units in previous operation before starting this one.', PreviousProdOrderRoutingLine."Send-Ahead Quantity");*/

        end;

    end;

    local procedure InsertMESOperation(
    prodOderNo: Code[20];
    operationNo: Code[10];
    machineNo: Code[20])
    var
        MESOperation: Record "MES Operation Status";
    begin
        MESOperation.Init();
        MESOperation."Prod Order No" := prodOderNo;
        MESOperation."Operation No" := operationNo;
        MESOperation."Machine No" := machineNo;
        MESOperation."Operator Id" := UserId;
        MESOperation."Operation Status" := MESOperation."Operation Status"::Running;
        MESOperation.Insert(true);
    end;

    local procedure InsertMESOperationProgression(
    prodOderNo: Code[20];
    operationNo: Code[10];
    machineNo: Code[20])
    var
        MESOperationProgress: Record "MES Operation Progression";
        ProdOrderLine: Record "Prod. Order Line";
    begin

        // i need to do setRange otherwise i wont be able to know order details like quantity
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange("Prod. Order No.", prodOderNo);

        if not ProdOrderLine.FindFirst() then
            Error('Production order line not found.');

        MESOperationProgress.Init();
        MESOperationProgress."Prod Order No" := prodOderNo;
        MESOperationProgress."Operation No" := operationNo;
        MESOperationProgress."Machine No" := machineNo;
        MESOperationProgress."Operator Id" := UserId;
        MESOperationProgress."Item No" := ProdOrderLine."Item No.";
        MESOperationProgress."Item Description" := ProdOrderLine.Description;
        MESOperationProgress."Order Quantity" := ProdOrderLine.Quantity;
        MESOperationProgress."Produced Quantity" := 0;
        MESOperationProgress."Scrap Quantity" := 0;
        MESOperationProgress.Insert(true);
    end;

    //__________________________status real time monitoring (tab 2)____________________________________________

    procedure fetchOperationsStatus(machineNo: Code[20]): Text
    var
        MESOperationStatus: Record "MES Operation Status";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;

        LastProdOrder: Code[20];
        LastOperation: Code[10];
    begin
        Clear(MESOperationStatusArr);
        MESOperationStatus.Reset();

        /*
        our table now look like this : 
        | Machine | Order   | Op | Time  | Status   |
    | ------- | ------- | -- | ----- | -------- |
    | 110     | 1011002 | 40 | 13:30 | Running  |
    | 110     | 1011002 | 40 | 13:39 | Paused   |
    | 110     | 1011003 | 40 | 13:42 | Running  |
    | 110     | 1011003 | 40 | 13:35 | Paused   |
    | 110     | 1011001 | 30 | 13:10 | Finished |


        */
        // now sort by machine order operation and time 
        MESOperationStatus.SetCurrentKey(
            "Machine No",
            "Prod Order No",
            "Operation No",
            "Last Updated At"
        );

        MESOperationStatus.SetRange("Machine No", machineNo);
        MESOperationStatus.Ascending(false); // newest record per group is now the first so i dont need to use findlast make stuff shorter
        /*
        now our table is sorted and looks like this : 

        | Order   | Op | Time  | Status   |
    | ------- | -- | ----- | -------- |
    | 1011003 | 40 | 13:42 | Running  |
    | 1011003 | 40 | 13:35 | Paused   |
    | 1011002 | 40 | 13:39 | Paused   |
    | 1011002 | 40 | 13:30 | Running  |
    | 1011001 | 30 | 13:10 | Finished |


        */

        if MESOperationStatus.FindSet() then begin
            repeat

                // since we are sorted by newest first,
                // the first time we see a group = latest status
                if (MESOperationStatus."Prod Order No" <> LastProdOrder) or
                   (MESOperationStatus."Operation No" <> LastOperation) then begin

                    LastProdOrder := MESOperationStatus."Prod Order No"; //: = 1011003
                    LastOperation := MESOperationStatus."Operation No"; //:= 40

                    /* here earlier i did a mistake, i did setFilter where running or paused which is wrong. 
                    why ? bcz it will only fetch me rows with status running and paused as a group,ignoring thoese who have paused.
                     so Find can return me paused or running but it's wrong bcz i might have one that is paused at latest time which is not counted
                      bcz of the setFilter so no matter what the find return it will be wrong thats why we use the if else here 
                      : if the last record is running or paused add to the obj else go out and loop again */

                    if (MESOperationStatus."Operation Status" =
                        MESOperationStatus."Operation Status"::Running) or
                       (MESOperationStatus."Operation Status" =
                        MESOperationStatus."Operation Status"::Paused) then begin

                        Clear(MESOperationStatusObj);

                        MESOperationStatusObj.Add('prodOrderNo', MESOperationStatus."Prod Order No");
                        MESOperationStatusObj.Add('operationNo', MESOperationStatus."Operation No");
                        MESOperationStatusObj.Add('operationStatus', Format(MESOperationStatus."Operation Status"));
                        MESOperationStatusObj.Add('lastUpdatedAt', Format(MESOperationStatus."Last Updated At"));

                        MESOperationStatusArr.Add(MESOperationStatusObj);
                    end;
                end;

            until MESOperationStatus.Next() = 0;
        end;

        exit(JsonToTextArr(MESOperationStatusArr));
    end;

    //__________________________operation progression real time monitoring (tab 2)________________

    procedure fetchOperationsProgress(machineNo: Code[20]): Text
    var
        MESOperationProgress: Record "MES Operation Progression";
        MESOperationProgressObj: JsonObject;
        MESOperationProgressArr: JsonArray;

        LastProdOrder: Code[20];
        LastOperation: Code[10];
    begin
        Clear(MESOperationProgressArr);
        MESOperationProgress.Reset();
        MESOperationProgress.SetCurrentKey(
            "Machine No",
            "Prod Order No",
            "Operation No",
            "Last Updated At"
        );

        MESOperationProgress.SetRange("Machine No", machineNo);
        MESOperationProgress.Ascending(false);
        if MESOperationProgress.FindSet() then begin
            repeat

                if (MESOperationProgress."Prod Order No" <> LastProdOrder) or
                   (MESOperationProgress."Operation No" <> LastOperation) then begin

                    LastProdOrder := MESOperationProgress."Prod Order No";
                    LastOperation := MESOperationProgress."Operation No";

                    Clear(MESOperationProgressObj);
                    MESOperationProgressObj.Add('prodOrderNo', MESOperationProgress."Prod Order No");
                    MESOperationProgressObj.Add('operationNo', MESOperationProgress."Operation No");
                    MESOperationProgressObj.Add('producedQty', MESOperationProgress."Produced Quantity");
                    MESOperationProgressObj.Add('scrapQty', MESOperationProgress."Scrap Quantity");
                    MESOperationProgressObj.Add('orderQty', MESOperationProgress."Order Quantity");
                    // <> 0 so we dont devide on 0 
                    if MESOperationProgress."Order Quantity" <> 0 then
                        MESOperationProgressObj.Add('progressPercent',
                            (MESOperationProgress."Produced Quantity" / MESOperationProgress."Order Quantity") * 100);

                    MESOperationProgressArr.Add(MESOperationProgressObj);
                end;


            until MESOperationProgress.Next() = 0;
        end;

        exit(JsonToTextArr(MESOperationProgressArr));
    end;


    //_____________progress + status merge___________________


    procedure fetchOperationsStatusAndProgress(machineNo: Code[20]): Text
    var
        MESOperationStatus: Record "MES Operation Status";
        MESOperationProgress: Record "MES Operation Progression";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
        LastProdOrder: Code[20];
        LastOperation: Code[10];
    begin
        Clear(MESOperationStatusArr);

        MESOperationStatus.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
        MESOperationStatus.SetRange("Machine No", machineNo);
        MESOperationStatus.Ascending(false);

        if MESOperationStatus.FindSet() then begin
            repeat
                // since we are sorted by newest first,
                // the first time we see a group = latest status
                if (MESOperationStatus."Prod Order No" <> LastProdOrder) or
                   (MESOperationStatus."Operation No" <> LastOperation) then begin

                    LastProdOrder := MESOperationStatus."Prod Order No";
                    LastOperation := MESOperationStatus."Operation No";
                    // we skip the finished operations
                    if (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Running) or
                       (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Paused) then begin

                        Clear(MESOperationStatusObj);

                        // adding status fields
                        MESOperationStatusObj.Add('prodOrderNo', MESOperationStatus."Prod Order No");
                         MESOperationStatusObj.Add('machineNo', MESOperationStatus."Machine No");
                        MESOperationStatusObj.Add('operationNo', MESOperationStatus."Operation No");
                        MESOperationStatusObj.Add('operationStatus', Format(MESOperationStatus."Operation Status"));
                        MESOperationStatusObj.Add('lastUpdatedAt', Format(MESOperationStatus."Last Updated At"));


                        /*
                        so basicly for status we don't know what's there, so we explore the whole table
                        thats why we loop and doing grouping to show me all operations / orders that r not finished
                        we need the grouping and the <> check to skip dupplicates.
                        as for progress no need cuz status loop provide us with a specific operation and order number
                        so we could just do set range with these values and return us the progress fields info of this specific operation.
                        */
                        MESOperationProgress.Reset();
                        MESOperationProgress.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
                        MESOperationProgress.SetRange("Machine No", machineNo);
                        MESOperationProgress.SetRange("Prod Order No", MESOperationStatus."Prod Order No");
                        MESOperationProgress.SetRange("Operation No", MESOperationStatus."Operation No");
                        MESOperationProgress.Ascending(false);

                        // add progress fields
                        // FindFirst cuz we did ascending false so the newest row is on top
                        if MESOperationProgress.FindFirst() then begin
                            MESOperationStatusObj.Add('producedQty', MESOperationProgress."Produced Quantity");
                            MESOperationStatusObj.Add('scrapQty', MESOperationProgress."Scrap Quantity");
                            MESOperationStatusObj.Add('orderQty', MESOperationProgress."Order Quantity");
                            MESOperationStatusObj.Add('itemDescription', MESOperationProgress."Item Description");
                            if MESOperationProgress."Order Quantity" <> 0 then
                                MESOperationStatusObj.Add('progressPercent',
                                    (MESOperationProgress."Produced Quantity" / MESOperationProgress."Order Quantity") * 100);
                        end;

                        MESOperationStatusArr.Add(MESOperationStatusObj);
                    end;
                end;
            until MESOperationStatus.Next() = 0;
        end;

        /* _____________final json _____________
        [
          {
            "prodOrderNo":     "1011003",
            "operationNo":     "40",
            "operationStatus": "Running",
            "lastUpdatedAt":   "14:00",
            "producedQty":     50,
            "scrapQty":        2,
            "orderQty":        100,
            "progressPercent": 50.0
          },
          {
            "prodOrderNo":     "1011002",
            "operationNo":     "40",
            "operationStatus": "Paused",
            "lastUpdatedAt":   "13:39",
            "producedQty":     80,
            "scrapQty":        3,
            "orderQty":        100,
            "progressPercent": 80.0
          }
        ]
        */
        exit(JsonToTextArr(MESOperationStatusArr));
    end;
    //______________________________________________________________________

    procedure fetchOperationLiveData(machineNo: Code[20]; prodOderNo: Code[20];
        operationNo: Code[10]): Text
    var
        MESOperationStatus: Record "MES Operation Status";
        MESOperationProgress: Record "MES Operation Progression";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;
    begin
        Clear(MESOperationStatusArr);

        MESOperationStatus.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
        MESOperationStatus.SetRange("Machine No", machineNo);
        MESOperationStatus.SetRange("Prod Order No", prodOderNo);
        MESOperationStatus.SetRange("Operation No", operationNo);
        MESOperationStatus.Ascending(false);

        if MESOperationStatus.FindFirst() then begin

            // we skip the finished operations
            if (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Running) or
               (MESOperationStatus."Operation Status" = MESOperationStatus."Operation Status"::Paused) then begin

                Clear(MESOperationStatusObj);

                // adding status fields

                MESOperationStatusObj.Add('operationStatus', Format(MESOperationStatus."Operation Status"));

                MESOperationProgress.Reset();
                MESOperationProgress.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
                MESOperationProgress.SetRange("Machine No", machineNo);
                MESOperationProgress.SetRange("Prod Order No", MESOperationStatus."Prod Order No");
                MESOperationProgress.SetRange("Operation No", MESOperationStatus."Operation No");
                MESOperationProgress.Ascending(false);

                if MESOperationProgress.FindFirst() then begin
                    MESOperationStatusObj.Add('producedQty', MESOperationProgress."Produced Quantity");
                    MESOperationStatusObj.Add('scrapQty', MESOperationProgress."Scrap Quantity");

                    if MESOperationProgress."Order Quantity" <> 0 then
                        MESOperationStatusObj.Add('progressPercent',
                            (MESOperationProgress."Produced Quantity" / MESOperationProgress."Order Quantity") * 100);
                end;

                MESOperationStatusArr.Add(MESOperationStatusObj);
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
        InsertMESOperationProgression(machineNo, prodOderNo, operationNo, input);
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
    MESOperationProgress: Record "MES Operation Progression";
begin
    MESOperationProgress.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
    MESOperationProgress.SetRange("Machine No", machineNo);
    MESOperationProgress.SetRange("Prod Order No", prodOderNo);
    MESOperationProgress.SetRange("Operation No", operationNo);
    MESOperationProgress.Ascending(false);

    if not MESOperationProgress.FindFirst() then
        Error('Operation progression record not found.');

    if input <= 0 then
        Error('Declared quantity must be greater than zero.');

    if (MESOperationProgress."Produced Quantity" + input) > MESOperationProgress."Order Quantity" then
        Error('Declared quantity exceeds the remaining order quantity.');
end;

local procedure InsertMESOperationProgression(
    machineNo: Code[20];
    prodOderNo: Code[20];
    operationNo: Code[10];
    input: Decimal
)
var
    MESOperationProgress: Record "MES Operation Progression";
    NewMESOperationProgress: Record "MES Operation Progression";
    Total: Decimal;
begin
    MESOperationProgress.SetCurrentKey("Machine No", "Prod Order No", "Operation No", "Last Updated At");
    MESOperationProgress.SetRange("Machine No", machineNo);
    MESOperationProgress.SetRange("Prod Order No", prodOderNo);
    MESOperationProgress.SetRange("Operation No", operationNo);
    MESOperationProgress.Ascending(false);
    MESOperationProgress.FindFirst();

    Total := MESOperationProgress."Produced Quantity" + input;

    NewMESOperationProgress.Init();
    NewMESOperationProgress."Prod Order No"     := prodOderNo;
    NewMESOperationProgress."Operation No"      := operationNo;
    NewMESOperationProgress."Machine No"        := machineNo;
    NewMESOperationProgress."Operator Id"       := UserId;
    NewMESOperationProgress."Item No"           := MESOperationProgress."Item No";
    NewMESOperationProgress."Item Description"  := MESOperationProgress."Item Description";
    NewMESOperationProgress."Order Quantity"    := MESOperationProgress."Order Quantity";
    NewMESOperationProgress."Produced Quantity" := Total;
    NewMESOperationProgress."Scrap Quantity"    := 0;
    NewMESOperationProgress.Insert(true);
end;
    


}

