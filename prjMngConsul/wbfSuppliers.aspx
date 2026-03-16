<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliers.aspx.vb" Inherits="MngConsul.wbfSuppliers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Fournisseurs — MngConsul
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
 

        /* Petites touches pour harmoniser avec le thème du Site.master */
        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }
      

      

        .page-title {
            font-weight: 900;
            font-size: 18px;
            line-height: 1.2;
        }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

        .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .grid-wrap {
            padding: 16px;
        }

        .full-grid {
            height: calc(100vh - 220px);
            padding: 16px;
            box-sizing: border-box;
        }

        .supplier-cards-shell {
            height: 100%;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15,23,42,.06);
            display: flex;
            flex-direction: column;
            min-height: 0;
        }

        .supplier-scroll {
            flex: 1 1 auto;
            overflow: auto;
            min-height: 0;
        }

        .supplier-cards-list {
            padding: 16px;
            gap: 16px;
            align-content: start;
            box-sizing: border-box;
        }

        .supplier-card {
            background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%);
            border: 1px solid #e8edf5;
            border-radius: 18px;
            padding: 16px;
            box-shadow: 0 8px 24px rgba(15,23,42,.05);
            transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
        }

            .supplier-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 16px 34px rgba(15,23,42,.10);
                border-color: #d7e3f4;
            }

        .supplier-card-top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
        }

        .supplier-card-title-wrap {
            min-width: 0;
            flex: 1;
        }

        .supplier-card-title {
            font-size: 17px;
            font-weight: 900;
            color: #0f172a;
            line-height: 1.3;
            word-break: break-word;
        }

        .supplier-card-sub {
            margin-top: 4px;
            font-size: 12px;
            color: #64748b;
        }

        .supplier-card-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .supplier-card-body {
            margin-top: 14px;
            padding-top: 14px;
            border-top: 1px solid #eef2f7;
        }

        .supplier-meta {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .supplier-meta-label {
            font-size: 12px;
            font-weight: 800;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .supplier-meta-value {
            font-size: 14px;
            font-weight: 700;
            color: #0f172a;
        }

        .supplier-empty {
            padding: 40px 20px;
            text-align: center;
            color: var(--mc-muted);
        }

        .supplier-pager {
            flex: 0 0 auto;
            padding: 12px 16px 16px 16px;
            border-top: 1px solid var(--mc-stroke);
            background: #fff;
        }

        .btn.danger {
            border-color: #fecaca !important;
            background: #fff5f5 !important;
            color: #b91c1c !important;
        }

            .btn.danger:hover {
                background: #fee2e2 !important;
            }
               
        @media (max-width: 700px) {
            .supplier-cards-list {
                grid-template-columns: 1fr;
                padding: 12px;
                gap: 12px;
            }

            .supplier-card {
                padding: 14px;
            }

            .supplier-card-top {
                flex-direction: column;
            }

            .supplier-card-actions {
                width: 100%;
                justify-content: flex-start;
            }
        }



        .supplier-row:hover {
            background: #fafcff;
        }



        .supplier-empty {
            padding: 28px;
            text-align: center;
            color: var(--mc-muted);
        }

        .full-grid {
            min-height: calc(100vh - 220px);
            padding: 16px;
            box-sizing: border-box;
        }

        .supplier-cards-shell {
            min-height: 100%;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15,23,42,.06);
            display: flex;
            flex-direction: column;
        }


        .supplier-card {
            background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%);
            border: 1px solid #e8edf5;
            border-radius: 18px;
            padding: 16px;
            box-shadow: 0 8px 24px rgba(15,23,42,.05);
            transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
        }

            .supplier-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 16px 34px rgba(15,23,42,.10);
                border-color: #d7e3f4;
            }

        .supplier-card-top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
        }

        .supplier-card-title-wrap {
            min-width: 0;
            flex: 1;
        }

        .supplier-card-title {
            font-size: 17px;
            font-weight: 900;
            color: #0f172a;
            line-height: 1.3;
            word-break: break-word;
        }

        .supplier-card-sub {
            margin-top: 4px;
            font-size: 12px;
            color: #64748b;
        }

        .supplier-card-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .supplier-card-body {
            margin-top: 14px;
            padding-top: 14px;
            border-top: 1px solid #eef2f7;
        }

        .supplier-meta {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .supplier-meta-label {
            font-size: 12px;
            font-weight: 800;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .supplier-meta-value {
            font-size: 14px;
            font-weight: 700;
            color: #0f172a;
        }

        .supplier-empty {
            padding: 40px 20px;
            text-align: center;
            color: var(--mc-muted);
        }

        .supplier-pager {
            padding: 12px 16px 16px 16px;
            border-top: 1px solid var(--mc-stroke);
            background: #fff;
        }

        .btn.danger {
            border-color: #fecaca !important;
            background: #fff5f5 !important;
            color: #b91c1c !important;
        }

            .btn.danger:hover {
                background: #fee2e2 !important;
            }

        @media (max-width: 700px) {
            .supplier-cards-list {
                grid-template-columns: 1fr;
                padding: 12px;
                gap: 12px;
            }

            .supplier-card {
                padding: 14px;
            }

            .supplier-card-top {
                flex-direction: column;
            }

            .supplier-card-actions {
                width: 100%;
                justify-content: flex-start;
            }
        }

        @media (max-width: 900px) {
            .supplier-list-head {
                display: none;
            }

            .supplier-row {
                grid-template-columns: 1fr;
                gap: 10px;
            }

            .supplier-created::before {
                content: "Créé le : ";
                font-weight: 800;
                color: #0f172a;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmSuppliers" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <div class="page-head">
            <div class="page-head-left">

                <div class="page-title">Fournisseurs</div>

            </div>

            <div class="searchbox">
                <asp:Button ID="btnAddSupplier" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Supplier"
                    CausesValidation="false"
                    OnClientClick="openSupplierWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input  txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />

                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>

            </div>
        </div>
        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rgFournisseurs" runat="server"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false"
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
                                OnClientClick='<%# "openSupplierWindow(" & Eval("Id") & "); return false;" %>' />

                            <asp:Button ID="btnDelete" runat="server"
                                CssClass="btn btn-icon btn-icon-delete"
                                Text=""
                                CommandName="DeleteSupplier"
                                CommandArgument='<%# Eval("Id") %>' />
                        </div>
   </div>

                        <%--<div class="supplier-card-body">
                                <div class="supplier-meta">
                                    <span class="supplier-meta-label">Créé le</span>
                                    <span class="supplier-meta-value"><%# Eval("Created", "{0:yyyy-MM-dd}") %></span>
                                </div>
                            </div>--%>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucun fournisseur trouvé.
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>




            </div>
        </div>
    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwSupplier" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        ClientIDMode="Static"
        Title="Ajouter / Modifier un fournisseur"
        OnClientClose="rwSupplier_OnClientClose">
    </telerik:RadWindow>
    <script type="text/javascript">
        function openSupplierWindow(id) {
            var wnd = $find("rwSupplier");
            var url = "wbfSupplierEdit.aspx";

            if (id && id > 0) {
                url += "?SupplierId=" + id;
                wnd.set_title("Modifier un fournisseur");
            } else {
                url += "?SupplierId=0";
                wnd.set_title("Ajouter un fournisseur");
            }

            wnd.setUrl(url);
            wnd.show();
        }

        function rwSupplier_OnClientClose(sender, args) {
            __doPostBack("rgFournisseurs", "Rebind");
        }
    </script>
</asp:Content>
