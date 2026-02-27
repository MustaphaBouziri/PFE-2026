enum 50102 "MES Operation Status"
{
    Extensible = true;

    value(0; NotStarted)
    {
        Caption = 'NotStarted';
    }

    value(1; Running)
    {
        Caption = 'Running';
    }

    value(2; Paused)
    {
        Caption = 'Paused';
    }
    value(3; Finished)
    {
        Caption = 'Finished';
    }
}
