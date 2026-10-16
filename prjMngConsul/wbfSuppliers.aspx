<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfSuppliers.aspx.vb"
    Inherits="MngConsul.wbfSuppliers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
   <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <script src="js/viewport.js"></script>

    <style>
    /* ── Ventes › Clients : la signature du gabarit « Portail du client ».
       Le titre pose sur le fond de la page (FondDePage), puis la carte
       « recherche et filtre », puis la carte de la liste. ── */
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

    .fc-filtres { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-bottom: 16px }
    .fc-recherche { flex: 1 1 260px; display: flex; align-items: center; gap: 8px; min-height: 44px; padding: 0 6px 0 14px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; width: 100%; max-width: 520px; box-sizing: border-box }
    .fc-recherche:focus-within { border-color: #1B4F9C; box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .fc-recherche svg { flex: none }
    .fc-recherche input[type=text] { border: 0 !important; outline: none; flex: 1 1 auto; min-width: 0; background: transparent !important; color: #0E1F3D; font: inherit; font-size: 15px; padding: 0 !important; box-shadow: none !important; width: auto !important; border-radius: 0 }
    .fc-recherche .btn-icon { width: 34px; height: 34px; border: 0; background-color: transparent !important; border-radius: 50% }
    .fc-recherche .btn-icon:hover { background-color: #F2F5F9 !important }
    /* Le groupe de pastilles du filtre : un rail gris, la pastille choisie en blanc. */
    .fc-pills { display: flex; flex-wrap: wrap; gap: 4px; padding: 4px; background: #E8EDF5; border-radius: 999px }
    .fc-pill { min-height: 36px; padding: 0 12px; border: 0; border-radius: 999px; font-weight: 700; font-size: 14px; font-family: inherit; background: transparent; color: #0E1F3D; cursor: pointer }
    .fc-pill span { opacity: .7 }
    .fc-pill:hover { background: rgba(255,255,255,.6) }
    .fc-pill.on { background: #fff; box-shadow: 0 1px 2px rgba(14,31,61,.12) }

    /* La liste : une carte blanche ; en-tête gris-bleu sans fond, lignes à filet doux. */
    .fc-liste.full-grid { height: auto; min-height: 0 }
    .fc-liste .list-shell { height: auto; padding: 6px 12px 12px; border-radius: 24px; background: #fff; overflow-x: auto }
    .fc-liste .list-shell > * { flex: none; display: block }
    .fc-liste .listview-list { min-width: 820px }
    .fc-liste .listview-list-body { overflow: visible }
    .fc-liste .listview-list-head, .fc-liste .listview-row {
        display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1.6fr) 110px 130px 110px;
        gap: 10px; align-items: center; padding: 10px 6px; box-sizing: border-box;
    }
    .fc-liste .listview-list-head { position: static; background: transparent; border: 0; font-size: 14px; font-weight: 800; color: #5B6B86; z-index: auto }
    .fc-liste .listview-row { border: 0; border-top: 1px solid #E3E9F1; background: #fff; font-size: 15px; padding: 12px 6px }
    .fc-liste .listview-row:hover { background: #FAFCFF }
    .fc-liste .sort-link, .fc-liste .sort-link:hover, .fc-liste .sort-link:visited { color: inherit; text-decoration: none; cursor: pointer; font-weight: inherit }
    .fc-liste .sort-link:hover { text-decoration: underline }
    .fc-liste .adroite { text-align: right }
    .c-client { display: flex; align-items: center; gap: 10px; min-width: 0 }
    .c-client .av { width: 40px; height: 40px; flex: none; border-radius: 50%; background: #E3EBF7; color: #143A73; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 14px }
    .c-client .txt { display: flex; flex-direction: column; min-width: 0 }
    .c-client .txt b { font-weight: 800; color: #0E1F3D }
    .c-client .txt span { font-size: 13px; color: #44536E; overflow-wrap: anywhere }
    .c-adr { font-size: 15px; color: #44536E }
    .c-delai { font-size: 15px; color: #0E1F3D }
    .c-du { display: flex; flex-direction: column; align-items: flex-end }
    .c-du b { font-weight: 800; color: #0E1F3D }
    .c-du b.rien { font-weight: 400; color: #94a3b8 }
    .c-du span { font-size: 13px; color: #44536E }
    .c-du.retard b, .c-du.retard span { color: #A3261C }
    .fc-liste .listview-actions { display: flex; justify-content: flex-end; gap: 4px; flex-wrap: nowrap }
    .fc-liste .listview-actions .btn-icon { width: 40px; height: 40px; border: 0; border-radius: 10px; background-color: transparent !important; background-size: 22px 22px !important }
    .fc-liste .listview-actions .btn-icon:hover { background-color: #F2F5F9 !important }
    .fc-liste .listview-empty { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .fc-pied { padding: 12px 6px 0; color: #44536E; font-size: 14px }
        /* Badge d'inscription Stripe (cliquable → page de statut) */
        .stripe-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 800;
            text-decoration: none;
            white-space: nowrap;
            flex: 0 0 auto;
        }

        /* Colonne Stripe : le badge occupe sa propre cellule */
        .field-stripe { display: flex; align-items: center; }
        .stripe-badge .dot { width: 7px; height: 7px; border-radius: 50%; flex: 0 0 7px; }
        .stripe-badge.on  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .stripe-badge.on .dot  { background: #10b981; }
        .stripe-badge.off { background: #f1f5f9; border: 1px solid #D5DDE8; color: #44536E; }
        .stripe-badge.off .dot { background: #94a3b8; }
        .stripe-badge:hover { filter: brightness(0.97); }
        /* Icône Stripe Connect (violet Stripe) */
        .btn-icon-stripe {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23635BFF' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='5' width='20' height='14' rx='2'/%3E%3Cpath d='M2 10h20'/%3E%3Cpath d='M7 15h2'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }
    /* Six colonnes : le compte Stripe a la sienne. */
    .fc-liste .listview-list { min-width: 960px }
    .fc-liste .listview-list-head, .fc-liste .listview-row { grid-template-columns: minmax(0, 2fr) minmax(0, 1.5fr) 100px 130px 150px 136px }
    </style>




</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1"  runat="server" Skin="Metro" ClientIDMode="Static"></telerik:RadAjaxLoadingPanel>

    <telerik:RadWindowManager  ID="rwmSuppliers" runat="server" EnableShadow="true" ClientIDMode="Static"></telerik:RadWindowManager>


  <telerik:RadAjaxManager ID="Ram1" runat="server"  ClientIDMode="Static">
      <ClientEvents OnRequestStart="captureListScroll" OnResponseEnd="restoreListScroll" />
      <AjaxSettings>

          <%-- Refresh du label fournisseur + label adresse + lignes --%>
          <telerik:AjaxSetting AjaxControlID="btnClear">
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

     

        <%-- Tout ce qui change au clic (titre, pastilles, liste, pied) vit dans pnlPage, la cible des envois AJAX. --%>
        <asp:Panel ID="pnlPage" runat="server">
        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
             le titre, le sous-titre, et à droite le bouton en pastille. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div class="btns">
                <asp:Button ID="btnAddSupplier" runat="server"
                    CssClass="fc-btn primaire"  ClientIDMode="Static"
                    Text="+ Ajouter un fournisseur"
                    CausesValidation="false"
                    OnClientClick="saveListScrollNow(); openNewSupplierWindow(0); return false;" />
            </div>
        </div>

        <section class="fc-filtres">
            <asp:Panel ID="pnlRecherche" runat="server" CssClass="fc-recherche" DefaultButton="btnSearch">
                <svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#44536E" stroke-width="2.2" stroke-linecap="round"><circle cx="11" cy="11" r="7"></circle><path d="M20 20l-4-4"></path></svg>
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" ToolTip="Effacer" CausesValidation="false" />
            </asp:Panel>
            <div class="fc-pills" role="group"><asp:Literal ID="litChips" runat="server" /></div>
        </section>

        <div class="fc-liste full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvSuppliers" runat="server"
                    Skin="Metro"
                    DataKeyNames="Id"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <%-- Colonnes triables, sauf « Action ». --%>
                            <div class="listview-list-head">
                                <div><asp:LinkButton ID="lnkSortName" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="Name" CausesValidation="false" /></div>
                                <div><asp:Literal ID="litColAdresse" runat="server" /></div>
                                <div><asp:LinkButton ID="lnkSortDelai" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="DelaiJours" CausesValidation="false" /></div>
                                <div class="adroite"><asp:LinkButton ID="lnkSortAmount" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="APayer" CausesValidation="false" /></div>
                                <div><asp:LinkButton ID="lnkSortStripe" runat="server" CssClass="sort-link" CommandName="SortBy" CommandArgument="StripeAccountId" CausesValidation="false" /></div>
                                <div class="adroite"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder  ClientIDMode="Static" ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            <%-- Fournisseur (initiales, nom, courriel · téléphone), adresse de facturation,
                                 délai de paiement, à payer (en retard dessous), compte Stripe, puis les actions. --%>
                            <div class="c-client"><%# ClientCell(Eval("Name"), Eval("Email"), Eval("Phone")) %></div>
                            <div class="c-adr"><%# AdresseCell(Eval("AdresseFacturation")) %></div>
                            <div class="c-delai"><%# DelaiCell(Eval("DelaiJours")) %></div>
                            <div class='<%# DuClass(Eval("NbRetard")) %>'><%# DuCell(Eval("APayer"), Eval("EnRetard"), Eval("NbRetard")) %></div>
                            <div class="field-stripe"><%# StripeBadge(Eval("StripeAccountId"), Eval("Id")) %></div>

                            <div class="listview-actions">

                                <%-- Bouton Stripe Connect : ouvre l'onboarding du fournisseur dans une nouvelle fenêtre --%>
                                <asp:Button ID="btnStripe" runat="server"
                                    CssClass="btn btn-icon btn-icon-stripe"
                                    Text=""
                                    ClientIDMode="Static"
                                    ToolTip='<%# L("stripeTip") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "window.open(""wbfSupplierStripeOnboarding.aspx?PartyId="" + " & Eval("Id") & ", ""_blank""); return false;" %>' />

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ClientIDMode="Static"
                                    ToolTip='<%# L("edit") %>'
                                    CausesValidation="false"
                                    OnClientClick='<%# "saveListScrollNow(); openRadWindow(" & Eval("Id") & ", ""rwSupplier"", ""wbfSupplierEdit.aspx"", L_EDIT_SUPPLIER, L_ADD_SUPPLIER); return false;" %>' />
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ClientIDMode="Static"
                                    ToolTip='<%# L("delete") %>'
                                    CommandName="DeleteSupplier"
                                    CommandArgument='<%# Eval("Id") %>'
                                    OnClientClick="saveListScrollNow();"
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

        </asp:Panel>

        <%-- FAB mobile --%>
        <button class="fab-add" ClientIDMode="Static" onclick="saveListScrollNow(); openNewSupplierWindow(0); return false;" title="">+</button>
        <%--openRadWindow(" & Eval("Id") & ", ""rwSupplier"", ""wbfSupplierEdit.aspx"", ""Modifier un fournisseur"", ""Ajouter un fournisseur""); return false;" %>' />--%> 

  

    <telerik:RadWindow ID="rwSupplier" runat="server"
        Modal="true" 
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        
        Title="Ajouter / Modifier un Fournisseur"
        OnClientClose="rwSupplier_OnClientClose"
        ClientIDMode="Static">
    </telerik:RadWindow>
    <script src="js/RadWindows.js"></script>



    <script type="text/javascript">
        // Une pastille de filtre cliquée : le RadAjaxManager renvoie « chip|groupe|valeur »
        // au serveur (Ram1_AjaxRequest → ChoisirPastille), qui recharge pnlPage.
        function fcChip(g, v) {
            var am = $find("Ram1");
            if (am) { am.ajaxRequest("chip|" + g + "|" + v); }
        }

        // ── Conservation du scroll ───────────────────────────────────────
        // Stratégie en deux temps :
        //   (a) sessionStorage : survit aux rechargements complets de page
        //       → utilisé via saveListScrollNow() avant ouverture du modal
        //   (b) ClientEvents Telerik : couvre les refresh AJAX in-place
        //       → captureListScroll / restoreListScroll
        var SCROLL_KEY = 'wbfSuppliers_listScroll';

        function saveListScrollNow() {
            var body = document.querySelector('.listview-list-body');
            var v = body ? body.scrollTop : 0;
            try { sessionStorage.setItem(SCROLL_KEY, v); } catch (e) { }
        }

        function restoreListScrollFromStorage() {
            var raw = null;
            try { raw = sessionStorage.getItem(SCROLL_KEY); } catch (e) { }
            if (raw === null) return;
            var n = parseInt(raw, 10) || 0;
            try { sessionStorage.removeItem(SCROLL_KEY); } catch (e) { }
            if (n <= 0) return;

            var apply = function () {
                var body = document.querySelector('.listview-list-body');
                if (body) body.scrollTop = n;
            };
            apply();
            if (window.requestAnimationFrame) requestAnimationFrame(apply);
            setTimeout(apply, 50);
            setTimeout(apply, 200);
            setTimeout(apply, 500);
        }

        if (document.readyState !== 'loading') {
            restoreListScrollFromStorage();
        } else {
            document.addEventListener('DOMContentLoaded', restoreListScrollFromStorage);
        }
        window.addEventListener('load', restoreListScrollFromStorage);

        // Hooks Telerik AJAX (cas refresh in-place sans reload)
        var __listScrollSaved = { winY: 0, bodyY: 0, has: false };

        function captureListScroll(sender, args) {
            __listScrollSaved.winY = window.scrollY || window.pageYOffset || 0;
            var body = document.querySelector('.listview-list-body');
            __listScrollSaved.bodyY = body ? body.scrollTop : 0;
            __listScrollSaved.has = true;
        }

        function restoreListScroll(sender, args) {
            if (!__listScrollSaved.has) return;
            var winY = __listScrollSaved.winY, bodyY = __listScrollSaved.bodyY;

            var apply = function () {
                if (winY > 0) window.scrollTo(0, winY);
                var body = document.querySelector('.listview-list-body');
                if (body && bodyY > 0) body.scrollTop = bodyY;
            };
            apply();
            if (window.requestAnimationFrame) requestAnimationFrame(apply);
            setTimeout(apply, 50);
            setTimeout(apply, 200);
        }


        // L_ADD_SUPPLIER / L_EDIT_SUPPLIER sont injectes par le code-behind
        // (ScriptManager.RegisterStartupScript). Aucun bloc de rendu serveur ne doit
        // rester dans MainContent, sinon RadAjax ne peut pas deplacer le RadUpdatePanel.

        function openNewSupplierWindow() {
            openRadWindow(0, "rwSupplier", "wbfSupplierEdit.aspx", L_ADD_SUPPLIER, L_ADD_SUPPLIER);
        }


        function rwSupplier_OnClientClose(sender, args) {

            var ajaxManager = $find("Ram1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }


        }



    </script>
</asp:Content>
