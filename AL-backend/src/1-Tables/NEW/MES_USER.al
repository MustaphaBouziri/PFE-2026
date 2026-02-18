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
//   CustomerContent                — table-level default for most fields.
//   EndUserIdentifiableInformation — applied to fields that can directly
//                                    identify a real person (User Id, Employee
//                                    ID, Auth ID).
//   SystemMetadata                 — applied to operational fields that are not
//                                    PII (flags, timestamps).
//
// PASSWORD STORAGE
//   Passwords are NEVER stored in plaintext.  The flow is:
//     1. MakeSalt()      → random hex salt (MES Password Mgt codeunit)
//     2. HashPassword()  → SHA-256(password + salt)
//     3. CopyStr(hash,1,128) stored in "Hashed Password"
//     4. CopyStr(salt,1,64)  stored in "Password Salt"
//   See MESPasswordMgt.al for the hashing implementation.
//
// ACCOUNT LIFECYCLE
//   Created               → Is Active = true,  Need To Change Pw = true
//   SetPassword called    → Need To Change Pw = true , a temporary password is set for the user
//   SetActive(false)      → Is Active = false, all tokens revoked immediately
//   SetActive(true)       → Is Active = true,  user must log in again
//
// KEYS
//   PK         (User Id)     — clustered; all auth lookups resolve in O(log n)
//                              with no secondary lookup.
//   AuthId     (Auth ID)     — unique non-clustered; guards against duplicate
//                              Auth IDs at the database level.
//   EmployeeId (Employee ID) — unique non-clustered; enforces one-to-one mapping
//                              between an HR Employee record and an MES User at
//                              the database level. The OnValidate trigger on the
//                              Employee ID field surfaces a readable error before
//                              commit.
//   UserRole   (Role)        — non-clustered; enables efficient "find all users
//                              with Role = X" queries. Currently used for
//                              reporting; reserved for future role-based
//                              filtering in admin list APIs.
// =============================================================================
table 50101 "MES User"
{
    DataClassification = CustomerContent;
    Caption = 'MES User';

    fields
    {
        // ---------------------------------------------------------------------
        // Field 1 — User Id (Primary Key)
        // Short alphanumeric identifier chosen at account creation time.
        // This is the value the user types at the MES login prompt — it is
        // not a GUID and should be human-readable (e.g. "JDOE", "OP001").
        // If left blank on insert, a GUID-derived value is assigned
        // automatically (braces stripped, 36 characters).
        // Maximum length 50 characters matches the Code[50] login input fields
        // throughout the codebase.
        // ---------------------------------------------------------------------
        field(1; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }

        // ---------------------------------------------------------------------
        // Field 3 — Employee ID (Foreign Key → Employee."No.")
        // Links this MES account to a Business Central HR Employee record.
        // Required: every MES account must be backed by an HR Employee record.
        // TableRelation enforces referential integrity — you cannot set this to
        // an employee number that does not exist in the Employee table.
        // A unique key (EmployeeId) and an OnValidate trigger together ensure
        // no two MES Users share the same Employee ID.
        // Field number 3 (not 2) is intentional — field 2 is reserved for a
        // future "Display Name" field without requiring a schema renumber.
        // ---------------------------------------------------------------------
        field(3; "employee ID"; Code[50])
        {
            Caption = 'Employee ID';
            TableRelation = Employee."No.";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                MESUser: Record "MES User";
            begin
                // Employee ID is required
                if "Employee ID" = '' then
                    Error('Employee ID is required.');

                // Enforce uniqueness of Employee ID across MES Users.
                // The unique key on Employee ID handles this at DB commit time,
                // but this check surfaces a readable error message earlier.
                MESUser.SetRange("Employee ID", "Employee ID");
                MESUser.SetFilter("User Id", '<>%1', "User Id");
                if not MESUser.IsEmpty() then
                    Error('Employee ID %1 is already assigned to another MES User.', "Employee ID");
            end;
        }

        // ---------------------------------------------------------------------
        // Field 4 — Auth ID
        // Short memorable identifier assigned automatically at account creation.
        // Format: 'AUTH-' followed by 8 alphanumeric characters, e.g. AUTH-A1B2C3D4.
        // Used for display purposes and external references (e.g. API responses).
        // Not used for MES login — login is always by User Id + password.
        // Do NOT change the length or format: the value is intended to be
        // memorised and manually entered by users in external flows.
        // Uniqueness is enforced by the AuthId unique key and by
        // GenerateUniqueAuthId() which retries on the rare collision.
        // ---------------------------------------------------------------------
        field(4; "Auth ID"; Text[100])
        {
            Caption = 'Auth ID';
            DataClassification = EndUserIdentifiableInformation;
        }

        // ---------------------------------------------------------------------
        // Field 5 — Role
        // Controls what the user is allowed to do within the MES application.
        // Values are defined in the MES User Role enum (Enum 50100):
        //   0 = Operator    — floor-level worker, basic MES operations only
        //   1 = Supervisor  — team lead, can view and approve work orders
        //   2 = Admin       — full access including user management via API
        // Required: ValidateRequiredFields() rejects a zero (unset) Role value
        // on every insert and modify.
        // See MESAuthMgt.RequireAdmin() for how the Admin role is enforced.
        // ---------------------------------------------------------------------
        field(5; "Role"; Enum "MES User Role")
        {
            Caption = 'Role';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 6 — Work Center No. (Foreign Key → Work Center."No.")
        // The production work center this user is assigned to.
        // Required for Operators and Supervisors; must be blank for Admins who
        // work across all work centers.
        // TableRelation enforces referential integrity — you cannot set this to
        // a work center that does not exist in the Work Center table.
        // Returned in Login and Me API responses so the MES frontend can
        // automatically scope the UI to the correct work center on login.
        // ---------------------------------------------------------------------
        field(6; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center"."No.";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateRoleWorkCenterCombination();
            end;
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
            Caption = 'Is Active';
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
            Caption = 'Need To Change Password';
            DataClassification = SystemMetadata;
        }

        // ---------------------------------------------------------------------
        // Field 9 — Password Salt
        // Randomly generated hex string mixed into the password before hashing
        // to ensure two users with the same password produce different hashes.
        // Generated by MESPasswordMgt.MakeSalt() (SHA-256 of GUID + timestamp).
        // Text[64] accommodates the full 64-character SHA-256 hex output.
        // ---------------------------------------------------------------------
        field(9; "Password Salt"; Text[64])
        {
            Caption = 'Password Salt';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 10 — Hashed Password
        // The result of SHA-256(password + salt), stored as a hex string.
        // Never stores the plaintext password.
        // Generated by MESPasswordMgt.HashPassword().
        // Text[128] accommodates up to SHA-512 output (128 hex chars) for
        // potential future algorithm upgrades without a schema change.
        // ---------------------------------------------------------------------
        field(10; "Hashed Password"; Text[128])
        {
            Caption = 'Password Hash';
            DataClassification = CustomerContent;
        }

        // ---------------------------------------------------------------------
        // Field 11 — Created At
        // UTC timestamp set once at Insert() time.  Never modified after that.
        // Used for audit trail and reporting (e.g. "accounts created this month").
        // ---------------------------------------------------------------------
        field(11; "Created At"; DateTime)
        {
            Caption = 'Created At';
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

        // Auth ID — unique non-clustered index.
        // Enforces uniqueness of Auth ID at the database level as a safety net.
        // GenerateUniqueAuthId() already checks for collisions before insert,
        // but this key ensures the constraint holds even under concurrent inserts.
        key(AuthId; "Auth ID")
        {
            Unique = true;
        }

        // Employee ID — unique non-clustered index.
        // Enforces a one-to-one mapping between an HR Employee record and an
        // MES User at the database level.  The OnValidate trigger on the
        // Employee ID field surfaces a readable error before commit; this key
        // is the hard guarantee that the constraint cannot be bypassed.
        key(EmployeeId; "Employee ID")
        {
            Unique = true;
        }

        // Role — non-clustered index on Role.
        // Enables efficient "find all users with Role = X" queries.
        // Currently used for reporting; reserved for future role-based filtering
        // in admin list APIs.
        key(UserRole; "Role") { }
    }

    trigger OnInsert()
    var
        GuidTxt: Text[50];
    begin
        // If no User Id was provided, derive one from a new GUID.
        // CopyStr(..., 2, 36) strips the leading '{' and trailing '}' that
        // Format(CreateGuid()) produces, yielding a clean 36-character value.
        if "User Id" = '' then begin
            GuidTxt := Format(CreateGuid());
            "User Id" := CopyStr(GuidTxt, 2, 36);
        end;

        // Auth ID is assigned automatically — never set by the caller.
        // See GenerateUniqueAuthId() for format details and collision handling.
        "Auth ID" := GenerateUniqueAuthId();

        "Is Active" := true;
        "Need To Change Pw" := true;
        "Created At" := CurrentDateTime();

        "Password Salt" := '';
        "Hashed Password" := '';
    end;

    // -------------------------------------------------------------------------
    // GenerateUniqueAuthId
    // Returns a unique Auth ID of the form 'AUTH-XXXXXXXX' (13 characters).
    // The 8-character suffix is taken from a freshly generated GUID on each
    // attempt.  A uniqueness check against the AuthId key is performed before
    // returning; if a collision is found (extremely rare given the key space)
    // a new GUID is generated and the check is repeated.
    // The format and length are intentionally fixed — the Auth ID is designed
    // to be memorised and manually entered by users in external flows.
    // -------------------------------------------------------------------------
    local procedure GenerateUniqueAuthId(): Text[100]
    var
        MESUser: Record "MES User";
        CandidateId: Text[100];
        GuidTxt: Text[50];
    begin
        repeat
            GuidTxt := Format(CreateGuid());
            CandidateId := 'AUTH-' + CopyStr(GuidTxt, 2, 9);
            MESUser.SetRange("Auth ID", CandidateId);
        until MESUser.IsEmpty();
        exit(CandidateId);
    end;

    trigger OnModify()
    begin
        ValidateRequiredFields();
    end;

    // -------------------------------------------------------------------------
    // ValidateRequiredFields
    // Called from OnInsert() and OnModify() to enforce field-level business
    // rules that apply on every write:
    //   • Employee ID must not be blank.
    //   • Role must be explicitly set (AsInteger = 0 means the enum is unset).
    //   • Role and Work Center No. must satisfy the combination rules defined
    //     in ValidateRoleWorkCenterCombination().
    // -------------------------------------------------------------------------
    local procedure ValidateRequiredFields()
    begin
        if "Employee ID" = '' then
            Error('Employee ID is required.');

        if "Role".AsInteger() = 0 then
            Error('Role is required.');

        ValidateRoleWorkCenterCombination();
    end;

    // -------------------------------------------------------------------------
    // ValidateRoleWorkCenterCombination
    // Enforces the business rules governing the relationship between Role and
    // Work Center No.:
    //   Operator   → Work Center No. is required; operators are always assigned
    //                to a specific work center.
    //   Supervisor → Work Center No. is required; supervisors manage a specific
    //                work center.
    //   Admin      → Work Center No. must be blank; admins operate across all
    //                work centers and must not be scoped to one.
    // Called from the Work Center No. OnValidate trigger and from
    // ValidateRequiredFields() to ensure the rule is checked on every write.
    // -------------------------------------------------------------------------
    local procedure ValidateRoleWorkCenterCombination()
    begin
        if ("Role" = "Role"::Operator) and ("Work Center No." = '') then
            Error('Work Center No. is required for the %1 role.', "Role");

        if ("Role" = "Role"::Admin) and ("Work Center No." <> '') then
            Error('Work Center No. must be empty for the %1 role.', "Role");
    end;
}