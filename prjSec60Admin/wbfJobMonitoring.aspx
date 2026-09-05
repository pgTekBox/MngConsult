<%@ Page Title="Historique des exécutions" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobMonitoring.aspx.vb"
    Inherits="prjSec60Admin.wbfJobMonitoring" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .mon-page { max-width: 1300px; margin: 0 auto; padding: 12px; }
        .mon-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .mon-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .mon-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }

        /* KPI Row */
        .kpi-row {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 12px;
            margin-bottom: 16px;
        }
        .kpi-card {
            background: #fff; border: 1px solid #e2e8f0; border-radius: 8px;
            padding: 12px 14px;
        }
        .kpi-card .lbl {
            font-size: 11px; color: #64748b;
            text-transform: uppercase; letter-spacing: 0.5px;
            margin-bottom: 4px;
        }
        .kpi-card .val {
            font-size: 22px; font-weight: 600; color: #0f172a;
            font-variant-numeric: tabular-nums; line-height: 1;
        }
        .kpi-card.kpi-success { border-top: 3px solid #16a34a; }
        .kpi-card.kpi-success .val { color: #16a34a; }
        .kpi-card.kpi-danger  { border-top: 3px solid #dc2626; }
        .kpi-card.kpi-danger  .val { color: #dc2626; }
        .kpi-card.kpi-warning { border-top: 3px solid #f59e0b; }
        .kpi-card.kpi-warning .val { color: #f59e0b; }
        .kpi-card.kpi-info    { border-top: 3px solid #0ea5e9; }
        .kpi-card.kpi-info    .val { color: #0ea5e9; }

        .kpi-card .meta {
            font-size: 11px; color: #94a3b8; margin-top: 4px;
        }

        /* Filtres */
        .filters {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 8px 12px;
            margin-bottom: 12px;
        }
        .filter-group label {
            display: block; font-size: 11px; color: #64748b;
            text-transform: uppercase; letter-spacing: 0.5px;
            margin-bottom: 3px; font-weight: 500;
        }
        .filter-actions {
            display: flex; justify-content: flex-end; gap: 8px;
            padding-top: 8px; border-top: 1px solid #f1f5f9;
        }

        /* Tableau */
        .exec-table { width: 100%; border-collapse: collapse; }
        .exec-table th {
            background: #f1f5f9; color: #475569; font-weight: 600;
            font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;
            padding: 8px 10px; text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        .exec-table td {
            padding: 8px 10px; border-bottom: 1px solid #f1f5f9;
            font-size: 13px; vertical-align: middle;
        }
        .exec-table tr:hover td { background: #fafbfc; cursor: pointer; }
        .exec-table .col-num { text-align: right; font-variant-numeric: tabular-nums; }
        .exec-table .col-actions { text-align: right; white-space: nowrap; }

        .job-name { font-weight: 600; color: #0f172a; }
        .meta-line { font-size: 11px; color: #64748b; margin-top: 2px; }
        .meta-line .sep { margin: 0 6px; color: #cbd5e1; }
        .job-code {
            font-family: 'Consolas', 'Monaco', monospace; font-size: 10px;
            color: #64748b; background: #f1f5f9;
            padding: 1px 6px; border-radius: 3px;
        }

        .pill {
            display: inline-block; padding: 2px 8px; border-radius: 999px;
            font-size: 11px; font-weight: 600;
        }
        .pill-success  { background: #dcfce7; color: #166534; }
        .pill-warning  { background: #fef3c7; color: #92400e; }
        .pill-danger   { background: #fee2e2; color: #991b1b; }
        .pill-info     { background: #dbeafe; color: #1e40af; }
        .pill-neutral  { background: #f1f5f9; color: #475569; }
        .pill-running  {
            background: #dbeafe; color: #1e40af;
            animation: pulse 1.5s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }

        .trigger-badge {
            display: inline-block; padding: 1px 6px; border-radius: 3px;
            font-size: 10px; font-weight: 600;
            background: #f1f5f9; color: #475569;
        }
        .trigger-MANUAL { background: #fef3c7; color: #92400e; }
        .trigger-RETRY  { background: #fce7f3; color: #9d174d; }

        /* Message tronqué */
        .msg-cell {
            max-width: 300px;
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
            color: #475569;
        }

        /* Pagination */
        .pagination {
            display: flex; justify-content: space-between; align-items: center;
            padding: 12px 0; border-top: 1px solid #e2e8f0; margin-top: 12px;
        }
        .pagination .info { font-size: 12px; color: #64748b; }
        .pagination .controls { display: flex; gap: 4px; align-items: center; }
        .page-btn {
            background: #fff; border: 1px solid #cbd5e1;
            padding: 4px 10px; border-radius: 4px;
            font-size: 12px; cursor: pointer; color: #475569;
            min-width: 32px; text-align: center;
        }
        .page-btn:hover { background: #f1f5f9; }
        .page-btn.active {
            background: #0ea5e9; border-color: #0ea5e9; color: #fff;
        }
        .page-btn:disabled {
            opacity: 0.4; cursor: not-allowed;
        }

        .empty-state {
            text-align: center; padding: 40px; color: #64748b; font-size: 14px;
        }

        .action-btn {
            background: transparent; border: 1px solid #cbd5e1;
            border-radius: 4px; padding: 3px 10px;
            font-size: 11px; cursor: pointer;
            color: #475569;
        }
        .action-btn:hover { background: #f1f5f9; }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="ddlJob">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="ddlStatut">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="ddlTrigger">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="dpDateDebut">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="dpDateFin">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnFiltrer">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnReset">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="ddlJob" />
                    <telerik:AjaxUpdatedControl ControlID="ddlStatut" />
                    <telerik:AjaxUpdatedControl ControlID="ddlTrigger" />
                    <telerik:AjaxUpdatedControl ControlID="dpDateDebut" />
                    <telerik:AjaxUpdatedControl ControlID="dpDateFin" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="rpExecutions">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="mon-page">

        <h2><asp:Literal ID="litLoc01" runat="server" /></h2>
        <div class="subtitle">
            <asp:Literal ID="litLoc02" runat="server" />
        </div>

        <!-- KPI Row -->
        <div class="kpi-row">
            <div class="kpi-card kpi-info">
                <div class="lbl"><asp:Literal ID="litLoc03" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiTotal" runat="server" Text="0" /></div>
                <div class="meta"><asp:Literal ID="litLoc04" runat="server" /></div>
            </div>
            <div class="kpi-card kpi-success">
                <div class="lbl"><asp:Literal ID="litLoc05" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiSucces" runat="server" Text="0" /></div>
                <div class="meta"><asp:Literal ID="litKpiSuccesPct" runat="server" /></div>
            </div>
            <div class="kpi-card kpi-danger">
                <div class="lbl"><asp:Literal ID="litLoc06" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiEchecs" runat="server" Text="0" /></div>
                <div class="meta"><asp:Literal ID="litKpiEchecsPct" runat="server" /></div>
            </div>
            <div class="kpi-card kpi-warning">
                <div class="lbl"><asp:Literal ID="litLoc07" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiEnCours" runat="server" Text="0" /></div>
                <div class="meta"><asp:Literal ID="litLoc08" runat="server" /></div>
            </div>
            <div class="kpi-card">
                <div class="lbl"><asp:Literal ID="litLoc09" runat="server" /></div>
                <div class="val"><asp:Literal ID="litKpiDureeMoy" runat="server" Text="—" /></div>
                <div class="meta"><asp:Literal ID="litLoc10" runat="server" /></div>
            </div>
        </div>

        <!-- Filtres -->
        <div class="mon-card">
            <div class="filters">
                <div class="filter-group">
                    <label><asp:Literal ID="litLoc11" runat="server" /></label>
                    <telerik:RadComboBox ID="ddlJob" runat="server" Skin="Bootstrap"
                        Width="100%" AutoPostBack="true" Filter="Contains"
                        EmptyMessage="Tous les jobs"
                        OnSelectedIndexChanged="Filtre_Changed" />
                </div>

                <div class="filter-group">
                    <label><asp:Literal ID="litLoc12" runat="server" /></label>
                    <telerik:RadComboBox ID="ddlStatut" runat="server" Skin="Bootstrap"
                        Width="100%" AutoPostBack="true"
                        OnSelectedIndexChanged="Filtre_Changed">
                        <Items>
                            <telerik:RadComboBoxItem Text="Tous" Value="" Selected="true" />
                            <telerik:RadComboBoxItem Text="Succès" Value="SUCCES" />
                            <telerik:RadComboBoxItem Text="Échec" Value="ECHEC" />
                            <telerik:RadComboBoxItem Text="Timeout" Value="TIMEOUT" />
                            <telerik:RadComboBoxItem Text="En cours" Value="EN_COURS" />
                            <telerik:RadComboBoxItem Text="Annulé" Value="ANNULE" />
                        </Items>
                    </telerik:RadComboBox>
                </div>

                <div class="filter-group">
                    <label><asp:Literal ID="litLoc13" runat="server" /></label>
                    <telerik:RadComboBox ID="ddlTrigger" runat="server" Skin="Bootstrap"
                        Width="100%" AutoPostBack="true"
                        OnSelectedIndexChanged="Filtre_Changed">
                        <Items>
                            <telerik:RadComboBoxItem Text="Tous" Value="" Selected="true" />
                            <telerik:RadComboBoxItem Text="Schedule" Value="SCHEDULE" />
                            <telerik:RadComboBoxItem Text="Manuel" Value="MANUAL" />
                            <telerik:RadComboBoxItem Text="Retry" Value="RETRY" />
                            <telerik:RadComboBoxItem Text="Dépendance" Value="DEPENDENCY" />
                        </Items>
                    </telerik:RadComboBox>
                </div>

                <div class="filter-group">
                    <label><asp:Literal ID="litLoc14" runat="server" /></label>
                    <div style="display: flex; gap: 4px;">
                        <telerik:RadDatePicker ID="dpDateDebut" runat="server" Skin="Bootstrap"
                            Width="49%" AutoPostBack="true"
                            OnSelectedDateChanged="Filtre_Changed" />
                        <telerik:RadDatePicker ID="dpDateFin" runat="server" Skin="Bootstrap"
                            Width="49%" AutoPostBack="true"
                            OnSelectedDateChanged="Filtre_Changed" />
                    </div>
                </div>
            </div>

            <div class="filter-actions">
                <telerik:RadButton ID="btnReset" runat="server" Skin="Bootstrap"
                    Text="Réinitialiser" Icon-PrimaryIconCssClass="rbRefresh"
                    OnClick="btnReset_Click" />
                <telerik:RadButton ID="btnFiltrer" runat="server" Skin="Bootstrap"
                    Text="Appliquer" OnClick="btnFiltrer_Click" />
            </div>
        </div>

        <!-- Liste des exécutions -->
        <asp:PlaceHolder ID="phContenu" runat="server">
            <div class="mon-card">

                <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        <asp:Literal ID="litLoc15" runat="server" />
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phTable" runat="server" Visible="false">
                    <table class="exec-table">
                        <thead>
                            <tr>
                                <th style="width:18%;"><asp:Literal ID="litLoc16" runat="server" /></th>
                                <th style="width:25%;"><asp:Literal ID="litLoc17" runat="server" /></th>
                                <th style="width:9%;"><asp:Literal ID="litLoc18" runat="server" /></th>
                                <th style="width:9%;"><asp:Literal ID="litLoc19" runat="server" /></th>
                                <th class="col-num" style="width:8%;"><asp:Literal ID="litLoc20" runat="server" /></th>
                                <th class="col-num" style="width:7%;"><asp:Literal ID="litLoc21" runat="server" /></th>
                                <th style="width:14%;"><asp:Literal ID="litLoc22" runat="server" /></th>
                                <th class="col-actions" style="width:10%;"><asp:Literal ID="litLoc23" runat="server" /></th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpExecutions" runat="server"
                                OnItemDataBound="rpExecutions_ItemDataBound"
                                OnItemCommand="rpExecutions_ItemCommand">
                                <ItemTemplate>
                                    <tr>
                                        <td>
                                            <%# Convert.ToDateTime(Eval("Demarre")).ToString("yyyy-MM-dd HH:mm:ss") %>
                                            <div class="meta-line">
                                                <asp:Literal ID="litRelative" runat="server" />
                                            </div>
                                        </td>
                                        <td>
                                            <div class="job-name"><%# Eval("JobNom") %></div>
                                            <div class="meta-line">
                                                <span class="job-code"><%# Eval("JobCode") %></span>
                                                <%# IIf(Convert.IsDBNull(Eval("ScheduleNom")), "",
                                                       "<span class='sep'>•</span>" & Server.HtmlEncode(Eval("ScheduleNom").ToString())) %>
                                            </div>
                                        </td>
                                        <td><asp:Literal ID="litStatutPill" runat="server" /></td>
                                        <td>
                                            <asp:Literal ID="litTriggerBadge" runat="server" />
                                            <%# IIf(Convert.ToInt32(Eval("TentativeNumero")) > 1,
                                                   String.Format("<div class='meta-line'>{0} #{1}</div>", T("Tentative", "Attempt", "Intento"), Eval("TentativeNumero")),
                                                   "") %>
                                        </td>
                                        <td class="col-num">
                                            <asp:Literal ID="litDuree" runat="server" />
                                        </td>
                                        <td class="col-num">
                                            <%# IIf(Convert.IsDBNull(Eval("LignesTraitees")), "—", Eval("LignesTraitees")) %>
                                        </td>
                                        <td class="msg-cell" title='<%# IIf(Convert.IsDBNull(Eval("ResultatMessage")), "", Eval("ResultatMessage")) %>'>
                                            <%# IIf(Convert.IsDBNull(Eval("ResultatMessage")), "", Server.HtmlEncode(Eval("ResultatMessage").ToString())) %>
                                        </td>
                                        <td class="col-actions">
                                            <asp:LinkButton ID="btnDetail" runat="server"
                                                CssClass="action-btn"
                                                CommandName="Detail"
                                                CommandArgument='<%# Eval("Id") %>'
                                                Text='<%# T("Détails →", "Details →", "Detalles →") %>' />
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>

                    <!-- Pagination -->
                    <div class="pagination">
                        <div class="info">
                            <asp:Literal ID="litPagInfo" runat="server" />
                        </div>
                        <div class="controls">
                            <asp:LinkButton ID="btnPagPrev" runat="server"
                                CssClass="page-btn" Text="‹ Précédent"
                                OnClick="btnPagPrev_Click" />
                            <asp:Literal ID="litPagPages" runat="server" />
                            <asp:LinkButton ID="btnPagNext" runat="server"
                                CssClass="page-btn" Text="Suivant ›"
                                OnClick="btnPagNext_Click" />
                        </div>
                    </div>
                </asp:PlaceHolder>
            </div>
        </asp:PlaceHolder>

    </div>

</asp:Content>
