
//this table is added cuz now users can have multiple work center
table 50115 "MES User Work Center"
{
    DataClassification = CustomerContent;
    Caption = 'MES User Work Center';

    fields
    {
        field(1; "User Id"; Code[50])
        {
            TableRelation = "MES User"."User Id";
            DataClassification = CustomerContent;
        }

        field(2; "Work Center No."; Code[20])
        {
            TableRelation = "Work Center"."No.";
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "User Id", "Work Center No.") { Clustered = true; }
        key(UserKey; "User Id") { }
    }
}