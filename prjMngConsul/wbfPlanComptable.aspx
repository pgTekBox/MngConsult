<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfPlanComptable.aspx.vb" Inherits="MngConsul.wbfPlanComptable" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>
    <style>

        .listview-list-head {
            display: grid;
            grid-template-columns: 80px minmax(200px, 1.5fr) minmax(100px, 1fr) 80px 70px 70px 60px;
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
            grid-template-columns: 80px minmax(200px, 1.5fr) minmax(100px, 1fr) 80px 70px 70px 60px;
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

        /* Ligne de classe parente (Niveau 1) */
        .row-classe {
            background: linear-gradient(135deg, rgba(37,99,235,.04), rgba(6,182,212,.03));
            font-weight: 700;
            border-bottom: 1px solid rgba(37,99,235,.12);
        }

        .row-classe:hover {
            background: linear-gradient(135deg, rgba(37,99,235,.07), rgba(6,182,212,.05));
        }

        /* Ligne de sous-classe (Niveau 2) */
        .row-sous-classe {
            padding-left: 32px;
            font-size: 13px;
            color: #334155;
        }

        /* Badges */
        .badge-type {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
            text-align: center;
        }

        .badge-bilan { background: #eff6ff; color: #1d4ed8; }
        .badge-resultat { background: #f0fdf4; color: #15803d; }

        .badge-sens {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 700;
        }
        .badge-debit { background: #fef3c7; color: #92400e; }
        .badge-credit { background: #e0e7ff; color: #3730a3; }

        .badge-actif {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }
        .badge-actif-oui { background: #22c55e; }
        .badge-actif-non { background: #ef4444; }

        .field-numero {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
            color: #475569;
        }

        .field-code {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            color: #64748b;
        }

        .field-plage {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            color: #94a3b8;
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

        .btn.danger {
            border-color: #fecaca !important;
            background: #fff5f5 !important;
            color: #b91c1c !important;
        }

        .btn.danger:hover {
            background: #fee2e2 !important;
        }

        /* Filter tabs */
        .filter-tabs {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
        }

        .filter-tab {
            cursor: pointer;
            border: 1px solid var(--mc-stroke);
            border-radius: 10px;
            padding: 6px 14px;
            background: #fff;
            color: var(--mc-muted);
            font-weight: 700;
            font-size: 12px;
        }

        .filter-tab:hover { background: #f8fafc; }
        .filter-tab.active {
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: var(--mc-text);
            border-color: rgba(37,99,235,.25);
        }


    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmPlanComptable" runat="server" EnableShadow="true">
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
                    Text="Ajouter un compte"
                    CausesValidation="false"
                    OnClientClick="openRadWindow(0, 'rwCompte', 'wbfPlanComptableEdit.aspx', L_EDIT_COMPTE, L_ADD_COMPTE); return false;" />
                <div class="search-group">
                    <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (numéro, nom…)" />
                    <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                    <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" CausesValidation="false" />
                </div>
            </div>
        </div>

        <%-- Filtres rapides --%>
        <div style="padding: 10px 16px; display:flex; gap:8px; flex-wrap:wrap; align-items:center; border-bottom:1px solid var(--mc-stroke);">
            <asp:Button ID="btnFilterAll" runat="server" CssClass="filter-tab active" Text="Tous" CausesValidation="false" />
            <asp:Button ID="btnFilterBilan" runat="server" CssClass="filter-tab" Text="Bilan" CausesValidation="false" />
            <asp:Button ID="btnFilterResultat" runat="server" CssClass="filter-tab" Text="Résultats" CausesValidation="false" />
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvComptes" runat="server"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder"
                    RenderItemWrapper="false"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div><asp:Literal ID="litColNumero" runat="server" /></div>
                                <div><asp:Literal ID="litColNom" runat="server" /></div>
                                <div class="col-classe"><asp:Literal ID="litColClasse" runat="server" /></div>
                                <div class="col-type"><asp:Literal ID="litColType" runat="server" /></div>
                                <div class="col-sens"><asp:Literal ID="litColSens" runat="server" /></div>
                                <div class="col-plage"><asp:Literal ID="litColActif" runat="server" /></div>
                                <div><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class='listview-row'>

                            <div class="field-numero">
                                <%# Eval("Numero") %>
                            </div>

                            <div>
                                <div><%# Eval("Nom") %></div>
                                <div class="field-code"><%# Eval("ClasseCode") %></div>
                            </div>

                            <div class="col-classe">
                                <%# Eval("ClasseDescription") %>
                            </div>

                            <div class="col-type">
                                <span class='badge-type <%# If(Eval("GroupeEtatFinancier").ToString() = "BILAN", "badge-bilan", "badge-resultat") %>'>
                                    <%# Eval("GroupeEtatFinancier") %>
                                </span>
                            </div>

                            <div class="col-sens">
                                <span class='badge-sens <%# If(Eval("Sens").ToString() = "D", "badge-debit", "badge-credit") %>'>
                                    <%# SensLabel(Eval("Sens")) %>
                                </span>
                            </div>

                            <div class="col-plage" style="text-align:center;">
                                <span class='badge-actif <%# If(CBool(Eval("Actif")), "badge-actif-oui", "badge-actif-non") %>'></span>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn btn-icon btn-icon-edit"
                                    Text=""
                                    OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwCompte"", ""wbfPlanComptableEdit.aspx"", L_EDIT_COMPTE, L_ADD_COMPTE); return false;" %>' />
                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    CommandName="DeleteCompte"
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
        <button id="fabAdd" runat="server" type="button" class="fab-add" onclick="openRadWindow(0, 'rwCompte', 'wbfPlanComptableEdit.aspx', L_EDIT_COMPTE, L_ADD_COMPTE); return false;" title="">+</button>

    </telerik:RadAjaxPanel>

    <telerik:RadWindow ID="rwCompte" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        ClientIDMode="Static"
        Title="Ajouter / Modifier un compte"
        OnClientClose="rwCompte_OnClientClose">
    </telerik:RadWindow>

    <script src="js/RadWindows.js"></script>

    <%-- RadCodeBlock obligatoire : blocs de rendu serveur enfants directs de
         MainContent, que le RadAjaxPanel modifie au rendu. --%>
    <telerik:RadCodeBlock ID="rcbPlanJs" runat="server">
    <script type="text/javascript">
        var L_ADD_COMPTE = "<%= L("addCompteWin") %>";
        var L_EDIT_COMPTE = "<%= L("editCompteWin") %>";
        function rwCompte_OnClientClose(sender, args) {
            __doPostBack("rlvComptes", "Rebind");
        }
    </script>
    </telerik:RadCodeBlock>
</asp:Content>
