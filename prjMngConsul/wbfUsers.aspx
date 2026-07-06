<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfUsers.aspx.vb"
    Inherits="MngConsul.wbfUsers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Utilisateurs — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) minmax(180px, 1fr) 100px 90px 130px 100px;
            gap: 16px; padding: 14px 16px;
            font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky; top: 0; z-index: 0;
            box-sizing: border-box;
        }
        .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) minmax(180px, 1fr) 100px 90px 130px 100px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .user-avatar {
            width: 36px; height: 36px;
            border-radius: 50%;
            background: linear-gradient(135deg, #2563eb, #06b6d4);
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 14px;
        }
        .user-name { font-weight: 700; }
        .user-email { color: #475569; font-size: 13px; }
        .user-meta { font-size: 12px; color: #64748b; }

        .badge {
            display: inline-flex; align-items: center;
            padding: 4px 10px; border-radius: 8px;
            font-size: 11px; font-weight: 800; white-space: nowrap;
        }
        .badge.admin   { background: rgba(37,99,235,.10);  color: #2563eb; border: 1px solid rgba(37,99,235,.25); }
        .badge.user    { background: rgba(100,116,139,.10); color: #64748b; border: 1px solid rgba(100,116,139,.25); }
        .badge.active  { background: rgba(22,163,74,.10);  color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.inactive { background: rgba(220,38,38,.10); color: #dc2626; border: 1px solid rgba(220,38,38,.25); }

        @media (max-width: 1024px) {
            .listview-list-head, .listview-row {
                grid-template-columns: 40px 1fr 90px 80px 90px;
                gap: 10px; padding: 12px 14px;
            }
            .col-email, .col-lastlogin { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmUsers" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwUser"  runat="server"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="640px"
                Height="600px"
                Title="Utilisateur"
                OnClientClose="rwUser_OnClientClose" ClientIDMode="Static">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1"  runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvUsers" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvUsers" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Utilisateurs</div>
        </div>

        <div class="searchbox">
            <asp:Button ID="btnAddUser" runat="server"
                CssClass="btn btnAddRow"
                Text="+ Ajouter un utilisateur"
                CausesValidation="false"
                OnClientClick="openUserWindow(0); return false;" />

            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server"
                    CssClass="input txttbsearch"
                    placeholder="Rechercher (nom, courriel)…" />

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

            <telerik:RadListView ID="rlvUsers" runat="server"
                Skin="Metro"
                DataKeyNames="Id"
                AllowPaging="false"
                ItemPlaceholderID="itemPlaceholder"
                ClientIDMode="Static">

                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Nom</div>
                            <div class="col-email">Courriel</div>
                            <div>Rôle</div>
                            <div>Statut</div>
                            <div class="col-lastlogin">Dernière conn.</div>
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
                            <div class="user-avatar">
                                <%# GetInitials(Eval("FirstName"), Eval("LastName"), Eval("Email")) %>
                            </div>
                        </div>

                        <div>
                            <div class="user-name">
                                <%# If(String.IsNullOrEmpty(Eval("FullName").ToString().Trim()), Eval("Email"), Eval("FullName")) %>
                            </div>
                            <div class="user-meta">ID: <%# Eval("Id") %></div>
                        </div>

                        <div class="user-email col-email">
                            <%# Eval("Email") %>
                        </div>

                        <div>
                            <span class='<%# "badge " & If(CBool(Eval("IsAdmin")), "admin", "user") %>'>
                                <%# If(CBool(Eval("IsAdmin")), "Admin", "Utilisateur") %>
                            </span>
                        </div>

                        <div>
                            <span class='<%# "badge " & If(CBool(Eval("IsActive")), "active", "inactive") %>'>
                                <%# If(CBool(Eval("IsActive")), "Actif", "Inactif") %>
                            </span>
                        </div>

                        <div class="user-meta col-lastlogin">
                            <%# If(Eval("LastLoginOn") Is DBNull.Value, "—", CDate(Eval("LastLoginOn")).ToString("yyyy-MM-dd HH:mm")) %>
                        </div>

                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server"
                                CssClass="btn btn-icon btn-icon-edit"
                                Text="" ToolTip="Modifier"
                                CausesValidation="false"
                                OnClientClick='<%# "openUserWindow(" & Eval("Id") & "); return false;" %>' />

                            <asp:Button ID="btnDelete" runat="server"
                                CssClass="btn btn-icon btn-icon-delete"
                                Text="" ToolTip="Supprimer"
                                CommandName="DeleteUser"
                                CommandArgument='<%# Eval("Id") %>'
                                OnClientClick="return confirm('Supprimer cet utilisateur ?');"
                                CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>

                <EmptyDataTemplate>
                    <div class="listview-empty">
                        Aucun utilisateur trouvé.
                    </div>
                </EmptyDataTemplate>

            </telerik:RadListView>

        </div>
    </div>

    <script type="text/javascript">

        function openUserWindow(id) {
            var win = $find('rwUser');
            if (!win) return;
            win.setUrl('wbfUserEdit.aspx?id=' + id);
            win.show();
            win.center();
            win.setActive(true);
        }

        function rwUser_OnClientClose(sender, args) {
            var ajaxManager = $find('Ram1');
            if (ajaxManager) {
                ajaxManager.ajaxRequest('refreshgrid');
            }
        }

    </script>
</asp:Content>
