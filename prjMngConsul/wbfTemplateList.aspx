<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfTemplateList.aspx.vb" Inherits="MngConsul.wbfTemplateList" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Templates d'écritures — Liste</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .badge-actif {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #ecfdf5;
            color: #059669;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #a7f3d0;
        }

        .badge-inactif {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #f1f5f9;
            color: #64748b;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #cbd5e1;
        }

        .badge-prefilled {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #eff6ff;
            color: #1e40af;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #bfdbfe;
        }

        .rw-page { height: 100%; display: flex; flex-direction: column; }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 5;
            padding: 14px;
            background: rgba(255,255,255,.9);
            border-bottom: 1px solid var(--line);
        }

        .filterbar {
            display: flex;
            gap: 10px;
            align-items: end;
            flex-wrap: wrap;
        }

        .filter-field label {
            display: block;
            font-size: 11px;
            font-weight: 700;
            color: var(--muted);
            margin-bottom: 4px;
        }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px;
            padding-bottom: 90px;
        }

        .container { max-width: 1400px; margin: 0 auto; }

        .grid-wrap {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--r-xl);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .grid-header {
            display: grid;
            grid-template-columns: 110px 1fr 160px 80px 100px 100px 80px;
            padding: 12px 14px;
            font-size: 12px;
            font-weight: 900;
            color: var(--muted);
            background: #f8fafc;
            border-bottom: 1px solid var(--line);
        }

        .grid-row {
            display: grid;
            grid-template-columns: 110px 1fr 160px 80px 100px 100px 80px;
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            align-items: center;
            gap: 6px;
        }

            .grid-row:hover { background: #f8fafc; }

        .template-code {
            font-weight: 700;
            color: #0f172a;
            cursor: pointer;
        }

        .template-name { font-weight: 600; }
        .template-desc { font-size: 12px; color: var(--muted); margin-top: 2px; }

        .empty {
            padding: 40px;
            text-align: center;
            color: var(--muted);
        }

        .actions-cell {
            display: flex;
            gap: 4px;
            justify-content: center;
        }

        .btn-icon-edit {
            width: 30px;
            height: 30px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            background-color: #fff;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%232563eb' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7'/%3E%3Cpath d='M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: center;
            background-size: 17px 17px;
            cursor: pointer;
        }

        .btn-icon-delete {
            width: 30px;
            height: 30px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            background-color: #fff;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23ef4444' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='3 6 5 6 21 6'/%3E%3Cpath d='M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6'/%3E%3Cpath d='M10 11v6'/%3E%3Cpath d='M14 11v6'/%3E%3Cpath d='M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: center;
            background-size: 17px 17px;
            cursor: pointer;
        }

        .fab-add {
            position: fixed;
            right: 22px;
            bottom: 22px;
            z-index: 2000;
        }

            .fab-add img { width: 56px; height: 56px; display: block; }

    </style>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" EnablePartialRendering="true" AsyncPostBackTimeout="300" />

        <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

        <telerik:RadAjaxManager ID="Ram1" runat="server">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="btnFilter">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpTemplates" />
                        <telerik:AjaxUpdatedControl ControlID="lblCount" />
                        <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="rpTemplates">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpTemplates" />
                        <telerik:AjaxUpdatedControl ControlID="lblCount" />
                        <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <div class="topbar">
                <div class="filterbar">
                    <div class="filter-field" style="width: 220px">
                        <label>Journal</label>
                        <telerik:RadComboBox ID="cbJournalFilter" runat="server" Width="220px"
                            DataTextField="DisplayName" DataValueField="Id">
                            <Items>
                                <telerik:RadComboBoxItem Text="(Tous)" Value="" />
                            </Items>
                        </telerik:RadComboBox>
                    </div>
                    <div class="filter-field" style="flex: 1; min-width: 200px">
                        <label>Recherche (code, libellé, description)</label>
                        <telerik:RadTextBox ID="txtSearch" runat="server" EmptyMessage="Rechercher..." Width="100%" />
                    </div>
                    <div class="filter-field">
                        <label>&nbsp;</label>
                        <asp:CheckBox ID="chkOnlyActive" runat="server" Checked="true" Text="Seulement les actifs" />
                    </div>
                    <div class="filter-field">
                        <label>&nbsp;</label>
                        <telerik:RadButton ID="btnFilter" runat="server" Text="Filtrer" />
                    </div>
                </div>
            </div>

            <div class="content">
                <div class="container">
                    <div class="grid-wrap">
                        <div class="grid-header">
                            <div>Code</div>
                            <div>Libellé / Description</div>
                            <div>Journal</div>
                            <div style="text-align: center">Lignes</div>
                            <div style="text-align: center">Pré-rempli</div>
                            <div style="text-align: center">Statut</div>
                            <div style="text-align: center">Actions</div>
                        </div>

                        <asp:Repeater ID="rpTemplates" runat="server">
                            <ItemTemplate>
                                <div class="grid-row">
                                    <div class="template-code"
                                        onclick='<%# "openTemplate(" & Eval("Id") & ")" %>'>
                                        <%# Eval("Code") %>
                                    </div>
                                    <div>
                                        <div class="template-name"><%# Eval("Libelle") %></div>
                                        <div class="template-desc"><%# Eval("Description") %></div>
                                    </div>
                                    <div>
                                        <strong><%# Eval("JournalCode") %></strong>
                                        <div style="font-size: 11px; color: var(--muted);"><%# Eval("JournalLibelle") %></div>
                                    </div>
                                    <div style="text-align: center"><%# Eval("NbLignes") %></div>
                                    <div style="text-align: center">
                                        <%# IIf(CBool(Eval("MontantsPreRemplis")), "<span class='badge-prefilled'>Oui</span>", "—") %>
                                    </div>
                                    <div style="text-align: center">
                                        <span class='<%# IIf(CBool(Eval("Actif")), "badge-actif", "badge-inactif") %>'>
                                            <%# IIf(CBool(Eval("Actif")), "Actif", "Inactif") %>
                                        </span>
                                    </div>
                                    <div class="actions-cell">
                                        <button type="button" class="btn-icon-edit" title="Modifier"
                                            onclick='<%# "openTemplate(" & Eval("Id") & "); return false;" %>'></button>
                                        <asp:LinkButton ID="btnDelete" runat="server"
                                            CssClass="btn-icon-delete"
                                            CommandName="DeleteTemplate"
                                            CommandArgument='<%# Eval("Id") %>'
                                            OnClientClick="return confirm('Supprimer ce template ?');"
                                            ToolTip="Supprimer">&nbsp;</asp:LinkButton>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                            Aucun template trouvé. Cliquez sur le bouton + pour en créer un.
                        </asp:Panel>
                    </div>

                    <div style="margin-top: 12px; padding: 14px; background: #fff; border: 1px solid var(--line); border-radius: var(--r-xl);">
                        <strong><asp:Label ID="lblCount" runat="server" Text="0" /></strong> template(s)
                    </div>
                </div>
            </div>

            <div class="fab-add">
                <a href="javascript:openTemplate(0)" title="Nouveau template">
                    <img src="Images/rondplus45.png" alt="Nouveau template" />
                </a>
            </div>

        </asp:Panel>

        <telerik:RadWindowManager ID="RadWindowManager1" runat="server" Skin="Metro"
            EnableShadow="true" Behaviors="Close, Move, Resize" />

        <script type="text/javascript">

            function openTemplate(id) {
                var oManager = GetRadWindowManager();
                var oWnd = oManager.open("wbfTemplateEdit.aspx?Id=" + id, "wndTemplate");
                oWnd.setSize(1100, 750);
                oWnd.set_modal(true);
                oWnd.set_title(id > 0 ? "Modifier le template" : "Nouveau template");
                oWnd.center();
                oWnd.add_close(function () {
                    __doPostBack('<%= btnFilter.UniqueID %>', '');
                });
                return false;
            }

            function GetRadWindowManager() {
                return $find("<%= RadWindowManager1.ClientID %>");
            }

        </script>
    </form>
</body>
</html>
