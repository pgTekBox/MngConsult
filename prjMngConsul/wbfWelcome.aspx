<%@ Page Title="Bienvenue chez MngConsul" Language="vb"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="false"
    CodeBehind="wbfWelcome.aspx.vb" Inherits="MngConsul.wbfWelcome" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        :root {
            --welcome-blue:  #2563eb;
            --welcome-cyan:  #06b6d4;
            --welcome-green: #10b981;
            --welcome-50:    #f8fafc;
            --welcome-100:   #f1f5f9;
            --welcome-200:   #e2e8f0;
            --welcome-300:   #cbd5e1;
            --welcome-500:   #64748b;
            --welcome-600:   #475569;
            --welcome-700:   #334155;
            --welcome-800:   #1e293b;
            --welcome-orange:#f59e0b;
        }

        .welcome-wrap {
            max-width: 980px;
            margin: 0 auto;
            padding: 24px 16px;
            font-family: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            color: var(--welcome-800);
        }

        /* === Hero === */
        .welcome-hero {
            position: relative;
            background: linear-gradient(135deg, var(--welcome-blue), var(--welcome-cyan));
            color: #fff;
            border-radius: 24px;
            padding: 40px 36px;
            overflow: hidden;
            margin-bottom: 24px;
            box-shadow: 0 20px 50px rgba(37,99,235,.25);
        }

        .welcome-hero::before {
            content: "";
            position: absolute;
            top: -80px; right: -80px;
            width: 280px; height: 280px;
            border-radius: 50%;
            background: rgba(255,255,255,.1);
        }
        .welcome-hero::after {
            content: "";
            position: absolute;
            bottom: -100px; left: -100px;
            width: 320px; height: 320px;
            border-radius: 50%;
            background: rgba(255,255,255,.06);
        }

        .welcome-hero .content {
            position: relative;
            z-index: 1;
        }

        .welcome-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(255,255,255,.18);
            color: #fff;
            font-size: 12px;
            font-weight: 800;
            padding: 6px 14px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: .08em;
            margin-bottom: 16px;
        }

        .welcome-hero h1 {
            font-size: 32px;
            font-weight: 800;
            margin: 0 0 10px 0;
            line-height: 1.2;
            letter-spacing: -.5px;
        }

        .welcome-hero p {
            font-size: 16px;
            margin: 0 0 22px 0;
            opacity: 0.95;
            line-height: 1.55;
            max-width: 640px;
        }

        .trial-card {
            display: inline-flex;
            align-items: center;
            gap: 14px;
            background: rgba(255,255,255,.16);
            border: 1px solid rgba(255,255,255,.25);
            border-radius: 14px;
            padding: 14px 18px;
            backdrop-filter: blur(8px);
        }
        .trial-card-icon {
            width: 44px; height: 44px;
            border-radius: 12px;
            background: rgba(255,255,255,.22);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .trial-card-text { line-height: 1.3; }
        .trial-card .lbl {
            font-size: 11px;
            opacity: 0.8;
            text-transform: uppercase;
            letter-spacing: .08em;
            font-weight: 700;
        }
        .trial-card .val {
            font-size: 16px;
            font-weight: 800;
        }

        /* === Steps === */
        .section-title {
            font-size: 13px;
            font-weight: 800;
            color: var(--welcome-500);
            text-transform: uppercase;
            letter-spacing: .1em;
            margin: 32px 0 16px 0;
        }

        .steps-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
        }

        @media (max-width: 720px) {
            .steps-grid { grid-template-columns: 1fr; }
        }

        .step-card {
            background: #fff;
            border: 1px solid var(--welcome-200);
            border-radius: 16px;
            padding: 20px;
            text-decoration: none;
            color: inherit;
            display: flex;
            gap: 14px;
            transition: transform .15s, box-shadow .15s, border-color .15s;
        }
        .step-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 28px rgba(15,23,42,.08);
            border-color: var(--welcome-blue);
            text-decoration: none;
        }

        .step-icon {
            width: 44px; height: 44px;
            border-radius: 12px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            flex-shrink: 0;
        }
        .step-icon.blue   { background: linear-gradient(135deg, #3b82f6, #2563eb); }
        .step-icon.cyan   { background: linear-gradient(135deg, #06b6d4, #0891b2); }
        .step-icon.green  { background: linear-gradient(135deg, #10b981, #059669); }
        .step-icon.orange { background: linear-gradient(135deg, #f59e0b, #d97706); }

        .step-content { flex: 1; }
        .step-num {
            font-size: 11px;
            font-weight: 800;
            color: var(--welcome-500);
            text-transform: uppercase;
            letter-spacing: .08em;
            margin-bottom: 4px;
        }
        .step-title {
            font-size: 16px;
            font-weight: 800;
            color: var(--welcome-800);
            margin: 0 0 4px 0;
        }
        .step-desc {
            font-size: 13px;
            color: var(--welcome-600);
            line-height: 1.5;
            margin: 0;
        }
        .step-arrow {
            color: var(--welcome-300);
            display: flex;
            align-items: center;
            transition: transform .15s, color .15s;
        }
        .step-card:hover .step-arrow {
            color: var(--welcome-blue);
            transform: translateX(4px);
        }

        /* === Tips section === */
        .tips-card {
            background: linear-gradient(135deg, #fffbeb, #fef3c7);
            border: 1px solid var(--welcome-orange);
            border-radius: 16px;
            padding: 22px 24px;
            margin-top: 8px;
        }
        .tips-card h3 {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 15px;
            font-weight: 800;
            color: #78350f;
            margin: 0 0 12px 0;
        }
        .tips-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .tips-list li {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            padding: 6px 0;
            font-size: 13px;
            color: #92400e;
            line-height: 1.5;
        }
        .tips-list li svg {
            flex-shrink: 0;
            color: var(--welcome-orange);
            margin-top: 2px;
        }

        /* === Resources === */
        .resources-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
        }
        @media (max-width: 720px) {
            .resources-grid { grid-template-columns: 1fr; }
        }

        .resource-link {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 14px;
            background: #fff;
            border: 1px solid var(--welcome-200);
            border-radius: 10px;
            text-decoration: none;
            color: var(--welcome-700);
            font-size: 13px;
            font-weight: 700;
            transition: border-color .15s, color .15s, background .15s;
        }
        .resource-link:hover {
            border-color: var(--welcome-blue);
            color: var(--welcome-blue);
            text-decoration: none;
            background: var(--welcome-50);
        }
        .resource-link svg { flex-shrink: 0; color: var(--welcome-500); }
        .resource-link:hover svg { color: var(--welcome-blue); }

        /* === CTA bottom === */
        .cta-bottom {
            text-align: center;
            margin-top: 36px;
            padding: 24px;
            background: var(--welcome-50);
            border-radius: 16px;
        }
        .cta-bottom p {
            color: var(--welcome-600);
            font-size: 14px;
            margin: 0 0 14px 0;
        }
        .btn-dashboard {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 14px 28px;
            background: linear-gradient(135deg, var(--welcome-blue), var(--welcome-cyan));
            color: #fff;
            font-size: 15px;
            font-weight: 800;
            text-decoration: none;
            border-radius: 12px;
            transition: transform .12s, box-shadow .12s;
        }
        .btn-dashboard:hover {
            transform: translateY(-1px);
            box-shadow: 0 12px 24px rgba(37,99,235,.3);
            text-decoration: none;
            color: #fff;
        }
    </style>
</asp:Content>


<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="welcome-wrap">

        <!-- ====== HERO ====== -->
        <div class="welcome-hero">
            <div class="content">

                <span class="welcome-badge">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    Compte créé avec succès
                </span>

                <h1>
                    Bienvenue, <asp:Literal ID="litFirstName" runat="server" Text="" /> ! 👋
                </h1>

                <p>
                    Votre essai gratuit du forfait
                    <strong><asp:Literal ID="litPlanName" runat="server" Text="Pro" /></strong>
                    est maintenant actif. Vous avez accès à toutes les fonctionnalités sans engagement
                    pendant 30 jours, aucune carte de crédit requise.
                </p>

                <div class="trial-card">
                    <div class="trial-card-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                    </div>
                    <div class="trial-card-text">
                        <div class="lbl">Votre essai gratuit se termine le</div>
                        <div class="val">
                            <asp:Literal ID="litTrialEnd" runat="server" />
                        </div>
                    </div>
                </div>

            </div>
        </div>


        <!-- ====== ÉTAPES SUIVANTES ====== -->
        <div class="section-title">🚀 Vos prochaines étapes</div>

        <div class="steps-grid">

            <a href="<%= ResolveUrl("~/wbfNewUser.aspx") %>" class="step-card">
                <div class="step-icon blue">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
                        <circle cx="12" cy="7" r="4"></circle>
                    </svg>
                </div>
                <div class="step-content">
                    <div class="step-num">Étape 1</div>
                    <div class="step-title">Compléter votre profil</div>
                    <p class="step-desc">
                        Ajoutez vos informations fiscales (NEQ, TPS, TVQ) pour débloquer la facturation.
                    </p>
                </div>
                <div class="step-arrow">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                    </svg>
                </div>
            </a>

            <a href="<%= ResolveUrl("~/wbfCustomers.aspx") %>" class="step-card">
                <div class="step-icon cyan">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                        <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                    </svg>
                </div>
                <div class="step-content">
                    <div class="step-num">Étape 2</div>
                    <div class="step-title">Ajouter vos clients</div>
                    <p class="step-desc">
                        Créez votre carnet de clients pour commencer à émettre vos premières factures.
                    </p>
                </div>
                <div class="step-arrow">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                    </svg>
                </div>
            </a>

            <a href="<%= ResolveUrl("~/wbfProducts.aspx") %>" class="step-card">
                <div class="step-icon green">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="12" y1="1" x2="12" y2="23"></line>
                        <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                    </svg>
                </div>
                <div class="step-content">
                    <div class="step-num">Étape 3</div>
                    <div class="step-title">Configurer vos services</div>
                    <p class="step-desc">
                        Définissez votre liste de services avec leurs tarifs et durées.
                    </p>
                </div>
                <div class="step-arrow">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                    </svg>
                </div>
            </a>

            <a href="<%= ResolveUrl("~/wbfAgenda.aspx") %>" class="step-card">
                <div class="step-icon orange">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                        <line x1="16" y1="2" x2="16" y2="6"></line>
                        <line x1="8" y1="2" x2="8" y2="6"></line>
                        <line x1="3" y1="10" x2="21" y2="10"></line>
                    </svg>
                </div>
                <div class="step-content">
                    <div class="step-num">Étape 4</div>
                    <div class="step-title">Planifier votre agenda</div>
                    <p class="step-desc">
                        Prenez votre premier rendez-vous et organisez votre semaine en quelques clics.
                    </p>
                </div>
                <div class="step-arrow">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9 18 15 12 9 6"></polyline>
                    </svg>
                </div>
            </a>

        </div>


        <!-- ====== CONSEILS ====== -->
        <div class="section-title">💡 Quelques conseils pour bien démarrer</div>

        <div class="tips-card">
            <h3>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="16" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12.01" y2="8"></line>
                </svg>
                À savoir avant de commencer
            </h3>
            <ul class="tips-list">
                <li>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    <span><strong>Vos données sont en sécurité.</strong>
                          Toutes les sauvegardes sont automatiques et chiffrées.</span>
                </li>
                <li>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    <span><strong>Aucune carte de crédit requise pendant l'essai.</strong>
                          Vous serez informé 7 jours avant la fin de votre période d'essai.</span>
                </li>
                <li>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    <span><strong>Conformité fiscale Québec.</strong>
                          MngConsul calcule automatiquement la TPS (5 %) et la TVQ (9,975 %)
                          sur vos factures.</span>
                </li>
                <li>
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    <span><strong>Vous n'êtes pas seul·e.</strong>
                          Notre équipe de support est disponible par courriel à
                          <a href="mailto:support@60sec.ca" style="color:#92400e; font-weight:800;">
                              support@60sec.ca</a>.</span>
                </li>
            </ul>
        </div>


        <!-- ====== RESSOURCES ====== -->
        <div class="section-title">📚 Ressources utiles</div>

        <div class="resources-grid">
            <a href="<%= ResolveUrl("~/wbfHelp.aspx") %>" class="resource-link">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                Centre d'aide
            </a>

            <a href="<%= ResolveUrl("~/wbfTutorials.aspx") %>" class="resource-link">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="23 7 16 12 23 17 23 7"></polygon>
                    <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
                </svg>
                Tutoriels vidéo
            </a>

            <a href="mailto:support@60sec.ca" class="resource-link">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
                    <polyline points="22,6 12,13 2,6"></polyline>
                </svg>
                Contacter le support
            </a>
        </div>


        <!-- ====== CTA BOTTOM ====== -->
        <div class="cta-bottom">
            <p>Prêt à démarrer ? Rendez-vous sur votre tableau de bord pour explorer toutes les fonctionnalités.</p>
            <a href="<%= ResolveUrl("~/Default.aspx") %>" class="btn-dashboard">
                Accéder au tableau de bord
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                    <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
            </a>
        </div>

    </div>

</asp:Content>
