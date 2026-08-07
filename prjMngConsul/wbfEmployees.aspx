<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfEmployees.aspx.vb"
    Inherits="MngConsul.wbfEmployees" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <style>
        .listview-list-head, .listview-row {
            display: grid;
            grid-template-columns: minmax(220px, 1.5fr) minmax(170px, 1fr) minmax(190px, 1fr) 90px 210px;
            gap: 16px; align-items: center; box-sizing: border-box;
        }
        .listview-list-head {
            padding: 14px 16px; font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc; border-bottom: 1px solid var(--mc-stroke); position: sticky; top: 0; z-index: 0;
        }
        .listview-row { padding: 14px 16px; border-bottom: 1px solid #eef2f7; background: #fff; }
        .colh-actions { text-align: right; }
        .emp-id { display: flex; align-items: center; gap: 10px; }
        .emp-dot { width: 30px; height: 30px; border-radius: 9px; flex: 0 0 auto; box-shadow: inset 0 0 0 1px rgba(0,0,0,.08); }
        .emp-name { font-weight: 800; font-size: 14px; }
        .emp-meta { font-size: 12px; color: #64748b; }
        .emp-mail { font-family: ui-monospace, Consolas, monospace; font-size: 13px; color: #0f172a; }
        .emp-none { color: #94a3b8; font-style: italic; }
        .pw-key { margin-left: 6px; }
        .badge { display: inline-flex; align-items: center; padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 800; white-space: nowrap; }
        .badge.on  { background: rgba(22,163,74,.10); color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.off { background: rgba(100,116,139,.10); color: #64748b; border: 1px solid rgba(100,116,139,.25); }
        .listview-actions { display: flex; gap: 8px; flex-wrap: wrap; justify-content: flex-end; }
        .btn-mini { display: inline-flex; align-items: center; gap: 6px; padding: 6px 11px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer; border: 1px solid var(--mc-stroke); background: #fff; color: #0f172a; }
        .btn-mini:hover { background: #f8fafc; }
        .btn-mini.primary { background: #2563eb; border-color: #2563eb; color: #fff; }
        .btn-mini.warn { color: #b45309; border-color: rgba(217,119,6,.35); }
        .btn-mini.danger { color: #dc2626; border-color: rgba(220,38,38,.35); }
        @media (max-width: 1024px) {
            .listview-list-head, .listview-row { grid-template-columns: minmax(160px,1.4fr) 90px 200px; }
            .col-ext, .col-box { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmEmployees" runat="server" EnableShadow="true"></telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls><telerik:AjaxUpdatedControl ControlID="rlvEmployees" /></UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls><telerik:AjaxUpdatedControl ControlID="rlvEmployees" /></UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
        </div>
        <div class="searchbox">
            <asp:Button ID="btnAddEmployee" runat="server" CssClass="btn btnAddRow" Text="Ajouter" CausesValidation="false"
                OnClientClick="openNewEmployeeWindow(); return false;" />
            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher…" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" ToolTip="Effacer" CausesValidation="false" />
            </div>
        </div>
    </div>

    <div class="full-grid">
        <div class="list-shell">
            <telerik:RadListView ID="rlvEmployees" runat="server" Skin="Metro" DataKeyNames="Id"
                AllowPaging="false" ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">
                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div><asp:Literal ID="litColName" runat="server" /></div>
                            <div class="col-ext"><asp:Literal ID="litColExt" runat="server" /></div>
                            <div class="col-box"><asp:Literal ID="litColBox" runat="server" /></div>
                            <div><asp:Literal ID="litColState" runat="server" /></div>
                            <div class="colh-actions"><asp:Literal ID="litColAction" runat="server" /></div>
                        </div>
                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <div class="listview-row">
                        <div class="emp-id">
                            <span class="emp-dot" style='<%# "background:" & Eval("ColorHex") %>'></span>
                            <span>
                                <span class="emp-name"><%# Server.HtmlEncode(Val_(Eval("FullName"))) %></span><br />
                                <span class="emp-meta"><%# Server.HtmlEncode(Val_(Eval("EmployeeNumber"))) %><%# IIf(Val_(Eval("JobTitle"))<>"", " · " & Server.HtmlEncode(Val_(Eval("JobTitle"))), "") %></span>
                            </span>
                        </div>
                        <div class="col-ext emp-meta"><%# IIf(Val_(Eval("Email"))="", "—", Server.HtmlEncode(Val_(Eval("Email")))) %></div>
                        <div class="col-box">
                            <span class='<%# IIf(CBool(Eval("HasMailbox")), "emp-mail", "emp-mail emp-none") %>'><%# IIf(CBool(Eval("HasMailbox")), Server.HtmlEncode(Val_(Eval("Sec60Email"))), "aucune") %></span>
                            <%# IIf(CBool(Eval("HasPassword")), "<span class=""pw-key"" title=""Mot de passe défini"">🔑</span>", "") %>
                        </div>
                        <div>
                            <span class='<%# "badge " & IIf(CBool(Eval("Active")), "on", "off") %>'><%# IIf(CBool(Eval("Active")), L("stActive"), L("stInactive")) %></span>
                        </div>
                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server" CssClass="btn-mini" Text="✎" ToolTip='<%# L("edit") %>' CausesValidation="false"
                                OnClientClick='<%# "openRadWindow(" & Eval("Id") & ", ""rwEmployee"", ""wbfEmployeeEdit.aspx"", L_EDIT_EMP, L_ADD_EMP); return false;" %>' />

                            <asp:Button ID="btnAssign" runat="server" CssClass="btn-mini primary" Text='<%# L("assignBox") %>'
                                CommandName="AssignMailbox" CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                Visible='<%# Not CBool(Eval("HasMailbox")) %>' />

                            <asp:Button ID="btnReset" runat="server" CssClass="btn-mini warn" Text='<%# L("resetPwd") %>'
                                CommandName="ResetPwd" CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                Visible='<%# CBool(Eval("HasMailbox")) %>' />

                            <asp:Button ID="btnDelete" runat="server" CssClass="btn-mini danger" Text="🗑"
                                ToolTip='<%# L("delete") %>' CommandName="DeleteEmployee" CommandArgument='<%# Eval("Id") %>'
                                CausesValidation="false" OnClientClick='<%# "return confirm(L_DEL_CONFIRM);" %>' />
                        </div>
                    </div>
                </ItemTemplate>
                <EmptyDataTemplate>
                    <div class="listview-empty"><asp:Literal ID="litEmpty" runat="server" /></div>
                </EmptyDataTemplate>
            </telerik:RadListView>
        </div>
    </div>

    <telerik:RadWindow ID="rwEmployee" runat="server" Modal="true" VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize" DestroyOnClose="true" Width="720px" Height="680px"
        Title="Employé" OnClientClose="rwEmployee_OnClientClose" ClientIDMode="Static">
    </telerik:RadWindow>
    <script src="js/RadWindows.js"></script>

    <telerik:RadCodeBlock ID="rcbEmpJs" runat="server">
        <script type="text/javascript">
            var L_ADD_EMP = "<%= L("addEmpWin") %>";
            var L_EDIT_EMP = "<%= L("editEmpWin") %>";
            var L_DEL_CONFIRM = "<%= L("delConfirm") %>";
            function openNewEmployeeWindow() {
                openRadWindow(0, "rwEmployee", "wbfEmployeeEdit.aspx", L_ADD_EMP, L_ADD_EMP);
            }
            function rwEmployee_OnClientClose(sender, args) {
                var m = $find("Ram1"); if (m) { m.ajaxRequest("refreshgrid"); }
            }
        </script>
    </telerik:RadCodeBlock>
</asp:Content>
