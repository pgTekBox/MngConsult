<%@ Page Title="Tâches planifiées" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobs.aspx.vb"
    Inherits="prjSec60Admin.wbfJobs" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .jobs-page { max-width: 1200px; margin: 0 auto; padding: 12px; }
        .jobs-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .jobs-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .jobs-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .jobs-card h3 { margin: 0 0 12px 0; font-size: 16px; color: #0f172a; }

        /* Toolbar */
        .toolbar {
            display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
            padding-bottom: 12px;
        }
        .toolbar .spacer { flex: 1; }

        /* Cards KPI en haut */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin-bottom: 16px;
        }
        .kpi-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 14px 16px;
        }
        .kpi-card .lbl {
            font-size: 11px; color: #64748b;
            text-transform: uppercase; letter-spacing: 0.5px;
            margin-bottom: 4px;
        }
        .kpi-card .val {
            font-size: 26px; font-weight: 600; color: #0f172a;
            font-variant-numeric: tabular-nums; line-height: 1;
        }
        .kpi-card.kpi-success .val { color: #16a34a; }
        .kpi-card.kpi-warning .val { color: #f59e0b; }
        .kpi-card.kpi-danger  .val { color: #dc2626; }

        /* Tableau des jobs */
        .jobs-table { width: 100%; border-collapse: collapse; }
        .jobs-table th {
            background: #f1f5f9; color: #475569; font-weight: 600;
            font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;
            padding: 8px 10px; text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        .jobs-table td {
            padding: 10px 10px; border-bottom: 1px solid #f1f5f9;
            font-size: 13px; vertical-align: middle;
        }
        .jobs-table tr:hover td { background: #fafbfc; }

        .jobs-table .col-actions { white-space: nowrap; text-align: right; }
        .jobs-table .col-num { text-align: right; font-variant-numeric: tabular-nums; }

        .job-name { font-weight: 600; color: #0f172a; }
        .job-name a { color: inherit; text-decoration: none; }
        .job-name a:hover { color: #0ea5e9; text-decoration: underline; }
        .job-code { font-family: 'Consolas', 'Monaco', monospace; font-size: 11px;
                    color: #64748b; background: #f1f5f9;
                    padding: 1px 6px; border-radius: 4px; }

        /* Pills de statut */
        .pill {
            display: inline-block; padding: 2px 8px; border-radius: 999px;
            font-size: 11px; font-weight: 600;
        }
        .pill-success  { background: #dcfce7; color: #166534; }
        .pill-warning  { background: #fef3c7; color: #92400e; }
        .pill-danger   { background: #fee2e2; color: #991b1b; }
        .pill-info     { background: #dbeafe; color: #1e40af; }
        .pill-neutral  { background: #f1f5f9; color: #475569; }
        .pill-running  { background: #dbeafe; color: #1e40af;
                         animation: pulse 1.5s ease-in-out infinite; }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }

        /* Badge système */
        .badge-systeme {
            background: #f3e8ff; color: #6b21a8;
            font-size: 10px; font-weight: 600;
            padding: 1px 6px; border-radius: 4px;
            margin-left: 6px;
        }

        /* Boutons d'action en ligne */
        .action-btn {
            background: transparent; border: 1px solid #cbd5e1;
            border-radius: 4px; padding: 4px 10px;
            font-size: 11px; cursor: pointer;
            color: #475569; margin-left: 4px;
            font-weight: 500;
        }
        .action-btn:hover { background: #f1f5f9; border-color: #94a3b8; }
        .action-btn.primary { color: #16a34a; border-color: #86efac; }
        .action-btn.primary:hover { background: #dcfce7; }
        .action-btn.danger { color: #dc2626; border-color: #fecaca; }
        .action-btn.danger:hover { background: #fee2e2; }

        /* Volet déplié */
        .schedule-row { background: #fafbfc; }
        .schedule-list {
            padding: 8px 16px; border-left: 3px solid #cbd5e1; margin: 4px 0;
        }
        .schedule-item {
            display: flex; gap: 12px; align-items: center;
            padding: 6px 0; font-size: 12px; color: #475569;
            border-bottom: 1px dashed #e2e8f0;
        }
        .schedule-item:last-child { border-bottom: 0; }
        .schedule-item .sched-name { font-weight: 600; color: #0f172a; min-width: 200px; }
        .schedule-item .sched-desc { color: #475569; min-width: 220px; }
        .schedule-item .sched-next { color: #64748b; min-width: 180px; }

        .empty-state {
            text-align: center; padding: 40px;
            color: #64748b; font-size: 14px;
        }

        /* Info ligne */
        .meta-line { font-size: 11px; color: #64748b; margin-top: 2px; }
        .meta-line .sep { margin: 0 6px; color: #cbd5e1; }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="ddlFiltreActif">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="ddlFiltreType">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtRecherche">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnRefresh">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="rpJobs">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="jobs-page">

        <h2><asp:Literal ID="litTitre" runat="server" /></h2>
        <div class="subtitle">
            <asp:Literal ID="litSousTitre" runat="server" />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="jobs-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- KPI Row -->
        <div class="kpi-row">
            <div class="kpi-card">
                <div class="lbl"><asp:Literal ID="litLblActifs" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiActifs" runat="server" Text="0" /></div>
            </div>
            <div class="kpi-card kpi-success">
                <div class="lbl"><asp:Literal ID="litLblSucces" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiSucces" runat="server" Text="0" /></div>
            </div>
            <div class="kpi-card kpi-danger">
                <div class="lbl"><asp:Literal ID="litLblEchecs" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiEchecs" runat="server" Text="0" /></div>
            </div>
            <div class="kpi-card kpi-warning">
                <div class="lbl"><asp:Literal ID="litLblEnCours" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiEnCours" runat="server" Text="0" /></div>
            </div>
        </div>

        <!-- Filtres + actions globales -->
        <div class="jobs-card">
            <div class="toolbar">
                <telerik:RadComboBox ID="ddlFiltreActif" runat="server" Skin="Bootstrap"
                    Width="140px" AutoPostBack="true"
                    OnSelectedIndexChanged="Filtre_Changed">
                    <Items>
                        <telerik:RadComboBoxItem Text="Tous les jobs" Value="" Selected="true" />
                        <telerik:RadComboBoxItem Text="Actifs" Value="1" />
                        <telerik:RadComboBoxItem Text="Inactifs" Value="0" />
                    </Items>
                </telerik:RadComboBox>

                <telerik:RadComboBox ID="ddlFiltreType" runat="server" Skin="Bootstrap"
                    Width="160px" AutoPostBack="true"
                    OnSelectedIndexChanged="Filtre_Changed">
                    <Items>
                        <telerik:RadComboBoxItem Text="Tous les types" Value="" Selected="true" />
                        <telerik:RadComboBoxItem Text="Procédure stockée" Value="SP" />
                        <telerik:RadComboBoxItem Text="Connecteur" Value="CONNECTOR" />
                        <telerik:RadComboBoxItem Text="Courriel" Value="EMAIL" />
                        <telerik:RadComboBoxItem Text="Custom" Value="CUSTOM" />
                    </Items>
                </telerik:RadComboBox>

                <telerik:RadTextBox ID="txtRecherche" runat="server" Skin="Bootstrap"
                    EmptyMessage="Rechercher..." Width="250px" AutoPostBack="true"
                    OnTextChanged="Filtre_Changed" />

                <telerik:RadButton ID="btnRefresh" runat="server" Skin="Bootstrap"
                    Text="Rafraîchir" Icon-PrimaryIconCssClass="rbRefresh"
                    OnClick="btnRefresh_Click" />

                <div class="spacer"></div>

                <telerik:RadButton ID="btnNouveau" runat="server" Skin="Bootstrap"
                    Text="Nouveau job" Icon-PrimaryIconCssClass="rbAdd"
                    AutoPostBack="false"
                    OnClientClicked="navigerNouveauJob" />
            </div>
        </div>

        <!-- Liste des jobs -->
        <asp:PlaceHolder ID="phContenu" runat="server">
            <div class="jobs-card">
                <h3><asp:Literal ID="litListeTitre" runat="server" /></h3>

                <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        <asp:Literal ID="litEmptyText" runat="server" />
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phTable" runat="server" Visible="false">
                    <table class="jobs-table">
                        <thead>
                            <tr>
                                <th style="width:30%;"><asp:Literal ID="litThJob" runat="server" /></th>
                                <th style="width:12%;"><asp:Literal ID="litThType" runat="server" /></th>
                                <th style="width:12%;"><asp:Literal ID="litThSchedules" runat="server" /></th>
                                <th style="width:18%;"><asp:Literal ID="litThProchaine" runat="server" /></th>
                                <th style="width:13%;"><asp:Literal ID="litThDerniere" runat="server" /></th>
                                <th class="col-actions" style="width:15%;"><asp:Literal ID="litThActions" runat="server" /></th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpJobs" runat="server"
                                OnItemDataBound="rpJobs_ItemDataBound"
                                OnItemCommand="rpJobs_ItemCommand">
                                <ItemTemplate>
                                    <tr>
                                        <td>
                                            <div class="job-name">
                                                <asp:LinkButton ID="lnkEditerJob" runat="server"
                                                    CommandName="Editer"
                                                    CommandArgument='<%# Eval("JobDefinitionId") %>'
                                                    Style="color: inherit; text-decoration: none;">
                                                    <%# Eval("Nom") %>
                                                </asp:LinkButton>
                                                <%# IIf(Convert.ToBoolean(Eval("Systeme")), "<span class='badge-systeme'>" & T("SYSTÈME", "SYSTEM", "SISTEMA") & "</span>", "") %>
                                            </div>
                                            <div class="meta-line">
                                                <span class="job-code"><%# Eval("JobCode") %></span>
                                                <%# IIf(Convert.IsDBNull(Eval("Description")) OrElse String.IsNullOrEmpty(Eval("Description").ToString()),
                                                       "",
                                                       "<span class='sep'>•</span>" & Server.HtmlEncode(Eval("Description").ToString())) %>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="pill pill-neutral"><%# Eval("HandlerType") %></span>
                                        </td>
                                        <td>
                                            <asp:Literal ID="litSchedules" runat="server" />
                                        </td>
                                        <td>
                                            <asp:Literal ID="litProchaineExec" runat="server" />
                                        </td>
                                        <td>
                                            <asp:Literal ID="litDerniereExec" runat="server" />
                                        </td>
                                        <td class="col-actions">
                                            <asp:LinkButton ID="btnEditer" runat="server"
                                                CssClass="action-btn"
                                                CommandName="Editer"
                                                CommandArgument='<%# Eval("JobDefinitionId") %>'
                                                Text="Éditer" />

                                            <asp:LinkButton ID="btnRunNow" runat="server"
                                                CssClass="action-btn primary"
                                                CommandName="RunNow"
                                                CommandArgument='<%# Eval("JobDefinitionId") %>'
                                                Text="Run now"
                                                OnClientClick="return confirm('Lancer ce job maintenant ?');" />

                                            <asp:LinkButton ID="btnToggleActif" runat="server"
                                                CssClass="action-btn"
                                                CommandName="ToggleActif"
                                                CommandArgument='<%# Eval("JobDefinitionId") %>'>
                                                <%# IIf(Convert.ToBoolean(Eval("Actif")), T("Désactiver", "Disable", "Desactivar"), T("Activer", "Enable", "Activar")) %>
                                            </asp:LinkButton>

                                            <asp:LinkButton ID="btnHistorique" runat="server"
                                                CssClass="action-btn"
                                                CommandName="Historique"
                                                CommandArgument='<%# Eval("JobDefinitionId") %>'
                                                Text="Historique" />

                                            <asp:LinkButton ID="btnSupprimer" runat="server"
                                                CssClass="action-btn danger"
                                                CommandName="Supprimer"
                                                CommandArgument='<%# Eval("JobDefinitionId") %>'
                                                Text="✕"
                                                Visible='<%# Not Convert.ToBoolean(Eval("Systeme")) %>'
                                                OnClientClick="return confirm('Supprimer définitivement ce job et tout son historique ?');" />
                                        </td>
                                    </tr>
                                    <!-- Volet déplié : schedules du job -->
                                    <tr class="schedule-row">
                                        <td colspan="6" style="padding: 0;">
                                            <asp:PlaceHolder ID="phSchedules" runat="server" />
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </asp:PlaceHolder>
            </div>
        </asp:PlaceHolder>

    </div>

    <script type="text/javascript">
        function navigerNouveauJob(sender, args) {
            window.location.href = "wbfJobEdit.aspx?Id=0";
        }
    </script>

</asp:Content>
