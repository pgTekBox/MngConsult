<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="PlaidAccounts.aspx.vb"
    Inherits="MngConsul.PlaidAccounts" Async="true" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>

    <style>
    /* ── Ventes › Factures clients : la signature du gabarit « Portail du client ».
       Le titre pose sur le fond de la page (FondDePage), puis quatre indicateurs
       cliquables, la carte « recherche et filtres », et la carte de la liste. ── */
    .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
    .fc-tete .txt { flex: 1 1 260px }
    .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
    .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
    .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
    .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px }
    .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
    .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 }
    .fc-btn.primaire, input.fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
    .fc-btn.primaire:hover, input.fc-btn.primaire:hover { background: #143A73 }

    .fc-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 16px }
    .fc-kpi { padding: 14px 16px; border-radius: 22px; text-align: left; display: flex; flex-direction: column; gap: 2px; border: 2px solid transparent; background: #fff; color: #0E1F3D; cursor: pointer; font-family: inherit }
    .fc-kpi:hover { border-color: #D5DDE8 }
    .fc-kpi.on { border-color: #1B4F9C }
    .fc-kpi .lab { display: flex; align-items: center; gap: 8px; font-weight: 700; color: #44536E; font-size: 14px }
    .fc-kpi .lab i { width: 10px; height: 10px; border-radius: 50%; flex: none }
    .fc-kpi .val { font-size: 24px; font-weight: 800; line-height: 1.15 }
    .fc-kpi .sub { font-size: 14px; color: #44536E }

    .fc-filtres { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px }
    .fc-recherche { display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 0 6px 0 14px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; width: 100%; max-width: 520px; box-sizing: border-box }
    .fc-recherche:focus-within { border-color: #1B4F9C; box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .fc-recherche svg { flex: none }
    .fc-recherche input[type=text] { border: 0 !important; outline: none; flex: 1 1 auto; min-width: 0; background: transparent !important; color: #0E1F3D; font: inherit; font-size: 15px; padding: 0 !important; box-shadow: none !important; width: auto !important; border-radius: 0; max-width: none !important }
    .fc-recherche .btn-icon { width: 34px; height: 34px; border: 0; background-color: transparent !important; border-radius: 50% }
    .fc-recherche .btn-icon-search { margin-left: auto }
    .fc-recherche .btn-icon:hover { background-color: #F2F5F9 !important }
    .fc-groupes { display: flex; flex-wrap: wrap; gap: 10px 24px; align-items: flex-end }
    .fc-groupe { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 800; color: #5B6B86 }
    .fc-chips { display: flex; flex-wrap: wrap; gap: 6px }
    .fc-chip { display: inline-flex; align-items: center; gap: 6px; min-height: 36px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 13px; font-family: inherit; cursor: pointer }
    .fc-chip i { width: 8px; height: 8px; border-radius: 50%; flex: none }
    .fc-chip b { font-weight: 700; color: #5B6B86 }
    .fc-chip:hover { background: #F2F5F9 }
    .fc-chip.on { background: #0E1F3D; border-color: #0E1F3D; color: #fff }
    .fc-chip.on b { color: #AEBBCD }

    /* La liste : une carte blanche ; en-tête gris-bleu sans fond, lignes à filet doux. */
    .fc-liste.full-grid { height: auto; min-height: 0 }
    .fc-liste .list-shell { height: auto; padding: 6px 12px 12px; border-radius: 24px; background: #fff }
    .fc-liste .list-shell > * { flex: none; display: block }
    .fc-liste .listview-list-body { overflow: visible }
    .fc-liste .listview-list-head, .fc-liste .listview-row {
        display: grid; grid-template-columns: 96px 118px minmax(0, 2fr) 120px 112px 104px 132px 210px;
        gap: 10px; align-items: center; padding: 10px 6px; box-sizing: border-box;
    }
    .fc-liste .listview-list-head { position: static; background: transparent; border: 0; font-size: 14px; font-weight: 800; color: #5B6B86; z-index: auto }
    .fc-liste .listview-row { border: 0; border-top: 1px solid #E3E9F1; background: #fff; font-size: 15px }
    .fc-liste .listview-row:hover { background: #FAFCFF }
    .fc-liste .sort-link, .fc-liste .sort-link:hover, .fc-liste .sort-link:visited { color: inherit; text-decoration: none; cursor: pointer; font-weight: inherit }
    .fc-liste .sort-link:hover { text-decoration: underline }
    .fc-liste .adroite { text-align: right }
    .fc-liste .c-num { white-space: nowrap }
    .fc-liste .lien { font-weight: 800 }
    .fc-liste .c-ech { display: flex; flex-direction: column; line-height: 1.3 }
    .fc-liste .c-ech b { font-weight: 700 }
    .fc-liste .c-ech span { font-size: 13px; color: #44536E }
    .fc-liste .c-client { min-width: 0 }
    .fc-liste .c-client > div:first-child { font-weight: 800 }
    .fc-liste .cust-email { font-size: 13px; color: #44536E; margin-top: 0 }
    .fc-pay { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800; white-space: nowrap }
    .fc-liste .c-reste { text-align: right; font-weight: 800 }
    .fc-liste .c-reste.retard { color: #A3261C }
    .fc-liste .c-reste span { display: block; font-size: 12px; font-weight: 600; color: #44536E }
    .fc-liste .c-total { text-align: right; font-weight: 700 }
    .fc-etat { display: inline-flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 700 }
    .fc-etat svg { flex: none }
    .fc-liste .listview-actions { display: flex; justify-content: flex-end; gap: 4px; flex-wrap: nowrap }
    .fc-liste .listview-actions .btn-icon { width: 40px; height: 40px; border: 0; border-radius: 10px; background-color: transparent !important; background-size: 22px 22px !important }
    .fc-liste .listview-actions .btn-icon:hover { background-color: #F2F5F9 !important }
    .fc-liste .listview-actions .btn-icon-invoice-send { background-size: 26px 26px !important }
    .fc-liste .empty-state { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .fc-pied { padding: 12px 6px 0; color: #44536E; font-size: 14px }
    /* Les colonnes : banque, solde, connecté le, état, actions. */
    .fc-liste .listview-list { min-width: 860px }
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: minmax(0, 2fr) 150px 150px 140px 100px }
    .fc-liste .c-banque { display: flex; flex-direction: column; min-width: 0 }
    .fc-liste .c-banque b { font-weight: 800; color: #0E1F3D }
    .fc-liste .c-banque span { font-size: 14px; color: #44536E }
    .fc-liste .c-solde { text-align: right; font-weight: 800; white-space: nowrap }
    .fc-liste .c-solde.neg { color: #A3261C }
    .fc-etat .pt { width: 10px; height: 10px; border-radius: 50%; display: inline-block }
    /* L'importation des transactions, au pied de la carte de la liste. */
    .import-panel { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 12px; padding: 14px 6px 4px; margin-top: 8px; border-top: 1px solid #E3E9F1 }
    .import-panel label { font-size: 13px; font-weight: 800; color: #5B6B86 }
    .import-panel .input, .import-panel select { min-height: 40px; min-width: 150px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; font: inherit; font-size: 14px; color: #0E1F3D }
    .import-result { display: block; padding: 10px 6px 0; font-size: 14px; font-weight: 700 }
    .text-success { color: #0F5A3A }
    .text-danger { color: #A3261C }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
             le titre, le sous-titre, et à droite le bouton de connexion en pastille bleue. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div class="btns">
                <a class="fc-btn" href="wbfReleve.aspx"><asp:Literal ID="litReleveBtn" runat="server" /></a>
                <asp:Button ID="btnConnect" runat="server"
                    CssClass="fc-btn primaire"
                    Text=""
                    CausesValidation="false"
                    OnClientClick="openPlaidFromPage(); return false;" />
            </div>
        </div>

        <%-- Les quatre indicateurs : comptes connectés, solde des comptes connectés,
             déconnectés, dernière connexion. --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <div class="fc-liste full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvAccounts" runat="server"
                    Skin="Metro"
                    DataKeyNames="ItemId"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div><asp:Literal ID="litColBank" runat="server" /></div>
                                <div class="adroite"><asp:Literal ID="litColBalance" runat="server" /></div>
                                <div><asp:Literal ID="litColDate" runat="server" /></div>
                                <div><asp:Literal ID="litColStatus" runat="server" /></div>
                                <div class="adroite"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>

                            <%-- Panel d'import en bas de la liste --%>
                            <div class="import-panel">
                                <label><asp:Literal ID="litLblAccount" runat="server" /></label>
                                <asp:DropDownList ID="ddlAccount" runat="server" CssClass="input"></asp:DropDownList>

                                <label><asp:Literal ID="litLblFrom" runat="server" /></label>
                                <asp:TextBox ID="txtStartDate" runat="server" CssClass="input" TextMode="Date"></asp:TextBox>

                                <label><asp:Literal ID="litLblTo" runat="server" /></label>
                                <asp:TextBox ID="txtEndDate" runat="server" CssClass="input" TextMode="Date"></asp:TextBox>

                                <asp:Button ID="btnImport" runat="server"
                                    CssClass="fc-btn"
                                    Text=""
                                    CausesValidation="false" />
                            </div>

                            <asp:Label ID="lblResult" runat="server" CssClass="import-result" Visible="false"></asp:Label>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            <%-- La banque et le compte, le solde, la date de connexion, l'état, puis l'action. --%>
                            <div class="c-banque"><%# BanqueCell(Eval("BankName"), Eval("AccountName"), Eval("AccountNumber")) %></div>
                            <div class='<%# "c-solde" & If(Nombre(Eval("BalanceCurrent")) < 0D, " neg", "") %>'><%# FormatMontant(Eval("BalanceCurrent")) %></div>
                            <div><%# FormatDateOnly(Eval("Created")) %></div>
                            <div><%# EtatCell(Eval("Active")) %></div>

                            <div class="listview-actions">
                                <asp:Button ID="btnDisconnect" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip='<%# L("disconnect") %>'
                                    CommandName="Disconnect"
                                    CommandArgument='<%# Eval("ItemId") %>'
                                    Visible='<%# CBool(Eval("Active")) %>'
                                    OnClientClick="if (!confirm(L_CONFIRM_DISCONNECT)) { return false; }"
                                    CausesValidation="false" />
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            <asp:Literal ID="litEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

                <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>

            </div>
        </div>

        <%-- FAB mobile --%>
        <button id="fabAdd" runat="server" class="fab-add" onclick="openPlaidFromPage(); return false;" title="">+</button>

    </telerik:RadAjaxPanel>

    <telerik:RadCodeBlock ID="rcbPlaidJs" runat="server">
        <script type="text/javascript">
            var L_CONFIRM_DISCONNECT = "<%= L("confirmDisconnect") %>";
        </script>
    </telerik:RadCodeBlock>

</asp:Content>
