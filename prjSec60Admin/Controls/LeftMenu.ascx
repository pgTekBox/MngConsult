<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="LeftMenu.ascx.vb" Inherits="prjSec60Admin.LeftMenu" %>

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
                <asp:Literal runat="server" ID="litAppName" Text="Sec60Admin"></asp:Literal></span>
            <span class="brand-sub">Console</span>
        </div>
    </header>

    <!-- Backdrop mobile -->
    <button type="button" class="backdrop" id="menuBackdrop" aria-label="Fermer le menu" tabindex="-1"></button>

    <!-- Sidebar -->
    <aside class="sidebar" id="appSidebar" aria-label="Navigation principale">
        <div class="sidebar-inner">

            <a class="nav-item" href="~/Default.aspx" runat="server" data-navlink>
                <span class="nav-ico" aria-hidden="true">🏠</span>
                <span class="nav-txt">Tableau de bord</span>
            </a>

            <!-- Sous-menu Courriel (accordion, ouvert par défaut) -->
            <div class="nav-group" data-accordion>
                <button type="button" class="nav-parent" aria-expanded="true">
                    <span class="nav-ico" aria-hidden="true">✉️</span>
                    <span class="nav-txt">Courriel</span>
                    <span class="nav-meta">
                        <span class="chev" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                        </span>
                    </span>
                </button>

                <div class="nav-children">
                    <a class="nav-child" href="~/wbfMail.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Courriel
                    </a>
                    <a class="nav-child" href="~/wbfMailAccounts.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Comptes de courriel
                    </a>
                </div>
            </div>

            <!-- Sous-menu Sécurité (accordion, ouvert par défaut) -->
            <div class="nav-group" data-accordion>
                <button type="button" class="nav-parent" aria-expanded="true">
                    <span class="nav-ico" aria-hidden="true">🔐</span>
                    <span class="nav-txt">Sécurité</span>
                    <span class="nav-meta">
                        <span class="chev" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                        </span>
                    </span>
                </button>

                <div class="nav-children">
                    <a class="nav-child" href="~/wbfUsers.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Utilisateurs
                    </a>
                    <a class="nav-child" href="~/wbfAdmins.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Administrateurs
                    </a>
                </div>
            </div>

            <!-- Sous-menu Abonnements (accordion) -->
            <div class="nav-group" data-accordion>
                <button type="button" class="nav-parent" aria-expanded="true">
                    <span class="nav-ico" aria-hidden="true">💳</span>
                    <span class="nav-txt">Abonnements</span>
                    <span class="nav-meta">
                        <span class="chev" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                        </span>
                    </span>
                </button>

                <div class="nav-children">
                    <a class="nav-child" href="~/wbfPlans.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Forfaits
                    </a>
                    <a class="nav-child" href="~/wbfLanding.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        LandingPage
                    </a>
                    <a class="nav-child" href="~/wbfCompanies.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Compagnies
                    </a>
                    <a class="nav-child" href="~/wbfStripeWebhookDiagnostic.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Webhooks Stripe
                    </a>
                    <a class="nav-child" href="~/wbfSquareWebhookDiagnostic.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Webhooks Square
                    </a>
                    <a class="nav-child" href="~/wbfPlaidDiagnostic.aspx" runat="server" data-navlink>
                        <span class="dot" aria-hidden="true"></span>
                        Connexions Plaid
                    </a>
                </div>
            </div>

            <!-- Footer -->
            <div class="sidebar-footer">
                <a class="nav-item subtle" href="~/wbfSettingsOpenAiPrompts.aspx" runat="server" data-navlink>
                    <span class="nav-ico" aria-hidden="true">🤖</span>
                    <span class="nav-txt">Prompts OpenAI</span>
                </a>
                <a class="nav-item subtle" href="~/wbfDemoReset.aspx" runat="server" data-navlink>
                    <span class="nav-ico" aria-hidden="true">🔄</span>
                    <span class="nav-txt">Réinitialiser la démo</span>
                </a>
                <a class="nav-item subtle" href="~/About.aspx" runat="server" data-navlink>
                    <span class="nav-ico" aria-hidden="true">ℹ️</span>
                    <span class="nav-txt">À propos</span>
                </a>
                <a class="nav-item subtle" href="~/Contact.aspx" runat="server" data-navlink>
                    <span class="nav-ico" aria-hidden="true">✉️</span>
                    <span class="nav-txt">Contact</span>
                </a>

                <div class="signed-in">
                    <span class="si-ico" aria-hidden="true">👤</span>
                    <span class="si-email"><asp:Literal runat="server" ID="litAdminEmail" /></span>
                </div>
                <a class="nav-item subtle" href="~/wbfLogout.aspx" runat="server" data-navlink>
                    <span class="nav-ico" aria-hidden="true">🚪</span>
                    <span class="nav-txt">Déconnexion</span>
                </a>
            </div>

        </div>
    </aside>

