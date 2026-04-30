<%@ Page Title="AI Sales" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfAISale.aspx.vb"
    Inherits="MngConsul.wbfAISale" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .ai-page {
            max-width: 1300px; margin: 0 auto; padding: 24px;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            min-height: calc(100vh - 100px);
            width:100%;        }

        /* ─── Header ─── */
        .ai-header {
            background: #fff; border: 1px solid #e2e8f0;
            margin: -24px -24px 24px -24px; padding: 16px 24px;
            display: flex; justify-content: space-between; align-items: center;
        }
        .ai-header h1 { margin: 0; font-size: 24px; color: #1e293b; font-weight: 700; }
        .ai-header .subtitle { margin: 4px 0 0 0; font-size: 13px; color: #64748b; }
        .ai-header .left { display: flex; align-items: center; gap: 12px; }
        .ai-header .back-btn {
            background: transparent; border: none; cursor: pointer;
            padding: 8px; border-radius: 8px; color: #475569;
        }
        .ai-header .back-btn:hover { background: #f1f5f9; }
        .ai-header .bank-widget {
            display: flex; align-items: center; gap: 8px;
            background: #f8fafc; border: 1px solid #e2e8f0;
            border-radius: 12px; padding: 8px 16px;
            box-shadow: 0 1px 2px 0 rgba(0,0,0,0.05);
        }
        .ai-header .bank-icon {
            display: flex; align-items: center; justify-content: center;
            width: 32px; height: 32px;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            border-radius: 8px; flex-shrink: 0;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        .ai-header .bank-icon svg { color: #fff; width: 16px; height: 16px; }
        .ai-header .bank-info { text-align: left; line-height: 1; }
        .ai-header .bank-label {
            font-size: 11px; color: #64748b; font-weight: 500;
            margin: 0 0 2px 0;
        }
        .ai-header .bank-value {
            font-size: 14px; color: #1e293b; font-weight: 700;
            margin: 0;
        }
        .ai-header .bank-toggle {
            margin-left: 4px; padding: 4px;
            background: transparent; border: none; cursor: pointer;
            border-radius: 6px; color: #94a3b8;
            transition: all 0.15s;
        }
        .ai-header .bank-toggle:hover { color: #475569; background: #e2e8f0; }
        .ai-header .bank-toggle svg { width: 14px; height: 14px; }

        /* ─── Page title ─── */
        .ai-page-title { margin-bottom: 32px; }
        .ai-page-title h2 { font-size: 28px; font-weight: 700; color: #1e293b; margin: 0 0 4px 0; }
        .ai-page-title p { color: #475569; margin: 0; font-size: 14px; }

        /* ─── Filter card (4 tuiles) ─── */
        .filter-card {
            background: #fff; border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1);
            border: 1px solid #e2e8f0; padding: 24px; margin-bottom: 32px;
        }
        .filter-card-header { margin-bottom: 24px; }
        .filter-card-header h3 { font-size: 20px; font-weight: 700; color: #1e293b; margin: 0 0 4px 0; }
        .filter-card-header p { color: #64748b; margin: 0; font-size: 13px; }

        .periods-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
        }
        @media (max-width: 768px) {
            .periods-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
        .period-btn {
            background: #fff; border: 2px solid #e2e8f0;
            border-radius: 12px; padding: 16px; text-align: left;
            cursor: pointer; transition: all 0.2s;
            text-decoration: none; display: block; color: inherit;
        }
        .period-btn:hover {
            border-color: #cbd5e1; background: #f8fafc;
            text-decoration: none; color: inherit;
        }
        .period-btn.active {
            border-color: #f59e0b; background: #fffbeb;
            box-shadow: 0 4px 6px -1px rgba(245,158,11,0.1);
        }
        .period-btn-header {
            display: flex; align-items: center; gap: 12px; margin-bottom: 12px;
        }
        .period-icon {
            width: 36px; height: 36px; border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            color: #fff; flex-shrink: 0;
        }
        .period-icon-today  { background: linear-gradient(135deg, #3b82f6, #2563eb); }
        .period-icon-week   { background: linear-gradient(135deg, #06b6d4, #0891b2); }
        .period-icon-month  { background: linear-gradient(135deg, #14b8a6, #0d9488); }
        .period-icon-3month { background: linear-gradient(135deg, #10b981, #059669); }
        .period-name { font-weight: 700; font-size: 14px; color: #1e293b; margin: 0; }
        .period-btn.active .period-name { color: #b45309; }
        .period-info { font-size: 11px; color: #64748b; margin: 2px 0 0 0; }

        /* Sous-totaux à l'intérieur de chaque tuile */
        .period-stats { display: flex; flex-direction: column; gap: 6px; }
        .period-stat-row {
            display: flex; align-items: center; justify-content: space-between;
            padding: 4px 8px; border-radius: 6px;
            border: 1px solid; font-size: 11px;
        }
        .period-stat-row.collecte {
            background: #ecfdf5; border-color: #d1fae5;
        }
        .period-stat-row.collecte .label { color: #065f46; font-weight: 600; }
        .period-stat-row.collecte .value { color: #047857; font-weight: 700; }

        .period-stat-row.recevoir {
            background: #fffbeb; border-color: #fde68a;
        }
        .period-stat-row.recevoir .label { color: #92400e; font-weight: 600; }
        .period-stat-row.recevoir .value { color: #b45309; font-weight: 700; }

        .period-stat-row.retard {
            background: #fef2f2; border-color: #fecaca;
        }
        .period-stat-row.retard .label { color: #991b1b; font-weight: 600; }
        .period-stat-row.retard .value { color: #b91c1c; font-weight: 700; }

        .period-stat-row .label-block {
            display: flex; align-items: center; gap: 6px;
        }
        .period-stat-row .label-block svg { width: 12px; height: 12px; flex-shrink: 0; }

        /* ─── Section détail ─── */
        .section-title {
            font-size: 22px; font-weight: 700; color: #1e293b;
            margin: 0 0 16px 0;
        }
        .section-title .periode-label { color: #64748b; }

        .detail-card {
            background: #fff; border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1);
            border: 1px solid #e2e8f0; padding: 24px;
        }

        /* ─── Tabs ─── */
        .tabs-row {
            display: flex; gap: 4px; flex-wrap: wrap;
            border-bottom: 1px solid #e2e8f0;
            margin-bottom: 16px; padding-bottom: 12px;
        }
        .tab-btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 8px 16px; border-radius: 8px; border: 1px solid transparent;
            background: transparent; cursor: pointer;
            font-size: 13px; font-weight: 600; color: #64748b;
            transition: all 0.15s;
            text-decoration: none;
        }
        .tab-btn:hover { background: #f8fafc; color: #475569; text-decoration: none; }
        .tab-btn svg { width: 14px; height: 14px; flex-shrink: 0; }

        .tab-btn.active.collecte {
            background: #ecfdf5; border-color: #a7f3d0; color: #047857;
        }
        .tab-btn.active.recevoir {
            background: #fffbeb; border-color: #fde68a; color: #b45309;
        }
        .tab-btn.active.retard {
            background: #fef2f2; border-color: #fecaca; color: #b91c1c;
        }
        .tab-pill {
            display: inline-block; font-size: 11px; font-weight: 700;
            padding: 1px 8px; border-radius: 999px; line-height: 1.4;
        }
        .tab-btn .tab-pill { background: #e2e8f0; color: #475569; }
        .tab-btn.active.collecte .tab-pill { background: #a7f3d0; color: #065f46; }
        .tab-btn.active.recevoir .tab-pill { background: #fde68a; color: #92400e; }
        .tab-btn.active.retard .tab-pill { background: #fecaca; color: #991b1b; }

        /* ─── Liste des items ─── */
        .item-list { display: flex; flex-direction: column; gap: 8px; }
        .item-row {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px;
            padding: 12px 16px; border-radius: 8px; border: 1px solid;
            transition: all 0.15s;
        }
        .item-row.collecte {
            background: #ecfdf5cc; border-color: #d1fae5;
        }
        .item-row.collecte:hover { background: #ecfdf5; }
        .item-row.recevoir {
            background: #fffbebcc; border-color: #fde68a;
        }
        .item-row.recevoir:hover { background: #fffbeb; }
        .item-row.retard {
            background: #fef2f2cc; border-color: #fecaca;
        }
        .item-row.retard:hover { background: #fef2f2; }

        .item-left {
            display: flex; align-items: center; gap: 12px;
            min-width: 0; flex: 1;
        }
        .item-icon { width: 16px; height: 16px; flex-shrink: 0; }
        .item-icon.collecte { color: #10b981; }
        .item-icon.recevoir { color: #f59e0b; }
        .item-icon.retard { color: #ef4444; }

        .item-info { min-width: 0; }
        .item-info .client {
            font-weight: 600; color: #1e293b; font-size: 13px;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .item-info .desc {
            font-size: 11px; color: #64748b;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }

        .item-right {
            display: flex; align-items: center; gap: 12px; flex-shrink: 0;
        }
        .item-date { font-size: 11px; color: #94a3b8; }
        .item-id {
            font-family: 'Consolas', 'Monaco', monospace; font-size: 11px;
            color: #94a3b8;
        }
        .item-amount { font-weight: 700; font-size: 13px; white-space: nowrap; }
        .item-amount.collecte { color: #047857; }
        .item-amount.recevoir { color: #b45309; }
        .item-amount.retard { color: #b91c1c; }

        @media (max-width: 640px) {
            .item-date, .item-id { display: none; }
        }

        .empty-state {
            text-align: center; padding: 48px 24px;
            color: #94a3b8;
        }
        .empty-state .ico { font-size: 36px; margin-bottom: 8px; opacity: 0.4; }
        .empty-state .msg { font-size: 13px; color: #94a3b8; }

        .status-msg {
            padding: 12px 16px; border-radius: 8px;
            margin-bottom: 16px; border-left: 4px solid;
            font-size: 13px;
        }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnDispatchAction">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phContenu" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <!-- HiddenFields pour le dispatcher -->
    <asp:HiddenField ID="hfPeriodeSel" runat="server" Value="3MONTHS" ClientIDMode="Static" />
    <asp:HiddenField ID="hfTabSel" runat="server" Value="COLLECTE" ClientIDMode="Static" />
    <asp:HiddenField ID="hfActionName" runat="server" Value="" ClientIDMode="Static" />
    <asp:HiddenField ID="hfActionArg" runat="server" Value="" ClientIDMode="Static" />

    <asp:LinkButton ID="btnDispatchAction" runat="server" Text="."
        Style="position:absolute; left:-9999px; width:1px; height:1px; overflow:hidden;"
        CausesValidation="false"
        OnClick="btnDispatchAction_Click" />

    <div class="ai-page">

        <!-- Header -->
        <div class="ai-header">
            <div class="left">
                <button type="button" class="back-btn" onclick="history.back()" title="Retour">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
                        fill="none" stroke="currentColor" stroke-width="2"
                        stroke-linecap="round" stroke-linejoin="round">
                        <path d="m15 18-6-6 6-6"/>
                    </svg>
                </button>
                <div>
                    <h1>AI Sales</h1>
                    <p class="subtitle">Gestion intelligente des ventes</p>
                </div>
            </div>
            <div class="bank-widget">
                <div class="bank-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2"
                        stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" x2="21" y1="22" y2="22"/>
                        <line x1="6" x2="6" y1="18" y2="11"/>
                        <line x1="10" x2="10" y1="18" y2="11"/>
                        <line x1="14" x2="14" y1="18" y2="11"/>
                        <line x1="18" x2="18" y1="18" y2="11"/>
                        <polygon points="12 2 20 7 4 7"/>
                    </svg>
                </div>
                <div class="bank-info">
                    <p class="bank-label">Solde bancaire</p>
                    <p class="bank-value" id="bankValue">
                        <asp:Literal ID="litSoldeBancaire" runat="server" Text="—" />
                    </p>
                </div>
                <button type="button" class="bank-toggle" id="btnToggleSolde"
                        onclick="toggleSolde(); return false;" title="Masquer le solde">
                    <svg id="iconEye" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2"
                        stroke-linecap="round" stroke-linejoin="round">
                        <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/>
                        <circle cx="12" cy="12" r="3"/>
                    </svg>
                </button>
            </div>
        </div>

       

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="status-msg">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <asp:PlaceHolder ID="phContenu" runat="server">

            <!-- Card filtre période -->
            <div class="filter-card">
                <div class="filter-card-header">
                    <h3>Période de vente</h3>
                    <p>Sélectionnez une période</p>
                </div>

                <div class="periods-grid">

                    <!-- TODAY -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodToday"
                       class="period-btn" onclick="selectPeriode('TODAY')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-today">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <div>
                                <p class="period-name">Today</p>
                                <p class="period-info"><asp:Literal ID="litTodayCount" runat="server" Text="0" /> ventes</p>
                            </div>
                        </div>
                        <div class="period-stats">
                            <div class="period-stat-row collecte">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/>
                                        <polyline points="16 7 22 7 22 13"/>
                                    </svg>
                                    <span class="label">Collecté</span>
                                </span>
                                <span class="value"><asp:Literal ID="litTodayCollecte" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row recevoir">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/>
                                        <polyline points="16 17 22 17 22 11"/>
                                    </svg>
                                    <span class="label">À recevoir</span>
                                </span>
                                <span class="value"><asp:Literal ID="litTodayRecevoir" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row retard">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/>
                                        <polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <span class="label">En retard</span>
                                </span>
                                <span class="value"><asp:Literal ID="litTodayRetard" runat="server" Text="0 $" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- WEEK -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodWeek"
                       class="period-btn" onclick="selectPeriode('WEEK')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-week">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <div>
                                <p class="period-name">Week</p>
                                <p class="period-info"><asp:Literal ID="litWeekCount" runat="server" Text="0" /> ventes</p>
                            </div>
                        </div>
                        <div class="period-stats">
                            <div class="period-stat-row collecte">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/>
                                        <polyline points="16 7 22 7 22 13"/>
                                    </svg>
                                    <span class="label">Collecté</span>
                                </span>
                                <span class="value"><asp:Literal ID="litWeekCollecte" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row recevoir">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/>
                                        <polyline points="16 17 22 17 22 11"/>
                                    </svg>
                                    <span class="label">À recevoir</span>
                                </span>
                                <span class="value"><asp:Literal ID="litWeekRecevoir" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row retard">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/>
                                        <polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <span class="label">En retard</span>
                                </span>
                                <span class="value"><asp:Literal ID="litWeekRetard" runat="server" Text="0 $" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- MONTH -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodMonth"
                       class="period-btn" onclick="selectPeriode('MONTH')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-month">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <div>
                                <p class="period-name">Month</p>
                                <p class="period-info"><asp:Literal ID="litMonthCount" runat="server" Text="0" /> ventes</p>
                            </div>
                        </div>
                        <div class="period-stats">
                            <div class="period-stat-row collecte">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/>
                                        <polyline points="16 7 22 7 22 13"/>
                                    </svg>
                                    <span class="label">Collecté</span>
                                </span>
                                <span class="value"><asp:Literal ID="litMonthCollecte" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row recevoir">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/>
                                        <polyline points="16 17 22 17 22 11"/>
                                    </svg>
                                    <span class="label">À recevoir</span>
                                </span>
                                <span class="value"><asp:Literal ID="litMonthRecevoir" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row retard">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/>
                                        <polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <span class="label">En retard</span>
                                </span>
                                <span class="value"><asp:Literal ID="litMonthRetard" runat="server" Text="0 $" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- 3 MONTHS -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriod3M"
                       class="period-btn active" onclick="selectPeriode('3MONTHS')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-3month">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <div>
                                <p class="period-name">3 Months</p>
                                <p class="period-info"><asp:Literal ID="lit3MCount" runat="server" Text="0" /> ventes</p>
                            </div>
                        </div>
                        <div class="period-stats">
                            <div class="period-stat-row collecte">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/>
                                        <polyline points="16 7 22 7 22 13"/>
                                    </svg>
                                    <span class="label">Collecté</span>
                                </span>
                                <span class="value"><asp:Literal ID="lit3MCollecte" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row recevoir">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/>
                                        <polyline points="16 17 22 17 22 11"/>
                                    </svg>
                                    <span class="label">À recevoir</span>
                                </span>
                                <span class="value"><asp:Literal ID="lit3MRecevoir" runat="server" Text="0 $" /></span>
                            </div>
                            <div class="period-stat-row retard">
                                <span class="label-block">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/>
                                        <polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <span class="label">En retard</span>
                                </span>
                                <span class="value"><asp:Literal ID="lit3MRetard" runat="server" Text="0 $" /></span>
                            </div>
                        </div>
                    </a>

                </div>
            </div>

            <!-- Section détail -->
            <h3 class="section-title">
                Détail — <span class="periode-label"><asp:Literal ID="litPeriodeLabel" runat="server" Text="3 Months" /></span>
            </h3>

            <div class="detail-card">

                <!-- Tabs : Collecté / À recevoir / Retard -->
                <div class="tabs-row">
                    <a href="javascript:void(0)" runat="server" id="tabCollecte" class="tab-btn collecte"
                       onclick="selectTab('COLLECTE')">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/>
                            <polyline points="16 7 22 7 22 13"/>
                        </svg>
                        Collecté
                        <span class="tab-pill"><asp:Literal ID="litTabCollecteCount" runat="server" Text="0" /></span>
                    </a>
                    <a href="javascript:void(0)" runat="server" id="tabRecevoir" class="tab-btn recevoir"
                       onclick="selectTab('RECEVOIR')">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/>
                            <polyline points="16 17 22 17 22 11"/>
                        </svg>
                        À recevoir
                        <span class="tab-pill"><asp:Literal ID="litTabRecevoirCount" runat="server" Text="0" /></span>
                    </a>
                    <a href="javascript:void(0)" runat="server" id="tabRetard" class="tab-btn retard"
                       onclick="selectTab('RETARD')">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>
                            <path d="M12 9v4"/>
                            <path d="M12 17h.01"/>
                        </svg>
                        Retard
                        <span class="tab-pill"><asp:Literal ID="litTabRetardCount" runat="server" Text="0" /></span>
                    </a>
                </div>

                <!-- Liste des items -->
                <div class="item-list">
                    <asp:Repeater ID="rpItems" runat="server"
                        OnItemDataBound="rpItems_ItemDataBound">
                        <ItemTemplate>
                            <asp:Literal ID="litItemHtml" runat="server" />
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                        <div class="empty-state">
                            <div class="ico">📭</div>
                            <div class="msg">Aucune vente dans cette catégorie pour cette période.</div>
                        </div>
                    </asp:PlaceHolder>
                </div>

            </div>

        </asp:PlaceHolder>

    </div>

    <script type="text/javascript">
        // ─── Sélection période → dispatcher central ───
        function selectPeriode(periode) {
            document.getElementById('hfPeriodeSel').value = periode;
            document.getElementById('hfActionName').value = 'ChangePeriode';
            document.getElementById('hfActionArg').value = periode;
            __doPostBack(__dispatchTarget, '');
        }

        // ─── Sélection tab → dispatcher central ───
        function selectTab(tab) {
            document.getElementById('hfTabSel').value = tab;
            document.getElementById('hfActionName').value = 'ChangeTab';
            document.getElementById('hfActionArg').value = tab;
            __doPostBack(__dispatchTarget, '');
        }

        // ─── Toggle masquer/afficher le solde bancaire ───
        var __soldeMasque = false;
        var __soldeOriginal = '';
        function toggleSolde() {
            var elValue = document.getElementById('bankValue');
            var btn = document.getElementById('btnToggleSolde');
            var icon = document.getElementById('iconEye');
            if (!elValue || !icon) return;

            __soldeMasque = !__soldeMasque;
            if (__soldeMasque) {
                __soldeOriginal = elValue.innerText;
                elValue.innerText = '••••••';
                btn.title = 'Afficher le solde';
                // Icône œil-barré
                icon.innerHTML =
                    '<path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/>' +
                    '<path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/>' +
                    '<path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/>' +
                    '<line x1="2" x2="22" y1="2" y2="22"/>';
            } else {
                elValue.innerText = __soldeOriginal;
                btn.title = 'Masquer le solde';
                // Icône œil ouvert
                icon.innerHTML =
                    '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/>' +
                    '<circle cx="12" cy="12" r="3"/>';
            }
        }
    </script>

</asp:Content>
