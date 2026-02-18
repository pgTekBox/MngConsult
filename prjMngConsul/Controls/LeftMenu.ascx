<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="LeftMenu.ascx.vb" Inherits="MngConsul.Controls.LeftMenu" %>

<div class="app-shell" id="appShell" runat="server">

  <!-- Topbar -->
  <header class="topbar">
    <button type="button" class="hamburger" id="btnMenu" aria-label="Ouvrir le menu" aria-controls="appSidebar" aria-expanded="false">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M4 6h16M4 12h16M4 18h16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      </svg>
    </button>

    <div class="brand">
      <span class="brand-dot" aria-hidden="true"></span>
      <span class="brand-title"><asp:Literal runat="server" ID="litAppName" Text="MngConsul"></asp:Literal></span>
      <span class="brand-sub">ERP</span>
    </div>

   <%-- <div class="topbar-right">
      <div class="user-pill">
        <span class="user-avatar" aria-hidden="true">PG</span>
        <span class="user-name"><asp:Literal runat="server" ID="litUserName" Text="Pierre"></asp:Literal></span>
      </div>
    </div>--%>
  </header>

  <!-- Backdrop mobile -->
  <button type="button" class="backdrop" id="menuBackdrop" aria-label="Fermer le menu" tabindex="-1"></button>

  <!-- Sidebar -->
  <aside class="sidebar" id="appSidebar" aria-label="Navigation principale">
    <div class="sidebar-inner">

      <!-- Item simple -->
      <a class="nav-item" href="~/Accueil.aspx" runat="server" data-navlink>
        <span class="nav-ico" aria-hidden="true">🏠</span>
        <span class="nav-txt">Tableau de bord</span>
      </a>

      <!-- Sous-menu (accordion) -->
      <div class="nav-group" data-accordion>
        <button type="button" class="nav-parent" aria-expanded="false">
          <span class="nav-ico" aria-hidden="true">🧾</span>
          <span class="nav-txt">Ventes</span>
          <span class="nav-meta">
            <span class="nav-badge">12</span>
            <span class="chev" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </span>
          </span>
        </button>

        <div class="nav-children">
          <a class="nav-child" href="~/wbfCustomers.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Clients
          </a>
          <a class="nav-child" href="~/Factures.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Factures clients
          </a>
          <a class="nav-child" href="~/Paiements.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Paiements reçus
          </a>
        </div>
      </div>

      <!-- Sous-menu (accordion) -->
      <div class="nav-group" data-accordion>
        <button type="button" class="nav-parent" aria-expanded="false">
          <span class="nav-ico" aria-hidden="true">📦</span>
          <span class="nav-txt">Achats</span>
          <span class="nav-meta">
            <span class="chev" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </span>
          </span>
        </button>

        <div class="nav-children">
          <a class="nav-child" href="~/wbfSuppliers.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Fournisseurs
          </a>
          <a class="nav-child" href="~/FacturesFournisseurs.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Factures fournisseurs
          </a>
          <a class="nav-child" href="~/Depenses.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Dépenses
          </a>
<a class="nav-child" href="~/wbfReceipt.aspx" runat="server" data-navlink>
  <span class="dot" aria-hidden="true"></span>
  Recus
</a>

        </div>
      </div>

      <!-- Sous-menu (accordion) -->
      <div class="nav-group" data-accordion>
        <button type="button" class="nav-parent" aria-expanded="false">
          <span class="nav-ico" aria-hidden="true">📒</span>
          <span class="nav-txt">Comptabilité</span>
          <span class="nav-meta">
            <span class="chev" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </span>
          </span>
        </button>

        <div class="nav-children">
          <a class="nav-child" href="~/PlanComptable.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Plan comptable
          </a>
          <a class="nav-child" href="~/Ecritures.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Écritures
          </a>
          <a class="nav-child" href="~/Rapports.aspx" runat="server" data-navlink>
            <span class="dot" aria-hidden="true"></span>
            Rapports
          </a>
        </div>
      </div>

      <!-- Footer -->
      <div class="sidebar-footer">
        <a class="nav-item subtle" href="~/Settings.aspx" runat="server" data-navlink>
          <span class="nav-ico" aria-hidden="true">⚙️</span>
          <span class="nav-txt">Paramètres</span>
        </a>
        <a class="nav-item subtle" href="~/Logout.aspx" runat="server" data-navlink>
          <span class="nav-ico" aria-hidden="true">🚪</span>
          <span class="nav-txt">Déconnexion</span>
        </a>
      </div>

    </div>
  </aside>

   

</div>

