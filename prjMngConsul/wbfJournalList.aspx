<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfJournalList.aspx.vb" Inherits="MngConsul.wbfJournalList" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Journal général — Liste des écritures</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
        .badge-validee {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #ecfdf5;
            color: #059669;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #a7f3d0;
        }

        .badge-brouillon {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #fef3c7;
            color: #d97706;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #fde68a;
        }

        .badge-extournee {
            display: inline-flex;
            padding: 4px 10px;
            border-radius: 999px;
            background: #fee2e2;
            color: #dc2626;
            font-size: 11px;
            font-weight: 700;
            border: 1px solid #fecaca;
        }

        .badge-source {
            display: inline-flex;
            padding: 2px 8px;
            border-radius: 999px;
            background: #eff6ff;
            color: #1e40af;
            font-size: 10px;
            font-weight: 600;
            border: 1px solid #bfdbfe;
            margin-left: 6px;
            vertical-align: middle;
        }

        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column;
        }

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

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .grid-wrap {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--r-xl);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .grid-header {
            display: grid;
            grid-template-columns: 110px 100px 140px 1fr 110px 110px 110px 70px;
            padding: 12px 14px;
            font-size: 12px;
            font-weight: 900;
            color: var(--muted);
            background: #f8fafc;
            border-bottom: 1px solid var(--line);
        }

        .grid-row {
            display: grid;
            grid-template-columns: 110px 100px 140px 1fr 110px 110px 110px 70px;
            padding: 12px 14px;
            border-bottom: 1px solid #f1f5f9;
            align-items: center;
            gap: 6px;
        }

            .grid-row:hover {
                background: #f8fafc;
            }

        .ecriture-no {
            font-weight: 700;
            color: #0f172a;
        }

        .ecriture-amount {
            text-align: right;
            font-weight: 700;
        }

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

       

        @media (max-width: 768px) {
            .grid-header {
                display: none;
            }

            .grid-row {
                grid-template-columns: 1fr 1fr;
                gap: 8px;
                padding: 14px;
            }
        }
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
                        <telerik:AjaxUpdatedControl ControlID="rpEcritures" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                        <telerik:AjaxUpdatedControl ControlID="lblCount" />
                        <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="rpEcritures">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpEcritures" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                        <telerik:AjaxUpdatedControl ControlID="lblCount" />
                        <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <%-- BARRE DE FILTRES --%>
            <div class="topbar">
                <div class="filterbar">
                    <div class="filter-field" style="width: 140px">
                        <label>Date de</label>
                        <telerik:RadDatePicker ID="dpDateFrom" runat="server" />
                    </div>
                    <div class="filter-field" style="width: 140px">
                        <label>Date à</label>
                        <telerik:RadDatePicker ID="dpDateTo" runat="server" />
                    </div>
                    <div class="filter-field" style="width: 200px">
                        <label>Journal</label>
                        <telerik:RadComboBox ID="cbJournalFilter" runat="server" Width="200px"
                            DataTextField="DisplayName" DataValueField="Id">
                            <Items>
                                <telerik:RadComboBoxItem Text="(Tous)" Value="" />
                            </Items>
                        </telerik:RadComboBox>
                    </div>
                    <div class="filter-field" style="width: 160px">
                        <label>Statut</label>
                        <telerik:RadComboBox ID="cbStatusFilter" runat="server" Width="160px">
                            <Items>
                                <telerik:RadComboBoxItem Text="(Tous)" Value="" Selected="true" />
                                <telerik:RadComboBoxItem Text="Brouillon" Value="BROUILLON" />
                                <telerik:RadComboBoxItem Text="Validée" Value="VALIDEE" />
                                <telerik:RadComboBoxItem Text="Extournée" Value="EXTOURNEE" />
                            </Items>
                        </telerik:RadComboBox>
                    </div>
                    <div class="filter-field" style="flex: 1; min-width: 200px">
                        <label>Recherche (no pièce, libellé)</label>
                        <telerik:RadTextBox ID="txtSearch" runat="server" EmptyMessage="Rechercher..." Width="100%" />
                    </div>
                    <div class="filter-field">
                        <label>&nbsp;</label>
                        <telerik:RadButton ID="btnFilter" runat="server" Text="Filtrer" />
                    </div>
                </div>
            </div>

            <%-- LISTE --%>
            <div class="content">
                <div class="container">
                    <div class="grid-wrap">
                        <div class="grid-header">
                            <div>No pièce</div>
                            <div>Date</div>
                            <div>Journal</div>
                            <div>Libellé</div>
                            <div style="text-align: right">Débit</div>
                            <div style="text-align: right">Crédit</div>
                            <div style="text-align: center">Statut</div>
                            <div style="text-align: center">Actions</div>
                        </div>

                        <asp:Repeater ID="rpEcritures" runat="server">
                            <ItemTemplate>
                                <div class="grid-row">
                                    <div class="ecriture-no" onclick='<%# "openEcriture(" & Eval("Id") & ")" %>' style="cursor: pointer;">
                                        <%# Eval("NumeroPiece") %>
                                    </div>
                                    <div><%# Eval("DateEcriture", "{0:yyyy-MM-dd}") %></div>
                                    <div>
                                        <strong><%# Eval("JournalCode") %></strong>
                                        <div style="font-size: 11px; color: var(--muted);"><%# Eval("JournalLibelle") %></div>
                                    </div>
                                    <div>
                                        <%# Eval("Libelle") %>
                                        <%# RenderSourceBadge(Eval("SourceType")) %>
                                    </div>
                                    <div class="ecriture-amount"><%# Eval("TotalDebit", "{0:N2}") %></div>
                                    <div class="ecriture-amount"><%# Eval("TotalCredit", "{0:N2}") %></div>
                                    <div style="text-align: center">
                                        <span class='<%# GetStatutCssClass(Eval("Statut")) %>'>
                                            <%# GetStatutLabel(Eval("Statut")) %>
                                        </span>
                                    </div>
                                    <div class="actions-cell">
                                        <button type="button" class="btn-icon-edit" title="Modifier"
                                            onclick='<%# "openEcriture(" & Eval("Id") & "); return false;" %>'></button>
                                        <asp:LinkButton ID="btnDelete" runat="server"
                                            CssClass="btn-icon-delete"
                                            CommandName="DeleteEcriture"
                                            CommandArgument='<%# Eval("Id") %>'
                                            OnClientClick="return confirm('Supprimer cette écriture ?');"
                                            Visible='<%# CanDelete(Eval("Statut")) %>'
                                            ToolTip="Supprimer">&nbsp;</asp:LinkButton>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                            Aucune écriture trouvée pour ces critères.
                        </asp:Panel>
                    </div>

                    <%-- PIED DE PAGE TOTAUX --%>
                    <div style="margin-top: 12px; padding: 14px; background: #fff; border: 1px solid var(--line); border-radius: var(--r-xl);">
                        <div style="display: grid; grid-template-columns: 1fr auto auto; gap: 30px; align-items: center;">
                            <div>
                                <strong>
                                    <asp:Label ID="lblCount" runat="server" Text="0" /></strong> écriture(s)
                            </div>
                            <div>Total Débit : <strong>
                                <asp:Label ID="lblTotalDebit" runat="server" Text="0.00" /></strong></div>
                            <div>Total Crédit : <strong>
                                <asp:Label ID="lblTotalCredit" runat="server" Text="0.00" /></strong></div>
                        </div>
                    </div>
                </div>
            </div>

            <%-- FAB NOUVELLE ÉCRITURE --%>
            <div class="fab-add">
                <a href="javascript:openEcriture(0)" title="Nouvelle écriture">
                    <img src="Images/rondplus45.png" alt="Nouvelle écriture" />
                </a>
            </div>

        </asp:Panel>

        <%-- POPUP D'ÉDITION --%>
        <telerik:RadWindowManager ID="RadWindowManager1" runat="server" Skin="Metro"
            EnableShadow="true" Behaviors="Close, Move, Resize" />

        <script type="text/javascript">

            function openEcriture(id) {
                var oManager = GetRadWindowManager();
                var oWnd = oManager.open("wbfJournalEntryEdit.aspx?Id=" + id, "wndEcriture");
                oWnd.setSize(1100, 750);
                oWnd.set_modal(true);
                oWnd.set_title(id > 0 ? "Modifier l'écriture" : "Nouvelle écriture");
                oWnd.center();
                oWnd.add_close(function () {
                    /* Recharger la liste à la fermeture */
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
