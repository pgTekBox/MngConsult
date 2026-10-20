<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="LeftMenu.ascx.vb" Inherits="MngConsul.Controls.LeftMenu" %>
<%-- Le menu de l'ERP au modèle de l'accueil 60secondes (accueil-60secondes-complet.html) :
     une carte blanche arrondie, des titres de section en petites capitales
     (Mon argent, Mon entreprise, Mon accompagnement, Administration), des
     éléments en pilule avec l'icône dans un rond, la page courante en bleu pâle
     et les pastilles de couleur (jaune = à faire). Le bouton ☰ de l'en-tête
     (Header.ascx) affiche ou masque le menu ; le choix est gardé par navigateur
     (localStorage « 60s-menu »). Sur téléphone, l'en-tête est masqué : la barre
     du haut ci-dessous porte un second ☰ et le menu glisse depuis la gauche. --%>

<div class="app-shell" id="appShell" runat="server">

    <!-- Barre du haut : téléphone seulement (l'en-tête complet y est masqué) -->
    <header class="topbar">
        <button type="button" class="burger60" data-menu-burger
            data-lbl-ouvrir="<%= L("menuShow") %>" data-lbl-fermer="<%= L("menuHide") %>"
            aria-label="<%= L("menuShow") %>" title="<%= L("menuShow") %>" aria-controls="appSidebar" aria-expanded="false">
            <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round">
                <path class="i-b" d="M4 7h16M4 12h16M4 17h16" /><path class="i-x" d="M6 6l12 12M18 6L6 18" />
            </svg>
        </button>
        <div class="brand">
            <span class="brand-title"><asp:Literal runat="server" ID="litAppName" Text="60secondes"></asp:Literal></span>
        </div>
    </header>

    <!-- Voile (téléphone) -->
    <button type="button" class="backdrop" id="menuBackdrop" aria-label="<%= L("menuHide") %>" tabindex="-1"></button>

    <!-- Le menu -->
    <nav class="sidebar" id="appSidebar" aria-label="<%= L("menu") %>">
        <div class="sidebar-inner">
            <asp:Literal ID="litMenu" runat="server" />
        </div>
    </nav>

</div>

<style>
    :root {
        /* Les jetons que les pages consomment (var(--primary)…), au style « Doux bleu marine » */
        --bg: #F2F5F9;
        --card: #ffffff;
        --text: #0E1F3D;
        --muted: #44536E;
        --border: #D5DDE8;
        --shadow: 0 1px 3px rgba(14, 31, 61, .08);
        --primary: #1B4F9C;
        --primary-weak: #E3EBF7;
        --ring: 0 0 0 4px rgba(27, 79, 156, .18);
        --sidebarW: 280px;
        --radius: 16px;
        --font: Nunito, system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
    }

    .app-shell { color: var(--text); font-family: var(--font); }

    /* Le bouton ☰ (aussi dans l'en-tête) : 44 px, coins de 14 px, bleu pâle quand le menu est ouvert ;
       l'icône devient × pour le refermer. */
    .burger60 {
        width: 44px; height: 44px; flex-shrink: 0;
        display: flex; align-items: center; justify-content: center;
        border: 1px solid #D5DDE8; border-radius: 14px;
        background: #FFFFFF; color: #0E1F3D; cursor: pointer; padding: 0;
    }
    .burger60:hover { background: #F2F5F9; }
    .burger60:focus-visible { outline: none; box-shadow: var(--ring); }
    .burger60 .i-x { display: none; }
    .burger60.ouvert { background: #E3EBF7; }
    .burger60.ouvert .i-b { display: none; }
    .burger60.ouvert .i-x { display: inline; }

    /* Barre du haut : seulement sur téléphone */
    .topbar { display: none; }
    .brand-title { font-weight: 800; font-size: 20px; letter-spacing: -.01em; color: #0E1F3D; }

    /* Le menu : une carte blanche de 24 px d'arrondi posée sur le fond, sous l'en-tête. */
    .sidebar {
        position: fixed;
        top: 87px;
        left: 16px;
        width: 270px;
        max-height: calc(100vh - 103px);
        box-sizing: border-box;
        background: #FFFFFF;
        border-radius: 24px;
        overflow: auto;
        scrollbar-width: thin;
        scrollbar-color: #AEBBCD transparent;
        z-index: 40;
    }
    .sidebar-inner {
        display: flex;
        flex-direction: column;
        gap: 2px;
        padding: 10px;
        font-family: Nunito, system-ui, sans-serif;
    }

    /* Titres de section : Mon argent, Mon entreprise… */
    .nav-sec {
        padding: 12px 10px 4px;
        font-size: 12px;
        font-weight: 800;
        letter-spacing: .06em;
        text-transform: uppercase;
        color: #5B6B86;
    }

    /* Éléments : pilule de 44 px, icône dans un rond de 30 px */
    .nav-item, .nav-parent {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 10px;
        min-height: 44px;
        padding: 0 8px;
        border: 0;
        border-radius: 999px;
        background: transparent;
        color: #0E1F3D;
        text-decoration: none;
        font: inherit;
        font-weight: 700;
        text-align: left;
        cursor: pointer;
        box-sizing: border-box;
    }
    .nav-item:hover, .nav-parent:hover { background: #F2F5F9; }
    .nav-item:focus-visible, .nav-parent:focus-visible { outline: none; box-shadow: var(--ring); }
    .nav-ico {
        width: 30px; height: 30px; flex: 0 0 30px;
        border-radius: 50%;
        background: #F2F5F9;
        color: #1B4F9C;
        display: flex; align-items: center; justify-content: center;
    }
    .nav-ico svg { display: block; }
    .nav-txt { flex-grow: 1; font-size: 15px; }

    /* La page où l'on est : fond bleu pâle, icône blanche sur rond bleu */
    .nav-item.ici, .nav-parent.ici { background: #E3EBF7; color: #143A73; }
    .nav-item.ici .nav-ico, .nav-parent.ici .nav-ico { background: #1B4F9C; color: #FFFFFF; }

    /* Pastilles : jaune = à faire, rouge = en retard, bleu pâle = information */
    .nav-badge {
        min-width: 22px; height: 22px; box-sizing: border-box;
        padding: 0 7px; border-radius: 11px;
        display: inline-flex; align-items: center; justify-content: center;
        font-size: 12px; font-weight: 800;
        background: #E8EDF5; color: #143A73;
    }
    .nav-badge.y { background: #E3B341; color: #3D2A00; }
    .nav-badge.r { background: #A3261C; color: #FFFFFF; }

    /* Groupes dépliables (les écrans d'un même élément) */
    .chev { display: flex; color: #5B6B86; }
    .chev svg { transition: transform .18s ease; }
    .nav-parent[aria-expanded="true"] .chev svg { transform: rotate(90deg); }
    .nav-parent[aria-expanded="false"] + .nav-children { display: none; }
    .nav-children { display: flex; flex-direction: column; gap: 1px; padding: 2px 0 6px 48px; }
    .nav-child {
        display: flex; align-items: center;
        min-height: 34px; padding: 0 12px;
        border-radius: 999px;
        color: #44536E; text-decoration: none;
        font-weight: 700; font-size: 14px;
    }
    .nav-child:hover { background: #F2F5F9; color: #0E1F3D; }
    .nav-child.ici { background: #E3EBF7; color: #143A73; font-weight: 800; }

    /* Voile (téléphone) */
    .backdrop { display: none; position: fixed; inset: 0; background: rgba(14, 31, 61, .42); z-index: 35; border: none; }

    /* Ordinateur : le menu masqué par ☰ libère sa colonne */
    @media (min-width: 769px) {
        html.menu-ferme .mc-shell { grid-template-columns: minmax(0, 1fr); }
        html.menu-ferme .mc-sidebar { display: none; }
    }

    /* Téléphone : barre du haut avec ☰, le menu glisse depuis la gauche */
    @media (max-width: 768px) {
        .topbar {
            display: flex; align-items: center; gap: 12px;
            position: fixed; top: 0; left: 0; right: 0; z-index: 50;
            height: 64px; padding: 10px 16px; box-sizing: border-box;
            background: #FFFFFF; border-bottom: 1px solid #D5DDE8;
        }
        .mc-shell { padding-top: 64px; grid-template-columns: minmax(0, 1fr); }
        .sidebar {
            top: 64px; left: 0; width: var(--sidebarW);
            height: calc(100% - 64px); max-height: none; border-radius: 0 24px 24px 0;
            transform: translateX(-110%);
            transition: transform .22s ease;
        }
        .app-shell.menu-open .sidebar { transform: translateX(0); }
        .app-shell.menu-open .backdrop { display: block; }
    }

    @media (prefers-reduced-motion: reduce) {
        .sidebar, .chev svg { transition: none; }
    }
</style>

<script>
    (function () {
        var CLE = '60s-menu';
        var html = document.documentElement;
        var shell = document.getElementById('<%= appShell.ClientID %>');
        var backdrop = document.getElementById('menuBackdrop');
        if (!shell) return;
        // Les deux ☰ : celui de l'en-tête (ordinateur) et celui de la barre du haut (téléphone)
        var boutons = Array.prototype.slice.call(document.querySelectorAll('[data-menu-burger]'));

        function telephone() { return window.innerWidth <= 768; }
        function estOuvert() {
            return telephone() ? shell.classList.contains('menu-open') : !html.classList.contains('menu-ferme');
        }
        function peindre() {
            var o = estOuvert();
            boutons.forEach(function (b) {
                var lbl = o ? b.getAttribute('data-lbl-fermer') : b.getAttribute('data-lbl-ouvrir');
                b.classList.toggle('ouvert', o);
                b.setAttribute('aria-expanded', String(o));
                if (lbl) { b.setAttribute('aria-label', lbl); b.title = lbl; }
            });
        }
        function ouvrirTiroir(o) {
            shell.classList.toggle('menu-open', o);
            document.body.style.overflow = o ? 'hidden' : '';
            peindre();
        }
        function basculer() {
            if (telephone()) { ouvrirTiroir(!shell.classList.contains('menu-open')); return; }
            var ferme = !html.classList.contains('menu-ferme');
            html.classList.toggle('menu-ferme', ferme);
            try { window.localStorage.setItem(CLE, ferme ? '0' : '1'); } catch (e) { }
            peindre();
        }

        boutons.forEach(function (b) { b.addEventListener('click', basculer); });
        if (backdrop) backdrop.addEventListener('click', function () { ouvrirTiroir(false); });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && telephone() && shell.classList.contains('menu-open')) ouvrirTiroir(false);
        });
        window.addEventListener('resize', function () {
            if (!telephone() && shell.classList.contains('menu-open')) ouvrirTiroir(false); else peindre();
        });

        // Groupes dépliables
        Array.prototype.forEach.call(shell.querySelectorAll('.nav-parent'), function (p) {
            p.addEventListener('click', function () {
                p.setAttribute('aria-expanded', p.getAttribute('aria-expanded') === 'true' ? 'false' : 'true');
            });
        });

        // La page courante (marquée par le serveur) : son groupe s'ouvre et prend la couleur « ici »
        var courant = shell.querySelector('.nav-child.ici');
        if (courant) {
            var groupe = courant.closest('.nav-group');
            var parent = groupe ? groupe.querySelector('.nav-parent') : null;
            if (parent) { parent.setAttribute('aria-expanded', 'true'); parent.classList.add('ici'); }
        }

        // Téléphone : un lien choisi referme le tiroir
        Array.prototype.forEach.call(shell.querySelectorAll('[data-navlink]'), function (a) {
            a.addEventListener('click', function () { if (telephone()) ouvrirTiroir(false); });
        });

        peindre();
    })();
</script>
