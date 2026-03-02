enum 50102 "MES Operation Status"
{
    Extensible = true;

    

    value(0; Running)
    {
        Caption = 'Running';
    }

    value(1; Paused)
    {
        Caption = 'Paused';
    }
    value(2; Finished)
    {
        Caption = 'Finished';
    }
}
