<%@ Page Title="AI Payment" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfAIPaiement.aspx.vb"
    Inherits="MngConsul.wbfAIPaiement" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* ─── Conteneur ─── */
        .ai-page {
            max-width: 1300px; margin: 0 auto; padding: 24px;
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            min-height: calc(100vh - 100px);
        }

        /* ─── Header ─── */
        .ai-header {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 0;
            margin: -24px -24px 24px -24px;
            padding: 16px 24px;
            display: flex; justify-content: space-between; align-items: center;
        }
        .ai-header h1 {
            margin: 0; font-size: 24px; color: #1e293b; font-weight: 700;
        }
        .ai-header .subtitle {
            margin: 4px 0 0 0; font-size: 13px; color: #64748b;
        }
        .ai-header .left { display: flex; align-items: center; gap: 12px; }
        .ai-header .back-btn {
            background: transparent; border: none; cursor: pointer;
            padding: 8px; border-radius: 8px; transition: background 0.15s;
            color: #475569;
        }
        .ai-header .back-btn:hover { background: #f1f5f9; }
        .ai-header .currency-box { text-align: right; }
        .ai-header .currency-label {
            font-size: 11px; color: #64748b; margin: 0;
        }
        .ai-header .currency-value {
            font-size: 14px; font-weight: 600; color: #334155; margin: 0;
        }

        /* ─── Page title ─── */
        .ai-page-title { margin-bottom: 32px; }
        .ai-page-title h2 {
            font-size: 28px; font-weight: 700; color: #1e293b; margin: 0 0 4px 0;
        }
        .ai-page-title p {
            color: #475569; margin: 0; font-size: 14px;
        }

        /* ─── Card filtre période ─── */
        .filter-card {
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
            border: 1px solid #e2e8f0;
            padding: 24px;
            margin-bottom: 24px;
        }
        .filter-card-header {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 20px; flex-wrap: wrap; gap: 16px;
        }
        .filter-card-header h3 {
            font-size: 18px; font-weight: 700; color: #1e293b; margin: 0 0 2px 0;
        }
        .filter-card-header p {
            color: #64748b; margin: 0; font-size: 13px;
        }
        .filter-totals { display: flex; align-items: center; gap: 20px; }
        .filter-totals .stat { text-align: right; }
        .filter-totals .stat-label {
            font-size: 11px; color: #64748b; font-weight: 500; margin: 0;
        }
        .filter-totals .stat-value {
            font-size: 22px; font-weight: 700; color: #1e293b; margin: 0;
        }
        .filter-totals .stat-value.amount { color: #059669; }
        .filter-totals .divider {
            width: 1px; height: 40px; background: #e2e8f0;
        }

        /* ─── Boutons période ─── */
        .periods-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
            gap: 12px;
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
            border-color: #10b981; background: #ecfdf5;
            box-shadow: 0 4px 6px -1px rgba(16,185,129,0.1);
        }
        .period-btn-header {
            display: flex; align-items: center; gap: 12px; margin-bottom: 12px;
        }
        .period-icon {
            width: 32px; height: 32px; border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            color: #fff; flex-shrink: 0;
        }
        .period-icon-today  { background: linear-gradient(135deg, #3b82f6, #2563eb); }
        .period-icon-week   { background: linear-gradient(135deg, #06b6d4, #0891b2); }
        .period-icon-month  { background: linear-gradient(135deg, #14b8a6, #0d9488); }
        .period-icon-3month { background: linear-gradient(135deg, #10b981, #059669); }
        .period-btn.active .period-name { color: #047857; }
        .period-name { font-weight: 700; font-size: 14px; color: #1e293b; }

        .period-counters { display: flex; gap: 8px; }
        .counter-box {
            flex: 1; border-radius: 8px; padding: 6px 4px;
            display: flex; flex-direction: column; align-items: center;
        }
        .counter-box.cat-gov { background: #eff6ff; }
        .counter-box.cat-frn { background: #fffbeb; }
        .counter-box.cat-emp { background: #f0fdfa; }
        .counter-box svg {
            width: 12px; height: 12px; color: #64748b; margin-bottom: 2px;
        }
        .counter-box .count {
            font-size: 12px; font-weight: 700; color: #334155;
        }

        /* ─── Cartes catégorie accordéon ─── */
        .category-list { display: flex; flex-direction: column; gap: 16px; }
        .category-card {
            background: #fff;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05);
            overflow: hidden;
            transition: all 0.2s;
            min-width: 1200px;
        }
        .category-card.expanded.cat-gov { border-color: #bfdbfe; }
        .category-card.expanded.cat-frn { border-color: #fcd34d; }
        .category-card.expanded.cat-emp { border-color: #99f6e4; }

        .category-header {
            width: 100%; padding: 20px;
            display: flex; align-items: center; justify-content: space-between;
            cursor: pointer; transition: background 0.15s;
            border: none; background: transparent; text-align: left;
        }
        .category-header:hover { background: #f8fafc; }
        .category-card.expanded.cat-gov .category-header { background: #eff6ff; }
        .category-card.expanded.cat-frn .category-header { background: #fffbeb; }
        .category-card.expanded.cat-emp .category-header { background: #f0fdfa; }

        .category-header-left {
            display: flex; align-items: center; gap: 16px;
        }
        .category-icon {
            width: 48px; height: 48px; border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            color: #fff; flex-shrink: 0;
        }
        .category-icon.cat-gov { background: linear-gradient(135deg, #3b82f6, #2563eb); }
        .category-icon.cat-frn { background: linear-gradient(135deg, #f59e0b, #d97706); }
        .category-icon.cat-emp { background: linear-gradient(135deg, #14b8a6, #0d9488); }

        .category-info h4 {
            font-size: 18px; font-weight: 700; color: #1e293b; margin: 0;
        }
        .category-info p {
            font-size: 13px; color: #64748b; margin: 2px 0 0 0;
        }
        .category-header-right {
            display: flex; align-items: center; gap: 16px;
        }
        .category-total .label {
            font-size: 11px; color: #64748b; font-weight: 500; margin: 0; text-align: right;
        }
        .category-total .value {
            font-size: 20px; font-weight: 700; color: #059669; margin: 0;
        }
        .category-badge {
            font-size: 11px; font-weight: 700; padding: 6px 12px; border-radius: 999px;
        }
        .category-badge.cat-gov { background: #dbeafe; color: #1d4ed8; }
        .category-badge.cat-frn { background: #fef3c7; color: #b45309; }
        .category-badge.cat-emp { background: #ccfbf1; color: #0f766e; }
        .chevron {
            width: 20px; height: 20px; color: #94a3b8;
            transition: transform 0.2s;
        }
        .category-card.expanded .chevron { transform: rotate(180deg); }

        /* ★ ★ ★ Toggle JS pur : caché par défaut, visible si expanded */
        .category-body { display: none; border-top: 1px solid #e2e8f0; }
        .category-card.expanded .category-body { display: block; }

        .category-bar {
            display: flex; align-items: center; justify-content: space-between;
            padding: 12px 20px; background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
        }
        .category-bar .info {
            font-size: 13px; color: #475569; font-weight: 500;
        }
        .pay-all-btn {
            display: inline-flex; align-items: center; gap: 8px;
            padding: 6px 16px; border-radius: 8px; border: none;
            color: #fff; font-size: 13px; font-weight: 600;
            cursor: pointer; transition: all 0.15s;
        }
        .pay-all-btn.cat-gov { background: linear-gradient(90deg, #3b82f6, #2563eb); }
        .pay-all-btn.cat-frn { background: linear-gradient(90deg, #f59e0b, #d97706); }
        .pay-all-btn.cat-emp { background: linear-gradient(90deg, #14b8a6, #0d9488); }
        .pay-all-btn:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.15); }

        .pay-table { width: 100%; border-collapse: collapse; }
        .pay-table thead th {
            text-align: left; padding: 12px 16px;
            font-size: 11px; font-weight: 700; color: #64748b;
            text-transform: uppercase; letter-spacing: 0.5px;
            border-bottom: 1px solid #e2e8f0;
        }
        .pay-table thead th.right { text-align: right; }
        .pay-table thead th.center { text-align: center; }
        .pay-table tbody td {
            padding: 12px 16px; border-bottom: 1px solid #f1f5f9;
            font-size: 13px; color: #334155;
        }
        .pay-table tbody tr:hover td { background: #fafbfc; }
        .pay-table .id-badge {
            font-family: 'Consolas', 'Monaco', monospace; font-size: 11px;
            color: #64748b; background: #f1f5f9;
            padding: 2px 8px; border-radius: 4px;
        }
        .pay-table .desc { font-weight: 500; color: #1e293b; }
        .pay-table .amount {
            text-align: right; font-weight: 700; color: #059669;
            font-variant-numeric: tabular-nums;
        }
        .pay-table .action-cell { text-align: center; }
        .pay-btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 6px 12px; border-radius: 8px; border: none;
            color: #fff; font-size: 12px; font-weight: 600;
            cursor: pointer; transition: all 0.15s;
        }
        .pay-btn.cat-gov { background: linear-gradient(90deg, #3b82f6, #2563eb); }
        .pay-btn.cat-frn { background: linear-gradient(90deg, #f59e0b, #d97706); }
        .pay-btn.cat-emp { background: linear-gradient(90deg, #14b8a6, #0d9488); }
        .pay-btn:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.15); }

        .empty-state {
            text-align: center; padding: 32px;
            color: #94a3b8; font-size: 13px;
        }

        /* ─── Status message ─── */
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

    <!-- HiddenFields pour mémoriser quelle catégorie est dépliée + dispatcher les actions -->
    <asp:HiddenField ID="hfPeriodeSel" runat="server" Value="3MONTHS" ClientIDMode="Static" />
    <asp:HiddenField ID="hfCategorieOpen" runat="server" Value="Fournisseur" ClientIDMode="Static" />
    <asp:HiddenField ID="hfActionName" runat="server" Value="" ClientIDMode="Static" />
    <asp:HiddenField ID="hfActionArg" runat="server" Value="" ClientIDMode="Static" />

    <!-- LinkButton invisible (mais présent dans le DOM) qui déclenche les actions de paiement -->
    <!-- LinkButton invisible (mais présent dans le DOM) qui déclenche les actions -->
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
                    <h1>AI Payment</h1>
                    <p class="subtitle">Gestion en temps réel avec AI</p>
                </div>
            </div>
            <div class="currency-box">
                <p class="currency-label">Devise</p>
                <p class="currency-value">CAD $</p>
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
                    <div>
                        <h3>Période de paiement</h3>
                        <p>Sélectionnez une période pour voir les paiements</p>
                    </div>
                    <div class="filter-totals">
                        <div class="stat">
                            <p class="stat-label">Transactions</p>
                            <p class="stat-value"><asp:Literal ID="litTotalTrans" runat="server" Text="0" /></p>
                        </div>
                        <div class="divider"></div>
                        <div class="stat">
                            <p class="stat-label">Montant total</p>
                            <p class="stat-value amount"><asp:Literal ID="litTotalMontant" runat="server" Text="0 $" /></p>
                        </div>
                    </div>
                </div>

                <!-- Boutons période -->
                <div class="periods-grid">

                    <!-- TODAY -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodToday"
                       class="period-btn" onclick="selectPeriode('TODAY')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-today">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <span class="period-name">Today</span>
                        </div>
                        <div class="period-counters">
                            <div class="counter-box cat-gov">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litTodayGov" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-frn">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>
                                    <circle cx="17" cy="18" r="2"/>
                                    <circle cx="7" cy="18" r="2"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litTodayFrn" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-emp">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litTodayEmp" runat="server" Text="0" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- WEEK -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodWeek"
                       class="period-btn" onclick="selectPeriode('WEEK')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-week">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <span class="period-name">Week</span>
                        </div>
                        <div class="period-counters">
                            <div class="counter-box cat-gov">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litWeekGov" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-frn">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>
                                    <circle cx="17" cy="18" r="2"/>
                                    <circle cx="7" cy="18" r="2"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litWeekFrn" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-emp">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litWeekEmp" runat="server" Text="0" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- MONTH -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriodMonth"
                       class="period-btn" onclick="selectPeriode('MONTH')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-month">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <span class="period-name">Month</span>
                        </div>
                        <div class="period-counters">
                            <div class="counter-box cat-gov">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litMonthGov" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-frn">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>
                                    <circle cx="17" cy="18" r="2"/>
                                    <circle cx="7" cy="18" r="2"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litMonthFrn" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-emp">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span class="count"><asp:Literal ID="litMonthEmp" runat="server" Text="0" /></span>
                            </div>
                        </div>
                    </a>

                    <!-- 3 MONTHS -->
                    <a href="javascript:void(0)" runat="server" id="btnPeriod3M"
                       class="period-btn active" onclick="selectPeriode('3MONTHS')">
                        <div class="period-btn-header">
                            <div class="period-icon period-icon-3month">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M8 2v4"/><path d="M16 2v4"/>
                                    <rect width="18" height="18" x="3" y="4" rx="2"/>
                                    <path d="M3 10h18"/>
                                </svg>
                            </div>
                            <span class="period-name">3 Months</span>
                        </div>
                        <div class="period-counters">
                            <div class="counter-box cat-gov">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/>
                                </svg>
                                <span class="count"><asp:Literal ID="lit3MGov" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-frn">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>
                                    <circle cx="17" cy="18" r="2"/>
                                    <circle cx="7" cy="18" r="2"/>
                                </svg>
                                <span class="count"><asp:Literal ID="lit3MFrn" runat="server" Text="0" /></span>
                            </div>
                            <div class="counter-box cat-emp">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2"
                                    stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span class="count"><asp:Literal ID="lit3MEmp" runat="server" Text="0" /></span>
                            </div>
                        </div>
                    </a>

                </div>
            </div>

            <!-- Liste des catégories accordéon -->
            <div class="category-list">
                <asp:Repeater ID="rpCategories" runat="server"
                    OnItemDataBound="rpCategories_ItemDataBound">
                    <ItemTemplate>
                        <asp:Literal ID="litCategorieHtml" runat="server" />
                    </ItemTemplate>
                </asp:Repeater>
            </div>

        </asp:PlaceHolder>

    </div>

    <script type="text/javascript">
        // ─── Sélection d'une période → utilise le dispatcher central ───
        function selectPeriode(periode) {
            document.getElementById('hfPeriodeSel').value = periode;
            document.getElementById('hfActionName').value = 'ChangePeriode';
            document.getElementById('hfActionArg').value = periode;
            __doPostBack(__dispatchTarget, '');
        }

        // ─── Toggle UI pur — pas de postback ───
        function toggleCategory(headerElement) {
            var card = headerElement.closest('.category-card');
            if (!card) return;

            var wasExpanded = card.classList.contains('expanded');
            var hf = document.getElementById('hfCategorieOpen');

            // Replier toutes les cartes
            document.querySelectorAll('.category-card').forEach(function (c) {
                c.classList.remove('expanded');
            });

            // Si elle n'était pas dépliée, la déplier
            if (!wasExpanded) {
                card.classList.add('expanded');
                // Mémoriser le nom dans le HiddenField pour survivre aux postbacks
                var titre = card.querySelector('.category-info h4');
                if (hf) hf.value = titre ? titre.textContent.trim() : '';
            } else {
                if (hf) hf.value = '';
            }
        }

        // ─── Restaurer l'état des catégories après chaque rendu (initial + postback) ───
        function restaurerEtatCategories() {
            var hf = document.getElementById('hfCategorieOpen');
            var nomOuvert = hf ? hf.value : '';

            document.querySelectorAll('.category-card').forEach(function (card) {
                var titre = card.querySelector('.category-info h4');
                var nomCategorie = titre ? titre.textContent.trim() : '';

                if (nomCategorie === nomOuvert && nomOuvert !== '') {
                    card.classList.add('expanded');
                } else {
                    card.classList.remove('expanded');
                }
            });
        }

        // Au démarrage initial
        document.addEventListener('DOMContentLoaded', restaurerEtatCategories);
        // Et après chaque postback AJAX Telerik (changement de période)
        if (typeof Sys !== 'undefined' && Sys.WebForms) {
            Sys.WebForms.PageRequestManager.getInstance()
                .add_endRequest(restaurerEtatCategories);
        }

        // ─── Dispatcher pour les actions de paiement (postback serveur) ───
        function dispatchAction(actionName, actionArg) {
            document.getElementById('hfActionName').value = actionName;
            document.getElementById('hfActionArg').value = actionArg;
            __doPostBack(__dispatchTarget, '');
        }

        // ─── Confirmation pour "Payer tout" ───
        function confirmPayerTout(montant) {
            return confirm('Confirmer le paiement de ' + montant + ' ?\n\n' +
                'Toutes les transactions de cette catégorie seront marquées payées.');
        }
    </script>

</asp:Content>
