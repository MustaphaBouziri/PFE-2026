// =============================================================================
// Codeunit: MES Password Mgt
// ID      : 50110
// Domain  : Auth / 3-CodeUnits
// Purpose : Low-level password hashing primitives — the crypto layer.
//           Used exclusively by MES Auth Mgt (50111).
//           Knows nothing about users, tokens, or roles.
//
// ALGORITHM
//   Salt generation : SHA-256(GUID + CurrentDateTime) → 64-char hex string
//   Password hash   : SHA-256(password + salt)        → 64-char hex string
//   Verification    : re-hash with stored salt, compare with stored hash
//
// [NonDebuggable] on all three procedures ensures that passwords, salts, and
// hash values never appear in debugger variable watches, telemetry logs, or
// support snapshots.
//
// DEPENDENCY
//   "Cryptography Management" (Microsoft System Application codeunit)
//   GenerateHash(Input: Text; HashAlgorithmType: Option): Text
//   HashAlgorithmType = 2 → SHA-256 (64-character uppercase hex output)
// =============================================================================
codeunit 50110 "MES Password Mgt"
{
    /// <summary>
    /// Generates a cryptographically random salt string.
    /// Returns a 64-character uppercase SHA-256 hex string.
    /// Combining a random GUID with the current timestamp ensures sufficient
    /// entropy even if two salts are generated in the same millisecond.
    /// </summary>
    [NonDebuggable]
    procedure MakeSalt(): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
    begin
        exit(CryptographyMgt.GenerateHash(Format(CreateGuid()) + Format(CurrentDateTime()), 2)); // 2 = SHA-256
    end;

    /// <summary>
    /// Hashes a plaintext password: SHA-256(password + salt).
    /// Returns a 64-character uppercase hex string.
    /// </summary>
    [NonDebuggable]
    procedure HashPassword(Password: Text; Salt: Text): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        CurrentHash: Text;
        Combined: Text;
    begin
        // Round 1: hash the raw password concatenated with the salt.
        Combined := Password + Salt;
        CurrentHash := CryptographyMgt.GenerateHash(Combined, 2);  // SHA-256

        exit(CurrentHash);
    end;

    /// <summary>
    /// Verifies a candidate password against a stored hash.
    /// Re-hashes the candidate with the stored salt and compares.
    /// Returns TRUE if they match (password is correct), FALSE otherwise.
    /// </summary>
    [NonDebuggable]
    procedure VerifyPassword(Password: Text; StoredHash: Text; Salt: Text): Boolean
    var
        ComputedHash: Text;
    begin
        ComputedHash := HashPassword(Password, Salt);
        exit(ComputedHash = StoredHash);
    end;
}
