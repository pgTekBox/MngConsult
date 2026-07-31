<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfProductCategory.aspx.vb" Inherits="MngConsul.wbfProductCategory" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>
    <style>

        .listview-list-head {
            display: grid;
            grid-template-columns: 70px minmax(180px, 1.5fr) minmax(120px, 1fr) minmax(120px, 1fr) 80px 60px 70px;
            gap: 12px;
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
            grid-template-columns: 70px minmax(180px, 1.5fr) minmax(120px, 1fr) minmax(120px, 1fr) 80px 60px 70px;
            gap: 12px;
            align-items: center;
            padding: 10px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
            font-size: 14px;
        }

        .listview-row:hover {
            background: #f8fafc;
        }

        /* En-tête page */
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

        .full-grid {
            height: calc(100vh - 220px);
            padding: 16px;
            box-sizing: border-box;
        }

        /* Badges */
        .field-code {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
            color: #475569;
        }

        .field-compte {
            font-size: 12px;
            color: #64748b;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .field-compte-num {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
            color: #334155;
        }

        .field-compte-nom {
            font-size: 11px;
            color: #94a3b8;
        }

        .badge-taxe {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
        }

        .badge-taxable { background: #dbeafe; color: #1e40af; }
        .badge-exempt  { background: #fef3c7; color: #92400e; }
        .badge-zero    { background: #f1f5f9; color: #64748b; }

        .badge-actif {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }
        .badge-actif-oui { background: #22c55e; }
        .badge-actif-non { background: #ef4444; }

        .btn.danger {
            border-color: #fecaca !important;
            background: #fff5f5 !important;
            color: #b91c1c !important;
        }

        .btn.danger:hover {
            background: #fee2e2 !important;
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmCategory" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
                <div class="page-sub">
                    <asp:Label ID="lblInfo" runat="server" />
                </div>
            </div>

            <div class="searchbox">
                <asp:Button ID="btnAdd" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter une catégorie"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwCategory', 'wbfProductCategoryEdit.aspx', L_EDIT_CATEGORY, L_ADD_CATEGORY); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (code, nom…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvCategories" runat="server"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div><asp:Literal ID="litColCode" runat="server" /></div>
                                <div><asp:Literal ID="litColName" runat="server" /></div>
                                <div class="col-vente"><asp:Literal ID="litColSaleAccount" runat="server" /></div>
                                <div class="col-achat"><asp:Literal ID="litColPurchaseAccount" runat="server" /></div>
                                <div class="col-taxe"><asp:Literal ID="litColTaxe" runat="server" /></div>
                                <div class="col-actif"><asp:Literal ID="litColActive" runat="server" /></div>
                                <div><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <div class="field-code">
                                <%# Eval("Code") %>
                            </div>

                            <div>
                                <div style="font-weight:600;"><%# Eval("Name") %></div>
                                <div style="font-size:12px; color:#94a3b8;"><%# Eval("Description") %></div>
                            </div>

                            <div class="col-vente">
                                <div class="field-compte">
                                    <span class="field-compte-num"><%# Eval("CompteVenteNumero") %></span>
                                    <span class="field-compte-nom"><%# Eval("CompteVenteNom") %></span>
                                </div>
                            </div>

                            <div class="col-achat">
                                <div class="field-compte">
                                    <span class="field-compte-num"><%# Eval("CompteAchatNumero") %></span>
                                    <span class="field-compte-nom"><%# Eval("CompteAchatNom") %></span>
                                </div>
                            </div>

                            <div class="col-taxe">
                                <span class='badge-taxe <%# GetTaxeBadgeClass(Eval("TaxeStatusDefault")) %>'>
                                    <%# GetTaxeLabel(Eval("TaxeStatusDefault")) %>
                                </span>
                            </div>

                            <div class="col-actif" style="text-align:center;">
                                <span class='badge-actif <%# If(CBool(Eval("Actif")), "badge-actif-oui", "badge-actif-non") %>'></span>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwCategory"", ""wbfProductCategoryEdit.aspx"", L_EDIT_CATEGORY, L_ADD_CATEGORY); return false;" %>' />
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    CommandName="DeleteCategory"
                                    CommandArgument='<%# Eval("Id") %>' />
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
        <button id="fabAdd" runat="server" type="button" class="fab-add" onclick="openRadWindow(0, 'rwCategory', 'wbfProductCategoryEdit.aspx', L_EDIT_CATEGORY, L_ADD_CATEGORY); return false;" title="">+</button>

    </telerik:RadAjaxPanel>

    <telerik:RadWindow ID="rwCategory" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        ClientIDMode="Static"
        Title="Ajouter / Modifier une catégorie"
        OnClientClose="rwCategory_OnClientClose">
    </telerik:RadWindow>

    <script src="js/RadWindows.js"></script>

    <%-- RadCodeBlock obligatoire : les blocs de rendu serveur ci-dessous sont enfants
         directs de MainContent, et le RadAjaxPanel (RadAjaxControl) modifie
         MainContent.Controls au rendu. Sans RadCodeBlock : erreur Controls collection. --%>
    <telerik:RadCodeBlock ID="rcbCategoryJs" runat="server">
    <script type="text/javascript">
        var L_ADD_CATEGORY = "<%= L("addCategoryWin") %>";
        var L_EDIT_CATEGORY = "<%= L("editCategoryWin") %>";
        function rwCategory_OnClientClose(sender, args) {
            __doPostBack("rlvCategories", "Rebind");
        }
    </script>
    </telerik:RadCodeBlock>
</asp:Content>
