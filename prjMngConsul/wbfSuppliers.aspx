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

        /* Cellule d'actions : badge + boutons alignés à droite, sur une ligne */
        .listview-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 8px;
            flex-wrap: wrap;
        }
        /* Colonne Stripe : le badge occupe sa propre cellule */
        .field-stripe { display: flex; align-items: center; }
        .stripe-badge .dot { width: 7px; height: 7px; border-radius: 50%; flex: 0 0 7px; }
        .stripe-badge.on  { background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; }
        .stripe-badge.on .dot  { background: #10b981; }
        .stripe-badge.off { background: #f1f5f9; border: 1px solid #e2e8f0; color: #64748b; }
        .stripe-badge.off .dot { background: #94a3b8; }
        .stripe-badge:hover { filter: brightness(0.97); }

        /* Icône Stripe Connect (violet Stripe) */
        .btn-icon-stripe {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23635BFF' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='2' y='5' width='20' height='14' rx='2'/%3E%3Cpath d='M2 10h20'/%3E%3Cpath d='M7 15h2'/%3E%3C/svg%3E") !important;
            background-repeat: no-repeat !important;
            background-position: center !important;
            background-size: 18px 18px !important;
        }

        /* Montant dû : chiffres alignés à droite, colonne étroite. */
        .colh-amount, .field-amount {
            text-align: right;
            font-variant-numeric: tabular-nums;
            white-space: nowrap;
        }
        .field-amount { font-weight: 700; color: #0f172a; }
        .field-amount.zero { font-weight: 400; color: #94a3b8; }

        /* Entêtes cliquables (tri) */
        .sort-link, .sort-link:hover, .sort-link:visited {
            color: inherit;
            text-decoration: none;
            cursor: pointer;
            font-weight: inherit;
        }
        .sort-link:hover { text-decoration: underline; }

        /* Courriel affiché sous l'adresse */
        .cust-email { color: #64748b; font-size: 12px; }

        .listview-list-head {
            display: grid;
            /* L'entête et les lignes sont deux grilles CSS distinctes : une
               dernière colonne « auto » s'y calculait différemment (largeur du
               mot « Action » d'un côté, largeur des boutons de l'autre), ce qui
               décalait « À payer » de son montant. Largeurs fixes des deux côtés. */
            grid-template-columns: minmax(220px, 1fr) 130px 160px 140px;
            gap: 16px;
            padding: 14px 16px;
            font-weight: 800;
            font-size: 13px;
            color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky;
            top: 0;
            z-index: 0;
            box-sizing: border-box;
        }



        .listview-row {
            display: grid;
            /* L'entête et les lignes sont deux grilles CSS distinctes : une
               dernière colonne « auto » s'y calculait différemment (largeur du
               mot « Action » d'un côté, largeur des boutons de l'autre), ce qui
               décalait « À payer » de son montant. Largeurs fixes des deux côtés. */
            grid-template-columns: minmax(220px, 1fr) 130px 160px 140px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

          

      

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
                  <telerik:AjaxUpdatedControl ControlID="rlvSuppliers" />
                
              </UpdatedControls>
          </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
              <UpdatedControls>
                <telerik:AjaxUpdatedControl ControlID="rlvSuppliers" />
         
              </UpdatedControls>
            </telerik:AjaxSetting>
          
             <telerik:AjaxSetting AjaxControlID="btnClear">
    <UpdatedControls>
      <telerik:AjaxUpdatedControl ControlID="rlvSuppliers" />
         
    </UpdatedControls>
  </telerik:AjaxSetting>

      </AjaxSettings>
  </telerik:RadAjaxManager>

     

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>

            </div>

            <div class="searchbox">
                <asp:Button ID="btnAddSupplier" runat="server"
                    CssClass="btn btnAddRow"  ClientIDMode="Static"
                    Text="Ajouter Fournisseur"
                    CausesValidation="false"
                    OnClientClick="saveListScrollNow(); openNewSupplierWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server"  ClientIDMode="Static"
                        CssClass="input  txttbsearch"
                        placeholder="Rechercher (nom, email, téléphone…)" />

                    <asp:Button ID="btnSearch" runat="server"
                        CssClass="btn btn-icon btn-icon-search"  ClientIDMode="Static"
                        Text="" />

                    <asp:Button ID="btnClear" runat="server"
                        CssClass="btn btn-icon btn-icon-clear"  ClientIDMode="Static"
                        Text=""
                        ToolTip="Effacer"
                        CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
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
                                <div class="colh-file">
                                    <asp:LinkButton ID="lnkSortName" runat="server" CssClass="sort-link"
                                        CommandName="SortBy" CommandArgument="Name" CausesValidation="false" />
                                </div>
                                <div class="colh-amount">
                                    <asp:LinkButton ID="lnkSortAmount" runat="server" CssClass="sort-link"
                                        CommandName="SortBy" CommandArgument="APayer" CausesValidation="false" />
                                </div>
                                <div class="colh-stripe">
                                    <asp:LinkButton ID="lnkSortStripe" runat="server" CssClass="sort-link"
                                        CommandName="SortBy" CommandArgument="StripeAccountId" CausesValidation="false" />
                                </div>
                                <div class="colh-actions"><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder  ClientIDMode="Static" ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                           
                            
                             <div   class="field-AllAddress">
                                <%# Eval("NameAllAdddress") %>
                            </div>

                            <div class="field-amount"><%# FormatAmount(Eval("APayer")) %></div>


                            <%-- Badge d'inscription Stripe : colonne à part, sous son entête --%>
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

            </div>
        </div>

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
