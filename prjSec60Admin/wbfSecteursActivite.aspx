<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfSecteursActivite.aspx.vb"
    Inherits="prjSec60Admin.wbfSecteursActivite" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Secteurs d'activité — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .listview-list-head {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 200px 100px;
            gap: 16px; padding: 14px 16px;
            font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky; top: 0; z-index: 0;
            box-sizing: border-box;
        }
        .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(220px, 1fr) 200px 100px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .met-icon {
            width: 36px; height: 36px;
            border-radius: 10px;
            background: linear-gradient(135deg, #1B4F9C, #3DDCCB);
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 13px;
        }
        .met-name { font-weight: 700; }
        .met-meta { font-size: 12px; color: #64748b; }

        .met-msg {
            margin: 0 0 12px; padding: 10px 12px; border-radius: 12px;
            font-weight: 700; font-size: 13px;
            border: 1px solid rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: #dc2626;
        }

        @media (max-width: 1024px) {
            .listview-list-head, .listview-row {
                grid-template-columns: 40px 1fr 140px 90px;
                gap: 10px; padding: 12px 14px;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmSecteurs" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwSecteur" runat="server"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="600px"
                Height="360px"
                Title="Secteur d'activité"
                OnClientClose="rwSecteur_OnClientClose" ClientIDMode="Static">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <telerik:RadAjaxManager ID="Ram1" runat="server" ClientIDMode="Static">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvSecteurs" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvSecteurs" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Secteurs d'activité</div>
        </div>

        <div class="searchbox">
            <asp:Button ID="btnAddSecteur" runat="server"
                CssClass="btn btnAddRow"
                Text="+ Ajouter un secteur"
                CausesValidation="false"
                OnClientClick="openSecteurWindow(0); return false;" />

            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server"
                    CssClass="input txttbsearch"
                    placeholder="Rechercher un secteur…" />

                <asp:Button ID="btnSearch" runat="server"
                    CssClass="btn btn-icon btn-icon-search" Text="" />

                <asp:Button ID="btnClear" runat="server"
                    CssClass="btn btn-icon btn-icon-clear"
                    Text="" ToolTip="Effacer"
                    CausesValidation="false" />
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlMsg" runat="server" Visible="false" CssClass="met-msg">
        <asp:Literal ID="litMsg" runat="server" Mode="Encode" />
    </asp:Panel>

    <div class="full-grid">
        <div class="list-shell">

            <telerik:RadListView ID="rlvSecteurs" runat="server"
                Skin="Metro"
                DataKeyNames="Id"
                AllowPaging="false"
                ItemPlaceholderID="itemPlaceholder"
                ClientIDMode="Static">

                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Secteur</div>
                            <div>Métiers</div>
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
                            <div class="met-icon"><%# GetInitials(Eval("Nom")) %></div>
                        </div>

                        <div class="met-name"><%# Server.HtmlEncode(S(Eval("Nom"))) %></div>

                        <div class="met-meta"><%# GetMetiers(Eval("NbMetiers"), Eval("NbActifs")) %></div>

                        <div class="listview-actions">
                            <asp:Button ID="btnEdit" runat="server"
                                CssClass="btn btn-icon btn-icon-edit"
                                Text="" ToolTip="Modifier"
                                CausesValidation="false"
                                OnClientClick='<%# "openSecteurWindow(" & Eval("Id") & "); return false;" %>' />

                            <asp:Button ID="btnDelete" runat="server"
                                CssClass="btn btn-icon btn-icon-delete"
                                Text="" ToolTip="Supprimer"
                                CommandName="DeleteSecteur"
                                CommandArgument='<%# Eval("Id") %>'
                                OnClientClick="if (!confirm('Supprimer ce secteur ? Il ne doit plus être porté par aucun métier.')) { return false; }"
                                CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>

                <EmptyDataTemplate>
                    <div class="listview-empty">
                        Aucun secteur trouvé.
                    </div>
                </EmptyDataTemplate>

            </telerik:RadListView>

        </div>
    </div>

    <script type="text/javascript">

        function openSecteurWindow(id) {
            var win = $find('rwSecteur');
            if (!win) return;
            win.setUrl('wbfSecteurActiviteEdit.aspx?id=' + id);
            win.show();
            win.center();
            win.setActive(true);
        }

        function rwSecteur_OnClientClose(sender, args) {
            var ajaxManager = $find('Ram1');
            if (ajaxManager) {
                ajaxManager.ajaxRequest('refreshgrid');
            }
        }

    </script>
</asp:Content>
