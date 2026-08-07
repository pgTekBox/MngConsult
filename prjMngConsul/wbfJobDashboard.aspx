<%@ Page Title="Tableau de bord — Orchestrateur" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobDashboard.aspx.vb"
    Inherits="MngConsul.wbfJobDashboard" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .dash-page { max-width: 1300px; margin: 0 auto; padding: 12px; }
        .dash-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .dash-page .subtitle {
            color: #64748b; font-size: 13px; margin-bottom: 16px;
            display: flex; justify-content: space-between; align-items: center;
        }
        .dash-page .subtitle .live-indicator {
            display: inline-flex; align-items: center; gap: 6px;
            font-size: 11px; color: #16a34a; font-weight: 600;
        }
        .live-dot {
            width: 8px; height: 8px; border-radius: 50%;
            background: #16a34a; animation: liveBlink 2s ease-in-out infinite;
        }
        @keyframes liveBlink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.3; }
        }

        /* KPI Row haut */
        .kpi-grid {
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
            border-top: 3px solid #cbd5e1;
        }
        .kpi-card.kpi-success { border-top-color: #16a34a; }
        .kpi-card.kpi-success .val { color: #16a34a; }
        .kpi-card.kpi-danger  { border-top-color: #dc2626; }
        .kpi-card.kpi-danger  .val { color: #dc2626; }
        .kpi-card.kpi-warning { border-top-color: #f59e0b; }
        .kpi-card.kpi-warning .val { color: #f59e0b; }
        .kpi-card.kpi-info    { border-top-color: #0ea5e9; }
        .kpi-card.kpi-info    .val { color: #0ea5e9; }

        .kpi-card .lbl {
            font-size: 11px; color: #64748b;
            text-transform: uppercase; letter-spacing: 0.5px;
            margin-bottom: 4px;
        }
        .kpi-card .val {
            font-size: 26px; font-weight: 600; color: #0f172a;
            font-variant-numeric: tabular-nums; line-height: 1;
        }
        .kpi-card .trend {
            font-size: 11px; color: #94a3b8; margin-top: 4px;
        }

        /* Layout 2 colonnes */
        .dash-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 16px;
        }

        .dash-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
        }
        .dash-card h3 {
            margin: 0 0 12px 0; font-size: 14px; color: #0f172a;
            padding-bottom: 8px; border-bottom: 1px solid #f1f5f9;
            display: flex; justify-content: space-between; align-items: center;
        }
        .dash-card h3 .badge-count {
            background: #f1f5f9; color: #475569;
            font-size: 11px; font-weight: 600;
            padding: 2px 8px; border-radius: 999px;
        }
        .dash-card h3 .badge-count.danger {
            background: #fee2e2; color: #991b1b;
        }

        /* Liste générique */
        .item-list { display: flex; flex-direction: column; gap: 8px; }
        .item-row {
            display: flex; gap: 12px; align-items: center;
            padding: 8px 10px; border-radius: 6px;
            background: #fafbfc;
            border-left: 3px solid #cbd5e1;
            font-size: 13px;
        }
        .item-row.row-danger  { border-left-color: #dc2626; background: #fef2f2; }
        .item-row.row-warning { border-left-color: #f59e0b; background: #fffbeb; }
        .item-row.row-success { border-left-color: #16a34a; background: #f0fdf4; }
        .item-row.row-info    { border-left-color: #0ea5e9; background: #eff6ff; }

        .item-row .ico {
            font-size: 18px; line-height: 1; min-width: 22px; text-align: center;
        }
        .item-row .body { flex: 1; min-width: 0; }
        .item-row .body .title {
            font-weight: 600; color: #0f172a;
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        }
        .item-row .body .meta {
            font-size: 11px; color: #64748b; margin-top: 2px;
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        }
        .item-row .when {
            font-size: 11px; color: #64748b; white-space: nowrap;
            font-variant-numeric: tabular-nums;
        }
        .item-row .when strong { display: block; color: #0f172a; }
        .item-row a { color: inherit; text-decoration: none; }

        /* Pills (réutilisables) */
        .pill {
            display: inline-block; padding: 1px 8px; border-radius: 999px;
            font-size: 10px; font-weight: 600;
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

        .empty-state {
            text-align: center; padding: 24px; color: #94a3b8;
            font-size: 13px;
        }
        .empty-state .ico { font-size: 32px; opacity: 0.4; margin-bottom: 6px; }

        /* Tendance 7 jours - graphique en barres CSS */
        .tendance {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 8px;
            padding: 8px 0;
        }
        .tendance-jour {
            text-align: center;
        }
        .tendance-jour .label {
            font-size: 10px; color: #94a3b8;
            text-transform: uppercase; letter-spacing: 0.5px;
            margin-top: 4px;
        }
        .tendance-jour .date {
            font-size: 11px; color: #475569; font-weight: 600;
        }
        .tendance-bar-wrap {
            height: 80px; display: flex; flex-direction: column-reverse;
            border-radius: 4px; overflow: hidden;
            background: #f8fafc; position: relative;
            margin-bottom: 4px;
        }
        .tendance-bar-success { background: #86efac; }
        .tendance-bar-echec   { background: #fca5a5; }
        .tendance-total {
            position: absolute; top: 4px; left: 0; right: 0;
            text-align: center; font-size: 11px; font-weight: 600;
            color: #0f172a;
        }

        .toolbar {
            display: flex; gap: 8px;
        }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnRefresh">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="litLastRefresh" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="tmrAutoRefresh">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" />
                    <telerik:AjaxUpdatedControl ControlID="litLastRefresh" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <!-- Timer pour auto-refresh toutes les 30 secondes -->
    <asp:Timer ID="tmrAutoRefresh" runat="server" Interval="30000"
        OnTick="tmrAutoRefresh_Tick" />

    <div class="dash-page">

        <h2><asp:Literal ID="litLoc01" runat="server" /></h2>
        <div class="subtitle">
            <div>
                <asp:Literal ID="litLoc02" runat="server" />
                <asp:Literal ID="litLoc03" runat="server" /> <asp:Literal ID="litLastRefresh" runat="server" />
            </div>
            <div class="toolbar">
                <span class="live-indicator">
                    <span class="live-dot"></span> <asp:Literal ID="litLoc04" runat="server" />
                </span>
                <telerik:RadButton ID="btnRefresh" runat="server" Skin="Bootstrap"
                    Text="Rafraîchir" Icon-PrimaryIconCssClass="rbRefresh"
                    OnClick="btnRefresh_Click" />
            </div>
        </div>

        <asp:PlaceHolder ID="phContenu" runat="server">

            <!-- KPIs -->
            <div class="kpi-grid">
                <div class="kpi-card kpi-info">
                    <div class="lbl"><asp:Literal ID="litLoc05" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litKpiJobsActifs" runat="server" Text="0" /></div>
                    <div class="trend">
                        <asp:Literal ID="litKpiJobsInactifs" runat="server" /> <asp:Literal ID="litLoc06" runat="server" />
                    </div>
                </div>
                <div class="kpi-card kpi-success">
                    <div class="lbl"><asp:Literal ID="litLoc07" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litKpiSucces24h" runat="server" Text="0" /></div>
                    <div class="trend">
                        <asp:Literal ID="litLoc08" runat="server" /> <strong><asp:Literal ID="litKpiTaux7j" runat="server" /></strong>
                    </div>
                </div>
                <div class="kpi-card kpi-danger">
                    <div class="lbl"><asp:Literal ID="litLoc09" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litKpiEchecs24h" runat="server" Text="0" /></div>
                    <div class="trend">
                        <asp:Literal ID="litLoc10" runat="server" /> <strong><asp:Literal ID="litKpiTotal7j" runat="server" /></strong> <asp:Literal ID="litLoc11" runat="server" />
                    </div>
                </div>
                <div class="kpi-card kpi-warning">
                    <div class="lbl"><asp:Literal ID="litLoc12" runat="server" /></div>
                    <div class="val"><asp:Literal ID="litKpiEnCours" runat="server" Text="0" /></div>
                    <div class="trend">
                        <asp:Literal ID="litLoc13" runat="server" /> <strong><asp:Literal ID="litKpiDureeMoy" runat="server" /></strong>
                    </div>
                </div>
            </div>

            <!-- Tendance 7 jours -->
            <div class="dash-card" style="margin-bottom: 16px;">
                <h3><asp:Literal ID="litLoc14" runat="server" /></h3>
                <div class="tendance">
                    <asp:Literal ID="litTendance" runat="server" />
                </div>
            </div>

            <!-- Layout 2 colonnes -->
            <div class="dash-grid">

                <!-- Jobs en alerte -->
                <div class="dash-card">
                    <h3>
                        <asp:Literal ID="litLoc15" runat="server" />
                        <span id="badgeAlertes" runat="server" class="badge-count">0</span>
                    </h3>
                    <asp:PlaceHolder ID="phAlertesEmpty" runat="server" Visible="false">
                        <div class="empty-state">
                            <div class="ico">✓</div>
                            <asp:Literal ID="litLoc16" runat="server" />
                        </div>
                    </asp:PlaceHolder>
                    <div class="item-list">
                        <asp:Repeater ID="rpAlertes" runat="server"
                            OnItemDataBound="rpAlertes_ItemDataBound"
                            OnItemCommand="rpAlertes_ItemCommand">
                            <ItemTemplate>
                                <asp:LinkButton ID="lnkAlerte" runat="server"
                                    CommandName="VoirExec"
                                    CommandArgument='<%# Eval("DerniereExecutionId") %>'
                                    Style="text-decoration: none; color: inherit;">
                                    <asp:Literal ID="litRow" runat="server" />
                                </asp:LinkButton>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <!-- Prochaines exécutions -->
                <div class="dash-card">
                    <h3>
                        <asp:Literal ID="litLoc17" runat="server" />
                        <span class="badge-count">
                            <asp:Literal ID="litNbProchaines" runat="server" Text="0" />
                        </span>
                    </h3>
                    <asp:PlaceHolder ID="phProchainesEmpty" runat="server" Visible="false">
                        <div class="empty-state">
                            <div class="ico">📅</div>
                            <asp:Literal ID="litLoc18" runat="server" />
                        </div>
                    </asp:PlaceHolder>
                    <div class="item-list">
                        <asp:Repeater ID="rpProchaines" runat="server"
                            OnItemDataBound="rpProchaines_ItemDataBound">
                            <ItemTemplate>
                                <div class="item-row row-info">
                                    <div class="ico">⏱</div>
                                    <div class="body">
                                        <div class="title"><%# Eval("JobNom") %></div>
                                        <div class="meta">
                                            <%# Eval("ScheduleNom") %> •
                                            <%# Eval("HandlerType") %>
                                        </div>
                                    </div>
                                    <div class="when">
                                        <strong><asp:Literal ID="litRelative" runat="server" /></strong>
                                        <%# Convert.ToDateTime(Eval("ProchaineExec")).ToString("HH:mm") %>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

            </div>

            <!-- Activité récente -->
            <div class="dash-card">
                <h3>
                    <asp:Literal ID="litLoc19" runat="server" />
                    <span class="badge-count"><asp:Literal ID="litLoc20" runat="server" /></span>
                </h3>
                <asp:PlaceHolder ID="phActiviteEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        <div class="ico">○</div>
                        <asp:Literal ID="litLoc21" runat="server" />
                    </div>
                </asp:PlaceHolder>
                <div class="item-list">
                    <asp:Repeater ID="rpActivite" runat="server"
                        OnItemDataBound="rpActivite_ItemDataBound"
                        OnItemCommand="rpActivite_ItemCommand">
                        <ItemTemplate>
                            <asp:LinkButton ID="lnkAct" runat="server"
                                CommandName="VoirExec"
                                CommandArgument='<%# Eval("ExecutionId") %>'
                                Style="text-decoration: none; color: inherit;">
                                <asp:Literal ID="litRow" runat="server" />
                            </asp:LinkButton>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>
            </div>

        </asp:PlaceHolder>

    </div>

</asp:Content>
