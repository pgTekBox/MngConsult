<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="LandingPage.aspx.vb" Inherits="MngConsul.LandingPage" %>
<!doctype html>
<html lang="fr-CA">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>60sec-AI — Gestion financière 100% automatisée</title>
    <link href="css/landingpage.css" rel="stylesheet" />
    <script src="js/lucide.min.js"></script>
    <style>
        html {
            scroll-behavior: smooth
        }

        [data-page].hidden {
            display: none !important
        }

        body {
            margin: 0
        }
    </style>
</head>
<body class="font-sans antialiased bg-white text-slate-900">
    <nav class="fixed top-0 left-0 right-0 z-50 transition-all duration-300 bg-white/95 backdrop-blur-md shadow-sm shadow-slate-200/80 border-b border-slate-100">
        <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="flex items-center justify-between h-16 lg:h-20">
                <a data-nav="accueil" href="#" class="flex items-center gap-2 group">
                    <div class="w-9 h-9 bg-blue-600 rounded-lg flex items-center justify-center group-hover:bg-blue-500 transition-colors">
                        <i data-lucide="zap" class="w-5 h-5 text-white fill-white"></i>
                    </div>
                    <span class="text-slate-900 font-bold text-2xl tracking-tight">60sec-AI</span>
                </a>
                <div class="hidden md:flex items-center gap-8">
                    <a data-nav="accueil" href="#problem" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Problème</a>
                    <a data-nav="accueil" href="#solution" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Solution</a>
                    <a data-nav="accueil" href="#features" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Fonctionnalités</a>
                    <a data-nav="accueil" href="#mission" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Mission</a>
                </div>
                <div class="hidden md:flex items-center gap-4">
                    <div class="relative">
                        <button class="flex items-center gap-1.5 text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors px-2 py-1 rounded-lg hover:bg-slate-100">
                            <i data-lucide="globe" class="w-4 h-4"></i>FR
                        </button>
                    </div>
                    <a href="wbfLogin.aspx" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Connexion</a>
                    <a data-nav="accueil" href="#plans" class="bg-blue-700 hover:bg-blue-600 text-white text-sm font-semibold px-5 py-2.5 rounded-lg transition-all duration-200 hover:shadow-lg hover:shadow-blue-700/25">Inscription</a>
                </div>
                <button class="md:hidden text-slate-700 p-2">
                    <i data-lucide="menu" class="w-6 h-6"></i>
                </button>
            </div>
        </div>
    </nav>

    <main>
        <div class="page" data-page="accueil">
            <asp:Repeater ID="rptSections" runat="server">
                <ItemTemplate>
                    <%# RenderSection(Container.DataItem) %>
                </ItemTemplate>
            </asp:Repeater>
        </div>

        <div class="page hidden" data-page="documentation">
            <div class="min-h-screen font-sans antialiased bg-white">
                <main>
                    <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                        <div class="max-w-7xl mx-auto px-6 lg:px-8">
                            <div class="max-w-3xl">
                                <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                                    <i data-lucide="book-open" class="w-4 h-4"></i>Documentation
                                </div>
                                <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Documentation développeur</h1>
                                <p class="text-lg text-slate-600 leading-relaxed mb-8">Tout ce dont vous avez besoin pour intégrer 60sec-AI dans vos applications — de l'authentification aux webhooks en passant par les exports comptables.</p>
                                <div class="flex items-center gap-3">
                                    <a href="#quickstart" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-700/25">Démarrage rapide<i data-lucide="chevron-right" class="w-4 h-4"></i></a>
                                    <a href="#api" class="inline-flex items-center gap-2 bg-white border border-slate-200 hover:border-slate-300 text-slate-700 font-semibold px-6 py-3 rounded-xl transition-all duration-200">Référence API</a>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section class="py-20 bg-white">
                        <div class="max-w-7xl mx-auto px-6 lg:px-8">
                            <h2 class="text-2xl font-bold text-slate-900 mb-10">Explorer la documentation</h2>
                            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                                <a href="#quickstart" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="zap" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">Démarrage rapide</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">Intégrez 60sec-AI en moins de 5 minutes avec notre guide pas à pas.</p>
                                </a>
                                <a href="#api" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="terminal" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">Référence API</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">Explorez tous les endpoints REST, paramètres et réponses de l'API.</p>
                                </a>
                                <a href="#sdk" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="code-2" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">SDK &amp; Librairies</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">SDK officiels pour JavaScript, Python, PHP et d'autres langages.</p>
                                </a>
                                <a href="#webhooks" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="layers" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">Webhooks</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">Recevez des événements en temps réel dans vos systèmes.</p>
                                </a>
                                <a href="#auth" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="shield" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">Authentification</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">OAuth 2.0, clés API et gestion des permissions par rôle.</p>
                                </a>
                                <a href="#concepts" class="group p-6 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                                    <div class="w-11 h-11 bg-blue-50 group-hover:bg-blue-100 rounded-xl flex items-center justify-center mb-4 transition-colors"><i data-lucide="book-open" class="w-5 h-5 text-blue-600"></i></div>
                                    <h3 class="font-bold text-slate-900 mb-2">Concepts fondamentaux</h3>
                                    <p class="text-sm text-slate-500 leading-relaxed">Comprenez l'architecture de la plateforme et ses modèles de données.</p>
                                </a>
                            </div>
                        </div>
                    </section>

                    <section id="quickstart" class="py-20 bg-slate-50">
                        <div class="max-w-7xl mx-auto px-6 lg:px-8">
                            <h2 class="text-2xl font-bold text-slate-900 mb-3">Démarrage rapide</h2>
                            <p class="text-slate-600 mb-10">Intégrez l'API 60sec-AI en moins de 5 minutes.</p>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div class="bg-white rounded-2xl p-6 border border-slate-200 flex gap-5">
                                    <span class="text-3xl font-black text-blue-100 flex-shrink-0 leading-none">01</span>
                                    <div>
                                        <h3 class="font-bold text-slate-900 mb-1">Créer un compte</h3>
                                        <p class="text-sm text-slate-500 leading-relaxed">Inscrivez-vous gratuitement et récupérez votre clé API dans les paramètres du compte.</p>
                                    </div>
                                </div>
                                <div class="bg-white rounded-2xl p-6 border border-slate-200 flex gap-5">
                                    <span class="text-3xl font-black text-blue-100 flex-shrink-0 leading-none">02</span>
                                    <div>
                                        <h3 class="font-bold text-slate-900 mb-1">Installer le SDK</h3>
                                        <p class="text-sm text-slate-500 leading-relaxed">npm install @60sec-ai/sdk ou ajoutez la dépendance dans votre projet.</p>
                                    </div>
                                </div>
                                <div class="bg-white rounded-2xl p-6 border border-slate-200 flex gap-5">
                                    <span class="text-3xl font-black text-blue-100 flex-shrink-0 leading-none">03</span>
                                    <div>
                                        <h3 class="font-bold text-slate-900 mb-1">Premier appel API</h3>
                                        <p class="text-sm text-slate-500 leading-relaxed">Initialisez le client avec votre clé et appelez votre premier endpoint en quelques lignes.</p>
                                    </div>
                                </div>
                                <div class="bg-white rounded-2xl p-6 border border-slate-200 flex gap-5">
                                    <span class="text-3xl font-black text-blue-100 flex-shrink-0 leading-none">04</span>
                                    <div>
                                        <h3 class="font-bold text-slate-900 mb-1">Configurer les webhooks</h3>
                                        <p class="text-sm text-slate-500 leading-relaxed">Abonnez-vous aux événements paie, facture et remise pour réagir en temps réel.</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section id="api" class="py-20 bg-white">
                        <div class="max-w-7xl mx-auto px-6 lg:px-8">
                            <h2 class="text-2xl font-bold text-slate-900 mb-3">Exemple de requête API</h2>
                            <p class="text-slate-600 mb-8">Créez une remise de paie en une seule requête REST.</p>
                            <div class="bg-slate-950 rounded-2xl overflow-hidden border border-slate-800">
                                <div class="flex items-center gap-2 px-5 py-3 border-b border-slate-800">
                                    <div class="w-3 h-3 rounded-full bg-red-500/70"></div>
                                    <div class="w-3 h-3 rounded-full bg-amber-500/70"></div>
                                    <div class="w-3 h-3 rounded-full bg-emerald-500/70"></div>
                                    <span class="ml-2 text-xs text-slate-500 font-mono">Terminal</span>
                                </div>
                                <pre class="p-6 text-sm font-mono text-slate-300 overflow-x-auto leading-relaxed"><code>curl -X POST https://api.60sec-ai.ca/v1/payroll/remittances \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "period": "2026-06",
    "employees": [
      { "id": "emp_001", "gross": 4500.00 },
      { "id": "emp_002", "gross": 3800.00 }
    ],
    "auto_submit": true
  }'</code></pre>
                            </div>
                        </div>
                    </section>

                    <section id="sdk" class="py-20 bg-slate-50">
                        <div class="max-w-7xl mx-auto px-6 lg:px-8">
                            <h2 class="text-2xl font-bold text-slate-900 mb-3">SDK officiels</h2>
                            <p class="text-slate-600 mb-10">Bibliothèques maintenues par l'équipe 60sec-AI.</p>
                            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                                <div class="bg-white border border-slate-200 rounded-2xl p-5 flex items-center gap-3">
                                    <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center"><i data-lucide="code-2" class="w-5 h-5 text-blue-600"></i></div>
                                    <div>
                                        <p class="font-semibold text-slate-900 text-sm">JavaScript / Node.js</p>
                                        <p class="text-xs text-emerald-600 font-medium">Disponible</p>
                                    </div>
                                </div>
                                <div class="bg-white border border-slate-200 rounded-2xl p-5 flex items-center gap-3">
                                    <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center"><i data-lucide="code-2" class="w-5 h-5 text-blue-600"></i></div>
                                    <div>
                                        <p class="font-semibold text-slate-900 text-sm">Python</p>
                                        <p class="text-xs text-emerald-600 font-medium">Disponible</p>
                                    </div>
                                </div>
                                <div class="bg-white border border-slate-200 rounded-2xl p-5 flex items-center gap-3">
                                    <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center"><i data-lucide="code-2" class="w-5 h-5 text-blue-600"></i></div>
                                    <div>
                                        <p class="font-semibold text-slate-900 text-sm">PHP</p>
                                        <p class="text-xs text-emerald-600 font-medium">Disponible</p>
                                    </div>
                                </div>
                                <div class="bg-white border border-slate-200 rounded-2xl p-5 flex items-center gap-3">
                                    <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center"><i data-lucide="code-2" class="w-5 h-5 text-blue-600"></i></div>
                                    <div>
                                        <p class="font-semibold text-slate-900 text-sm">Ruby</p>
                                        <p class="text-xs text-emerald-600 font-medium">Disponible</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>
                </main>
            </div>
        </div>

        <div class="page hidden" data-page="guides">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="book-marked" class="w-4 h-4"></i>Guides
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Guides pratiques</h1>
                        <p class="text-lg text-slate-600 leading-relaxed">Des tutoriels pas à pas pour maîtriser chaque fonctionnalité de 60sec-AI, de la configuration initiale aux cas d'usage avancés.</p>
                    </div>
                </div>
            </section>

            <section class="py-16 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-xl font-bold text-slate-900 mb-6 flex items-center gap-2">
                        <i data-lucide="star" class="w-5 h-5 text-amber-500 fill-amber-500"></i>Guide en vedette
                    </h2>
                    <div class="bg-gradient-to-br from-blue-700 to-sky-500 rounded-2xl p-8 lg:p-10 text-white flex flex-col lg:flex-row items-start lg:items-center gap-6">
                        <div class="flex-1">
                            <span class="inline-block bg-white/20 text-white text-xs font-semibold px-3 py-1 rounded-full mb-4">Démarrage</span>
                            <h3 class="text-xl lg:text-2xl font-bold mb-3">Configurer votre première paie automatique en 10 minutes</h3>
                            <p class="text-sky-100 text-sm leading-relaxed mb-4">De la création du compte à la première remise DAS automatique, ce guide vous accompagne pas à pas dans la configuration complète.</p>
                            <div class="flex items-center gap-4 text-sm text-sky-100">
                                <span class="flex items-center gap-1.5"><i data-lucide="clock" class="w-4 h-4"></i>10 min</span>
                                <span>Débutant</span>
                            </div>
                        </div>
                        <a href="#" class="flex-shrink-0 flex items-center gap-2 bg-white hover:bg-sky-50 text-blue-700 font-bold px-7 py-3.5 rounded-xl transition-all duration-200">
                            <i data-lucide="play" class="w-4 h-4 fill-blue-700"></i>Commencer
                        </a>
                    </div>
                </div>
            </section>

            <section class="py-8 pb-24 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8 space-y-14">

                    <div>
                        <h2 class="text-xl font-bold text-slate-900 mb-6">Paie</h2>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Ajouter et gérer vos employés</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>5 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Configurer les déductions automatiques (RRQ, AE, impôt)</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>8 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-50 text-amber-700">Intermédiaire</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Gérer les congés et jours de maladie</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>6 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Émettre des T4 et relevés 1 en fin d'année</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>12 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-50 text-amber-700">Intermédiaire</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                        </div>
                    </div>

                    <div>
                        <h2 class="text-xl font-bold text-slate-900 mb-6">Comptabilité</h2>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Connecter votre compte bancaire</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>4 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Configurer les catégories de dépenses</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>7 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Générer vos états financiers mensuels</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>5 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Préparer votre déclaration de revenus</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>15 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700">Avancé</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                        </div>
                    </div>

                    <div>
                        <h2 class="text-xl font-bold text-slate-900 mb-6">Taxes &amp; Remises</h2>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Configurer la remise automatique TPS/TVH</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>6 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Configurer la remise automatique TPS/TVQ</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>6 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Gérer les acomptes provisionnels</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>10 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700">Avancé</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Préparer le Sommaire des retenues et cotisations</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>8 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-50 text-amber-700">Intermédiaire</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                        </div>
                    </div>

                    <div>
                        <h2 class="text-xl font-bold text-slate-900 mb-6">Intégrations</h2>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Connecter QuickBooks</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>5 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700">Débutant</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Importer depuis Sage 50</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>8 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-50 text-amber-700">Intermédiaire</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Configurer l'API REST</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>20 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700">Avancé</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                            <a href="#" class="group flex items-center gap-4 bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 transition-all duration-200 hover:shadow-sm">
                                <div class="flex-1">
                                    <h3 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors mb-2">Activer les webhooks temps réel</h3>
                                    <div class="flex items-center gap-3">
                                        <span class="flex items-center gap-1 text-xs text-slate-500"><i data-lucide="clock" class="w-3 h-3"></i>12 min</span>
                                        <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700">Avancé</span>
                                    </div>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                            </a>
                        </div>
                    </div>

                </div>
            </section>
        </div>

        <div class="page hidden" data-page="blog">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="rss" class="w-4 h-4"></i>Blog
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Actualités &amp; conseils</h1>
                        <p class="text-lg text-slate-600 leading-relaxed">Mises à jour produit, conseils fiscaux, stratégies de croissance pour les PME et travailleurs autonomes canadiens.</p>
                    </div>
                </div>
            </section>

            <section class="border-b border-slate-100 bg-white sticky top-16 z-10">
                <div class="max-w-7xl mx-auto px-6 lg:px-8 py-4">
                    <div class="flex items-center gap-2 overflow-x-auto scrollbar-hide">
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-blue-700 text-white border-blue-700">Tout</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Mise à jour produit</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Fiscalité</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Paie</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Conseils</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Croissance</button>
                        <button class="flex-shrink-0 flex items-center gap-1.5 text-sm font-medium px-4 py-2 rounded-full border transition-colors bg-white border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700"><i data-lucide="tag" class="w-3 h-3"></i>Technologie</button>
                    </div>
                </div>
            </section>

            <section class="py-16 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="flex items-center gap-2 mb-6">
                        <i data-lucide="trending-up" class="w-5 h-5 text-blue-600"></i>
                        <h2 class="text-xl font-bold text-slate-900">Article en vedette</h2>
                    </div>
                    <a href="#" class="group grid grid-cols-1 lg:grid-cols-2 gap-0 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-lg">
                        <div class="aspect-video lg:aspect-auto overflow-hidden">
                            <img src="img/landingpage-1.jpg" alt="60sec-AI v3.0 : remises DAS prédictives et assistant IA amélioré" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                        </div>
                        <div class="p-8 lg:p-10 flex flex-col justify-center">
                            <div class="flex items-center gap-3 mb-4">
                                <span class="text-xs font-semibold px-3 py-1 rounded-full bg-blue-50 text-blue-700">Mise à jour produit</span>
                                <span class="text-xs text-slate-400">10 juin 2026</span>
                            </div>
                            <h3 class="text-xl lg:text-2xl font-bold text-slate-900 mb-3 group-hover:text-blue-700 transition-colors leading-snug">60sec-AI v3.0 : remises DAS prédictives et assistant IA amélioré</h3>
                            <p class="text-slate-600 text-sm leading-relaxed mb-6">Notre dernier déploiement introduit un moteur de prédiction des remises basé sur l'historique de paie, un assistant IA conversationnel refondu et une intégration directe avec l'ARC.</p>
                            <div class="flex items-center gap-4 text-sm text-slate-500">
                                <span class="flex items-center gap-1.5"><i data-lucide="clock" class="w-4 h-4"></i>6 min de lecture</span>
                                <span class="flex items-center gap-1.5 text-blue-600 font-medium group-hover:gap-2.5 transition-all">Lire l'article <i data-lucide="arrow-right" class="w-4 h-4"></i></span>
                            </div>
                        </div>
                    </a>
                </div>
            </section>

            <section class="pb-24 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-xl font-bold text-slate-900 mb-8">Articles récents</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-2.jpg" alt="PIPEDA vs Loi 25 : ce que les PME québécoises doivent savoir en 2026" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-amber-50 text-amber-700">Fiscalité</span>
                                    <span class="text-xs text-slate-400">5 juin 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">PIPEDA vs Loi 25 : ce que les PME québécoises doivent savoir en 2026</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">Le délai de mise en conformité est passé — voici un récapitulatif des obligations qui s'appliquent à votre entreprise.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>8 min de lecture</span>
                            </div>
                        </a>

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-3.jpg" alt="5 erreurs courantes de remises TPS/TVQ (et comment les éviter)" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-sky-50 text-sky-700">Conseils</span>
                                    <span class="text-xs text-slate-400">28 mai 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">5 erreurs courantes de remises TPS/TVQ (et comment les éviter)</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">Des montants incorrects aux mauvaises périodes — les erreurs les plus fréquentes repérées lors d'audits de PME canadiennes.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>5 min de lecture</span>
                            </div>
                        </a>

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-4.jpg" alt="Travailleurs autonomes : comment structurer votre rémunération pour optimiser l'impôt" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Paie</span>
                                    <span class="text-xs text-slate-400">20 mai 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">Travailleurs autonomes : comment structurer votre rémunération pour optimiser l'impôt</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">Salaire, dividendes ou combinaison — ce que les données de nos utilisateurs révèlent sur la stratégie optimale.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>10 min de lecture</span>
                            </div>
                        </a>

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-5.jpg" alt="Nouveaux exports : vos états financiers dans Excel et Google Sheets" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-blue-50 text-blue-700">Mise à jour produit</span>
                                    <span class="text-xs text-slate-400">12 mai 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">Nouveaux exports : vos états financiers dans Excel et Google Sheets</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">Exportez bilan, résultats et flux de trésorerie directement vers vos tableurs favoris en un clic.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>3 min de lecture</span>
                            </div>
                        </a>

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-6.jpg" alt="Embaucher votre premier employé à temps plein : guide étape par étape" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-violet-50 text-violet-700">Croissance</span>
                                    <span class="text-xs text-slate-400">5 mai 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">Embaucher votre premier employé à temps plein : guide étape par étape</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">De l'immatriculation à la première paie — ce que vous devez configurer avant de signer le contrat.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>12 min de lecture</span>
                            </div>
                        </a>

                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-2xl overflow-hidden transition-all duration-200 hover:shadow-md">
                            <div class="aspect-video overflow-hidden">
                                <img src="img/landingpage-7.jpg" alt="Comment 60sec-AI protège vos données financières" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
                            </div>
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 text-slate-700">Technologie</span>
                                    <span class="text-xs text-slate-400">28 avril 2026</span>
                                </div>
                                <h3 class="font-bold text-slate-900 mb-2 leading-snug group-hover:text-blue-700 transition-colors text-sm">Comment 60sec-AI protège vos données financières</h3>
                                <p class="text-xs text-slate-500 leading-relaxed mb-4">Chiffrement de bout en bout, conformité SOC 2 Type II et sauvegardes géo-redondantes — tour d'horizon de notre infrastructure.</p>
                                <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="clock" class="w-3 h-3"></i>7 min de lecture</span>
                            </div>
                        </a>

                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="communaute">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="users" class="w-4 h-4"></i>Communauté
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Rejoignez la communauté 60sec-AI</h1>
                        <p class="text-lg text-slate-600 leading-relaxed mb-8">Plus de 12 000 entrepreneurs et professionnels partagent leurs pratiques, posent des questions et s'entraident au quotidien.</p>
                        <div class="flex flex-col sm:flex-row gap-3">
                            <a href="#" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-700/25">Rejoindre le forum<i data-lucide="chevron-right" class="w-4 h-4"></i></a>
                            <a href="#" class="inline-flex items-center gap-2 bg-white border border-slate-200 hover:border-slate-300 text-slate-700 font-semibold px-6 py-3 rounded-xl transition-all duration-200">Discord — Canal #fr-canada</a>
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-14 bg-white border-b border-slate-100">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
                        <div>
                            <p class="text-3xl font-black text-blue-700 mb-1">12 400+</p>
                            <p class="text-sm text-slate-500">Membres actifs</p>
                        </div>
                        <div>
                            <p class="text-3xl font-black text-blue-700 mb-1">5 907</p>
                            <p class="text-sm text-slate-500">Discussions</p>
                        </div>
                        <div>
                            <p class="text-3xl font-black text-blue-700 mb-1">94%</p>
                            <p class="text-sm text-slate-500">Questions résolues</p>
                        </div>
                        <div>
                            <p class="text-3xl font-black text-blue-700 mb-1">&lt; 2h</p>
                            <p class="text-sm text-slate-500">Temps de réponse moyen</p>
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8">Catégories du forum</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <a href="#" class="group flex items-center gap-5 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 bg-blue-50 text-blue-600">
                                <i data-lucide="zap" class="w-6 h-6"></i>
                            </div>
                            <div class="flex-1">
                                <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-1">Paie &amp; RH</h3>
                                <p class="text-sm text-slate-500">Employés, déductions, T4, remises DAS</p>
                            </div>
                            <div class="text-right flex-shrink-0">
                                <p class="text-lg font-bold text-slate-900">1 284</p>
                                <p class="text-xs text-slate-400">messages</p>
                            </div>
                        </a>
                        <a href="#" class="group flex items-center gap-5 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 bg-emerald-50 text-emerald-600">
                                <i data-lucide="message-square" class="w-6 h-6"></i>
                            </div>
                            <div class="flex-1">
                                <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-1">Comptabilité &amp; Taxes</h3>
                                <p class="text-sm text-slate-500">TPS/TVQ, états financiers, bilan</p>
                            </div>
                            <div class="text-right flex-shrink-0">
                                <p class="text-lg font-bold text-slate-900">978</p>
                                <p class="text-xs text-slate-400">messages</p>
                            </div>
                        </a>
                        <a href="#" class="group flex items-center gap-5 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 bg-amber-50 text-amber-600">
                                <i data-lucide="help-circle" class="w-6 h-6"></i>
                            </div>
                            <div class="flex-1">
                                <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-1">API &amp; Intégrations</h3>
                                <p class="text-sm text-slate-500">SDK, webhooks, connecteurs</p>
                            </div>
                            <div class="text-right flex-shrink-0">
                                <p class="text-lg font-bold text-slate-900">542</p>
                                <p class="text-xs text-slate-400">messages</p>
                            </div>
                        </a>
                        <a href="#" class="group flex items-center gap-5 bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 bg-sky-50 text-sky-600">
                                <i data-lucide="users" class="w-6 h-6"></i>
                            </div>
                            <div class="flex-1">
                                <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-1">Travailleurs autonomes</h3>
                                <p class="text-sm text-slate-500">Revenus, acomptes, incorporation</p>
                            </div>
                            <div class="text-right flex-shrink-0">
                                <p class="text-lg font-bold text-slate-900">2 103</p>
                                <p class="text-xs text-slate-400">messages</p>
                            </div>
                        </a>
                    </div>
                </div>
            </section>
            <section class="py-12 pb-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8">Discussions récentes</h2>
                    <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
                        <a href="#" class="group flex items-start gap-4 px-6 py-5 hover:bg-slate-50 transition-colors border-b border-slate-100">
                            <div class="flex-shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center border-emerald-500 bg-emerald-50">
                                <div class="w-2 h-2 rounded-full bg-emerald-500"></div>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="font-semibold text-slate-900 group-hover:text-blue-700 transition-colors text-sm leading-snug mb-1">Comment configurer une paie bi-mensuelle avec congés variables?</p>
                                <div class="flex items-center gap-3 text-xs text-slate-400">
                                    <span>Martin L.</span><span>·</span><span>Il y a 2h</span><span class="text-emerald-600 font-medium">Résolu</span>
                                </div>
                            </div>
                            <div class="flex-shrink-0 flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                                <i data-lucide="message-square" class="w-3 h-3"></i>12
                            </div>
                        </a>
                        <a href="#" class="group flex items-start gap-4 px-6 py-5 hover:bg-slate-50 transition-colors border-b border-slate-100">
                            <div class="flex-shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center border-slate-300"></div>
                            <div class="flex-1 min-w-0">
                                <p class="font-semibold text-slate-900 group-hover:text-blue-700 transition-colors text-sm leading-snug mb-1">Remise TPS/TVQ : fréquence trimestrielle vs mensuelle — quand changer?</p>
                                <div class="flex items-center gap-3 text-xs text-slate-400">
                                    <span>Sophie T.</span><span>·</span><span>Il y a 5h</span>
                                </div>
                            </div>
                            <div class="flex-shrink-0 flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                                <i data-lucide="message-square" class="w-3 h-3"></i>8
                            </div>
                        </a>
                        <a href="#" class="group flex items-start gap-4 px-6 py-5 hover:bg-slate-50 transition-colors border-b border-slate-100">
                            <div class="flex-shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center border-emerald-500 bg-emerald-50">
                                <div class="w-2 h-2 rounded-full bg-emerald-500"></div>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="font-semibold text-slate-900 group-hover:text-blue-700 transition-colors text-sm leading-snug mb-1">Connexion Sage 50 — erreur d'authentification après mise à jour</p>
                                <div class="flex items-center gap-3 text-xs text-slate-400">
                                    <span>Pierre G.</span><span>·</span><span>Il y a 1j</span><span class="text-emerald-600 font-medium">Résolu</span>
                                </div>
                            </div>
                            <div class="flex-shrink-0 flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                                <i data-lucide="message-square" class="w-3 h-3"></i>6
                            </div>
                        </a>
                        <a href="#" class="group flex items-start gap-4 px-6 py-5 hover:bg-slate-50 transition-colors border-b border-slate-100">
                            <div class="flex-shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center border-emerald-500 bg-emerald-50">
                                <div class="w-2 h-2 rounded-full bg-emerald-500"></div>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="font-semibold text-slate-900 group-hover:text-blue-700 transition-colors text-sm leading-snug mb-1">Calcul automatique des vacances (4% vs 6%) — comment le définir par employé?</p>
                                <div class="flex items-center gap-3 text-xs text-slate-400">
                                    <span>Julie M.</span><span>·</span><span>Il y a 2j</span><span class="text-emerald-600 font-medium">Résolu</span>
                                </div>
                            </div>
                            <div class="flex-shrink-0 flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                                <i data-lucide="message-square" class="w-3 h-3"></i>15
                            </div>
                        </a>
                        <a href="#" class="group flex items-start gap-4 px-6 py-5 hover:bg-slate-50 transition-colors">
                            <div class="flex-shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center border-slate-300"></div>
                            <div class="flex-1 min-w-0">
                                <p class="font-semibold text-slate-900 group-hover:text-blue-700 transition-colors text-sm leading-snug mb-1">Export vers QuickBooks — les catégories de dépenses ne se synchronisent pas</p>
                                <div class="flex items-center gap-3 text-xs text-slate-400">
                                    <span>André B.</span><span>·</span><span>Il y a 3j</span>
                                </div>
                            </div>
                            <div class="flex-shrink-0 flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                                <i data-lucide="message-square" class="w-3 h-3"></i>4
                            </div>
                        </a>
                    </div>
                </div>
            </section>
            <section class="py-20 bg-white">
                <div class="max-w-3xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8 flex items-center gap-2">
                        <i data-lucide="help-circle" class="w-6 h-6 text-blue-600"></i>Questions fréquentes
                    </h2>
                    <div class="space-y-5">
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-6">
                            <div class="flex items-start gap-3">
                                <i data-lucide="star" class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5"></i>
                                <div>
                                    <p class="font-semibold text-slate-900 mb-2 text-sm">Puis-je importer mes données depuis un autre logiciel de paie?</p>
                                    <p class="text-sm text-slate-600 leading-relaxed">Oui, 60sec-AI supporte l'importation depuis Ceridian Dayforce, Nethris, ADP et les exports CSV standard. L'assistant d'importation vous guide étape par étape.</p>
                                </div>
                            </div>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-6">
                            <div class="flex items-start gap-3">
                                <i data-lucide="star" class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5"></i>
                                <div>
                                    <p class="font-semibold text-slate-900 mb-2 text-sm">Mes données financières sont-elles partagées avec des tiers?</p>
                                    <p class="text-sm text-slate-600 leading-relaxed">Non. Vos données ne sont jamais vendues ou partagées. Elles sont chiffrées, stockées dans des centres de données canadiens et accessibles uniquement par vous.</p>
                                </div>
                            </div>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-6">
                            <div class="flex items-start gap-3">
                                <i data-lucide="star" class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5"></i>
                                <div>
                                    <p class="font-semibold text-slate-900 mb-2 text-sm">Comment fonctionne la remise automatique à l'ARC?</p>
                                    <p class="text-sm text-slate-600 leading-relaxed">60sec-AI calcule vos remises, génère les formulaires requis et les soumet directement via les services gouvernementaux en ligne — vous n'avez qu'à approuver.</p>
                                </div>
                            </div>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-6">
                            <div class="flex items-start gap-3">
                                <i data-lucide="star" class="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5"></i>
                                <div>
                                    <p class="font-semibold text-slate-900 mb-2 text-sm">Que se passe-t-il si je dépasse le nombre d'employés de mon forfait?</p>
                                    <p class="text-sm text-slate-600 leading-relaxed">Vous serez invité à mettre à niveau votre forfait. Aucun service n'est interrompu — vous disposez d'une période de grâce de 30 jours pour ajuster votre abonnement.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="statut">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-16">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                        <i data-lucide="activity" class="w-4 h-4"></i>Statut des systèmes
                    </div>
                    <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
                        <div>
                            <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-3 leading-tight">État des services</h1>
                            <p class="text-slate-600">Dernière vérification : il y a moins d'une minute</p>
                        </div>
                        <div class="flex items-center gap-3 bg-emerald-50 border border-emerald-200 text-emerald-700 px-6 py-4 rounded-2xl">
                            <i data-lucide="check-circle" class="w-6 h-6 text-emerald-500 fill-emerald-100"></i>
                            <div>
                                <p class="font-bold text-lg leading-none">Tous les systèmes opérationnels</p>
                                <p class="text-sm text-emerald-600 mt-0.5">Aucun incident en cours</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-16 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-xl font-bold text-slate-900 mb-6">Composantes du service</h2>
                    <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">API principale</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.98% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Traitement de la paie</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.97% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Remises automatiques</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">100% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Portail employé</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.99% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Tableau de bord web</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.95% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Webhooks &amp; Événements</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.96% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4 border-b border-slate-100">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Exportation de données</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">99.93% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                        <div class="flex items-center gap-4 px-6 py-4">
                            <div class="flex items-center gap-2.5 flex-1">
                                <div class="w-2.5 h-2.5 rounded-full flex-shrink-0 bg-emerald-500 animate-pulse"></div>
                                <span class="font-medium text-slate-900 text-sm">Authentification</span>
                            </div>
                            <span class="text-xs text-slate-500 font-mono">100% disponibilité (90j)</span>
                            <span class="text-xs font-semibold px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700">Opérationnel</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-12 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-xl font-bold text-slate-900 mb-8">Disponibilité mensuelle — 2026</h2>
                    <div class="bg-white border border-slate-200 rounded-2xl p-6 lg:p-8">
                        <div class="flex items-end gap-4 h-32">
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">100%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:80px"></div>
                                <span class="text-xs text-slate-500">Jan</span>
                            </div>
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">99.97%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:79.976px"></div>
                                <span class="text-xs text-slate-500">Fév</span>
                            </div>
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">100%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:80px"></div>
                                <span class="text-xs text-slate-500">Mar</span>
                            </div>
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">99.98%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:79.984px"></div>
                                <span class="text-xs text-slate-500">Avr</span>
                            </div>
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">99.95%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:79.96px"></div>
                                <span class="text-xs text-slate-500">Mai</span>
                            </div>
                            <div class="flex-1 flex flex-col items-center gap-2">
                                <span class="text-xs font-mono text-slate-600">100%</span>
                                <div class="w-full rounded-t-md bg-emerald-400" style="height:80px"></div>
                                <span class="text-xs text-slate-500">Juin</span>
                            </div>
                        </div>
                        <div class="mt-6 flex items-center gap-6 text-sm text-slate-600">
                            <div class="flex items-center gap-2">
                                <div class="w-3 h-3 bg-emerald-400 rounded-sm"></div> Disponibilité
                            </div>
                            <span class="font-semibold text-slate-900">Moyenne 2026 : 99.97%</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-xl font-bold text-slate-900 mb-8">Historique des incidents</h2>
                    <div class="space-y-4">
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div>
                                    <div class="flex items-center gap-2 mb-1">
                                        <i data-lucide="alert-triangle" class="w-4 h-4 text-amber-500"></i>
                                        <h3 class="font-bold text-slate-900 text-sm">Latence élevée sur l'API — exportations retardées</h3>
                                    </div>
                                    <p class="text-xs text-slate-500">28 mai 2026</p>
                                </div>
                                <div class="flex items-center gap-3 flex-shrink-0">
                                    <div class="flex items-center gap-1.5 text-xs text-slate-500">
                                        <i data-lucide="clock" class="w-3.5 h-3.5"></i>Durée : 18 min
                                    </div>
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-full">Résolu</span>
                                </div>
                            </div>
                            <p class="text-sm text-slate-600 leading-relaxed">Une mise à jour de routage réseau a provoqué une latence accrue sur les endpoints d'exportation. Résolu à 14h32 HNE.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div>
                                    <div class="flex items-center gap-2 mb-1">
                                        <i data-lucide="alert-triangle" class="w-4 h-4 text-amber-500"></i>
                                        <h3 class="font-bold text-slate-900 text-sm">Maintenance planifiée — mise à jour base de données</h3>
                                    </div>
                                    <p class="text-xs text-slate-500">14 avril 2026</p>
                                </div>
                                <div class="flex items-center gap-3 flex-shrink-0">
                                    <div class="flex items-center gap-1.5 text-xs text-slate-500">
                                        <i data-lucide="clock" class="w-3.5 h-3.5"></i>Durée : 45 min
                                    </div>
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-full">Résolu</span>
                                </div>
                            </div>
                            <p class="text-sm text-slate-600 leading-relaxed">Fenêtre de maintenance planifiée pour la migration vers PostgreSQL 17. Aucune perte de données. Service restauré comme prévu.</p>
                        </div>
                    </div>
                    <div class="mt-12 bg-blue-50 border border-blue-200 rounded-2xl p-6 flex items-start gap-4">
                        <i data-lucide="zap" class="w-6 h-6 text-blue-600 flex-shrink-0 mt-0.5 fill-blue-200"></i>
                        <div>
                            <h3 class="font-bold text-slate-900 mb-1">Abonnez-vous aux alertes</h3>
                            <p class="text-sm text-slate-600 mb-4">Recevez une notification par courriel ou SMS dès qu'un incident affecte un service que vous utilisez.</p>
                            <a href="#" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white text-sm font-semibold px-5 py-2.5 rounded-lg transition-colors">S'abonner aux alertes</a>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="a-propos">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="users" class="w-4 h-4"></i>À propos
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Nous rendons la conformité financière <span class="text-blue-600">accessible à tous</span></h1>
                        <p class="text-lg text-slate-600 leading-relaxed">60sec-AI est né d'une conviction simple : les entrepreneurs canadiens méritent les mêmes outils financiers que les grandes entreprises, sans la complexité ni les coûts prohibitifs.</p>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
                        <div>
                            <h2 class="text-3xl font-bold text-slate-900 mb-5">Notre mission</h2>
                            <p class="text-slate-600 leading-relaxed mb-6">En 2022, Alexandre Dubois et Mariam Koné ont fondé 60sec-AI après avoir observé des milliers de PME et travailleurs autonomes consacrer des dizaines d'heures chaque mois à des tâches administratives qui pourraient être entièrement automatisées.</p>
                            <p class="text-slate-600 leading-relaxed mb-6">Notre plateforme combine intelligence artificielle, données fiscales en temps réel et connexions directes aux agences gouvernementales pour éliminer les erreurs, les pénalités et les nuits blanche avant les remises.</p>
                            <div class="bg-blue-50 border-l-4 border-blue-500 pl-6 py-4 rounded-r-xl">
                                <p class="font-bold text-slate-900 text-lg">"Chaque entrepreneur devrait pouvoir gérer ses finances en 60 secondes."</p>
                                <p class="text-slate-500 text-sm mt-1">— Alexandre Dubois, PDG</p>
                            </div>
                        </div>
                        <div>
                            <img src="img/landingpage-8.jpg" alt="Équipe 60sec-AI" class="w-full h-80 object-cover rounded-2xl shadow-sm">
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Nos valeurs</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="bg-white border border-slate-200 rounded-2xl p-7">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="zap" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="text-lg font-bold text-slate-900 mb-2">Automatisation d'abord</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Chaque tâche répétitive que nous pouvons éliminer libère du temps pour ce qui compte vraiment : faire croître votre entreprise.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-7">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="heart" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="text-lg font-bold text-slate-900 mb-2">Conçu pour les humains</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">La technologie doit s'adapter aux entrepreneurs, pas l'inverse. Simplicité et clarté à chaque écran.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-7">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="target" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="text-lg font-bold text-slate-900 mb-2">Conformité sans compromis</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Les règles fiscales et sociales changent. Notre moteur de conformité s'adapte automatiquement pour vous.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-7">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="trending-up" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="text-lg font-bold text-slate-900 mb-2">Croissance partagée</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Votre succès est notre succès. Nous construisons des outils qui s'adaptent à votre croissance, pas des prix qui la pénalisent.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">L'équipe dirigeante</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <div class="text-center">
                            <img src="img/landingpage-9.jpg" alt="Alexandre Dubois" class="w-24 h-24 rounded-full object-cover mx-auto mb-4 shadow-sm">
                            <h3 class="font-bold text-slate-900">Alexandre Dubois</h3>
                            <p class="text-sm text-blue-600 font-medium mb-3">PDG & Co-fondateur</p>
                            <p class="text-xs text-slate-500 leading-relaxed">Ancien comptable agréé, 12 ans en conseil aux PME québécoises. Il a connu de l'intérieur la douleur des remises manuelles.</p>
                        </div>
                        <div class="text-center">
                            <img src="img/landingpage-10.jpg" alt="Mariam Koné" class="w-24 h-24 rounded-full object-cover mx-auto mb-4 shadow-sm">
                            <h3 class="font-bold text-slate-900">Mariam Koné</h3>
                            <p class="text-sm text-blue-600 font-medium mb-3">CTO & Co-fondatrice</p>
                            <p class="text-xs text-slate-500 leading-relaxed">Ingénieure en IA, ex-Microsoft. Elle a conçu l'architecture du moteur de conformité fiscale en temps réel.</p>
                        </div>
                        <div class="text-center">
                            <img src="img/landingpage-11.jpg" alt="François Tremblay" class="w-24 h-24 rounded-full object-cover mx-auto mb-4 shadow-sm">
                            <h3 class="font-bold text-slate-900">François Tremblay</h3>
                            <p class="text-sm text-blue-600 font-medium mb-3">VP Produit</p>
                            <p class="text-xs text-slate-500 leading-relaxed">Designer UX passionné par la simplification des processus complexes. Ancien responsable produit chez Sage.</p>
                        </div>
                        <div class="text-center">
                            <img src="img/landingpage-12.jpg" alt="Isabelle Lavoie" class="w-24 h-24 rounded-full object-cover mx-auto mb-4 shadow-sm">
                            <h3 class="font-bold text-slate-900">Isabelle Lavoie</h3>
                            <p class="text-sm text-blue-600 font-medium mb-3">VP Conformité & Légal</p>
                            <p class="text-xs text-slate-500 leading-relaxed">Juriste spécialisée en droit fiscal canadien, elle supervise la conformité avec l'ARC, Revenu Québec et les lois provinciales.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Notre parcours</h2>
                    <div class="max-w-2xl mx-auto">
                        <div class="flex gap-5 mb-8 last:mb-0">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 bg-blue-700 rounded-full flex items-center justify-center flex-shrink-0"><span class="text-white text-xs font-bold">22</span></div>
                                <div class="w-0.5 bg-slate-200 flex-1 my-2"></div>
                            </div>
                            <div class="pt-2 pb-6">
                                <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">2022</span>
                                <p class="text-slate-800 font-medium mt-0.5">Fondation de 60sec-AI à Montréal, Québec</p>
                            </div>
                        </div>
                        <div class="flex gap-5 mb-8 last:mb-0">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 bg-blue-700 rounded-full flex items-center justify-center flex-shrink-0"><span class="text-white text-xs font-bold">23</span></div>
                                <div class="w-0.5 bg-slate-200 flex-1 my-2"></div>
                            </div>
                            <div class="pt-2 pb-6">
                                <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">2023</span>
                                <p class="text-slate-800 font-medium mt-0.5">Lancement de la version bêta — 200 entreprises pionnières</p>
                            </div>
                        </div>
                        <div class="flex gap-5 mb-8 last:mb-0">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 bg-blue-700 rounded-full flex items-center justify-center flex-shrink-0"><span class="text-white text-xs font-bold">24</span></div>
                                <div class="w-0.5 bg-slate-200 flex-1 my-2"></div>
                            </div>
                            <div class="pt-2 pb-6">
                                <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">2024</span>
                                <p class="text-slate-800 font-medium mt-0.5">Certification SOC 2 Type II obtenue — 5 000 clients actifs</p>
                            </div>
                        </div>
                        <div class="flex gap-5 mb-8 last:mb-0">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 bg-blue-700 rounded-full flex items-center justify-center flex-shrink-0"><span class="text-white text-xs font-bold">25</span></div>
                                <div class="w-0.5 bg-slate-200 flex-1 my-2"></div>
                            </div>
                            <div class="pt-2 pb-6">
                                <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">2025</span>
                                <p class="text-slate-800 font-medium mt-0.5">Expansion pancanadienne — conformité dans toutes les provinces</p>
                            </div>
                        </div>
                        <div class="flex gap-5 mb-8 last:mb-0">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 bg-blue-700 rounded-full flex items-center justify-center flex-shrink-0"><span class="text-white text-xs font-bold">26</span></div>
                            </div>
                            <div class="pt-2 pb-6">
                                <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">2026</span>
                                <p class="text-slate-800 font-medium mt-0.5">Plus de 12 000 entreprises font confiance à 60sec-AI</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8 text-center">
                    <div class="inline-flex items-center gap-2 text-slate-600 mb-3">
                        <i data-lucide="map-pin" class="w-5 h-5 text-blue-600"></i>
                        <span class="font-medium">Fièrement québécois — servant tout le Canada</span>
                    </div>
                    <p class="text-slate-500 text-sm">Siège social : 1155 boul. René-Lévesque Ouest, Montréal, QC H3B 3T1</p>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="carrieres">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="briefcase" class="w-4 h-4"></i>Carrières
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Bâtissez le futur de la finance pour les PME canadiennes</h1>
                        <p class="text-lg text-slate-600 leading-relaxed mb-8">Nous sommes une équipe passionnée de 68 personnes à Montréal et en télétravail partout au Canada. Ensemble, nous automatisons ce qui devrait l'être pour libérer les entrepreneurs.</p>
                        <div class="flex gap-4 text-center">
                            <div class="bg-white border border-slate-200 rounded-xl px-6 py-4">
                                <p class="text-2xl font-black text-blue-700">68</p>
                                <p class="text-xs text-slate-500 mt-0.5">Membres d'équipe</p>
                            </div>
                            <div class="bg-white border border-slate-200 rounded-xl px-6 py-4">
                                <p class="text-2xl font-black text-blue-700">12</p>
                                <p class="text-xs text-slate-500 mt-0.5">Postes ouverts</p>
                            </div>
                            <div class="bg-white border border-slate-200 rounded-xl px-6 py-4">
                                <p class="text-2xl font-black text-blue-700">4.8/5</p>
                                <p class="text-xs text-slate-500 mt-0.5">Note Glassdoor</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-16 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 h-64 lg:h-80">
                        <img src="img/landingpage-13.jpg" alt="Culture" class="rounded-2xl object-cover w-full h-full lg:row-span-1">
                        <img src="img/landingpage-14.jpg" alt="Équipe" class="rounded-2xl object-cover w-full h-full hidden lg:block">
                        <img src="img/landingpage-15.jpg" alt="Bureau" class="rounded-2xl object-cover w-full h-full hidden lg:block">
                    </div>
                </div>
            </section>
            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-3 text-center">Pourquoi rejoindre 60sec-AI?</h2>
                    <p class="text-slate-600 text-center mb-12">Des avantages conçus pour votre épanouissement à long terme.</p>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="heart" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Santé &amp; bien-être</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Assurance collective complète, compte santé de 1 500 $/an, abonnement gym remboursé.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="trending-up" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Croissance professionnelle</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Budget de formation de 2 500 $/an, conférences, certifications et mentorat interne.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="zap" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Flexibilité totale</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Télétravail flexible, semaine de 4 jours optionnelle, horaires adaptables.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="users" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Culture d'équipe</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Équipe multiculturelle et inclusive, événements d'équipe mensuels, culture de transparence.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="shield" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Sécurité financière</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Salaires compétitifs, options d'achat d'actions, REER collectif avec contribution de l'employeur.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6">
                            <div class="w-11 h-11 bg-blue-50 rounded-xl flex items-center justify-center mb-4"><i data-lucide="map-pin" class="w-5 h-5 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Bureaux modernes</h3>
                            <p class="text-sm text-slate-500 leading-relaxed">Espaces de coworking à Montréal et Toronto, café illimité, salles de jeux et espaces calmes.</p>
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-20 pb-24 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-10">Postes ouverts</h2>
                    <div class="space-y-10">
                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Ingénierie</h3>
                            <div class="space-y-3">
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Développeur·se backend senior — Node.js / PostgreSQL</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal ou télétravail</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Ingénieur·e ML — Modèles de conformité fiscale</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Télétravail (Canada)</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Développeur·se frontend — React / TypeScript</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal ou télétravail</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                            </div>
                        </div>
                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Produit &amp; Design</h3>
                            <div class="space-y-3">
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Designer UX/UI senior — Applications financières</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Gestionnaire de produit — Paie &amp; RH</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal ou Toronto</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                            </div>
                        </div>
                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Ventes &amp; Croissance</h3>
                            <div class="space-y-3">
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Responsable des ventes — PME Québec</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Spécialiste succès client bilingue (FR/EN)</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Télétravail (Canada)</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                            </div>
                        </div>
                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Finances &amp; Conformité</h3>
                            <div class="space-y-3">
                                <a href="#" class="group flex items-center justify-between bg-white border border-slate-200 hover:border-blue-300 rounded-xl px-6 py-4 transition-all duration-200 hover:shadow-sm">
                                    <div>
                                        <h4 class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors">Analyste conformité fiscale — ARC &amp; RQ</h4>
                                        <div class="flex items-center gap-3 mt-1">
                                            <span class="text-xs text-slate-500 flex items-center gap-1"><i data-lucide="map-pin" class="w-3 h-3"></i>Montréal</span>
                                            <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2 py-0.5 rounded-full">Temps plein</span>
                                        </div>
                                    </div>
                                    <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all flex-shrink-0"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                    <div class="mt-12 text-center bg-slate-50 border border-slate-200 rounded-2xl p-8">
                        <h3 class="font-bold text-slate-900 mb-2">Vous ne voyez pas votre poste idéal?</h3>
                        <p class="text-slate-600 text-sm mb-5">Envoyez-nous une candidature spontanée — nous sommes toujours à la recherche de talents exceptionnels.</p>
                        <a data-nav="contact" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200">Candidature spontanée</a>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="partenaires">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="handshake" class="w-4 h-4"></i>Programme Partenaires
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Croissez avec nous. Ensemble.</h1>
                        <p class="text-lg text-slate-600 leading-relaxed mb-8">Rejoignez notre réseau de partenaires — comptables, consultants, intégrateurs — et générez des revenus récurrents en recommandant 60sec-AI à vos clients.</p>
                        <div class="flex items-center gap-6 text-sm text-slate-600">
                            <div class="text-center">
                                <p class="text-2xl font-black text-blue-700">320+</p>
                                <p class="text-xs text-slate-500">Partenaires actifs</p>
                            </div>
                            <div class="text-center">
                                <p class="text-2xl font-black text-blue-700">18%</p>
                                <p class="text-xs text-slate-500">Commission moy.</p>
                            </div>
                            <div class="text-center">
                                <p class="text-2xl font-black text-blue-700">12 M$+</p>
                                <p class="text-xs text-slate-500">Versés aux partenaires</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Comment ça fonctionne</h2>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                        <div class="text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-5">
                                <i data-lucide="users" class="w-7 h-7 text-white"></i>
                            </div>
                            <span class="text-xs font-black text-blue-300 tracking-widest uppercase">01</span>
                            <h3 class="text-lg font-bold text-slate-900 mt-1 mb-2">Inscrivez-vous</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Créez votre compte partenaire gratuitement et obtenez votre lien de référence unique en moins de 2 minutes.</p>
                        </div>
                        <div class="text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-5">
                                <i data-lucide="trending-up" class="w-7 h-7 text-white"></i>
                            </div>
                            <span class="text-xs font-black text-blue-300 tracking-widest uppercase">02</span>
                            <h3 class="text-lg font-bold text-slate-900 mt-1 mb-2">Référez des clients</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Partagez 60sec-AI avec vos clients PME. Suivez chaque conversion dans votre tableau de bord en temps réel.</p>
                        </div>
                        <div class="text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-5">
                                <i data-lucide="dollar-sign" class="w-7 h-7 text-white"></i>
                            </div>
                            <span class="text-xs font-black text-blue-300 tracking-widest uppercase">03</span>
                            <h3 class="text-lg font-bold text-slate-900 mt-1 mb-2">Encaissez</h3>
                            <p class="text-slate-600 text-sm leading-relaxed">Recevez votre commission chaque mois, directement par virement bancaire ou PayPal. Commissions récurrentes à vie.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-3 text-center">Niveaux de partenariat</h2>
                    <p class="text-slate-600 text-center mb-12">Votre niveau évolue automatiquement avec votre volume de référencement.</p>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="bg-white rounded-2xl border-2 border-slate-300 p-7  transition-all duration-200">
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full mb-4 bg-slate-100 text-slate-700">Partenaire Référent</span>
                            <div class="mb-2">
                                <span class="text-4xl font-black text-slate-900">15%</span>
                                <span class="text-slate-500 text-sm ml-1">commission récurrente</span>
                            </div>
                            <p class="text-xs text-slate-500 mb-6">1–5 clients/mois</p>
                            <ul class="space-y-2.5 mb-7">
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Lien de référence unique</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Tableau de bord des conversions</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Paiement mensuel automatique</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Support partenaire par courriel</li>
                            </ul>
                            <a href="#" class="block text-center font-semibold py-3 rounded-xl transition-all duration-200 bg-slate-100 hover:bg-slate-200 text-slate-800">Commencer</a>
                        </div>
                        <div class="bg-white rounded-2xl border-2 border-blue-400 p-7 shadow-lg scale-105 transition-all duration-200">
                            <div class="flex items-center gap-1.5 text-xs font-bold text-blue-600 mb-4"><i data-lucide="star" class="w-4 h-4 fill-blue-600"></i> Le plus populaire</div>
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full mb-4 bg-blue-50 text-blue-700">Partenaire Certifié</span>
                            <div class="mb-2">
                                <span class="text-4xl font-black text-slate-900">20%</span>
                                <span class="text-slate-500 text-sm ml-1">commission récurrente</span>
                            </div>
                            <p class="text-xs text-slate-500 mb-6">6–20 clients/mois</p>
                            <ul class="space-y-2.5 mb-7">
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Tout du niveau Référent</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Badge certifié sur notre site</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Accès aux démos personnalisées</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Co-marketing inclus</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Support prioritaire</li>
                            </ul>
                            <a href="#" class="block text-center font-semibold py-3 rounded-xl transition-all duration-200 bg-blue-700 hover:bg-blue-600 text-white">Commencer</a>
                        </div>
                        <div class="bg-white rounded-2xl border-2 border-amber-400 p-7  transition-all duration-200">
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full mb-4 bg-amber-50 text-amber-700">Partenaire Stratégique</span>
                            <div class="mb-2">
                                <span class="text-4xl font-black text-slate-900">25%+</span>
                                <span class="text-slate-500 text-sm ml-1">commission récurrente</span>
                            </div>
                            <p class="text-xs text-slate-500 mb-6">21+ clients/mois</p>
                            <ul class="space-y-2.5 mb-7">
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Tout du niveau Certifié</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Commission négociée</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Gestionnaire de compte dédié</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Intégration profonde API</li>
                                <li class="flex items-start gap-2 text-sm text-slate-700"><i data-lucide="chevron-right" class="w-4 h-4 text-blue-500 flex-shrink-0 mt-0.5"></i>Programme de formation</li>
                            </ul>
                            <a href="#" class="block text-center font-semibold py-3 rounded-xl transition-all duration-200 bg-slate-100 hover:bg-slate-200 text-slate-800">Commencer</a>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8 text-center">Partenaires institutionnels</h2>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-5 text-center">
                            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3"><i data-lucide="bar-chart-2" class="w-6 h-6 text-blue-600"></i></div>
                            <p class="font-semibold text-slate-900 text-sm">Ordre des CPA du Québec</p>
                            <p class="text-xs text-slate-500 mt-1">Association professionnelle</p>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-5 text-center">
                            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3"><i data-lucide="bar-chart-2" class="w-6 h-6 text-blue-600"></i></div>
                            <p class="font-semibold text-slate-900 text-sm">Fédération des chambres de commerce</p>
                            <p class="text-xs text-slate-500 mt-1">Association d'affaires</p>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-5 text-center">
                            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3"><i data-lucide="bar-chart-2" class="w-6 h-6 text-blue-600"></i></div>
                            <p class="font-semibold text-slate-900 text-sm">Réseau des SADC</p>
                            <p class="text-xs text-slate-500 mt-1">Développement économique</p>
                        </div>
                        <div class="bg-slate-50 border border-slate-200 rounded-xl p-5 text-center">
                            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3"><i data-lucide="bar-chart-2" class="w-6 h-6 text-blue-600"></i></div>
                            <p class="font-semibold text-slate-900 text-sm">Association canadienne de la paie</p>
                            <p class="text-xs text-slate-500 mt-1">Organisation sectorielle</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-slate-50">
                <div class="max-w-3xl mx-auto px-6 lg:px-8 text-center">
                    <h2 class="text-3xl font-bold text-slate-900 mb-4">Prêt à devenir partenaire?</h2>
                    <p class="text-slate-600 mb-8">L'inscription est gratuite et prend moins de 2 minutes. Commencez à générer des revenus récurrents dès aujourd'hui.</p>
                    <a href="#" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-bold px-8 py-4 rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-700/25">Rejoindre le programme<i data-lucide="chevron-right" class="w-5 h-5"></i></a>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="presse">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-8">
                        <div class="max-w-2xl">
                            <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                                <i data-lucide="newspaper" class="w-4 h-4"></i>Salle de presse
                            </div>
                            <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Salle de presse</h1>
                            <p class="text-lg text-slate-600 leading-relaxed">Communiqués officiels, couverture médiatique et ressources pour les journalistes. Pour toute demande d'entrevue, contactez notre équipe relations médias.</p>
                        </div>
                        <div class="flex flex-col sm:flex-row gap-3">
                            <a href="#" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-5 py-3 rounded-xl transition-all duration-200">
                                <i data-lucide="download" class="w-4 h-4"></i>Trousse de presse
                            </a>
                            <a href="/contact" data-nav="contact" class="inline-flex items-center gap-2 bg-white border border-slate-200 hover:border-slate-300 text-slate-700 font-semibold px-5 py-3 rounded-xl transition-all duration-200">
                                <i data-lucide="mail" class="w-4 h-4"></i>Contact médias
                            </a>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-12 bg-white border-b border-slate-100">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
                        <div>
                            <p class="text-2xl lg:text-3xl font-black text-blue-700 mb-1">12 000+</p>
                            <p class="text-sm text-slate-500">Entreprises clientes</p>
                        </div>
                        <div>
                            <p class="text-2xl lg:text-3xl font-black text-blue-700 mb-1">18 M$</p>
                            <p class="text-sm text-slate-500">Levée Series B</p>
                        </div>
                        <div>
                            <p class="text-2xl lg:text-3xl font-black text-blue-700 mb-1">2022</p>
                            <p class="text-sm text-slate-500">Fondée à Montréal</p>
                        </div>
                        <div>
                            <p class="text-2xl lg:text-3xl font-black text-blue-700 mb-1">68</p>
                            <p class="text-sm text-slate-500">Employés</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8">Communiqués de presse</h2>
                    <div class="space-y-5">
                        <a href="#" class="group block bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div class="flex items-center gap-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full">Financement</span>
                                    <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="calendar" class="w-3.5 h-3.5"></i>10 juin 2026</span>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 flex-shrink-0 transition-colors hidden sm:block"></i>
                            </div>
                            <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-2">60sec-AI dépasse les 12 000 entreprises clientes et annonce une levée de 18 M$</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">La plateforme canadienne de gestion financière automatisée franchit un nouveau cap et accélère son expansion avec une ronde de financement Series B menée par Real Ventures.</p>
                        </a>
                        <a href="#" class="group block bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div class="flex items-center gap-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full">Sécurité</span>
                                    <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="calendar" class="w-3.5 h-3.5"></i>15 mai 2026</span>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 flex-shrink-0 transition-colors hidden sm:block"></i>
                            </div>
                            <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-2">60sec-AI obtient la certification SOC 2 Type II et la conformité PIPEDA avancée</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Après un audit rigoureux, 60sec-AI confirme sa conformité aux normes les plus élevées de sécurité et de protection des données pour les entreprises canadiennes.</p>
                        </a>
                        <a href="#" class="group block bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div class="flex items-center gap-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full">Produit</span>
                                    <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="calendar" class="w-3.5 h-3.5"></i>3 avril 2026</span>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 flex-shrink-0 transition-colors hidden sm:block"></i>
                            </div>
                            <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-2">Nouveau: intégration directe avec les systèmes de paie provinciaux du Québec</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Les clients québécois peuvent désormais soumettre leurs relevés 1 et leurs remises à Revenu Québec directement depuis la plateforme, sans aucune démarche manuelle.</p>
                        </a>
                        <a href="#" class="group block bg-white border border-slate-200 hover:border-blue-300 rounded-2xl p-6 transition-all duration-200 hover:shadow-md">
                            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-3">
                                <div class="flex items-center gap-3">
                                    <span class="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full">Prix</span>
                                    <span class="flex items-center gap-1.5 text-xs text-slate-400"><i data-lucide="calendar" class="w-3.5 h-3.5"></i>18 février 2026</span>
                                </div>
                                <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 group-hover:text-blue-600 flex-shrink-0 transition-colors hidden sm:block"></i>
                            </div>
                            <h3 class="font-bold text-slate-900 group-hover:text-blue-700 transition-colors mb-2">60sec-AI remporte le prix PME Innovation 2026 de la Chambre de commerce de Montréal</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">La plateforme est reconnue comme l'innovation la plus impactante pour les petites et moyennes entreprises québécoises lors du gala annuel.</p>
                        </a>
                    </div>
                </div>
            </section>

            <section class="py-16 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-2xl font-bold text-slate-900 mb-8">Couverture médiatique</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 flex items-start gap-4 transition-all duration-200 hover:shadow-sm">
                            <div class="w-12 h-12 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                                <i data-lucide="newspaper" class="w-5 h-5 text-slate-500"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-xs font-bold text-slate-500 mb-1">Les Affaires · Juin 2026</p>
                                <p class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors leading-snug">Cette startup montréalaise veut éliminer la paperasse fiscale pour les PME</p>
                            </div>
                            <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5 group-hover:text-blue-600 transition-colors"></i>
                        </a>
                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 flex items-start gap-4 transition-all duration-200 hover:shadow-sm">
                            <div class="w-12 h-12 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                                <i data-lucide="newspaper" class="w-5 h-5 text-slate-500"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-xs font-bold text-slate-500 mb-1">La Presse · Mai 2026</p>
                                <p class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors leading-snug">60sec-AI : quand l'IA prend en charge vos remises à l'ARC</p>
                            </div>
                            <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5 group-hover:text-blue-600 transition-colors"></i>
                        </a>
                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 flex items-start gap-4 transition-all duration-200 hover:shadow-sm">
                            <div class="w-12 h-12 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                                <i data-lucide="newspaper" class="w-5 h-5 text-slate-500"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-xs font-bold text-slate-500 mb-1">BetaKit · Juin 2026</p>
                                <p class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors leading-snug">Montreal fintech 60sec-AI raises $18M to automate payroll compliance across Canada</p>
                            </div>
                            <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5 group-hover:text-blue-600 transition-colors"></i>
                        </a>
                        <a href="#" class="group bg-white border border-slate-200 hover:border-blue-300 rounded-xl p-5 flex items-start gap-4 transition-all duration-200 hover:shadow-sm">
                            <div class="w-12 h-12 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                                <i data-lucide="newspaper" class="w-5 h-5 text-slate-500"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-xs font-bold text-slate-500 mb-1">Devoir · Avril 2026</p>
                                <p class="font-semibold text-slate-900 text-sm group-hover:text-blue-700 transition-colors leading-snug">Une solution technologique québécoise pour simplifier la comptabilité des indépendants</p>
                            </div>
                            <i data-lucide="chevron-right" class="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5 group-hover:text-blue-600 transition-colors"></i>
                        </a>
                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-white">
                <div class="max-w-xl mx-auto px-6 lg:px-8 text-center">
                    <div class="w-14 h-14 bg-blue-50 rounded-2xl flex items-center justify-center mx-auto mb-5">
                        <i data-lucide="mail" class="w-7 h-7 text-blue-600"></i>
                    </div>
                    <h2 class="text-2xl font-bold text-slate-900 mb-3">Contact relations médias</h2>
                    <p class="text-slate-600 mb-6 text-sm leading-relaxed">Pour les demandes d'entrevues, de photos ou d'informations supplémentaires, contactez notre équipe dédiée.</p>
                    <a href="mailto:presse@60sec-ai.ca" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200">
                        <i data-lucide="mail" class="w-4 h-4"></i>presse@60sec-ai.ca
                    </a>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="contact">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-2xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6"><i data-lucide="mail" class="w-4 h-4"></i>Contact</div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Nous sommes là pour vous aider</h1>
                        <p class="text-lg text-slate-600 leading-relaxed">Une question sur la paie, une remise qui approche, ou un problème technique? Notre équipe de spécialistes est disponible 7 jours sur 7.</p>
                    </div>
                </div>
            </section>
            <section class="py-16 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center mb-5 bg-blue-50 text-blue-600"><i data-lucide="message-square" class="w-6 h-6"></i></div>
                            <h3 class="font-bold text-slate-900 mb-1">Chat en direct</h3>
                            <p class="text-sm text-slate-600 mb-1">Réponse en moins de 3 minutes</p>
                            <div class="flex items-center gap-1.5 text-xs text-slate-400 mb-5"><i data-lucide="clock" class="w-3.5 h-3.5"></i>Lun–Ven, 8h–20h HNE</div>
                            <a href="#" class="inline-flex items-center gap-1.5 text-sm font-semibold text-blue-700 hover:text-blue-600 transition-colors">Ouvrir le chat<i data-lucide="chevron-right" class="w-3.5 h-3.5"></i></a>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center mb-5 bg-emerald-50 text-emerald-600"><i data-lucide="mail" class="w-6 h-6"></i></div>
                            <h3 class="font-bold text-slate-900 mb-1">Courriel support</h3>
                            <p class="text-sm text-slate-600 mb-1">Réponse garantie sous 4h</p>
                            <div class="flex items-center gap-1.5 text-xs text-slate-400 mb-5"><i data-lucide="clock" class="w-3.5 h-3.5"></i>7 jours sur 7</div>
                            <a href="#" class="inline-flex items-center gap-1.5 text-sm font-semibold text-blue-700 hover:text-blue-600 transition-colors">support@60sec-ai.ca<i data-lucide="chevron-right" class="w-3.5 h-3.5"></i></a>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 rounded-xl flex items-center justify-center mb-5 bg-amber-50 text-amber-600"><i data-lucide="phone" class="w-6 h-6"></i></div>
                            <h3 class="font-bold text-slate-900 mb-1">Téléphone</h3>
                            <p class="text-sm text-slate-600 mb-1">Pour les urgences comptables</p>
                            <div class="flex items-center gap-1.5 text-xs text-slate-400 mb-5"><i data-lucide="clock" class="w-3.5 h-3.5"></i>Lun–Ven, 9h–17h HNE</div>
                            <a href="#" class="inline-flex items-center gap-1.5 text-sm font-semibold text-blue-700 hover:text-blue-600 transition-colors">+1 (514) 900-6060<i data-lucide="chevron-right" class="w-3.5 h-3.5"></i></a>
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-16 pb-24 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="grid grid-cols-1 lg:grid-cols-3 gap-12">
                        <div class="lg:col-span-2">
                            <h2 class="text-2xl font-bold text-slate-900 mb-7">Envoyer un message</h2>
                            <form class="space-y-5">
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                                    <div>
                                        <label class="block text-sm font-semibold text-slate-700 mb-2">Nom complet</label>
                                        <input type="text" required placeholder="Jean Tremblay" value="" class="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm">
                                    </div>
                                    <div>
                                        <label class="block text-sm font-semibold text-slate-700 mb-2">Adresse courriel</label>
                                        <input type="email" required placeholder="vous@entreprise.ca" value="" class="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm">
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Sujet</label>
                                    <select class="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm appearance-none">
                                        <option value="">Sélectionner un sujet…</option>
                                        <option>Support technique</option>
                                        <option>Question de facturation</option>
                                        <option>Conformité / remises</option>
                                        <option>Partenariats</option>
                                        <option>Autre</option>
                                    </select>
                                </div>
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Message</label>
<textarea required rows="5" placeholder="Décrivez votre question ou problème en détail…" class="w-full px-4 py-3 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-sm resize-none"></textarea>
                                </div>
                                <button type="submit" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-8 py-3.5 rounded-xl transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-700/25">Envoyer le message<i data-lucide="chevron-right" class="w-4 h-4"></i></button>
                            </form>
                        </div>
                        <div class="space-y-8">
                            <div>
                                <h3 class="font-bold text-slate-900 mb-5 flex items-center gap-2"><i data-lucide="map-pin" class="w-4 h-4 text-blue-600"></i>Nos bureaux</h3>
                                <div class="space-y-4">
                                    <div class="bg-white border border-slate-200 rounded-xl p-4">
                                        <p class="font-semibold text-slate-900 text-sm mb-1">Montréal (siège)</p>
                                        <p class="text-xs text-slate-500 whitespace-pre-line leading-relaxed">
                                            1155 boul. René-Lévesque O., Suite 2000
                                            Montréal, QC  H3B 3T1
                                        </p>
                                    </div>
                                    <div class="bg-white border border-slate-200 rounded-xl p-4">
                                        <p class="font-semibold text-slate-900 text-sm mb-1">Toronto</p>
                                        <p class="text-xs text-slate-500 whitespace-pre-line leading-relaxed">
                                            100 King Street West, Suite 5600
                                            Toronto, ON  M5X 1C9
                                        </p>
                                    </div>
                                </div>
                            </div>
                            <div>
                                <h3 class="font-bold text-slate-900 mb-5 flex items-center gap-2"><i data-lucide="help-circle" class="w-4 h-4 text-blue-600"></i>Questions fréquentes</h3>
                                <div class="space-y-4">
                                    <div class="bg-white border border-slate-200 rounded-xl p-4">
                                        <p class="font-semibold text-slate-900 text-xs mb-1.5">Quel est votre délai de réponse moyen?</p>
                                        <p class="text-xs text-slate-500 leading-relaxed">Chat : moins de 3 min | Courriel : moins de 4h | Téléphone : immédiat aux heures ouvrables.</p>
                                    </div>
                                    <div class="bg-white border border-slate-200 rounded-xl p-4">
                                        <p class="font-semibold text-slate-900 text-xs mb-1.5">Offrez-vous du support en anglais?</p>
                                        <p class="text-xs text-slate-500 leading-relaxed">Oui, notre équipe est bilingue (FR/EN). Les forfaits Compagnie incluent un support prioritaire bilingue.</p>
                                    </div>
                                    <div class="bg-white border border-slate-200 rounded-xl p-4">
                                        <p class="font-semibold text-slate-900 text-xs mb-1.5">Comment signaler un problème critique (remise manquée)?</p>
                                        <p class="text-xs text-slate-500 leading-relaxed">Utilisez le téléphone ou le chat en direct. Indiquez «URGENT» — un spécialiste prend en charge sous 10 minutes.</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="conditions">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-16">
                <div class="max-w-4xl mx-auto px-6 lg:px-8">
                    <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                        <i data-lucide="scale" class="w-4 h-4"></i>Légal
                    </div>
                    <h1 class="text-4xl font-bold text-slate-950 tracking-tight mb-4">Conditions d'utilisation</h1>
                    <div class="flex items-center gap-2 text-sm text-slate-500">
                        <i data-lucide="calendar" class="w-4 h-4"></i>
                        <span>Dernière mise à jour : 1er juin 2026</span>
                    </div>
                </div>
            </section>
            <section class="py-12 pb-24 bg-white">
                <div class="max-w-4xl mx-auto px-6 lg:px-8">
                    <div class="bg-amber-50 border border-amber-200 rounded-xl p-5 mb-10">
                        <p class="text-sm text-amber-800 leading-relaxed"><strong>Résumé simplifié :</strong> En utilisant 60sec-AI, vous acceptez d'utiliser nos services légalement, de maintenir la sécurité de votre compte et de vérifier vos remises fiscales. Nous fournissons les outils; vous demeurez responsable de l'exactitude de vos données.</p>
                    </div>
                    <div class="space-y-10">
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">1. Acceptation des conditions</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                En accédant à la plateforme 60sec-AI ou en l'utilisant, vous acceptez d'être lié par les présentes Conditions d'utilisation, ainsi que par notre Politique de confidentialité et toutes les politiques complémentaires intégrées par renvoi.

                                Si vous utilisez 60sec-AI au nom d'une entreprise, vous déclarez que vous êtes autorisé à engager cette entité aux présentes conditions.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">2. Description des services</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                60sec-AI Inc. (« Société », « nous ») exploite une plateforme SaaS de gestion financière automatisée comprenant, sans s'y limiter : traitement de la paie, calcul et remise automatique des déductions à la source, gestion de la TPS/TVH/TVQ, génération d'états financiers, et conformité réglementaire.

                                Les services sont fournis « tels quels » et peuvent être modifiés, suspendus ou interrompus avec un préavis raisonnable.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">3. Compte et responsabilités</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Vous êtes responsable de :
                                • Maintenir la confidentialité de vos identifiants de connexion
                                • Toutes les activités réalisées sous votre compte
                                • L'exactitude des données financières saisies dans la plateforme
                                • Vérifier l'exactitude de toute remise générée automatiquement avant sa soumission aux autorités fiscales

                                Vous devez nous notifier immédiatement de tout accès non autorisé à votre compte.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">4. Utilisation acceptable</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Vous vous engagez à ne pas :
                                • Utiliser les services à des fins illégales ou contraires aux lois canadiennes ou provinciales
                                • Tenter d'accéder aux systèmes sans autorisation
                                • Reproduire, vendre ou revendre les services sans accord écrit préalable
                                • Soumettre des informations fausses, inexactes ou frauduleuses
                                • Perturber ou interférer avec le bon fonctionnement de la plateforme
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">5. Tarification et facturation</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Les abonnements sont facturés mensuellement ou annuellement selon le forfait sélectionné. Les prix sont en dollars canadiens (CAD) et excluent les taxes applicables.

                                Le renouvellement est automatique sauf résiliation explicite. Aucun remboursement n'est accordé pour les périodes partielles, sauf disposition contraire prévue par la loi.

                                Nous nous réservons le droit de modifier les tarifs avec un préavis de 30 jours par courriel.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">6. Propriété intellectuelle</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                La plateforme, y compris son code source, ses algorithmes, son interface, sa documentation et tous les éléments qui la composent, est la propriété exclusive de 60sec-AI Inc. et est protégée par les lois canadiennes et internationales sur la propriété intellectuelle.

                                Vous conservez la propriété de vos données financières. Vous nous accordez une licence limitée pour les traiter aux fins de fourniture des services.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">7. Limitation de responsabilité</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Dans toute la mesure permise par la loi applicable, 60sec-AI Inc. ne sera pas responsable des dommages indirects, accessoires, spéciaux ou consécutifs, y compris les pénalités fiscales résultant d'erreurs dans les données que vous avez fournies.

                                Notre responsabilité totale envers vous, pour toute réclamation liée aux services, est limitée aux montants que vous avez payés au cours des 12 derniers mois précédant l'incident.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">8. Résiliation</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Vous pouvez résilier votre compte à tout moment depuis les paramètres de votre compte. La résiliation prend effet à la fin de la période de facturation en cours.

                                Nous pouvons suspendre ou résilier votre accès immédiatement en cas de violation des présentes conditions, d'activité frauduleuse ou de non-paiement.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">9. Droit applicable</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">Les présentes conditions sont régies par les lois de la province de Québec et les lois fédérales du Canada qui y sont applicables. Tout litige sera soumis à la juridiction exclusive des tribunaux du district judiciaire de Montréal.</p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">10. Contact</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Pour toute question relative aux présentes conditions, contactez :
                                60sec-AI Inc.
                                1155 boul. René-Lévesque Ouest, Suite 2000
                                Montréal, QC  H3B 3T1
                                legal@60sec-ai.ca
                            </p>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="confidentialite">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-16">
                <div class="max-w-4xl mx-auto px-6 lg:px-8">
                    <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                        <i data-lucide="lock" class="w-4 h-4"></i>Légal
                    </div>
                    <h1 class="text-4xl font-bold text-slate-950 tracking-tight mb-4">Politique de confidentialité</h1>
                    <div class="flex items-center gap-4 text-sm text-slate-500">
                        <div class="flex items-center gap-1.5">
                            <i data-lucide="calendar" class="w-4 h-4"></i>Dernière mise à jour : 1er juin 2026
                        </div>
                        <div class="flex items-center gap-1.5">
                            <i data-lucide="shield" class="w-4 h-4 text-emerald-500"></i>Conforme Loi 25 &amp; LPRPDE
                        </div>
                    </div>
                </div>
            </section>
            <section class="py-12 pb-24 bg-white">
                <div class="max-w-4xl mx-auto px-6 lg:px-8">
                    <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-5 mb-10">
                        <p class="text-sm text-emerald-800 leading-relaxed"><strong>En bref :</strong> Vos données financières vous appartiennent. Nous les utilisons uniquement pour fournir le service et respecter nos obligations légales. Nous ne vendons jamais vos données. Tout est stocké au Canada et chiffré.</p>
                    </div>
                    <div class="space-y-10">
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">1. Introduction</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                60sec-AI Inc. (« nous », « notre ») s'engage à protéger la vie privée des utilisateurs de sa plateforme. La présente Politique de confidentialité décrit la nature des renseignements personnels que nous recueillons, la façon dont nous les utilisons, les divulguons, les protégeons et les conservons.

                                Cette politique est conforme à la Loi sur la protection des renseignements personnels dans le secteur privé (Loi 25 du Québec), à la LPRPDE (loi fédérale), et au Règlement général sur la protection des données (RGPD) pour nos clients de l'Union européenne.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">2. Renseignements recueillis</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous recueillons les catégories de renseignements suivantes :

                                Renseignements d'identification : nom, prénom, adresse courriel, numéro de téléphone, adresse postale.

                                Renseignements financiers : données de paie, numéros d'entreprise (NE), numéros d'assurance sociale des employés (traités de façon chiffrée), informations bancaires pour les remises automatiques.

                                Données d'utilisation : journaux de connexion, adresses IP, données de navigation dans la plateforme, préférences d'interface.

                                Communications : messages échangés avec notre support et historique des tickets.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">3. Utilisation des renseignements</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous utilisons vos renseignements pour :
                                • Fournir, maintenir et améliorer nos services
                                • Traiter les remises automatiques aux autorités fiscales (ARC, Revenu Québec)
                                • Vous envoyer les notifications de service et les confirmations de remises
                                • Assurer la sécurité et prévenir la fraude
                                • Respecter nos obligations légales et réglementaires
                                • Améliorer nos algorithmes de conformité fiscale (données agrégées et anonymisées)

                                Nous ne vendons, ne louons ni ne partageons vos renseignements personnels à des fins commerciales.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">4. Partage de renseignements</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous pouvons partager vos renseignements avec :

                                Autorités gouvernementales : Agence du revenu du Canada (ARC), Revenu Québec, Emploi et Développement social Canada — uniquement dans le cadre des remises et obligations légales.

                                Sous-traitants : fournisseurs d'infrastructure cloud (hébergés au Canada), processeurs de paiement et fournisseurs d'authentification liés par des accords de confidentialité stricts.

                                Situations légales : si requis par une ordonnance judiciaire valide ou une obligation légale.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">5. Conservation et suppression</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous conservons vos renseignements pendant la durée de votre abonnement actif et pour une période supplémentaire de 7 ans conformément aux obligations fiscales canadiennes.

                                À votre demande écrite, nous supprimerons vos renseignements personnels non requis légalement dans un délai de 30 jours, conformément à la Loi 25.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">6. Sécurité des données</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous appliquons des mesures de sécurité de niveau entreprise :
                                • Chiffrement AES-256 des données au repos
                                • Chiffrement TLS 1.3 en transit
                                • Authentification à deux facteurs obligatoire pour les comptes administrateurs
                                • Audits de sécurité trimestriels par des tiers certifiés
                                • Conformité SOC 2 Type II
                                • Centres de données situés exclusivement au Canada

                                En cas d'incident de sécurité, nous vous notifierons dans les 72 heures conformément à la Loi 25.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">7. Vos droits</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Conformément à la Loi 25 et à la LPRPDE, vous avez le droit de :
                                • Accéder à vos renseignements personnels
                                • Corriger les renseignements inexacts
                                • Retirer votre consentement (avec effet pour l'avenir)
                                • Demander la suppression (sous réserve des obligations légales)
                                • Obtenir une copie portable de vos données
                                • Déposer une plainte auprès de la Commission d'accès à l'information du Québec

                                Pour exercer ces droits : privacy@60sec-ai.ca
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">8. Témoins (cookies)</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Nous utilisons des témoins essentiels (nécessaires au fonctionnement), analytiques (anonymisés via Plausible Analytics, hébergé au Canada) et de préférences.

                                Vous pouvez gérer vos préférences de témoins via les paramètres de votre navigateur. Le refus des témoins non essentiels n'affecte pas la fonctionnalité principale de la plateforme.
                            </p>
                        </div>
                        <div class="border-b border-slate-100 pb-10 last:border-0">
                            <h2 class="text-lg font-bold text-slate-900 mb-4">9. Contact — Responsable de la protection des renseignements</h2>
                            <p class="text-slate-600 text-sm leading-relaxed whitespace-pre-line">
                                Pour toute question relative à cette politique ou pour exercer vos droits :

                                Responsable de la protection des renseignements personnels
                                60sec-AI Inc.
                                1155 boul. René-Lévesque Ouest, Suite 2000
                                Montréal, QC  H3B 3T1
                                privacy@60sec-ai.ca
                                +1 (514) 900-6060
                            </p>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="securite">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="shield" class="w-4 h-4"></i>Sécurité
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Votre sécurité est notre priorité absolue</h1>
                        <p class="text-lg text-slate-600 leading-relaxed">Vos données financières sont parmi les plus sensibles qui soient. Voici comment nous les protégeons à chaque niveau de notre infrastructure.</p>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Les piliers de notre sécurité</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="lock" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Chiffrement de bout en bout</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Toutes vos données financières sont chiffrées avec AES-256 au repos et TLS 1.3 en transit. Les NAS des employés sont tokenisés — jamais stockés en clair.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="server" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Infrastructure canadienne</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Tous vos données résident dans des centres de données certifiés SOC 2 situés au Canada (Toronto et Montréal). Aucune donnée ne quitte le Canada.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="shield" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Certification SOC 2 Type II</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Nous avons obtenu la certification SOC 2 Type II après audit indépendant. Nos contrôles de sécurité, disponibilité et confidentialité sont vérifiés trimestriellement.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="eye" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Journalisation &amp; Audit</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Chaque action critique est journalisée avec horodatage, IP et identité. Les journaux sont immuables et conservés 2 ans pour permettre les audits de conformité.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="alert-triangle" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Gestion des incidents</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Protocole d'intervention en moins de 2h pour tout incident P1. Notification aux clients affectés sous 72h conformément à la Loi 25 du Québec.</p>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 hover:shadow-md transition-all duration-200">
                            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center mb-5"><i data-lucide="check-circle" class="w-6 h-6 text-blue-600"></i></div>
                            <h3 class="font-bold text-slate-900 mb-2">Tests de pénétration</h3>
                            <p class="text-sm text-slate-600 leading-relaxed">Tests de pénétration externes réalisés semestriellement par des firmes spécialisées indépendantes. Les résultats font l'objet d'un plan de remédiation documenté.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Certifications &amp; conformité</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-4"><i data-lucide="shield" class="w-7 h-7 text-white"></i></div>
                            <h3 class="font-bold text-slate-900 text-sm mb-1">SOC 2 Type II</h3>
                            <p class="text-xs text-slate-500 mb-1">AICPA</p>
                            <p class="text-xs text-slate-400 mb-3">Obtenu : 2024</p>
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full bg-emerald-50 text-emerald-700">Actif</span>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-4"><i data-lucide="shield" class="w-7 h-7 text-white"></i></div>
                            <h3 class="font-bold text-slate-900 text-sm mb-1">Conformité PIPEDA / Loi 25</h3>
                            <p class="text-xs text-slate-500 mb-1">CAI Québec</p>
                            <p class="text-xs text-slate-400 mb-3">Obtenu : 2023</p>
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full bg-emerald-50 text-emerald-700">Actif</span>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-4"><i data-lucide="shield" class="w-7 h-7 text-white"></i></div>
                            <h3 class="font-bold text-slate-900 text-sm mb-1">PCI DSS Level 2</h3>
                            <p class="text-xs text-slate-500 mb-1">PCI Security Standards Council</p>
                            <p class="text-xs text-slate-400 mb-3">Obtenu : 2024</p>
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full bg-emerald-50 text-emerald-700">Actif</span>
                        </div>
                        <div class="bg-white border border-slate-200 rounded-2xl p-6 text-center">
                            <div class="w-14 h-14 bg-blue-700 rounded-2xl flex items-center justify-center mx-auto mb-4"><i data-lucide="shield" class="w-7 h-7 text-white"></i></div>
                            <h3 class="font-bold text-slate-900 text-sm mb-1">ISO 27001 (en cours)</h3>
                            <p class="text-xs text-slate-500 mb-1">BSI Group</p>
                            <p class="text-xs text-slate-400 mb-3">Obtenu : 2026</p>
                            <span class="inline-block text-xs font-semibold px-3 py-1 rounded-full bg-amber-50 text-amber-700">En processus</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-3">Contrôles d'accès</h2>
                    <p class="text-slate-600 mb-10">Mesures de contrôle d'accès appliquées à l'ensemble de la plateforme.</p>
                    <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                        <div class="grid grid-cols-3 px-6 py-3 bg-slate-50 border-b border-slate-100">
                            <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Contrôle</span>
                            <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Portée</span>
                            <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Détails</span>
                        </div>
                        <div class="grid grid-cols-3 px-6 py-4 gap-4 border-b border-slate-100">
                            <span class="font-semibold text-slate-900 text-sm">Authentification à deux facteurs (2FA)</span>
                            <span class="text-sm text-slate-600">Obligatoire pour admins</span>
                            <span class="text-sm text-slate-500">TOTP ou clé matérielle FIDO2</span>
                        </div>
                        <div class="grid grid-cols-3 px-6 py-4 gap-4 border-b border-slate-100">
                            <span class="font-semibold text-slate-900 text-sm">Accès par rôle (RBAC)</span>
                            <span class="text-sm text-slate-600">Tous les comptes</span>
                            <span class="text-sm text-slate-500">Permissions granulaires par module</span>
                        </div>
                        <div class="grid grid-cols-3 px-6 py-4 gap-4 border-b border-slate-100">
                            <span class="font-semibold text-slate-900 text-sm">SSO SAML 2.0 / OIDC</span>
                            <span class="text-sm text-slate-600">Forfaits Entreprise</span>
                            <span class="text-sm text-slate-500">Intégration Okta, Azure AD, Google Workspace</span>
                        </div>
                        <div class="grid grid-cols-3 px-6 py-4 gap-4 border-b border-slate-100">
                            <span class="font-semibold text-slate-900 text-sm">Sessions sécurisées</span>
                            <span class="text-sm text-slate-600">Tous les comptes</span>
                            <span class="text-sm text-slate-500">Expiration automatique après 8h d'inactivité</span>
                        </div>
                        <div class="grid grid-cols-3 px-6 py-4 gap-4">
                            <span class="font-semibold text-slate-900 text-sm">Liste blanche IP</span>
                            <span class="text-sm text-slate-600">Forfaits Entreprise</span>
                            <span class="text-sm text-slate-500">Restriction d'accès par plage IP</span>
                        </div>
                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-slate-50">
                <div class="max-w-3xl mx-auto px-6 lg:px-8 text-center">
                    <div class="w-14 h-14 bg-blue-50 rounded-2xl flex items-center justify-center mx-auto mb-5"><i data-lucide="alert-triangle" class="w-7 h-7 text-blue-600"></i></div>
                    <h2 class="text-2xl font-bold text-slate-900 mb-3">Divulgation responsable</h2>
                    <p class="text-slate-600 text-sm leading-relaxed mb-6">Vous avez découvert une vulnérabilité de sécurité? Nous vous remercions de nous la signaler de façon responsable. Notre programme de divulgation responsable prévoit des récompenses pour les chercheurs en sécurité.</p>
                    <a href="mailto:security@60sec-ai.ca" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200"><i data-lucide="lock" class="w-4 h-4"></i>security@60sec-ai.ca</a>
                </div>
            </section>
        </div>

        <div class="page hidden" data-page="conformite">
            <section class="bg-gradient-to-br from-slate-50 via-sky-50/40 to-white pt-32 pb-20">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <div class="max-w-3xl">
                        <div class="inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-6">
                            <i data-lucide="check-square" class="w-4 h-4"></i>Conformité
                        </div>
                        <h1 class="text-4xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-5 leading-tight">Conformité réglementaire — Canada &amp; Québec</h1>
                        <p class="text-lg text-slate-600 leading-relaxed">60sec-AI maintient la conformité avec toutes les lois fiscales, sociales et sur la protection des données applicables au Canada. Notre moteur de conformité est mis à jour en temps réel dès qu'une loi change.</p>
                    </div>
                </div>
            </section>

            <section class="py-20 bg-white">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-12 text-center">Cadres réglementaires respectés</h2>
                    <div class="space-y-5">

                        <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row sm:items-start gap-5">
                            <div class="flex-shrink-0">
                                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                                    <i data-lucide="shield" class="w-7 h-7 text-blue-600"></i>
                                </div>
                            </div>
                            <div class="flex-1">
                                <div class="flex flex-wrap items-center gap-3 mb-2">
                                    <h3 class="font-bold text-slate-900">LPRPDE</h3>
                                    <span class="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full">Canada (fédéral)</span>
                                    <span class="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1"><i data-lucide="check-square" class="w-3 h-3"></i>Conforme</span>
                                </div>
                                <p class="text-xs text-slate-500 italic mb-2">Loi sur la protection des renseignements personnels et les documents électroniques</p>
                                <p class="text-sm text-slate-600 leading-relaxed">Encadre la collecte, l'utilisation et la divulgation des renseignements personnels dans le cadre d'activités commerciales au Canada.</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row sm:items-start gap-5">
                            <div class="flex-shrink-0">
                                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                                    <i data-lucide="shield" class="w-7 h-7 text-blue-600"></i>
                                </div>
                            </div>
                            <div class="flex-1">
                                <div class="flex flex-wrap items-center gap-3 mb-2">
                                    <h3 class="font-bold text-slate-900">Loi 25 (Québec)</h3>
                                    <span class="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full">Québec</span>
                                    <span class="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1"><i data-lucide="check-square" class="w-3 h-3"></i>Conforme</span>
                                </div>
                                <p class="text-xs text-slate-500 italic mb-2">Loi modernisant des dispositions législatives en matière de protection des renseignements personnels</p>
                                <p class="text-sm text-slate-600 leading-relaxed">Renforce les droits des individus (droit à l'oubli, portabilité) et impose des obligations accrues aux entreprises opérant au Québec.</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row sm:items-start gap-5">
                            <div class="flex-shrink-0">
                                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                                    <i data-lucide="shield" class="w-7 h-7 text-blue-600"></i>
                                </div>
                            </div>
                            <div class="flex-1">
                                <div class="flex flex-wrap items-center gap-3 mb-2">
                                    <h3 class="font-bold text-slate-900">SOC 2 Type II</h3>
                                    <span class="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full">International</span>
                                    <span class="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1"><i data-lucide="check-square" class="w-3 h-3"></i>Certifié</span>
                                </div>
                                <p class="text-xs text-slate-500 italic mb-2">Service Organization Control 2 — Trust Services Criteria</p>
                                <p class="text-sm text-slate-600 leading-relaxed">Audit indépendant annuel vérifiant nos contrôles de sécurité, disponibilité, intégrité du traitement et confidentialité sur une période de 12 mois.</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row sm:items-start gap-5">
                            <div class="flex-shrink-0">
                                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                                    <i data-lucide="shield" class="w-7 h-7 text-blue-600"></i>
                                </div>
                            </div>
                            <div class="flex-1">
                                <div class="flex flex-wrap items-center gap-3 mb-2">
                                    <h3 class="font-bold text-slate-900">PCI DSS</h3>
                                    <span class="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full">International</span>
                                    <span class="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1"><i data-lucide="check-square" class="w-3 h-3"></i>Niveau 2</span>
                                </div>
                                <p class="text-xs text-slate-500 italic mb-2">Payment Card Industry Data Security Standard</p>
                                <p class="text-sm text-slate-600 leading-relaxed">Normes de sécurité pour la protection des données de cartes bancaires utilisées pour les paiements d'abonnement.</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200 rounded-2xl p-6 flex flex-col sm:flex-row sm:items-start gap-5">
                            <div class="flex-shrink-0">
                                <div class="w-14 h-14 bg-blue-50 rounded-xl flex items-center justify-center">
                                    <i data-lucide="shield" class="w-7 h-7 text-blue-600"></i>
                                </div>
                            </div>
                            <div class="flex-1">
                                <div class="flex flex-wrap items-center gap-3 mb-2">
                                    <h3 class="font-bold text-slate-900">RGPD</h3>
                                    <span class="text-xs bg-slate-100 text-slate-600 px-2.5 py-1 rounded-full">Union européenne</span>
                                    <span class="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1"><i data-lucide="check-square" class="w-3 h-3"></i>Conforme</span>
                                </div>
                                <p class="text-xs text-slate-500 italic mb-2">Règlement Général sur la Protection des Données</p>
                                <p class="text-sm text-slate-600 leading-relaxed">Applicable à nos clients ayant des employés ou opérations en Europe. Droits à l'accès, à la rectification et à l'effacement respectés.</p>
                            </div>
                        </div>

                    </div>
                </div>
            </section>

            <section class="py-20 bg-slate-50">
                <div class="max-w-7xl mx-auto px-6 lg:px-8">
                    <h2 class="text-3xl font-bold text-slate-900 mb-3">Obligations fiscales — Tableau de bord</h2>
                    <p class="text-slate-600 mb-10">Récapitulatif des obligations prises en charge automatiquement par 60sec-AI.</p>
                    <div class="space-y-8">

                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Déclarations de revenus</h3>
                            <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                                <div class="grid grid-cols-3 px-6 py-3 bg-slate-50 border-b border-slate-100">
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Obligation</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Fréquence</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Automatisé</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Déclaration T2 — Impôt des sociétés (ARC)</span></div>
                                    <span class="text-sm text-slate-600">Annuelle</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Déclaration CO-17 — Revenu Québec</span></div>
                                    <span class="text-sm text-slate-600">Annuelle</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Acomptes provisionnels</span></div>
                                    <span class="text-sm text-slate-600">Trimestrielle</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                            </div>
                        </div>

                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Paie &amp; Déductions à la source</h3>
                            <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                                <div class="grid grid-cols-3 px-6 py-3 bg-slate-50 border-b border-slate-100">
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Obligation</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Fréquence</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Automatisé</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Remise DAS (RPC/RRQ, AE, impôt)</span></div>
                                    <span class="text-sm text-slate-600">Mensuelle / bi-mensuelle</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">T4 / Relevé 1 — feuillets employés</span></div>
                                    <span class="text-sm text-slate-600">Annuelle (fév.)</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Sommaire T4 / Relevé 1</span></div>
                                    <span class="text-sm text-slate-600">Annuelle (fév.)</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                            </div>
                        </div>

                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Taxes à la consommation</h3>
                            <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                                <div class="grid grid-cols-3 px-6 py-3 bg-slate-50 border-b border-slate-100">
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Obligation</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Fréquence</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Automatisé</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Déclaration TPS/TVH (ARC)</span></div>
                                    <span class="text-sm text-slate-600">Mensuelle / trim. / ann.</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">Déclaration TPS/TVQ (Revenu Québec)</span></div>
                                    <span class="text-sm text-slate-600">Mensuelle / trim. / ann.</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                            </div>
                        </div>

                        <div>
                            <h3 class="text-sm font-bold text-blue-600 uppercase tracking-wider mb-4">Travailleurs indépendants</h3>
                            <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden">
                                <div class="grid grid-cols-3 px-6 py-3 bg-slate-50 border-b border-slate-100">
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Obligation</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Fréquence</span>
                                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Automatisé</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">T1 — Déclaration personnelle</span></div>
                                    <span class="text-sm text-slate-600">Annuelle (avril)</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-slate-100 text-slate-600"><i data-lucide="check-square" class="w-3 h-3"></i>Assisté</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center border-b border-slate-100">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">T2125 — Revenu d'entreprise</span></div>
                                    <span class="text-sm text-slate-600">Annuelle (avril)</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                                <div class="grid grid-cols-3 px-6 py-4 gap-4 items-center">
                                    <div class="flex items-center gap-2.5"><i data-lucide="file-text" class="w-4 h-4 text-slate-400 flex-shrink-0"></i><span class="text-sm text-slate-800 font-medium">T4A / Relevé 1 (sous-traitants)</span></div>
                                    <span class="text-sm text-slate-600">Annuelle (mars)</span>
                                    <span class="inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full w-fit bg-emerald-50 text-emerald-700"><i data-lucide="check-square" class="w-3 h-3"></i>100% automatique</span>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </section>

            <section class="py-16 pb-24 bg-white">
                <div class="max-w-3xl mx-auto px-6 lg:px-8 text-center">
                    <div class="w-14 h-14 bg-blue-50 rounded-2xl flex items-center justify-center mx-auto mb-5">
                        <i data-lucide="calendar" class="w-7 h-7 text-blue-600"></i>
                    </div>
                    <h2 class="text-2xl font-bold text-slate-900 mb-3">Mises à jour réglementaires en temps réel</h2>
                    <p class="text-slate-600 text-sm leading-relaxed mb-6">Notre équipe de juristes et fiscalistes monitore quotidiennement les modifications législatives de l'ARC, Revenu Québec, EDSC et des gouvernements provinciaux. Chaque changement est intégré dans le moteur de conformité avant son entrée en vigueur — sans aucune action de votre part.</p>
                    <a data-nav="contact" class="inline-flex items-center gap-2 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-6 py-3 rounded-xl transition-all duration-200">Parler à notre équipe conformité</a>
                </div>
            </section>
        </div>

    </main>
    <footer class="bg-slate-50 border-t border-slate-200">
        <div class="max-w-7xl mx-auto px-6 lg:px-8 py-16 lg:py-20">
            <div class="grid grid-cols-1 lg:grid-cols-5 gap-12 mb-16">
                <div class="lg:col-span-1">
                    <a data-nav="accueil" href="#" class="flex items-center gap-2 mb-5">
                        <div class="w-9 h-9 bg-blue-600 rounded-lg flex items-center justify-center">
                            <i data-lucide="zap" class="w-5 h-5 text-white fill-white"></i>
                        </div>
                        <span class="text-slate-900 font-bold text-2xl tracking-tight">60sec-AI</span>
                    </a>
                    <p class="text-slate-500 text-sm leading-relaxed mb-6">L'administration financière automatisée pour les PME &amp; les Travailleurs Autonomes du Québec et du Canada.</p>
                    <div class="flex items-center gap-3">
                        <a href="#" class="w-9 h-9 bg-white hover:bg-slate-100 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 border border-slate-200 transition-all duration-200">
                            <i data-lucide="twitter" class="w-4 h-4"></i>
                        </a>
                        <a href="#" class="w-9 h-9 bg-white hover:bg-slate-100 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 border border-slate-200 transition-all duration-200">
                            <i data-lucide="linkedin" class="w-4 h-4"></i>
                        </a>
                        <a href="#" class="w-9 h-9 bg-white hover:bg-slate-100 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 border border-slate-200 transition-all duration-200">
                            <i data-lucide="mail" class="w-4 h-4"></i>
                        </a>
                    </div>
                </div>
                <div class="lg:col-span-4 grid grid-cols-2 sm:grid-cols-3 gap-8">
                    <div>
                        <h4 class="text-slate-900 font-semibold text-sm mb-4">Ressources</h4>
                        <ul class="space-y-3">
                            <li><a data-nav="documentation" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Documentation</a></li>
                            <li><a data-nav="guides" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Guides</a></li>
                            <li><a data-nav="blog" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Blog</a></li>
                            <li><a data-nav="communaute" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Communauté</a></li>
                            <li><a data-nav="statut" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Statut</a></li>
                        </ul>
                    </div>
                    <div>
                        <h4 class="text-slate-900 font-semibold text-sm mb-4">Entreprise</h4>
                        <ul class="space-y-3">
                            <li><a data-nav="a-propos" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">À propos</a></li>
                            <li><a data-nav="carrieres" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Carrières</a></li>
                            <li><a data-nav="partenaires" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Partenaires</a></li>
                            <li><a data-nav="presse" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Presse</a></li>
                            <li><a data-nav="contact" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Contact</a></li>
                        </ul>
                    </div>
                    <div>
                        <h4 class="text-slate-900 font-semibold text-sm mb-4">Légal</h4>
                        <ul class="space-y-3">
                            <li><a data-nav="conditions" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Conditions d'utilisation</a></li>
                            <li><a data-nav="confidentialite" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Confidentialité</a></li>
                            <li><a data-nav="securite" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Sécurité des données</a></li>
                            <li><a data-nav="conformite" href="#" class="text-slate-500 hover:text-slate-900 text-sm transition-colors">Conformité</a></li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="pt-8 border-t border-slate-200 flex flex-col sm:flex-row items-center justify-between gap-4">
                <p class="text-slate-400 text-sm">© 2026 60s Technologies Inc. Tous droits réservés. Fièrement conçu au Québec.</p>
                <div class="flex items-center gap-1 bg-emerald-50 border border-emerald-200 text-emerald-600 text-xs px-3 py-1.5 rounded-full">
                    <div class="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></div>Tous les systèmes opérationnels
                </div>
            </div>
        </div>
    </footer>

    <script>(function () {
  function showPage(slug) {
    document.querySelectorAll('[data-page]').forEach(function (p) {
      p.classList.toggle('hidden', p.getAttribute('data-page') !== slug);
    });
    window.scrollTo({ top: 0, behavior: 'auto' });
  }
  function closeMobile() { var mm = document.getElementById('mobile-menu'); if (mm) mm.classList.add('hidden'); }
  function toggleMobile() { var mm = document.getElementById('mobile-menu'); if (mm) mm.classList.toggle('hidden'); }

  document.addEventListener('click', function (e) {
    var nav = e.target.closest('[data-nav]');
    if (nav) {
      e.preventDefault();
      var slug = nav.getAttribute('data-nav');
      var href = nav.getAttribute('href') || '';
      showPage(slug);
      if (href.charAt(0) === '#' && href.length > 1) {
        var el = document.getElementById(href.slice(1));
        if (el) setTimeout(function () { el.scrollIntoView({ behavior: 'smooth' }); }, 30);
      }
      closeMobile();
      return;
    }
    var mob = e.target.closest('[data-mobile-toggle]');
    if (mob) { e.preventDefault(); toggleMobile(); return; }
  });


  // Neutralise la soumission des formulaires (reconstruction statique hors-ligne)
  document.addEventListener('submit', function (e) { e.preventDefault(); });

  function init() {
    showPage('accueil');
    if (window.lucide && typeof window.lucide.createIcons === 'function') window.lucide.createIcons();
  }
  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);
})();</script>
</body>
</html>