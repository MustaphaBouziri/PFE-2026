// =============================================================================
// Codeunit: MES Settings Functions  (full replacement)
// ID      : 50124
// Changes : GetMESSettings now returns "twoFAEnabled" field.
//           UpdateMESSettings now accepts and persists twoFAEnabled.
// =============================================================================
codeunit 50124 "MES Settings Functions"
{
    var
        AuthVal:    Codeunit "MES Auth Validation";
        JsonHelper: Codeunit "MES Json Helper";

    procedure GetMESSettings(): Text
    var
        ResultJson:       JsonObject;
        MESSettings:      Record "MES Settings";
        PwChangePeriodDays: Decimal;
    begin
        if not MESSettings.FindFirst() then begin
            ResultJson.Add('pwChangePeriod', '0');
            ResultJson.Add('twoFAEnabled',   false);
            exit(JsonHelper.JsonToText(ResultJson));
        end;

        PwChangePeriodDays := MESSettings."PW change period" / 86400000;
        ResultJson.Add('pwChangePeriod', Format(Round(PwChangePeriodDays, 1, '<'), 0, 9));
        ResultJson.Add('twoFAEnabled',   MESSettings."TwoFA Enabled");

        exit(JsonHelper.JsonToText(ResultJson));
    end;

    procedure UpdateMESSettings(PwChangePeriodDays: Integer; TwoFAEnabled: Boolean; token: Text): Text
    var
        MESSettings:  Record "MES Settings";
        AdminUserId:  Code[50];
    begin
        if not AuthVal.TryValidateAdminToken(token, AdminUserId) then
            exit(JsonHelper.BuildErrorFromLastError('Settings update failed'));

        if PwChangePeriodDays < 1 then
            Error('Password change period must be at least 1 day.');

        if MESSettings.FindFirst() then begin
            MESSettings."PW change period" := PwChangePeriodDays * 86400000;
            MESSettings."TwoFA Enabled"    := TwoFAEnabled;
            MESSettings.Modify(true);
        end else begin
            MESSettings."PW change period" := PwChangePeriodDays * 86400000;
            MESSettings."TwoFA Enabled"    := TwoFAEnabled;
            MESSettings.Insert(true);
        end;

        exit('{"status":"success"}');
    end;
}