<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="ucReceiptEdit.ascx.vb" Inherits="MngConsul.ucReceiptEdit" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

    <style>
        .badge-posted {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 999px;
            background: #ecfdf5;
            color: #059669;
            font-size: 12px;
            font-weight: 700;
            border: 1px solid #a7f3d0;
        }

        .readonly {
            opacity: 0.85;
        }

        .readonly-blocked {
            pointer-events: none;
        }

        .readonly input,
        .readonly textarea {
            background-color: #f1f5f9 !important;
        }

        .footerbar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid var(--line);
            padding: 8px 14px;
        }

        .customer-selector,
        .bank-selector {
            display: block;
            width: 100%;
            min-height: 38px;
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: #fff;
            cursor: pointer;
            box-sizing: border-box;
        }

        .customer-selector::after,
        .bank-selector::after {
            content: "▾";
            float: right;
            color: #64748b;
        }

        .customer-selector:active,
        .bank-selector:active {
            background: #f1f5f9;
        }

        .customer-picker-overlay,
        .bank-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .customer-picker-shell,
        .bank-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .customer-picker-searchbar,
        .bank-picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px;
            border-bottom: 1px solid var(--line);
            background: #fff;
        }

        .customer-picker-close-inline,
        .bank-picker-close-inline {
            margin-left: auto;
            width: 44px;
            height: 44px;
            flex: 0 0 44px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            background: #fff;
            font-size: 20px;
            line-height: 1;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .customer-picker-close-inline:active,
        .bank-picker-close-inline:active {
            background: #f8fafc;
        }

        .customer-picker-input,
        .bank-picker-input {
            width: 100%;
            max-width: 260px;
            min-width: 0;
            height: 44px;
            padding: 0 12px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            box-sizing: border-box;
            font-size: 16px;
        }

        .customer-picker-list,
        .bank-picker-list {
            flex: 1 1 auto;
            min-height: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column;
        }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px;
            padding-bottom: 90px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
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
            padding: 14px;
        }

        .row2,
        .row3,
        .row4 {
            display: grid;
            gap: 12px;
        }

        .row2 {
            grid-template-columns: 1fr 1fr;
        }

        .row3 {
            grid-template-columns: auto auto 1fr;
        }

        .row4 {
            grid-template-columns: auto auto auto 1fr;
        }

        .qty-right input {
            text-align: right !important;
        }

        .RadComboBoxDropDown,
        .rcbSlide {
            max-height: 220px !important;
            overflow-y: auto !important;
            overflow-x: hidden !important;
            -webkit-overflow-scrolling: touch !important;
            touch-action: pan-y !important;
        }

        .RadInput, .RadPicker, .RadComboBox, .RadNumericTextBox {
            width: 100% !important;
        }

        .list-shell {
            flex: 1 1 auto;
            min-height: 0;
            display: flex;
            flex-direction: column;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .lv-footer {
            flex: 0 0 auto;
            position: sticky;
            bottom: 0;
            z-index: 3;
            padding: 14px 16px;
            background: #fff;
            border-top: 1px solid var(--line);
            text-align: right;
        }

        .items-wrap {
            flex: 1 1 auto;
            min-height: 0;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
            padding: 14px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 14px;
        }

        .customer-card,
        .bank-card {
            align-items: center;
            gap: 10px;
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }

        .Contact-name {
            font-size: 16px;
            font-weight: 800;
            color: var(--accent);
        }

        .BillingTo,
        .bank-name {
            font-size: 15px;
            font-weight: 600;
        }

        .bank-code {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 6px;
        }

        .empty {
            padding: 24px;
            color: var(--muted);
            text-align: center;
        }

        /* Grille des factures à encaisser */
        .invoices-header {
            display: grid;
            grid-template-columns: 140px 110px 110px 110px 110px 130px 40px;
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            overflow: hidden;
            margin-bottom: 8px;
            padding: 10px;
            font-size: 12px;
            font-weight: 900;
            color: var(--muted);
            background: #f8fafc;
            border-right: 1px solid var(--line);
        }

        .invoice-gridrow {
            display: grid;
            grid-template-columns: 140px 110px 110px 110px 110px 130px 40px;
            align-items: center;
            padding: 8px 10px;
            border-bottom: 1px solid var(--line);
        }

            .invoice-gridrow:hover {
                background: #f8fafc;
            }

        .invoice-checkbox {
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .totals {
            display: grid;
            grid-template-columns: auto auto;
            justify-content: end;
            column-gap: 30px;
        }

        .diff-ok {
            color: #059669;
            font-weight: 900;
        }

        .diff-ko {
            color: #dc2626;
            font-weight: 900;
        }

        @media (max-width: 480px) {
            .content {
                padding-bottom: 84px;
            }

            .totals {
                display: grid;
                grid-template-columns: 1fr 85px 85px;
            }
        }
    </style>

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="rapReceipt" runat="server" LoadingPanelID="RadAjaxLoadingPanel1">

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <div class="content">
                <div class="container">

                    <asp:Label ID="lblPostedBadge" runat="server" CssClass="badge-posted" Visible="false" Text="Comptabilisé 🔒"></asp:Label>

                    <%-- EN-TÊTE : CLIENT + INFOS RÈGLEMENT --%>
                    <div class="card">
                        <div class="card-body">

                            <div class="row2">
                                <div>
                                    <asp:Label ID="lblTiersLabel" runat="server" Text="Client" />
                                    <asp:Label ID="lblCustomer" runat="server" CssClass="customer-selector" Text="Sélectionner un client"></asp:Label>
                                </div>

                                <div class="field">
                                    <div style="height: 100%; display: flex; align-items: flex-end;">
                                        <telerik:RadLabel ID="rdLabel" runat="server"></telerik:RadLabel>
                                    </div>
                                </div>
                            </div>

                            <div style="height: 12px"></div>

                            <div class="row4">
                                <div style="width: 160px">
                                    <label><asp:Literal ID="litDateLabel" runat="server" /></label>
                                    <telerik:RadDatePicker Width="160px" ID="dpDateEncaissement" runat="server" />
                                </div>

                                <div style="width: 160px">
                                    <label><asp:Literal ID="litTypeReglLabel" runat="server" /></label>
                                    <telerik:RadComboBox ID="cbTypeReglement" runat="server" Width="160px">
                                        <Items>
                                            <telerik:RadComboBoxItem Text="Chèque" Value="CHEQUE" />
                                            <telerik:RadComboBoxItem Text="Virement" Value="VIREMENT" />
                                            <telerik:RadComboBoxItem Text="Espèces" Value="ESPECES" />
                                            <telerik:RadComboBoxItem Text="Carte" Value="CARTE" />
                                            <telerik:RadComboBoxItem Text="Autre" Value="AUTRE" />
                                        </Items>
                                    </telerik:RadComboBox>
                                </div>

                                <div style="width: 180px">
                                    <label><asp:Literal ID="litReferenceLabel" runat="server" /></label>
                                    <telerik:RadTextBox ID="txtReference" runat="server" />
                                </div>

                                <div>
                                    <br />
                                    <label><asp:Literal ID="litComptabiliseLabel" runat="server" /></label><asp:CheckBox ID="chkPost" runat="server" />
                                </div>
                            </div>

                            <div style="height: 12px"></div>

                            <div class="row2">
                                <div>
                                    <label><asp:Literal ID="litCompteBanqueLabel" runat="server" /></label>
                                    <asp:Label ID="lblBank" runat="server" CssClass="bank-selector"></asp:Label>
                                    <asp:HiddenField ID="hidBankCompte" runat="server" />
                                </div>

                                <div>
                                    <asp:Label ID="lblMontantLabel" runat="server" Text="Montant reçu total" />
                                    <telerik:RadTextBox ID="txtMontantRecu" runat="server"
                                        CssClass="num-right"
                                        oninput="fixNumber(this)" onblur="formatPrice(this); recalcDiff();" onfocus="this.select()"
                                        Text="0.00" />
                                </div>
                            </div>

                        </div>
                    </div>

                    <%-- LIGNES : FACTURES OUVERTES DU CLIENT --%>
                    <div class="card">
                        <div class="card-header">
                            <strong><asp:Literal ID="litLignesTitle" runat="server" Text="Factures ouvertes à encaisser" /></strong>
                            <telerik:RadButton ID="btnAutoImpute" runat="server" Text="Imputer automatiquement"
                                OnClientClicked="onAutoImputeClicked" AutoPostBack="false" />
                        </div>

                        <div class="card-body">
                            <div class="invoices-header">
                                <div><asp:Literal ID="litColNoFacture" runat="server" /></div>
                                <div style="text-align: center"><asp:Literal ID="litColDate" runat="server" /></div>
                                <div style="text-align: right"><asp:Literal ID="litColTotal" runat="server" /></div>
                                <div style="text-align: right"><asp:Literal ID="litColDejaRecu" runat="server" /></div>
                                <div style="text-align: right"><asp:Literal ID="litColReste" runat="server" /></div>
                                <div style="text-align: right"><asp:Literal ID="litColAImputer" runat="server" /></div>
                                <div style="text-align: center"></div>
                            </div>

                            <div class="items-wrap" style="display: block; padding: 0;">
                                <asp:Repeater ID="rpInvoices" runat="server">
                                    <ItemTemplate>
                                        <div class="item-row" data-reste='<%# Eval("Reste") %>'>
                                            <div class="invoice-gridrow">
                                                <asp:HiddenField ID="hidDocumentId" runat="server" Value='<%# Eval("DocumentId") %>' />

                                                <div class="cell">
                                                    <strong><%# Eval("DocumentNumber") %></strong>
                                                </div>

                                                <div class="cell" style="text-align: center">
                                                    <%# Eval("IssueDate", "{0:yyyy-MM-dd} ") %>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <%# Eval("Total", "{0:N2}") %>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <%# Eval("DejaRecu", "{0:N2}") %>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <strong class="lbl-reste"><%# Eval("Reste", "{0:N2}") %></strong>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numAImputer" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("AImputer")) %>'
                                                            CssClass="num-right num-imputer"
                                                            oninput="fixNumber(this)" onblur="formatPrice(this); recalcDiff();" onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell invoice-checkbox">
                                                    <telerik:RadImageButton ID="btnFillRest"
                                                        runat="server"
                                                        Text=""
                                                        CssClass="imgaction btn-fillrest"
                                                        Width="25px"
                                                        Height="25px"
                                                        Image-Url="~/Images/rondplus45.png" Image-Sizing="Stretch"
                                                        ToolTip="Imputer le reste complet"
                                                        AutoPostBack="false">
                                                    </telerik:RadImageButton>
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

            <%-- FOOTER TOTAUX --%>
            <div class="footerbar">
                <div class="totals">
                    <div class="tot"><asp:Literal ID="litTotalDuLabel" runat="server" /></div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblTotalDu" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot"><asp:Literal ID="litTotalImputeLabel" runat="server" /></div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblTotalImpute" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot"><asp:Literal ID="litLabelDiff" runat="server" Text="Différence (reçu − imputé)" /></div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblDiff" runat="server" Text="0.00" CssClass="diff-ok" /></strong>
                    </div>
                </div>
            </div>

            <telerik:RadButton ID="radSave" runat="server" OnClientClicked="onSaveClicked" BackColor="lightgrey" Text="Enregistrer l'encaissement" />

            <%-- OVERLAY PICKER CLIENTS --%>
            <asp:HiddenField ID="hidSelectedCustomerId" runat="server" />
            <div id="customerPickerOverlay" class="customer-picker-overlay" style="display: none;">
                <div class="customer-picker-shell">
                    <div class="customer-picker-searchbar">
                        <input type="text" id="customerPickerSearch" oninput="filterCustomersClient()" class="customer-picker-input" />
                        <button type="button" class="customer-picker-close-inline" onclick="closeCustomerPicker()">✕</button>
                    </div>

                    <div id="customerPickerList" class="customer-picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvCustomers" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemcustomerPlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemcustomerPlaceholder" runat="server"></asp:PlaceHolder>
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="customer-card" data-search='<%# Eval("search").ToString().ToLower() %>' onclick="selectCustomer('<%# Eval("Id") %>')">
                                        <div class="Contact-name"><%# Eval("ContactName") %></div>
                                        <div class="BillingTo"><%# Eval("BillingTo") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty"><asp:Literal ID="litEmptyCustomers" runat="server" /></div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

            <%-- OVERLAY PICKER COMPTES BANQUE --%>
            <asp:HiddenField ID="hidSelectedBankId" runat="server" />
            <div id="bankPickerOverlay" class="bank-picker-overlay" style="display: none;">
                <div class="bank-picker-shell">
                    <div class="bank-picker-searchbar">
                        <input type="text" id="bankPickerSearch" oninput="filterBanksClient()" class="bank-picker-input" />
                        <button type="button" class="bank-picker-close-inline" onclick="closeBankPicker()">✕</button>
                    </div>

                    <div id="bankPickerList" class="bank-picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvBanks" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itembankPlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itembankPlaceholder" runat="server"></asp:PlaceHolder>
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="bank-card" data-search='<%# Eval("search").ToString().ToLower() %>' onclick="selectBank('<%# Eval("NoCompte") %>')">
                                        <div class="bank-code"><%# Eval("NoCompte") %></div>
                                        <div class="bank-name"><%# Eval("Name") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty"><asp:Literal ID="litEmptyBanks" runat="server" /></div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

        </asp:Panel>

    </telerik:RadAjaxPanel>

    <telerik:RadCodeBlock ID="rcbReceipt" runat="server">
        <script type="text/javascript">

            var IS_READONLY = <%= chkPost.Checked.ToString().ToLower() %>;

            // Chaînes localisées (fr/en/es)
            var L_AMOUNT_FIRST = "<%= L("alertAmountFirst") %>";
            var L_SEARCH_TIERS = "<%= If(IsEncaissement(), L("searchClient"), L("searchSupplier")) %>";
            var L_SEARCH_BANK = "<%= L("searchBank") %>";
            var L_EMPTY_TIERS = "<%= L("emptyTiers") %>";
            var L_EMPTY_BANK = "<%= L("emptyBank") %>";
            var L_CLOSE = "<%= L("close") %>";

            function localizeReceiptPickers() {
                var c = document.getElementById("customerPickerSearch"); if (c) c.placeholder = L_SEARCH_TIERS;
                var b = document.getElementById("bankPickerSearch"); if (b) b.placeholder = L_SEARCH_BANK;
                document.querySelectorAll(".customer-picker-close-inline,.bank-picker-close-inline")
                    .forEach(function (x) { x.setAttribute("aria-label", L_CLOSE); });
            }
            document.addEventListener("DOMContentLoaded", localizeReceiptPickers);
            if (window.Sys && Sys.Application) { Sys.Application.add_load(localizeReceiptPickers); }

            function onSaveClicked(sender, args) {
                if (window.parent && window.parent.setInvoiceClean) {
                    window.parent.setInvoiceClean();
                }
            }

            /* Récupère la référence à la RadWindow parente (mode popup) */
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            /* Ferme la fenêtre courante */
            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
            }

            function trimZeros(s) {
                s = (s || "").toString().trim();
                if (s === "") return "";
                if (s.endsWith(".")) s = s.slice(0, -1);
                if (s.indexOf(".") >= 0) {
                    s = s.replace(/0+$/, "");
                    s = s.replace(/\.$/, "");
                }
                return s;
            }

            function formatPrice(el) {
                fixNumber(el);
                let v = el.value;
                if (v === "") { el.value = "0.00"; return; }
                let n = parseFloat(v);
                if (isNaN(n)) { el.value = "0.00"; return; }
                el.value = n.toFixed(2);
            }

            function fixNumber(el) {
                let v = (el.value || "").replace(/,/g, ".");
                v = v.replace(/[^0-9.]/g, "");
                const firstDot = v.indexOf(".");
                if (firstDot !== -1) {
                    let left = v.substring(0, firstDot);
                    let right = v.substring(firstDot + 1).replace(/\./g, "");
                    right = right.substring(0, 2);
                    v = left + "." + right;
                }
                el.value = v;
            }

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

            /* Recalcul des totaux + différence */
            function recalcDiff() {
                var totalImpute = 0;
                var totalDu = 0;

                document.querySelectorAll(".item-row").forEach(function (row) {
                    var reste = toNum(row.getAttribute("data-reste"));
                    var inp = row.querySelector(".num-imputer");
                    var val = inp ? toNum(inp.value) : 0;

                    totalImpute += val;
                    if (val > 0) totalDu += reste;
                });

                var recu = toNum(document.getElementById("<%= txtMontantRecu.ClientID %>").value);
                var diff = Math.round((recu - totalImpute) * 100) / 100;

                var elDu = document.getElementById("<%= lblTotalDu.ClientID %>");
                var elImp = document.getElementById("<%= lblTotalImpute.ClientID %>");
                var elDiff = document.getElementById("<%= lblDiff.ClientID %>");

                if (elDu) elDu.innerText = fmt2(totalDu);
                if (elImp) elImp.innerText = fmt2(totalImpute);
                if (elDiff) {
                    elDiff.innerText = fmt2(diff);
                    elDiff.className = (Math.abs(diff) < 0.01) ? "diff-ok" : "diff-ko";
                }
            }

            /* Remplit automatiquement le reste à recevoir pour une ligne */
            function fillRest(btn) {
                var row = btn.closest(".item-row");
                if (!row) return;
                var reste = toNum(row.getAttribute("data-reste"));
                var inp = row.querySelector(".num-imputer");
                if (inp) {
                    inp.value = reste.toFixed(2);
                    recalcDiff();
                }
            }

            /* Imputation automatique : répartit le montant reçu sur les factures de la plus ancienne à la plus récente */
            function onAutoImputeClicked(sender, args) {
                var recu = toNum(document.getElementById("<%= txtMontantRecu.ClientID %>").value);
                if (recu <= 0) {
                    alert(L_AMOUNT_FIRST);
                    return;
                }

                var reste = recu;
                document.querySelectorAll(".item-row").forEach(function (row) {
                    var dispo = toNum(row.getAttribute("data-reste"));
                    var inp = row.querySelector(".num-imputer");
                    if (!inp) return;

                    if (reste <= 0) {
                        inp.value = "0.00";
                        return;
                    }

                    var imp = Math.min(reste, dispo);
                    imp = Math.round(imp * 100) / 100;
                    inp.value = imp.toFixed(2);
                    reste = Math.round((reste - imp) * 100) / 100;
                });

                recalcDiff();
            }

            function wireInvoiceInputs() {
                document.querySelectorAll(".item-row input.num-imputer")
                    .forEach(function (inp) {
                        if (inp.dataset.wired === "1") return;
                        inp.dataset.wired = "1";

                        inp.addEventListener("input", function () { recalcDiff(); });
                        inp.addEventListener("keyup", function () { recalcDiff(); });
                    });

                /* Boutons "+" pour remplir le reste */
                document.querySelectorAll(".btn-fillrest").forEach(function (btn) {
                    if (btn.dataset.wired === "1") return;
                    btn.dataset.wired = "1";
                    btn.addEventListener("click", function (e) {
                        e.preventDefault();
                        fillRest(btn);
                    });
                });

                recalcDiff();
            }

            document.addEventListener("DOMContentLoaded", function () {
                wireInvoiceInputs();
            });

            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(function () {
                    wireInvoiceInputs();
                });
            }

            function normalizeText(str) {
                return (str || "")
                    .toLowerCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "");
            }

            /* ============== PICKER CLIENTS ============== */
            var currentCustomerLabel = null;

            function closeCustomerPicker() {
                var overlay = document.getElementById("customerPickerOverlay");
                if (overlay) overlay.style.display = "none";
            }

            function openCustomerPicker(label) {
                if (IS_READONLY) return;
                currentCustomerLabel = label;
                var overlay = document.getElementById("customerPickerOverlay");
                if (overlay) overlay.style.display = "block";
            }

            function selectCustomer(customerId) {
                document.getElementById("<%= hidSelectedCustomerId.ClientID %>").value = customerId;
                closeCustomerPicker();
                var ajaxManager = $find("<%= rapReceipt.ClientID %>");
                ajaxManager.ajaxRequest('CUSTOMER|' + customerId.toString());
            }

            function filterCustomersClient() {
                var tb = document.getElementById("customerPickerSearch");
                var q = (tb ? tb.value : "").toLowerCase().trim();
                var cards = document.querySelectorAll("#customerPickerList .customer-card");
                var visibleCount = 0;
                cards.forEach(function (card) {
                    var text = normalizeText(card.getAttribute("data-search"));
                    var show = q === "" || text.indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                    if (show) visibleCount++;
                });
                toggleEmptyMsg("customerPickerEmptyJs", "customerPickerList", L_EMPTY_TIERS, visibleCount === 0);
            }

            /* ============== PICKER BANQUES ============== */
            var currentBankLabel = null;

            function closeBankPicker() {
                var overlay = document.getElementById("bankPickerOverlay");
                if (overlay) overlay.style.display = "none";
            }

            function openBankPicker(label) {
                if (IS_READONLY) return;
                currentBankLabel = label;
                var overlay = document.getElementById("bankPickerOverlay");
                if (overlay) overlay.style.display = "block";
            }

            function selectBank(noCompte) {
                document.getElementById("<%= hidSelectedBankId.ClientID %>").value = noCompte;
                closeBankPicker();
                var ajaxManager = $find("<%= rapReceipt.ClientID %>");
                ajaxManager.ajaxRequest('BANK|' + noCompte.toString());
            }

            function filterBanksClient() {
                var tb = document.getElementById("bankPickerSearch");
                var q = (tb ? tb.value : "").toLowerCase().trim();
                var cards = document.querySelectorAll("#bankPickerList .bank-card");
                var visibleCount = 0;
                cards.forEach(function (card) {
                    var text = normalizeText(card.getAttribute("data-search"));
                    var show = q === "" || text.indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                    if (show) visibleCount++;
                });
                toggleEmptyMsg("bankPickerEmptyJs", "bankPickerList", L_EMPTY_BANK, visibleCount === 0);
            }

            /* ============== HELPER message vide ============== */
            function toggleEmptyMsg(msgId, listId, text, show) {
                var list = document.getElementById(listId);
                if (!list) return;
                var empty = document.getElementById(msgId);
                if (!empty) {
                    empty = document.createElement("div");
                    empty.id = msgId;
                    empty.className = "empty";
                    empty.innerText = text;
                    empty.style.display = "none";
                    list.appendChild(empty);
                }
                empty.style.display = show ? "block" : "none";
            }

        </script>
    </telerik:RadCodeBlock>
