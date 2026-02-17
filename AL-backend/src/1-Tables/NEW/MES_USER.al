// =============================================================================
// Table  : MES User
// ID     : 50101
// Purpose: Central user registry for the Manufacturing Execution System (MES).
//          Each row represents one MES operator, supervisor, or admin account.
//          This table is NOT the same as the standard BC User table — it is a
//          separate, self-contained identity store for MES-specific roles and
//          authentication, designed to work independently of BC login accounts.
//
// DATA CLASSIFICATION
//   CustomerContent        — table-level default for most fields.
//   EndUserIdentifiableInformation — applied to fields that can directly
//                            identify a real person (User Id, Employee ID,
//                            Auth ID).
//   SystemMetadata         — applied to operational fields that are not PII
//                            (flags, timestamps, iteration counts).
//
// PASSWORD STORAGE
//   Passwords are NEVER stored in plaintext.  The flow is:
//     1. MakeSalt()       → random hex salt (MES Password Mgt codeunit)
//     2. HashPassword()   → iterated SHA-256(password + salt)
//     3. CopyStr(hash,1,128) stored in "Hashed Password"
//     4. CopyStr(salt,1,50)  stored in "Password Salt"
//   See MESPasswordMgt.al for the hashing implementation.
//   NOTE: "Password Salt" is Text[50] which truncates the 64-char SHA-256 hex
//   output. Widening this field to Text[64] is a recommended future improvement.
//
// ACCOUNT LIFECYCLE
//   Created  → Is Active = true,  Need To Change Pw = true
//   SetPassword called → Need To Change Pw = false (or true for forced reset)
//   SetActive(false)  → Is Active = false, all tokens revoked immediately
//   SetActive(true)   → Is Active = true,  user must log in again
//
// KEYS
//   PK  (User Id) — clustered; all auth lookups are by User Id.
//   UserRole      — non-clustered on Role; reserved for future role-based
//                   queries (e.g. "list all Supervisors").
// =============================================================================
table 50101 "MES User"
{
    DataClassification = CustomerContent;
    Caption            = 'MES User';

    fields
    {
        // ---------------------------------------------------------------------
        // Field 1 — User Id (Primary Key)
        // Short alphanumeric identifier chosen at account creation time.
        // This is the value the user types at the MES login prompt — it is
        // not a GUID and should be human-readable (e.g. "JDOE", "OP001").
        // Maximum length 50 characters matches the Code[50] login input fields
        // throughout the codebase.
        // ---------------------------------------------------------------------
        field(1; "User Id"; Code[50])
        {
            Caption            = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }

        // ---------------------------------------------------------------------
        // Field 3 — Employee ID (Foreign Key → Employee."No.")
        // Links this MES account to a Business Central HR Employee record.
        // Optional: leave blank for MES-only accounts that have no HR record.
        // TableRelation enforces referential integrity — you cannot set this to
        // an employee number that does not exist in the Employee table.
        // Field number 3 (not 2) is intentional — field 2 is reserved for a
        // future "Display Name" field without requiring a schema renumber.
        // ---------------------------------------------------------------------
        field(3; "employee ID"; Code[50])
        {
            Caption            = 'Employee ID';
            TableRelation      = Employee."No.";
            DataClassification = EndUserIdentifiableInformation;
        }

        // ---------------------------------------------------------------------
        // Field 4 — Auth ID
        // Secondary identifier used for display purposes and for mapping to an
        // external identity provider (e.g. Active Directory UPN "AD\jdoe" or
        // an OAuth subject claim).  Not used for MES login — login is always
        // by User Id + password.  Returned in API responses as the "name" field.
        // ---------------------------------------------------------------------
        field(4; "Auth ID"; Text[100])
        {
            Caption            = 'Auth ID';
            DataClassification = EndUserIdentifiableInformation;
        }

        // ---------------------------------------------------------------------
        // Field 5 — Role
        // Controls what the user is allowed to do within the MES application.
        // Values are defined in the MES User Role enum (Enum 50100):
        //   0 = Operator    — floor-level worker, basic MES operations only
        //   1 = Supervisor  — team lead, can view and approve work orders
        //   2 = Admin       — full access including user management via API
        // See MESAuthMgt.RequireAdmin() for how the Admin role is enforced.
        // ---------------------------------------------------------------------
        field(5; "Role"; Enum "MES User Role")
        {
            Caption            = 'Role';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 6 — Work Center No. (Foreign Key → Work Center."No.")
        // The production work center this user is assigned to.
        // Optional: leave blank for Admins who work across all work centers.
        // Returned in login and Me API responses so the MES frontend can
        // automatically scope the UI to the correct work center on login.
        // ---------------------------------------------------------------------
        field(6; "Work Center No."; Code[20])
        {
            Caption            = 'Work Center No.';
            TableRelation      = "Work Center"."No.";
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 7 — Is Active
        // Controls whether this account can authenticate.
        //   true  → account is enabled; Login() and ValidateToken() will proceed
        //   false → account is locked; Login() returns "Account is disabled"
        //           and all existing tokens are revoked immediately on deactivation
        // Use SetActive() (via AdminSetActive API) to toggle this flag — do not
        // set it directly, as SetActive() also handles token revocation.
        // ---------------------------------------------------------------------
        field(7; "Is Active"; Boolean)
        {
            Caption            = 'Is Active';
            DataClassification = SystemMetadata;
        }

        // ---------------------------------------------------------------------
        // Field 8 — Need To Change Password
        // When TRUE, the user must call ChangePassword before using the MES app.
        //   true  → set on: account creation, AdminSetPassword with forceChange=true
        //   false → set on: user successfully calls ChangePassword themselves
        // The MES frontend should check this flag in the Login and Me responses
        // and redirect to a password-change screen when it is true.
        // ---------------------------------------------------------------------
        field(8; "Need To Change Pw"; Boolean)
        {
            Caption            = 'Need To Change Password';
            DataClassification = SystemMetadata;
        }

        // ---------------------------------------------------------------------
        // Field 9 — Password Salt
        // Randomly generated hex string mixed into the password before hashing
        // to ensure two users with the same password produce different hashes.
        // Generated by MESPasswordMgt.MakeSalt() (SHA-256 of GUID + timestamp).
        // Stored length is capped at 50 chars by CopyStr() in SetPassword().
        // The underlying SHA-256 output is 64 hex chars — widening this field
        // to Text[64] would store the full salt without truncation.
        // ---------------------------------------------------------------------
        field(9; "Password Salt"; Text[50])
        {
            Caption            = 'Password Salt';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 10 — Hashed Password
        // The result of iterating SHA-256(password + salt) N times, stored as
        // a hex string.  Never stores the plaintext password.
        // Generated by MESPasswordMgt.HashPassword().
        // 128 chars accommodates up to SHA-512 output (128 hex chars) for
        // potential future algorithm upgrades without a schema change.
        // ---------------------------------------------------------------------
        field(10; "Hashed Password"; Text[128])
        {
            Caption            = 'Password Hash';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 11 — Password Iterations
        // Number of SHA-256 rounds applied during hashing (PBKDF2-style).
        // Higher values make brute-force attacks more expensive.
        // Default: 1 000 (set by DefaultPasswordIterations() in MESAuthMgt.al).
        // Production recommendation: 100 000 or higher — benchmark on your
        // server to find the maximum value that keeps login latency acceptable.
        // Stored per-user so that the iteration count can be increased over time
        // without invalidating existing passwords.
        // ---------------------------------------------------------------------
        field(11; "Password Iterations"; Integer)
        {
            Caption            = 'Password Iterations';
            DataClassification = SystemMetadata;
        }

        // ---------------------------------------------------------------------
        // Field 12 — Created At
        // UTC timestamp set once at Insert() time.  Never modified after that.
        // Used for audit trail and reporting (e.g. "accounts created this month").
        // ---------------------------------------------------------------------
        field(12; "Created At"; DateTime)
        {
            Caption            = 'Created At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        // Primary key — clustered index on User Id.
        // Clustered = true means the SQL Server data pages are physically sorted
        // by User Id on disk.  Every Login() call does a U.Get(UserId) which
        // resolves in O(log n) with no secondary lookup.  This is the correct
        // choice for a table whose reads are almost exclusively by primary key.
        key(PK; "User Id")
        {
            Clustered = true;
        }

        // Secondary key — non-clustered index on Role.
        // Enables efficient "find all users with Role = X" queries.
        // Currently used for reporting; reserved for future role-based filtering
        // in admin list APIs.
        key(UserRole; "Role") { }
    }
}
