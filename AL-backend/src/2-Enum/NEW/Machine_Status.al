
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
