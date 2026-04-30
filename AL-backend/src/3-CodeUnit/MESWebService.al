codeunit 50126 "MES Web Service"
{
    var
        UnboundActions: Codeunit "MES Unbound Actions";
        MachineFetch: Codeunit "MES Machine Fetch";
        MachineWrite: Codeunit "MES Machine Write";
        Tools: Codeunit "MES Tool Functions";
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

    procedure FetchMachines(workCenterNoJson: Text): Text
    begin
        exit(MachineFetch.FetchMachines(workCenterNoJson));
    end;

    procedure getMachineOrders(machineNo: Text): Text
    begin
        exit(MachineFetch.getMachineOrders(machineNo));
    end;

    procedure fetchOngoingOperationsState(machineNo: Code[20]): Text
    begin
        exit(MachineFetch.fetchOperationsStatusAndProgress(machineNo, false));
    end;

    procedure fetchOperationsHistory(machineNo: Code[20]): Text
    begin
        exit(MachineFetch.fetchOperationsStatusAndProgress(machineNo, true));
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

        exit(MachineWrite.finishOperation(token, machineNo, prodOrderNo, operationNo));
    end;

    procedure cancelOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin

        exit(MachineWrite.cancelOperation(token, machineNo, prodOrderNo, operationNo));
    end;

    procedure pauseOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin

        exit(MachineWrite.pauseOperation(token, machineNo, prodOrderNo, operationNo));
    end;

    procedure resumeOperation(machineNo: Code[20]; prodOrderNo: Code[20]; operationNo: Code[10]; token: Text): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        exit(MachineWrite.resumeOperation(token, machineNo, prodOrderNo, operationNo));
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
        onBehalfOfUserId: Text;
        materialId: Code[20]

    ): Text
    var
        DeclaredById: Code[50];
        OperatorId: Code[50];
        ErrorResult: Text;
    begin
        if not TryResolveIdentity(token, onBehalfOfUserId, DeclaredById, OperatorId, ErrorResult) then
            exit(ErrorResult);

        exit(MachineWrite.declareScrap(executionId, description, scrapCode, quantity, OperatorId, DeclaredById, materialId));
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
        if not AuthMgt.ValidateToken(token, CallerUser, AuthToken, errorMessage) then begin
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

    procedure fetchMachineDashboard(hoursBack: Integer; workCenterNoJson: Text): Text
    begin
        exit(MachineFetch.fetchMachineDashboard(hoursBack, workCenterNoJson));
    end;

    // Returns production orders, optionally filtered by status, work center, or machine.
    // statusFilter  : '' = all, or comma-separated list of: 'Planned','Firm Planned','Released','Finished'
    // workCenterNo  : '' = all work centers
    // machineNo     : '' = all machines
    procedure fetchProductionOrders(statusFilter: Text; workCenterNo: Text; machineNo: Text): Text
    begin
        exit(Tools.fetchProductionOrders(statusFilter, workCenterNo, machineNo));
    end;

    // Returns a per-work-center summary: machine counts, operation queue,
    // active operators, produced quantity, and scrap for the window.
    // workCenterNoJson : JSON array of work center numbers, e.g. '["100","200"]'.
    //                    Pass '[]' to get all work centers.
    // hoursBack        : lookback window for produced/scrap aggregation.
    procedure fetchWorkCenterSummary(workCenterNoJson: Text; hoursBack: Decimal): Text
    begin
        exit(Tools.fetchWorkCenterSummary(workCenterNoJson, hoursBack));
    end;

    // Returns one row per MES user with their current activity status,
    // machine assignment, operation counts, and scrap for the time window.
    // workCenterNoJson : JSON array of WC numbers to scope the result.
    //                    Pass '[]' to return all users.
    // hoursBack        : lookback window for produced/scrap aggregation.
    procedure fetchOperatorSummary(workCenterNoJson: Text; hoursBack: Decimal): Text
    begin
        exit(Tools.fetchOperatorSummary(workCenterNoJson, hoursBack));
    end;

    // Returns data scoped to the authenticated user:
    //   - Operations started/paused/finished during the window
    //   - Machines interacted with
    //   - Produced and scrap quantities
    // token     : session token — identifies the calling user.
    // hoursBack : lookback window (pass shift length for shift-scoped queries).
    procedure fetchMyData(token: Text; hoursBack: Decimal): Text
    begin
        exit(Tools.fetchMyData(token, hoursBack));
    end;

    // Returns scrap aggregated by order, operation, machine, work center, and reason.
    // Any filter that is empty string means "all".
    //
    // hoursBack      : lookback window in hours.
    // prodOrderNo    : filter to a specific production order.
    // operationNo    : filter to a specific operation (requires prodOrderNo).
    // machineNo      : filter to a specific machine.
    // workCenterNo   : filter to a specific work center (matches machine's WC).
    // operatorId     : filter to a specific operator's declared scrap.
    procedure fetchScrapSummary(
        hoursBack: Decimal;
        prodOrderNo: Code[20];
        operationNo: Code[10];
        machineNo: Code[20];
        workCenterNo: Code[20];
        operatorId: Code[50]
    ): Text
    begin
        exit(Tools.fetchScrapSummary(hoursBack, prodOrderNo, operationNo, machineNo, workCenterNo, operatorId));
    end;

    // Returns delayed / blocked operations ranked by wait time.
    // An operation is "delayed" when its planned end date-time is past and it
    // is not yet finished, or when it is in Paused state longer than
    // pauseThresholdMinutes.
    // workCenterNoJson      : JSON array of WC numbers, or '[]' for all.
    // pauseThresholdMinutes : operations paused longer than this are flagged.
    procedure fetchDelayReport(workCenterNoJson: Text; pauseThresholdMinutes: Decimal): Text
    begin
        exit(Tools.fetchDelayReport(workCenterNoJson, pauseThresholdMinutes));
    end;

    // Returns component consumption vs. planned BOM quantity per execution,
    // flagging over- and under-consumption.
    // Any filter that is empty string means "all".
    //
    // prodOrderNo  : limit to a specific production order.
    // operationNo  : limit to a specific operation (use with prodOrderNo).
    // machineNo    : limit to a specific machine.
    // hoursBack    : only include executions that started within this window.
    //               Pass 0 to include all time.
    procedure fetchConsumptionSummary(prodOrderNo: Code[20]; operationNo: Code[10]; machineNo: Code[20]; hoursBack: Decimal): Text
    begin
        exit(Tools.fetchConsumptionSummary(prodOrderNo, operationNo, machineNo, hoursBack));
    end;


    // Returns a comprehensive supervisor overview for a shift or time window:
    //   - Stopped machines under supervision
    //   - Delayed / paused operations
    //   - Idle operators (logged in, no running op)
    //   - Scrap totals and high-scrap operations
    //   - Produced vs. order quantity (progress)
    // Suitable for: shift start briefing, handover, "what should I check first?"
    //
    // workCenterNoJson      : JSON array of WC numbers the supervisor covers.
    // hoursBack             : lookback window (use shift length).
    // pauseThresholdMinutes : paused ops exceeding this are flagged as abnormal.
    procedure fetchSupervisorOverview(workCenterNoJson: Text; hoursBack: Decimal; pauseThresholdMinutes: Decimal): Text
    begin
        exit(Tools.fetchSupervisorOverview(workCenterNoJson, hoursBack, pauseThresholdMinutes));
    end;

    procedure AdminChangeUserRole(
            token: Text;
            targetUserId: Text;
            newRoleInt: Integer;
            workCenterListJson: Text
        ): Text
    begin
        exit(UnboundActions.AdminChangeUserRole(token, targetUserId, newRoleInt, workCenterListJson));
    end;

    
    procedure resolveBarcode(barcode: Text): Text
    begin
        exit(MachineFetch.resolveBarcode(barcode));
    end;





}