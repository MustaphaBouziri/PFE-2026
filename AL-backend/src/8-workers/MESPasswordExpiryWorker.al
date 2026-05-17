/// <summary>
/// MES Password Expiry Worker
///
/// Designed to run as a Job Queue entry (OnRun trigger).
/// On each execution it:
///   1. Reads the global PW change period from MES Settings.
///   2. Iterates every active MES User that has a password set.
///   3. If the user's "Last Password Changed At" is older than the
///      configured period (or was never set), it flips
///      "Need To Change Pw" to TRUE.
/// </summary>
codeunit 50129 "MES Password Expiry Worker"
{
    trigger OnRun()
    begin
        CheckAndFlagExpiredPasswords();
    end;

    /// <summary>
    /// Normal production entry point – silent, no output.
    /// </summary>
    procedure CheckAndFlagExpiredPasswords()
    var
        Dummy: Text;
    begin
        RunInternal(false, Dummy);
    end;

    /// <summary>
    /// Debug entry point – returns a human-readable report of every
    /// decision made so you can see exactly why a user was or was not flagged.
    /// Call this from the debug page button.
    /// </summary>
    procedure CheckAndFlagExpiredPasswordsVerbose(): Text
    var
        Report: Text;
    begin
        RunInternal(true, Report);
        exit(Report);
    end;

    // ── Core logic ────────────────────────────────────────────────────────────

    local procedure RunInternal(Verbose: Boolean; var Report: Text)
    var
        MESSettings: Record "MES Settings";
        MESUser: Record "MES User";
        PwChangePeriodMs: Duration;
        CutoffDateTime: DateTime;
        B: TextBuilder;
        FlaggedCount: Integer;
        SkippedCount: Integer;
    begin
        if Verbose then begin
            B.AppendLine('=== MES Password Expiry Worker – Diagnostic Run ===');
            B.AppendLine('Run time: ' + Format(CurrentDateTime(), 0, 9));
            B.AppendLine('');
        end;

        // ── 1. Load settings ─────────────────────────────────────────────────
        EnsureSettingsExists(MESSettings, Verbose, B);


        PwChangePeriodMs := MESSettings."PW change period";

        if Verbose then
            B.AppendLine('PW change period (ms): ' + Format(PwChangePeriodMs) +
                '  ≈ ' + Format(Round(PwChangePeriodMs / 86400000, 0.1)) + ' days');

        if PwChangePeriodMs <= 0 then begin
            if Verbose then
                B.AppendLine('ABORT: PW change period is 0 or negative – feature is disabled.');
            Report := B.ToText();
            exit;
        end;

        CutoffDateTime := CurrentDateTime() - PwChangePeriodMs;

        if Verbose then begin
            B.AppendLine('Cutoff datetime: ' + Format(CutoffDateTime, 0, 9));
            B.AppendLine('(passwords last changed BEFORE this datetime will be flagged)');
            B.AppendLine('');
        end;

        // ── 2. Iterate users ──────────────────────────────────────────────────
        MESUser.Reset();
        MESUser.SetRange("Is Active", true);
        MESUser.SetFilter("Hashed Password", '<>%1', '');

        if not MESUser.FindSet(true) then begin
            if Verbose then
                B.AppendLine('No active users with a password found.');
            Report := B.ToText();
            exit;
        end;

        FlaggedCount := 0;
        SkippedCount := 0;

        repeat
            if Verbose then
                B.AppendLine('--- User: ' + MESUser."User Id");

            if ShouldFlagUser(MESUser, CutoffDateTime) then begin
                if Verbose then begin
                    if MESUser."Last Password Changed At" = 0DT then
                        B.AppendLine('  → FLAGGING  (Last Password Changed At is empty – never changed by user)')
                    else
                        B.AppendLine('  → FLAGGING  (Last changed: ' +
                            Format(MESUser."Last Password Changed At", 0, 9) +
                            ' which is before cutoff)');
                end;

                MESUser."Need To Change Pw" := true;
                MESUser.Modify(true);
                FlaggedCount += 1;
            end else begin
                if Verbose then
                    B.AppendLine('  → OK  (Last changed: ' +
                        Format(MESUser."Last Password Changed At", 0, 9) +
                        ' which is within the allowed period)');
                SkippedCount += 1;
            end;
        until MESUser.Next() = 0;

        if Verbose then begin
            B.AppendLine('');
            B.AppendLine('=== Summary ===');
            B.AppendLine('Flagged : ' + Format(FlaggedCount));
            B.AppendLine('OK      : ' + Format(SkippedCount));
        end;

        Report := B.ToText();
    end;

    local procedure ShouldFlagUser(MESUser: Record "MES User"; CutoffDateTime: DateTime): Boolean
    begin
        // Never changed by the user themselves → always expired.
        if MESUser."Last Password Changed At" = 0DT then
            exit(true);

        // Changed, but too long ago.
        if MESUser."Last Password Changed At" < CutoffDateTime then
            exit(true);

        exit(false);
    end;

    local procedure EnsureSettingsExists(var MESSettings: Record "MES Settings"; Verbose: Boolean; var B: TextBuilder)
    var
        DefaultPwChangePeriod: Duration;
    begin
        if MESSettings.FindFirst() then
            exit;

        DefaultPwChangePeriod := GetDefaultPwChangePeriod();

        MESSettings.Init();
        MESSettings.Validate("PW change period", DefaultPwChangePeriod);
        MESSettings.Insert(true);

        if Verbose then begin
            B.AppendLine('No MES Settings record found.');
            B.AppendLine('Created default MES Settings record with PW change period = 30 days.');
            B.AppendLine('');
        end;
    end;

    local procedure GetDefaultPwChangePeriod(): Duration
    var
        DefaultMs: BigInteger;
    begin
        DefaultMs := 30L * 86400000L;
        exit(DefaultMs);
    end;
}
