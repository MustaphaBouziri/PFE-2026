codeunit 50126 "MES Web Service"
{
    var
        UnboundActions: Codeunit "MES Unbound Actions";
        MachineFetch: Codeunit "MES Machine Fetch";
        MachineWrite: Codeunit "MES Machine Write";


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
        token: Text;
        userId: Text;
        employeeId: Text;
        authId: Text;
        roleInt: Integer;
        workCenterNo: Text): Text
    begin
        exit(UnboundActions.AdminCreateUser(token, userId, employeeId, authId, roleInt, workCenterNo));
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

    procedure FetchMachines(workCenterNo: Text): Text
    begin
        exit(MachineFetch.FetchMachines(workCenterNo));
    end;

    procedure getMachineOrders(machineNo: Text): Text
    begin
        exit(MachineFetch.getMachineOrders(machineNo));
    end;

    procedure startOperation(prodOrderNo: Code[20]; operationNo: Code[10]; machineNo: Code[20]): Text
    begin
        exit(MachineWrite.startOperation(prodOrderNo, operationNo, machineNo));
    end;

    procedure fetchOperationsStatusAndProgress(machineNo: Code[20]; fetchFinished: Boolean): Text
    begin
        exit(MachineFetch.fetchOperationsStatusAndProgress(machineNo, fetchFinished));
    end;

    procedure fetchOperationLiveData(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchOperationLiveData(machineNo, prodOrderNo, operationNo));
    end;

    procedure declareProduction(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; input: Decimal): Text
    begin
        exit(MachineWrite.declareProduction(machineNo, prodOrderNo, operationNo, input));
    end;

    procedure fetchProductionCycles(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchProductionCycles(machineNo, prodOrderNo, operationNo));
    end;

    procedure fetchBom(prodOrderNo: Code[20]; operationNo: Code[10]): Text
    begin
        exit(MachineFetch.fetchBom(prodOrderNo, operationNo));
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
}
