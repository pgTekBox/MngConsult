<%@ Page Title="" Language="vb" AutoEventWireup="false" 
    MasterPageFile="~/Site.Master" CodeBehind="wbfProducts.aspx.vb" Inherits="MngConsul.wbfProducts" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Produits — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>
    <style>

        .listview-list-head {
            display: grid;
            grid-template-columns: minmax(200px, 1.5fr) minmax(100px, 1fr) 90px 80px 70px 60px 70px;
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
            grid-template-columns: minmax(200px, 1.5fr) minmax(100px, 1fr) 90px 80px 70px 60px 70px;
            gap: 12px;
            align-items: center;
            padding: 10px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
            font-size: 14px;
        }

        .listview-row:hover { background: #f8fafc; }

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

        .page-title { font-weight: 900; font-size: 18px; line-height: 1.2; }

        .page-sub { color: var(--mc-muted); font-size: 13px; margin-top: 4px; }

        .full-grid {
            height: calc(100vh - 260px);
            padding: 16px;
            box-sizing: border-box;
        }

        .field-prix {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
            color: #0f172a;
            text-align: right;
        }

        .field-cat {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
            background: #f1f5f9;
            color: #475569;
            border: 1px solid #e2e8f0;
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
        .btn.danger:hover { background: #fee2e2 !important; }

        /* Filtre catégorie */
        .filter-bar {
            padding: 10px 16px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: center;
            border-bottom: 1px solid var(--mc-stroke);
            font-size: 13px;
        }
        .filter-bar label {
            font-weight: 700;
            color: var(--mc-muted);
            font-size: 12px;
        }

        /* ========================= TABLETTE ========================= */
        @media (min-width: 769px) and (max-width: 1024px) {
            .listview-list-head,
            .listview-row {
                grid-template-columns: minmax(160px, 1.5fr) minmax(80px, 1fr) 80px 70px 60px 50px 60px;
                gap: 8px;
                padding: 10px 12px;
            }
        }

        /* ========================= MOBILE ========================= */
        @media (max-width: 768px) {
            .listview-list-head { display: none; }
            .listview-row {
                grid-template-columns: 1fr 80px 60px;
                gap: 8px;
                padding: 12px 14px;
            }
            .col-cat, .col-taxe, .col-actif, .col-qty { display: none; }
        }

        @media (max-width: 480px) {
            .listview-row {
                grid-template-columns: 1fr 70px 40px;
                gap: 6px;
                padding: 10px;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmProducts" runat="server" EnableShadow="true" />

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Produits et services</div>
                <div class="page-sub">
                    <asp:Label ID="lblInfo" runat="server" />
                </div>
            </div>

            <div class="searchbox">
                <asp:Button ID="btnConnectSquare" runat="server"
                    CssClass="btn"
                    Text="Connecter Square"
                    CausesValidation="false"
                    OnClientClick="window.location.href='SquareOAuth.aspx'; return false;" />
                <asp:Button ID="btnExportSquare" runat="server"
                    CssClass="btn"
                    Text="Exporter vers Square"
                    CausesValidation="false"/>
                    <%--OnClientClick="return confirm('Exporter les produits/services actifs vers Square ?');" />--%>
                <asp:Button ID="btnImportSquare" runat="server"
                    CssClass="btn"
                    Text="Importer depuis Square"
                    CausesValidation="false"/>
                <asp:Button ID="btnAdd" runat="server"
                    CssClass="btn btnAddRow"
                    Text="Ajouter un produit"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwProduct', 'wbfProductEdit.aspx', 'Modifier un produit', 'Ajouter un produit'); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (nom, description…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <%-- Filtre par catégorie --%>
        <div class="filter-bar">
            <label>Catégorie :</label>
            <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlFilterCat" runat="server"
                DefaultMessage="Toutes" DropDownHeight="200px" AutoPostBack="true"
                OnSelectedIndexChanged="rddlFilterCat_SelectedIndexChanged"
                Width="260px">
            </telerik:RadDropDownList>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvProducts" runat="server"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div>Produit</div>
                                <div class="col-cat">Catégorie</div>
                                <div>Prix</div>
                                <div class="col-qty">Qté déf.</div>
                                <div class="col-taxe">Taxe</div>
                                <div class="col-actif">Actif</div>
                                <div>Action</div>
                            </div>
                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server" />
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            <div>
                                <div style="font-weight:700;"><%# Eval("Name") %></div>
                                <div style="font-size:12px; color:#94a3b8; margin-top:2px;"><%# TruncateText(Eval("Description"), 60) %></div>
                            </div>

                            <div class="col-cat">
                                <span class="field-cat"><%# Eval("CategoryName") %></span>
                            </div>

                            <div class="field-prix">
                                <%# FormatPrix(Eval("Prix")) %>
                            </div>

                            <div class="col-qty" style="text-align:center;">
                                <%# FormatQty(Eval("DefaultQty")) %>
                            </div>

                            <div class="col-taxe">
                                <span class='badge-taxe <%# GetTaxeBadgeClass(Eval("TaxeStatusId")) %>'>
                                    <%# GetTaxeLabel(Eval("TaxeStatusId")) %>
                                </span>
                            </div>

                            <div class="col-actif" style="text-align:center;">
                                <span class='badge-actif <%# If(IsActif(Eval("Actif")), "badge-actif-oui", "badge-actif-non") %>'></span>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwProduct"", ""wbfProductEdit.aspx"", ""Modifier un produit"", ""Ajouter un produit""); return false;" %>' />
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    CommandName="DeleteProduct"
                                    CommandArgument='<%# Eval("Id") %>' />
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucun produit trouvé.
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>

            </div>
        </div>

        <%-- FAB mobile --%>
        <button class="fab-add" onclick="openRadWindow(0, 'rwProduct', 'wbfProductEdit.aspx', 'Modifier un produit', 'Ajouter un produit'); return false;" title="Ajouter un produit">+</button>

    </telerik:RadAjaxPanel>

    <telerik:RadWindow ID="rwProduct" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        ClientIDMode="Static"
        Title="Ajouter / Modifier un produit"
        OnClientClose="rwProduct_OnClientClose">
    </telerik:RadWindow>

    <script src="js/RadWindows.js"></script>

    <script type="text/javascript">
        function rwProduct_OnClientClose(sender, args) {
            __doPostBack("rlvProducts", "Rebind");
        }
    </script>
</asp:Content>
