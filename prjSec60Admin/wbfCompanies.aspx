<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfCompanies.aspx.vb"
    Inherits="prjSec60Admin.wbfCompanies" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Compagnies &amp; abonnements — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 110px minmax(160px,1fr) 110px 80px;
            gap: 16px; padding: 14px 16px; font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc; border-bottom: 1px solid var(--mc-stroke);
            position: sticky; top: 0; z-index: 0; box-sizing: border-box;
        }
        .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 110px minmax(160px,1fr) 110px 80px;
            gap: 16px; align-items: center; padding: 14px 16px;
            border-bottom: 1px solid #eef2f7; background: #fff; box-sizing: border-box;
        }
        .co-avatar {
            width: 36px; height: 36px; border-radius: 10px;
            background: linear-gradient(135deg, #0ea5e9, #2563eb);
            color: #fff; display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 14px;
        }
        .co-name { font-weight: 700; }
        .co-meta { font-size: 12px; color: #64748b; }
        .badge {
            display: inline-flex; align-items: center; padding: 4px 10px;
            border-radius: 8px; font-size: 11px; font-weight: 800; white-space: nowrap;
        }
        .badge.active   { background: rgba(22,163,74,.10);  color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.trial    { background: rgba(37,99,235,.10);  color: #2563eb; border: 1px solid rgba(37,99,235,.25); }
        .badge.cancelled{ background: rgba(220,38,38,.10);  color: #dc2626; border: 1px solid rgba(220,38,38,.25); }
        .badge.none     { background: rgba(100,116,139,.10);color: #64748b; border: 1px solid rgba(100,116,139,.25); }
        @media (max-width: 1024px) {
            .listview-list-head, .listview-row { grid-template-columns: 40px 1fr 110px 70px; gap: 10px; padding: 12px 14px; }
            .col-struct, .col-plan { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmCompanies" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwCompany" runat="server" Modal="true" VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize" DestroyOnClose="true" Width="760px" Height="680px"
                Title="Compagnie" OnClientClose="rwCompany_OnClientClose" ClientIDMode="Static">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls><telerik:AjaxUpdatedControl ControlID="rlvCompanies" /></UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls><telerik:AjaxUpdatedControl ControlID="rlvCompanies" /></UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Compagnies &amp; abonnements</div>
        </div>
        <div class="searchbox">
            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (nom, code)…" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" ToolTip="Effacer" CausesValidation="false" />
            </div>
        </div>
    </div>

    <div class="full-grid">
        <div class="list-shell">
            <telerik:RadListView ID="rlvCompanies" runat="server" Skin="Metro" DataKeyNames="CompanyGUID"
                AllowPaging="false" ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">

                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Compagnie</div>
                            <div class="col-struct">Structure</div>
                            <div class="col-plan">Forfait</div>
                            <div>Abonnement</div>
                            <div>Actions</div>
                        </div>
                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                    </div>
                </LayoutTemplate>

                <ItemTemplate>
                    <div class="listview-row">
                        <div><div class="co-avatar"><%# GetInitials(Eval("Name")) %></div></div>
                        <div>
                            <div class="co-name"><%# Eval("Name") %></div>
                            <div class="co-meta">Code : <%# IIf(Eval("CompanyCode") Is DBNull.Value OrElse Eval("CompanyCode").ToString()="", "—", Eval("CompanyCode")) %></div>
                        </div>
                        <div class="co-meta col-struct">
                            <%# IIf(Eval("Structure") Is DBNull.Value OrElse Eval("Structure").ToString()="", "—", Eval("Structure")) %>
                        </div>
                        <div class="co-meta col-plan">
                            <%# IIf(Eval("PlanCode") Is DBNull.Value, "—", Eval("PlanCode")) %>
                            <%# IIf(Eval("PlanName") Is DBNull.Value OrElse Eval("PlanName").ToString()="", "", " — " & Eval("PlanName").ToString()) %>
                        </div>
                        <div>
                            <span class='<%# "badge " & GetStatusClass(Eval("SubStatus")) %>'><%# GetStatusLabel(Eval("SubStatus")) %></span>
                        </div>
                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server" CssClass="btn btn-icon btn-icon-edit" Text="" ToolTip="Gérer"
                                CausesValidation="false"
                                OnClientClick='<%# "openCompanyWindow(&#39;" & Eval("CompanyGUID").ToString() & "&#39;); return false;" %>' />
                        </div>
                    </div>
                </ItemTemplate>

                <EmptyDataTemplate><div class="listview-empty">Aucune compagnie trouvée.</div></EmptyDataTemplate>
            </telerik:RadListView>
        </div>
    </div>

    <script type="text/javascript">
        function openCompanyWindow(guid) {
            var win = $find('rwCompany');
            if (!win) return;
            win.setUrl('wbfCompanyEdit.aspx?guid=' + encodeURIComponent(guid));
            win.show(); win.center(); win.setActive(true);
        }
        function rwCompany_OnClientClose(sender, args) {
            var m = $find('Ram1'); if (m) { m.ajaxRequest('refreshgrid'); }
        }
    </script>
</asp:Content>
