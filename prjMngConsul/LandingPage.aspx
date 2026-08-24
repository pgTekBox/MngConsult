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

        /* ---------------------------------------------------------------
           Page « Application mobile » : maquette de téléphone en CSS pur
           (aucune image). Le reste de la page utilise les classes du CSS
           compilé (css/landingpage.css), qui est figé — d'où ces quelques
           règles dédiées ici plutôt que de nouvelles classes utilitaires.
           --------------------------------------------------------------- */
        .apk-stage {
            position: relative;
            display: flex;
            justify-content: center
        }

            .apk-stage::before {
                content: "";
                position: absolute;
                top: 50%;
                left: 50%;
                width: 360px;
                height: 360px;
                transform: translate(-50%,-50%);
                border-radius: 9999px;
                background: rgba(14,165,233,.20);
                filter: blur(70px)
            }

        .apk-phone {
            position: relative;
            width: 288px;
            height: 586px;
            padding: 11px;
            border-radius: 46px;
            background: #0b1220;
            box-shadow: 0 45px 90px -30px rgba(2,6,23,.55), 0 0 0 1px rgba(2,6,23,.08)
        }

            .apk-phone::before {
                content: "";
                position: absolute;
                top: 20px;
                left: 50%;
                transform: translateX(-50%);
                width: 104px;
                height: 24px;
                border-radius: 14px;
                background: #0b1220;
                z-index: 3
            }

        .apk-screen {
            position: relative;
            height: 100%;
            border-radius: 36px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            background: #f8fafc
        }

        .apk-top {
            padding: 52px 20px 22px;
            color: #fff;
            background: linear-gradient(135deg,#1d4ed8 0%,#2563eb 45%,#0ea5e9 100%)
        }

        .apk-brand {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
            font-weight: 600
        }

        .apk-avatar {
            width: 26px;
            height: 26px;
            border-radius: 9999px;
            background: rgba(255,255,255,.22);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 700
        }

        .apk-label {
            margin-top: 18px;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: .09em;
            color: rgba(224,242,254,.85)
        }

        .apk-amount {
            margin-top: 3px;
            font-size: 30px;
            font-weight: 700;
            letter-spacing: -.02em;
            line-height: 1.1
        }

        .apk-delta {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            margin-top: 12px;
            padding: 3px 10px;
            font-size: 11px;
            font-weight: 600;
            border-radius: 9999px;
            background: rgba(255,255,255,.16);
            border: 1px solid rgba(255,255,255,.24)
        }

            .apk-delta svg {
                width: 12px;
                height: 12px
            }

        .apk-body {
            flex: 1;
            padding: 16px;
            display: flex;
            flex-direction: column;
            gap: 10px;
            background: linear-gradient(180deg,#f8fafc 0%,#eff6ff 100%)
        }

        .apk-card {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px;
            border-radius: 16px;
            background: #fff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 6px 16px -10px rgba(15,23,42,.35)
        }

        .apk-ico {
            width: 34px;
            height: 34px;
            border-radius: 11px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0
        }

            .apk-ico svg {
                width: 16px;
                height: 16px
            }

        .apk-ico-blue {
            background: #eff6ff;
            color: #1d4ed8
        }

        .apk-ico-emerald {
            background: #ecfdf5;
            color: #047857
        }

        .apk-card-txt {
            min-width: 0;
            display: block
        }

        .apk-card-t {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: #020617;
            line-height: 1.3
        }

        .apk-card-s {
            display: block;
            margin-top: 1px;
            font-size: 11px;
            color: #64748b
        }

        .apk-card-v {
            margin-left: auto;
            text-align: right;
            flex-shrink: 0
        }

        .apk-card-a {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: #020617
        }

        .apk-pill {
            display: inline-block;
            margin-top: 3px;
            padding: 2px 7px;
            font-size: 9px;
            font-weight: 600;
            border-radius: 9999px;
            background: #ecfdf5;
            color: #047857
        }

        .apk-tabs {
            display: flex;
            align-items: center;
            justify-content: space-around;
            padding: 12px 8px 18px;
            background: #fff;
            border-top: 1px solid #e2e8f0
        }

        .apk-tab {
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8
        }

            .apk-tab svg {
                width: 18px;
                height: 18px
            }

            .apk-tab.is-on {
                color: #1d4ed8
            }

        .apk-qr svg {
            display: block;
            border-radius: 8px
        }

        /* Le code QR ne sert qu'aux visiteurs sur ordinateur : sur téléphone
           on masque la carte, le bouton de téléchargement suffit. */
        .apk-qr-card {
            display: none
        }

        @media (min-width:640px) {
            .apk-qr-card {
                display: flex
            }
        }
    </style>
</head>
<body class="font-sans antialiased bg-white text-slate-900">
    <nav class="fixed top-0 left-0 right-0 z-50 transition-all duration-300 bg-white/95 backdrop-blur-md shadow-sm shadow-slate-200/80 border-b border-slate-100">
        <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="flex items-center justify-between h-16 lg:h-20">
                <a data-nav="accueil" href="#" class="flex items-center gap-2 group">
                    <img src="Images/logo.svg" alt="60sec-AI" class="w-9 h-9 transition-transform duration-200 group-hover:scale-110" />
                    <span class="text-slate-900 font-bold text-2xl tracking-tight">60sec-AI</span>
                </a>
                <div class="hidden md:flex items-center gap-8">
                    <a data-nav="accueil" href="#problem" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Problème</a>
                    <a data-nav="accueil" href="#solution" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Solution</a>
                    <a data-nav="accueil" href="#features" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Fonctionnalités</a>
                    <a data-nav="accueil" href="#mission" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Mission</a>
                    <a data-nav="mobile" href="#" class="inline-flex items-center gap-1.5 text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors"><i data-lucide="smartphone" class="w-4 h-4"></i>Application mobile</a>
                </div>
                <div class="hidden md:flex items-center gap-4">
                    <asp:Literal ID="litLang" runat="server"></asp:Literal>
                    <a href="wbfLogin.aspx?lang=<%= CurrentLang %>" class="text-slate-600 hover:text-slate-900 text-sm font-medium transition-colors">Connexion</a>
                    <a data-nav="accueil" href="#plans" class="bg-blue-700 hover:bg-blue-600 text-white text-sm font-semibold px-5 py-2.5 rounded-lg transition-all duration-200 hover:shadow-lg hover:shadow-blue-700/25">Inscription</a>
                </div>
                <button type="button" data-mobile-toggle aria-controls="mobile-menu" aria-expanded="false" aria-label="Ouvrir le menu" class="md:hidden text-slate-700 p-2">
                    <i data-lucide="menu" class="w-6 h-6"></i>
                </button>
            </div>
        </div>

        <!-- Menu mobile : déplié par le bouton ci-dessus (data-mobile-toggle),
             replié dès qu'un lien est touché. Masqué au-delà de 768 px. -->
        <div id="mobile-menu" class="hidden md:hidden border-t border-slate-100 bg-white">
            <div class="max-w-7xl mx-auto px-6 py-4">
                <a data-nav="accueil" href="#problem" class="block py-3 text-slate-700 hover:text-slate-900 text-base font-medium transition-colors">Problème</a>
                <a data-nav="accueil" href="#solution" class="block py-3 text-slate-700 hover:text-slate-900 text-base font-medium transition-colors">Solution</a>
                <a data-nav="accueil" href="#features" class="block py-3 text-slate-700 hover:text-slate-900 text-base font-medium transition-colors">Fonctionnalités</a>
                <a data-nav="accueil" href="#mission" class="block py-3 text-slate-700 hover:text-slate-900 text-base font-medium transition-colors">Mission</a>
                <a data-nav="mobile" href="#" class="flex items-center gap-2 py-3 text-slate-700 hover:text-slate-900 text-base font-medium transition-colors"><i data-lucide="smartphone" class="w-4 h-4"></i>Application mobile</a>
                <div class="flex items-center justify-between pt-4 mt-2 border-t border-slate-100">
                    <asp:Literal ID="litLangMobile" runat="server"></asp:Literal>
                    <a href="wbfLogin.aspx?lang=<%= CurrentLang %>" class="text-slate-700 hover:text-slate-900 text-base font-medium transition-colors">Connexion</a>
                </div>
                <a data-nav="accueil" href="#plans" class="block text-center bg-blue-700 hover:bg-blue-600 text-white text-base font-semibold px-5 py-3 rounded-lg mt-6 transition-all duration-200">Inscription</a>
            </div>
        </div>
    </nav>

    <main>
        <asp:Literal ID="litPages" runat="server"></asp:Literal>
    </main>
    <footer class="bg-slate-50 border-t border-slate-200">
        <div class="max-w-7xl mx-auto px-6 lg:px-8 py-16 lg:py-20">
            <div class="grid grid-cols-1 lg:grid-cols-5 gap-12 mb-16">
                <div class="lg:col-span-1">
                    <a data-nav="accueil" href="#" class="flex items-center gap-2 mb-5 group">
                        <img src="Images/logo.svg" alt="60sec-AI" class="w-9 h-9 transition-transform duration-200 group-hover:scale-110" />
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
                            <li><a data-nav="mobile" href="#" class="inline-flex items-center gap-1.5 text-slate-500 hover:text-slate-900 text-sm transition-colors"><i data-lucide="smartphone" class="w-3.5 h-3.5"></i>Application Android</a></li>
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
  function setMobile(open) {
    var mm = document.getElementById('mobile-menu');
    if (mm) mm.classList.toggle('hidden', !open);
    var btn = document.querySelector('[data-mobile-toggle]');
    if (btn) btn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  function closeMobile() { setMobile(false); }
  function toggleMobile() {
    var mm = document.getElementById('mobile-menu');
    setMobile(mm ? mm.classList.contains('hidden') : false);
  }

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

  // Page affichée au chargement : « accueil » par défaut, ou celle demandée
  // par ?page=<code> (lien profond partageable, ex. ?page=mobile).
  function startSlug() {
    var m = /[?&]page=([A-Za-z0-9-]+)/.exec(window.location.search);
    if (!m) return 'accueil';
    var slug = m[1].toLowerCase();
    return document.querySelector('[data-page="' + slug + '"]') ? slug : 'accueil';
  }

  function init() {
    showPage(startSlug());
    if (window.lucide && typeof window.lucide.createIcons === 'function') window.lucide.createIcons();
  }
  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);
})();</script>
</body>
</html>