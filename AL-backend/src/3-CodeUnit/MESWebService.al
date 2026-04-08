codeunit 50126 "MES Web Service"
{
    var
        UnboundActions: Codeunit "MES Unbound Actions";
        MachineFetch: Codeunit "MES Machine Fetch";
        MachineWrite: Codeunit "MES Machine Write";
        AuthMgt: Codeunit "MES Auth Mgt";

    // ── Auth endpoints (no token write logic) ─────────────────────────────────

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

    // ── Admin endpoints ───────────────────────────────────────────────────────

    [NonDebuggable]
    procedure AdminCreateUser(
        token: Text;
        userId: Text;
        employeeId: Text;
        roleInt: Integer;
        workCenterListJson: Text
    ): Text
    begin
        exit(UnboundActions.AdminCreateUser(token, userId, employeeId, roleInt, workCenterListJson));
    end;

    procedure fetchAllMESUsers(): Text
    begin
        exit(UnboundActions.fetchAllMESUsers());
    end;

    procedure fetchMESUsersByWC(wcId: Code[20]): Text
    begin
        exit(UnboundActions.fetchMESUsersByWC(wcId));
    end;

    procedure AdminSetPassword(token: Text; userId: Text; newPassword: Text): Text
    begin
        exit(UnboundActions.AdminSetPassword(token, userId, newPassword));
    end;

    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    begin
        exit(UnboundActions.AdminSetActive(token, userId, isActive));
    end;

    // ── Read endpoints (no identity needed) ───────────────────────────────────

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
        exit(MachineFetch.fetchAllItemBarcodes());
    end;

    // ── Write endpoints ───────────────────────────────────────────────────────
    // All write procedures follow the same three-step pattern:
    //   ResolveIdentity → (optional) ValidateProxy → Delegate to MachineWrite

    procedure startOperation(
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20];
        token: Text
    ): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        exit(MachineWrite.startOperation(prodOrderNo, operationNo, machineNo, OperatorId));
    end;

    procedure declareProduction(
        machineNo: Code[20];
        prodOrderNo: Code[20];
        operationNo: Code[10];
        input: Decimal;
        token: Text;
        onBehalfOfUserId: Text
    ): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        if not TryResolveIdentity(token, onBehalfOfUserId, DeclaredById, OperatorId, ErrorResult) then
            exit(ErrorResult);

        exit(MachineWrite.declareProduction(machineNo, prodOrderNo, operationNo, input, OperatorId, DeclaredById));
    end;

    procedure finishOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin

        exit(MachineWrite.finishOperation(token,machineNo, prodOrderNo, operationNo));
    end;

    procedure cancelOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin

        exit(MachineWrite.cancelOperation(token,machineNo, prodOrderNo, operationNo));
    end;

    procedure pauseOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin

        exit(MachineWrite.pauseOperation(token,machineNo, prodOrderNo, operationNo));
    end;

    procedure resumeOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        exit(MachineWrite.resumeOperation(token,machineNo, prodOrderNo, operationNo));
    end;

    procedure insertScans(executionId: Code[50]; scansJson: Text; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        if not TryResolveIdentity(token, '', DeclaredById, OperatorId, ErrorResult) then
            exit(ErrorResult);

        exit(MachineWrite.insertScans(executionId, scansJson, OperatorId, DeclaredById));
    end;

    procedure declareScrap(
        executionId: Code[50];
        description: Text;
        scrapCode: Code[10];
        quantity: Decimal;
        token: Text;
        onBehalfOfUserId: Text
    ): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        if not TryResolveIdentity(token, onBehalfOfUserId, DeclaredById, OperatorId, ErrorResult) then
            exit(ErrorResult);

        exit(MachineWrite.declareScrap(executionId, description, scrapCode, quantity, OperatorId, DeclaredById));
    end;

    // ── Private identity helpers ──────────────────────────────────────────────

    // Validates the token, resolves DeclaredById from it, then resolves OperatorId:
    //   - If onBehalfOfUserId is empty → OperatorId = DeclaredById (self-declaration)
    //   - If non-empty → validate proxy permission and set OperatorId = onBehalfOfUserId
    // Returns false and populates ErrorResult if any check fails.
    local procedure TryResolveIdentity(
        token: Text;
        onBehalfOfUserId: Text;
        var DeclaredById: Code[50];
        var OperatorId: Code[50];
        var ErrorResult: Text
    ): Boolean
    var
        CallerUser: Record "MES User";
        AuthToken: Record "MES Auth Token";
        MachineValidation: Codeunit "MES Machine Validation";
        TargetUserId: Code[50];
        JsonHelper: Codeunit "MES Json Helper";
        errorMessage: Text;
    begin
        if not AuthMgt.ValidateToken(token, CallerUser, AuthToken,errorMessage) then begin
            ErrorResult := JsonHelper.BuildError('Unauthorized', errorMessage);
            exit(false);
        end;

        AuthMgt.TouchToken(AuthToken);
        DeclaredById := CallerUser."User Id";

        if onBehalfOfUserId = '' then begin
            // Self-declaration: operator and submitter are the same person
            OperatorId := DeclaredById;
            exit(true);
        end;

        // Proxy declaration: supervisor submitting on behalf of an operator
        TargetUserId := CopyStr(onBehalfOfUserId, 1, 50);

        if not MachineValidation.TryValidateProxyDeclaration(DeclaredById, TargetUserId) then begin
            ErrorResult := JsonHelper.BuildError('Forbidden', GetLastErrorText());
            ClearLastError();
            exit(false);
        end;

        OperatorId := TargetUserId;
        exit(true);
    end;

    procedure fetchActivityLog(hoursBack: Integer): Text
    begin
        exit(MachineFetch.fetchActivityLog(hoursBack));
    end;

    procedure fetchMachineDashboard(hoursBack: Integer): Text
    begin
        exit(MachineFetch.fetchMachineDashboard(hoursBack));
    end;





}