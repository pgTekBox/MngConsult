<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliersInvoices.aspx.vb" Inherits="MngConsul.wbfSuppliersInvoices" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <script src="js/viewport.js"></script>



    <style>
              .listview-list-head {
    display: grid;
    grid-template-columns: 210px 140px minmax(220px, 1fr) 140px 110px 130px;
    gap: 12px;
    padding: 14px 16px;
    font-weight: 800;
    font-size: 13px;
    color: #0f172a;
    background: #f8fafc;
    border-bottom: 1px solid var(--mc-stroke);
    position: sticky;
    top: 0;
    z-index: 5;
}

.listview-row {
    display: grid;
    grid-template-columns: 210px 140px minmax(220px, 1fr) 140px 110px 130px;
    gap: 12px;
    align-items: center;
    padding: 14px 16px;
    border-bottom: 1px solid #eef2f7;
    background: #fff;
}

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

        .full-grid {
            height: calc(100vh - 220px);
            padding: 16px;
            box-sizing: border-box;
        }

        .invoice-shell {
            height: 100%;
            display: flex;
            flex-direction: column;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15,23,42,.06);
            min-height: 0;
        }

        .invoice-scroll {
            flex: 1 1 auto;
            overflow: auto;
            min-height: 0;
        }

        .invoice-list {
            display: flex;
            flex-direction: column;
        }

     
        .invoice-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .invoice-number,
        .invoice-supplier,
        .invoice-status,
        .invoice-date {
            color: #0f172a;
            font-weight: 600;
            min-width: 0;
            word-break: break-word;
        }

        .invoice-total {
            color: #0f172a;
            font-weight: 800;
            text-align: right;
            white-space: nowrap;
        }

        .invoice-empty {
            padding: 40px 20px;
            text-align: center;
            color: var(--mc-muted);
        }

        .invoice-pager {
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

        @media (max-width: 920px) {
            .invoice-head {
                display: none;
            }

            .invoice-row {
                grid-template-columns: 1fr;
                gap: 8px;
                align-items: start;
            }

            .invoice-number::before {
                content: "Number: ";
                font-weight: 800;
                color: #64748b;
            }

            .invoice-supplier::before {
                content: "Supplier: ";
                font-weight: 800;
                color: #64748b;
            }

            .invoice-total::before {
                content: "Total: ";
                font-weight: 800;
                color: #64748b;
                float: left;
            }

            .invoice-status::before {
                content: "Status: ";
                font-weight: 800;
                color: #64748b;
            }

            .invoice-date::before {
                content: "Date: ";
                font-weight: 800;
                color: #64748b;
            }

            .invoice-total {
                text-align: left;
            }
        }
    </style>

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Fournisseurs</div>

            </div>


            <div class="searchbox">
                <asp:Button ID="btnAddSupplier" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter Supplier"
                    CausesValidation="false"
                    OnClientClick="openSupplierInvoiceWindow(0); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input  txttbsearch" placeholder="Rechercher (nom, email, téléphone…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">
                <telerik:RadListView ID="rgFournisseursFactures" runat="server"
                    DataKeyNames="Id"
                    ClientIDMode="Static"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">

                                <div>Number</div>
                                <div>Supplier</div>
                                <div style="text-align: right;">Total</div>
                                <div>Status</div>
                                <div>Date</div>
                                <div>Actions</div>
                            </div>
                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            

                            <div class="invoice-number">
                                <%# Eval("DocumentNumber") %>
                            </div>

                            <div class="invoice-supplier">
                                <%# Eval("Name") %>
                            </div>

                            <div class="invoice-total">
                                <%# Eval("Total", "{0:C2}") %>
                            </div>

                            <div class="invoice-status">
                                <%# Eval("Status") %>
                            </div>

                            <div class="invoice-date">
                                <%# Eval("DocumentDate", "{0:yyyy-MM-dd}") %>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    OnClientClick='<%# "openSupplierInvoiceWindow(" & Eval("Id") & "); return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>' />

                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucune facture trouvée.
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>
            </div>


        </div>
        

    </telerik:RadAjaxPanel>
    <telerik:RadWindow ID="rwSupplierInvoices" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        ClientIDMode="Static"
        Height="720px"
        Title="Ajouter / Modifier un facture fournisseur"
        OnClientClose="rwSupplierInvoice_OnClientClose">
    </telerik:RadWindow>

    <script type="text/javascript">
        function openSupplierInvoiceWindow(id) {
            var wnd = $find("rwSupplierInvoices");
            var url = "wbfSupplierInvoinceEdit.aspx";

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

        function rwSupplierInvoice_OnClientClose(sender, args) {
            __doPostBack("rgFournisseursFactures", "Rebind");
        }
    </script>
</asp:Content>
