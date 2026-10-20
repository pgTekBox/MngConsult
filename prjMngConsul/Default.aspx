<%@ Page Title="Home Page" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.vb" Inherits="MngConsul._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
<%-- Le tableau de bord, au modèle de l'accueil 60secondes (accueil-60secondes-complet.html) :
     1. la fenêtre de 60, « + Facture » et la tuile noire des 12 éléments du menu ;
     2. Mon argent (mois, compte bancaire, six cases) ;
     3. l'Agenda (la journée en liste, la semaine de 5 jours ouvrables) ;
     4. les Activités à faire (rouge, jaune, noir).
     Le serveur calcule le modèle (vraies données, Default.aspx.vb) ; le script
     ci-dessous le dessine et gère les clics. Couleurs : rouge #E35D55 / #A3261C,
     jaune #E3B341 / #7A5200, vert #43B47A / #0F5A3A, noir #14161A. --%>
<style>
    .ac{ font-family:Nunito, system-ui, sans-serif; color:#0E1F3D; font-size:16px; line-height:1.45; display:flex; flex-direction:column; gap:16px; }
    .ac button{ font-family:inherit; cursor:pointer; }
    .ac h2{ margin:0; font-size:19px; font-weight:800; }
    .ac-carte{ padding:18px; border-radius:24px; background:#FFFFFF; display:flex; flex-direction:column; gap:12px; }
    .ac-note{ font-size:12px; color:#5B6B86; }

    /* 1. L'essentiel */
    .ac-haut{ display:flex; flex-wrap:nowrap; gap:12px; align-items:stretch; }
    .ac-60{ flex:1 1 0; min-width:0; display:flex; flex-wrap:wrap; align-items:center; gap:8px 16px; padding:8px 14px; border-radius:18px; background:#FFFFFF; border:3px solid #43B47A; box-sizing:border-box; }
    .ac-60 .salut{ flex:0 1 auto; display:flex; align-items:center; gap:10px; }
    .ac-60 h1{ margin:0; font-size:17px; font-weight:800; line-height:1.15; }
    .ac-pastille{ padding:1px 10px; border-radius:999px; font-weight:800; font-size:12px; white-space:nowrap; }
    .ac-prio{ flex:1 1 340px; display:flex; flex-wrap:wrap; align-items:center; gap:6px 12px; padding-left:14px; border-left:1px solid #E3E9F1; }
    .ac-prio .quoi{ flex:1 1 220px; min-width:0; line-height:1.25; }
    .ac-prio .eti{ font-size:12px; font-weight:800; text-transform:uppercase; }
    .ac-prio .sous{ font-size:13px; color:#44536E; }
    .ac-btn{ min-height:40px; padding:0 16px; border:0; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-weight:800; font-size:15px; text-decoration:none; display:inline-flex; align-items:center; }
    .ac-btn:hover{ background:#143A73; color:#fff; }
    .ac-btn.clair{ background:#FFFFFF; color:#0E1F3D; border:1.5px solid #AEBBCD; }
    .ac-btn.clair:hover{ background:#F2F5F9; color:#0E1F3D; }
    .ac-afaire{ display:flex; align-items:center; gap:6px; padding-left:14px; margin-left:2px; border-left:2px solid #D5DDE8; }
    .ac-afaire b{ font-size:14px; white-space:nowrap; }
    .ac-rond{ min-width:40px; height:40px; flex-shrink:0; padding:0 8px; box-sizing:border-box; border:0; border-radius:999px; font-size:18px; font-weight:800; }
    .ac-rond.r{ background:#E35D55; color:#FFFFFF; } .ac-rond.y{ background:#E3B341; color:#3D2A00; }
    .ac-rond.vide{ opacity:.35; }
    .ac-ok{ flex:1 1 340px; padding-left:14px; border-left:1px solid #E3E9F1; color:#0F5A3A; font-size:15px; font-weight:800; }
    .ac-facture{ flex:0 0 auto; min-height:64px; padding:8px 20px; box-sizing:border-box; border:0; border-radius:24px; background:#1B4F9C; color:#FFFFFF; display:flex; align-items:center; justify-content:center; gap:10px; }
    .ac-facture:hover{ background:#143A73; }
    .ac-facture .plus{ font-size:40px; font-weight:800; line-height:1; }
    .ac-facture .mot{ font-size:28px; font-weight:800; line-height:1; }
    .ac-tuile{ flex:0 0 420px; min-height:64px; padding:8px 10px; box-sizing:border-box; border-radius:24px; background:#0E1F3D; color:#FFFFFF; display:flex; align-items:center; gap:6px; }
    .ac-tuile .fl{ width:40px; height:40px; flex-shrink:0; border:0; border-radius:50%; background:rgba(255,255,255,.18); color:#FFFFFF; font-size:22px; font-weight:800; }
    .ac-tuile .fl:hover{ background:rgba(255,255,255,.3); }
    .ac-tuile .go{ flex-grow:1; min-width:0; min-height:48px; border:0; background:transparent; color:#FFFFFF; display:flex; align-items:center; justify-content:center; gap:10px; }
    .ac-tuile .go .fleche{ font-size:34px; font-weight:800; line-height:1; }
    .ac-tuile .go .txt{ display:flex; flex-direction:column; align-items:flex-start; line-height:1.05; min-width:0; }
    .ac-tuile .go .genre{ font-size:11px; font-weight:800; letter-spacing:.06em; text-transform:uppercase; opacity:.7; }
    .ac-tuile .go .lab{ font-size:28px; font-weight:800; text-align:left; }
    .ac-tuile .pos{ flex-shrink:0; min-width:40px; font-size:12px; font-weight:800; text-align:center; opacity:.75; }

    /* 2. Mon argent */
    .ac-ligne{ display:flex; flex-wrap:wrap; align-items:center; gap:8px 12px; }
    .ac-mois{ display:flex; align-items:center; gap:4px; padding:3px; background:#E8EDF5; border-radius:999px; }
    .ac-mois .fl{ width:36px; height:36px; border:0; border-radius:50%; background:#FFFFFF; color:#0E1F3D; font-size:18px; font-weight:800; }
    .ac-mois .fl:disabled{ opacity:.35; cursor:default; }
    .ac-mois select{ min-height:36px; padding:0 10px; border:0; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-weight:800; font-size:15px; font-family:inherit; }
    .ac-etiq{ padding:3px 10px; border-radius:999px; font-size:13px; font-weight:800; }
    .ac-compte{ margin-left:auto; display:flex; align-items:center; gap:4px; padding:2px 4px 2px 12px; border-radius:999px; background:#F2F5F9; border:1px solid #D5DDE8; font-size:14px; font-weight:700; color:#0E1F3D; text-decoration:none; }
    .ac-compte .oeil{ width:34px; height:30px; padding:0; border:0; background:transparent; color:#1B4F9C; display:flex; align-items:center; justify-content:center; }
    .ac-compte .solde{ margin-left:6px; font-size:15px; font-weight:800; white-space:nowrap; }
    .ac-cases{ display:flex; flex-wrap:wrap; gap:10px; align-items:stretch; }
    .ac-case{ flex:1 1 128px; min-width:0; padding:10px 12px; border-radius:16px; background:#F2F5F9; color:#0E1F3D; text-align:left; display:flex; flex-direction:column; gap:2px; text-decoration:none; }
    .ac-case:hover{ background:#E3EBF7; color:#0E1F3D; }
    .ac-case.large{ flex:1.4 1 170px; }
    .ac-case .lab{ height:34px; display:flex; align-items:flex-end; gap:6px; font-size:13px; font-weight:700; line-height:1.25; color:#44536E; }
    .ac-case .lab span{ padding-bottom:2px; }
    .ac-case .pt{ width:12px; height:12px; flex-shrink:0; margin:0 0 5px auto; border-radius:50%; }
    .ac-case .val{ height:32px; display:flex; align-items:center; font-size:20px; font-weight:800; line-height:1.15; white-space:nowrap; }
    .ac-case .sous{ font-size:13px; color:#44536E; }
    .pt-r{ background:#E35D55; } .pt-y{ background:#E3B341; }

    /* 3. Agenda */
    .ac-agtete{ display:flex; flex-wrap:wrap; align-items:center; gap:10px; }
    .ac-agtete select{ min-width:0; max-width:240px; min-height:38px; padding:0 10px; border:1px solid #AEBBCD; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-weight:800; font-size:15px; font-family:inherit; }
    .ac-pill{ flex-shrink:0; min-height:48px; padding:0 14px; border:2px solid #D5DDE8; border-radius:999px; background:#FFFFFF; color:#0E1F3D; display:flex; align-items:center; gap:8px; text-decoration:none; }
    .ac-pill:hover{ background:#F2F5F9; color:#0E1F3D; }
    .ac-pill b{ font-size:18px; }
    .ac-rdvbtn{ margin-left:auto; flex-shrink:0; min-height:64px; padding:0 22px; border:0; border-radius:999px; background:#1B4F9C; color:#FFFFFF; display:flex; align-items:center; gap:10px; }
    .ac-rdvbtn:hover{ background:#143A73; }
    .ac-rdvbtn .plus{ font-size:40px; font-weight:800; line-height:1; }
    .ac-rdvbtn .mot{ font-size:28px; font-weight:800; letter-spacing:.02em; }
    .ac-agcorps{ display:flex; flex-wrap:wrap; gap:18px; align-items:stretch; }
    .ac-jour{ flex:1.5 1 520px; min-width:0; box-sizing:border-box; padding:12px; border:1px solid #D5DDE8; border-radius:20px; display:flex; flex-direction:column; gap:8px; }
    .ac-jour .titre{ min-height:46px; display:flex; flex-direction:column; justify-content:center; }
    .ac-jour .titre b{ font-size:17px; } .ac-jour .titre span{ font-size:13px; color:#44536E; }
    .ac-rdv{ border-radius:14px; background:#F2F5F9; border-left:6px solid #1B4F9C; }
    .ac-rdv > button{ width:100%; min-height:48px; padding:8px 12px; border:0; background:transparent; color:#0E1F3D; text-align:left; display:flex; align-items:center; gap:10px; }
    .ac-rdv .h{ width:72px; flex-shrink:0; font-size:16px; font-weight:800; }
    .ac-rdv .qui{ flex-grow:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    .ac-rdv .qui b{ font-size:16px; } .ac-rdv .qui span{ font-size:14px; color:#44536E; }
    .ac-chip{ flex-shrink:0; padding:2px 8px; border-radius:999px; font-size:12px; font-weight:800; }
    .ac-ini{ flex-shrink:0; min-width:28px; height:22px; padding:0 6px; box-sizing:border-box; border-radius:999px; color:#fff; font-size:11px; font-weight:800; display:inline-flex; align-items:center; justify-content:center; }
    .ac-chev{ flex-shrink:0; font-size:16px; color:#44536E; }
    .ac-det{ padding:0 12px 12px; display:flex; flex-direction:column; gap:8px; }
    .ac-infos{ display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:6px 14px; padding:8px 10px; border-radius:12px; background:#FFFFFF; }
    .ac-infos span{ display:flex; flex-direction:column; min-width:0; }
    .ac-infos i{ font-style:normal; font-size:11px; font-weight:800; letter-spacing:.04em; text-transform:uppercase; color:#5B6B86; }
    .ac-infos b{ font-size:14px; }
    .ac-vide{ padding:16px; border-radius:16px; background:#F2F5F9; color:#44536E; font-weight:700; }
    .ac-sem{ flex:1 1 420px; min-width:0; box-sizing:border-box; padding:12px; border:1px solid #D5DDE8; border-radius:20px; display:flex; flex-direction:column; gap:10px; }
    .ac-sem .tete{ display:flex; flex-wrap:wrap; align-items:center; gap:8px; }
    .ac-sem .tete .t{ flex-grow:1; display:flex; flex-direction:column; }
    .ac-sem .tete .t b{ font-size:17px; } .ac-sem .tete .t span{ font-size:13px; color:#44536E; }
    .ac-nav{ display:flex; align-items:center; gap:4px; padding:3px; border:1px solid #D5DDE8; border-radius:999px; }
    .ac-nav a{ width:34px; height:34px; border-radius:50%; background:#F2F5F9; color:#0E1F3D; font-size:18px; font-weight:800; display:flex; align-items:center; justify-content:center; text-decoration:none; }
    .ac-nav span{ padding:0 8px; font-weight:800; font-size:14px; }
    .ac-auj{ min-height:38px; padding:0 12px; border:1px solid #D5DDE8; border-radius:999px; color:#44536E; font-weight:800; font-size:14px; display:flex; align-items:center; text-decoration:none; }
    .ac-auj:hover{ background:#F2F5F9; color:#0E1F3D; }
    .ac-jours{ display:grid; grid-template-columns:repeat(5, minmax(0, 1fr)); gap:8px; }
    .ac-j{ min-height:96px; padding:8px; border:2px solid #F2F5F9; border-radius:14px; background:#F2F5F9; color:#0E1F3D; text-align:left; display:flex; flex-direction:column; gap:6px; }
    .ac-j.sel{ background:#E3EBF7; border-color:#1B4F9C; }
    .ac-j .l1{ display:flex; align-items:center; justify-content:space-between; gap:4px; font-weight:800; font-size:15px; white-space:nowrap; }
    .ac-j .nb{ min-width:26px; height:26px; border-radius:50%; color:#fff; font-size:13px; font-weight:800; display:flex; align-items:center; justify-content:center; }
    .ac-j .marques{ display:flex; flex-wrap:wrap; gap:3px; }

    /* 4. Activités */
    .ac-acttete{ display:flex; flex-wrap:wrap; align-items:center; gap:10px 16px; }
    .ac-barre{ flex:0 1 520px; min-width:200px; display:flex; height:24px; border-radius:999px; overflow:hidden; gap:3px; }
    .ac-barre button{ border:0; color:#fff; font-size:13px; font-weight:800; min-width:28px; }
    .ac-barre .r{ background:#E35D55; } .ac-barre .y{ background:#E3B341; color:#3D2A00; } .ac-barre .a{ background:#14161A; }
    .ac-barre button.eteint{ opacity:.3; }
    .ac-legende{ display:flex; flex-wrap:wrap; gap:6px 18px; font-size:13px; font-weight:700; color:#44536E; }
    .ac-legende span{ display:inline-flex; align-items:center; gap:6px; }
    .ac-legende i{ width:10px; height:10px; border-radius:50%; display:inline-block; }
    .ac-act{ border-radius:16px; background:#F2F5F9; border-left:6px solid #E3B341; }
    .ac-act.r{ border-left-color:#E35D55; } .ac-act.a{ border-left-color:#14161A; }
    .ac-act > button{ width:100%; min-height:56px; padding:10px 14px; border:0; background:transparent; color:#0E1F3D; text-align:left; display:flex; align-items:center; gap:14px; }
    .ac-act .num{ width:30px; height:30px; flex-shrink:0; border-radius:50%; font-size:15px; font-weight:800; display:flex; align-items:center; justify-content:center; }
    .ac-act.r .num{ background:#E35D55; color:#fff; } .ac-act.y .num{ background:#E3B341; color:#3D2A00; } .ac-act.a .num{ background:#14161A; color:#fff; }
    .ac-act .corps{ flex-grow:1; min-width:0; display:flex; flex-direction:column; }
    .ac-act .corps b{ font-size:17px; } .ac-act .corps span{ font-size:14px; color:#44536E; }
    .ac-act .fait{ font-size:13px; font-weight:800; color:#0F5A3A; white-space:nowrap; }
    .ac-act .det{ padding:0 14px 14px 58px; display:flex; flex-wrap:wrap; align-items:center; gap:10px; }
    .ac-act .det p{ margin:0; flex:1 1 300px; font-size:14px; }

    /* Le rappel flottant « N choses à regarder » */
    .ac-flottant{ position:fixed; right:24px; bottom:24px; z-index:30; display:flex; align-items:center; gap:10px; padding:8px 18px 8px 8px; border:0; border-radius:999px; background:#0E1F3D; color:#FFFFFF; font-size:16px; font-weight:800; box-shadow:0 10px 30px rgba(14,31,61,.35); }

    @media (max-width: 1280px){
        .ac-haut{ flex-wrap:wrap; }
        .ac-60{ flex:1 1 100%; }
        .ac-tuile{ flex:1 1 380px; }
    }
    @media (max-width: 640px){
        .ac-tuile .go .lab, .ac-facture .mot{ font-size:22px; }
                .ac-flottant{ right:12px; bottom:12px; }
        .ac-act .det{ padding-left:14px; }
        .ac-case{ flex:1 1 120px; }
        .ac-rdv .h{ width:52px; font-size:15px; }
        .ac-rdv .ac-chip.lieu, .ac-rdv .ac-ini{ display:none; }
        .ac-j{ min-height:72px; padding:6px; }
        .ac-j .l1{ flex-direction:column; align-items:flex-start; font-size:13px; }
        .ac-j .nb{ min-width:22px; height:22px; font-size:12px; }
        .ac-jours{ grid-template-columns:repeat(5, minmax(0, 1fr)); gap:4px; overflow:visible; }
        .ac-j .marques{ display:none; }
    }
</style>

<main class="home-page">
    <div class="ac" id="acAccueil" aria-live="polite"></div>
</main>

<%-- Fenêtres : nouvelle facture (même RadWindow que la liste des factures clients) et rendez-vous --%>
<telerik:RadWindow ID="rwInvoice" runat="server"
    Modal="true"
    VisibleOnPageLoad="false"
    Behaviors="Close,Move,Resize"
    DestroyOnClose="true"
    Title="Facture"
    OnClientClose="rwInvoice_OnClose"
    ClientIDMode="Static">
</telerik:RadWindow>
<telerik:RadWindow ID="rwRdv" runat="server"
    Modal="true"
    VisibleOnPageLoad="false"
    Behaviors="Close,Move,Resize"
    DestroyOnClose="true"
    Title="Rendez-vous"
    OnClientClose="rwInvoice_OnClose"
    ClientIDMode="Static">
</telerik:RadWindow>

<script src="js/RadWindows.js"></script>
<script type="text/javascript">
    var L_ADD_INVOICE = "<%= L("winAddInvoice") %>";
    var L_EDIT_INVOICE = "<%= L("winEditInvoice") %>";
    // Après fermeture d'une fenêtre (facture, rendez-vous), recharger le tableau de bord.
    function rwInvoice_OnClose(sender, args) {
        window.location.reload();
    }
    function acNouvelleFacture() {
        openRadWindow(0, 'rwInvoice', 'wbfInvoiceEdit.aspx', L_EDIT_INVOICE, L_ADD_INVOICE);
    }
    function acOuvrirRdv(url, titre) {
        var w = $find('rwRdv'); if (!w) { window.location.href = 'wbfAgenda.aspx'; return; }
        w.set_title(titre || '');
        w.set_width(Math.min(window.innerWidth - 20, 1300));
        w.set_height(window.innerWidth < 768 ? window.innerHeight - 20 : Math.min(window.innerHeight - 40, 720));
        w.setUrl(url); w.show(); w.center();
    }
</script>

<script type="text/javascript">
(function () {
    var M = <%= ModeleJson %>;
    var racine = document.getElementById('acAccueil');
    if (!M || !racine) return;
    var T = M.t;
    var CLE = '60s-accueil-choix';
    var choix = {};
    try { choix = JSON.parse(window.localStorage.getItem(CLE) || '{}') || {}; } catch (e) { choix = {}; }
    function garder(k, v) { choix[k] = v; try { window.localStorage.setItem(CLE, JSON.stringify(choix)); } catch (e) { } }

    // --- petits outils ---
    function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
    function fmt(s) { var a = arguments; return String(s).replace(/\{(\d)\}/g, function (m, i) { return a[+i + 1]; }); }
    function svg60(fill, taille) {
        var n = 'http://www.w3.org/2000/svg', s = document.createElementNS(n, 'svg');
        s.setAttribute('width', taille); s.setAttribute('height', taille); s.setAttribute('viewBox', '0 0 256 256'); s.setAttribute('aria-hidden', 'true');
        s.innerHTML = '<circle cx="128" cy="128" r="112" fill="' + fill + '" stroke="#D9A03C" stroke-width="16"></circle><circle cx="96" cy="120" r="16" fill="none" stroke="#0E1F3D" stroke-width="13"></circle><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#0E1F3D" stroke-width="13" stroke-linecap="round"></path><ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#0E1F3D" stroke-width="13"></ellipse><path d="M99 166 q29 16 58 0" fill="none" stroke="#0E1F3D" stroke-width="11" stroke-linecap="round"></path>';
        return s;
    }
    var OEIL = '<svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"></path></svg>';
    var BANQUE = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#44536E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10h18M5 10v8M9 10v8M15 10v8M19 10v8M2 21h20M12 3l9 5H3z"></path></svg>';
    var BULLE = '<svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1B4F9C" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16v11H8l-4 4z"></path></svg>';

    var acts = M.activites || [];
    var nR = acts.filter(function (a) { return a.u === 'r'; }).length;
    var nY = acts.filter(function (a) { return a.u === 'y'; }).length;
    var nA = acts.filter(function (a) { return a.u === 'a'; }).length;
    var prio = acts.filter(function (a) { return a.u !== 'a'; })[0];

    // =================== 1. L'essentiel ===================
    var haut = el('div', 'ac-haut');
    var f60 = el('section', 'ac-60'); f60.setAttribute('aria-label', T.assistant60);
    var coul = nR ? '#E35D55' : (nY ? '#E3B341' : '#43B47A');
    f60.style.borderColor = coul;
    var salut = el('div', 'salut'); salut.appendChild(svg60(coul, 36));
    var sw = el('div'); sw.style.cssText = 'display:flex;flex-wrap:wrap;align-items:center;gap:8px 12px';
    sw.appendChild(el('h1', '', M.prenom ? fmt(T.bonjourNom, M.prenom) : T.bonjour));
    var glob = el('span', 'ac-pastille', nR ? (nR === 1 ? T.gUrgent1 : fmt(T.gUrgentN, nR)) : (nY ? T.gVeille : T.gOk));
    glob.style.background = nR ? '#FDECEA' : (nY ? '#FBF1DC' : '#E3F3EA');
    glob.style.color = nR ? '#A3261C' : (nY ? '#7A5200' : '#0F5A3A');
    sw.appendChild(glob); salut.appendChild(sw); f60.appendChild(salut);
    if (prio) {
        var bp = el('div', 'ac-prio'), q = el('div', 'quoi');
        var eti = el('span', 'eti', T.enPremier + ' · '); eti.style.color = prio.u === 'r' ? '#A3261C' : '#7A5200';
        q.appendChild(eti); var tb = el('b', '', prio.t); tb.style.fontSize = '15px'; q.appendChild(tb);
        q.appendChild(el('span', 'sous', ' — ' + prio.d)); bp.appendChild(q);
        var go = el('a', 'ac-btn', prio.btn); go.href = prio.url; bp.appendChild(go);
        var af = el('span', 'ac-afaire'); af.appendChild(el('b', '', T.aFaire));
        [['r', nR, T.indR], ['y', nY, T.indY]].forEach(function (x) {
            var b = el('button', 'ac-rond ' + x[0] + (x[1] ? '' : ' vide'), String(x[1])); b.type = 'button';
            b.title = fmt(x[2], x[1]); b.setAttribute('aria-label', b.title);
            b.addEventListener('click', function () { filtrer(x[0]); allerActivites(); });
            af.appendChild(b);
        });
        bp.appendChild(af); f60.appendChild(bp);
    } else {
        f60.appendChild(el('div', 'ac-ok', T.rienUrgent));
    }
    haut.appendChild(f60);

    var bf = el('button', 'ac-facture'); bf.type = 'button';
    bf.appendChild(el('span', 'plus', '+')); bf.appendChild(el('span', 'mot', T.factureBtn));
    bf.addEventListener('click', acNouvelleFacture); haut.appendChild(bf);

    var tuile = el('div', 'ac-tuile'); tuile.setAttribute('role', 'group'); tuile.setAttribute('aria-label', T.autresFct);
    var ti = Math.max(0, Math.min((M.tuile || []).length - 1, +choix.qi || 0));
    var bPrec = el('button', 'fl', '‹'); bPrec.type = 'button'; bPrec.setAttribute('aria-label', T.fctPrec);
    var bGo = el('button', 'go'); bGo.type = 'button';
    var bSuiv = el('button', 'fl', '›'); bSuiv.type = 'button'; bSuiv.setAttribute('aria-label', T.fctSuiv);
    var pos = el('span', 'pos'); pos.setAttribute('aria-hidden', 'true');
    function peindreTuile() {
        var n = M.tuile[ti]; bGo.innerHTML = '';
        bGo.appendChild(el('span', 'fleche', '→'));
        var tx = el('span', 'txt'); tx.appendChild(el('span', 'genre', T.allerA)); tx.appendChild(el('span', 'lab', n.lab)); bGo.appendChild(tx);
        bGo.setAttribute('aria-label', T.allerA + ' ' + n.lab);
        pos.textContent = (ti + 1) + ' / ' + M.tuile.length;
    }
    bPrec.addEventListener('click', function () { ti = (ti - 1 + M.tuile.length) % M.tuile.length; garder('qi', ti); peindreTuile(); });
    bSuiv.addEventListener('click', function () { ti = (ti + 1) % M.tuile.length; garder('qi', ti); peindreTuile(); });
    bGo.addEventListener('click', function () {
        var n = M.tuile[ti];
        if (n.fen && window.ouvrirFenetreApp) { ouvrirFenetreApp(n.url, n.lab); } else { window.location.href = n.url; }
    });
    tuile.appendChild(bPrec); tuile.appendChild(bGo); tuile.appendChild(bSuiv); tuile.appendChild(pos);
    if (M.tuile && M.tuile.length) { peindreTuile(); haut.appendChild(tuile); }
    racine.appendChild(haut);

    // =================== 2. Mon argent ===================
    var arg = el('section', 'ac-carte');
    var la = el('div', 'ac-ligne'); la.appendChild(el('h2', '', T.monArgent));
    var opts = M.mois.options, iMois = 0;
    opts.forEach(function (o, i) { if (o.v === M.mois.val) iMois = i; });
    var mo = el('div', 'ac-mois');
    function allerMois(v) { var u = new URL(window.location.href); u.searchParams.set('mois', v); window.location.href = u.toString(); }
    var mp = el('button', 'fl', '‹'); mp.type = 'button'; mp.setAttribute('aria-label', T.moisPrec);
    mp.disabled = iMois >= opts.length - 1; mp.addEventListener('click', function () { allerMois(opts[iMois + 1].v); });
    var sel = el('select'); sel.setAttribute('aria-label', T.moisAffiche);
    opts.forEach(function (o) { var op = el('option', '', o.lab); op.value = o.v; if (o.v === M.mois.val) op.selected = true; sel.appendChild(op); });
    sel.addEventListener('change', function () { allerMois(sel.value); });
    var ms = el('button', 'fl', '›'); ms.type = 'button'; ms.setAttribute('aria-label', T.moisSuiv);
    ms.disabled = iMois === 0; ms.addEventListener('click', function () { allerMois(opts[iMois - 1].v); });
    mo.appendChild(mp); mo.appendChild(sel); mo.appendChild(ms); la.appendChild(mo);
    var tag = el('span', 'ac-etiq', M.mois.courant ? T.moisCourant : T.moisPasse);
    tag.style.background = M.mois.courant ? '#E3EBF7' : '#E8EDF5'; tag.style.color = M.mois.courant ? '#143A73' : '#44536E';
    la.appendChild(tag);
    var cpt = el('span', 'ac-compte'); cpt.innerHTML = BANQUE; cpt.appendChild(document.createTextNode(M.banque.lib));
    if (M.banque.aCompte) {
        var solde = el('b', 'solde', '· ' + M.banque.solde); solde.hidden = !choix.bqV; cpt.appendChild(solde);
        var oe = el('button', 'oeil'); oe.type = 'button'; oe.innerHTML = OEIL;
        var peindreOeil = function () { var t = solde.hidden ? T.voirMontant : T.masquerMontant; oe.title = t; oe.setAttribute('aria-label', t); };
        oe.addEventListener('click', function () { solde.hidden = !solde.hidden; garder('bqV', !solde.hidden); peindreOeil(); });
        peindreOeil(); cpt.appendChild(oe);
    }
    la.appendChild(cpt); arg.appendChild(la);
    var cases = el('div', 'ac-cases');
    (M.argent || []).forEach(function (k, i) {
        var a = el('a', 'ac-case' + (i === M.argent.length - 1 ? ' large' : '')); a.href = k.url;
        var lab = el('span', 'lab'); lab.appendChild(el('span', '', k.lab));
        if (k.dot) { var p = el('span', 'pt pt-' + k.dot); p.setAttribute('role', 'img'); lab.appendChild(p); }
        a.appendChild(lab); a.appendChild(el('span', 'val', k.val)); a.appendChild(el('span', 'sous', k.sous));
        cases.appendChild(a);
    });
    arg.appendChild(cases);
    arg.appendChild(el('span', 'ac-note', T.noteArgent));
    racine.appendChild(arg);

    // =================== 3. Agenda ===================
    var A = M.agenda || { emps: [], jours: [], rdv: [] };
    var ag = el('section', 'ac-carte');
    var at = el('div', 'ac-agtete'); at.appendChild(el('h2', '', T.agenda));
    var se = el('select'); se.setAttribute('aria-label', T.agendaDe);
    var o0 = el('option', '', T.equipe); o0.value = ''; se.appendChild(o0);
    A.emps.forEach(function (e) { var o = el('option', '', e.lab); o.value = e.v; se.appendChild(o); });
    var empSel = choix.agEmp || '';
    if (!A.emps.some(function (e) { return e.v === empSel; })) empSel = '';
    se.value = empSel;
    se.addEventListener('change', function () { empSel = se.value; garder('agEmp', empSel); peindreAgenda(); });
    at.appendChild(se);
    var msg = el('a', 'ac-pill'); msg.href = 'wbfMailbox.aspx'; msg.innerHTML = BULLE; msg.appendChild(el('b', '', T.messages));
    at.appendChild(msg);
    var br = el('button', 'ac-rdvbtn'); br.type = 'button'; br.setAttribute('aria-label', T.ajouterRdv);
    br.appendChild(el('span', 'plus', '+')); br.appendChild(el('span', 'mot', T.rdvBtn));
    br.addEventListener('click', function () {
        var j = jourSel || A.aujourdhui;
        acOuvrirRdv('wbfAppointmentEdit.aspx?id=0&start=' + encodeURIComponent(j + 'T09:00:00'), T.winRdv);
    });
    at.appendChild(br); ag.appendChild(at);

    var corps = el('div', 'ac-agcorps'); var colJour = el('div', 'ac-jour'); var colSem = el('div', 'ac-sem');
    corps.appendChild(colJour); corps.appendChild(colSem); ag.appendChild(corps);
    racine.appendChild(ag);

    var jourSel = A.jours.some(function (j) { return j.auj; }) ? A.aujourdhui : (A.jours[0] ? A.jours[0].v : '');
    var ouverts = {};
    function rdvDu(j) {
        return A.rdv.filter(function (r) { return r.jour === j && (!empSel || r.emp === empSel); })
                    .sort(function (a, b) { return a.tri < b.tri ? -1 : 1; });
    }
    function nbRdv(n) { return n === 0 ? T.agLibre : (n === 1 ? T.agRdv1 : fmt(T.agRdvN, n)); }
    function chipEtat(r) {
        var c = r.etat === 'termine' ? ['#E3F3EA', '#0F5A3A', T.stTermine] : (r.etat === 'encours' ? ['#E3EBF7', '#143A73', T.stEnCours] : ['#FFFFFF', '#44536E', T.stAVenir]);
        var s = el('span', 'ac-chip', c[2]); s.style.background = c[0]; s.style.color = c[1]; return s;
    }
    function peindreAgenda() {
        colJour.innerHTML = ''; colSem.innerHTML = '';
        var jd = A.jours.filter(function (j) { return j.v === jourSel; })[0] || A.jours[0];
        var liste = rdvDu(jourSel);
        var tt = el('div', 'titre');
        tt.appendChild(el('b', '', (jd && jd.auj ? T.agAuj + ' · ' : '') + (jd ? jd.libLong : '')));
        tt.appendChild(el('span', '', nbRdv(liste.length)));
        colJour.appendChild(tt);
        if (!liste.length) colJour.appendChild(el('div', 'ac-vide', T.agVide));
        liste.forEach(function (r) {
            var boite = el('div', 'ac-rdv'); boite.style.borderLeftColor = r.c;
            var b = el('button'); b.type = 'button'; b.setAttribute('aria-expanded', ouverts[r.id] ? 'true' : 'false');
            b.appendChild(el('b', 'h', r.h));
            var qui = el('span', 'qui'); qui.appendChild(el('b', '', r.client)); if (r.court) qui.appendChild(el('span', '', ' · ' + r.court)); b.appendChild(qui);
            if (!empSel && r.ini) { var ini = el('span', 'ac-ini', r.ini); ini.style.background = r.c; ini.title = r.empNom; b.appendChild(ini); }
            if (r.lieu) { var li = el('span', 'ac-chip lieu', r.lieu); li.style.background = '#FBF1DC'; li.style.color = '#7A5200'; b.appendChild(li); }
            b.appendChild(chipEtat(r));
            b.appendChild(el('span', 'ac-chev', ouverts[r.id] ? '▴' : '▾'));
            b.addEventListener('click', function () { ouverts[r.id] = !ouverts[r.id]; peindreAgenda(); });
            boite.appendChild(b);
            if (ouverts[r.id]) {
                var det = el('div', 'ac-det');
                if (r.desc) det.appendChild(el('span', '', r.desc));
                var inf = el('div', 'ac-infos');
                [[T.iHeure, r.plage], [T.iEmploye, r.empNom], [T.iType, r.typ], [T.iLieu, r.lieu]].forEach(function (x) {
                    if (!x[1]) return; var s = el('span'); s.appendChild(el('i', '', x[0])); s.appendChild(el('b', '', x[1])); inf.appendChild(s);
                });
                det.appendChild(inf);
                var ob = el('button', 'ac-btn clair', T.ouvrirRdv); ob.type = 'button'; ob.style.alignSelf = 'flex-start';
                ob.addEventListener('click', function () { acOuvrirRdv('wbfAppointmentEdit.aspx?id=' + r.id, T.winRdv); });
                det.appendChild(ob); boite.appendChild(det);
            }
            colJour.appendChild(boite);
        });

        var tete = el('div', 'tete'); var t = el('span', 't');
        t.appendChild(el('b', '', A.titre)); t.appendChild(el('span', '', T.agSemSous)); tete.appendChild(t);
        var nav = el('span', 'ac-nav');
        function lienSem(d, txt, aria) { var u = new URL(window.location.href); u.searchParams.set('sem', A.sem + d); var a = el('a', '', txt); a.href = u.toString(); a.setAttribute('aria-label', aria); return a; }
        nav.appendChild(lienSem(-1, '‹', T.semPrec)); nav.appendChild(el('span', '', T.semaine)); nav.appendChild(lienSem(1, '›', T.semSuiv));
        tete.appendChild(nav);
        var ua = new URL(window.location.href); ua.searchParams.delete('sem');
        var auj = el('a', 'ac-auj', T.agAuj); auj.href = ua.toString(); tete.appendChild(auj);
        colSem.appendChild(tete);
        var grille = el('div', 'ac-jours');
        A.jours.forEach(function (j) {
            var l = rdvDu(j.v);
            var b = el('button', 'ac-j' + (j.v === jourSel ? ' sel' : '')); b.type = 'button';
            b.setAttribute('aria-pressed', j.v === jourSel ? 'true' : 'false'); b.setAttribute('aria-label', j.libLong + ' : ' + nbRdv(l.length));
            var l1 = el('span', 'l1'); l1.appendChild(el('span', '', j.court));
            var nb = el('span', 'nb', String(l.length)); nb.style.background = l.length ? '#0E1F3D' : '#AEBBCD'; l1.appendChild(nb); b.appendChild(l1);
            var mq = el('span', 'marques'), vus = {};
            l.forEach(function (r) { if (!r.ini || vus[r.emp]) return; vus[r.emp] = 1; var m = el('span', 'ac-ini', r.ini); m.style.background = r.c; m.title = r.empNom; mq.appendChild(m); });
            b.appendChild(mq);
            b.addEventListener('click', function () { jourSel = j.v; peindreAgenda(); });
            grille.appendChild(b);
        });
        colSem.appendChild(grille);
    }
    peindreAgenda();

    // =================== 4. Activités à faire ===================
    var sec = el('section', 'ac-carte'); sec.id = 'activites-a-faire';
    var tA = el('div', 'ac-acttete');
    var h = el('h2', '', T.activites + ' '); var hn = el('span', '', '(' + acts.length + ')'); hn.style.color = '#44536E'; h.appendChild(hn); tA.appendChild(h);
    var barre = el('div', 'ac-barre'); tA.appendChild(barre); sec.appendChild(tA);
    var leg = el('div', 'ac-legende');
    [['#E35D55', T.lRouge], ['#E3B341', T.lJaune], ['#14161A', T.lNoir]].forEach(function (x) { var s = el('span'); var i = el('i'); i.style.background = x[0]; s.appendChild(i); s.appendChild(document.createTextNode(x[1])); leg.appendChild(s); });
    sec.appendChild(leg);
    var liste = el('div'); liste.style.cssText = 'display:flex;flex-direction:column;gap:8px'; sec.appendChild(liste);
    racine.appendChild(sec);

    var filtre = '', actOuv = {};
    function filtrer(u) { filtre = (filtre === u ? '' : u); peindreActivites(); }
    function allerActivites() { try { sec.scrollIntoView({ behavior: 'smooth', block: 'start' }); } catch (e) { sec.scrollIntoView(); } }
    function peindreActivites() {
        barre.innerHTML = ''; liste.innerHTML = '';
        [['r', nR], ['y', nY], ['a', nA]].forEach(function (x) {
            if (!x[1]) return;
            var b = el('button', x[0] + (filtre && filtre !== x[0] ? ' eteint' : ''), String(x[1])); b.type = 'button';
            b.style.flexGrow = x[1]; b.setAttribute('aria-pressed', filtre === x[0] ? 'true' : 'false');
            b.addEventListener('click', function () { filtrer(x[0]); });
            barre.appendChild(b);
        });
        barre.hidden = !acts.length;
        if (!acts.length) { liste.appendChild(el('div', 'ac-vide', T.toutFait)); return; }
        var n = 0;
        acts.forEach(function (a, i) {
            if (a.u !== 'a') n++;
            if (filtre && a.u !== filtre) return;
            var boite = el('div', 'ac-act ' + a.u);
            var b = el('button'); b.type = 'button'; b.setAttribute('aria-expanded', actOuv[i] ? 'true' : 'false');
            b.appendChild(el('span', 'num', a.u === 'a' ? '✓' : String(n)));
            var c = el('span', 'corps'); c.appendChild(el('b', '', a.t)); c.appendChild(el('span', '', a.d)); b.appendChild(c);
            if (a.u === 'a') b.appendChild(el('span', 'fait', '✓ ' + T.faitPar60));
            b.appendChild(el('span', 'ac-chev', actOuv[i] ? '▴' : '▾'));
            b.addEventListener('click', function () { actOuv[i] = !actOuv[i]; peindreActivites(); });
            boite.appendChild(b);
            if (actOuv[i]) {
                var d = el('div', 'det'); d.appendChild(el('p', '', a.det));
                if (a.btn && a.url) { var go = el('a', 'ac-btn', a.btn); go.href = a.url; d.appendChild(go); }
                boite.appendChild(d);
            }
            liste.appendChild(boite);
        });
        if (filtre) {
            var tout = el('button', 'ac-btn clair', T.tous); tout.type = 'button'; tout.style.alignSelf = 'flex-start';
            tout.addEventListener('click', function () { filtrer(''); }); liste.appendChild(tout);
        }
    }
    peindreActivites();

    // =================== Le rappel flottant ===================
    var aRegarder = nR + nY;
    if (aRegarder > 0) {
        var fl = el('button', 'ac-flottant'); fl.type = 'button';
        fl.appendChild(svg60(nR ? '#E35D55' : '#E3B341', 40));
        fl.appendChild(document.createTextNode(aRegarder === 1 ? T.choses1 : fmt(T.chosesN, aRegarder)));
        fl.addEventListener('click', allerActivites);
        document.body.appendChild(fl);
        // Il s'efface quand les activités sont à l'écran.
        if ('IntersectionObserver' in window) {
            new IntersectionObserver(function (e) { fl.style.display = e[0].isIntersecting ? 'none' : 'flex'; }).observe(sec);
        }
    }
})();
</script>

<%-- Connexion en fenêtre : quand personne n'est connecté, la page de connexion
     (wbfLogin.aspx?popup=1) s'ouvre dans un cadre par-dessus le tableau de bord,
     qui reste flou derrière. Pas de bouton Fermer : sans connexion, rien ne marche.
     Une fois connecté, la page de connexion recharge la fenêtre entière. --%>
<% If AfficherConnexion Then %>
<style>
    .cx-fond{ position:fixed; inset:0; z-index:100000; display:flex; align-items:center; justify-content:center; padding:16px;
              background:rgba(14,31,61,.45); -webkit-backdrop-filter:blur(6px); backdrop-filter:blur(6px); }
    .cx-cadre{ display:block; width:430px; max-width:100%; height:520px; max-height:calc(100vh - 32px);
               border:0; border-radius:20px; background:#fff; box-shadow:0 20px 50px rgba(15,23,42,.30); }
    .home-page{ visibility:hidden; }
</style>
<div class="cx-fond" role="dialog" aria-modal="true" aria-label="<%= L("loginTitle") %>">
    <iframe id="cxCadre" class="cx-cadre" src="<%= UrlConnexion %>" title="<%= L("loginTitle") %>"></iframe>
</div>
<script type="text/javascript">
    (function () {
        // La page derrière ne défile pas tant que la fenêtre est ouverte.
        document.documentElement.style.overflow = 'hidden';
        var cadre = document.getElementById('cxCadre');
        // Le cadre prend la hauteur de la carte de connexion (elle grandit avec un message d'erreur).
        function ajuster() {
            try {
                var d = cadre.contentWindow.document;
                var carte = d.querySelector('.login-card');
                cadre.style.height = (carte ? carte.offsetHeight : d.documentElement.scrollHeight) + 'px';
            } catch (e) { }
        }
        cadre.addEventListener('load', function () {
            ajuster();
            try { cadre.contentWindow.focus(); } catch (e) { }
        });
        window.addEventListener('resize', ajuster);
    })();
</script>
<% End If %>
</asp:Content>
