// =============================================================================
// Page   : MES Prod Order Component API
// ID     : 50110
// Domain : MES / Production
// Purpose: Read-only API — exposes Prod. Order Component table
//          Used to fetch BOM (materials) for a production order
//
// ENDPOINT
//   GET .../api/yourcompany/v1/v1.0/companies(<id>)/prodOrderComponents
// =============================================================================
page 50110 "MES Prod Order Comp API"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'v1';
    APIVersion = 'v1.0';
    EntityName = 'prodOrderComponent';
    EntitySetName = 'prodOrderComponents';
    SourceTable = "Prod. Order Component";
//http://localhost:7048/BC210/api/yourcompany/v1/v1.0/companies(9e31f41c-e73a-ed11-bbab-000d3a21ffa5)/prodOrderComponents
    DelayedInsert = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }

                field(prodOrderNo; Rec."Prod. Order No.")
                {
                    Caption = 'Prod Order No';
                }

                field(prodOrderLineNo; Rec."Prod. Order Line No.")
                {
                    Caption = 'Prod Order Line No';
                }

                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No';
                }

                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No';
                }

                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }

                field(quantity; Rec.Quantity)
                {
                    Caption = 'Required Quantity';
                }

                field(remainingQuantity; Rec."Remaining Quantity")
                {
                    Caption = 'Remaining Quantity';
                }

                field(actualConsumption; Rec."Act. Consumption (Qty)")
                {
                    Caption = 'Actual Consumption';
                }

                field(unitOfMeasure; Rec."Unit of Measure Code")
                {
                    Caption = 'UOM';
                }

                // 🔥 IMPORTANT — THIS IS WHAT YOU WANT TO TEST
                field(routingLinkCode; Rec."Routing Link Code")
                {
                    Caption = 'Routing Link Code';
                }
            }
        }
    }
}