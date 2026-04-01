codeunit 50126 "MES Web Service"
{
    var
        UnboundActions: Codeunit "MES Unbound Actions";
        MachineFetch: Codeunit "MES Machine Fetch";
        MachineWrite: Codeunit "MES Machine Write";

    // These are the functions that handle authentication and user administration.
    [NonDebuggable]
    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    begin
        exit(UnboundActions.Login(userId, password, deviceId));
    end;

    procedure Logout(token: Text): Text
    begin
        exit(UnboundActions.Logout(token));
    end;

    procedure Me(token: Text): Text
    begin
        exit(UnboundActions.Me(token));
    end;

    [NonDebuggable]
    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Text
    begin
        exit(UnboundActions.ChangePassword(token, oldPassword, newPassword));
    end;

    procedure AdminCreateUser(
        userId: Text;
        employeeId: Text;
        authId: Text;
        roleInt: Integer;
        workCenterListJson: Text): Text
    begin
        exit(UnboundActions.AdminCreateUser(userId, employeeId, authId, roleInt,workCenterListJson));
    end;

    [NonDebuggable]
    procedure AdminSetPassword(token: Text; userId: Text; newPassword: Text): Text
    begin
        exit(UnboundActions.AdminSetPassword(token, userId, newPassword));
    end;

    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    begin
        exit(UnboundActions.AdminSetActive(token, userId, isActive));
    end;

    // These are the functions that fetch and read MES data.
    procedure FetchMachines(workCenterNo: Text): Text
    begin
        exit(MachineFetch.FetchMachines(workCenterNo));
    end;

    procedure getMachineOrders(machineNo: Text): Text
    begin
        exit(MachineFetch.getMachineOrders(machineNo));
    end;

    procedure fetchOperationsStatusAndProgress(machineNo: Code[20]; fetchFinished: Boolean): Text
    begin
        exit(MachineFetch.fetchOperationsStatusAndProgress(machineNo, fetchFinished));
    end;

    procedure fetchOperationLiveData(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchOperationLiveData(machineNo, prodOrderNo, operationNo));
    end;

    procedure fetchProductionCycles(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchProductionCycles(machineNo, prodOrderNo, operationNo));
    end;

    procedure fetchBom(prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchBom(prodOrderNo, operationNo));
    end;

    procedure fetchAllItemBarcodes(): Text
    begin
        exit(MachineFetch.fetchAllItemBarcodes())
    end;

    // These are the functions that insert, update, and write MES operation data.
    procedure startOperation(prodOrderNo: Code[20]; operationNo: Code[10]; machineNo: Code[20]): Text
    begin
        exit(MachineWrite.startOperation(prodOrderNo, operationNo, machineNo));
    end;

    procedure declareProduction(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; input: Decimal): Text
    begin
        exit(MachineWrite.declareProduction(machineNo, prodOrderNo, operationNo, input));
    end;

    procedure finishOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineWrite.finishOperation(machineNo, prodOrderNo, operationNo));
    end;

    procedure cancelOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineWrite.cancelOperation(machineNo, prodOrderNo, operationNo));
    end;

    procedure pauseOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineWrite.pauseOperation(machineNo, prodOrderNo, operationNo));
    end;

    procedure resumeOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineWrite.resumeOperation(machineNo, prodOrderNo, operationNo));
    end;

    procedure insertScans(executionId: Code[50]; scansJson: Text): Text
    begin
        exit(MachineWrite.insertScans(executionId, scansJson));
    end;

    procedure declareScrap(
        executionId: Code[50];
        description: Text;
        scrapCode: Code[10];
        quantity: Decimal
    ): Text
    begin
        exit(MachineWrite.declareScrap(executionId, description, scrapCode, quantity))
    end;
}