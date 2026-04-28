codeunit 50128 "MES Tool Functions"
{
    // =========================================================================
    // these are the endpoint designed as tools for the ai module and that 
    // provide info that is not available in the rest of the endpoints 
    // =========================================================================

    procedure fetchOperatorSummary(workCenterNoJson: Text; hoursBack: Decimal): Text
    var
        MESUser: Record "MES User";
        MESUserEI: Record "MES User Execution Interaction";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        MESProgress: Record "MES Operation Progression";
        Employee: Record Employee;
        UserArr: JsonArray;
        UserObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        WorkCenterFilter: Text;
        TotalProduced: Decimal;
        TotalScrap: Decimal;
        OpsCompleted: Integer;
        OpsPaused: Integer;
        IsLoggedIn: Boolean;
        IsActiveOnMachine: Boolean;
        CurrentMachineNo: Text;
        CurrentOrderNo: Text;
        CurrentOpStatus: Text;
    begin
        Clear(UserArr);

        CutoffTime := GetCutoffTime(hoursBack);
        WorkCenterFilter := BuildWorkCenterFilter(workCenterNoJson);

        MESUser.Reset();

        if not MESUser.FindSet() then
            exit(JsonHelper.JsonToTextArr(UserArr));

        repeat
            if IsUserInExactWorkCenterScope(MESUser, WorkCenterFilter) then begin
                Clear(UserObj);

                TotalProduced := 0;
                TotalScrap := 0;
                OpsCompleted := 0;
                OpsPaused := 0;
                IsLoggedIn := IsUserLoggedInNow(MESUser);
                IsActiveOnMachine := false;
                CurrentMachineNo := '';
                CurrentOrderNo := '';
                CurrentOpStatus := '';

                MESUserEI.Reset();
                MESUserEI.SetRange("User Id", MESUser."User Id");

                if MESUserEI.FindSet() then
                    repeat
                        if MESExecution.Get(MESUserEI."Execution Id") then begin
                            if MESExecution."Start Time" >= CutoffTime then begin
                                if FindLatestOperatorProgress(MESExecution, MESUser, MESProgress) then
                                    TotalProduced += MESProgress."Cycle Quantity";

                                TotalScrap += SumOperatorScrapForExecution(MESExecution, MESUser);

                                if FindLatestExecutionState(MESExecution, MESState) then begin
                                    if MESState."Operation Status" = MESState."Operation Status"::Finished then
                                        OpsCompleted += 1;

                                    if MESState."Operation Status" = MESState."Operation Status"::Paused then
                                        OpsPaused += 1;

                                    if MESState."Operation Status" = MESState."Operation Status"::Running then begin
                                        IsActiveOnMachine := true;
                                        CurrentMachineNo := MESExecution."Machine No";
                                        CurrentOrderNo := MESExecution."Prod Order No";
                                        CurrentOpStatus := Format(MESState."Operation Status");
                                    end;
                                end;
                            end;
                        end;
                    until MESUserEI.Next() = 0;

                UserObj.Add('userId', MESUser."User Id");
                UserObj.Add('role', Format(MESUser.Role));
                UserObj.Add('isActive', MESUser."Is Active");
                UserObj.Add('isLoggedIn', IsLoggedIn);
                UserObj.Add('isActiveOnMachine', IsActiveOnMachine);
                UserObj.Add('currentMachineNo', CurrentMachineNo);
                UserObj.Add('currentOrderNo', CurrentOrderNo);
                UserObj.Add('currentOpStatus', CurrentOpStatus);
                UserObj.Add('totalProducedQty', TotalProduced);
                UserObj.Add('totalScrapQty', TotalScrap);
                UserObj.Add('completedOpsCount', OpsCompleted);
                UserObj.Add('pausedOpsCount', OpsPaused);

                if Employee.Get(MESUser."Employee ID") then begin
                    UserObj.Add('fullName', Employee.FullName());
                    UserObj.Add('email', Employee."E-Mail");
                end else begin
                    UserObj.Add('fullName', '');
                    UserObj.Add('email', '');
                end;

                UserArr.Add(UserObj);
            end;
        until MESUser.Next() = 0;

        exit(JsonHelper.JsonToTextArr(UserArr));
    end;

    procedure fetchProductionOrders(statusFilter: Text; workCenterNo: Text; machineNo: Text): Text
    var
        ProdOrderHeader: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        OrderArr: JsonArray;
        OrderObj: JsonObject;
        RoutingArr: JsonArray;
        JsonHelper: Codeunit "MES Json Helper";
        TotalProduced: Decimal;
        HasRunningOp: Boolean;
    begin
        Clear(OrderArr);

        ProdOrderHeader.Reset();
        ApplyProductionOrderStatusFilter(ProdOrderHeader, statusFilter);

        if not ProdOrderHeader.FindSet() then
            exit(JsonHelper.JsonToTextArr(OrderArr));

        repeat
            if ProductionOrderMatchesRoutingFilters(ProdOrderHeader, workCenterNo, machineNo) then begin
                Clear(OrderObj);
                Clear(RoutingArr);

                TotalProduced := SumProductionOrderProducedQuantity(ProdOrderHeader);
                HasRunningOp := ProductionOrderHasRunningOperation(ProdOrderHeader);

                BuildProductionOrderRoutingSummary(ProdOrderHeader, RoutingArr);

                ProdOrderLine.Reset();
                ProdOrderLine.SetRange("Prod. Order No.", ProdOrderHeader."No.");
                ProdOrderLine.FindFirst();

                OrderObj.Add('orderNo', ProdOrderHeader."No.");
                OrderObj.Add('status', Format(ProdOrderHeader.Status));
                OrderObj.Add('description', ProdOrderHeader.Description);
                OrderObj.Add('itemNo', ProdOrderLine."Item No.");
                OrderObj.Add('itemDescription', ProdOrderLine.Description);
                OrderObj.Add('orderQuantity', ProdOrderLine.Quantity);
                OrderObj.Add('dueDate', Format(ProdOrderHeader."Due Date", 0, 9));
                OrderObj.Add('startingDate', Format(ProdOrderHeader."Starting Date", 0, 9));
                OrderObj.Add('endingDate', Format(ProdOrderHeader."Ending Date", 0, 9));
                OrderObj.Add('totalProducedQuantity', TotalProduced);
                OrderObj.Add('hasRunningOperation', HasRunningOp);

                if ProdOrderLine.Quantity <> 0 then
                    OrderObj.Add('progressPercent', (TotalProduced / ProdOrderLine.Quantity) * 100)
                else
                    OrderObj.Add('progressPercent', 0);

                OrderObj.Add('operations', RoutingArr);

                OrderArr.Add(OrderObj);
            end;
        until ProdOrderHeader.Next() = 0;

        exit(JsonHelper.JsonToTextArr(OrderArr));
    end;

    procedure fetchWorkCenterSummary(workCenterNoJson: Text; hoursBack: Decimal): Text
    var
        WorkCenter: Record "Work Center";
        MESUserWC: Record "MES User Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WCArr: JsonArray;
        WCObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        WorkCenterFilter: Text;
        TotalMachines: Integer;
        WorkingMachines: Integer;
        IdleMachines: Integer;
        OperatorCount: Integer;
        PendingOpsCount: Integer;
        RunningOpsCount: Integer;
        TotalProduced: Decimal;
        TotalScrap: Decimal;
    begin
        Clear(WCArr);

        CutoffTime := GetCutoffTime(hoursBack);
        WorkCenterFilter := BuildWorkCenterFilter(workCenterNoJson);

        WorkCenter.Reset();

        if WorkCenterFilter <> '' then
            WorkCenter.SetFilter("No.", WorkCenterFilter);

        if not WorkCenter.FindSet() then
            exit(JsonHelper.JsonToTextArr(WCArr));

        repeat
            Clear(WCObj);

            TotalMachines := 0;
            WorkingMachines := 0;
            IdleMachines := 0;
            OperatorCount := 0;
            PendingOpsCount := 0;
            RunningOpsCount := 0;
            TotalProduced := 0;
            TotalScrap := 0;

            CalculateWorkCenterMachineSummary(
                WorkCenter,
                CutoffTime,
                TotalMachines,
                WorkingMachines,
                IdleMachines,
                TotalProduced,
                TotalScrap);

            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
            ProdOrderRoutingLine.SetFilter(
                Status,
                '%1|%2',
                ProdOrderRoutingLine.Status::"Firm Planned",
                ProdOrderRoutingLine.Status::Released);
            PendingOpsCount := ProdOrderRoutingLine.Count();

            RunningOpsCount := CountRunningOperationsForWorkCenter(WorkCenter);

            MESUserWC.Reset();
            MESUserWC.SetRange("Work Center No.", WorkCenter."No.");
            OperatorCount := MESUserWC.Count();

            WCObj.Add('workCenterNo', WorkCenter."No.");
            WCObj.Add('workCenterName', WorkCenter.Name);
            WCObj.Add('totalMachines', TotalMachines);
            WCObj.Add('workingMachines', WorkingMachines);
            WCObj.Add('idleMachines', IdleMachines);
            WCObj.Add('pendingOperationsCount', PendingOpsCount);
            WCObj.Add('runningOperationsCount', RunningOpsCount);
            WCObj.Add('assignedOperatorsCount', OperatorCount);
            WCObj.Add('totalProducedQty', TotalProduced);
            WCObj.Add('totalScrapQty', TotalScrap);

            WCArr.Add(WCObj);
        until WorkCenter.Next() = 0;

        exit(JsonHelper.JsonToTextArr(WCArr));
    end;

    procedure fetchMyData(token: Text; hoursBack: Decimal): Text
    var
        AuthMgt: Codeunit "MES Auth Mgt";
        CallerUser: Record "MES User";
        AuthToken: Record "MES Auth Token";
        MESUserEI: Record "MES User Execution Interaction";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        MESProgress: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
        Employee: Record Employee;
        ResultObj: JsonObject;
        OpsArr: JsonArray;
        ScrapArr: JsonArray;
        OpObj: JsonObject;
        ScrapObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        TotalProduced: Decimal;
        TotalScrap: Decimal;
        OpsCompleted: Integer;
        OpsPaused: Integer;
        OpsRunning: Integer;
        ErrorMessage: Text;
        LatestStateStr: Text;
        LatestDeclaredAt: DateTime;
    begin
        if not AuthMgt.ValidateToken(token, CallerUser, AuthToken, ErrorMessage) then begin
            ResultObj.Add('success', false);
            ResultObj.Add('message', ErrorMessage);
            exit(JsonHelper.JsonToText(ResultObj));
        end;

        AuthMgt.TouchToken(AuthToken);

        CutoffTime := GetCutoffTime(hoursBack);
        TotalProduced := 0;
        TotalScrap := 0;
        OpsCompleted := 0;
        OpsPaused := 0;
        OpsRunning := 0;

        MESUserEI.Reset();
        MESUserEI.SetRange("User Id", CallerUser."User Id");

        if MESUserEI.FindSet() then
            repeat
                if MESExecution.Get(MESUserEI."Execution Id") then
                    if MESExecution."Start Time" >= CutoffTime then begin
                        Clear(OpObj);

                        LatestStateStr := '';
                        LatestDeclaredAt := 0DT;

                        if FindLatestExecutionState(MESExecution, MESState) then begin
                            LatestStateStr := Format(MESState."Operation Status");
                            LatestDeclaredAt := MESState."Declared At";

                            case MESState."Operation Status" of
                                MESState."Operation Status"::Finished:
                                    OpsCompleted += 1;
                                MESState."Operation Status"::Paused:
                                    OpsPaused += 1;
                                MESState."Operation Status"::Running:
                                    OpsRunning += 1;
                            end;
                        end;

                        MESProgress.Reset();
                        MESProgress.SetRange("Execution Id", MESExecution."Execution Id");
                        MESProgress.SetRange("Operator Id", CallerUser."User Id");

                        if MESProgress.FindSet() then
                            repeat
                                TotalProduced += MESProgress."Cycle Quantity";
                            until MESProgress.Next() = 0;

                        MESScrap.Reset();
                        MESScrap.SetRange("Execution Id", MESExecution."Execution Id");
                        MESScrap.SetRange("Operator Id", CallerUser."User Id");

                        if MESScrap.FindSet() then
                            repeat
                                TotalScrap += MESScrap."Scrap Quantity";
                            until MESScrap.Next() = 0;

                        OpObj.Add('executionId', MESExecution."Execution Id");
                        OpObj.Add('prodOrderNo', MESExecution."Prod Order No");
                        OpObj.Add('operationNo', MESExecution."Operation No");
                        OpObj.Add('machineNo', MESExecution."Machine No");
                        OpObj.Add('itemNo', MESExecution."Item No");
                        OpObj.Add('itemDescription', MESExecution."Item Description");
                        OpObj.Add('orderQuantity', MESExecution."Order Quantity");
                        OpObj.Add('startTime', Format(MESExecution."Start Time", 0, 9));
                        OpObj.Add('endTime', Format(MESExecution."End Time", 0, 9));
                        OpObj.Add('latestStatus', LatestStateStr);
                        OpObj.Add('latestStatusAt', Format(LatestDeclaredAt, 0, 9));

                        OpsArr.Add(OpObj);
                    end;
            until MESUserEI.Next() = 0;

        MESScrap.Reset();
        MESScrap.SetRange("Operator Id", CallerUser."User Id");
        MESScrap.SetFilter("Declared At", '>=%1', CutoffTime);

        if MESScrap.FindSet() then
            repeat
                Clear(ScrapObj);

                if MESExecution.Get(MESScrap."Execution Id") then begin
                    ScrapObj.Add('executionId', MESScrap."Execution Id");
                    ScrapObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    ScrapObj.Add('operationNo', MESExecution."Operation No");
                    ScrapObj.Add('machineNo', MESExecution."Machine No");
                end;

                ScrapObj.Add('scrapCode', MESScrap."Scrap Code");
                ScrapObj.Add('scrapDescription', MESScrap."scrap Description");
                ScrapObj.Add('scrapNotes', MESScrap."scrap notes");
                ScrapObj.Add('scrapQuantity', MESScrap."Scrap Quantity");
                ScrapObj.Add('declaredAt', Format(MESScrap."Declared At", 0, 9));

                ScrapArr.Add(ScrapObj);
            until MESScrap.Next() = 0;

        ResultObj.Add('success', true);
        ResultObj.Add('userId', CallerUser."User Id");

        if Employee.Get(CallerUser."Employee ID") then
            ResultObj.Add('fullName', Employee.FullName())
        else
            ResultObj.Add('fullName', '');

        ResultObj.Add('totalProducedQty', TotalProduced);
        ResultObj.Add('totalScrapQty', TotalScrap);
        ResultObj.Add('completedOpsCount', OpsCompleted);
        ResultObj.Add('pausedOpsCount', OpsPaused);
        ResultObj.Add('runningOpsCount', OpsRunning);
        ResultObj.Add('operations', OpsArr);
        ResultObj.Add('scrapRecords', ScrapArr);

        exit(JsonHelper.JsonToText(ResultObj));
    end;

    procedure fetchScrapSummary(
        hoursBack: Decimal;
        filterProdOrderNo: Code[20];
        filterOperationNo: Code[10];
        filterMachineNo: Code[20];
        filterWorkCenterNo: Code[20];
        filterOperatorId: Code[50]
    ): Text
    var
        MESScrap: Record "MES Operation Scrap";
        MESExecution: Record "MES Operation Execution";
        DetailArr: JsonArray;
        DetailObj: JsonObject;
        SummaryObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        TotalScrap: Decimal;
        MachineWCNo: Code[20];
        OperatorName: Text;
    begin
        CutoffTime := GetCutoffTime(hoursBack);
        TotalScrap := 0;

        Clear(DetailArr);
        Clear(SummaryObj);

        MESScrap.Reset();
        MESScrap.SetFilter("Declared At", '>=%1', CutoffTime);

        if filterOperatorId <> '' then
            MESScrap.SetRange("Operator Id", filterOperatorId);

        if not MESScrap.FindSet() then begin
            SummaryObj.Add('totalScrapQty', 0);
            SummaryObj.Add('recordCount', 0);
            SummaryObj.Add('details', DetailArr);
            exit(JsonHelper.JsonToText(SummaryObj));
        end;

        repeat
            MachineWCNo := '';
            OperatorName := '';

            if MESExecution.Get(MESScrap."Execution Id") then
                if ScrapRecordMatchesFilters(
                    MESScrap,
                    MESExecution,
                    filterProdOrderNo,
                    filterOperationNo,
                    filterMachineNo,
                    filterWorkCenterNo,
                    MachineWCNo)
                then begin
                    TotalScrap += MESScrap."Scrap Quantity";
                    OperatorName := GetOperatorName(MESScrap."Operator Id");

                    Clear(DetailObj);
                    DetailObj.Add('scrapId', MESScrap."Id");
                    DetailObj.Add('executionId', MESScrap."Execution Id");
                    DetailObj.Add('prodOrderNo', MESExecution."Prod Order No");
                    DetailObj.Add('operationNo', MESExecution."Operation No");
                    DetailObj.Add('machineNo', MESExecution."Machine No");
                    DetailObj.Add('workCenterNo', MachineWCNo);
                    DetailObj.Add('scrapCode', MESScrap."Scrap Code");
                    DetailObj.Add('scrapDescription', MESScrap."scrap Description");
                    DetailObj.Add('scrapNotes', MESScrap."scrap notes");
                    DetailObj.Add('scrapQuantity', MESScrap."Scrap Quantity");
                    DetailObj.Add('materialId', MESScrap."Material Id");
                    DetailObj.Add('operatorId', MESScrap."Operator Id");
                    DetailObj.Add('operatorName', OperatorName);
                    DetailObj.Add('declaredAt', Format(MESScrap."Declared At", 0, 9));

                    DetailArr.Add(DetailObj);
                end;
        until MESScrap.Next() = 0;

        SummaryObj.Add('totalScrapQty', TotalScrap);
        SummaryObj.Add('recordCount', DetailArr.Count());
        SummaryObj.Add('details', DetailArr);

        exit(JsonHelper.JsonToText(SummaryObj));
    end;

    procedure fetchDelayReport(workCenterNoJson: Text; pauseThresholdMinutes: Decimal): Text
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        Machine: Record "Machine Center";
        DelayArr: JsonArray;
        DelayObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        WorkCenterFilter: Text;
        Now: DateTime;
        PausedSinceMinutes: Decimal;
        IsOverdue: Boolean;
        IsPausedTooLong: Boolean;
        DelayReason: Text;
        DelayMinutes: Decimal;
        PauseDeclaredAt: DateTime;
        MachineWC: Code[20];
        InScope: Boolean;
        HasMESExecution: Boolean;
    begin
        Clear(DelayArr);

        Now := CurrentDateTime();
        WorkCenterFilter := BuildWorkCenterFilter(workCenterNoJson);

        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetFilter(
            Status,
            '%1|%2',
            ProdOrderRoutingLine.Status::Released,
            ProdOrderRoutingLine.Status::"Firm Planned");

        if WorkCenterFilter <> '' then
            ProdOrderRoutingLine.SetFilter("Work Center No.", WorkCenterFilter);

        if not ProdOrderRoutingLine.FindSet() then
            exit(JsonHelper.JsonToTextArr(DelayArr));

        repeat
            IsOverdue := false;
            IsPausedTooLong := false;
            DelayReason := '';
            DelayMinutes := 0;
            PauseDeclaredAt := 0DT;
            InScope := true;
            HasMESExecution := false;

            MESExecution.Reset();
            MESExecution.SetRange("Prod Order No", ProdOrderRoutingLine."Prod. Order No.");
            MESExecution.SetRange("Operation No", ProdOrderRoutingLine."Operation No.");

            if MESExecution.FindFirst() then begin
                HasMESExecution := true;

                if FindLatestExecutionState(MESExecution, MESState) then begin
                    if MESState."Operation Status" in [
                        MESState."Operation Status"::Finished,
                        MESState."Operation Status"::Cancelled
                    ] then
                        InScope := false
                    else begin
                        if MESState."Operation Status" = MESState."Operation Status"::Paused then begin
                            PauseDeclaredAt := MESState."Declared At";
                            PausedSinceMinutes := (Now - PauseDeclaredAt) / 60000.0;

                            if PausedSinceMinutes >= pauseThresholdMinutes then begin
                                IsPausedTooLong := true;
                                DelayMinutes := PausedSinceMinutes;
                                DelayReason := 'Paused for ' + Format(Round(PausedSinceMinutes, 1)) + ' min';
                            end;
                        end;
                    end;
                end;
            end;

            if InScope then begin
                if (ProdOrderRoutingLine."Ending Date-Time" <> 0DT) and
                   (ProdOrderRoutingLine."Ending Date-Time" < Now)
                then begin
                    IsOverdue := true;
                    DelayMinutes := (Now - ProdOrderRoutingLine."Ending Date-Time") / 60000.0;

                    if DelayReason = '' then
                        DelayReason := 'Past planned end by ' + Format(Round(DelayMinutes, 1)) + ' min';
                end;

                if not HasMESExecution then begin
                    if IsOverdue then
                        DelayReason := 'Not started — past planned start'
                    else
                        InScope := false;
                end;
            end;

            if InScope and (IsOverdue or IsPausedTooLong) then begin
                MachineWC := ProdOrderRoutingLine."Work Center No.";

                if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then
                    if Machine.Get(ProdOrderRoutingLine."No.") then
                        MachineWC := Machine."Work Center No.";

                Clear(DelayObj);
                DelayObj.Add('prodOrderNo', ProdOrderRoutingLine."Prod. Order No.");
                DelayObj.Add('operationNo', ProdOrderRoutingLine."Operation No.");
                DelayObj.Add('operationDescription', ProdOrderRoutingLine.Description);
                DelayObj.Add('workCenterNo', MachineWC);
                DelayObj.Add('machineNo', ProdOrderRoutingLine."No.");
                DelayObj.Add('routingStatus', Format(ProdOrderRoutingLine.Status));
                DelayObj.Add('plannedEnd', Format(ProdOrderRoutingLine."Ending Date-Time", 0, 9));
                DelayObj.Add('isOverdue', IsOverdue);
                DelayObj.Add('isPausedTooLong', IsPausedTooLong);
                DelayObj.Add('delayMinutes', Round(DelayMinutes, 0.1));
                DelayObj.Add('delayReason', DelayReason);

                if HasMESExecution then
                    DelayObj.Add('executionId', MESExecution."Execution Id")
                else
                    DelayObj.Add('executionId', '');

                DelayArr.Add(DelayObj);
            end;
        until ProdOrderRoutingLine.Next() = 0;

        exit(JsonHelper.JsonToTextArr(DelayArr));
    end;

    procedure fetchConsumptionSummary(
        filterProdOrderNo: Code[20];
        filterOperationNo: Code[10];
        filterMachineNo: Code[20];
        hoursBack: Decimal
    ): Text
    var
        MESExecution: Record "MES Operation Execution";
        MESProgress: Record "MES Operation Progression";
        ResultArr: JsonArray;
        ExecObj: JsonObject;
        CompArr: JsonArray;
        JsonHelper: Codeunit "MES Json Helper";
        CutoffTime: DateTime;
        HasCutoff: Boolean;
        ProducedQty: Decimal;
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean;
    begin
        Clear(ResultArr);

        HasCutoff := hoursBack > 0;

        if HasCutoff then
            CutoffTime := GetCutoffTime(hoursBack);

        MESExecution.Reset();

        if filterProdOrderNo <> '' then
            MESExecution.SetRange("Prod Order No", filterProdOrderNo);

        if filterOperationNo <> '' then
            MESExecution.SetRange("Operation No", filterOperationNo);

        if filterMachineNo <> '' then
            MESExecution.SetRange("Machine No", filterMachineNo);

        if HasCutoff then
            MESExecution.SetFilter("Start Time", '>=%1', CutoffTime);

        if not MESExecution.FindSet() then
            exit(JsonHelper.JsonToTextArr(ResultArr));

        repeat
            Clear(ExecObj);
            Clear(CompArr);

            ProducedQty := 0;

            if FindLatestExecutionProgress(MESExecution, MESProgress) then
                ProducedQty := MESProgress."Total Produced Quantity";

            CurrentRoutingLinkCode := GetRoutingLinkCode(MESExecution);
            HasAnyRoutingLink := ProductionOrderHasAnyRoutingLink(MESExecution."Prod Order No");

            BuildExecutionConsumptionComponents(
                MESExecution,
                CurrentRoutingLinkCode,
                HasAnyRoutingLink,
                CompArr);

            ExecObj.Add('executionId', MESExecution."Execution Id");
            ExecObj.Add('prodOrderNo', MESExecution."Prod Order No");
            ExecObj.Add('operationNo', MESExecution."Operation No");
            ExecObj.Add('machineNo', MESExecution."Machine No");
            ExecObj.Add('orderQuantity', MESExecution."Order Quantity");
            ExecObj.Add('producedQuantity', ProducedQty);
            ExecObj.Add('components', CompArr);

            ResultArr.Add(ExecObj);
        until MESExecution.Next() = 0;

        exit(JsonHelper.JsonToTextArr(ResultArr));
    end;

    procedure fetchSupervisorOverview(workCenterNoJson: Text; hoursBack: Decimal; pauseThresholdMinutes: Decimal): Text
    var
        StoppedMachinesArr: JsonArray;
        IdleOperatorsArr: JsonArray;
        AbnormalPausesArr: JsonArray;
        HighScrapOpsArr: JsonArray;
        DelayedOpsArr: JsonArray;
        SummaryObj: JsonObject;
        JsonHelper: Codeunit "MES Json Helper";
        WorkCenterFilter: Text;
        CutoffTime: DateTime;
        Now: DateTime;
        TotalProduced: Decimal;
        TotalScrap: Decimal;
        StoppedMachineCount: Integer;
    begin
        Now := CurrentDateTime();
        CutoffTime := Now - (hoursBack * 3600000.0);

        TotalProduced := 0;
        TotalScrap := 0;
        StoppedMachineCount := 0;

        WorkCenterFilter := BuildWorkCenterFilter(workCenterNoJson);

        BuildStoppedMachinesOverview(
            WorkCenterFilter,
            Now,
            StoppedMachineCount,
            StoppedMachinesArr);

        BuildSupervisorDelayAndPauseOverview(
            WorkCenterFilter,
            Now,
            pauseThresholdMinutes,
            AbnormalPausesArr,
            DelayedOpsArr);

        BuildIdleOperatorsOverview(
            WorkCenterFilter,
            Now,
            IdleOperatorsArr);

        BuildHighScrapOverview(
            WorkCenterFilter,
            CutoffTime,
            TotalProduced,
            TotalScrap,
            HighScrapOpsArr);

        SummaryObj.Add('hoursBack', hoursBack);
        SummaryObj.Add('totalProducedQty', TotalProduced);
        SummaryObj.Add('totalScrapQty', TotalScrap);
        SummaryObj.Add('stoppedMachineCount', StoppedMachineCount);
        SummaryObj.Add('idleOperatorCount', IdleOperatorsArr.Count());
        SummaryObj.Add('abnormalPauseCount', AbnormalPausesArr.Count());
        SummaryObj.Add('highScrapOpsCount', HighScrapOpsArr.Count());
        SummaryObj.Add('delayedOpsCount', DelayedOpsArr.Count());
        SummaryObj.Add('stoppedMachines', StoppedMachinesArr);
        SummaryObj.Add('idleOperators', IdleOperatorsArr);
        SummaryObj.Add('abnormalPauses', AbnormalPausesArr);
        SummaryObj.Add('highScrapOperations', HighScrapOpsArr);
        SummaryObj.Add('delayedOperations', DelayedOpsArr);

        exit(JsonHelper.JsonToText(SummaryObj));
    end;

    // =========================================================================
    // Shared helper procedures
    // =========================================================================

    local procedure GetCutoffTime(hoursBack: Decimal): DateTime
    begin
        exit(CurrentDateTime() - (hoursBack * 3600000.0));
    end;

    local procedure BuildWorkCenterFilter(workCenterNoJson: Text): Text
    var
        WorkCenterNoArr: JsonArray;
        WorkCenterNoToken: JsonToken;
        WorkCenterFilter: Text;
        WorkCenterNo: Code[20];
    begin
        WorkCenterFilter := '';

        WorkCenterNoArr.ReadFrom(workCenterNoJson);

        foreach WorkCenterNoToken in WorkCenterNoArr do begin
            WorkCenterNo := CopyStr(WorkCenterNoToken.AsValue().AsText(), 1, 20);

            if WorkCenterFilter = '' then
                WorkCenterFilter := WorkCenterNo
            else
                WorkCenterFilter += '|' + WorkCenterNo;
        end;

        exit(WorkCenterFilter);
    end;

    local procedure FindLatestExecutionState(MESExecution: Record "MES Operation Execution"; var MESState: Record "MES Operation State"): Boolean
    begin
        MESState.Reset();
        MESState.SetCurrentKey("Execution Id", "Declared At");
        MESState.SetRange("Execution Id", MESExecution."Execution Id");
        MESState.Ascending(false);

        exit(MESState.FindFirst());
    end;

    local procedure FindLatestExecutionProgress(MESExecution: Record "MES Operation Execution"; var MESProgress: Record "MES Operation Progression"): Boolean
    begin
        MESProgress.Reset();
        MESProgress.SetCurrentKey("Execution Id", "Declared At");
        MESProgress.SetRange("Execution Id", MESExecution."Execution Id");
        MESProgress.Ascending(false);

        exit(MESProgress.FindFirst());
    end;

    local procedure FindLatestOperatorProgress(
        MESExecution: Record "MES Operation Execution";
        MESUser: Record "MES User";
        var MESProgress: Record "MES Operation Progression"
    ): Boolean
    begin
        MESProgress.Reset();
        MESProgress.SetCurrentKey("Execution Id", "Declared At");
        MESProgress.SetRange("Execution Id", MESExecution."Execution Id");
        MESProgress.SetRange("Operator Id", MESUser."User Id");
        MESProgress.Ascending(false);

        exit(MESProgress.FindFirst());
    end;

    // =========================================================================
    // User / operator helpers
    // =========================================================================

    local procedure IsUserInExactWorkCenterScope(MESUser: Record "MES User"; WorkCenterFilter: Text): Boolean
    var
        MESUserWC: Record "MES User Work Center";
    begin
        if WorkCenterFilter = '' then
            exit(true);

        MESUserWC.Reset();
        MESUserWC.SetRange("User Id", MESUser."User Id");
        MESUserWC.SetFilter("Work Center No.", WorkCenterFilter);

        exit(MESUserWC.FindFirst());
    end;

    local procedure IsUserInSupervisorWorkCenterScope(MESUser: Record "MES User"; WorkCenterFilter: Text): Boolean
    var
        MESUserWC: Record "MES User Work Center";
    begin
        if WorkCenterFilter = '' then
            exit(true);

        MESUserWC.Reset();
        MESUserWC.SetRange("User Id", MESUser."User Id");

        if MESUserWC.FindSet() then
            repeat
                if StrPos(WorkCenterFilter, MESUserWC."Work Center No.") > 0 then
                    exit(true);
            until MESUserWC.Next() = 0;

        exit(false);
    end;

    local procedure IsUserLoggedInNow(MESUser: Record "MES User"): Boolean
    var
        MESAuthToken: Record "MES Auth Token";
    begin
        MESAuthToken.Reset();
        MESAuthToken.SetRange("User Id", MESUser."User Id");

        if MESAuthToken.FindSet() then
            repeat
                if (not MESAuthToken.Revoked) and (MESAuthToken."Expires At" > CurrentDateTime()) then
                    exit(true);
            until MESAuthToken.Next() = 0;

        exit(false);
    end;

    local procedure IsUserLoggedInAt(MESUser: Record "MES User"; AtDateTime: DateTime): Boolean
    var
        MESAuthToken: Record "MES Auth Token";
    begin
        MESAuthToken.Reset();
        MESAuthToken.SetRange("User Id", MESUser."User Id");

        if MESAuthToken.FindSet() then
            repeat
                if (not MESAuthToken.Revoked) and (MESAuthToken."Expires At" > AtDateTime) then
                    exit(true);
            until MESAuthToken.Next() = 0;

        exit(false);
    end;

    local procedure UserHasRunningOperation(MESUser: Record "MES User"): Boolean
    var
        MESUserEI: Record "MES User Execution Interaction";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
    begin
        MESUserEI.Reset();
        MESUserEI.SetRange("User Id", MESUser."User Id");

        if MESUserEI.FindSet() then
            repeat
                if MESExecution.Get(MESUserEI."Execution Id") then
                    if FindLatestExecutionState(MESExecution, MESState) then
                        if MESState."Operation Status" = MESState."Operation Status"::Running then
                            exit(true);
            until MESUserEI.Next() = 0;

        exit(false);
    end;

    local procedure SumOperatorScrapForExecution(MESExecution: Record "MES Operation Execution"; MESUser: Record "MES User"): Decimal
    var
        MESScrap: Record "MES Operation Scrap";
        TotalScrap: Decimal;
    begin
        TotalScrap := 0;

        MESScrap.Reset();
        MESScrap.SetRange("Execution Id", MESExecution."Execution Id");
        MESScrap.SetRange("Operator Id", MESUser."User Id");

        if MESScrap.FindSet() then
            repeat
                TotalScrap += MESScrap."Scrap Quantity";
            until MESScrap.Next() = 0;

        exit(TotalScrap);
    end;

    local procedure GetOperatorName(OperatorId: Code[50]): Text
    var
        MESUser: Record "MES User";
        Employee: Record Employee;
    begin
        if MESUser.Get(OperatorId) then
            if Employee.Get(MESUser."Employee ID") then
                exit(Employee.FullName());

        exit('');
    end;

    // =========================================================================
    // Production order helpers
    // =========================================================================

    local procedure ApplyProductionOrderStatusFilter(var ProdOrderHeader: Record "Production Order"; StatusFilter: Text)
    begin
        if StatusFilter = '' then begin
            ProdOrderHeader.SetFilter(
                Status,
                '%1|%2|%3|%4',
                ProdOrderHeader.Status::Planned,
                ProdOrderHeader.Status::"Firm Planned",
                ProdOrderHeader.Status::Released,
                ProdOrderHeader.Status::Finished);
        end else begin
            if StrPos(StatusFilter, 'Planned') > 0 then
                ProdOrderHeader.SetFilter(Status, '%1', ProdOrderHeader.Status::Planned);

            if StrPos(StatusFilter, 'Firm Planned') > 0 then
                ProdOrderHeader.SetFilter(Status, '%1', ProdOrderHeader.Status::"Firm Planned");

            if StrPos(StatusFilter, 'Released') > 0 then
                ProdOrderHeader.SetFilter(Status, '%1', ProdOrderHeader.Status::Released);

            if StrPos(StatusFilter, 'Finished') > 0 then
                ProdOrderHeader.SetFilter(Status, '%1', ProdOrderHeader.Status::Finished);
        end;
    end;

    local procedure ProductionOrderMatchesRoutingFilters(
        ProdOrderHeader: Record "Production Order";
        WorkCenterNo: Text;
        MachineNo: Text
    ): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IncludeOrder: Boolean;
        MatchesWC: Boolean;
        MatchesMachine: Boolean;
    begin
        IncludeOrder := true;

        if WorkCenterNo <> '' then begin
            MatchesWC := false;

            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderHeader."No.");
            ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenterNo);

            if not ProdOrderRoutingLine.IsEmpty() then
                MatchesWC := true;

            if not MatchesWC then
                IncludeOrder := false;
        end;

        if MachineNo <> '' then begin
            MatchesMachine := false;

            ProdOrderRoutingLine.Reset();
            ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderHeader."No.");
            ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
            ProdOrderRoutingLine.SetRange("No.", MachineNo);

            if not ProdOrderRoutingLine.IsEmpty() then
                MatchesMachine := true;

            if not MatchesMachine then
                IncludeOrder := false;
        end;

        exit(IncludeOrder);
    end;

    local procedure SumProductionOrderProducedQuantity(ProdOrderHeader: Record "Production Order"): Decimal
    var
        MESExecution: Record "MES Operation Execution";
        MESProgress: Record "MES Operation Progression";
        TotalProduced: Decimal;
    begin
        TotalProduced := 0;

        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", ProdOrderHeader."No.");

        if MESExecution.FindSet() then
            repeat
                if FindLatestExecutionProgress(MESExecution, MESProgress) then
                    TotalProduced += MESProgress."Total Produced Quantity";
            until MESExecution.Next() = 0;

        exit(TotalProduced);
    end;

    local procedure ProductionOrderHasRunningOperation(ProdOrderHeader: Record "Production Order"): Boolean
    var
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
    begin
        MESExecution.Reset();
        MESExecution.SetRange("Prod Order No", ProdOrderHeader."No.");

        if MESExecution.FindSet() then
            repeat
                if FindLatestExecutionState(MESExecution, MESState) then
                    if MESState."Operation Status" = MESState."Operation Status"::Running then
                        exit(true);
            until MESExecution.Next() = 0;

        exit(false);
    end;

    local procedure BuildProductionOrderRoutingSummary(
        ProdOrderHeader: Record "Production Order";
        var RoutingArr: JsonArray
    )
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingObj: JsonObject;
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderHeader."No.");

        if ProdOrderRoutingLine.FindSet() then
            repeat
                Clear(RoutingObj);

                RoutingObj.Add('operationNo', ProdOrderRoutingLine."Operation No.");
                RoutingObj.Add('description', ProdOrderRoutingLine.Description);
                RoutingObj.Add('workCenterNo', ProdOrderRoutingLine."Work Center No.");
                RoutingObj.Add('machineNo', ProdOrderRoutingLine."No.");
                RoutingObj.Add('operationType', Format(ProdOrderRoutingLine.Type));
                RoutingObj.Add('routingStatus', Format(ProdOrderRoutingLine.Status));
                RoutingObj.Add('plannedStart', Format(ProdOrderRoutingLine."Starting Date-Time", 0, 9));
                RoutingObj.Add('plannedEnd', Format(ProdOrderRoutingLine."Ending Date-Time", 0, 9));

                RoutingArr.Add(RoutingObj);
            until ProdOrderRoutingLine.Next() = 0;
    end;

    // =========================================================================
    // Work center helpers
    // =========================================================================

    local procedure CalculateWorkCenterMachineSummary(
        WorkCenter: Record "Work Center";
        CutoffTime: DateTime;
        var TotalMachines: Integer;
        var WorkingMachines: Integer;
        var IdleMachines: Integer;
        var TotalProduced: Decimal;
        var TotalScrap: Decimal
    )
    var
        Machine: Record "Machine Center";
        MESMachineStatus: Record "MES Machine Status";
        MESExecution: Record "MES Operation Execution";
        MESProgress: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
    begin
        Machine.Reset();
        Machine.SetRange("Work Center No.", WorkCenter."No.");

        if Machine.FindSet() then
            repeat
                TotalMachines += 1;

                MESMachineStatus.Reset();
                MESMachineStatus.SetCurrentKey("Machine No.", "Updated At");
                MESMachineStatus.SetRange("Machine No.", Machine."No.");
                MESMachineStatus.Ascending(false);

                if MESMachineStatus.FindFirst() then begin
                    if MESMachineStatus.Status = MESMachineStatus.Status::Working then
                        WorkingMachines += 1
                    else
                        IdleMachines += 1;
                end else
                    IdleMachines += 1;

                MESExecution.Reset();
                MESExecution.SetRange("Machine No", Machine."No.");
                MESExecution.SetFilter("Start Time", '>=%1', CutoffTime);

                if MESExecution.FindSet() then
                    repeat
                        if FindLatestExecutionProgress(MESExecution, MESProgress) then
                            TotalProduced += MESProgress."Total Produced Quantity";

                        MESScrap.Reset();
                        MESScrap.SetRange("Execution Id", MESExecution."Execution Id");

                        if MESScrap.FindSet() then
                            repeat
                                TotalScrap += MESScrap."Scrap Quantity";
                            until MESScrap.Next() = 0;
                    until MESExecution.Next() = 0;
            until Machine.Next() = 0;
    end;

    local procedure CountRunningOperationsForWorkCenter(WorkCenter: Record "Work Center"): Integer
    var
        Machine: Record "Machine Center";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        RunningOpsCount: Integer;
    begin
        RunningOpsCount := 0;

        Machine.Reset();
        Machine.SetRange("Work Center No.", WorkCenter."No.");

        if Machine.FindSet() then
            repeat
                MESExecution.Reset();
                MESExecution.SetRange("Machine No", Machine."No.");

                if MESExecution.FindSet() then
                    repeat
                        if FindLatestExecutionState(MESExecution, MESState) then
                            if MESState."Operation Status" = MESState."Operation Status"::Running then
                                RunningOpsCount += 1;
                    until MESExecution.Next() = 0;
            until Machine.Next() = 0;

        exit(RunningOpsCount);
    end;

    // =========================================================================
    // Scrap helpers
    // =========================================================================

    local procedure ScrapRecordMatchesFilters(
        MESScrap: Record "MES Operation Scrap";
        MESExecution: Record "MES Operation Execution";
        FilterProdOrderNo: Code[20];
        FilterOperationNo: Code[10];
        FilterMachineNo: Code[20];
        FilterWorkCenterNo: Code[20];
        var MachineWCNo: Code[20]
    ): Boolean
    var
        Machine: Record "Machine Center";
    begin
        if FilterProdOrderNo <> '' then
            if MESExecution."Prod Order No" <> FilterProdOrderNo then
                exit(false);

        if FilterOperationNo <> '' then
            if MESExecution."Operation No" <> FilterOperationNo then
                exit(false);

        if FilterMachineNo <> '' then
            if MESExecution."Machine No" <> FilterMachineNo then
                exit(false);

        if Machine.Get(MESExecution."Machine No") then
            MachineWCNo := Machine."Work Center No."
        else
            MachineWCNo := '';

        if FilterWorkCenterNo <> '' then
            if MachineWCNo <> FilterWorkCenterNo then
                exit(false);

        exit(true);
    end;

    // =========================================================================
    // Consumption helpers
    // =========================================================================

    local procedure GetRoutingLinkCode(MESExecution: Record "MES Operation Execution"): Code[10]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", MESExecution."Prod Order No");
        ProdOrderRoutingLine.SetRange("Operation No.", MESExecution."Operation No");

        if ProdOrderRoutingLine.FindFirst() then
            exit(ProdOrderRoutingLine."Routing Link Code");

        exit('');
    end;

    local procedure ProductionOrderHasAnyRoutingLink(ProdOrderNo: Code[20]): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetFilter("Routing Link Code", '<>%1', '');

        exit(not ProdOrderComponent.IsEmpty());
    end;

    local procedure BuildExecutionConsumptionComponents(
        MESExecution: Record "MES Operation Execution";
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean;
        var CompArr: JsonArray
    )
    var
        ProdOrderComponent: Record "Prod. Order Component";
        CompObj: JsonObject;
        PlannedQty: Decimal;
        ConsumedQty: Decimal;
    begin
        ProdOrderComponent.Reset();
        ProdOrderComponent.SetRange("Prod. Order No.", MESExecution."Prod Order No");

        if ProdOrderComponent.FindSet() then
            repeat
                if ComponentBelongsToExecutionRouting(
                    ProdOrderComponent,
                    CurrentRoutingLinkCode,
                    HasAnyRoutingLink)
                then begin
                    PlannedQty := CalculatePlannedComponentQuantity(ProdOrderComponent, MESExecution);
                    ConsumedQty := CalculateConsumedComponentQuantity(ProdOrderComponent, MESExecution);

                    Clear(CompObj);
                    CompObj.Add('itemNo', ProdOrderComponent."Item No.");
                    CompObj.Add('itemDescription', ProdOrderComponent.Description);
                    CompObj.Add('unitOfMeasure', ProdOrderComponent."Unit of Measure Code");
                    CompObj.Add('plannedQty', PlannedQty);
                    CompObj.Add('consumedQty', ConsumedQty);
                    CompObj.Add('varianceQty', ConsumedQty - PlannedQty);
                    CompObj.Add('isOverConsumed', ConsumedQty > PlannedQty);
                    CompObj.Add('isUnderConsumed', (ConsumedQty < PlannedQty) and (ConsumedQty > 0));
                    CompObj.Add('isMissingConsumption', ConsumedQty = 0);

                    CompArr.Add(CompObj);
                end;
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure ComponentBelongsToExecutionRouting(
        ProdOrderComponent: Record "Prod. Order Component";
        CurrentRoutingLinkCode: Code[10];
        HasAnyRoutingLink: Boolean
    ): Boolean
    begin
        exit(not (
            HasAnyRoutingLink and
            (ProdOrderComponent."Routing Link Code" <> '') and
            (ProdOrderComponent."Routing Link Code" <> CurrentRoutingLinkCode)
        ));
    end;

    local procedure CalculatePlannedComponentQuantity(
        ProdOrderComponent: Record "Prod. Order Component";
        MESExecution: Record "MES Operation Execution"
    ): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        QtyPerUnit: Decimal;
    begin
        QtyPerUnit := ProdOrderComponent."Quantity per";

        ItemUnitOfMeasure.Reset();
        ItemUnitOfMeasure.SetRange("Item No.", ProdOrderComponent."Item No.");
        ItemUnitOfMeasure.SetRange(Code, ProdOrderComponent."Unit of Measure Code");

        if ItemUnitOfMeasure.FindFirst() then
            QtyPerUnit := ItemUnitOfMeasure."Qty. per Unit of Measure" * ProdOrderComponent."Quantity per";

        exit(QtyPerUnit * MESExecution."Order Quantity");
    end;

    local procedure CalculateConsumedComponentQuantity(
        ProdOrderComponent: Record "Prod. Order Component";
        MESExecution: Record "MES Operation Execution"
    ): Decimal
    var
        MESConsumption: Record "MES Component Consumption";
        ConsumedQty: Decimal;
    begin
        ConsumedQty := 0;

        MESConsumption.Reset();
        MESConsumption.SetRange("Execution Id", MESExecution."Execution Id");
        MESConsumption.SetRange("Item No", ProdOrderComponent."Item No.");

        if MESConsumption.FindSet() then
            repeat
                ConsumedQty += MESConsumption."Quantity Scanned" * MESConsumption."Quantity per Unit of Measure";
            until MESConsumption.Next() = 0;

        exit(ConsumedQty);
    end;

    // =========================================================================
    // Supervisor overview helpers
    // =========================================================================

    local procedure BuildStoppedMachinesOverview(
        WorkCenterFilter: Text;
        Now: DateTime;
        var StoppedMachineCount: Integer;
        var StoppedMachinesArr: JsonArray
    )
    var
        Machine: Record "Machine Center";
        MESMachineStatus: Record "MES Machine Status";
        ItemObj: JsonObject;
    begin
        Machine.Reset();

        if WorkCenterFilter <> '' then
            Machine.SetFilter("Work Center No.", WorkCenterFilter);

        if Machine.FindSet() then
            repeat
                MESMachineStatus.Reset();
                MESMachineStatus.SetCurrentKey("Machine No.", "Updated At");
                MESMachineStatus.SetRange("Machine No.", Machine."No.");
                MESMachineStatus.Ascending(false);

                if MESMachineStatus.FindFirst() then begin
                    if MESMachineStatus.Status = MESMachineStatus.Status::Idle then begin
                        StoppedMachineCount += 1;

                        Clear(ItemObj);
                        ItemObj.Add('machineNo', Machine."No.");
                        ItemObj.Add('machineName', Machine."Name");
                        ItemObj.Add('workCenterNo', Machine."Work Center No.");
                        ItemObj.Add(
                            'idleSinceMinutes',
                            Round((Now - MESMachineStatus."Updated At") / 60000.0, 0.1));
                        ItemObj.Add('lastOrderNo', MESMachineStatus."Current Prod. Order No.");

                        StoppedMachinesArr.Add(ItemObj);
                    end;
                end;
            until Machine.Next() = 0;
    end;

    local procedure BuildSupervisorDelayAndPauseOverview(
        WorkCenterFilter: Text;
        Now: DateTime;
        PauseThresholdMinutes: Decimal;
        var AbnormalPausesArr: JsonArray;
        var DelayedOpsArr: JsonArray
    )
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MESExecution: Record "MES Operation Execution";
        MESState: Record "MES Operation State";
        ItemObj: JsonObject;
        PausedSinceMin: Decimal;
        PauseDeclaredAt: DateTime;
    begin
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetFilter(
            Status,
            '%1|%2',
            ProdOrderRoutingLine.Status::Released,
            ProdOrderRoutingLine.Status::"Firm Planned");

        if WorkCenterFilter <> '' then
            ProdOrderRoutingLine.SetFilter("Work Center No.", WorkCenterFilter);

        if ProdOrderRoutingLine.FindSet() then
            repeat
                MESExecution.Reset();
                MESExecution.SetRange("Prod Order No", ProdOrderRoutingLine."Prod. Order No.");
                MESExecution.SetRange("Operation No", ProdOrderRoutingLine."Operation No.");

                if MESExecution.FindFirst() then begin
                    if FindLatestExecutionState(MESExecution, MESState) then begin
                        if MESState."Operation Status" in [
                            MESState."Operation Status"::Finished,
                            MESState."Operation Status"::Cancelled
                        ] then begin
                            // Preserve existing behavior: closed operations are ignored.
                        end else begin
                            if MESState."Operation Status" = MESState."Operation Status"::Paused then begin
                                PauseDeclaredAt := MESState."Declared At";
                                PausedSinceMin := (Now - PauseDeclaredAt) / 60000.0;

                                if PausedSinceMin >= PauseThresholdMinutes then begin
                                    Clear(ItemObj);
                                    ItemObj.Add('prodOrderNo', MESExecution."Prod Order No");
                                    ItemObj.Add('operationNo', MESExecution."Operation No");
                                    ItemObj.Add('machineNo', MESExecution."Machine No");
                                    ItemObj.Add('workCenterNo', ProdOrderRoutingLine."Work Center No.");
                                    ItemObj.Add('pausedSinceMinutes', Round(PausedSinceMin, 0.1));

                                    AbnormalPausesArr.Add(ItemObj);
                                end;
                            end;
                        end;
                    end;
                end else begin
                    if (ProdOrderRoutingLine."Ending Date-Time" <> 0DT) and
                       (ProdOrderRoutingLine."Ending Date-Time" < Now)
                    then begin
                        Clear(ItemObj);
                        ItemObj.Add('prodOrderNo', ProdOrderRoutingLine."Prod. Order No.");
                        ItemObj.Add('operationNo', ProdOrderRoutingLine."Operation No.");
                        ItemObj.Add('workCenterNo', ProdOrderRoutingLine."Work Center No.");
                        ItemObj.Add('plannedEnd', Format(ProdOrderRoutingLine."Ending Date-Time", 0, 9));
                        ItemObj.Add(
                            'overdueMinutes',
                            Round((Now - ProdOrderRoutingLine."Ending Date-Time") / 60000.0, 0.1));
                        ItemObj.Add('reason', 'Not started, past planned end');

                        DelayedOpsArr.Add(ItemObj);
                    end;
                end;
            until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure BuildIdleOperatorsOverview(
        WorkCenterFilter: Text;
        Now: DateTime;
        var IdleOperatorsArr: JsonArray
    )
    var
        MESUser: Record "MES User";
        Employee: Record Employee;
        ItemObj: JsonObject;
        OperatorName: Text;
    begin
        MESUser.Reset();

        if MESUser.FindSet() then
            repeat
                if IsUserInSupervisorWorkCenterScope(MESUser, WorkCenterFilter) then
                    if IsUserLoggedInAt(MESUser, Now) then
                        if not UserHasRunningOperation(MESUser) then begin
                            OperatorName := '';

                            if Employee.Get(MESUser."Employee ID") then
                                OperatorName := Employee.FullName();

                            Clear(ItemObj);
                            ItemObj.Add('userId', MESUser."User Id");
                            ItemObj.Add('fullName', OperatorName);
                            ItemObj.Add('role', Format(MESUser.Role));

                            IdleOperatorsArr.Add(ItemObj);
                        end;
            until MESUser.Next() = 0;
    end;

    local procedure BuildHighScrapOverview(
        WorkCenterFilter: Text;
        CutoffTime: DateTime;
        var TotalProduced: Decimal;
        var TotalScrap: Decimal;
        var HighScrapOpsArr: JsonArray
    )
    var
        Machine: Record "Machine Center";
        MESExecution: Record "MES Operation Execution";
        MESProgress: Record "MES Operation Progression";
        MESScrap: Record "MES Operation Scrap";
        ItemObj: JsonObject;
        ScrapQty: Decimal;
    begin
        Machine.Reset();

        if WorkCenterFilter <> '' then
            Machine.SetFilter("Work Center No.", WorkCenterFilter);

        if Machine.FindSet() then
            repeat
                MESExecution.Reset();
                MESExecution.SetRange("Machine No", Machine."No.");
                MESExecution.SetFilter("Start Time", '>=%1', CutoffTime);

                if MESExecution.FindSet() then
                    repeat
                        ScrapQty := 0;

                        MESScrap.Reset();
                        MESScrap.SetRange("Execution Id", MESExecution."Execution Id");

                        if MESScrap.FindSet() then
                            repeat
                                ScrapQty += MESScrap."Scrap Quantity";
                                TotalScrap += MESScrap."Scrap Quantity";
                            until MESScrap.Next() = 0;

                        if FindLatestExecutionProgress(MESExecution, MESProgress) then begin
                            TotalProduced += MESProgress."Total Produced Quantity";

                            if (MESProgress."Total Produced Quantity" > 0) and
                               (ScrapQty / MESProgress."Total Produced Quantity" > 0.10)
                            then begin
                                Clear(ItemObj);
                                ItemObj.Add('executionId', MESExecution."Execution Id");
                                ItemObj.Add('prodOrderNo', MESExecution."Prod Order No");
                                ItemObj.Add('operationNo', MESExecution."Operation No");
                                ItemObj.Add('machineNo', MESExecution."Machine No");
                                ItemObj.Add('scrapQty', ScrapQty);
                                ItemObj.Add('producedQty', MESProgress."Total Produced Quantity");
                                ItemObj.Add(
                                    'scrapRate',
                                    Round(ScrapQty / MESProgress."Total Produced Quantity" * 100, 0.1));

                                HighScrapOpsArr.Add(ItemObj);
                            end;
                        end;
                    until MESExecution.Next() = 0;
            until Machine.Next() = 0;
    end;
}