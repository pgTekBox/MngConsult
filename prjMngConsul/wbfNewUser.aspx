<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfNewUser.aspx.vb" Inherits="MngConsul.wbfNewUser" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Entrepreneur Information — MngConsul</title>

    <style>
        /* =====================================================================
           Reset + base
           ===================================================================== */
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;

            /* Slate */
            --slate-50:  #f8fafc;
            --slate-100: #f1f5f9;
            --slate-200: #e2e8f0;
            --slate-300: #cbd5e1;
            --slate-400: #94a3b8;
            --slate-500: #64748b;
            --slate-600: #475569;
            --slate-700: #334155;
            --slate-800: #1e293b;

            /* Blue */
            --blue-50:   #eff6ff;
            --blue-100:  #dbeafe;
            --blue-200:  #bfdbfe;
            --blue-400:  #60a5fa;
            --blue-500:  #3b82f6;
            --blue-600:  #2563eb;
            --blue-700:  #1d4ed8;
            --blue-800:  #1e40af;

            /* Cyan */
            --cyan-500:  #06b6d4;
            --cyan-600:  #0891b2;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: linear-gradient(135deg, var(--slate-50), var(--slate-100));
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        button { font-family: inherit; cursor: pointer; }
        input, select { font-family: inherit; }

        /* =====================================================================
           Header
           ===================================================================== */
        .app-header {
            background: #fff;
            border-bottom: 1px solid var(--slate-200);
            box-shadow: 0 1px 2px rgba(15,23,42,.04);
            flex-shrink: 0;
        }

        .header-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 16px;
            gap: 8px;
            flex-wrap: wrap;
        }

        .header-left {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-back {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 32px; height: 32px;
            border: none;
            background: transparent;
            border-radius: 8px;
            color: var(--slate-600);
            transition: background .15s;
        }
        .btn-back:hover { background: var(--slate-100); }

        .header-titles h1 {
            font-size: 18px;
            font-weight: 800;
            color: var(--slate-800);
            margin: 0;
            line-height: 1.1;
        }
        .header-titles p {
            margin: 2px 0 0 0;
            font-size: 12px;
            color: var(--slate-500);
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .pill-card {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--slate-50);
            border: 1px solid var(--slate-200);
            border-radius: 12px;
            padding: 8px 12px;
            transition: background .15s, border-color .15s;
        }
        .pill-card:hover { background: var(--slate-100); border-color: var(--slate-300); }

        .pill-icon {
            width: 28px; height: 28px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: white;
            flex-shrink: 0;
        }
        .pill-icon.blue { background: linear-gradient(135deg, var(--blue-500), var(--blue-600)); }
        .pill-icon.bank { background: linear-gradient(135deg, var(--blue-600), var(--blue-700)); }

        .pill-meta { text-align: left; line-height: 1.1; }
        .pill-meta .lbl {
            font-size: 11px; color: var(--slate-500);
            font-weight: 600; margin-bottom: 2px;
        }
        .pill-meta .val {
            font-size: 13px; color: var(--slate-700); font-weight: 800;
        }

        .pill-card .icon-btn {
            margin-left: 4px;
            width: 24px; height: 24px;
            border: none;
            background: transparent;
            border-radius: 6px;
            color: var(--slate-400);
            display: inline-flex; align-items: center; justify-content: center;
        }
        .pill-card .icon-btn:hover { color: var(--slate-600); background: var(--slate-200); }

        @media (max-width: 640px) {
            .pill-meta { display: none; }
        }

        /* =====================================================================
           Main
           ===================================================================== */
        main {
            flex: 1;
            overflow-y: auto;
            padding: 24px;
        }

        .page-title h2 {
            font-size: 28px;
            font-weight: 800;
            color: var(--slate-800);
            margin: 0 0 6px 0;
        }
        .page-title p {
            color: var(--slate-600);
            margin: 0 0 28px 0;
            font-size: 14px;
        }

        .card {
            background: #fff;
            border: 1px solid var(--slate-200);
            border-radius: 16px;
            box-shadow: 0 8px 20px rgba(15,23,42,.05);
            margin-bottom: 18px;
        }
        .card.thick { border-width: 2px; border-color: var(--blue-200); overflow: hidden; }
        .card-body { padding: 24px; }

        .section-label {
            font-size: 11px;
            font-weight: 800;
            color: var(--slate-400);
            text-transform: uppercase;
            letter-spacing: 0.1em;
            margin-bottom: 14px;
        }

        /* =====================================================================
           Structure card (sélecteur)
           ===================================================================== */
        .structure-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
            max-width: 380px;
        }

        .structure-card {
            position: relative;
            overflow: hidden;
            border-radius: 16px;
            border: 2px solid var(--blue-600);
            background: var(--blue-50);
            box-shadow: 0 4px 12px rgba(37,99,235,.15);
            padding: 20px;
            text-align: left;
            transition: transform .2s, box-shadow .2s;
        }
        .structure-card:hover { transform: translateY(-2px); }

        .structure-card .deco {
            position: absolute;
            top: -32px; right: -32px;
            width: 96px; height: 96px;
            border-radius: 50%;
            background: var(--blue-100);
            transition: transform .5s;
        }
        .structure-card:hover .deco { transform: scale(1.5); }

        .structure-card .content { position: relative; }

        .structure-head {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 12px;
        }

        .structure-icon {
            width: 40px; height: 40px;
            border-radius: 12px;
            background: var(--blue-600);
            color: white;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .badge-active {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            background: var(--blue-600);
            color: white;
            font-size: 11px;
            font-weight: 800;
            padding: 2px 10px;
            border-radius: 999px;
        }

        .structure-card h4 {
            font-size: 14px;
            font-weight: 800;
            color: var(--blue-800);
            line-height: 1.2;
            margin: 0 0 4px 0;
        }
        .structure-card .type {
            font-size: 11px;
            font-weight: 800;
            color: var(--blue-500);
            text-transform: uppercase;
            letter-spacing: 0.06em;
            margin-bottom: 12px;
        }

        .feature-list {
            list-style: none;
            padding: 0;
            margin: 12px 0 0 0;
        }
        .feature-list li {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: var(--slate-500);
            padding: 2px 0;
        }
        .feature-dot {
            width: 6px; height: 6px;
            border-radius: 50%;
            background: var(--blue-400);
            flex-shrink: 0;
        }

        /* =====================================================================
           Tabs
           ===================================================================== */
        .tabs {
            display: flex;
            border-bottom: 1px solid var(--slate-200);
        }

        .tab-btn {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 4px;
            padding: 14px 8px;
            font-size: 12px;
            font-weight: 800;
            color: var(--slate-500);
            background: transparent;
            border: none;
            border-bottom: 2px solid transparent;
            margin-bottom: -1px;
            transition: all .15s;
        }
        .tab-btn:hover { color: var(--slate-700); background: var(--slate-50); }
        .tab-btn.active {
            color: var(--blue-700);
            background: var(--blue-50);
            border-bottom-color: var(--blue-500);
        }

        .tab-icon {
            width: 28px; height: 28px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .tab-icon.blue  { background: linear-gradient(135deg, var(--blue-500), var(--blue-600)); }
        .tab-icon.cyan  { background: linear-gradient(135deg, var(--cyan-500), var(--cyan-600)); }

        /* =====================================================================
           Form
           ===================================================================== */
        .tab-content { display: none; }
        .tab-content.active { display: block; }

        .tab-title {
            margin-bottom: 20px;
        }
        .tab-title h3 {
            font-size: 20px;
            font-weight: 800;
            color: var(--slate-800);
            margin: 0 0 6px 0;
        }
        .tab-title .underline {
            height: 4px;
            width: 64px;
            border-radius: 999px;
            background: linear-gradient(90deg, var(--blue-500), var(--blue-600));
        }
        .tab-title.cyan .underline {
            background: linear-gradient(90deg, var(--cyan-500), var(--cyan-600));
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        .form-grid .full { grid-column: 1 / -1; }

        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
        }

        .field label {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
            font-weight: 700;
            color: var(--slate-700);
            margin-bottom: 8px;
        }

        .field input[type="text"],
        .field input[type="tel"],
        .field input[type="email"],
        .field select {
            width: 100%;
            padding: 12px 14px;
            border: 2px solid var(--slate-200);
            border-radius: 8px;
            font-size: 14px;
            color: var(--slate-800);
            background: #fff;
            outline: none;
            transition: border-color .15s, box-shadow .15s;
        }
        .field input:focus,
        .field select:focus {
            border-color: var(--blue-500);
            box-shadow: 0 0 0 3px rgba(59,130,246,.18);
        }

        .field-edit-btn {
            background: transparent;
            border: none;
            padding: 4px;
            border-radius: 6px;
            color: var(--slate-400);
            display: inline-flex;
        }
        .field-edit-btn:hover { color: var(--blue-500); background: var(--blue-50); }

        /* Toggle switch */
        .toggle-row {
            border-top: 1px solid var(--slate-200);
            padding-top: 18px;
            margin-top: 4px;
        }

        .toggle {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            cursor: pointer;
            user-select: none;
        }

        .toggle input { display: none; }

        .toggle-track {
            width: 40px; height: 24px;
            border-radius: 999px;
            background: var(--slate-300);
            display: inline-flex;
            align-items: center;
            padding: 2px;
            transition: background .15s;
            flex-shrink: 0;
        }

        .toggle-thumb {
            width: 20px; height: 20px;
            border-radius: 50%;
            background: #fff;
            box-shadow: 0 1px 3px rgba(0,0,0,.2);
            transition: transform .15s;
        }

        .toggle input:checked + .toggle-track { background: var(--blue-500); }
        .toggle input:checked + .toggle-track .toggle-thumb { transform: translateX(16px); }

        .toggle-label {
            font-size: 14px;
            font-weight: 700;
            color: var(--slate-700);
        }

        /* Action buttons */
        .form-actions {
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            padding-top: 20px;
            margin-top: 28px;
            border-top: 1px solid var(--slate-200);
        }

        .btn {
            padding: 10px 20px;
            border-radius: 8px;
            font-weight: 700;
            font-size: 14px;
            border: none;
            transition: all .15s;
        }
        .btn-secondary {
            background: var(--slate-100);
            color: var(--slate-700);
        }
        .btn-secondary:hover { background: var(--slate-200); }

        .btn-primary {
            background: linear-gradient(90deg, var(--blue-500), var(--blue-600));
            color: white;
        }
        .btn-primary:hover {
            box-shadow: 0 8px 16px rgba(37,99,235,.3);
            transform: translateY(-1px);
        }

        /* Sub-section header (Gouvernementale) */
        .sub-section-title {
            font-size: 14px;
            font-weight: 800;
            color: var(--slate-700);
            margin: 24px 0 12px 0;
            padding-bottom: 8px;
            border-bottom: 1px solid var(--slate-200);
        }
        .sub-section-title:first-child { margin-top: 0; }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- ============================================================
             HEADER
             ============================================================ -->
        <header class="app-header">
            <div class="header-inner">

                <div class="header-left">
                    <button type="button" class="btn-back" title="Retour">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="m15 18-6-6 6-6"></path>
                        </svg>
                    </button>
                    <div class="header-titles">
                        <h1>Entrepreneur Information</h1>
                        <p>Gestion en temps réel avec AI</p>
                    </div>
                </div>

                <div class="header-right">
                    <button type="button" class="pill-card" title="Modifier le profil entrepreneur">
                        <span class="pill-icon blue">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
                                <circle cx="12" cy="7" r="4"></circle>
                            </svg>
                        </span>
                        <span class="pill-meta">
                            <span class="lbl">Structure</span>
                            <span class="val">Trav. autonome</span>
                        </span>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                             style="color: var(--slate-400);">
                            <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                            <path d="m15 5 4 4"></path>
                        </svg>
                    </button>

                    <div class="pill-card" style="cursor:default;">
                        <span class="pill-icon bank">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="3" x2="21" y1="22" y2="22"></line>
                                <line x1="6" x2="6" y1="18" y2="11"></line>
                                <line x1="10" x2="10" y1="18" y2="11"></line>
                                <line x1="14" x2="14" y1="18" y2="11"></line>
                                <line x1="18" x2="18" y1="18" y2="11"></line>
                                <polygon points="12 2 20 7 4 7"></polygon>
                            </svg>
                        </span>
                        <span class="pill-meta">
                            <span class="lbl">Solde bancaire</span>
                            <span class="val">48&nbsp;320,55 $</span>
                        </span>
                        <button type="button" class="icon-btn" title="Masquer le solde">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path>
                                <circle cx="12" cy="12" r="3"></circle>
                            </svg>
                        </button>
                    </div>
                </div>

            </div>
        </header>


        <!-- ============================================================
             MAIN
             ============================================================ -->
        <main>

            <div class="page-title">
                <h2>Entrepreneur Information</h2>
                <p>Gestion complète des informations de l'entreprise</p>
            </div>

            <!-- ============================================================
                 STRUCTURE CONFIGURÉE
                 ============================================================ -->
            <div class="card">
                <div class="card-body">
                    <p class="section-label">Structure configurée</p>

                    <div class="structure-grid">
                        <button type="button" class="structure-card">
                            <span class="deco"></span>
                            <div class="content">

                                <div class="structure-head">
                                    <span class="structure-icon">
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                                             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
                                            <circle cx="12" cy="7" r="4"></circle>
                                        </svg>
                                    </span>
                                    <span class="badge-active">
                                        <svg width="10" height="10" fill="none" stroke="currentColor" stroke-width="3" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
                                        </svg>
                                        Actif
                                    </span>
                                </div>

                                <h4>Travailleur autonome</h4>
                                <p class="type">Solo</p>

                                <ul class="feature-list">
                                    <li><span class="feature-dot"></span> Facturation à son nom</li>
                                    <li><span class="feature-dot"></span> Aucun employé</li>
                                    <li><span class="feature-dot"></span> Déclaration TPS/TVQ</li>
                                </ul>

                            </div>
                        </button>
                    </div>
                </div>
            </div>


            <!-- ============================================================
                 ONGLETS GÉNÉRALE / GOUVERNEMENTALE
                 ============================================================ -->
            <div class="card thick">

                <div class="tabs" role="tablist">
                    <button type="button" class="tab-btn active"
                            data-tab="generale" role="tab" aria-selected="true">
                        <span class="tab-icon blue">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"></path>
                                <path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2"></path>
                                <path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2"></path>
                                <path d="M10 6h4"></path><path d="M10 10h4"></path>
                                <path d="M10 14h4"></path><path d="M10 18h4"></path>
                            </svg>
                        </span>
                        Générale
                    </button>

                    <button type="button" class="tab-btn"
                            data-tab="gouvernementale" role="tab" aria-selected="false">
                        <span class="tab-icon cyan">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"></path>
                                <path d="M14 2v4a2 2 0 0 0 2 2h4"></path>
                                <path d="M10 9H8"></path><path d="M16 13H8"></path><path d="M16 17H8"></path>
                            </svg>
                        </span>
                        Gouvernementale
                    </button>
                </div>


                <!-- ============================================================
                     TAB : GÉNÉRALE
                     ============================================================ -->
                <div class="card-body tab-content active" id="tab-generale">

                    <div class="tab-title">
                        <h3>Générale</h3>
                        <div class="underline"></div>
                    </div>

                    <div class="form-grid">

                        <div class="field">
                            <label>
                                Prénom
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtFirstName" runat="server" placeholder="Ex: Jean" />
                        </div>

                        <div class="field">
                            <label>
                                Nom de famille
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtLastName" runat="server" placeholder="Ex: Tremblay" />
                        </div>

                        <div class="field full">
                            <label>
                                Adresse
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtAddress" runat="server" placeholder="123 Rue Principale" />
                        </div>

                        <div class="field">
                            <label>
                                Ville
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtCity" runat="server" placeholder="Montréal" />
                        </div>

                        <div class="field">
                            <label>
                                Province
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:DropDownList ID="ddlProvince" runat="server">
                                <asp:ListItem Value=""   Text="Sélectionner" />
                                <asp:ListItem Value="QC" Text="Québec" />
                                <asp:ListItem Value="ON" Text="Ontario" />
                                <asp:ListItem Value="BC" Text="Colombie-Britannique" />
                                <asp:ListItem Value="AB" Text="Alberta" />
                                <asp:ListItem Value="MB" Text="Manitoba" />
                                <asp:ListItem Value="SK" Text="Saskatchewan" />
                                <asp:ListItem Value="NB" Text="Nouveau-Brunswick" />
                                <asp:ListItem Value="NS" Text="Nouvelle-Écosse" />
                                <asp:ListItem Value="PE" Text="Île-du-Prince-Édouard" />
                                <asp:ListItem Value="NL" Text="Terre-Neuve-et-Labrador" />
                                <asp:ListItem Value="YT" Text="Yukon" />
                                <asp:ListItem Value="NT" Text="Territoires du Nord-Ouest" />
                                <asp:ListItem Value="NU" Text="Nunavut" />
                            </asp:DropDownList>
                        </div>

                        <div class="field">
                            <label>
                                Code postal
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtPostalCode" runat="server" placeholder="H1H 1H1" />
                        </div>

                        <div class="field">
                            <label>
                                Téléphone
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtPhone" runat="server" TextMode="Phone" placeholder="(514) 555-1234" />
                        </div>

                        <div class="field">
                            <label>
                                Courriel
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" placeholder="jean.tremblay@courriel.com" />
                        </div>

                        <div class="field full toggle-row">
                            <label class="toggle">
                                <asp:CheckBox ID="cbDifferentBusinessAddress" runat="server" />
                                <span class="toggle-track"><span class="toggle-thumb"></span></span>
                                <span class="toggle-label">Adresse du bureau différente de l'adresse personnelle</span>
                            </label>
                        </div>

                    </div>

                    <div class="form-actions">
                        <asp:Button ID="btnCancelGen" runat="server" Text="Annuler"
                            CssClass="btn btn-secondary" CausesValidation="false" />
                        <asp:Button ID="btnSaveGen" runat="server" Text="Enregistrer"
                            CssClass="btn btn-primary" />
                    </div>

                </div>


                <!-- ============================================================
                     TAB : GOUVERNEMENTALE
                     ============================================================ -->
                <div class="card-body tab-content" id="tab-gouvernementale">

                    <div class="tab-title cyan">
                        <h3>Gouvernementale</h3>
                        <div class="underline"></div>
                    </div>

                    <div class="sub-section-title">Identification fiscale fédérale</div>

                    <div class="form-grid">

                        <div class="field">
                            <label>
                                Numéro d'entreprise (NE)
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtBusinessNumber" runat="server" placeholder="123456789" />
                        </div>

                        <div class="field">
                            <label>
                                Numéro d'assurance sociale
                                <button type="button" class="field-edit-btn" title="Modifier">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"></path>
                                        <path d="m15 5 4 4"></path>
                                    </svg>
                                </button>
                            </label>
                            <asp:TextBox ID="txtSin" runat="server" placeholder="123 456 789" />
                        </div>

                        <div class="field">
                            <label>Numéro de TPS</label>
                            <asp:TextBox ID="txtTps" runat="server" placeholder="123456789 RT0001" />
                        </div>

                        <div class="field">
                            <label>Date d'inscription TPS</label>
                            <asp:TextBox ID="txtTpsDate" runat="server" TextMode="Date" />
                        </div>

                    </div>

                    <div class="sub-section-title">Identification fiscale provinciale (Québec)</div>

                    <div class="form-grid">

                        <div class="field">
                            <label>Numéro d'entreprise du Québec (NEQ)</label>
                            <asp:TextBox ID="txtNeq" runat="server" placeholder="1234567890" />
                        </div>

                        <div class="field">
                            <label>Numéro de TVQ</label>
                            <asp:TextBox ID="txtTvq" runat="server" placeholder="1234567890 TQ0001" />
                        </div>

                        <div class="field">
                            <label>Date d'inscription TVQ</label>
                            <asp:TextBox ID="txtTvqDate" runat="server" TextMode="Date" />
                        </div>

                        <div class="field">
                            <label>Code d'activité économique (CAE)</label>
                            <asp:TextBox ID="txtCae" runat="server" placeholder="6219" />
                        </div>

                    </div>

                    <div class="sub-section-title">Périodicité des déclarations</div>

                    <div class="form-grid">

                        <div class="field">
                            <label>Fréquence TPS/TVH</label>
                            <asp:DropDownList ID="ddlTpsFrequency" runat="server">
                                <asp:ListItem Value=""    Text="Sélectionner" />
                                <asp:ListItem Value="MEN" Text="Mensuelle" />
                                <asp:ListItem Value="TRI" Text="Trimestrielle" />
                                <asp:ListItem Value="ANN" Text="Annuelle" />
                            </asp:DropDownList>
                        </div>

                        <div class="field">
                            <label>Fréquence TVQ</label>
                            <asp:DropDownList ID="ddlTvqFrequency" runat="server">
                                <asp:ListItem Value=""    Text="Sélectionner" />
                                <asp:ListItem Value="MEN" Text="Mensuelle" />
                                <asp:ListItem Value="TRI" Text="Trimestrielle" />
                                <asp:ListItem Value="ANN" Text="Annuelle" />
                            </asp:DropDownList>
                        </div>

                        <div class="field">
                            <label>Fin d'exercice financier</label>
                            <asp:TextBox ID="txtFiscalYearEnd" runat="server" TextMode="Date" />
                        </div>

                        <div class="field">
                            <label>Régime de paiements</label>
                            <asp:DropDownList ID="ddlPaymentRegime" runat="server">
                                <asp:ListItem Value=""     Text="Sélectionner" />
                                <asp:ListItem Value="ACMP" Text="Acomptes provisionnels" />
                                <asp:ListItem Value="DECL" Text="À la déclaration" />
                            </asp:DropDownList>
                        </div>

                    </div>

                    <div class="form-actions">
                        <asp:Button ID="btnCancelGov" runat="server" Text="Annuler"
                            CssClass="btn btn-secondary" CausesValidation="false" />
                        <asp:Button ID="btnSaveGov" runat="server" Text="Enregistrer"
                            CssClass="btn btn-primary" />
                    </div>

                </div>

            </div>

        </main>

        <!-- ============================================================
             SCRIPT : Tabs + Toggle visuels
             ============================================================ -->
        <script type="text/javascript">

            // ===== Onglets =====
            (function () {
                var buttons = document.querySelectorAll('.tab-btn');
                var contents = document.querySelectorAll('.tab-content');

                buttons.forEach(function (btn) {
                    btn.addEventListener('click', function (e) {
                        e.preventDefault();
                        var target = btn.getAttribute('data-tab');

                        buttons.forEach(function (b) {
                            b.classList.remove('active');
                            b.setAttribute('aria-selected', 'false');
                        });
                        contents.forEach(function (c) { c.classList.remove('active'); });

                        btn.classList.add('active');
                        btn.setAttribute('aria-selected', 'true');

                        var content = document.getElementById('tab-' + target);
                        if (content) content.classList.add('active');
                    });
                });
            })();

        </script>

    </form>
</body>
</html>
