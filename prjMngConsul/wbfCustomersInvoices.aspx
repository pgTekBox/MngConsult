<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomersInvoices.aspx.vb" Inherits="MngConsul.wbfCustomersInvoices" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

    <link href="css/listvew.css" rel="stylesheet" />

    <script src="js/viewport.js"></script>

    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 70px 100px 1fr 90px minmax(40px, 40px) 40px ;
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
            grid-template-columns: 70px 100px 1fr 90px minmax(40px, 40px) 40px ;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

            .listview-row:hover {
                background: #fafcff;
            }

        /* =========================
         TABLETTE — 769px à 1024px
      ========================= */
        @media (min-width: 769px) and (max-width: 1024px) {
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
        @media (min-width: 481px) and (max-width: 768px) {

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



    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <telerik:RadWindowManager ID="rwmCustomersInvoices" runat="server" EnableShadow="true">
        </telerik:RadWindowManager>



        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Client</div>

            </div>

            <div class="searchbox">
                <asp:Button ID="btnAddCustomerInvoice" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Facture"
                    CausesValidation="false"
                    OnClientClick="openCustomerInvoiceWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server"
                        CssClass="input"
                        placeholder="Rechercher (nom, email, téléphone…)" />

                    <asp:Button ID="btnSearch" runat="server"
                        CssClass="btn btn-icon btn-icon-search"
                        Text="" />

                    <asp:Button ID="btnClear" runat="server"
                        CssClass="btn btn-icon btn-icon-clear"
                        Text=""
                        CausesValidation="false" />
                </div>

            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvClientsFactures" runat="server"
                    Skin="Metro"
                    AllowPaging="False"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div class="colh-numero">#</div>
                                <div class="colh-date">Date</div>
                                <div class="colh-customer">Client</div>
                                <div class="colh-total">Total</div>
                                <div class="colh-etat">État</div>
                                <div class="colh-action">Action</div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <div class="field-number">
                                <%# Eval("DocumentNumber") %>
                            </div>
                            <div class="field-date">
                                <%# Eval("DocumentDate", "{0:yyyy-MM-dd}") %>
                            </div>
                            <div class="field-customer">
                                <%# Eval("Name") %>
                            </div>
                            <div class="field-total">
                                <%# Eval("Total", "{0:C2}") %>
                            </div>
                            <div class="field-etat">
                                <%# Eval("Status") %>
                            </div>


                            <div class="listview-actions">

                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    ToolTip="Modifier"
                                    CausesValidation="false"
                                    OnClientClick='<%# "openInvoiceWindow(" & Eval("Id") & "); return false;" %>' />

                                <asp:Button ID="Button1" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip="Supprimer"
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CausesValidation="false" />
                            </div>




                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="empty-state">
                            Aucune facture trouvée.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>



    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwInvoice" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        Title="Ajouter / Modifier une Facture"
        OnClientClose="rwCustomer_OnInvoiceClose"
        ClientIDMode="Static">
    </telerik:RadWindow>
    <script type="text/javascript">
        function openInvoiceWindow(id) {
            var wnd = $find("rwInvoice");
            var url = "wbfInvoiceEdit.aspx";

            if (id && id > 0) {
                url += "?InvoiceId=" + id;
                wnd.set_title("Modifier une facture");
            } else {
                url += "?InvoiceId=0";
                wnd.set_title("Ajouter un client");
            }

            wnd.setUrl(url);
            wnd.show();
        }

        function rwCustomer_OnInvoiceClose(sender, args) {

            var ajaxManager = $find("RAP1");
            if (ajaxManager) {
                ajaxManager.ajaxRequest("refreshgrid");
            }


        }

    </script>


</asp:Content>
