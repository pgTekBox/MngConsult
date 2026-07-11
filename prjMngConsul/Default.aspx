<%@ Page Title="Home Page" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.vb" Inherits="MngConsul._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

<style>
    :root{
        --mc-bg:#f6f8fc;
        --mc-card:#ffffff;
        --mc-text:#0f172a;
        --mc-muted:#64748b;
        --mc-line:#e2e8f0;
        --mc-primary:#2563eb;
        --mc-primary-2:#1d4ed8;
        --mc-success:#16a34a;
        --mc-warning:#f59e0b;
        --mc-danger:#ef4444;
        --mc-radius:18px;
        --mc-radius-sm:14px;
        --mc-shadow:0 12px 32px rgba(15,23,42,.08);
        --mc-shadow-soft:0 6px 18px rgba(15,23,42,.05);
    }

    .home-page{
        padding:24px;
        background:var(--mc-bg);
        min-height:calc(100vh - 140px);
    }

    .home-wrap{
        max-width:1400px;
        margin:0 auto;
        display:flex;
        flex-direction:column;
        gap:22px;
    }

    .hero{
        background:linear-gradient(135deg, #2563eb 0%, #1d4ed8 45%, #0f172a 100%);
        color:#fff;
        border-radius:24px;
        padding:28px;
        box-shadow:var(--mc-shadow);
        display:grid;
        grid-template-columns:1.5fr .9fr;
        gap:20px;
        overflow:hidden;
        position:relative;
    }

    .hero:before{
        content:"";
        position:absolute;
        right:-60px;
        top:-60px;
        width:220px;
        height:220px;
        border-radius:50%;
        background:rgba(255,255,255,.08);
    }

    .hero:after{
        content:"";
        position:absolute;
        right:120px;
        bottom:-80px;
        width:180px;
        height:180px;
        border-radius:50%;
        background:rgba(255,255,255,.06);
    }

    .hero-left,
    .hero-right{
        position:relative;
        z-index:0;
    }

    .hero-badge{
        display:inline-flex;
        align-items:center;
        gap:8px;
        padding:8px 12px;
        border-radius:999px;
        background:rgba(255,255,255,.12);
        border:1px solid rgba(255,255,255,.18);
        font-size:12px;
        font-weight:700;
        letter-spacing:.3px;
        margin-bottom:14px;
    }

    .hero-title{
        font-size:32px;
        line-height:1.15;
        font-weight:900;
        margin:0 0 10px 0;
    }

    .hero-sub{
        color:rgba(255,255,255,.86);
        font-size:15px;
        line-height:1.6;
        max-width:760px;
        margin:0;
    }

    .hero-actions{
        margin-top:18px;
        display:flex;
        flex-wrap:wrap;
        gap:12px;
    }

    .btn-hero,
    .btn-soft{
        display:inline-flex;
        align-items:center;
        justify-content:center;
        min-height:42px;
        padding:0 16px;
        border-radius:12px;
        text-decoration:none;
        font-weight:700;
        transition:.18s ease;
        border:1px solid transparent;
    }

    .btn-hero{
        background:#fff;
        color:#0f172a;
    }

    .btn-hero:hover{
        transform:translateY(-1px);
        box-shadow:0 10px 22px rgba(0,0,0,.16);
    }

    .btn-soft{
        background:rgba(255,255,255,.10);
        color:#fff;
        border-color:rgba(255,255,255,.16);
    }

    .btn-soft:hover{
        background:rgba(255,255,255,.16);
    }

    .hero-mini-stats{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:12px;
        align-self:stretch;
    }

    .mini-stat{
        background:rgba(255,255,255,.12);
        border:1px solid rgba(255,255,255,.18);
        border-radius:16px;
        padding:16px;
        backdrop-filter:blur(6px);
    }

    .mini-stat-label{
        font-size:12px;
        text-transform:uppercase;
        letter-spacing:.4px;
        color:rgba(255,255,255,.76);
        margin-bottom:6px;
    }

    .mini-stat-value{
        font-size:24px;
        font-weight:900;
        margin-bottom:4px;
    }

    .mini-stat-note{
        font-size:13px;
        color:rgba(255,255,255,.82);
    }

    .kpi-grid{
        display:grid;
        grid-template-columns:repeat(4, minmax(0,1fr));
        gap:18px;
    }

    .kpi-card{
        background:var(--mc-card);
        border:1px solid var(--mc-line);
        border-radius:var(--mc-radius);
        box-shadow:var(--mc-shadow-soft);
        padding:20px;
        display:flex;
        flex-direction:column;
        gap:10px;
    }

    .kpi-head{
        display:flex;
        align-items:center;
        justify-content:space-between;
        gap:12px;
    }

    .kpi-label{
        font-size:13px;
        color:var(--mc-muted);
        font-weight:700;
    }

    .kpi-icon{
        width:42px;
        height:42px;
        border-radius:12px;
        display:flex;
        align-items:center;
        justify-content:center;
        font-size:20px;
        background:#eff6ff;
    }

    .kpi-value{
        font-size:30px;
        line-height:1;
        font-weight:900;
        color:var(--mc-text);
    }

    .kpi-foot{
        font-size:13px;
        color:var(--mc-muted);
    }

    .layout-grid{
        display:grid;
        grid-template-columns:1.2fr .8fr;
        gap:22px;
    }

    .panel{
        background:var(--mc-card);
        border:1px solid var(--mc-line);
        border-radius:22px;
        box-shadow:var(--mc-shadow-soft);
        overflow:hidden;
    }

    .panel-head{
        padding:18px 20px;
        border-bottom:1px solid var(--mc-line);
        display:flex;
        align-items:center;
        justify-content:space-between;
        gap:12px;
        flex-wrap:wrap;
    }

    .panel-title{
        font-size:18px;
        font-weight:800;
        color:var(--mc-text);
        margin:0;
    }

    .panel-sub{
        font-size:13px;
        color:var(--mc-muted);
        margin-top:4px;
    }

    .panel-body{
        padding:18px 20px 20px 20px;
    }

    .module-grid{
        display:grid;
        grid-template-columns:repeat(3, minmax(0,1fr));
        gap:14px;
    }

    .module-card{
        display:block;
        text-decoration:none;
        color:inherit;
        background:#fff;
        border:1px solid var(--mc-line);
        border-radius:18px;
        padding:18px;
        transition:.18s ease;
        box-shadow:0 4px 14px rgba(15,23,42,.04);
    }

    .module-card:hover{
        transform:translateY(-3px);
        border-color:#bfdbfe;
        box-shadow:0 12px 22px rgba(37,99,235,.10);
    }

    .module-icon{
        width:48px;
        height:48px;
        border-radius:14px;
        display:flex;
        align-items:center;
        justify-content:center;
        font-size:24px;
        margin-bottom:12px;
        background:#eff6ff;
    }

    .module-title{
        font-size:16px;
        font-weight:800;
        color:var(--mc-text);
        margin-bottom:6px;
    }

    .module-desc{
        font-size:13px;
        line-height:1.5;
        color:var(--mc-muted);
    }

    .quick-actions{
        display:grid;
        grid-template-columns:1fr 1fr;
        gap:12px;
    }

    .quick-btn{
        display:flex;
        align-items:center;
        gap:12px;
        min-height:56px;
        border-radius:16px;
        text-decoration:none;
        padding:0 14px;
        font-weight:700;
        border:1px solid var(--mc-line);
        color:var(--mc-text);
        background:#fff;
        transition:.18s ease;
    }

    .quick-btn:hover{
        transform:translateY(-2px);
        border-color:#bfdbfe;
        box-shadow:0 10px 18px rgba(37,99,235,.08);
    }

    .quick-ico{
        width:36px;
        height:36px;
        border-radius:10px;
        display:flex;
        align-items:center;
        justify-content:center;
        background:#eff6ff;
        font-size:18px;
        flex:0 0 36px;
    }

    .table-wrap{
        width:100%;
        overflow:auto;
    }

    .data-table{
        width:100%;
        border-collapse:collapse;
        min-width:650px;
    }

    .data-table th{
        text-align:left;
        font-size:12px;
        letter-spacing:.3px;
        text-transform:uppercase;
        color:var(--mc-muted);
        padding:12px 10px;
        border-bottom:1px solid var(--mc-line);
        background:#f8fafc;
    }

    .data-table td{
        padding:14px 10px;
        border-bottom:1px solid #eef2f7;
        color:var(--mc-text);
        font-size:14px;
        vertical-align:middle;
    }

    .data-table tr:last-child td{
        border-bottom:none;
    }

    .badge{
        display:inline-flex;
        align-items:center;
        padding:6px 10px;
        border-radius:999px;
        font-size:12px;
        font-weight:800;
        line-height:1;
        white-space:nowrap;
    }

    .badge-success{
        background:#dcfce7;
        color:#166534;
    }

    .badge-warning{
        background:#fef3c7;
        color:#92400e;
    }

    .badge-danger{
        background:#fee2e2;
        color:#991b1b;
    }

    .activity-list{
        display:flex;
        flex-direction:column;
        gap:14px;
    }

    .activity-item{
        display:flex;
        align-items:flex-start;
        gap:12px;
        padding:14px;
        border:1px solid var(--mc-line);
        border-radius:16px;
        background:#fff;
    }

    .activity-dot{
        width:12px;
        height:12px;
        border-radius:50%;
        margin-top:4px;
        flex:0 0 12px;
    }

    .dot-blue{ background:#2563eb; }
    .dot-green{ background:#16a34a; }
    .dot-orange{ background:#f59e0b; }
    .dot-red{ background:#ef4444; }

    .activity-main{
        flex:1;
        min-width:0;
    }

    .activity-text{
        font-size:14px;
        color:var(--mc-text);
        font-weight:600;
        margin-bottom:3px;
    }

    .activity-time{
        font-size:12px;
        color:var(--mc-muted);
    }

    .link-muted{
        color:var(--mc-primary);
        text-decoration:none;
        font-weight:700;
        font-size:13px;
    }

    .link-muted:hover{
        text-decoration:underline;
    }

    @media (max-width: 1180px){
        .kpi-grid{
            grid-template-columns:repeat(2, minmax(0,1fr));
        }

        .layout-grid{
            grid-template-columns:1fr;
        }

        .module-grid{
            grid-template-columns:repeat(2, minmax(0,1fr));
        }

        .hero{
            grid-template-columns:1fr;
        }
    }

    @media (max-width: 760px){
        .home-page{
            padding:14px;
        }

        .hero{
            padding:20px;
            border-radius:20px;
        }

        .hero-title{
            font-size:24px;
        }

        .hero-mini-stats{
            grid-template-columns:1fr;
        }

        .kpi-grid{
            grid-template-columns:1fr;
        }

        .module-grid,
        .quick-actions{
            grid-template-columns:1fr;
        }

        .panel-head,
        .panel-body{
            padding-left:14px;
            padding-right:14px;
        }
    }

    /* ===== Boîte de bienvenue dépliable ===== */
    .welcome-box{
        background:linear-gradient(135deg,#2563eb 0%,#06b6d4 100%);
        border-radius:20px;
        box-shadow:var(--mc-shadow);
        overflow:hidden;
        color:#fff;
    }

    .welcome-summary{
        display:flex;
        align-items:center;
        gap:16px;
        padding:18px 22px;
        cursor:pointer;
        list-style:none;
        user-select:none;
    }
    .welcome-summary::-webkit-details-marker{ display:none; }

    .wb-emoji{
        font-size:26px;
        width:48px;
        height:48px;
        flex:0 0 48px;
        border-radius:14px;
        background:rgba(255,255,255,.18);
        display:flex;
        align-items:center;
        justify-content:center;
    }

    .wb-main{ flex:1; min-width:0; line-height:1.3; }
    .wb-title{ font-size:18px; font-weight:900; display:block; }
    .wb-sub{
        font-size:13px;
        color:rgba(255,255,255,.9);
        display:block;
        margin-top:2px;
        white-space:nowrap;
        overflow:hidden;
        text-overflow:ellipsis;
    }

    .wb-chevron{
        flex:0 0 auto;
        font-size:22px;
        transition:transform .22s ease;
        opacity:.9;
    }
    .welcome-box[open] .wb-chevron{ transform:rotate(180deg); }

    .wb-content{
        background:#fff;
        color:var(--mc-text);
        padding:8px 22px 24px 22px;
    }

    .wb-section-title{
        font-size:12px;
        font-weight:800;
        color:var(--mc-muted);
        text-transform:uppercase;
        letter-spacing:.1em;
        margin:20px 0 12px 0;
    }

    .wb-steps{
        display:grid;
        grid-template-columns:repeat(2,1fr);
        gap:14px;
    }

    .wb-step{
        display:flex;
        gap:14px;
        padding:16px;
        border:1px solid var(--mc-line);
        border-radius:14px;
        text-decoration:none;
        color:inherit;
        background:#fff;
        transition:.15s ease;
    }
    .wb-step:hover{
        transform:translateY(-2px);
        border-color:#bfdbfe;
        box-shadow:0 12px 22px rgba(37,99,235,.10);
    }

    .wb-step-ico{
        width:44px; height:44px;
        flex:0 0 44px;
        border-radius:12px;
        display:flex; align-items:center; justify-content:center;
        font-size:22px;
        color:#fff;
    }
    .wb-ico-blue{ background:linear-gradient(135deg,#3b82f6,#2563eb); }
    .wb-ico-cyan{ background:linear-gradient(135deg,#06b6d4,#0891b2); }
    .wb-ico-green{ background:linear-gradient(135deg,#10b981,#059669); }
    .wb-ico-orange{ background:linear-gradient(135deg,#f59e0b,#d97706); }

    .wb-step-num{
        font-size:11px; font-weight:800;
        color:var(--mc-muted);
        text-transform:uppercase; letter-spacing:.06em;
        margin-bottom:3px;
    }
    .wb-step-title{ font-size:15px; font-weight:800; margin-bottom:3px; }
    .wb-step-desc{ font-size:13px; color:var(--mc-muted); line-height:1.5; }

    .wb-tips{
        background:linear-gradient(135deg,#fffbeb,#fef3c7);
        border:1px solid var(--mc-warning);
        border-radius:14px;
        padding:18px 20px;
    }
    .wb-tips h4{
        font-size:14px; font-weight:800; color:#78350f;
        margin:0 0 10px 0;
    }
    .wb-tips ul{ list-style:none; padding:0; margin:0; }
    .wb-tips li{
        display:flex; align-items:flex-start; gap:8px;
        padding:5px 0; font-size:13px; color:#92400e; line-height:1.5;
    }
    .wb-tips li .ck{ color:var(--mc-warning); font-weight:900; margin-top:1px; }

    .wb-resources{
        display:grid;
        grid-template-columns:repeat(3,1fr);
        gap:12px;
    }
    .wb-res{
        display:flex; align-items:center; gap:10px;
        padding:12px 14px;
        background:#fff;
        border:1px solid var(--mc-line);
        border-radius:10px;
        text-decoration:none;
        color:var(--mc-text);
        font-size:13px; font-weight:700;
        transition:.15s ease;
    }
    .wb-res:hover{ border-color:#bfdbfe; color:var(--mc-primary); background:#f8fafc; }

    @media (max-width:760px){
        .wb-steps{ grid-template-columns:1fr; }
        .wb-resources{ grid-template-columns:1fr; }
        .wb-sub{ white-space:normal; }
    }
</style>

<main class="home-page">
    <div class="home-wrap">

        <!-- BOÎTE DE BIENVENUE (onboarding dépliable) -->
        <details class="welcome-box">
            <summary class="welcome-summary">
                <span class="wb-emoji" aria-hidden="true">👋</span>
                <span class="wb-main">
                    <span class="wb-title"><%= L("wbGreetBefore") %><asp:Literal ID="litFirstName" runat="server" /><%= L("wbGreetAfter") %></span>
                    <span class="wb-sub"><%= L("wbTrialBefore") %><asp:Literal ID="litPlanName" runat="server" Text="Solo" /><%= L("wbTrialMiddle") %><asp:Literal ID="litTrialEnd" runat="server" /> — <%= L("wbToggle") %></span>
                </span>
                <span class="wb-chevron" aria-hidden="true">⌄</span>
            </summary>

            <div class="wb-content">

                <!-- Prochaines étapes -->
                <div class="wb-section-title"><%= L("nextSteps") %></div>
                <div class="wb-steps">
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfNewUser.aspx") %>">
                        <span class="wb-step-ico wb-ico-blue">👤</span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 1</span>
                            <div class="wb-step-title"><%= L("step1Title") %></div>
                            <div class="wb-step-desc"><%= L("step1Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfCustomers.aspx") %>">
                        <span class="wb-step-ico wb-ico-cyan">👥</span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 2</span>
                            <div class="wb-step-title"><%= L("step2Title") %></div>
                            <div class="wb-step-desc"><%= L("step2Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfProducts.aspx") %>">
                        <span class="wb-step-ico wb-ico-green">💲</span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 3</span>
                            <div class="wb-step-title"><%= L("step3Title") %></div>
                            <div class="wb-step-desc"><%= L("step3Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfAgenda.aspx") %>">
                        <span class="wb-step-ico wb-ico-orange">📅</span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 4</span>
                            <div class="wb-step-title"><%= L("step4Title") %></div>
                            <div class="wb-step-desc"><%= L("step4Desc") %></div>
                        </span>
                    </a>
                </div>

                <!-- Conseils -->
                <div class="wb-section-title"><%= L("tipsTitle") %></div>
                <div class="wb-tips">
                    <h4><%= L("tipsHead") %></h4>
                    <ul>
                        <li><span class="ck" aria-hidden="true">✓</span><span><%= L("tip1") %></span></li>
                        <li><span class="ck" aria-hidden="true">✓</span><span><%= L("tip2") %></span></li>
                        <li><span class="ck" aria-hidden="true">✓</span><span><%= L("tip3") %></span></li>
                        <li><span class="ck" aria-hidden="true">✓</span><span><%= L("tip4") %></span></li>
                    </ul>
                </div>

                <!-- Ressources -->
                <div class="wb-section-title"><%= L("resourcesTitle") %></div>
                <div class="wb-resources">
                    <a class="wb-res" href="<%= ResolveUrl("~/wbfHelp.aspx") %>">❓ <%= L("helpCenter") %></a>
                    <a class="wb-res" href="<%= ResolveUrl("~/wbfTutorials.aspx") %>">🎬 <%= L("videoTutorials") %></a>
                    <a class="wb-res" href="mailto:support@60sec.ca">✉️ <%= L("contactSupport") %></a>
                </div>

            </div>
        </details>

        <!-- HERO -->
        <section class="hero">
            <div class="hero-left">
                <div class="hero-badge"><%= L("heroBadge") %></div>

                <h1 class="hero-title">
                    <%= L("heroTitle") %>
                </h1>

                <p class="hero-sub">
                    <%= L("heroSub") %>
                </p>

                <div class="hero-actions">
                    <a class="btn-hero" href="wbfInvoiceEdit.aspx"><%= L("btnNewInvoice") %></a>
                    <a class="btn-soft" href="wbfCustomers.aspx"><%= L("btnViewCustomers") %></a>
                    <a class="btn-soft" href="Settings.aspx"><%= L("btnSettings") %></a>
                </div>
            </div>

            <div class="hero-right">
                <div class="hero-mini-stats">
                    <div class="mini-stat">
                        <div class="mini-stat-label"><%= L("msSalesLabel") %></div>
                        <div class="mini-stat-value">24 580 $</div>
                        <div class="mini-stat-note"><%= L("msSalesNote") %></div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label"><%= L("msOpenInvLabel") %></div>
                        <div class="mini-stat-value">18</div>
                        <div class="mini-stat-note"><%= L("msOpenInvNote") %></div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label"><%= L("msActiveCustLabel") %></div>
                        <div class="mini-stat-value">326</div>
                        <div class="mini-stat-note"><%= L("msActiveCustNote") %></div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label"><%= L("msProductsLabel") %></div>
                        <div class="mini-stat-value">1 248</div>
                        <div class="mini-stat-note"><%= L("msProductsNote") %></div>
                    </div>
                </div>
            </div>
        </section>

        <!-- KPI -->
        <section class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label"><%= L("kpiCustomers") %></div>
                    <div class="kpi-icon">👥</div>
                </div>
                <div class="kpi-value">326</div>
                <div class="kpi-foot"><%= L("kpiCustomersFoot") %></div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label"><%= L("kpiInvoices") %></div>
                    <div class="kpi-icon">🧾</div>
                </div>
                <div class="kpi-value">87</div>
                <div class="kpi-foot"><%= L("kpiInvoicesFoot") %></div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label"><%= L("kpiProducts") %></div>
                    <div class="kpi-icon">📦</div>
                </div>
                <div class="kpi-value">1 248</div>
                <div class="kpi-foot"><%= L("kpiProductsFoot") %></div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label"><%= L("kpiRevenue") %></div>
                    <div class="kpi-icon">💰</div>
                </div>
                <div class="kpi-value">24 580 $</div>
                <div class="kpi-foot"><%= L("kpiRevenueFoot") %></div>
            </div>
        </section>

        <section class="layout-grid">

            <!-- GAUCHE -->
            <div style="display:flex; flex-direction:column; gap:22px;">

                <!-- MODULES -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title"><%= L("modulesTitle") %></div>
                            <div class="panel-sub"><%= L("modulesSub") %></div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="module-grid">
                            <a class="module-card" href="wbfCustomers.aspx">
                                <div class="module-icon">👥</div>
                                <div class="module-title"><%= L("modClients") %></div>
                                <div class="module-desc">
                                    <%= L("modClientsDesc") %>
                                </div>
                            </a>

                            <a class="module-card" href="wbfInvoice.aspx">
                                <div class="module-icon">🧾</div>
                                <div class="module-title"><%= L("modInvoices") %></div>
                                <div class="module-desc">
                                    <%= L("modInvoicesDesc") %>
                                </div>
                            </a>

                            <a class="module-card" href="wbfProducts.aspx">
                                <div class="module-icon">📦</div>
                                <div class="module-title"><%= L("modProducts") %></div>
                                <div class="module-desc">
                                    <%= L("modProductsDesc") %>
                                </div>
                            </a>

                            <a class="module-card" href="wbfSuppliers.aspx">
                                <div class="module-icon">🏭</div>
                                <div class="module-title"><%= L("modSuppliers") %></div>
                                <div class="module-desc">
                                    <%= L("modSuppliersDesc") %>
                                </div>
                            </a>

                            <a class="module-card" href="wbfReceipt.aspx">
                                <div class="module-icon">🧾</div>
                                <div class="module-title"><%= L("modReceipts") %></div>
                                <div class="module-desc">
                                    <%= L("modReceiptsDesc") %>
                                </div>
                            </a>

                            <a class="module-card" href="Settings.aspx">
                                <div class="module-icon">⚙️</div>
                                <div class="module-title"><%= L("modSettings") %></div>
                                <div class="module-desc">
                                    <%= L("modSettingsDesc") %>
                                </div>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- FACTURES RÉCENTES -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title"><%= L("recentInvTitle") %></div>
                            <div class="panel-sub"><%= L("recentInvSub") %></div>
                        </div>
                        <a class="link-muted" href="wbfInvoice.aspx"><%= L("viewAll") %></a>
                    </div>

                    <div class="panel-body" style="padding-top:0;">
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th><%= L("thNo") %></th>
                                        <th><%= L("thClient") %></th>
                                        <th><%= L("thDate") %></th>
                                        <th><%= L("thAmount") %></th>
                                        <th><%= L("thStatus") %></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>#1048</td>
                                        <td>Baignoire Expert</td>
                                        <td><%= L("d1") %></td>
                                        <td>1 245,00 $</td>
                                        <td><span class="badge badge-warning"><%= L("stOpen") %></span></td>
                                    </tr>
                                    <tr>
                                        <td>#1047</td>
                                        <td>Construction Nova</td>
                                        <td><%= L("d2") %></td>
                                        <td>2 890,00 $</td>
                                        <td><span class="badge badge-success"><%= L("stPaid") %></span></td>
                                    </tr>
                                    <tr>
                                        <td>#1046</td>
                                        <td>Immeubles Rive-Nord</td>
                                        <td><%= L("d2") %></td>
                                        <td>780,00 $</td>
                                        <td><span class="badge badge-warning"><%= L("stOpen") %></span></td>
                                    </tr>
                                    <tr>
                                        <td>#1045</td>
                                        <td>Atelier du Bain</td>
                                        <td><%= L("d3") %></td>
                                        <td>560,00 $</td>
                                        <td><span class="badge badge-danger"><%= L("stOverdue") %></span></td>
                                    </tr>
                                    <tr>
                                        <td>#1044</td>
                                        <td>Gestion MTL</td>
                                        <td><%= L("d4") %></td>
                                        <td>4 120,00 $</td>
                                        <td><span class="badge badge-success"><%= L("stPaid") %></span></td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

            </div>

            <!-- DROITE -->
            <div style="display:flex; flex-direction:column; gap:22px;">

                <!-- ACTIONS RAPIDES -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title"><%= L("quickTitle") %></div>
                            <div class="panel-sub"><%= L("quickSub") %></div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="quick-actions">
                            <a class="quick-btn" href="wbfInvoiceEdit.aspx">
                                <span class="quick-ico">➕</span>
                                <span><%= L("qaCreateInvoice") %></span>
                            </a>

                            <a class="quick-btn" href="wbfCustomers.aspx">
                                <span class="quick-ico">👤</span>
                                <span><%= L("qaAddCustomer") %></span>
                            </a>

                            <a class="quick-btn" href="wbfProducts.aspx">
                                <span class="quick-ico">📦</span>
                                <span><%= L("qaAddProduct") %></span>
                            </a>

                            <a class="quick-btn" href="wbfReceipt.aspx">
                                <span class="quick-ico">💵</span>
                                <span><%= L("qaViewReceipts") %></span>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- ACTIVITÉS -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title"><%= L("activityTitle") %></div>
                            <div class="panel-sub"><%= L("activitySub") %></div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="activity-list">
                            <div class="activity-item">
                                <span class="activity-dot dot-blue"></span>
                                <div class="activity-main">
                                    <div class="activity-text"><%= L("act1") %></div>
                                    <div class="activity-time"><%= L("act1Time") %></div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-green"></span>
                                <div class="activity-main">
                                    <div class="activity-text"><%= L("act2") %></div>
                                    <div class="activity-time"><%= L("act2Time") %></div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-orange"></span>
                                <div class="activity-main">
                                    <div class="activity-text"><%= L("act3") %></div>
                                    <div class="activity-time"><%= L("act3Time") %></div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-red"></span>
                                <div class="activity-main">
                                    <div class="activity-text"><%= L("act4") %></div>
                                    <div class="activity-time"><%= L("act4Time") %></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- PETITE CARTE INFO -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title"><%= L("summaryTitle") %></div>
                            <div class="panel-sub"><%= L("summarySub") %></div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div style="display:flex; flex-direction:column; gap:12px;">
                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;"><%= L("sumCustomers") %></span>
                                <strong><%= L("sumCustomersVal") %></strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;"><%= L("sumTaxes") %></span>
                                <strong><%= L("sumTaxesVal") %></strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;"><%= L("sumEmails") %></span>
                                <strong><%= L("sumEmailsVal") %></strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;"><%= L("sumPdf") %></span>
                                <strong><%= L("sumPdfVal") %></strong>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </section>
    </div>
</main>

</asp:Content>