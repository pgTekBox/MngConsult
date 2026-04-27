<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfJournalEntryEdit.aspx.vb" Inherits="MngConsul.wbfJournalEntryEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Écriture comptable — Édition</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .badge-validee {
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

        .badge-extournee {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 999px;
            background: #fee2e2;
            color: #dc2626;
            font-size: 12px;
            font-weight: 700;
            border: 1px solid #fecaca;
        }

        .badge-balanced {
            background: #ecfdf5;
            color: #059669;
            border: 1px solid #a7f3d0;
            display: inline-flex;
            padding: 6px 12px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
        }

        .badge-unbalanced {
            background: #fee2e2;
            color: #dc2626;
            border: 1px solid #fecaca;
            display: inline-flex;
            padding: 6px 12px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
        }

        .readonly { opacity: 0.85; }
        .readonly-blocked { pointer-events: none; }
        .readonly input,
        .readonly textarea { background-color: #f1f5f9 !important; }

        .footerbar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid var(--line);
            padding: 8px 14px;
        }

        .account-selector {
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

        .account-selector::after {
            content: "▾";
            float: right;
            color: #64748b;
        }

        .account-selector:active { background: #f1f5f9; }

        .account-picker-overlay,
        .template-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .account-picker-shell,
        .template-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .account-picker-searchbar,
        .template-picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px;
            border-bottom: 1px solid var(--line);
            background: #fff;
        }

        .account-picker-close-inline,
        .template-picker-close-inline {
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

        .account-picker-input,
        .template-picker-input {
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

        .account-picker-list,
        .template-picker-list {
            flex: 1 1 auto;
            min-height: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .rw-page { height: 100%; display: flex; flex-direction: column; }

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

        .card-body { padding: 14px; }

        .row2 { display: grid; gap: 12px; grid-template-columns: 1fr 1fr; }
        .row4 { display: grid; gap: 12px; grid-template-columns: 200px 200px 220px 1fr; }

        .qty-right input { text-align: right !important; }

        .RadInput, .RadPicker, .RadComboBox, .RadNumericTextBox { width: 100% !important; }

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

        .account-card,
        .template-card {
            align-items: center;
            gap: 10px;
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }

        .account-code,
        .template-code {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 6px;
        }

        .account-name,
        .template-name {
            font-size: 15px;
            font-weight: 600;
        }

        .empty {
            padding: 24px;
            color: var(--muted);
            text-align: center;
        }

        /* GRILLE LIGNES */
        .lines-header {
            display: grid;
            grid-template-columns: 250px 1fr 110px 110px 90px;
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            overflow: hidden;
            margin-bottom: 8px;
            padding: 10px;
            font-size: 12px;
            font-weight: 900;
            color: var(--muted);
            background: #f8fafc;
        }

        .line-gridrow {
            display: grid;
            grid-template-columns: 250px 1fr 110px 110px 90px;
            align-items: center;
            gap: 6px;
            padding: 4px 0;
        }

        .line-gridrow:hover { background: #f8fafc; }

        /* FOOTER TOTAUX */
        .totals {
            display: grid;
            grid-template-columns: auto auto;
            justify-content: end;
            column-gap: 30px;
        }

        .diff-ok { color: #059669; font-weight: 900; }
        .diff-ko { color: #dc2626; font-weight: 900; }

        .fab-addline {
            position: fixed;
            right: 190px;
            bottom: 22px;
            z-index: 2000;
        }

        .fab-addline img {
            width: 56px;
            height: 56px;
            display: block;
        }

        .header-actions {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 10px;
            gap: 8px;
        }

      
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" EnablePartialRendering="true" AsyncPostBackTimeout="300" />

        <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

        <telerik:RadAjaxManager ID="Ram1" runat="server">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="Ram1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpLines" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                        <telerik:AjaxUpdatedControl ControlID="lblBalance" />
                        <telerik:AjaxUpdatedControl ControlID="lblBalanceBadge" />
                        <telerik:AjaxUpdatedControl ControlID="cbJournal" />
                        <telerik:AjaxUpdatedControl ControlID="txtLibelle" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <telerik:AjaxSetting AjaxControlID="btnAddLine">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpLines" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                        <telerik:AjaxUpdatedControl ControlID="lblBalance" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <telerik:AjaxSetting AjaxControlID="rpLines">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpLines" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                        <telerik:AjaxUpdatedControl ControlID="lblBalance" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <div class="content">
                <div class="container">

                    <%-- BADGE DE STATUT --%>
                    <asp:Panel ID="pnlStatutBadges" runat="server">
                        <asp:Label ID="lblValideeBadge" runat="server" CssClass="badge-validee" Visible="false" Text="Validée 🔒"></asp:Label>
                        <asp:Label ID="lblExtourneeBadge" runat="server" CssClass="badge-extournee" Visible="false" Text="Extournée"></asp:Label>
                    </asp:Panel>

                    <%-- ACTIONS HEADER : CHARGER UN TEMPLATE --%>
                    <div class="header-actions">
                        <telerik:RadButton ID="btnLoadTemplate" runat="server"
                            Text="📋 Charger un template"
                            AutoPostBack="false"
                            OnClientClicked="openTemplatePicker">
                        </telerik:RadButton>
                    </div>

                    <%-- EN-TÊTE ÉCRITURE --%>
                    <div class="card">
                        <div class="card-body">

                            <div class="row4">
                                <div>
                                    <label>Journal</label>
                                    <telerik:RadComboBox ID="cbJournal" runat="server"
                                        DataTextField="DisplayName" DataValueField="Id"
                                        EmptyMessage="Sélectionner..." />
                                </div>

                                <div>
                                    <label>Période</label>
                                    <telerik:RadComboBox ID="cbPeriode" runat="server"
                                        DataTextField="Libelle" DataValueField="Id"
                                        EmptyMessage="Sélectionner..." />
                                </div>

                                <div>
                                    <label>Date écriture</label>
                                    <telerik:RadDatePicker ID="dpDateEcriture" runat="server" />
                                </div>

                                <div style="display: flex; align-items: end; padding-bottom: 8px;">
                                    <label style="margin: 0;">
                                        <asp:CheckBox ID="chkValider" runat="server" />
                                        Valider l'écriture
                                    </label>
                                </div>
                            </div>

                            <div style="height: 12px"></div>

                            <div class="row2">
                                <div>
                                    <label>No pièce</label>
                                    <telerik:RadTextBox ID="txtNumeroPiece" runat="server"
                                        EmptyMessage="(auto si laissé vide)" />
                                </div>
                                <div>
                                    <label>Libellé de l'écriture</label>
                                    <telerik:RadTextBox ID="txtLibelle" runat="server"
                                        EmptyMessage="Description / mémo..." Width="100%" />
                                </div>
                            </div>

                        </div>
                    </div>

                    <%-- LIGNES D'ÉCRITURE --%>
                    <div class="card">
                        <div class="card-header">
                            <strong>Lignes d'écriture</strong>
                            <asp:Label ID="lblBalanceBadge" runat="server" CssClass="badge-balanced" Text="Équilibré ✓" />
                        </div>

                        <div class="card-body">
                            <div class="lines-header">
                                <div>Compte</div>
                                <div>Libellé ligne</div>
                                <div style="text-align: right">Débit</div>
                                <div style="text-align: right">Crédit</div>
                                <div style="text-align: center"></div>
                            </div>

                            <div class="items-wrap" style="display: block; padding: 0;">
                                <asp:Repeater ID="rpLines" runat="server">
                                    <ItemTemplate>
                                        <div class="item-row">
                                            <div class="line-gridrow">
                                                <asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' />

                                                <div class="cell">
                                                    <asp:Label ID="lblAccount" runat="server"
                                                        CssClass="account-selector js-account-selector"
                                                        Text='<%# Eval("AccountDisplay") %>'>
                                                    </asp:Label>
                                                    <asp:HiddenField ID="hidPlanComptableId" runat="server" Value='<%# Eval("PlanComptableId") %>' />
                                                </div>

                                                <div class="cell">
                                                    <telerik:RadTextBox ID="txtLineLibelle" runat="server"
                                                        Text='<%# Eval("Libelle") %>'
                                                        EmptyMessage="Description ligne..." />
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numMontantDebit" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("MontantDebit")) %>'
                                                            CssClass="num-right num-mt-debit"
                                                            oninput="fixNumber(this); zeroOtherSide(this,'credit')"
                                                            onblur="formatPrice(this); recalcBalance();"
                                                            onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numMontantCredit" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("MontantCredit")) %>'
                                                            CssClass="num-right num-mt-credit"
                                                            oninput="fixNumber(this); zeroOtherSide(this,'debit')"
                                                            onblur="formatPrice(this); recalcBalance();"
                                                            onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell actions" style="text-align: center">
                                                    <telerik:RadImageButton ID="btnDeleteLine"
                                                        runat="server"
                                                        Text=""
                                                        CssClass="imgaction"
                                                        Width="25px"
                                                        Height="35px"
                                                        Image-Url="~/Images/del200.png" Image-Sizing="Stretch"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClicking="function(s,e){ if(!confirm('Supprimer cette ligne ?')) e.set_cancel(true); }">
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

            <%-- FOOTER TOTAUX D/C/ÉCART --%>
            <div class="footerbar">
                <div class="totals">
                    <div class="tot">Total Débit</div>
                    <div class="tot" style="justify-self: end;">
                        <strong><asp:Label ID="lblTotalDebit" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">Total Crédit</div>
                    <div class="tot" style="justify-self: end;">
                        <strong><asp:Label ID="lblTotalCredit" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">Écart (D − C)</div>
                    <div class="tot" style="justify-self: end;">
                        <strong><asp:Label ID="lblBalance" runat="server" Text="0.00" CssClass="diff-ok" /></strong>
                    </div>
                </div>
            </div>

            <%-- BOUTON FAB AJOUTER LIGNE --%>
            <div style="z-index:25000" class="fab-addline">
                <telerik:RadImageButton ID="btnAddLine" runat="server"
                    Image-Url="~/Images/rondplus45.png"
                    Width="56px" Height="56px"
                    ToolTip="Ajouter une ligne">
                </telerik:RadImageButton>
            </div>

            <telerik:RadButton ID="radSave" runat="server"
                BackColor="lightgrey" Text="Enregistrer l'écriture" />

            <%-- OVERLAY PICKER COMPTES --%>
            <asp:HiddenField ID="hidSelectedAccountId" runat="server" />
            <div id="accountPickerOverlay" class="account-picker-overlay" style="display: none;">
                <div class="account-picker-shell">
                    <div class="account-picker-searchbar">
                        <input type="text" id="accountPickerSearch" oninput="filterAccountsClient()"
                            class="account-picker-input" placeholder="Rechercher un compte..." />
                        <button type="button" class="account-picker-close-inline"
                            onclick="closeAccountPicker()" aria-label="Fermer">✕</button>
                    </div>

                    <div id="accountPickerList" class="account-picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvAccounts" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemaccountPlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemaccountPlaceholder" runat="server"></asp:PlaceHolder>
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="account-card" data-search='<%# Eval("search").ToString().ToLower() %>'
                                        onclick="selectAccount('<%# Eval("Id") %>')">
                                        <div class="account-code"><%# Eval("NoCompte") %></div>
                                        <div class="account-name"><%# Eval("Name") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty">Aucun compte trouvé.</div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

            <%-- OVERLAY PICKER TEMPLATES --%>
            <asp:HiddenField ID="hidSelectedTemplateId" runat="server" />
            <div id="templatePickerOverlay" class="template-picker-overlay" style="display: none;">
                <div class="template-picker-shell">
                    <div class="template-picker-searchbar">
                        <input type="text" id="templatePickerSearch" oninput="filterTemplatesClient()"
                            class="template-picker-input" placeholder="Rechercher un template..." />
                        <button type="button" class="template-picker-close-inline"
                            onclick="closeTemplatePicker()" aria-label="Fermer">✕</button>
                    </div>

                    <div id="templatePickerList" class="template-picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvTemplates" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemtemplatePlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemtemplatePlaceholder" runat="server"></asp:PlaceHolder>
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="template-card"
                                        data-search='<%# Eval("search").ToString().ToLower() %>'
                                        onclick="selectTemplate('<%# Eval("Id") %>')">
                                        <div class="template-code">
                                            <%# Eval("Code") %> · <%# Eval("JournalCode") %>
                                            <%# IIf(CBool(Eval("MontantsPreRemplis")), " · 💰 pré-rempli", "") %>
                                        </div>
                                        <div class="template-name"><%# Eval("Libelle") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty">
                                        Aucun template défini.
                                    </div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

        </asp:Panel>

        <script type="text/javascript">

            var IS_READONLY = <%= IsReadOnly().ToString().ToLower() %>;

            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
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

            function formatPrice(el) {
                fixNumber(el);
                let v = el.value;
                if (v === "") return;
                let n = parseFloat(v);
                if (isNaN(n)) { el.value = ""; return; }
                el.value = n.toFixed(2);
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

            /* Quand on saisit un montant côté Débit, on remet Crédit à 0 (et inversement).
               Respecte la contrainte chk_T136_UnSeulCote : une ligne a Débit OU Crédit, pas les deux. */
            function zeroOtherSide(el, otherSide) {
                var row = el.closest(".item-row");
                if (!row) return;
                var v = toNum(el.value);
                if (v <= 0) return;
                var other = row.querySelector(otherSide === "credit" ? ".num-mt-credit" : ".num-mt-debit");
                if (other && toNum(other.value) > 0) {
                    other.value = "";
                }
            }

            /* Recalcul des totaux Débit/Crédit + équilibre */
            function recalcBalance() {
                var totDebit = 0;
                var totCredit = 0;

                document.querySelectorAll(".item-row").forEach(function (row) {
                    var d = row.querySelector(".num-mt-debit");
                    var c = row.querySelector(".num-mt-credit");
                    if (d) totDebit += toNum(d.value);
                    if (c) totCredit += toNum(c.value);
                });

                totDebit = Math.round(totDebit * 100) / 100;
                totCredit = Math.round(totCredit * 100) / 100;
                var ecart = Math.round((totDebit - totCredit) * 100) / 100;

                var elD = document.getElementById("<%= lblTotalDebit.ClientID %>");
                var elC = document.getElementById("<%= lblTotalCredit.ClientID %>");
                var elE = document.getElementById("<%= lblBalance.ClientID %>");
                var elBadge = document.getElementById("<%= lblBalanceBadge.ClientID %>");

                if (elD) elD.innerText = fmt2(totDebit);
                if (elC) elC.innerText = fmt2(totCredit);
                if (elE) {
                    elE.innerText = fmt2(ecart);
                    elE.className = (Math.abs(ecart) < 0.005) ? "diff-ok" : "diff-ko";
                }
                if (elBadge) {
                    if (Math.abs(ecart) < 0.005 && totDebit > 0) {
                        elBadge.innerText = "Équilibré ✓";
                        elBadge.className = "badge-balanced";
                    } else if (totDebit === 0 && totCredit === 0) {
                        elBadge.innerText = "Vide";
                        elBadge.className = "badge-balanced";
                    } else {
                        elBadge.innerText = "Déséquilibré ✗";
                        elBadge.className = "badge-unbalanced";
                    }
                }
            }

            function wireLineInputs() {
                document.querySelectorAll(".item-row input.num-mt-debit, .item-row input.num-mt-credit")
                    .forEach(function (inp) {
                        if (inp.dataset.wired === "1") return;
                        inp.dataset.wired = "1";

                        inp.addEventListener("input", function () { recalcBalance(); });
                        inp.addEventListener("keyup", function () { recalcBalance(); });
                    });

                recalcBalance();
            }

            function wireAccountSelectors() {
                document.querySelectorAll(".js-account-selector").forEach(function (el) {
                    if (el.dataset.wired === "1") return;
                    el.dataset.wired = "1";

                    el.addEventListener("click", function () {
                        if (IS_READONLY) return;
                        var row = el.closest(".item-row");
                        if (!row) return;
                        var hidId = row.querySelector("input[id*='hidId']");
                        var lineId = hidId ? hidId.value : "0";
                        openAccountPicker(el, lineId);
                    });
                });
            }

            document.addEventListener("DOMContentLoaded", function () {
                wireLineInputs();
                wireAccountSelectors();
            });

            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(function () {
                    wireLineInputs();
                    wireAccountSelectors();
                });
            }

            function normalizeText(str) {
                return (str || "")
                    .toLowerCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "");
            }

            /* ========== PICKER COMPTES ========== */
            var currentAccountLabel = null;
            var currentLineId = null;

            function closeAccountPicker() {
                var overlay = document.getElementById("accountPickerOverlay");
                if (overlay) overlay.style.display = "none";
            }

            function openAccountPicker(label, lineId) {
                if (IS_READONLY) return;
                currentAccountLabel = label;
                currentLineId = lineId;
                var overlay = document.getElementById("accountPickerOverlay");
                if (overlay) overlay.style.display = "block";
            }

            function selectAccount(accountId) {
                document.getElementById("<%= hidSelectedAccountId.ClientID %>").value = accountId;
                if (!currentAccountLabel) return;
                closeAccountPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('ACCOUNT|' + currentLineId.toString() + '|' + accountId.toString());
            }

            function filterAccountsClient() {
                var tb = document.getElementById("accountPickerSearch");
                var q = (tb ? tb.value : "").toLowerCase().trim();
                var cards = document.querySelectorAll("#accountPickerList .account-card");
                cards.forEach(function (card) {
                    var text = normalizeText(card.getAttribute("data-search"));
                    var show = q === "" || text.indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                });
            }

            /* ========== PICKER TEMPLATES ========== */

            function openTemplatePicker(sender, args) {
                if (IS_READONLY) return;
                var overlay = document.getElementById("templatePickerOverlay");
                if (overlay) overlay.style.display = "block";
            }

            function closeTemplatePicker() {
                var overlay = document.getElementById("templatePickerOverlay");
                if (overlay) overlay.style.display = "none";
            }

            function selectTemplate(templateId) {
                document.getElementById("<%= hidSelectedTemplateId.ClientID %>").value = templateId;

                /* Si des montants sont déjà saisis, demander confirmation */
                var hasContent = false;
                document.querySelectorAll(".item-row input.num-mt-debit, .item-row input.num-mt-credit")
                    .forEach(function (inp) {
                        if (toNum(inp.value) > 0) hasContent = true;
                    });

                if (hasContent) {
                    if (!confirm("Charger ce template écrasera les lignes actuelles. Continuer ?")) return;
                }

                closeTemplatePicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('TEMPLATE|' + templateId.toString());
            }

            function filterTemplatesClient() {
                var tb = document.getElementById("templatePickerSearch");
                var q = (tb ? tb.value : "").toLowerCase().trim();
                var cards = document.querySelectorAll("#templatePickerList .template-card");
                cards.forEach(function (card) {
                    var text = normalizeText(card.getAttribute("data-search"));
                    var show = q === "" || text.indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                });
            }

        </script>
    </form>
</body>
</html>
