<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfTemplateEdit.aspx.vb" Inherits="MngConsul.wbfTemplateEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= CurrentLang %>">
<head runat="server">
    <title><%= L("pageTitle") %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
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

        .account-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .account-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .account-picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px;
            border-bottom: 1px solid var(--line);
        }

        .account-picker-close-inline {
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
        }

        .account-picker-input {
            width: 100%;
            max-width: 260px;
            min-width: 0;
            height: 44px;
            padding: 0 12px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            font-size: 16px;
        }

        .account-picker-list {
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
        .row4 { display: grid; gap: 12px; grid-template-columns: 200px 220px auto auto; }

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
            overflow: hidden;
        }

        .items-wrap {
            flex: 1 1 auto;
            min-height: 0;
            overflow-y: auto;
            padding: 14px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 14px;
        }

        .account-card {
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }

        .account-code { color: var(--muted); font-size: 13px; margin-bottom: 6px; }
        .account-name { font-size: 15px; font-weight: 600; }

        .empty { padding: 24px; color: var(--muted); text-align: center; }

        /* GRILLE LIGNES TEMPLATE */
        .lines-header {
            display: grid;
            grid-template-columns: 250px 1fr 110px 130px 50px;
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
            grid-template-columns: 250px 1fr 110px 130px 50px;
            align-items: center;
            gap: 6px;
            padding: 4px 0;
        }

        .line-gridrow:hover { background: #f8fafc; }

        .info-banner {
            padding: 10px 14px;
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 10px;
            color: #1e40af;
            font-size: 13px;
        }

        .fab-addline {
            position: fixed;
            right: 190px;
            bottom: 22px;
            z-index: 2000;
        }

        .fab-addline img { width: 56px; height: 56px; display: block; }

        
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
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="btnAddLine">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpLines" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="rpLines">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpLines" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="chkPreRempli">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="pnlMontantInfo" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <div class="content">
                <div class="container">

                    <%-- EN-TÊTE TEMPLATE --%>
                    <div class="card">
                        <div class="card-body">

                            <div class="row4">
                                <div>
                                    <label><asp:Literal ID="litLblCode" runat="server" /></label>
                                    <telerik:RadTextBox ID="txtCode" runat="server" EmptyMessage="ex: AMORT-MENS" MaxLength="50" />
                                </div>

                                <div>
                                    <label><asp:Literal ID="litLblJournal" runat="server" /></label>
                                    <telerik:RadComboBox ID="cbJournal" runat="server"
                                        DataTextField="DisplayName" DataValueField="Id"
                                        EmptyMessage="Sélectionner..." />
                                </div>

                                <div style="display: flex; align-items: end; padding-bottom: 8px;">
                                    <label style="margin: 0;">
                                        <asp:CheckBox ID="chkPreRempli" runat="server" AutoPostBack="true" />
                                        <asp:Literal ID="litPreRempli" runat="server" />
                                    </label>
                                </div>

                                <div style="display: flex; align-items: end; padding-bottom: 8px;">
                                    <label style="margin: 0;">
                                        <asp:CheckBox ID="chkActif" runat="server" Checked="true" />
                                        <asp:Literal ID="litActif" runat="server" />
                                    </label>
                                </div>
                            </div>

                            <div style="height: 12px"></div>

                            <div class="row2">
                                <div>
                                    <label><asp:Literal ID="litLblLibelle" runat="server" /></label>
                                    <telerik:RadTextBox ID="txtLibelle" runat="server"
                                        EmptyMessage="ex: Amortissement mensuel équipement" Width="100%" MaxLength="250" />
                                </div>
                                <div>
                                    <label><asp:Literal ID="litLblDescription" runat="server" /></label>
                                    <telerik:RadTextBox ID="txtDescription" runat="server"
                                        EmptyMessage="Description appliquée à l'écriture..." Width="100%" MaxLength="500" />
                                </div>
                            </div>

                        </div>
                    </div>

                    <%-- BANNIÈRE INFO MODE --%>
                    <asp:Panel ID="pnlMontantInfo" runat="server" CssClass="info-banner">
                        <asp:Label ID="lblModeInfo" runat="server" />
                    </asp:Panel>

                    <%-- LIGNES TEMPLATE --%>
                    <div class="card">
                        <div class="card-header">
                            <strong><asp:Literal ID="litStructTitle" runat="server" /></strong>
                        </div>

                        <div class="card-body">
                            <div class="lines-header">
                                <div><asp:Literal ID="litColCompte" runat="server" /></div>
                                <div><asp:Literal ID="litColLibelle" runat="server" /></div>
                                <div style="text-align: center"><asp:Literal ID="litColSens" runat="server" /></div>
                                <div style="text-align: right"><asp:Literal ID="litColMontant" runat="server" /></div>
                                <div></div>
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
                                                        EmptyMessage="Description ligne..." MaxLength="250" />
                                                </div>

                                                <div class="cell">
                                                    <telerik:RadComboBox ID="cbSens" runat="server" Width="95px">
                                                        <Items>
                                                            <telerik:RadComboBoxItem Text="Débit" Value="DEBIT" />
                                                            <telerik:RadComboBoxItem Text="Crédit" Value="CREDIT" />
                                                        </Items>
                                                    </telerik:RadComboBox>
                                                </div>


                                                <div class="cell" style="text-align: right">
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numMontant" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("Montant")) %>'
                                                            CssClass="num-right num-montant"
                                                            oninput="fixNumber(this)"
                                                            onblur="formatPrice(this)"
                                                            onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell actions" style="text-align: center">
                                                    <telerik:RadImageButton ID="btnDeleteLine"
                                                        runat="server"
                                                        CssClass="imgaction"
                                                        Width="25px"
                                                        Height="35px"
                                                        Image-Url="~/Images/del200.png" Image-Sizing="Stretch"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClicking="function(s,e){ if(!confirm(LOC.delLine)) e.set_cancel(true); }">
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

            <div class="fab-addline">
                <telerik:RadImageButton ID="btnAddLine" runat="server"
                    Image-Url="~/Images/rondplus45.png"
                    Width="56px" Height="56px"
                    ToolTip="Ajouter une ligne">
                </telerik:RadImageButton>
            </div>

            <telerik:RadButton ID="radSave" runat="server"
                BackColor="lightgrey" Text="Enregistrer le template" />

            <telerik:RadCodeBlock ID="rcbLoc" runat="server">
                <script type="text/javascript">
                    var LOC = { delLine: "<%= L("confirmDelLine") %>" };
                </script>
            </telerik:RadCodeBlock>

            <%-- OVERLAY PICKER COMPTES --%>
            <asp:HiddenField ID="hidSelectedAccountId" runat="server" />
            <div id="accountPickerOverlay" class="account-picker-overlay" style="display: none;">
                <div class="account-picker-shell">
                    <div class="account-picker-searchbar">
                        <input type="text" id="accountPickerSearch" runat="server" ClientIDMode="Static"
                            oninput="filterAccountsClient()"
                            class="account-picker-input" placeholder="Rechercher un compte..." />
                        <button type="button" class="account-picker-close-inline" onclick="closeAccountPicker()">✕</button>
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
                                    <div class="empty"><asp:Literal ID="litAccEmpty" runat="server" /></div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

        </asp:Panel>

        <script type="text/javascript">

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

            function normalizeText(str) {
                return (str || "")
                    .toLowerCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "");
            }

            /* PICKER COMPTES */
            var currentAccountLabel = null;
            var currentLineId = null;

            function closeAccountPicker() {
                var overlay = document.getElementById("accountPickerOverlay");
                if (overlay) overlay.style.display = "none";
            }

            function openAccountPicker(label, lineId) {
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

            function wireAccountSelectors() {
                document.querySelectorAll(".js-account-selector").forEach(function (el) {
                    if (el.dataset.wired === "1") return;
                    el.dataset.wired = "1";
                    el.addEventListener("click", function () {
                        var row = el.closest(".item-row");
                        if (!row) return;
                        var hidId = row.querySelector("input[id*='hidId']");
                        var lineId = hidId ? hidId.value : "0";
                        openAccountPicker(el, lineId);
                    });
                });
            }

            document.addEventListener("DOMContentLoaded", wireAccountSelectors);

            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(wireAccountSelectors);
            }

        </script>
    </form>
</body>
</html>
