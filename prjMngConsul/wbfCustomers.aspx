<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfCustomers.aspx.vb"
    Inherits="MngConsul.wbfCustomers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — 60Sec-AI
 
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
   <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <script src="js/viewport.js"></script>

    <style>

  

        .listview-list-head {
            display: grid;
            grid-template-columns: minmax(280px, auto) minmax(40px, 1fr);
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
            grid-template-columns: minmax(280px, 1.7fr) 100px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

          

      

        /* =========================
             MOBILE LARGE  grands smartphones en portrait
         ========================= */
        @media  (max-width: 768px) {

            .field-AllAddress {
                order: 1;
            }

            .listview-list-head {
                display: none;
            }
        }

        /* =========================
         PETIT MOBILE — max 480px
           ========================= */
        @media (max-width: 480px) {


            .listview-row {
                grid-template-columns: auto 30px;
                gap: 10px;
                padding: 14px;
            }

            .listview-list-head {
                display: none;
            }
        }
    </style>




</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadWindowManager ID="rwmCustomers" runat="server" EnableShadow="true"></telerik:RadWindowManager>


  <telerik:RadAjaxManager ID="Ram1" runat="server"  ClientIDMode="Static">
      <ClientEvents OnRequestStart="captureListScroll" OnResponseEnd="restoreListScroll" />
      <AjaxSettings>

          <%-- Refresh du label fournisseur + label adresse + lignes --%>
          <telerik:AjaxSetting AjaxControlID="btnClear">
              <UpdatedControls>
                  <telerik:AjaxUpdatedControl ControlID="rlvClients" />
                
              </UpdatedControls>
          </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
              <UpdatedControls>
                <telerik:AjaxUpdatedControl ControlID="rlvClients" />
         
              </UpdatedControls>
            </telerik:AjaxSetting>
          
             <telerik:AjaxSetting AjaxControlID="btnClear">
    <UpdatedControls>
      <telerik:AjaxUpdatedControl ControlID="rlvClients" />
         
    </UpdatedControls>
  </telerik:AjaxSetting>

      </AjaxSettings>
  </telerik:RadAjaxManager>

     

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Clients</div>

            </div>

            <div class="searchbox">
                <asp:Button ID="btnAddCustomer" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Client"
                    CausesValidation="false"
                    OnClientClick="saveListScrollNow(); openNewCustomerWindow(0); return false;" />
                <asp:Button ID="btnExportSquare" runat="server"
                    CssClass="btn"
                    Text="Exporter vers Square"
                    CausesValidation="false" />
                <asp:Button ID="btnImportSquare" runat="server"
                    CssClass="btn"
                    Text="Importer depuis Square"
                    CausesValidation="false" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server"
                        CssClass="input  txttbsearch"
                        placeholder="Rechercher (nom, email, téléphone…)" />

                    <asp:Button ID="btnSearch" runat="server"
                        CssClass="btn btn-icon btn-icon-search"
                        Text="" />

                    <asp:Button ID="btnClear" runat="server"
                        CssClass="btn btn-icon btn-icon-clear"
                        Text=""
                        ToolTip="Effacer"
                        CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvClients" runat="server"
                    Skin="Metro"
                    DataKeyNames="Id"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div class="colh-file">Nom</div>

                                <div class="colh-actions">Action</div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                           
                            
                             <div class="field-AllAddress">
                                <%# Eval("NameAllAdddress") %>
                            </div>
                             

                            <div class="listview-actions">

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip="Modifier"
                                    CausesValidation="false"
                                    
                                    OnClientClick='<%# "saveListScrollNow(); openRadWindow(" & Eval("Id") & ", ""rwCustomer"", ""wbfCustomerEdit.aspx"", ""Modifier un client"", ""Ajouter un client""); return false;" %>' />
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip="Supprimer"
                                    CommandName="DeleteClient"
                                    CommandArgument='<%# Eval("Id") %>'
                                    OnClientClick="saveListScrollNow();"
                                    CausesValidation="false" />
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucun client trouvé.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

        <%-- FAB mobile --%>
        <button class="fab-add" onclick="saveListScrollNow(); openNewCustomerWindow(0); return false;" title="Ajouter un client">+</button>
        <%--openRadWindow(" & Eval("Id") & ", ""rwCustomer"", ""wbfCustomerEdit.aspx"", ""Modifier un client"", ""Ajouter un client""); return false;" %>' />--%> 

  

    <telerik:RadWindow ID="rwCustomer" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        
        Title="Ajouter / Modifier un Client"
        OnClientClose="rwCustomer_OnClientClose"
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
        var SCROLL_KEY = 'wbfCustomers_listScroll';

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

        // Restaurer dès que possible après chaque chargement de page
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


        function openNewCustomerWindow() {
            openRadWindow(0, "rwCustomer", "wbfCustomerEdit.aspx", "Ajouter un client", "Ajouter un client");
        }


        function rwCustomer_OnClientClose(sender, args) {

            var ajaxManager = $find("Ram1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }


        }



    </script>
</asp:Content>
