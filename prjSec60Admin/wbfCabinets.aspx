<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfCabinets.aspx.vb"
    Inherits="prjSec60Admin.wbfCabinets" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Cabinets certifiés — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 150px 90px minmax(180px, 1fr) 90px 100px;
            gap: 16px; padding: 14px 16px;
            font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky; top: 0; z-index: 0;
            box-sizing: border-box;
        }
        .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 150px 90px minmax(180px, 1fr) 90px 100px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .cab-icon {
            width: 36px; height: 36px;
            border-radius: 10px;
            background: linear-gradient(135deg, #1B4F9C, #3DDCCB);
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 13px;
        }
        .cab-name { font-weight: 700; }
        .cab-meta { font-size: 12px; color: #64748b; }
        .cab-meta a { color: #2563eb; text-decoration: none; }
        .cab-meta a:hover { text-decoration: underline; }

        .badge {
            display: inline-flex; align-items: center;
            padding: 4px 10px; border-radius: 8px;
            font-size: 11px; font-weight: 800; white-space: nowrap;
            margin: 2px 4px 2px 0;
        }
        .badge.active   { background: rgba(22,163,74,.10);  color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.inactive { background: rgba(220,38,38,.10);  color: #dc2626; border: 1px solid rgba(220,38,38,.25); }
        .badge.lang     { background: rgba(245,158,11,.12); color: #92400e; border: 1px solid rgba(245,158,11,.30); }
        .badge.spec     { background: rgba(37,99,235,.10);  color: #2563eb; border: 1px solid rgba(37,99,235,.25); }

        @media (max-width: 1024px) {
            .listview-list-head, .listview-row {
                grid-template-columns: 40px 1fr 110px 80px 90px;
                gap: 10px; padding: 12px 14px;
            }
            .col-lang, .col-spec { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmCabinets" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwCabinet" runat="server"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="760px"
                Height="700px"
                Title="Cabinet certifié"
                OnClientClose="rwCabinet_OnClientClose" ClientIDMode="Static">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvCabinets" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvCabinets" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Cabinets certifiés</div>
        </div>

        <div class="searchbox">
            <asp:Button ID="btnAddCabinet" runat="server"
                CssClass="btn btnAddRow"
                Text="+ Ajouter un cabinet"
                CausesValidation="false"
                OnClientClick="openCabinetWindow(0); return false;" />

            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server"
                    CssClass="input txttbsearch"
                    placeholder="Rechercher (nom, responsable, ville)…" />

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

            <telerik:RadListView ID="rlvCabinets" runat="server"
                Skin="Metro"
                DataKeyNames="Id"
                AllowPaging="false"
                ItemPlaceholderID="itemPlaceholder"
                ClientIDMode="Static">

                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Cabinet</div>
                            <div>Ville</div>
                            <div class="col-lang">Langues</div>
                            <div class="col-spec">Spécialités</div>
                            <div>Statut</div>
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
                            <div class="cab-icon"><%# GetInitials(Eval("Nom")) %></div>
                        </div>

                        <div>
                            <div class="cab-name"><%# Server.HtmlEncode(S(Eval("Nom"))) %></div>
                            <div class="cab-meta"><%# GetMeta(Eval("Responsable"), Eval("Courriel"), Eval("Telephone"), Eval("CertifieDepuis")) %></div>
                        </div>

                        <div class="cab-meta"><%# GetLieu(Eval("Ville"), Eval("Province")) %></div>

                        <div class="col-lang"><%# GetLangues(Eval("Langues")) %></div>

                        <div class="col-spec"><%# GetSpecialites(Eval("Specialites")) %></div>

                        <div>
                            <span class='<%# "badge " & If(CBool(Eval("IsActive")), "active", "inactive") %>'>
                                <%# If(CBool(Eval("IsActive")), "Actif", "Inactif") %>
                            </span>
                        </div>

                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server"
                                CssClass="btn btn-icon btn-icon-edit"
                                Text="" ToolTip="Modifier"
                                CausesValidation="false"
                                OnClientClick='<%# "openCabinetWindow(" & Eval("Id") & "); return false;" %>' />

                            <asp:Button ID="btnDelete" runat="server"
                                CssClass="btn btn-icon btn-icon-delete"
                                Text="" ToolTip="Supprimer"
                                CommandName="DeleteCabinet"
                                CommandArgument='<%# Eval("Id") %>'
                                OnClientClick="if (!confirm('Supprimer ce cabinet de l\'annuaire ? Pour seulement le cacher, mettez-le Inactif.')) { return false; }"
                                CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>

                <EmptyDataTemplate>
                    <div class="listview-empty">
                        Aucun cabinet trouvé.
                    </div>
                </EmptyDataTemplate>

            </telerik:RadListView>

        </div>
    </div>

    <script type="text/javascript">

        function openCabinetWindow(id) {
            var win = $find('rwCabinet');
            if (!win) return;
            win.setUrl('wbfCabinetEdit.aspx?id=' + id);
            win.show();
            win.center();
            win.setActive(true);
        }

        function rwCabinet_OnClientClose(sender, args) {
            var ajaxManager = $find('Ram1');
            if (ajaxManager) {
                ajaxManager.ajaxRequest('refreshgrid');
            }
        }

    </script>
</asp:Content>
