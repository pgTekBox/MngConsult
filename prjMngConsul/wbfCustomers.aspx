<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfCustomers.aspx.vb"
    Inherits="MngConsul.wbfCustomers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — MngConsul
 
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
            TABLETTE — 769px à 1024px
         ========================= */
        @media  (max-width: 1024px) {
            .listview-row {
                grid-template-columns: minmax(180px, 1.4fr) 30px;
                gap: 12px;
                padding: 12px 14px;
            }


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


  <telerik:RadAjaxManager ID="Ram1" runat="server">
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
                    OnClientClick="openCustomerWindow(0); return false;" />
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
                                    
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwCustomer"", ""wbfCustomerEdit.aspx"", ""Modifier un client"", ""Ajouter un client""); return false;" %>' /> 
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip="Supprimer"
                                    CommandName="DeleteClient"
                                    CommandArgument='<%# Eval("Id") %>'
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
        <button class="fab-add" onclick="openRadWindow(0); return false;" title="Ajouter un client">+</button>
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
         

        function rwCustomer_OnClientClose(sender, args) {

            var ajaxManager = $find("RAP1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }


        }



    </script>
</asp:Content>
