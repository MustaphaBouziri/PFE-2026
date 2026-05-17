// =============================================================================
// Table  : MES Settings
// Changes: Added field 2 "TwoFA Enabled" (Boolean).
//          When true, the Flutter login flow will show the badge scan dialog
//          after a successful password check before granting access.
//          The badge QR secret is always generated on user creation regardless
//          of this setting — enabling 2FA later will work immediately.
// =============================================================================
table 50100 "MES Settings"
{
    DataClassification = CustomerContent;
    Caption = 'MES Settings';

    fields
    {
        field(1; "PW change period"; Duration)
        {
            Caption            = 'Password Change Period';
            DataClassification = CustomerContent;
        }

        field(2; "TwoFA Enabled"; Boolean)
        {
            Caption            = 'Two-Factor Authentication Enabled';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "PW change period") { Clustered = true; }
    }
}
