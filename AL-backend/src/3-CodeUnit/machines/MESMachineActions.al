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


    procedure getMachineOrders(machineNo: Text): Text
    var
        ProductOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductOrderLine: Record "Prod. Order Line";
        ProductOrderRoutingLineArr: JsonArray;
        ProductOrderRoutingLineObj: JsonObject;
    begin

        if MachineNo = '' then Error('Machine Number is required');
        ProductOrderRoutingLine.SetRange(Type, ProductOrderRoutingLine.Type::"Machine Center"); // the "::" used to acess the available options of the fild "Type" by options I mean enum values.
        ProductOrderRoutingLine.SetRange("No.", MachineNo);
        // setRange used for simple comperation , setFilter for complex comperation
        ProductOrderRoutingLine.SetFilter(Status, '%1|%2|%3', // %1|%2|%3 means get me orders where status = ? or ? or ?
                                          ProductOrderRoutingLine.Status::Planned,
                                          ProductOrderRoutingLine.Status::"Firm Planned",
                                          ProductOrderRoutingLine.Status::Released
                                         );

        if ProductOrderRoutingLine.FindSet() then
            repeat
                Clear(ProductOrderRoutingLineObj);
                ProductOrderLine.SetRange("Prod. Order No.", ProductOrderRoutingLine."Prod. Order No.");

                if ProductOrderLine.FindFirst() then begin
                    ProductOrderRoutingLineObj.Add('orderNo', ProductOrderRoutingLine."Prod. Order No.");
                    ProductOrderRoutingLineObj.Add('status', Format(ProductOrderRoutingLine.Status));
                    ProductOrderRoutingLineObj.Add('operationNo', ProductOrderRoutingLine."Operation No.");
                    ProductOrderRoutingLineObj.Add('plannedStart', ProductOrderRoutingLine."Starting Date-Time");
                    // Order description
                    ProductOrderRoutingLineObj.Add('plannedEnd', ProductOrderRoutingLine."Ending Date-Time");
                    ProductOrderRoutingLineObj.Add('itemNo', ProductOrderLine."Item No.");
                    ProductOrderRoutingLineObj.Add('ItemDescription', ProductOrderLine.Description);
                    // Operation description
                    ProductOrderRoutingLineObj.Add('OrderQuantity', ProductOrderLine.Quantity);
                    ProductOrderRoutingLineObj.Add('operationDescription', ProductOrderRoutingLine.Description);

                    ProductOrderRoutingLineArr.Add(ProductOrderRoutingLineObj);
                end;

            until ProductOrderRoutingLine.Next() = 0;

        exit(JsonToTextArr(ProductOrderRoutingLineArr));

    end;
    // you need to explain this why did you remove the arrtotext func just to replace it with another func that does thhe same thing

    procedure startOperation(
        ProdOderNo: code[20];
        OperationNo: Code[10]
    ): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PreviousProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MESOperation: Record "MES Operation";
        PreviousMESOperation: Record "MES Operation";
        TotalProducedQuantity: Decimal;

    begin
        //get current order routing line mainly to know what operation u on  10 20 30 

        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOderNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);

        if not ProdOrderRoutingLine.FindFirst() then
            Error('Routing line not found.');

        // now we prevent starting the same operation twice

        MESOperation.Reset();
        MESOperation.SetRange("Prod Order No", ProdOderNo);
        MESOperation.SetRange("Operation No", OperationNo);
        MESOperation.SetRange("Operation Status", MESOperation."Operation Status"::Running);

        if MESOperation.FindFirst() then
            Error('This operation is already running.');

        // now we find the previous order routing line 
        PreviousProdOrderRoutingLine.Reset();
        // again why setRange and not get if we used primary keys info ? Get() is used only when we know the FULL primary key and want one exact record. in our case we may return multiple rows so get is useless here
        PreviousProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status); // we use the status of the row the get returned 
        PreviousProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOderNo);
        PreviousProdOrderRoutingLine.SetFilter("Operation No.", '<%1', OperationNo); // means where operation number < of the current operation number exemple operation number < 30

        if PreviousProdOrderRoutingLine.FindLast() then begin // why FindLast ? let say the filter return 10 20  and our curent operation is 30  we need to use find last since we wanna the 20 not the 10 cuz our goal is to get the previous operation.

            /* now we need to do validation:
            there is 2 type of factories flow : 
            1/ the privious operation need to be fully done to move on to the next operation
            */

            if PreviousProdOrderRoutingLine."Send-Ahead Quantity" = 0 then begin // means must finish the previous operation to move in the next one  (if the privious operation didnt send a ahead quantity = to u gotta wait until its fully done )
                                                                                 // we r in findLast thats why its named PreviousMesOpration + we do need to know the previous operation info from mes table
                PreviousMESOperation.Reset();
                //We check PreviousMESOperation because we need to validate that the previous step has actually finished or at least started before starting the current operation. PreviousRouitng line is just a plan the actual info to use to verrify is in PreviousMESOperation

                PreviousMESOperation.SetRange("Prod Order No", ProdOderNo);
                PreviousMESOperation.SetRange("Operation No", PreviousProdOrderRoutingLine."Operation No.");
                PreviousMESOperation.SetRange("Operation Status", PreviousMESOperation."Operation Status"::Finished);

                if not PreviousMESOperation.FindFirst() then // i dont think findFirst or findLast matter here cuz our goal is to find any record thar show a previous operation is finished 
                    Error('Previous operation must be fully finished before starting this one.');

            end else begin
                // 2/ no need to wait for the previous operation to be done to move on to the next one 
                PreviousMESOperation.Reset();
                PreviousMESOperation.SetRange("Prod Order No", ProdOderNo);
                PreviousMESOperation.SetRange("Operation No", PreviousProdOrderRoutingLine."Operation No.");
                // no need to do PreviousMESOperation.SetRange("Operation Status",PreviousMESOperation."Operation Status"::Finished); // cuz it do not need ot be finished 

                if not PreviousMESOperation.FindFirst() then
                    Error('Previous operation has not started yet.');


                if PreviousMESOperation."Produced Quantity" <
               PreviousProdOrderRoutingLine."Send-Ahead Quantity" then // u see in the erp this firld send ahead qte is determed like if it's 30  u can not start ur operation until the previous on make at least 30 units  
                    Error('Previous operation must produce at least %1 units before starting this operation.', PreviousProdOrderRoutingLine."Send-Ahead Quantity");
            end;

        end;

        MESOperation.Init();
        MESOperation."Prod Order No" := ProdOderNo;
        MESOperation."Order Status" := ProdOrderRoutingLine.Status;
        MESOperation."Operation No" := OperationNo;
        MESOperation."Machine No" := ProdOrderRoutingLine."No.";
        MESOperation."Operator Id" := UserId;
        MESOperation."Item No" := '';
        MESOperation."Item Description" := '';
        MESOperation."Order Quantity" := ProdOrderRoutingLine."Input Quantity";
        MESOperation."Produced Quantity" := 0;
        MESOperation."Scrap Quantity" := 0;
        MESOperation."Operation Status" := MESOperation."Operation Status"::Running;
        MESOperation."Start DateTime" := CurrentDateTime;
        MESOperation.Insert();

        exit(true);

    end;






}

