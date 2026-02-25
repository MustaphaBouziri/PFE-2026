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


}

