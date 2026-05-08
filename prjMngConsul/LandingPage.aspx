<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="LandingPage.aspx.vb" Inherits="MngConsul.LandingPage" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>60S-AI — La gestion financière 100% automatisée pour les PME</title>
    <meta name="description" content="60S-AI révolutionne l'administration des PME et travailleurs autonomes grâce à l'intelligence artificielle." />
    <link href="css/landingpage.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">

    <!-- ===== NAVIGATION ===== -->
    <nav class="navbar">
        <div class="nav-container">
            <a href="#" class="logo">
                <div class="logo-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
                    </svg>
                </div>
                <span class="logo-text">60S-AI</span>
            </a>

            <div class="nav-links">
                <a href="#problem">Problème</a>
                <a href="#solution">Solution</a>
                <a href="#features">Fonctionnalités</a>
                <a href="#mission">Mission</a>
            </div>

            <div class="nav-actions">
                <button type="button" class="btn-lang">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
                        <path d="M2 12h20"></path>
                    </svg>
                    FR
                </button>
               
               
                <asp:LinkButton ID="lnkConnexion"  runat="server" CssClass="btn-connexion"
                    CausesValidation="false">Connexion</asp:LinkButton>



                
                  <a href="#plangrid"  Class="btn-connexion"  >Inscription</a>
            </div>
        </div>
    </nav>

    <!-- ===== HERO ===== -->
    <section class="hero">
        <div class="hero-bg-blur-1"></div>
        <div class="hero-bg-blur-2"></div>
        <div class="hero-grid"></div>

        <div class="hero-container">
            <div class="hero-flex">
                <div class="hero-content">
                    <div class="badge">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
                        </svg>
                        Une première au Québec et au Canada
                    </div>

                    <h1 class="hero-title">
                        La gestion financière <span class="highlight">100% automatisée</span> pour les PME &amp; les Travailleurs Autonomes
                    </h1>

                    <p class="hero-subtitle">
                        60S-AI révolutionne l'administration des PME &amp; des Travailleurs Autonomes grâce à une intelligence artificielle qui automatise votre comptabilité, vos remises et vos états financiers — en temps réel, sans effort.
                    </p>

                    <div class="hero-buttons">
                        <a href="#cta" class="btn-primary">
                            Commencer gratuitement
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="20" height="20">
                                <path d="M5 12h14"></path>
                                <path d="m12 5 7 7-7 7"></path>
                            </svg>
                        </a>
                        <a href="#solution" class="btn-secondary">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="16" height="16">
                                <polygon points="5 3 19 12 5 21 5 3"></polygon>
                            </svg>
                            Voir la démo
                        </a>
                    </div>

                    <div class="hero-trust">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"></path>
                        </svg>
                        Sécurisé et conforme
                    </div>
                </div>

                <!-- Mockup Tableau de bord -->
                <div class="hero-visual">
                    <div class="dashboard-mockup">
                        <div class="mockup-header">
                            <div class="mockup-dots">
                                <div class="mockup-dot red"></div>
                                <div class="mockup-dot yellow"></div>
                                <div class="mockup-dot green"></div>
                            </div>
                            <div class="mockup-url">app.60s.ca — Tableau de bord</div>
                        </div>
                        <div class="mockup-body">
                            <div class="mockup-title-row">
                                <h3>Aperçu financier — Avril 2026</h3>
                                <span class="tag-live">En direct</span>
                            </div>

                            <div class="kpi-grid">
                                <div class="kpi-card">
                                    <p class="kpi-label">Revenus</p>
                                    <p class="kpi-value">142 500 $</p>
                                    <p class="kpi-trend up">+12%</p>
                                </div>
                                <div class="kpi-card">
                                    <p class="kpi-label">Dépenses</p>
                                    <p class="kpi-value">68 200 $</p>
                                    <p class="kpi-trend down">-4%</p>
                                </div>
                                <div class="kpi-card">
                                    <p class="kpi-label">Trésorerie</p>
                                    <p class="kpi-value">74 300 $</p>
                                    <p class="kpi-trend up">+8%</p>
                                </div>
                            </div>

                            <div class="ai-card">
                                <p class="ai-label">Assistant IA</p>
                                <div class="ai-message">
                                    <div class="ai-avatar">
                                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                                            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
                                        </svg>
                                    </div>
                                    <div class="ai-bubble">
                                        Votre TPS/TVQ de <strong>8 240 $</strong> est due dans 12 jours. Je prépare la remise automatiquement — souhaitez-vous que je la transmette?
                                    </div>
                                </div>
                            </div>

                            <div class="task-row"><span class="task-label">Paie traitée — 8 employés</span><span class="task-status done">Complété</span></div>
                            <div class="task-row"><span class="task-label">Factures clients envoyées</span><span class="task-status pending">3 en attente</span></div>
                            <div class="task-row"><span class="task-label">Remise DAS — Juillet</span><span class="task-status pending">Automatique</span></div>
                        </div>
                    </div>
                     
                </div>
            </div>
        </div>
    </section>

    <!-- ===== PROBLÈME ===== -->
    <section id="problem" class="section section-light">
        <div class="container">
            <div class="section-header">
                <div class="badge-light badge-rose">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"></path>
                        <path d="M12 9v4"></path>
                        <path d="M12 17h.01"></path>
                    </svg>
                    Le problème réel des PME &amp; des Travailleurs Autonomes
                </div>
                <h2 class="section-title">
                    Les PME &amp; les Travailleurs Autonomes ont les mêmes obligations <span class="text-rose">que les grandes entreprises</span>
                </h2>
                <p class="section-subtitle">
                    Pourtant, les solutions intégrées demeurent trop complexes ou trop coûteuses pour des entreprises qui représentent <strong>90 % du tissu économique canadien.</strong>
                </p>
            </div>

            <div class="problem-grid">
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                    </div>
                    <div>
                        <h4>Gestion des rendez-vous clients</h4>
                        <p>Agenda, gestion des rappels</p>
                    </div>
                </div>
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path></svg>
                    </div>
                    <div>
                        <h4>Livres comptables</h4>
                        <p>Journal, grand livre, balance</p>
                    </div>
                </div>
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"></path><path d="M14 2v4a2 2 0 0 0 2 2h4"></path></svg>
                    </div>
                    <div>
                        <h4>Facturation client</h4>
                        <p>Création, envoi, suivi des paiements</p>
                    </div>
                </div>
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"></rect><line x1="2" x2="22" y1="10" y2="10"></line></svg>
                    </div>
                    <div>
                        <h4>Paiements fournisseurs</h4>
                        <p>Approbation, paiement, réconciliation</p>
                    </div>
                </div>
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"></path><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"></path></svg>
                    </div>
                    <div>
                        <h4>Remises gouvernementales</h4>
                        <p>TPS/TVQ, DAS</p>
                    </div>
                </div>
                <div class="problem-card">
                    <div class="problem-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 5c-1.5 0-2.8 1.4-3 2-3.5-1.5-11-.3-11 5 0 1.8 0 3 2 4.5V20h4v-2h3v2h4v-4c1-.5 1.7-1 2-2h2v-4h-2c0-1-.5-1.5-1-2h0V5z"></path></svg>
                    </div>
                    <div>
                        <h4>Gestion de trésorerie</h4>
                        <p>Flux, prévisions, liquidités</p>
                    </div>
                </div>
            </div>

            <div class="result-banner">
                <p class="label">Résultat :</p>
                <p>
                    Des entrepreneurs <span class="text-rose-400">débordés</span>, freinés par une lourdeur administrative qui nuit directement à leur <span class="text-amber">productivité</span> et à leur <span class="text-emerald-400">croissance</span>.
                </p>
                <div class="result-tagline">60S-AI met fin à ce non-sens.</div>
            </div>
        </div>
    </section>

    <!-- ===== SOLUTION ===== -->
    <section id="solution" class="section section-gray">
        <div class="container">
            <div class="section-header">
                <div class="badge-light badge-sky">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="16" height="16"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
                    La solution 60S-AI
                </div>
                <h2 class="section-title">Contrairement aux outils actuels, <span class="text-sky">60S-AI offre une intégration complète</span></h2>
                <p class="section-subtitle">Tout est centralisé, automatisé et pensé pour l'entrepreneur, pas pour les spécialistes.</p>
            </div>

            <div class="solution-flex">
                <div class="checklist">
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>Intégration complète de toutes les fonctions administratives</p></div>
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>Intelligence artificielle qui vous guide en temps réel</p></div>
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>États financiers générés automatiquement</p></div>
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>Remises gouvernementales soumises sans intervention</p></div>
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>Zéro dépendance à un comptable externe</p></div>
                    <div class="check-item"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><path d="m9 11 3 3L22 4"></path></svg><p>Tableau de bord centralisé, pensé pour l'entrepreneur</p></div>
                    <a href="#cta" class="btn-primary" style="margin-top:16px;">Découvrir la plateforme</a>
                </div>

                <div class="compare-table">
                    <div class="compare-header">Comparaison de marché</div>
                    <div class="compare-row head">
                        <p>Critère</p>
                        <p style="text-align:center;">Autres outils</p>
                        <p class="amber" style="text-align:center;">60S-AI</p>
                    </div>
                    <div class="compare-row"><p class="col-label">Intégration</p><p class="col-other">Outils partiels, silos</p><p class="col-60s">Tout centralisé en un seul endroit</p></div>
                    <div class="compare-row"><p class="col-label">Automatisation</p><p class="col-other">Saisie manuelle requise</p><p class="col-60s">100% automatisé par IA</p></div>
                    <div class="compare-row"><p class="col-label">Assistance</p><p class="col-other">Manuel PDF, support limité</p><p class="col-60s">IA conversationnelle en temps réel</p></div>
                    <div class="compare-row"><p class="col-label">Coût</p><p class="col-other">Abonnements multiples + comptable</p><p class="col-60s">Un seul abonnement accessible</p></div>
                    <div class="compare-row"><p class="col-label">Complexité</p><p class="col-other">Conçu pour les spécialistes</p><p class="col-60s">Pensé pour l'entrepreneur</p></div>
                </div>
            </div>

            <div class="feature-cards-4">
                <div class="feature-card-light">
                    <div class="feature-icon-circle icon-sky">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5a3 3 0 1 0-5.997.125 4 4 0 0 0-2.526 5.77 4 4 0 0 0 .556 6.588A4 4 0 1 0 12 18Z"></path><path d="M12 5a3 3 0 1 1 5.997.125 4 4 0 0 1 2.526 5.77 4 4 0 0 1-.556 6.588A4 4 0 1 1 12 18Z"></path></svg>
                    </div>
                    <h3>IA conversationnelle</h3>
                    <p>Posez vos questions en français, obtenez des réponses claires sur vos finances — à toute heure.</p>
                </div>
                <div class="feature-card-light">
                    <div class="feature-icon-circle icon-emerald">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"></path><path d="M18 17V9"></path><path d="M13 17V5"></path><path d="M8 17v-3"></path></svg>
                    </div>
                    <h3>États financiers en temps réel</h3>
                    <p>Bilan, résultats, flux de trésorerie — générés automatiquement, toujours à jour.</p>
                </div>
                <div class="feature-card-light">
                    <div class="feature-icon-circle icon-amber">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                    </div>
                    <h3>Remises automatiques</h3>
                    <p>TPS/TVQ, DAS, acomptes provisionnels — calculés et soumis sans votre intervention.</p>
                </div>
                <div class="feature-card-light">
                    <div class="feature-icon-circle icon-slate">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
                    </div>
                    <h3>Tout en moins de 60 secondes</h3>
                    <p>Accédez à l'état complet de votre entreprise en quelques secondes, à tout moment.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- ===== FONCTIONNALITÉS ===== -->
    <section id="features" class="section section-light">
        <div class="container">
            <div class="section-header">
                <div class="badge-light badge-emerald">Fonctionnalités complètes</div>
                <h2 class="section-title">Toute votre administration. <span class="text-emerald">Un seul endroit.</span></h2>
                <p class="section-subtitle">60S-AI couvre l'ensemble des obligations administratives de votre PME — sans compromis, sans modules supplémentaires, sans surprise.</p>
            </div>

            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle></svg></div>
                    <p class="feature-cat">Ressources humaines</p>
                    <h3>Paie automatisée</h3>
                    <p>Calcul automatique des salaires, déductions, DAS et talons de paie. Conformité garantie avec les lois du travail.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-popular">Populaire</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"></path></svg></div>
                    <p class="feature-cat">Facturation</p>
                    <h3>Facturation intelligente</h3>
                    <p>Créez, envoyez et suivez vos factures. L'IA relance automatiquement les comptes en souffrance.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"></rect><line x1="2" x2="22" y1="10" y2="10"></line></svg></div>
                    <p class="feature-cat">Fournisseurs</p>
                    <h3>Paiements fournisseurs</h3>
                    <p>Centralisez vos factures fournisseurs, approuvez les paiements et réconciliez automatiquement.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-key">Clé</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"></path></svg></div>
                    <p class="feature-cat">Gouvernement</p>
                    <h3>Remises gouvernementales</h3>
                    <p>TPS/TVQ, DAS, acomptes provisionnels — tout est calculé, préparé et soumis automatiquement.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path></svg></div>
                    <p class="feature-cat">Comptabilité</p>
                    <h3>Livres comptables automatiques</h3>
                    <p>Chaque transaction est automatiquement journalisée, classifiée et reportée.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 5c-1.5 0-2.8 1.4-3 2-3.5-1.5-11-.3-11 5 0 1.8 0 3 2 4.5V20h4v-2h3v2h4v-4c1-.5 1.7-1 2-2h2v-4h-2c0-1-.5-1.5-1-2h0V5z"></path></svg></div>
                    <p class="feature-cat">Trésorerie</p>
                    <h3>Gestion des liquidités</h3>
                    <p>Visualisez vos flux en temps réel, anticipez les manques de liquidités et optimisez votre trésorerie.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-ai">IA</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg></div>
                    <p class="feature-cat">Intelligence artificielle</p>
                    <h3>Assistant IA en temps réel</h3>
                    <p>Posez n'importe quelle question sur vos finances en français. L'IA vous répond et prend des actions pour vous.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"></path><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"></path></svg></div>
                    <p class="feature-cat">Alertes intelligentes</p>
                    <h3>Notifications proactives</h3>
                    <p>Recevez des alertes avant les échéances fiscales, les dépassements budgétaires et les anomalies.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-new">Nouveau</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"></path><path d="M16 2v4"></path><rect width="18" height="18" x="3" y="4" rx="2"></rect><path d="M3 10h18"></path></svg></div>
                    <p class="feature-cat">Gestion clients</p>
                    <h3>CRM &amp; Agenda intégré</h3>
                    <p>Gérez vos clients, vos contacts et vos rendez-vous dans un seul espace.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-new">Nouveau</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="15" r="3"></circle><circle cx="9" cy="7" r="4"></circle><path d="M10 15H6a4 4 0 0 0-4 4v2"></path></svg></div>
                    <p class="feature-cat">Ressources humaines</p>
                    <h3>Portail employé</h3>
                    <p>Chaque employé accède à ses talons de paie, ses congés, ses documents RH et son horaire.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-new">Nouveau</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"></path><circle cx="12" cy="12" r="2"></circle><path d="M19.1 4.9C23 8.8 23 15.1 19.1 19"></path></svg></div>
                    <p class="feature-cat">Communication</p>
                    <h3>Notifications en temps réel</h3>
                    <p>Envoyez des alertes, des messages et des annonces à vos employés ou clients instantanément.</p>
                </div>
                <div class="feature-card">
                    <span class="feature-tag tag-key">Clé</span>
                    <div class="feature-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 3 4 7l4 4"></path><path d="M4 7h16"></path><path d="m16 21 4-4-4-4"></path><path d="M20 17H4"></path></svg></div>
                    <p class="feature-cat">Réconciliation</p>
                    <h3>Réconciliation bancaire</h3>
                    <p>Chaque transaction est rapprochée automatiquement avec vos relevés bancaires en temps réel.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- ===== PLANS / PRICING ===== -->
    <section id="plans" class="section section-light">
        <div class="container">
            <div class="section-header">
                <div class="badge-light badge-sky">Conçu pour les entreprises de 0 à 9 employés</div>
                <h2 class="section-title">Un plan taillé <span class="text-sky">sur mesure</span> pour votre réalité</h2>
                <p class="section-subtitle">Que vous soyez Travailleur Autonome, entrepreneur incorporé ou à la tête d'une petite équipe, 60S-AI s'adapte exactement à votre structure.</p>
            </div>
              <div  id="plangrid" style="height:74px;">
              </div>
            <div class="plans-grid">
                <!-- Plan 1 : Travailleur autonome -->
                <div class="plan-card">
                    <div class="plan-icon-circle plan-icon-slate">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                    </div>
                    <h3>Travailleur Autonome</h3>
                    <p class="plan-tagline">Sans incorporation</p>
                    <span class="plan-pill">0 employé</span>
                    <p class="plan-desc">Idéal pour le Travailleur Autonome non incorporé qui veut gérer ses finances simplement.</p>
                    <div class="plan-price"><span class="amount">69,99 $</span><span class="period">/ mois</span></div>
                    <ul class="plan-features">
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Gestion des clients avec calendrier</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Facturation client</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Gestion des fournisseurs</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Plan comptable complet</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>États financiers en temps réel</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Remises gouvernementales</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Assistant IA en français</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Point de vente (POS)</span></li>
                    </ul>
                    <a href="wbfRegister.aspx?ab=solo" class="plan-button">Commencer gratuitement</a>
                </div>

                <!-- Plan 2 : Compagnie Solo (featured) -->
                <div class="plan-card featured">
                    <div class="plan-badge-popular">Le plus populaire</div>
                    <div class="plan-icon-circle plan-icon-sky">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><polyline points="16 11 18 13 22 9"></polyline></svg>
                    </div>
                    <h3>Compagnie Solo</h3>
                    <p class="plan-tagline">Avec incorporation</p>
                    <span class="plan-pill">0 employé</span>
                    <p class="plan-desc">Pour l'entrepreneur incorporé qui décide de ne pas se verser de salaire.</p>
                    <div class="plan-price"><span class="amount">99,99 $</span><span class="period">/ mois</span></div>
                    <ul class="plan-features">
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Tout du plan Travailleur Autonome</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Comptabilité d'entreprise incorporée</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Dividendes &amp; rémunération mixte</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Fermeture &amp; ouverture d'année</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Connexion compte bancaire</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Conciliation financière automatisée</span></li>
                    </ul>
                    <a href="wbfRegister.aspx?ab=comsolo" class="plan-button">Commencer gratuitement</a>
                </div>

                <!-- Plan 3 : Compagnie 1-19 -->
                <div class="plan-card emerald-bordered">
                    <div class="plan-icon-circle plan-icon-emerald">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path></svg>
                    </div>
                    <h3>Compagnie 1–19</h3>
                    <p class="plan-tagline">1 à 9 employés</p>
                    <span class="plan-pill">1–19 employés</span>
                    <p class="plan-desc">Conçu pour les PME en croissance avec une équipe d'employés à temps plein.</p>
                    <div class="plan-price"><span class="amount">149,99 $</span><span class="period">/ mois</span></div>
                    <ul class="plan-features">
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Tout du plan Compagnie Solo</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Paie jusqu'à 19 employés</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Portail employé &amp; talons de paie</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Gestion des congés &amp; maladies</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Contrats &amp; T4A</span></li>
                        <li class="plan-feature"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"></path></svg><span>Alertes de conformité RH</span></li>
                    </ul>
                    <a href="wbfRegister.aspx?ab=scom119" class="plan-button">Commencer gratuitement</a>
                </div>
            </div>

            <p class="plans-note">Tous les plans incluent un essai gratuit. Aucune carte de crédit requise. Annulation à tout moment.</p>
        </div>
    </section>

    <!-- ===== MISSION ===== -->
    <section id="mission" class="section section-dark">
        <div class="grid-bg"></div>
        <div class="container">
            <div class="mission-flex">
                <div>
                    <div class="badge">Notre mission</div>
                    <h2 class="section-title mission-title">Les PME &amp; les Travailleurs Autonomes sont le moteur de la prospérité économique canadienne</h2>
                    <p class="mission-subtitle">En les soutenant concrètement, nous encourageons leur croissance, leur pérennité et leur réussite. 60S-AI n'est pas qu'un outil.</p>
                    <div class="mission-quote">
                        <h3>60S-AI est un partenaire de croissance</h3>
                        <p>pour les entrepreneurs d'aujourd'hui.</p>
                    </div>
                </div>

                <div class="mission-cards">
                    <div class="mission-card">
                        <div class="mission-card-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg></div>
                        <div>
                            <h3>Libérer les entrepreneurs</h3>
                            <p>Éliminer les tâches administratives répétitives pour que vous puissiez vous concentrer sur ce qui compte.</p>
                        </div>
                    </div>
                    <div class="mission-card">
                        <div class="mission-card-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"></polyline><polyline points="16 7 22 7 22 13"></polyline></svg></div>
                        <div>
                            <h3>Redonner du temps</h3>
                            <p>Chaque heure économisée sur l'administration est une heure investie dans la croissance et vos clients.</p>
                        </div>
                    </div>
                    <div class="mission-card">
                        <div class="mission-card-icon"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="6"></circle><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"></path></svg></div>
                        <div>
                            <h3>Créer de la valeur durable</h3>
                            <p>En soutenant les PME &amp; les Travailleurs Autonomes, nous contribuons à la prospérité économique canadienne.</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <p class="stat-number">90%</p>
                    <p class="stat-label">des entreprises canadiennes sont des PME</p>
                    <p class="stat-source">Selon Statistiques Canada</p>
                </div>
                <div class="stat-card">
                    <p class="stat-number">20h+</p>
                    <p class="stat-label">économisées par mois en administration</p>
                    <p class="stat-source">Par entrepreneur en moyenne</p>
                </div>
                <div class="stat-card">
                    <p class="stat-number">#1</p>
                    <p class="stat-label">solution IA d'administration au Canada</p>
                    <p class="stat-source">Première plateforme intégrée</p>
                </div>
            </div>
        </div>
    </section>

    <!-- ===== CTA ===== -->
    <section id="cta" class="section section-light">
        <div class="container">
            <div class="cta-box">
                <div class="cta-grid-bg"></div>
                <div class="cta-box-content">
                    <div class="badge">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="16" height="16"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
                        Devenez un leader
                    </div>
                    <h2 class="cta-title">Prêt à transformer votre gestion financière ?</h2>
                    <p class="cta-subtitle">Rejoignez les premières PME &amp; Travailleurs Autonomes qui font confiance à 60S-AI pour automatiser leur administration — et reprendre le contrôle de leur temps.</p>

                    <div class="cta-form">
                        <asp:Button ID="btnDemarrer" runat="server" Text="Démarrer →"
                            CssClass="btn-primary"   CausesValidation="false" />
                    </div>

                    <div class="cta-trust">
                        <div class="cta-trust-item"><div class="cta-trust-dot"></div>Configuration en moins de 10 minutes</div>
                        <div class="cta-trust-item"><div class="cta-trust-dot"></div>Support en français inclus</div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- ===== FOOTER ===== -->
    <footer class="footer">
        <div class="footer-container">
            <div class="footer-grid">
                <div class="footer-brand">
                    <a href="#" class="logo">
                        <div class="logo-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
                        </div>
                        <span class="logo-text">60S-AI</span>
                    </a>
                    <p>L'administration financière automatisée pour les PME &amp; les Travailleurs Autonomes du Québec et du Canada.</p>
                    <div class="footer-socials">
                        <a href="#" aria-label="Twitter"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z"></path></svg></a>
                        <a href="#" aria-label="LinkedIn"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"></path><rect width="4" height="12" x="2" y="9"></rect><circle cx="4" cy="4" r="2"></circle></svg></a>
                        <a href="#" aria-label="Email"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="16" x="2" y="4" rx="2"></rect><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"></path></svg></a>
                    </div>
                </div>

                <div class="footer-links">
                    <div class="footer-col">
                        <h4>Produit</h4>
                        <ul>
                            <li><a href="#features">Fonctionnalités</a></li>
                            <li><a href="#plans">Tarification</a></li>
                            <li><a href="#">Sécurité</a></li>
                            <li><a href="#">API</a></li>
                            <li><a href="#">Nouveautés</a></li>
                        </ul>
                    </div>
                    <div class="footer-col">
                        <h4>Ressources</h4>
                        <ul>
                            <li><a href="#">Documentation</a></li>
                            <li><a href="#">Guides</a></li>
                            <li><a href="#">Blog</a></li>
                            <li><a href="#">Communauté</a></li>
                            <li><a href="#">Statut</a></li>
                        </ul>
                    </div>
                    <div class="footer-col">
                        <h4>Entreprise</h4>
                        <ul>
                            <li><a href="#">À propos</a></li>
                            <li><a href="#">Carrières</a></li>
                            <li><a href="#">Partenaires</a></li>
                            <li><a href="#">Presse</a></li>
                            <li><a href="#">Contact</a></li>
                        </ul>
                    </div>
                    <div class="footer-col">
                        <h4>Légal</h4>
                        <ul>
                            <li><a href="#">Conditions d'utilisation</a></li>
                            <li><a href="#">Confidentialité</a></li>
                            <li><a href="#">Sécurité des données</a></li>
                            <li><a href="#">Conformité</a></li>
                        </ul>
                    </div>
                </div>
            </div>

            <div class="footer-bottom">
                <p class="footer-copyright">© 2026 60s Technologies Inc. Tous droits réservés. Fièrement conçu au Québec.</p>
                <div class="footer-status">
                    <div class="footer-status-dot"></div>
                    Tous les systèmes opérationnels
                </div>
            </div>
        </div>
    </footer>

    </form>
</body>
</html>
