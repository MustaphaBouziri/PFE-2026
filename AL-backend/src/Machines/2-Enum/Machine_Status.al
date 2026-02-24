// =============================================================================
// Enum   : MES Machine Status
// ID     : 50101
// Domain : Machines / 2-Enums
// Purpose: Operational states a machine can be in.
//          Stored in "MES Machine Status"."Status" and returned by
//          FetchMachines() as a formatted string (e.g. "Idle", "OutOfOrder").
//          Extensible = true allows other extensions to add custom states.
// =============================================================================
enum 50101 "MES Machine Status"
{
    Extensible = true;

    value(0; Idle)
    {
        Caption = 'Idle';
    }

    value(1; Starting)
    {
        Caption = 'Starting';
    }

    value(2; OutOfOrder)
    {
        Caption = 'OutOfOrder';
    }
}
