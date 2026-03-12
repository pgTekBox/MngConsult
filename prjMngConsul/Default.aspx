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
        z-index:1;
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
</style>

<main class="home-page">
    <div class="home-wrap">

        <!-- HERO -->
        <section class="hero">
            <div class="hero-left">
                <div class="hero-badge">✨ Tableau de bord principal</div>

                <h1 class="hero-title">
                    Bienvenue dans MngConsul
                </h1>

                <p class="hero-sub">
                    Gérez vos clients, vos factures, vos produits et vos opérations quotidiennes
                    depuis une seule interface claire, rapide et adaptée au mobile.
                </p>

                <div class="hero-actions">
                    <a class="btn-hero" href="wbfInvoiceEdit.aspx">Nouvelle facture</a>
                    <a class="btn-soft" href="wbfCustomers.aspx">Voir les clients</a>
                    <a class="btn-soft" href="Settings.aspx">Paramètres</a>
                </div>
            </div>

            <div class="hero-right">
                <div class="hero-mini-stats">
                    <div class="mini-stat">
                        <div class="mini-stat-label">Ventes du mois</div>
                        <div class="mini-stat-value">24 580 $</div>
                        <div class="mini-stat-note">+12.4% vs mois dernier</div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label">Factures ouvertes</div>
                        <div class="mini-stat-value">18</div>
                        <div class="mini-stat-note">5 à relancer cette semaine</div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label">Clients actifs</div>
                        <div class="mini-stat-value">326</div>
                        <div class="mini-stat-note">Nouveaux ce mois-ci : 14</div>
                    </div>

                    <div class="mini-stat">
                        <div class="mini-stat-label">Produits</div>
                        <div class="mini-stat-value">1 248</div>
                        <div class="mini-stat-note">Catalogue synchronisé</div>
                    </div>
                </div>
            </div>
        </section>

        <!-- KPI -->
        <section class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label">Clients</div>
                    <div class="kpi-icon">👥</div>
                </div>
                <div class="kpi-value">326</div>
                <div class="kpi-foot">14 nouveaux clients ce mois-ci</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label">Factures</div>
                    <div class="kpi-icon">🧾</div>
                </div>
                <div class="kpi-value">87</div>
                <div class="kpi-foot">18 ouvertes, 69 payées</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label">Produits</div>
                    <div class="kpi-icon">📦</div>
                </div>
                <div class="kpi-value">1 248</div>
                <div class="kpi-foot">Catalogue prêt pour la vente</div>
            </div>

            <div class="kpi-card">
                <div class="kpi-head">
                    <div class="kpi-label">Revenus</div>
                    <div class="kpi-icon">💰</div>
                </div>
                <div class="kpi-value">24 580 $</div>
                <div class="kpi-foot">Performance du mois courant</div>
            </div>
        </section>

        <section class="layout-grid">

            <!-- GAUCHE -->
            <div style="display:flex; flex-direction:column; gap:22px;">

                <!-- MODULES -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title">Modules</div>
                            <div class="panel-sub">Accès rapide aux sections principales</div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="module-grid">
                            <a class="module-card" href="wbfCustomers.aspx">
                                <div class="module-icon">👥</div>
                                <div class="module-title">Clients</div>
                                <div class="module-desc">
                                    Consultez, ajoutez et modifiez vos clients.
                                </div>
                            </a>

                            <a class="module-card" href="wbfInvoice.aspx">
                                <div class="module-icon">🧾</div>
                                <div class="module-title">Factures</div>
                                <div class="module-desc">
                                    Gérez vos factures, paiements et suivis.
                                </div>
                            </a>

                            <a class="module-card" href="wbfProducts.aspx">
                                <div class="module-icon">📦</div>
                                <div class="module-title">Produits</div>
                                <div class="module-desc">
                                    Maintenez votre catalogue et vos prix.
                                </div>
                            </a>

                            <a class="module-card" href="wbfSuppliers.aspx">
                                <div class="module-icon">🏭</div>
                                <div class="module-title">Fournisseurs</div>
                                <div class="module-desc">
                                    Suivi des partenaires et des approvisionnements.
                                </div>
                            </a>

                            <a class="module-card" href="wbfReceipt.aspx">
                                <div class="module-icon">🧾</div>
                                <div class="module-title">Reçus</div>
                                <div class="module-desc">
                                    Consultez les reçus et les encaissements.
                                </div>
                            </a>

                            <a class="module-card" href="Settings.aspx">
                                <div class="module-icon">⚙️</div>
                                <div class="module-title">Paramètres</div>
                                <div class="module-desc">
                                    Configurez l’entreprise, les taxes et l’email.
                                </div>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- FACTURES RÉCENTES -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title">Factures récentes</div>
                            <div class="panel-sub">Aperçu rapide des dernières opérations</div>
                        </div>
                        <a class="link-muted" href="wbfInvoice.aspx">Voir tout</a>
                    </div>

                    <div class="panel-body" style="padding-top:0;">
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>No</th>
                                        <th>Client</th>
                                        <th>Date</th>
                                        <th>Montant</th>
                                        <th>Statut</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>#1048</td>
                                        <td>Baignoire Expert</td>
                                        <td>11 mars 2026</td>
                                        <td>1 245,00 $</td>
                                        <td><span class="badge badge-warning">Ouverte</span></td>
                                    </tr>
                                    <tr>
                                        <td>#1047</td>
                                        <td>Construction Nova</td>
                                        <td>10 mars 2026</td>
                                        <td>2 890,00 $</td>
                                        <td><span class="badge badge-success">Payée</span></td>
                                    </tr>
                                    <tr>
                                        <td>#1046</td>
                                        <td>Immeubles Rive-Nord</td>
                                        <td>10 mars 2026</td>
                                        <td>780,00 $</td>
                                        <td><span class="badge badge-warning">Ouverte</span></td>
                                    </tr>
                                    <tr>
                                        <td>#1045</td>
                                        <td>Atelier du Bain</td>
                                        <td>9 mars 2026</td>
                                        <td>560,00 $</td>
                                        <td><span class="badge badge-danger">En retard</span></td>
                                    </tr>
                                    <tr>
                                        <td>#1044</td>
                                        <td>Gestion MTL</td>
                                        <td>8 mars 2026</td>
                                        <td>4 120,00 $</td>
                                        <td><span class="badge badge-success">Payée</span></td>
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
                            <div class="panel-title">Actions rapides</div>
                            <div class="panel-sub">Les opérations les plus utilisées</div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="quick-actions">
                            <a class="quick-btn" href="wbfInvoiceEdit.aspx">
                                <span class="quick-ico">➕</span>
                                <span>Créer une facture</span>
                            </a>

                            <a class="quick-btn" href="wbfCustomers.aspx">
                                <span class="quick-ico">👤</span>
                                <span>Ajouter un client</span>
                            </a>

                            <a class="quick-btn" href="wbfProducts.aspx">
                                <span class="quick-ico">📦</span>
                                <span>Ajouter un produit</span>
                            </a>

                            <a class="quick-btn" href="wbfReceipt.aspx">
                                <span class="quick-ico">💵</span>
                                <span>Voir les reçus</span>
                            </a>
                        </div>
                    </div>
                </div>

                <!-- ACTIVITÉS -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title">Activité récente</div>
                            <div class="panel-sub">Derniers événements du système</div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div class="activity-list">
                            <div class="activity-item">
                                <span class="activity-dot dot-blue"></span>
                                <div class="activity-main">
                                    <div class="activity-text">La facture #1048 a été créée.</div>
                                    <div class="activity-time">Aujourd’hui à 08:42</div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-green"></span>
                                <div class="activity-main">
                                    <div class="activity-text">Paiement reçu pour la facture #1047.</div>
                                    <div class="activity-time">Aujourd’hui à 07:58</div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-orange"></span>
                                <div class="activity-main">
                                    <div class="activity-text">Un nouveau client a été ajouté au système.</div>
                                    <div class="activity-time">Hier à 16:21</div>
                                </div>
                            </div>

                            <div class="activity-item">
                                <span class="activity-dot dot-red"></span>
                                <div class="activity-main">
                                    <div class="activity-text">La facture #1045 est maintenant en retard.</div>
                                    <div class="activity-time">Hier à 09:14</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- PETITE CARTE INFO -->
                <div class="panel">
                    <div class="panel-head">
                        <div>
                            <div class="panel-title">Résumé</div>
                            <div class="panel-sub">État général de votre environnement</div>
                        </div>
                    </div>

                    <div class="panel-body">
                        <div style="display:flex; flex-direction:column; gap:12px;">
                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;">Base clients</span>
                                <strong>À jour</strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;">Taxes</span>
                                <strong>Configurées</strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;">Emails</span>
                                <strong>Actifs</strong>
                            </div>

                            <div style="display:flex; align-items:center; justify-content:space-between; gap:12px;">
                                <span style="color:var(--mc-muted); font-size:14px;">PDF / Modèles</span>
                                <strong>Disponibles</strong>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </section>
    </div>
</main>

</asp:Content>