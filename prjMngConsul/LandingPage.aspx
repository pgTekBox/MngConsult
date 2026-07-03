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
        <asp:Literal ID="litPages" runat="server"></asp:Literal>
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