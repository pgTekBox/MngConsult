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
                               
                                 <div>Product</div>
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
                                                  <asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' />
                                                 
                                                <div class="cell">
                                                    <div class="m-label">Produit</div>
                                                    <telerik:RadComboBox ID="rcProducts" runat="server" AutoPostBack="true"
                                                        EmptyMessage="Sélectionner un produit..."
                                                        Filter="Contains"
                                                        MarkFirstMatch="true"
                                                        EnableLoadOnDemand="true"
                                                        DataTextField="Name" DataValueField="Id"
                                                        OnSelectedIndexChanged="rcProducts_SelectedIndexChanged"  />
                                                     <asp:HiddenField ID="hidProductId" runat="server" Value='<%# Eval("ProductId") %>' />

                                                </div>
                                                <div class="cell">
                                                    <div class="m-label">Description</div>
                                                    <telerik:RadTextBox ID="txtDesc" runat="server"
                                                        TextMode="MultiLine" Rows="2"
                                                        Text='<%# Eval("Description") %>' />
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <span class="m-label">Qty</span>
                                                    <telerik:RadNumericTextBox ID="numQty"   runat="server"
                                                        Text='<%# IIf(Eval("Qty") Is DBNull.Value, Nothing, Eval("Qty")) %>'
                                                        MinValue="0" >
                                                        <NumberFormat DecimalDigits="4" />


                                                    </telerik:RadNumericTextBox>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <span class="m-label">Prix unité</span>
                                                    <telerik:RadNumericTextBox ID="numUnitPrice" runat="server"  Width="200px"
                                                        Text='<%# IIf(Eval("UnitPrice") Is DBNull.Value, Nothing, Eval("UnitPrice")) %>'
                                                        MinValue="0">
                                                        <NumberFormat DecimalDigits="2" />


                                                    </telerik:RadNumericTextBox>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <div class="m-label">Total</div>
                                                    <asp:Label ID="lblAmount" runat="server" CssClass="lbl-amount"
                                                        Text='<%# Eval("Amount","{0:N2}") %>' />
                                                </div>

                                                <div class="cell actions" style="text-align: center">
                                                    <div class="m-label">Action</div>
                                                    <telerik:RadButton ID="RadButton1" runat="server"
                                                        Text="Supprimer"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClicking="function(s,e){ if(!confirm('Supprimer cette ligne ?')) e.set_cancel(true); }" />


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

        <script type="text/javascript">
            // helper: number parsing (manage comma or point)
            function toNumber(v) {
                if (v === null || v === undefined || v === '') return 0;
                if (typeof v === 'number') return v;
                v = String(v).replace(/\s/g, '').replace(',', '.');
                var n = parseFloat(v);
                return isNaN(n) ? 0 : n;
            }

            // Called by RadNumericTextBox client event
            function onItemValueChanged(sender, eventArgs) {
                try {




                    // sender is the RadNumericTextBox client object
                    var inputEl = sender.get_element(); // the actual input DOM element
                    // find the repeater item container (.item-row)
                    var itemRow = inputEl.closest('.item-row');
                    if (!itemRow) return;

                    // find qty and unit price inputs inside this row
                    // they might be RadNumericTextBox inputs; select by id fragment or by name/class
                    var qtyInput = itemRow.querySelector('input[id*="numQty"]');
                    var priceInput = itemRow.querySelector('input[id*="numUnitPrice"]');

                    var qty = toNumber(qtyInput ? qtyInput.value : sender.get_value());
                    var unitPrice = toNumber(priceInput ? priceInput.value : 0);

                    var amount = Math.round((qty * unitPrice) * 100) / 100; // 2 decimals

                    // update label
                    var lbl = itemRow.querySelector('.lbl-amount');
                    if (lbl) {
                        lbl.innerText = amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                    }

                    // update a hidden field in the row so server can pick up values on postback (recommended)
                    var hidQty = itemRow.querySelector('input[type="hidden"][id*="hidQty"]');
                    if (!hidQty) {
                        // create for later postback if not exists
                        hidQty = document.createElement('input');
                        hidQty.type = 'hidden';
                        hidQty.id = itemRow.querySelector('input[id*="hidId"]').id + '_qty';
                        hidQty.name = hidQty.id;
                        itemRow.appendChild(hidQty);
                    }
                    hidQty.value = qty;

                    var hidPrice = itemRow.querySelector('input[type="hidden"][id*="hidUnitPrice"]');
                    if (!hidPrice) {
                        hidPrice = document.createElement('input');
                        hidPrice.type = 'hidden';
                        hidPrice.id = itemRow.querySelector('input[id*="hidId"]').id + '_price';
                        hidPrice.name = hidPrice.id;
                        itemRow.appendChild(hidPrice);
                    }
                    hidPrice.value = unitPrice;

                    // recalc totals visible
                    recalcTotalsClient();

                    // optional: mark row as dirty via hidden field
                    var hidDirty = itemRow.querySelector('input[type="hidden"][id*="hidDirty"]');
                    if (!hidDirty) {
                        hidDirty = document.createElement('input');
                        hidDirty.type = 'hidden';
                        hidDirty.id = itemRow.querySelector('input[id*="hidId"]').id + '_dirty';
                        hidDirty.name = hidDirty.id;
                        itemRow.appendChild(hidDirty);
                    }
                    hidDirty.value = '1';

                } catch (ex) {
                    console.log('onItemValueChanged error', ex);
                }
            }

            function recalcTotalsClient() {
                var subtotal = 0;
                document.querySelectorAll('.item-row').forEach(function (row) {
                    // skip deleted rows (you may add a data-deleted attr)
                    var deletedFlag = row.getAttribute('data-deleted');
                    if (deletedFlag === '1') return;

                    var lbl = row.querySelector('.lbl-amount');
                    if (!lbl) return;
                    var text = lbl.innerText || lbl.textContent;
                    // remove thousands and convert
                    var v = String(text).replace(/\s/g, '').replace(',', '.');
                    var n = parseFloat(v);
                    if (!isNaN(n)) subtotal += n;
                });

                // taxes (example 5% + 9.975%)
                var tps = Math.round(subtotal * 0.05 * 100) / 100;
                var tvq = Math.round(subtotal * 0.09975 * 100) / 100;
                var total = Math.round((subtotal + tps + tvq) * 100) / 100;

                var elSub = document.querySelector('#<%= lblSubTotal.ClientID %>');
      var elTax1 = document.querySelector('#<%= lblTax1.ClientID %>');
      var elTax2 = document.querySelector('#<%= lblTax2.ClientID %>');
      var elTotal = document.querySelector('#<%= lblTotal.ClientID %>');

                if (elSub) elSub.innerText = subtotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                if (elTax1) elTax1.innerText = tps.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                if (elTax2) elTax2.innerText = tvq.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                if (elTotal) elTotal.innerText = total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            }

            // optional: run once on page load to normalize UI
            document.addEventListener('DOMContentLoaded', function () {
                recalcTotalsClient();
            });
        </script>

        <script type="text/javascript">
            // ===== CONFIG TAXES =====
            var TAX_TPS = 0.05;
            var TAX_TVQ = 0.09975;

            function toNum(v) {
                if (v == null) return 0;
                v = ("" + v).replace(/\s/g, "").replace(",", ".");
                var n = parseFloat(v);
                return isNaN(n) ? 0 : n;
            }

            function fmt2(n) {
                n = (isNaN(n) || n == null) ? 0 : n;
                return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            }

            function recalcRow(row) {
                var qtyEl = row.querySelector("input[id*='numQty']");
                var prEl = row.querySelector("input[id*='numUnitPrice']");
                if (!qtyEl || !prEl) return 0;

                var qty = toNum(qtyEl.value);
                var pr = toNum(prEl.value);

                var amt = Math.round(qty * pr * 100) / 100;

                var lbl = row.querySelector(".lbl-amount");
                if (lbl) lbl.innerText = fmt2(amt);

                return amt;
            }

            function recalcTotals() {
                var subtotal = 0;

                document.querySelectorAll(".item-row").forEach(function (row) {
                    if (row.getAttribute("data-deleted") === "1") return;
                    subtotal += recalcRow(row);
                });

                subtotal = Math.round(subtotal * 100) / 100;

                var tps = Math.round(subtotal * TAX_TPS * 100) / 100;
                var tvq = Math.round(subtotal * TAX_TVQ * 100) / 100;
                var total = Math.round((subtotal + tps + tvq) * 100) / 100;

                // Labels server-side (ClientID)
                var elSub = document.getElementById("<%= lblSubTotal.ClientID %>");
                var elTps = document.getElementById("<%= lblTax1.ClientID %>");
                var elTvq = document.getElementById("<%= lblTax2.ClientID %>");
                var elTot = document.getElementById("<%= lblTotal.ClientID %>");

                if (elSub) elSub.innerText = fmt2(subtotal);
                if (elTps) elTps.innerText = fmt2(tps);
                if (elTvq) elTvq.innerText = fmt2(tvq);
                if (elTot) elTot.innerText = fmt2(total);
            }

            function wireInvoiceInputs() {
                // Attache events à chaque input (1 seule fois)
                document.querySelectorAll(".item-row input[id*='numQty'], .item-row input[id*='numUnitPrice']")
                    .forEach(function (inp) {
                        if (inp.dataset.wired === "1") return;
                        inp.dataset.wired = "1";

                        // input = à chaque modification (touche, collage, wheel, etc.)
                        inp.addEventListener("input", function () {
                            var row = inp.closest(".item-row");
                            if (row) {
                                recalcRow(row);
                                recalcTotals();
                            }
                        });

                        // fallback
                        inp.addEventListener("keyup", function () {
                            var row = inp.closest(".item-row");
                            if (row) {
                                recalcRow(row);
                                recalcTotals();
                            }
                        });
                    });

                // Calcul initial
                recalcTotals();
            }

            // 1) Load initial
            document.addEventListener("DOMContentLoaded", function () {
                wireInvoiceInputs();
            });

            // 2) Après RadAjax (UpdatePanel/Telerik)
            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(function () {
                    wireInvoiceInputs();
                });
            }

            // Optionnel: helper si tu veux marquer une ligne supprimée sans rebind
            function markRowDeleted(buttonEl) {
                var row = buttonEl.closest(".item-row");
                if (row) {
                    row.setAttribute("data-deleted", "1");
                    row.style.display = "none";
                    recalcTotals();
                }
            }
        </script>

    </form>
</body>
</html>
