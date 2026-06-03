// =============================================================================
// Codeunit: MES Settings Functions  (full replacement)
// ID      : 50124
// Changes : GetMESSettings now returns "twoFAEnabled" field.
//           UpdateMESSettings now accepts and persists twoFAEnabled.
// =============================================================================
codeunit 50124 "MES Settings Functions"
{
    var
        AuthVal: Codeunit "MES Auth Validation";
        JsonHelper: Codeunit "MES Json Helper";

    procedure GetMESSettings(): Text
    var
        ResultJson: JsonObject;
        MESSettings: Record "MES Settings";
        PwChangePeriodDays: Decimal;
    begin
        if not MESSettings.FindFirst() then begin
            ResultJson.Add('pwChangePeriod', '0');
            ResultJson.Add('twoFAEnabled', false);
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        PwChangePeriodDays := MESSettings."PW change period" / 86400000;
        ResultJson.Add('pwChangePeriod', Format(Round(PwChangePeriodDays, 1, '<'), 0, 9));
        ResultJson.Add('twoFAEnabled', MESSettings."TwoFA Enabled");

        exit(JsonHelper.JsonToText(ResultJson));
    end;

    procedure UpdateMESSettings(PwChangePeriodDays: Integer; TwoFAEnabled: Boolean; token: Text): Text
    var
        MESSettings: Record "MES Settings";
        AdminUserId: Code[50];
        resultJson: JsonObject;
        DefaultMs: BigInteger;
    begin
        if not AuthVal.TryValidateAdminToken(token, AdminUserId) then
            exit(JsonHelper.BuildErrorFromLastError('Settings update failed'));

        if PwChangePeriodDays < 0 then
            Error('Password change period must be a positive number.');

        DefaultMs := PwChangePeriodDays * 86400000L;

        // Delete existing record if present (can't modify a PK field)
        if MESSettings.FindFirst() then
            MESSettings.Delete(true);

        MESSettings.Init();
        MESSettings."PW change period" := DefaultMs;
        MESSettings."TwoFA Enabled" := TwoFAEnabled;
        MESSettings.Insert(true);

        resultJson.Add('success', true);
        exit(JsonHelper.JsonToText(resultJson));
    end;
}