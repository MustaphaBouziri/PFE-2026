/// Development-only codeunit that provisions three MES users (one per role)
/// and inserts permanent auth tokens for each.
///
/// WARNING: Run this only in development/sandbox environments.
/// The tokens created here never expire — they must not exist in production.
codeunit 50127 "MES Dev Setup"
{
    // Fixed token GUIDs — hard-coded so developers can paste them directly
    // into AppConstants.devToken without running the page each time.
    var
        OperatorTokenGuid: Text[50];
        SupervisorTokenGuid: Text[50];
        AdminTokenGuid: Text[50];

    trigger OnRun()
    begin
        // Assign well-known GUIDs so they are stable across re-runs.
        OperatorTokenGuid := 'DE000000-0000-0000-0000-000000000001';
        SupervisorTokenGuid := 'DE000000-0000-0000-0000-000000000002';
        AdminTokenGuid := 'DE000000-0000-0000-0000-000000000003';

        EnsureDevUser('DEV-OPERATOR', 'AC', 'AUTH-DEV-OP', Enum::"MES User Role"::Operator);
        EnsureDevUser('DEV-SUPERVISOR', 'AF', 'AUTH-DEV-SV', Enum::"MES User Role"::Supervisor);
        EnsureDevUser('DEV-ADMIN', 'CB', 'AUTH-DEV-AD', Enum::"MES User Role"::Admin);

        EnsureDevToken(OperatorTokenGuid, 'DEV-OPERATOR');
        EnsureDevToken(SupervisorTokenGuid, 'DEV-SUPERVISOR');
        EnsureDevToken(AdminTokenGuid, 'DEV-ADMIN');
    end;

    /// Returns the result summary so the debug page can display the tokens.
    procedure GetTokenSummary(): Text
    var
        J: JsonObject;
        JsonText: Text;
    begin
        J.Add('operatorToken', OperatorTokenGuid);
        J.Add('supervisorToken', SupervisorTokenGuid);
        J.Add('adminToken', AdminTokenGuid);
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    // ──────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────

    /// Creates a MES user only if it does not already exist.
    local procedure EnsureDevUser(
        userId: Code[50];
        employeeId: Code[50];
        authId: Text[100];
        role: Enum "MES User Role"
    )
    var
        AuthMgt: Codeunit "MES Auth Mgt";
        U: Record "MES User";
    begin
        if U.Get(userId) then
            exit; // already provisioned — skip

        AuthMgt.CreateUser(userId, employeeId, authId, role);

        // Set a known dev password so the login flow also works manually.
        AuthMgt.SetPassword(userId, 'Dev@1234!', false);
    end;

    /// Inserts a permanent (year 9999) auth token for a dev user.
    /// Idempotent — does nothing if the token row already exists.
    local procedure EnsureDevToken(tokenGuid: Text[50]; userId: Code[50])
    var
        T: Record "MES Auth Token";
        GuidValue: Guid;
    begin
        Evaluate(GuidValue, tokenGuid);
        if T.Get(GuidValue) then
            exit; // already exists — skip

        T.Init();
        T."Token" := GuidValue;
        T."User Id" := userId;
        T."Device Id" := 'dev-device';
        T."Issued At" := CurrentDateTime();
        // 31 Dec 9999 — effectively non-expiring for dev purposes.
        T."Expires At" := CreateDateTime(DMY2Date(31, 12, 9999), 235959T);
        T."Last Seen At" := CurrentDateTime();
        T.Revoked := false;
        T.Insert(true);
    end;
}
