<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfInvoiceEdit.aspx.vb" Inherits="MngConsul.wbfInvoiceEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Facture</title>

    <style>
        :root {
            --bg: #f6f8fc;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --accent: #2563eb;
            --accent2: #06b6d4;
            --r-md: 14px;
            --r-lg: 18px;
            --r-xl: 22px;
            --shadow: 0 18px 50px rgba(2,6,23,.10);
        }

        html, body, form {
            height: 100%
        }

        body {
            margin: 0;
            background: var(--bg);
            font-family: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
            color: var(--text);
        }

        /* layout */
        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column
        }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 5;
            padding: 14px;
            background: rgba(255,255,255,.9);
            border-bottom: 1px solid var(--line);
        }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px
        }

        .card {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--r-xl);
            box-shadow: var(--shadow);
        }

        .card-header {
            padding: 12px 14px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--line);
        }

        .card-body {
            padding: 14px
        }

        .row2 {
            display: grid;
            gap: 12px
        }

        .row4 {
            display: grid;
            gap: 12px
        }

        @media(min-width:840px) {
            .row2 {
                grid-template-columns: 1fr 1fr
            }

            .row4 {
                grid-template-columns: 1fr 1fr 1fr 1fr
            }
        }

        /* ========= ITEMS RESPONSIVE ========= */

        .items-header {
            display: none
        }

        .items-wrap {
            display: flex;
            flex-direction: column;
            gap: 10px
        }

        .item-row {
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            background: #fff;
        }

        @media(min-width:840px) {

            .items-header {
                display: grid;
                grid-template-columns: 140px 1fr 120px 140px 140px 110px;
                border: 1px solid var(--line);
                border-radius: var(--r-lg);
                overflow: hidden;
                margin-bottom: 8px;
            }

                .items-header div {
                    padding: 10px;
                    font-size: 12px;
                    font-weight: 900;
                    color: var(--muted);
                    background: #f8fafc;
                    border-right: 1px solid var(--line);
                }

            .item-grid {
                display: grid;
                grid-template-columns: 140px 1fr 120px 140px 140px 110px;
            }

            .cell {
                padding: 10px;
                border-bottom: 1px solid var(--line);
                border-right: 1px solid var(--line);
            }

            .m-label {
                display: none
            }
        }

        /* mobile */

        @media(max-width:839px) {

            .item-grid {
                display: flex;
                flex-direction: column;
                gap: 10px;
                padding: 12px;
            }

            .cell {
                border: none;
                padding: 0
            }

            .m-label {
                display: block;
                font-size: 11px;
                color: var(--muted);
                margin-bottom: 4px;
            }

            .cell.actions {
                display: flex;
                gap: 8px;
                flex-wrap: wrap;
            }

                .cell.actions > * {
                    flex: 1;
                    min-width: 140px;
                }
        }

        /* footer totals */

        .footerbar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid var(--line);
            padding: 12px 14px;
        }

        .totals {
            display: flex;
            gap: 14px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .tot {
            min-width: 150px;
            padding: 10px;
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            text-align: right;
        }

        .RadInput, .RadPicker, .RadComboBox, .RadNumericTextBox {
            width: 100% !important
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />

        <telerik:RadAjaxManager ID="Ram1" runat="server">
            <AjaxSettings>

                  <telerik:AjaxSetting AjaxControlID="ddlCustomer">
      <UpdatedControls>
        
          <telerik:AjaxUpdatedControl ControlID="rdLabel" />
      </UpdatedControls>
  </telerik:AjaxSetting>


                <telerik:AjaxSetting AjaxControlID="btnAddLine">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <telerik:AjaxSetting AjaxControlID="rpItems">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <!-- TOP -->
            <div class="topbar">
                <strong>Édition de facture</strong>
            </div>

            <!-- CONTENT -->
            <div class="content">
                <div class="container">

                    <!-- HEADER -->
                    <div class="card">
                        <div class="card-body">

                            <div class="row2">

                                <div>
                                    <label>Client</label>
                                    <telerik:RadComboBox ID="ddlCustomer" runat="server" AutoPostBack="true"
                                        EmptyMessage="Sélectionner un client..."
                                        Filter="Contains"
                                        MarkFirstMatch="true"
                                        EnableLoadOnDemand="true" />
                                </div>

                              
                                    <div class="field">
                                        <div style="height: 100%; display: flex; align-items: flex-end;">
                                            <telerik:RadLabel ID="rdLabel" runat="server"></telerik:RadLabel>
                                        </div>
                                    </div>
                                

                            </div>

                            <div style="height: 12px"></div>

                            <div class="row4">
                                <div>
                                    <label>Date facture</label>
                                    <telerik:RadDatePicker ID="dpIssueDate" runat="server" />
                                </div>

                                <div>
                                    <label>Date d’échéance</label>
                                    <telerik:RadDatePicker ID="dpDueDate" runat="server" />
                                </div>
                            </div>

                        </div>
                    </div>

                    <!-- ITEMS -->
                    <div class="card">
                        <div class="card-header">
                            <strong>Lignes</strong>
                            <telerik:RadButton ID="btnAddLine" runat="server" Text="+ Ajouter une ligne" Width="170px" />
                        </div>

                        <div class="card-body">

                            <!-- header desktop -->
                            <div class="items-header">
                                <div>Code</div>
                                <div>Description</div>
                                <div style="text-align: right">Qty</div>
                                <div style="text-align: right">Prix unité</div>
                                <div style="text-align: right">Total</div>
                                <div style="text-align: center">Action</div>
                            </div>

                            <div class="items-wrap">

                                <asp:Repeater ID="rpItems" runat="server">
                                    <ItemTemplate>

                                        <div class="item-row">
                                            <div class="item-grid">

                                                <div class="cell">
                                                    <div class="m-label">Code</div>
                                                    <telerik:RadTextBox ID="txtItemCode" runat="server"
                                                        Text='<%# Eval("ProductId") %>' />
                                                    <asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' />
                                                </div>

                                                <div class="cell">
                                                    <div class="m-label">Description</div>
                                                    <telerik:RadTextBox ID="txtDesc" runat="server"
                                                        TextMode="MultiLine" Rows="2"
                                                        Text='<%# Eval("Description") %>' />
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <div class="m-label">Qty</div>
                                                    <telerik:RadNumericTextBox ID="numQty" runat="server"
                                                        Text='<%# IIf(Eval("Qty") Is DBNull.Value, Nothing, Eval("Qty")) %>'
                                                        MinValue="0">
                                                        <NumberFormat DecimalDigits="4" />
                                                    </telerik:RadNumericTextBox>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <div class="m-label">Prix unité</div>
                                                    <telerik:RadNumericTextBox ID="numUnitPrice" runat="server"
                                                        Text='<%# IIf(Eval("UnitPrice") Is DBNull.Value, Nothing, Eval("UnitPrice")) %>'
                                                        MinValue="0">
                                                        <NumberFormat DecimalDigits="2" />
                                                    </telerik:RadNumericTextBox>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <div class="m-label">Total</div>
                                                    <asp:Label ID="lblAmount" runat="server"
                                                        Text='<%# Eval("Amount","{0:N2}") %>' />
                                                </div>

                                                <div class="cell actions" style="text-align: center">
                                                    <div class="m-label">Action</div>
                                                    <asp:Button ID="btnDelete" runat="server"
                                                        Text="Supprimer"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClick="return confirm('Supprimer cette ligne ?');" />
                                                </div>

                                            </div>
                                        </div>

                                    </ItemTemplate>
                                </asp:Repeater>

                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <!-- FOOTER -->
            <div class="footerbar">
                <div class="totals">

                    <div class="tot">
                        Sous-total<br />
                        <strong>
                            <asp:Label ID="lblSubTotal" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">
                        TPS<br />
                        <strong>
                            <asp:Label ID="lblTax1" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">
                        TVQ<br />
                        <strong>
                            <asp:Label ID="lblTax2" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">
                        Total<br />
                        <strong>
                            <asp:Label ID="lblTotal" runat="server" Text="0.00" /></strong>
                    </div>

                </div>
            </div>
            <asp:Button ID="btnSave" runat="server" Text="Enregistrer" />
        </asp:Panel>
    </form>
</body>
</html>
