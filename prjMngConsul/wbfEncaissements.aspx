<%@ Page Title="Encaissements" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfEncaissements.aspx.vb" Inherits="MngConsul.wbfEncaissements" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Encaissements — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <style>
    /* ── Ventes › Encaissements : la signature du gabarit « Portail du client ».
       Le titre pose sur le fond de la page (FondDePage), puis trois indicateurs,
       puis la carte « Paiements reçus » : une ligne par paiement. ── */
    .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
    .fc-tete .txt { flex: 1 1 260px }
    .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
    .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
    .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
    .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
    .fc-btn.primaire, input.fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
    .fc-btn.primaire:hover, input.fc-btn.primaire:hover { background: #143A73 }

    .fc-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 16px }
    .fc-kpi { padding: 14px 16px; border-radius: 22px; display: flex; flex-direction: column; gap: 2px; background: #fff; color: #0E1F3D }
    .fc-kpi .lab { font-weight: 700; color: #44536E; font-size: 14px }
    .fc-kpi .val { font-size: 24px; font-weight: 800; line-height: 1.15 }
    .fc-kpi .sub { font-size: 14px; color: #44536E }

    .en-carte { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-direction: column }
    .en-carte h2 { margin: 0 0 6px; font-size: 19px; font-weight: 800; color: #0E1F3D }
    .en-outils { display: flex; align-items: center; gap: 10px; margin: 4px 0 8px }
    .fc-recherche { flex: 1 1 260px; display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 0 6px 0 14px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; width: 100%; max-width: 520px; box-sizing: border-box }
    .fc-recherche:focus-within { border-color: #1B4F9C; box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .fc-recherche svg { flex: none }
    .fc-recherche input[type=text] { border: 0 !important; outline: none; flex: 1 1 auto; min-width: 0; background: transparent !important; color: #0E1F3D; font: inherit; font-size: 15px; padding: 0 !important; box-shadow: none !important; width: auto !important; border-radius: 0; max-width: none !important }
    .fc-recherche .btn-icon { width: 34px; height: 34px; border: 0; background-color: transparent !important; border-radius: 50% }
    .fc-recherche .btn-icon-search { margin-left: auto }
    .fc-recherche .btn-icon:hover { background-color: #F2F5F9 !important }

    .en-ligne { display: flex; flex-wrap: wrap; align-items: center; gap: 6px 14px; padding: 12px 0; border-top: 1px solid #E3E9F1 }
    .en-ico { width: 40px; height: 40px; flex: none; border-radius: 50%; background: #E3F3EA; color: #0F5A3A; display: flex; align-items: center; justify-content: center }
    .en-ico svg { width: 18px; height: 18px }
    .en-qui { flex: 1 1 220px; display: flex; flex-direction: column; min-width: 0 }
    .en-qui b { font-weight: 800; color: #0E1F3D }
    .en-qui span { font-size: 14px; color: #44536E }
    .en-fact { font-size: 14px; color: #44536E; flex: 0 1 220px }
    .en-montant { min-width: 110px; text-align: right; font-weight: 800; color: #0E1F3D }
    .en-par { padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800; white-space: nowrap }
    .en-par.banque { background: #FBF1DC; color: #7A5200 }
    .en-par.vous { background: #E8EDF5; color: #143A73 }
    .en-vide { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .fc-pied { padding: 12px 0 0; color: #44536E; font-size: 14px }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <%-- Le RadWindowManager reste HORS du RadAjaxPanel (même règle que les factures). --%>
    <telerik:RadWindowManager ID="rwmEncaissements" runat="server" EnableShadow="true"></telerik:RadWindowManager>
    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="Ram1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="pnlPage" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="pnlPage" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="pnlPage" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <asp:Panel ID="pnlPage" runat="server">

        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <asp:Button ID="btnNouveau" runat="server" CssClass="fc-btn primaire" CausesValidation="false"
                OnClientClick="ouvrirEncaissement(); return false;" />
        </div>

        <%-- Les trois indicateurs : reçu ce mois, rapprochés avec la banque, encore à recevoir. --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <section class="en-carte">
            <h2><asp:Literal ID="litTitreListe" runat="server" /></h2>
            <div class="en-outils">
                <asp:Panel ID="pnlRecherche" runat="server" CssClass="fc-recherche" DefaultButton="btnSearch">
                    <svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#44536E" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </asp:Panel>
            </div>
            <asp:Literal ID="litLignes" runat="server" />
            <div class="fc-pied"><asp:Literal ID="litPied" runat="server" /></div>
        </section>

    </asp:Panel>

    <%-- La fenêtre de saisie d'un paiement reçu : l'usercontrol d'encaissement, sens ENCAISSEMENT. --%>
    <telerik:RadWindow ID="rwEncaissement" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Title="Enregistrer un paiement reçu"
        OnClientClose="rwEncaissement_OnClose"
        ClientIDMode="Static">
    </telerik:RadWindow>

    <telerik:RadCodeBlock ID="rcbLang" runat="server">
        <script type="text/javascript">
            var L_NOUVEL_ENC = "<%= L("winNouveau") %>";
        </script>
    </telerik:RadCodeBlock>

    <script type="text/javascript">
        // Un paiement reçu sans client présélectionné : le client se choisit dans la fenêtre.
        function ouvrirEncaissement() {
            var w = $find("rwEncaissement");
            if (!w) { return; }
            w.set_title(L_NOUVEL_ENC);
            w.set_width(Math.min(window.innerWidth - 20, 1100));
            w.set_height(Math.min(window.innerHeight - 20, 720));
            w.setUrl("wbfReceiptEditPopup.aspx?Id=0&Sens=ENCAISSEMENT");
            w.show();
            w.center();
        }
        // À la fermeture, la liste et les indicateurs se rechargent.
        function rwEncaissement_OnClose(sender, args) {
            var am = $find("Ram1");
            if (am) { am.ajaxRequest("refresh"); }
        }
    </script>
</asp:Content>
