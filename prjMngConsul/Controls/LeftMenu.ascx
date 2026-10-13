<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="LeftMenu.ascx.vb" Inherits="MngConsul.Controls.LeftMenu" %>


<div class="app-shell" id="appShell" runat="server">

    <!-- Topbar -->
    <header class="topbar">
        <button type="button" class="hamburger" id="btnMenu" aria-label="Ouvrir le menu" aria-controls="appSidebar" aria-expanded="false">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M4 6h16M4 12h16M4 18h16" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
        </button>

        <div class="brand">
            <span class="brand-dot" aria-hidden="true"></span>
            <span class="brand-title">
                <asp:Literal runat="server" ID="litAppName" Text="60Sec-AI"></asp:Literal></span>
            <span class="brand-sub">ERP</span>
        </div>

    </header>

    <!-- Backdrop mobile -->
    <button type="button" class="backdrop" id="menuBackdrop" aria-label="Fermer le menu" tabindex="-1"></button>

    <!-- Sidebar -->
    <aside class="sidebar" id="appSidebar" aria-label="Navigation principale">
        <div class="sidebar-inner">
            <asp:Literal ID="litMenu" runat="server" />
        </div>
    </aside>



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

    .app-shell {
        /* min-height:100vh; */
        background: var(--bg);
        color: var(--text);
        font-family: var(--font);
    }

    /* Topbar */
    .topbar {
        position: sticky;
        top: 0;
        z-index: 30;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 14px;
        padding: 12px 16px;
        border-bottom: 1px solid var(--border);
        background: rgba(255,255,255,.85);
        backdrop-filter: blur(10px);
    }

    .hamburger {
        width: 44px;
        height: 44px;
        display: none;
        align-items: center;
        justify-content: center;
        border: 1px solid var(--border);
        background: #fff;
        border-radius: 12px;
        color: var(--text);
        cursor: pointer;
        box-shadow: 0 2px 10px rgba(2,6,23,.06);
    }

        .hamburger:focus {
            outline: none;
            box-shadow: var(--ring);
        }

    .brand {
        display: flex;
        align-items: baseline;
        gap: 10px;
        min-width: 180px;
        margin-right: auto;
    }


    .brand-dot {
        width: 10px;
        height: 10px;
        border-radius: 999px;
        background: var(--primary);
        box-shadow: 0 0 0 6px rgba(37,99,235,.12);
        display: inline-block;
    }

    .brand-title {
        font-weight: 800;
        letter-spacing: .2px;
    }

    .brand-sub {
        font-size: 12px;
        color: var(--muted);
        font-weight: 600;
    }

    .user-pill {
        display: flex;
        align-items: center;
        gap: 10px;
        background: #fff;
        border: 1px solid var(--border);
        border-radius: 14px;
        padding: 8px 10px;
        box-shadow: 0 2px 12px rgba(2,6,23,.05);
    }

    .user-avatar {
        width: 30px;
        height: 30px;
        border-radius: 10px;
        background: var(--primary-weak);
        color: var(--primary);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 12px;
    }

    .user-name {
        font-size: 14px;
        font-weight: 700;
    }

    /* Sidebar */
    .sidebar {
        position: fixed;
        top: 0;
        left: 0;
        /* height:100vh; */
        height: 100%;
        width: var(--sidebarW);
        background: #fff;
        border-right: 1px solid var(--border);
        box-shadow: 0 10px 40px rgba(2,6,23,.08);
        z-index: 40;
    }

    .sidebar-inner {
        height: 100%;
        display: flex;
        flex-direction: column;
        padding: 12px;
        padding-top: 82px; /* sous l'en-tête de 71 px */
        gap: 4px;
        font-family: var(--mc-font-titre, Nunito, system-ui, sans-serif);
    }

    /* Items */
    .nav-item, .nav-parent {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 12px;
        min-height: 50px;
        padding: 0 8px;
        border-radius: 999px;
        text-decoration: none;
        color: var(--mc-navy, #0E1F3D);
        border: 0;
        background: transparent;
        cursor: pointer;
        font: inherit;
        text-align: left;
    }
        .nav-item:hover, .nav-parent:hover {
            background: var(--mc-page, #F2F5F9);
        }
        /* La page où l'on est : fond bleu pâle, icône sur rond bleu marine. */
        .nav-item.ici, .nav-parent.ici {
            background: var(--mc-soft2, #E3EBF7);
            color: var(--mc-primary-dark, #143A73);
        }
        .nav-item.ici .nav-txt { font-weight: 800; }
        .nav-item.ici .nav-ico, .nav-parent.ici .nav-ico {
            background: var(--mc-primary, #1B4F9C);
            color: #fff;
        }

        .nav-item:focus, .nav-parent:focus {
            outline: none;
            box-shadow: var(--ring);
        }

    .nav-ico {
        width: 36px;
        height: 36px;
        flex: 0 0 36px;
        border-radius: 50%;
        background: var(--mc-page, #F2F5F9);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 17px;
        line-height: 1;
        color: var(--mc-primary, #1B4F9C);
    }
    .nav-ico svg { display: block; }
    .nav-txt {
        font-weight: 700;
        font-size: 15px;
    }

    .nav-meta {
        margin-left: auto;
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .nav-badge {
        background: var(--mc-soft, #E8EDF5);
        color: var(--mc-primary, #1B4F9C);
        border: 1px solid transparent;
        font-size: 12px;
        font-weight: 800;
        padding: 2px 8px;
        border-radius: 999px;
    }

        /* Pastille d'alerte : ce qui attend une décision de l'utilisateur. */
        .nav-badge.alert {
            background: #fef3c7;
            color: #b45309;
            border-color: #fcd34d;
        }

    .chev {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 26px;
        height: 26px;
        border-radius: 50%;
        color: var(--mc-muted2, #44536E);
    }
    /* Accordion */
    .nav-group {
        padding: 2px 0;
    }

    .nav-children {
        display: block;
        padding: 2px 4px 8px 26px;
    }
    .nav-child {
        display: flex;
        align-items: center;
        gap: 10px;
        min-height: 38px;
        padding: 0 14px;
        border-radius: 999px;
        color: var(--mc-muted2, #44536E);
        text-decoration: none;
        font-weight: 700;
        font-size: 13.5px;
    }
        .nav-child:hover {
            background: var(--mc-page, #F2F5F9);
            color: var(--mc-navy, #0E1F3D);
        }
        .nav-child.ici {
            background: var(--mc-soft2, #E3EBF7);
            color: var(--mc-primary-dark, #143A73);
            font-weight: 800;
        }
        .nav-child.ici .dot { background: var(--mc-primary, #1B4F9C); box-shadow: none; }
    .dot {
        width: 7px;
        height: 7px;
        border-radius: 999px;
        background: var(--mc-line2, #AEBBCD);
    }

    /* Closed state */
    .nav-parent[aria-expanded="false"] + .nav-children {
        display: none;
    }

    .nav-parent[aria-expanded="true"] .chev svg {
        transform: rotate(90deg);
    }

    .nav-parent .chev svg {
        transition: transform .18s ease;
    }

    /* Footer */
    .sidebar-footer {
        margin-top: auto;
        padding: 8px 0 0;
        border-top: 1px solid var(--mc-soft, #E8EDF5);
    }
    .subtle {
        color: var(--mc-navy, #0E1F3D);
    }

    /* Content */
    .content {
        margin-left: var(--sidebarW);
        padding: 18px;
    }

    /* Backdrop */
    .backdrop {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(2, 6, 23, .42);
        z-index: 35;
        border: none;
    }

    /* =========================
            TABLETTE — 769px à 1024px
         ========================= */
    @media (max-width: 1024px) {
    }

    /* =========================
             MOBILE LARGE  grands smartphones en portrait
         ========================= */
    @media (max-width: 768px) {

        .hamburger {
            display: flex;
        }

        .sidebar {
            transform: translateX(-110%);
            transition: transform .22s ease;
        }

        .content {
            margin-left: 0;
            padding: 14px;
        }

        .app-shell.menu-open .sidebar {
            transform: translateX(0);
        }

        .app-shell.menu-open .backdrop {
            display: block;
        }

        .topbar {
            position: fixed; /* ← au lieu de sticky */
            top: 0;
            left: 0;
            right: 0;
            z-index: 50;
            height: 64px;
        }

        /* Compense la hauteur du topbar fixe */
        .mc-shell {
            padding-top: 64px;
        }
    }
    /* =========================
         PETIT MOBILE — max 480px
           ========================= */
    @media (max-width: 480px) {
    }

    @media (prefers-reduced-motion: reduce) {
        .sidebar, .nav-parent .chev svg {
            transition: none;
        }
    }
</style>

<script>
    (function () {
        var shell = document.getElementById('<%= appShell.ClientID %>');
        var btn = document.getElementById('btnMenu');
        var backdrop = document.getElementById('menuBackdrop');

        if (!shell) return;

        // --- Mobile open/close ---
        function setMenuOpen(isOpen) {
            if (!btn || !backdrop) return;
            if (isOpen) {
                shell.classList.add('menu-open');
                btn.setAttribute('aria-expanded', 'true');
                document.body.style.overflow = 'hidden';
            } else {
                shell.classList.remove('menu-open');
                btn.setAttribute('aria-expanded', 'false');
                document.body.style.overflow = '';
            }
        }

        if (btn) {
            btn.addEventListener('click', function () {
                setMenuOpen(!shell.classList.contains('menu-open'));
            });
        }
        if (backdrop) {
            backdrop.addEventListener('click', function () { setMenuOpen(false); });
        }
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') setMenuOpen(false);
        });
        window.addEventListener('resize', function () {
            if (window.innerWidth > 820) setMenuOpen(false);
        });

        // --- Accordion behavior ---
        var groups = shell.querySelectorAll('[data-accordion] .nav-parent');
        groups.forEach(function (btnParent) {
            btnParent.addEventListener('click', function () {
                var isOpen = btnParent.getAttribute('aria-expanded') === 'true';
                btnParent.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
            });
        });

        // --- La page courante (marquée par le serveur) : son groupe s'ouvre ---
        var courant = shell.querySelector('.nav-child.ici');
        if (courant) {
            var groupe = courant.closest('.nav-group');
            var parent = groupe ? groupe.querySelector('.nav-parent') : null;
            if (parent) { parent.setAttribute('aria-expanded', 'true'); parent.classList.add('ici'); }
        }
        // --- Close mobile menu after click on any link ---
var links = shell.querySelectorAll('[data-navlink]');
        links.forEach(function (a) {
            a.addEventListener('click', function () {
                if (window.innerWidth <= 820) {
                    setMenuOpen(false);
                }
            });
        });

    })();
</script>
