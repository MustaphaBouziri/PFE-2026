// =============================================================================
// Codeunit: MES Machine Actions
// ID      : 50130
// Domain  : Machines / 3-CodeUnits
// Purpose : Business logic + OData response builder for machine list queries.
//           Called by the MES frontend to populate the machine list screen
//           for a given work center.
//
// PUBLISH AS WEB SERVICE
//   Register this codeunit in BC Web Services:
//     Object Type  = Codeunit
//     Object ID    = 50130
//     Service Name = MESMachinesActionsEndpoints
//     Published    = true
//
// ENDPOINT
//   POST  .../ODataV4/MESMachinesActionsEndpoints_FetchMachines
//   Body  : { "workCenterNo": "WC-01" }
//   Return: JSON array — see FetchMachines() return shape below.
//
// REAL-TIME STATUS DESIGN
//   MES Machine Status may have multiple rows per machine (history log).
//   FindLast() retrieves only the most recent status record.
//   Default to status "Idle" and empty order when no status row exists yet.
// =============================================================================
codeunit 50130 "MES Machine Actions"
{
    /// <summary>
    /// Returns all machines for a work center with their latest real-time status.
    ///
    /// Return shape (JSON array):
    /// [
    ///   {
    ///     "machineNo"    : "MC-01",
    ///     "machineName"  : "CNC 1",
    ///     "status"       : "Idle",
    ///     "currentOrder" : ""
    ///   },
    ///   ...
    /// ]
    /// </summary>
    procedure FetchMachines(workCenterNo: Text): Text
    var
        Machine: Record "Machine Center";
        StatusRec: Record "MES Machine Status";
        MachineArr: JsonArray;
        MachineObj: JsonObject;
    begin
        if workCenterNo = '' then
            Error('Work Center Number is required.');

        Machine.SetRange("Work Center No.", workCenterNo);

        if Machine.FindSet() then
            repeat
                Clear(MachineObj);

                // Set defaults — overwritten below if a status record exists.
                MachineObj.Add('machineNo',    Machine."No.");
                MachineObj.Add('machineName',  Machine."Name");
                MachineObj.Add('status',       'Idle');
                MachineObj.Add('currentOrder', '');

                StatusRec.Reset();
                StatusRec.SetRange("Machine No.", Machine."No.");
                if StatusRec.FindLast() then begin
                    // FindLast() is intentional — we want the most recent status entry.
                    MachineObj.Replace('status',       Format(StatusRec.Status));
                    MachineObj.Replace('currentOrder', StatusRec."Current Prod. Order No.");
                end;

                MachineArr.Add(MachineObj);
            until Machine.Next() = 0;

        exit(ArrayToText(MachineArr));
    end;

    local procedure ArrayToText(J: JsonArray): Text
    var
        T: Text;
    begin
        J.WriteTo(T);
        exit(T);
    end;
}