<style>
  :root{
    --bg:#f6f7fb;
    --card:#ffffff;
    --text:#0f172a;
    --muted:#64748b;
    --border:#e5e7eb;
    --shadow: 0 10px 30px rgba(15, 23, 42, .08);
    --primary:#2563eb;
    --primary-weak:#eff6ff;
    --ring: 0 0 0 4px rgba(37, 99, 235, .18);
    --sidebarW: 280px;
    --radius: 16px;
    --font: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
  }

  .app-shell{ 
      /* min-height:100vh; */
       background:var(--bg); 
       color:var(--text); 
       font-family:var(--font); 

  }

  /* Topbar */
  .topbar{
    position: sticky; top:0; z-index:30;
    display:flex; align-items:center; justify-content:space-between; gap:14px;
    padding:12px 16px;
    border-bottom:1px solid var(--border);
    background: rgba(255,255,255,.85);
    backdrop-filter: blur(10px);
  }
  .hamburger{
    width:44px; height:44px;
    display:none; align-items:center; justify-content:center;
    border:1px solid var(--border); background:#fff; border-radius:12px;
    color:var(--text); cursor:pointer;
    box-shadow:0 2px 10px rgba(2,6,23,.06);
  }
  .hamburger:focus{ outline:none; box-shadow:var(--ring); }

  .brand{ display:flex; align-items:baseline; gap:10px; min-width:180px; }
  .brand-dot{
    width:10px; height:10px; border-radius:999px; background:var(--primary);
    box-shadow:0 0 0 6px rgba(37,99,235,.12);
    display:inline-block;
  }
  .brand-title{ font-weight:800; letter-spacing:.2px; }
  .brand-sub{ font-size:12px; color:var(--muted); font-weight:600; }

  .user-pill{
    display:flex; align-items:center; gap:10px;
    background:#fff; border:1px solid var(--border);
    border-radius:14px; padding:8px 10px;
    box-shadow:0 2px 12px rgba(2,6,23,.05);
  }
  .user-avatar{
    width:30px; height:30px; border-radius:10px;
    background:var(--primary-weak); color:var(--primary);
    display:flex; align-items:center; justify-content:center;
    font-weight:800; font-size:12px;
  }
  .user-name{ font-size:14px; font-weight:700; }

  /* Sidebar */
  .sidebar{
    position:fixed; top:0; left:0;
    /* height:100vh; */
       height:100%; 
    width:var(--sidebarW);
    background:#fff; border-right:1px solid var(--border);
    box-shadow:0 10px 40px rgba(2,6,23,.08);
    z-index:40;
  }
  .sidebar-inner{
    height:100%;
    display:flex; flex-direction:column;
    padding: 14px 12px 12px;
    padding-top: 68px;
    gap: 6px;
  }

  /* Items */
  .nav-item, .nav-parent{
    width:100%;
    display:flex; align-items:center; gap:10px;
    padding:10px 12px;
    border-radius:12px;
    text-decoration:none;
    color:var(--text);
    border: 1px solid transparent;
    background: transparent;
    cursor:pointer;
    font: inherit;
  }
  .nav-item:hover, .nav-parent:hover{ background:#f8fafc; border-color:#eef2f7; }
  .nav-item:focus, .nav-parent:focus{ outline:none; box-shadow:var(--ring); }

  .nav-ico{ width:24px; text-align:center; }
  .nav-txt{ font-weight:800; font-size:14px; }
  .nav-meta{ margin-left:auto; display:flex; align-items:center; gap:10px; }

  .nav-badge{
    background:var(--primary-weak);
    color:var(--primary);
    border:1px solid rgba(37,99,235,.18);
    font-size:12px; font-weight:800;
    padding:2px 8px;
    border-radius:999px;
  }

  .chev{
    display:flex; align-items:center; justify-content:center;
    width:26px; height:26px;
    border-radius:10px;
    color: var(--muted);
  }

  /* Accordion */
  .nav-group{ padding: 2px 0; }
  .nav-children{
    display:block;
    padding: 2px 6px 8px 42px;
  }

  .nav-child{
    display:flex; align-items:center; gap:10px;
    padding:8px 10px;
    border-radius:10px;
    color: var(--muted);
    text-decoration:none;
    font-weight:700;
    font-size: 13px;
    border: 1px solid transparent;
  }
  .nav-child:hover{ background:#f8fafc; color:var(--text); border-color:#eef2f7; }
  .dot{
    width:7px; height:7px;
    border-radius:999px;
    background:#cbd5e1;
    box-shadow: 0 0 0 4px rgba(203,213,225,.35);
  }

  /* Closed state */
  .nav-parent[aria-expanded="false"] + .nav-children{ display:none; }
  .nav-parent[aria-expanded="true"] .chev svg{ transform: rotate(90deg); }
  .nav-parent .chev svg{ transition: transform .18s ease; }

  /* Footer */
  .sidebar-footer{
    margin-top:auto;
    padding: 6px;
    border-top: 1px dashed #e9eef5;
  }
  .subtle{ color:#0f172a; }

  /* Content */
  .content{ margin-left: var(--sidebarW); padding: 18px; }

  /* Backdrop */
  .backdrop{
    display:none;
    position: fixed; inset:0;
    background: rgba(2, 6, 23, .42);
    z-index:35; border:none;
  }

  /* Responsive */
  @media (max-width: 820px){
    .hamburger{ display:flex; }
    .sidebar{
      transform: translateX(-110%);
      transition: transform .22s ease;
    }
    .content{ margin-left: 0; padding: 14px; }
    .app-shell.menu-open .sidebar{ transform: translateX(0); }
    .app-shell.menu-open .backdrop{ display:block; }
  }

  @media (prefers-reduced-motion: reduce){
    .sidebar, .nav-parent .chev svg{ transition:none; }
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