</div>

<style>
    :root {
        --bg: #f6f7fb;
        --card: #ffffff;
        --text: #0f172a;
        --muted: #64748b;
        --border: #e5e7eb;
        --shadow: 0 10px 30px rgba(15, 23, 42, .08);
        --primary: #2563eb;
        --primary-weak: #eff6ff;
        --ring: 0 0 0 4px rgba(37, 99, 235, .18);
        --sidebarW: 280px;
        --radius: 16px;
        --font: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
    }

    .app-shell {
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

    /* Sidebar */
    .sidebar {
        position: fixed;
        top: 0;
        left: 0;
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
        padding: 14px 12px 12px;
        padding-top: 68px;
        gap: 6px;
    }

    /* Items */
    .nav-item, .nav-parent {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 10px 12px;
        border-radius: 12px;
        text-decoration: none;
        color: var(--text);
        border: 1px solid transparent;
        background: transparent;
        cursor: pointer;
        font: inherit;
    }

        .nav-item:hover, .nav-parent:hover {
            background: #f8fafc;
            border-color: #eef2f7;
        }

        .nav-item:focus, .nav-parent:focus {
            outline: none;
            box-shadow: var(--ring);
        }

    .nav-ico {
        width: 24px;
        text-align: center;
    }

    .nav-txt {
        font-weight: 800;
        font-size: 14px;
    }

    .nav-meta {
        margin-left: auto;
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .chev {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 26px;
        height: 26px;
        border-radius: 10px;
        color: var(--muted);
    }

    /* Accordion */
    .nav-group {
        padding: 2px 0;
    }

    .nav-children {
        display: block;
        padding: 2px 6px 8px 42px;
    }

    .nav-child {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 8px 10px;
        border-radius: 10px;
        color: var(--muted);
        text-decoration: none;
        font-weight: 700;
        font-size: 13px;
        border: 1px solid transparent;
    }

        .nav-child:hover {
            background: #f8fafc;
            color: var(--text);
            border-color: #eef2f7;
        }

    .dot {
        width: 7px;
        height: 7px;
        border-radius: 999px;
        background: #cbd5e1;
        box-shadow: 0 0 0 4px rgba(203,213,225,.35);
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
        padding: 6px;
        border-top: 1px dashed #e9eef5;
    }

    .subtle {
        color: #0f172a;
    }

    .signed-in {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 12px 2px;
        font-size: 12px;
        color: var(--muted);
        overflow: hidden;
    }

    .si-email {
        font-weight: 700;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
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
             MOBILE — sidebar coulissante
         ========================= */
    @media (max-width: 768px) {

        .hamburger {
            display: flex;
        }

        .sidebar {
            transform: translateX(-110%);
            transition: transform .22s ease;
        }

        .app-shell.menu-open .sidebar {
            transform: translateX(0);
        }

        .app-shell.menu-open .backdrop {
            display: block;
        }

        .topbar {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 50;
            height: 64px;
        }
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
