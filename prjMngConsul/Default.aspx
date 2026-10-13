<%@ Page Title="Home Page" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.vb" Inherits="MngConsul._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
<%-- Le tableau de bord au style « Doux bleu marine » du gabarit 60secondes :
     à gauche, la carte d'accueil (le visage « Le 60 », « Bonjour, prénom ! Voici
     votre journée. »), les trois choses à regarder (urgent / à surveiller / tout
     va bien, calculées), les indicateurs, les modules et les factures récentes ;
     à droite, « Ce mois-ci » sur fond bleu marine, « Mon cabinet certifié » et
     les actions rapides. La boîte de bienvenue dépliable des nouveaux comptes
     reste au-dessus. --%>
<style>
    .home-page{ font-family: var(--mc-font); color: var(--mc-navy); }
    .home-wrap{ display:flex; flex-wrap:wrap; gap:16px; align-items:flex-start; padding:16px; }
    .home-main{ flex: 999 1 480px; min-width:0; display:flex; flex-direction:column; gap:16px; }
    .home-side{ flex: 1 1 270px; max-width:320px; display:flex; flex-direction:column; gap:16px; }
    @media (max-width: 1100px){ .home-side{ max-width:none; } }

    /* Cartes et boutons, comme dans le gabarit */
    .carte-b{ background:#fff; border-radius:24px; padding:22px 24px; }
    .btn-pill{ display:inline-flex; align-items:center; justify-content:center; gap:8px; min-height:46px; padding:0 20px; border-radius:999px;
               border:1px solid var(--mc-line2); background:#fff; color:var(--mc-navy); font-weight:700; font-size:15px; text-decoration:none; cursor:pointer; font-family:inherit; white-space:nowrap; }
    .btn-pill:hover{ background:var(--mc-page); border-color:var(--mc-primary); color:var(--mc-navy); }
    .btn-pill.p{ background:var(--mc-primary); border-color:var(--mc-primary); color:#fff; font-weight:800; font-size:17px; min-height:52px; padding:0 24px; }
    .btn-pill.p:hover{ background:var(--mc-primary-dark); border-color:var(--mc-primary-dark); color:#fff; }
    .btn-pill.navy{ background:var(--mc-navy); border-color:var(--mc-navy); color:#fff; }
    .btn-pill.navy:hover{ background:#162E5C; border-color:#162E5C; color:#fff; }

    /* L'accueil */
    .hero-b{ display:flex; flex-wrap:wrap; align-items:center; gap:16px; }
    .hero-b .visage{ flex-shrink:0; display:block; }
    .hero-b .txt{ flex:1 1 260px; min-width:0; }
    .hero-b h1{ margin:0; font-size:30px; font-weight:800; line-height:1.15; color:var(--mc-navy); }
    .hero-b p{ margin:2px 0 0; font-size:17px; color:var(--mc-muted2); }
    .hero-b .acts{ display:flex; flex-wrap:wrap; gap:10px; align-items:center; }

    /* Les trois choses à regarder */
    .att{ display:flex; flex-wrap:wrap; align-items:center; gap:12px 16px; padding:20px 22px; }
    .att .rond{ width:44px; height:44px; flex-shrink:0; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; }
    .att .corps{ flex:1 1 240px; min-width:0; }
    .att .lbl{ font-weight:800; font-size:14px; }
    .att .titre{ font-size:21px; font-weight:800; line-height:1.2; color:var(--mc-navy); }
    .att .sous{ color:var(--mc-muted2); }
    .att.urgent .rond{ background:#FDECEA; color:#A3261C; } .att.urgent .lbl{ color:#A3261C; }
    .att.veille .rond{ background:#FBF1DC; color:#7A5200; } .att.veille .lbl{ color:#7A5200; }
    .att.ok .rond{ background:#E3F3EA; color:#0F5A3A; } .att.ok .lbl{ color:#0F5A3A; }
    .att .ic{ width:22px; height:22px; }

    /* Les indicateurs */
    .kpi-grid{ display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:16px; }
    .kpi-card{ background:#fff; border-radius:24px; padding:18px 20px; display:flex; flex-direction:column; gap:6px; }
    .kpi-head{ display:flex; align-items:center; justify-content:space-between; gap:10px; }
    .kpi-label{ font-size:13px; font-weight:800; color:var(--mc-muted2); letter-spacing:.02em; }
    .kpi-icon{ width:36px; height:36px; border-radius:50%; background:var(--mc-page); color:var(--mc-primary); display:flex; align-items:center; justify-content:center; font-size:18px; }
    .kpi-value{ font-size:28px; font-weight:800; line-height:1.1; color:var(--mc-navy); }
    .kpi-foot{ font-size:13px; color:var(--mc-muted2); }

    /* Les panneaux */
    .panel{ background:#fff; border-radius:24px; padding:22px; display:flex; flex-direction:column; gap:14px; }
    .panel-head{ display:flex; align-items:flex-start; justify-content:space-between; gap:12px; }
    .panel-title{ font-size:21px; font-weight:800; color:var(--mc-navy); }
    .panel-sub{ color:var(--mc-muted2); font-size:14px; margin-top:2px; }
    .link-muted{ color:var(--mc-primary); font-weight:700; text-decoration:none; white-space:nowrap; }
    .link-muted:hover{ text-decoration:underline; }

    .module-grid{ display:grid; grid-template-columns:repeat(auto-fit, minmax(190px, 1fr)); gap:12px; }
    .module-card{ display:flex; flex-direction:column; gap:8px; padding:16px; border-radius:18px; background:var(--mc-page); color:var(--mc-navy); text-decoration:none; transition:background .15s; }
    .module-card:hover{ background:var(--mc-soft2); color:var(--mc-navy); }
    .module-icon{ width:36px; height:36px; border-radius:50%; background:#fff; color:var(--mc-primary); display:flex; align-items:center; justify-content:center; font-size:18px; }
    .module-title{ font-weight:800; font-size:15px; }
    .module-desc{ font-size:13px; color:var(--mc-muted2); line-height:1.45; }

    .table-wrap{ overflow:auto; }
    .data-table{ width:100%; border-collapse:collapse; font-size:14px; }
    .data-table th{ text-align:left; padding:10px 12px; font-size:12.5px; font-weight:800; color:var(--mc-muted2); background:var(--mc-page); border-bottom:1px solid var(--mc-line); }
    .data-table th:first-child{ border-radius:12px 0 0 12px; } .data-table th:last-child{ border-radius:0 12px 12px 0; }
    .data-table td{ padding:11px 12px; border-bottom:1px solid var(--mc-soft); }
    .data-table tr:last-child td{ border-bottom:0; }
    .badge{ display:inline-block; padding:3px 10px; border-radius:999px; font-size:12px; font-weight:800; }
    .badge-success{ background:#E3F3EA; color:#0F5A3A; } .badge-warning{ background:#FBF1DC; color:#7A5200; } .badge-danger{ background:#FDECEA; color:#A3261C; }
    .note-fictif{ margin:0; font-size:13px; color:var(--mc-muted2); }

    /* La colonne de droite */
    .side-dark{ background:var(--mc-navy); color:#fff; border-radius:24px; padding:22px; display:flex; flex-direction:column; gap:10px; }
    .side-dark h2{ margin:0 0 4px; font-size:21px; font-weight:800; color:#E7C377; }
    .side-dark .ligne{ display:flex; gap:10px; align-items:center; font-size:15px; }
    .side-dark .pt{ width:14px; height:14px; border-radius:50%; flex-shrink:0; }
    .pt.ok{ background:#5CD6A0; } .pt.veille{ background:#E7C377; } .pt.urgent{ background:#FF8A7A; }
    .side-card{ background:#fff; border-radius:24px; padding:22px; display:flex; flex-direction:column; gap:8px; }
    .side-card h2{ margin:0 0 4px; font-size:21px; font-weight:800; color:var(--mc-navy); }
    .side-card .pers{ color:var(--mc-navy); font-size:15px; }
    .side-card .pers small{ display:block; color:var(--mc-muted2); font-size:13px; }
    .side-card .aucun{ color:var(--mc-muted2); font-size:14px; }
    .quick-actions{ display:flex; flex-direction:column; gap:6px; }
    .quick-btn{ display:flex; align-items:center; gap:12px; min-height:46px; padding:0 8px; border-radius:999px; color:var(--mc-navy); text-decoration:none; font-weight:700; }
    .quick-btn:hover{ background:var(--mc-page); color:var(--mc-navy); }
    .quick-ico{ width:36px; height:36px; border-radius:50%; background:var(--mc-page); color:var(--mc-primary); display:flex; align-items:center; justify-content:center; font-size:17px; flex-shrink:0; }
    .activity-list{ display:flex; flex-direction:column; }
    .activity-item{ display:flex; gap:10px; align-items:flex-start; padding:9px 0; border-top:1px solid #E3E9F1; }
    .activity-item:first-child{ border-top:0; padding-top:0; }
    .activity-dot{ width:10px; height:10px; border-radius:50%; margin-top:6px; flex-shrink:0; }
    .dot-blue{ background:var(--mc-primary); } .dot-green{ background:#5CD6A0; } .dot-orange{ background:#E7C377; } .dot-red{ background:#FF8A7A; }
    .activity-text{ font-size:14px; color:var(--mc-navy); }
    .activity-time{ font-size:12.5px; color:var(--mc-muted2); }

    /* ===== Boîte de bienvenue dépliable ===== */
    .welcome-box{
        background:linear-gradient(135deg,#1B4F9C 0%,#06b6d4 100%);
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
    .wb-ico-blue{ background:linear-gradient(135deg,#3b82f6,#1B4F9C); }
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
</style>

<main class="home-page">
    <div class="home-wrap">
        <div class="home-main">

        <!-- BOÎTE DE BIENVENUE (onboarding dépliable) -->
        <details class="welcome-box">
            <summary class="welcome-summary">
                <span class="wb-emoji" aria-hidden="true"><i class="ic ic-hand" aria-hidden="true"></i></span>
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
                        <span class="wb-step-ico wb-ico-blue"><i class="ic ic-user" aria-hidden="true"></i></span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 1</span>
                            <div class="wb-step-title"><%= L("step1Title") %></div>
                            <div class="wb-step-desc"><%= L("step1Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfCustomers.aspx") %>">
                        <span class="wb-step-ico wb-ico-cyan"><i class="ic ic-users" aria-hidden="true"></i></span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 2</span>
                            <div class="wb-step-title"><%= L("step2Title") %></div>
                            <div class="wb-step-desc"><%= L("step2Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfProducts.aspx") %>">
                        <span class="wb-step-ico wb-ico-green"><i class="ic ic-dollar" aria-hidden="true"></i></span>
                        <span>
                            <span class="wb-step-num"><%= L("step") %> 3</span>
                            <div class="wb-step-title"><%= L("step3Title") %></div>
                            <div class="wb-step-desc"><%= L("step3Desc") %></div>
                        </span>
                    </a>
                    <a class="wb-step" href="<%= ResolveUrl("~/wbfAgenda.aspx") %>">
                        <span class="wb-step-ico wb-ico-orange"><i class="ic ic-calendar" aria-hidden="true"></i></span>
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
                    <a class="wb-res" href="<%= UrlAide() %>" target="aide60sec"><i class="ic ic-help" aria-hidden="true"></i> <%= L("helpCenter") %></a>
                    <a class="wb-res" href="<%= ResolveUrl("~/wbfTutorials.aspx") %>"><i class="ic ic-film" aria-hidden="true"></i> <%= L("videoTutorials") %></a>
                    <a class="wb-res" href="mailto:support@60sec.ca"><i class="ic ic-mail" aria-hidden="true"></i> <%= L("contactSupport") %></a>
                </div>

            </div>
        </details>

            <!-- L'ACCUEIL -->
            <section class="carte-b hero-b">
                <svg class="visage" aria-hidden="true" width="84" height="84" viewBox="0 0 256 256">
                    <defs><radialGradient id="heroAv" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#C8F7F1" /><stop offset="1" stop-color="#3DDCCB" /></radialGradient></defs>
                    <circle cx="128" cy="128" r="104" fill="url(#heroAv)" />
                    <ellipse cx="96" cy="62" rx="44" ry="20" fill="#FFFFFF" opacity=".45" transform="rotate(-20 96 62)" />
                    <circle cx="128" cy="128" r="102" fill="none" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="3" />
                    <circle cx="96" cy="120" r="16" fill="none" stroke="#06524C" stroke-width="12" />
                    <path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#06524C" stroke-width="12" stroke-linecap="round" />
                    <ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#06524C" stroke-width="12" />
                    <path d="M99 166 q29 16 58 0" fill="none" stroke="#06524C" stroke-width="10" stroke-linecap="round" />
                </svg>
                <div class="txt">
                    <h1><asp:Literal ID="litSalut" runat="server" /></h1>
                    <p><asp:Literal ID="litSalutSous" runat="server" /></p>
                </div>
                <div class="acts">
                    <a class="btn-pill p" href="javascript:void(0)"
                       onclick="openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;">+ <%= L("btnNewInvoice") %></a>
                    <a class="btn-pill" href="wbfCustomers.aspx"><%= L("btnViewCustomers") %></a>
                    <a class="btn-pill" href="wbfSetting.aspx"><%= L("btnSettings") %></a>
                </div>
            </section>

            <!-- LES TROIS CHOSES À REGARDER (calculées : approbations, factures fournisseurs, revenus) -->
            <asp:Literal ID="litAttention" runat="server" />

            <!-- LES INDICATEURS -->
            <section class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-head">
                        <div class="kpi-label"><%= L("kpiCustomers") %></div>
                        <div class="kpi-icon"><i class="ic ic-users" aria-hidden="true"></i></div>
                    </div>
                    <div class="kpi-value"><asp:Literal ID="litKpiCustomers" runat="server" Text="0" /></div>
                    <div class="kpi-foot"><%= L("kpiCustomersFoot") %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-head">
                        <div class="kpi-label"><%= L("kpiSupplierInvoices") %></div>
                        <div class="kpi-icon"><i class="ic ic-factory" aria-hidden="true"></i></div>
                    </div>
                    <div class="kpi-value"><asp:Literal ID="litKpiSupplierInvoices" runat="server" Text="0" /></div>
                    <div class="kpi-foot"><%= L("kpiSupplierInvoicesFoot") %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-head">
                        <div class="kpi-label"><%= L("kpiProducts") %></div>
                        <div class="kpi-icon"><i class="ic ic-package" aria-hidden="true"></i></div>
                    </div>
                    <div class="kpi-value"><asp:Literal ID="litKpiProducts" runat="server" Text="0" /></div>
                    <div class="kpi-foot"><%= L("kpiProductsFoot") %></div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-head">
                        <div class="kpi-label"><%= L("kpiRevenue") %></div>
                        <div class="kpi-icon"><i class="ic ic-coins" aria-hidden="true"></i></div>
                    </div>
                    <div class="kpi-value"><asp:Literal ID="litKpiRevenue" runat="server" Text="0 $" /></div>
                    <div class="kpi-foot"><%= L("kpiRevenueFoot") %></div>
                </div>
            </section>

            <!-- LES MODULES -->
            <div class="panel">
                <div class="panel-head">
                    <div>
                        <div class="panel-title"><%= L("modulesTitle") %></div>
                        <div class="panel-sub"><%= L("modulesSub") %></div>
                    </div>
                </div>
                <div class="module-grid">
                    <a class="module-card" href="wbfCustomers.aspx">
                        <div class="module-icon"><i class="ic ic-users" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modClients") %></div>
                        <div class="module-desc"><%= L("modClientsDesc") %></div>
                    </a>
                    <a class="module-card" href="wbfSuppliersInvoices.aspx">
                        <div class="module-icon"><i class="ic ic-receipt" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modInvoices") %></div>
                        <div class="module-desc"><%= L("modInvoicesDesc") %></div>
                    </a>
                    <a class="module-card" href="wbfProducts.aspx">
                        <div class="module-icon"><i class="ic ic-package" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modProducts") %></div>
                        <div class="module-desc"><%= L("modProductsDesc") %></div>
                    </a>
                    <a class="module-card" href="wbfSuppliers.aspx">
                        <div class="module-icon"><i class="ic ic-factory" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modSuppliers") %></div>
                        <div class="module-desc"><%= L("modSuppliersDesc") %></div>
                    </a>
                    <a class="module-card" href="wbfReceipt.aspx">
                        <div class="module-icon"><i class="ic ic-receipt" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modReceipts") %></div>
                        <div class="module-desc"><%= L("modReceiptsDesc") %></div>
                    </a>
                    <a class="module-card" href="wbfSetting.aspx">
                        <div class="module-icon"><i class="ic ic-settings" aria-hidden="true"></i></div>
                        <div class="module-title"><%= L("modSettings") %></div>
                        <div class="module-desc"><%= L("modSettingsDesc") %></div>
                    </a>
                </div>
            </div>

            <!-- FACTURES RÉCENTES (exemples, comme dans le gabarit) -->
            <div class="panel">
                <div class="panel-head">
                    <div>
                        <div class="panel-title"><%= L("recentInvTitle") %></div>
                        <div class="panel-sub"><%= L("recentInvSub") %></div>
                    </div>
                    <a class="link-muted" href="wbfCustomersInvoices.aspx"><%= L("viewAll") %></a>
                </div>
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
                            <tr><td>#1048</td><td>Baignoire Expert</td><td><%= L("d1") %></td><td>1 245,00 $</td><td><span class="badge badge-warning"><%= L("stOpen") %></span></td></tr>
                            <tr><td>#1047</td><td>Construction Nova</td><td><%= L("d2") %></td><td>2 890,00 $</td><td><span class="badge badge-success"><%= L("stPaid") %></span></td></tr>
                            <tr><td>#1046</td><td>Immeubles Rive-Nord</td><td><%= L("d2") %></td><td>780,00 $</td><td><span class="badge badge-warning"><%= L("stOpen") %></span></td></tr>
                            <tr><td>#1045</td><td>Atelier du Bain</td><td><%= L("d3") %></td><td>560,00 $</td><td><span class="badge badge-danger"><%= L("stOverdue") %></span></td></tr>
                            <tr><td>#1044</td><td>Gestion MTL</td><td><%= L("d4") %></td><td>4 120,00 $</td><td><span class="badge badge-success"><%= L("stPaid") %></span></td></tr>
                        </tbody>
                    </table>
                </div>
                <p class="note-fictif"><%= L("exemplesFictifs") %></p>
            </div>
        </div>

        <!-- LA COLONNE DE DROITE -->
        <aside class="home-side">
            <section class="side-dark">
                <h2><%= L("moisTitre") %></h2>
                <asp:Literal ID="litMois" runat="server" />
            </section>
            <section class="side-card">
                <h2><%= L("cabinetTitre") %></h2>
                <asp:Literal ID="litCabinet" runat="server" />
            </section>
            <section class="side-card">
                <h2><%= L("quickTitle") %></h2>
                <div class="quick-actions">
                    <a class="quick-btn" href="javascript:void(0)" onclick="openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE); return false;">
                        <span class="quick-ico"><i class="ic ic-plus" aria-hidden="true"></i></span><span><%= L("qaCreateInvoice") %></span></a>
                    <a class="quick-btn" href="wbfCustomers.aspx">
                        <span class="quick-ico"><i class="ic ic-users" aria-hidden="true"></i></span><span><%= L("qaAddCustomer") %></span></a>
                    <a class="quick-btn" href="wbfProducts.aspx">
                        <span class="quick-ico"><i class="ic ic-package" aria-hidden="true"></i></span><span><%= L("qaAddProduct") %></span></a>
                    <a class="quick-btn" href="wbfReceipt.aspx">
                        <span class="quick-ico"><i class="ic ic-receipt" aria-hidden="true"></i></span><span><%= L("qaViewReceipts") %></span></a>
                </div>
            </section>
            <section class="side-card">
                <h2><%= L("activityTitle") %></h2>
                <div class="activity-list">
                    <div class="activity-item"><span class="activity-dot dot-blue"></span><div><div class="activity-text"><%= L("act1") %></div><div class="activity-time"><%= L("act1Time") %></div></div></div>
                    <div class="activity-item"><span class="activity-dot dot-green"></span><div><div class="activity-text"><%= L("act2") %></div><div class="activity-time"><%= L("act2Time") %></div></div></div>
                    <div class="activity-item"><span class="activity-dot dot-orange"></span><div><div class="activity-text"><%= L("act3") %></div><div class="activity-time"><%= L("act3Time") %></div></div></div>
                    <div class="activity-item"><span class="activity-dot dot-red"></span><div><div class="activity-text"><%= L("act4") %></div><div class="activity-time"><%= L("act4Time") %></div></div></div>
                </div>
                <p class="note-fictif"><%= L("exemplesFictifs") %></p>
            </section>
        </aside>
    </div>
</main>

<%-- Popup « Nouvelle facture » (même RadWindow que la liste des factures clients) --%>
<telerik:RadWindow ID="rwInvoice" runat="server"
    Modal="true"
    VisibleOnPageLoad="false"
    Behaviors="Close,Move,Resize"
    DestroyOnClose="true"
    Title="Facture"
    OnClientClose="rwInvoice_OnClose"
    ClientIDMode="Static">
</telerik:RadWindow>

<script src="js/RadWindows.js"></script>
<script type="text/javascript">
    var L_ADD_INVOICE = "<%= L("winAddInvoice") %>";
    var L_EDIT_INVOICE = "<%= L("winEditInvoice") %>";
    // Après fermeture du popup, recharger le tableau de bord pour rafraîchir les KPI.
    function rwInvoice_OnClose(sender, args) {
        window.location.reload();
    }
</script>
</asp:Content>
