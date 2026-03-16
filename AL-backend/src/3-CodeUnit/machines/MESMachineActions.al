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

    //______________________________________________________________________

    procedure fetchOperationsStatus(machineNo: Code[20]): Text
    var
        MESOperationStatus: Record "MES Operation Status";
        MESOperationStatusObj: JsonObject;
        MESOperationStatusArr: JsonArray;

        LastProdOrder: Code[20];
        LastOperation: Code[10];
    begin
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

    /*procedure fetchOperationProgression(
    MachineNo: Code[20]
): Text
    var
        MESOperation: Record "MES Operation";
        MESOperationObj: JsonObject;
        MESOperationArr: JsonArray;
        ResultTxt: Text;
    begin
        MESOperation.Reset();
        MESOperation.SetRange("Machine No", MachineNo);

        MESOperation.SetFilter(
            "Operation Status",
            '%1|%2',
            MESOperation."Operation Status"::Running,
            MESOperation."Operation Status"::Paused
        );

        if MESOperation.FindSet() then begin
            repeat
                Clear(MESOperationObj);

                MESOperationObj.Add('ProdOrderNo', MESOperation."Prod Order No");
                MESOperationObj.Add('OperationNo', MESOperation."Operation No");
                MESOperationObj.Add('MachineNo', MESOperation."Machine No");
                MESOperationObj.Add('OrderQuantity', MESOperation."Order Quantity");
                MESOperationObj.Add('ProducedQuantity', MESOperation."Produced Quantity");
                MESOperationObj.Add('ScrapQuantity', MESOperation."Scrap Quantity");
                MESOperationObj.Add('OperationStatus', Format(MESOperation."Operation Status"));
                MESOperationObj.Add('StartDateTime', MESOperation."Start DateTime");
                MESOperationObj.Add('EndDateTime', MESOperation."End DateTime");
                MESOperationObj.Add('LastUpdatedAt', MESOperation."Last Updated At");

                MESOperationArr.Add(MESOperationObj);
            until MESOperation.Next() = 0;
        end;



        exit(JsonToTextArr(MESOperationArr));
    end;*/





}

