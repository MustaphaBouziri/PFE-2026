table 50112 "MES User Execution Interaction"
{
    DataClassification = CustomerContent;
    Caption = 'MES User Execution Interaction';

    fields
    {
        field(1; "Execution Id"; Code[50])
        {
            Caption = 'Execution Id';
            TableRelation = "MES Operation Execution"."Execution Id";
            DataClassification = CustomerContent;
        }
        field(2; "User Id"; Code[50])
        {
            Caption = 'User Id';
            TableRelation = "MES User"."User Id";
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Execution Id", "User Id")
        {
            Clustered = true;
        }
        key(ByUser; "User Id") { }
    }
}