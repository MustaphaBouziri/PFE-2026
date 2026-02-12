permissionset 50130 "MES AUTH API"
{
    Assignable = true;

    Permissions =
        tabledata "MES User" = RIMD,
        tabledata "MES Auth Token" = RIMD,
        table "MES Auth Token" = X,
        codeunit "MES Password Mgt" = X,
        codeunit "MES Auth Mgt" = X,
        codeunit "MES Auth API" = X;
}
