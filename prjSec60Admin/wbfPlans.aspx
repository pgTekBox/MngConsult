<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfPlans.aspx.vb"
    Inherits="prjSec60Admin.wbfPlans" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Forfaits — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 50px minmax(200px, 1fr) 140px 110px 90px 80px 100px;
            gap: 16px; padding: 14px 16px;
            font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky; top: 0; z-index: 0;
            box-sizing: border-box;
        }
        .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(200px, 1fr) 140px 110px 90px 80px 100px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .plan-icon {
            width: 36px; height: 36px;
            border-radius: 10px;
            background: linear-gradient(135deg, #7c3aed, #2563eb);
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 14px;
        }
        .plan-name { font-weight: 700; }
        .plan-meta { font-size: 12px; color: #64748b; }
        .plan-price { font-weight: 800; }
        .plan-price small { font-weight: 600; color: #64748b; }

        .badge {
            display: inline-flex; align-items: center;
            padding: 4px 10px; border-radius: 8px;
            font-size: 11px; font-weight: 800; white-space: nowrap;
        }
        .badge.reco     { background: rgba(124,58,237,.10); color: #7c3aed; border: 1px solid rgba(124,58,237,.25); }
        .badge.active   { background: rgba(22,163,74,.10);  color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.inactive { background: rgba(220,38,38,.10);  color: #dc2626; border: 1px solid rgba(220,38,38,.25); }
        .badge.cycle    { background: rgba(37,99,235,.10);  color: #2563eb; border: 1px solid rgba(37,99,235,.25); }

        @media (max-width: 1024px) {
            .listview-list-head, .listview-row {
                grid-template-columns: 40px 1fr 110px 80px 90px;
                gap: 10px; padding: 12px 14px;
            }
            .col-cycle, .col-order { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmPlans" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwPlan" runat="server"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="760px"
                Height="680px"
                Title="Forfait"
                OnClientClose="rwPlan_OnClientClose" ClientIDMode="Static">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvPlans" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvPlans" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Forfaits</div>
        </div>

        <div class="searchbox">
            <asp:Button ID="btnAddPlan" runat="server"
                CssClass="btn btnAddRow"
                Text="+ Ajouter un forfait"
                CausesValidation="false"
                OnClientClick="openPlanWindow(0); return false;" />

            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server"
                    CssClass="input txttbsearch"
                    placeholder="Rechercher (code, nom)…" />

                <asp:Button ID="btnSearch" runat="server"
                    CssClass="btn btn-icon btn-icon-search" Text="" />

                <asp:Button ID="btnClear" runat="server"
                    CssClass="btn btn-icon btn-icon-clear"
                    Text="" ToolTip="Effacer"
                    CausesValidation="false" />
            </div>
        </div>
    </div>

    <div class="full-grid">
        <div class="list-shell">

            <telerik:RadListView ID="rlvPlans" runat="server"
                Skin="Metro"
                DataKeyNames="Id"
                AllowPaging="false"
                ItemPlaceholderID="itemPlaceholder"
                ClientIDMode="Static">

                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Forfait</div>
                            <div>Prix</div>
                            <div class="col-cycle">Cycle</div>
                            <div>Statut</div>
                            <div class="col-order">Ordre</div>
                            <div>Actions</div>
                        </div>

                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                    </div>
                </LayoutTemplate>

                <ItemTemplate>
                    <div class="listview-row">
                        <div>
                            <div class="plan-icon">
                                <%# GetInitials(Eval("Name"), Eval("Code")) %>
                            </div>
                        </div>

                        <div>
                            <div class="plan-name">
                                <%# Eval("Name") %>
                                <%# If(CBool(Eval("IsRecommended")), " <span class='badge reco'>Recommandé</span>", "") %>
                            </div>
                            <div class="plan-meta">
                                Code : <%# Eval("Code") %><%# If(Eval("Tagline") Is DBNull.Value OrElse Eval("Tagline").ToString() = "", "", " — " & Eval("Tagline").ToString()) %>
                            </div>
                        </div>

                        <div class="plan-price">
                            <%# FormatAmount(Eval("Amount")) %> <small><%# Eval("Currency") %></small>
                        </div>

                        <div class="col-cycle">
                            <span class="badge cycle"><%# GetCycleLabel(Eval("BillingCycle")) %></span>
                        </div>

                        <div>
                            <span class='<%# "badge " & If(CBool(Eval("IsActive")), "active", "inactive") %>'>
                                <%# If(CBool(Eval("IsActive")), "Actif", "Inactif") %>
                            </span>
                        </div>

                        <div class="plan-meta col-order">
                            <%# Eval("DisplayOrder") %>
                        </div>

                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server"
                                CssClass="btn btn-icon btn-icon-edit"
                                Text="" ToolTip="Modifier"
                                CausesValidation="false"
                                OnClientClick='<%# "openPlanWindow(" & Eval("Id") & "); return false;" %>' />

                            <asp:Button ID="btnDelete" runat="server"
                                CssClass="btn btn-icon btn-icon-delete"
                                Text="" ToolTip="Supprimer"
                                CommandName="DeletePlan"
                                CommandArgument='<%# Eval("Id") %>'
                                OnClientClick="return confirm('Supprimer ce forfait ?');"
                                CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>

                <EmptyDataTemplate>
                    <div class="listview-empty">
                        Aucun forfait trouvé.
                    </div>
                </EmptyDataTemplate>

            </telerik:RadListView>

        </div>
    </div>

    <script type="text/javascript">

        function openPlanWindow(id) {
            var win = $find('rwPlan');
            if (!win) return;
            win.setUrl('wbfPlanEdit.aspx?id=' + id);
            win.show();
            win.center();
            win.setActive(true);
        }

        function rwPlan_OnClientClose(sender, args) {
            var ajaxManager = $find('Ram1');
            if (ajaxManager) {
                ajaxManager.ajaxRequest('refreshgrid');
            }
        }

    </script>
</asp:Content>
