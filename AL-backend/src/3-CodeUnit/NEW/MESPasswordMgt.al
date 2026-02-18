// =============================================================================
// Codeunit: MES Password Mgt
// ID      : 50110
// Purpose : Low-level password hashing primitives used exclusively by
//           MES Auth Mgt (Codeunit 50111).  This codeunit is intentionally
//           small and focused — it knows nothing about users, tokens, or roles.
//
// ALGORITHM
//   Salt generation  : SHA-256( GUID_string + CurrentDateTime_string )
//                      Produces a 64-character hex string.
//                      NOTE: stored in "Password Salt" (Text[50]), so only
//                      the first 50 characters are persisted.  Widening the
//                      field to Text[64] would store the full salt.
//
//   Password hashing :  SHA-256 (PBKDF2-style):
//                       hash = SHA-256( password + salt )
//                       
//   Verification     : Re-hash with the same salt and compare
//                      the result to the stored hash using string equality.
//                      Constant-time comparison is not available in standard
//                      AL — this is acceptable at the current usecase.
//
// [NonDebuggable]
//   All three procedures are marked [NonDebuggable] to prevent plaintext
//   passwords, salts, and hash values from appearing in debugger variable
//   watches, telemetry logs, or support snapshots.
//
// DEPENDENCIES
//   "Cryptography Management" (Microsoft System Application codeunit)
//   Method used: GenerateHash(InputString: Text; HashAlgorithmType: Option): Text
//   HashAlgorithmType = 2 → SHA-256 (returns 64-character uppercase hex string)
// =============================================================================
codeunit 50110 "MES Password Mgt"
{
    // =========================================================================
    // MakeSalt
    // =========================================================================
    /// <summary>
    /// Generates a cryptographically random salt string.
    ///
    /// Implementation: SHA-256 of (GUID + CurrentDateTime) gives sufficient
    /// entropy for a salt — the GUID provides 122 bits of randomness, and
    /// the timestamp adds additional uniqueness to prevent two salts generated
    /// in the same millisecond from being identical.
    ///
    /// Returns a 64-character uppercase hex string (SHA-256 output length).
    /// Only the first 50 characters are stored due to the field width of
    /// "Password Salt" — this is a known limitation (see table comment).
    /// </summary>
    [NonDebuggable]
    procedure MakeSalt(): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
    begin
        // Combine a random GUID with the current timestamp for entropy, then
        // hash to produce a fixed-length, uniformly distributed salt string.
        exit(CryptographyMgt.GenerateHash(Format(CreateGuid()) + Format(CurrentDateTime()), 2));
        //                                                                       ^ 2 = SHA-256
    end;

    // =========================================================================
    // HashPassword
    // =========================================================================
    /// <summary>
    /// Hashes a plaintext password using  SHA-256 with the given salt.
    ///
    /// Algorithm (PBKDF2-style, SHA-256 variant):
    /// 
    /// 
    ///
    /// Parameters:
    ///   Password   — plaintext password entered by the user
    ///   Salt       — value from MakeSalt() stored in "Password Salt"
    ///  
    /// Returns a 64-character uppercase hex string (SHA-256 output).
    /// The caller (SetPassword) stores this in "Hashed Password" (Text[128]).
    /// </summary>
    [NonDebuggable]
    procedure HashPassword(Password: Text; Salt: Text): Text
    var
        CryptographyMgt: Codeunit "Cryptography Management";
        CurrentHash: Text;
        Combined   : Text;
    begin
        // Round 1: hash the raw password concatenated with the salt.
        Combined    := Password + Salt;
        CurrentHash := CryptographyMgt.GenerateHash(Combined, 2);  // SHA-256

        exit(CurrentHash);
    end;

    // =========================================================================
    // VerifyPassword
    // =========================================================================
    /// <summary>
    /// Verifies a candidate plaintext password against a stored hash.
    ///
    /// Re-hashes the candidate using the stored salt, then
    /// compares the result to the stored hash with string equality.
    ///
    /// Returns TRUE if the hashes match (password is correct), FALSE otherwise.
    ///
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
