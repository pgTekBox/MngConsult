<%@ Page Title="Home Page" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.vb" Inherits="MngConsul._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
<%-- Le tableau de bord, au modèle de la page d'accueil 60secondes du 21 octobre
     (60secondes-plateforme-complete-page-premiere-21-oct.html) :
     1. la fenêtre de 60 : bonjour, « En premier », Activité à faire, Messages,
        Revenu en retard, Paiements en retard, compte d'opérations ;
     2. l'Agenda : Aujourd'hui (plages libres, RDV, Facturer, + RDV) et À venir ;
     3. les Activités à faire (rouge, jaune) ; 60 se rend sur l'enjeu prioritaire.
     Le serveur calcule le modèle (vraies données, Default.aspx.vb) ; le script
     ci-dessous le dessine et gère les clics. Couleurs : rouge #E35D55 / #A3261C,
     jaune #E3B341 / #7A5200, vert #43B47A / #0F5A3A, or #D9A03C. --%>
<style>
    .ac{ font-family:Nunito, system-ui, sans-serif; color:#0E1F3D; font-size:16px; line-height:1.45; display:flex; flex-direction:column; gap:16px; }
    .ac button{ font-family:inherit; cursor:pointer; }
    .ac h2{ margin:0; font-size:16px; font-weight:800; }
    .ac-carte{ padding:18px; border-radius:24px; background:#FFFFFF; display:flex; flex-direction:column; gap:12px; }
    .ac-vide{ padding:16px; border-radius:16px; background:#F2F5F9; color:#44536E; font-weight:700; }
    .ac-btn{ min-height:44px; padding:0 18px; border:1px solid #1B4F9C; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-weight:800; font-size:15px; text-decoration:none; display:inline-flex; align-items:center; }
    .ac-btn:hover{ background:#143A73; color:#fff; }
    .ac-btn.clair{ background:#FFFFFF; color:#0E1F3D; border-color:#AEBBCD; }
    .ac-btn.clair:hover{ background:#F2F5F9; color:#0E1F3D; }
    .ac-chev{ flex-shrink:0; width:36px; height:36px; padding:0; border:1px solid #D5DDE8; border-radius:50%; background:#FFFFFF; color:#44536E; font-size:15px; font-weight:800; }
    .ac-chip{ flex-shrink:0; padding:2px 8px; border-radius:999px; font-size:12px; font-weight:800; white-space:nowrap; }
    .ac-rond{ min-width:24px; height:24px; padding:0 5px; box-sizing:border-box; border:0; border-radius:999px; font-size:13px; font-weight:800; display:flex; align-items:center; justify-content:center; }
    .ac-rond.r{ background:#E35D55; color:#FFFFFF; } .ac-rond.y{ background:#E3B341; color:#3D2A00; }
    .ac-rond.vide{ opacity:.35; }

    /* 1. La fenêtre de 60 */
    .ac-60{ display:flex; flex-wrap:wrap; align-items:center; gap:8px 10px; padding:8px 14px; border-radius:18px; background:#FFFFFF; border:3px solid #43B47A; }
    .ac-60 .salut{ flex:1 1 240px; min-width:240px; display:flex; align-items:center; gap:10px; }
    .ac-60 .col{ flex:1 1 auto; min-width:0; display:flex; flex-direction:column; gap:2px; }
    .ac-60 h1{ margin:0; font-size:17px; font-weight:800; line-height:1.15; white-space:nowrap; }
    .ac-60 .prio{ min-width:0; max-width:100%; padding:0; border:0; background:transparent; color:#0E1F3D; text-align:left; font-size:14px; line-height:1.3; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .ac-60 .prio .eti{ font-size:11px; font-weight:800; text-transform:uppercase; }
    .ac-60 .prio .sous{ color:#44536E; }
    .ac-60 .ok{ font-size:14px; font-weight:800; color:#0F5A3A; white-space:nowrap; }
    .ac-pills{ flex:0 1 auto; margin-left:auto; display:flex; flex-wrap:wrap; justify-content:flex-end; align-items:center; gap:8px; }
    .ac-pill{ flex-shrink:0; min-height:44px; box-sizing:border-box; padding:0 9px; border:2px solid #D5DDE8; border-radius:999px; background:#FFFFFF; color:#0E1F3D; display:flex; align-items:center; gap:4px; white-space:nowrap; text-decoration:none; }
    .ac-pill:hover{ color:#0E1F3D; background:#F7F9FC; }
    .ac-pill b{ font-size:14px; }
    .ac-pill .chv{ padding:0 4px; color:#44536E; }
    .ac-pill.dem{ padding:0 9px 0 12px; gap:6px; border-color:#E35D55; }
    .ac-pill.mt{ padding:2px 10px; flex-direction:column; align-items:flex-start; justify-content:center; gap:0; line-height:1.1; }
    .ac-pill.mt span{ font-size:12px; font-weight:800; color:#0E1F3D; }
    .ac-pill.mt.actif{ border-color:#E35D55; color:#A3261C; }
    .ac-pill.mt:not(.actif){ color:#44536E; }
    .ac-pill.cpt{ padding:2px 2px 2px 10px; background:#F2F5F9; }
    .ac-pill.cpt .txt{ display:flex; flex-direction:column; line-height:1.1; }
    .ac-pill.cpt .txt span{ font-size:12px; font-weight:800; color:#44536E; }
    .ac-pill.cpt .solde{ margin-left:4px; font-size:15px; }
    .ac-oeil{ width:34px; height:30px; padding:0; border:0; background:transparent; color:#1B4F9C; display:flex; align-items:center; justify-content:center; }
    .ac-brancher{ margin-left:6px; padding:4px 10px; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-size:12px; font-weight:800; text-decoration:none; }
    .ac-brancher:hover{ color:#fff; background:#143A73; }
    .a60-btn{ width:65px; height:65px; flex-shrink:0; padding:0; border:0; border-radius:50%; background:transparent; display:flex; align-items:center; justify-content:center; transition:transform .15s; animation:a60-bouge 7s ease-in-out infinite; transform-origin:50% 90%; }
    .a60-btn:hover{ transform:scale(1.08); animation-play-state:paused; }
    .a60-btn:focus-visible{ outline:3px solid #D9A03C; outline-offset:2px; }
    .a60-btn svg{ animation:a60-pouls 2.4s ease-in-out infinite; }
    .a60-parti{ width:65px; height:65px; flex-shrink:0; padding:0; border:2px dashed #AEBBCD; border-radius:50%; background:#F7F9FC; color:#8D9CB3; font-size:12px; font-weight:800; }
    @keyframes a60-bouge{ 0%,78%,100%{transform:none} 81%{transform:translateY(-8px) rotate(-10deg)} 84%{transform:translateY(0) rotate(9deg)} 87%{transform:translateY(-5px) rotate(-7deg)} 90%{transform:rotate(5deg)} 93%{transform:none} }
    @keyframes a60-pouls{ 0%,100%{transform:scale(1)} 50%{transform:scale(1.06)} }
    .a60-arrive{ display:flex; align-items:flex-start; gap:12px; padding:12px 14px; border-radius:18px; background:#FFFFFF; border:2px solid #D9A03C; box-shadow:0 10px 26px rgba(14,31,61,.16); animation:a60-arrive .45s cubic-bezier(.2,.9,.3,1.3); }
    .a60-arrive .txt{ flex-grow:1; display:flex; flex-direction:column; gap:4px; font-size:15px; }
    .a60-arrive .txt span:last-child{ font-size:13px; color:#44536E; }
    .a60-arrive button{ flex-shrink:0; min-height:38px; padding:0 14px; border:1px solid #AEBBCD; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-weight:800; font-size:13px; }
    @keyframes a60-arrive{ from{opacity:0; transform:translateY(-24px) scale(.9)} to{opacity:1; transform:none} }
    @media (prefers-reduced-motion:reduce){ .a60-btn, .a60-btn svg, .a60-arrive{ animation:none; } }

    /* 2. L'agenda */
    .ac-bloc{ box-sizing:border-box; padding:12px; border:1px solid #D5DDE8; border-radius:20px; display:flex; flex-direction:column; gap:8px; }
    .ac-btete{ display:flex; flex-wrap:wrap; align-items:center; gap:8px 14px; }
    .ac-btete .titre{ flex-shrink:0; min-height:46px; display:flex; flex-direction:column; justify-content:center; }
    .ac-btete .titre b{ font-size:16px; } .ac-btete .titre span{ font-size:13px; color:#44536E; }
    .ac-libres{ flex:1 1 0; min-width:0; padding-left:14px; border-left:1px solid #E3E9F1; display:flex; flex-wrap:wrap; align-items:center; gap:6px 8px; }
    .ac-libres select{ min-width:0; max-width:230px; min-height:38px; padding:0 10px; border:1px solid #AEBBCD; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-weight:800; font-size:15px; font-family:inherit; }
    .ac-libres .chips{ display:flex; flex-wrap:wrap; align-items:center; gap:4px; min-width:0; }
    .ac-libres .chips button{ min-height:26px; padding:0 6px; border:1.5px solid #43B47A; border-radius:999px; background:#FFFFFF; color:#0F5A3A; font-size:12px; font-weight:800; white-space:nowrap; }
    .ac-libres .chips button:hover{ background:#E3F3EA; }
    .ac-libres .chips span{ font-size:12px; color:#44536E; }
    .ac-agbtn{ margin-left:auto; min-height:40px; padding:0 14px; flex-shrink:0; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-size:15px; font-weight:800; display:flex; align-items:center; gap:8px; text-decoration:none; }
    .ac-agbtn:hover{ background:#143A73; color:#fff; }
    .ac-onglets{ display:flex; flex-wrap:wrap; gap:6px; }
    .ac-onglets button{ min-height:34px; padding:0 12px; border:1px solid #D5DDE8; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-size:13px; font-weight:800; white-space:nowrap; }
    .ac-onglets button[aria-selected="true"]{ background:#0E1F3D; border-color:#0E1F3D; color:#FFFFFF; }
    .ac-btete .ac-chev{ margin-left:auto; }
    .ac-btete .ac-agbtn + .ac-chev{ margin-left:0; }
    .ac-groupe{ display:flex; align-items:baseline; gap:8px; padding:6px 2px 0; }
    .ac-groupe b{ font-size:14px; } .ac-groupe span{ font-size:12px; color:#44536E; }
    .ac-rdv{ border-radius:14px; background:#F2F5F9; border-left:6px solid #AEBBCD; }
    .ac-rdv .ligne{ display:flex; align-items:center; gap:8px; padding-right:8px; }
    .ac-rdv .main{ flex:1 1 auto; min-width:0; min-height:48px; padding:8px 0 8px 12px; border:0; background:transparent; color:#0E1F3D; text-align:left; display:flex; align-items:center; gap:10px; }
    .ac-rdv .h{ width:64px; flex-shrink:0; font-size:16px; font-weight:800; }
    .ac-rdv .qui{ flex-grow:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    .ac-rdv .qui b{ font-size:16px; } .ac-rdv .qui span{ font-size:14px; color:#44536E; }
    .ac-rdv .fac{ flex-shrink:0; min-height:32px; padding:0 12px; border:0; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-size:13px; font-weight:800; white-space:nowrap; }
    .ac-rdv .fac:hover{ background:#143A73; }
    .ac-rdv .chv{ flex-shrink:0; width:28px; height:32px; padding:0; border:0; background:transparent; color:#44536E; font-size:16px; }
    .ac-rdv .plus{ flex-shrink:0; min-height:32px; padding:0 10px; border:1.5px solid #1B4F9C; border-radius:999px; background:#FFFFFF; color:#1B4F9C; font-size:13px; font-weight:800; white-space:nowrap; }
    .ac-rdv .plus:hover{ background:#E3EBF7; }
    .ac-ini{ flex-shrink:0; min-width:28px; height:22px; padding:0 6px; box-sizing:border-box; border-radius:999px; color:#fff; font-size:11px; font-weight:800; display:inline-flex; align-items:center; justify-content:center; }
    .ac-det{ padding:0 12px 12px; display:flex; flex-direction:column; gap:6px; }
    .ac-det > span{ font-size:14px; }
    .ac-infos{ display:flex; flex-wrap:nowrap; padding:8px 4px; border-radius:12px; background:#FFFFFF; overflow-x:auto; }
    .ac-infos span{ flex:1 1 0; min-width:96px; display:flex; flex-direction:column; padding:0 10px; border-right:1px solid #E3E9F1; }
    .ac-infos span:last-child{ border-right:0; }
    .ac-infos i{ font-style:normal; font-size:10px; font-weight:800; letter-spacing:.04em; text-transform:uppercase; color:#5B6B86; white-space:nowrap; }
    .ac-infos b{ font-size:13px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .ac-infos small{ font-size:11px; color:#44536E; }
    .ac-det .ac-btn{ align-self:flex-start; min-height:38px; font-size:14px; }
    .ac-lanes{ display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:10px; }
    .ac-lane{ padding:10px; border-radius:16px; background:#F2F5F9; display:flex; flex-direction:column; gap:6px; }
    .ac-lane .tete{ display:flex; align-items:center; gap:8px; }
    .ac-lane .tete span{ display:flex; flex-direction:column; line-height:1.15; }
    .ac-lane .tete small{ font-size:12px; color:#44536E; }
    .ac-lane .it{ padding:6px 8px; border-radius:12px; background:#FFFFFF; border-left:4px solid #AEBBCD; display:flex; align-items:center; gap:6px; }
    .ac-lane .it button.q{ flex-grow:1; min-width:0; padding:0; border:0; background:transparent; color:#0E1F3D; text-align:left; display:flex; flex-direction:column; line-height:1.2; }
    .ac-lane .it button.q span{ font-size:12px; color:#44536E; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .ac-lane .it .plus{ flex-shrink:0; width:28px; height:28px; padding:0; border:1.5px solid #1B4F9C; border-radius:50%; background:#FFFFFF; color:#1B4F9C; font-weight:800; }
    .ac-lane .libre{ font-size:13px; color:#44536E; }

    /* 3. Activités à faire */
    .ac-acttete{ display:flex; flex-wrap:wrap; align-items:center; gap:10px 16px; }
    .ac-acttete h2{ font-size:19px; }
    .ac-acttete h2 span{ color:#44536E; }
    .ac-barre{ flex:0 1 520px; min-width:200px; display:flex; height:24px; border-radius:999px; overflow:hidden; gap:3px; }
    .ac-barre button{ border:0; color:#fff; font-size:13px; font-weight:800; min-width:28px; }
    .ac-barre .r{ background:#E35D55; } .ac-barre .y{ background:#E3B341; color:#3D2A00; }
    .ac-barre button.eteint{ opacity:.3; }
    .ac-acttete .ac-chev{ margin-left:auto; }
    .ac-legende{ display:flex; flex-wrap:wrap; gap:6px 18px; font-size:13px; font-weight:700; color:#44536E; }
    .ac-legende span{ display:inline-flex; align-items:center; gap:6px; }
    .ac-legende i{ width:10px; height:10px; border-radius:50%; display:inline-block; }
    .ac-act{ border-radius:16px; background:#F2F5F9; border-left:6px solid #E3B341; scroll-margin-top:90px; }
    .ac-act.r{ border-left-color:#E35D55; }
    .ac-act > button{ width:100%; min-height:56px; padding:10px 14px; border:0; background:transparent; color:#0E1F3D; text-align:left; display:flex; align-items:center; gap:14px; }
    .ac-act .num{ width:30px; height:30px; flex-shrink:0; border-radius:50%; font-size:15px; font-weight:800; display:flex; align-items:center; justify-content:center; }
    .ac-act.r .num{ background:#E35D55; color:#fff; } .ac-act.y .num{ background:#E3B341; color:#3D2A00; }
    .ac-act .corps{ flex-grow:1; min-width:0; display:flex; flex-direction:column; }
    .ac-act .corps b{ font-size:17px; } .ac-act .corps span{ font-size:14px; color:#44536E; }
    .ac-act .p60{ flex-shrink:0; padding:2px 10px; border:1px solid #AEBBCD; border-radius:999px; background:#FFFFFF; font-size:12px; font-weight:800; color:#44536E; white-space:nowrap; }
    .ac-act .chv{ flex-shrink:0; font-size:16px; color:#44536E; }
    .ac-act .det{ padding:0 14px 14px 58px; display:flex; flex-direction:column; gap:10px; }
    .ac-act .conseil{ padding:10px 12px; border-radius:14px; background:#FFFFFF; border:1px solid #E7C377; font-size:14px; }
    .ac-act .actions{ display:flex; flex-wrap:wrap; gap:8px; }

    @media (max-width: 760px){
        .ac-carte{ padding:10px; }
        .ac-60 .salut{ min-width:0; }
        .ac-pills{ margin-left:0; justify-content:flex-start; }
        .ac-libres{ flex:1 1 100%; order:3; padding-left:0; border-left:0; }
        .ac-rdv .ligne{ flex-wrap:wrap; gap:6px; padding:0 8px 8px 0; }
        .ac-rdv .main{ flex:1 1 100%; padding-bottom:2px; }
        .ac-rdv .ligne > :nth-child(2){ margin-left:12px; }
        .ac-rdv .h{ width:auto; min-width:48px; }
        .ac-act .det{ padding-left:14px; }
        .ac-act .p60{ display:none; }
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
    var T = M.t, A = M.agenda || { emps: [], rdv: [] };
    var CLE = '60s-accueil-choix';
    var choix = {};
    try { choix = JSON.parse(window.localStorage.getItem(CLE) || '{}') || {}; } catch (e) { choix = {}; }
    function garder(k, v) { choix[k] = v; try { window.localStorage.setItem(CLE, JSON.stringify(choix)); } catch (e) { } }

    // --- petits outils ---
    function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
    function bouton(cls, txt) { var b = el('button', cls, txt); b.type = 'button'; return b; }
    function fmt(s) { var a = arguments; return String(s).replace(/\{(\d)\}/g, function (m, i) { return a[+i + 1]; }); }
    function maj(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
    function svg60(fill, taille) {
        var n = 'http://www.w3.org/2000/svg', s = document.createElementNS(n, 'svg');
        s.setAttribute('width', taille); s.setAttribute('height', taille); s.setAttribute('viewBox', '0 0 256 256'); s.setAttribute('aria-hidden', 'true');
        s.innerHTML = '<circle cx="128" cy="128" r="112" fill="' + fill + '" stroke="#D9A03C" stroke-width="16"></circle><circle cx="96" cy="120" r="16" fill="none" stroke="#0E1F3D" stroke-width="13"></circle><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#0E1F3D" stroke-width="13" stroke-linecap="round"></path><ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#0E1F3D" stroke-width="13"></ellipse><path d="M99 166 q29 16 58 0" fill="none" stroke="#0E1F3D" stroke-width="11" stroke-linecap="round"></path>';
        return s;
    }
    var OEIL = '<svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"></path></svg>';
    var CAL = '<svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="17" rx="2"></rect><path d="M3 9h18M8 2v4M16 2v4"></path></svg>';

    // --- dates et heures (dans la langue de l'utilisateur) ---
    var LOC = M.lang === 'en' ? 'en-CA' : (M.lang === 'es' ? 'es-ES' : 'fr-CA');
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    function dJ(s) { var p = s.split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
    function cle(d) { return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()); }
    function plus(d, n) { var x = new Date(d.getFullYear(), d.getMonth(), d.getDate()); x.setDate(x.getDate() + n); return x; }
    function jLong(d) { return maj(d.toLocaleDateString(LOC, { weekday: 'long', day: 'numeric', month: 'long' })); }
    function jCourt(d) { return maj(d.toLocaleDateString(LOC, { weekday: 'short' }).replace('.', '')) + ' ' + d.getDate(); }
    function jAbr(d) { return d.toLocaleDateString(LOC, { day: 'numeric', month: 'short' }); }
    function fH(min) {
        var h = Math.floor(min / 60), m = min % 60;
        if (M.lang === 'en') return new Date(2000, 0, 1, h, m).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
        if (M.lang === 'es') return h + ':' + pad(m);
        return h + ' h' + (m ? ' ' + pad(m) : '');
    }
    function fHc(min) { return M.lang === 'fr' || !M.lang ? fH(min).replace(/ h$/, '').replace(' h ', 'h') : fH(min); }
    function nbH(min) { var s = String(Math.round(min / 6) / 10); return M.lang === 'en' ? s : s.replace('.', ','); }
    var auj = dJ(A.aujourdhui || cle(new Date()));
    var finRdv = new Date(auj.getFullYear(), auj.getMonth() + 2, 1);

    // --- l'état de la page ---
    var acts = (M.activites || []).filter(function (a) { return a.u === 'r' || a.u === 'y'; })
                                  .sort(function (a, b) { return (a.u === 'r' ? 0 : 1) - (b.u === 'r' ? 0 : 1); });
    var nR = acts.filter(function (a) { return a.u === 'r'; }).length;
    var nY = acts.length - nR;
    var aEquipe = A.emps.length > 1;
    var s = {
        a60: false, cible: -1, actOuv: -1, filtre: '', rdvOuv: '',
        agEmp: aEquipe && A.emps.some(function (e) { return e.v === choix.agEmp; }) ? choix.agEmp : '',
        avP: choix.avP || 'sem', rpJ: choix.rpJ !== false, rpV: !!choix.rpV, rpA: choix.rpA !== false, bqV: !!choix.bqV
    };
    function rdvDu(j) {
        return A.rdv.filter(function (r) { return r.jour === j && (!s.agEmp || r.emp === s.agEmp); })
                    .sort(function (a, b) { return a.deb - b.deb; });
    }
    function chev(ouvert) { return ouvert ? '▴' : '▾'; }
    function boutonChev(ouvert, onclick) {
        var b = bouton('ac-chev', chev(ouvert)); var t = ouvert ? T.replier : T.deplier;
        b.setAttribute('aria-expanded', ouvert ? 'true' : 'false'); b.setAttribute('aria-label', t); b.title = t;
        b.addEventListener('click', onclick); return b;
    }
    function nouveauRdv(jour, min, client, emp) {
        var u = 'wbfAppointmentEdit.aspx?id=0&start=' + encodeURIComponent(jour + 'T' + pad(Math.floor(min / 60)) + ':' + pad(min % 60) + ':00');
        if (client) u += '&client=' + encodeURIComponent(client);
        if (emp) u += '&emp=' + encodeURIComponent(emp);
        acOuvrirRdv(u, T.winRdv);
    }

    // 60 se rend sur une activité (l'enjeu prioritaire par défaut), l'ouvre et attend votre action.
    function envoyer60(i) {
        if (i < 0 || i >= acts.length) return;
        s.a60 = true; s.cible = i; s.actOuv = i; s.rpA = true;
        if (s.filtre && acts[i].u !== s.filtre) s.filtre = '';
        peindre();
        var t = document.getElementById('tache-' + i);
        if (t) { try { t.scrollIntoView({ behavior: 'smooth', block: 'start' }); } catch (e) { t.scrollIntoView(); } }
    }
    function ramener60() {
        s.a60 = false; s.cible = -1; peindre();
        try { window.scrollTo({ top: 0, behavior: 'smooth' }); } catch (e) { window.scrollTo(0, 0); }
    }
    function premier(u) { for (var i = 0; i < acts.length; i++) if (acts[i].u === u) return i; return -1; }

    // =================== 1. La fenêtre de 60 ===================
    function peindre60() {
        var coul = nR ? '#E35D55' : (nY ? '#E3B341' : '#43B47A');
        var f = el('section', 'ac-60'); f.setAttribute('aria-label', T.assistant60); f.style.borderColor = coul;
        var salut = el('div', 'salut');
        if (s.a60) {
            var bp = bouton('a60-parti', '60'); bp.setAttribute('aria-label', T.a60Retour); bp.title = T.a60RetourTip;
            bp.addEventListener('click', ramener60); salut.appendChild(bp);
        } else {
            var b60 = bouton('a60-btn'); b60.appendChild(svg60(coul, 60));
            b60.setAttribute('aria-label', acts.length ? T.a60Aria : T.assistant60); b60.title = b60.getAttribute('aria-label');
            if (acts.length) b60.addEventListener('click', function () { envoyer60(0); });
            salut.appendChild(b60);
        }
        var col = el('div', 'col');
        var h1 = el('h1', '', M.prenom ? fmt(T.bonjourNom, M.prenom) : T.bonjour);
        h1.title = nR ? (nR === 1 ? T.gUrgent1 : fmt(T.gUrgentN, nR)) : (nY ? T.gVeille : T.gOk);
        col.appendChild(h1);
        if (acts.length) {
            var p = acts[0], bpr = bouton('prio');
            bpr.title = p.t + ' — ' + p.d;
            var eti = el('span', 'eti', T.enPremier + ' · '); eti.style.color = p.u === 'r' ? '#A3261C' : '#7A5200';
            bpr.appendChild(eti); bpr.appendChild(el('b', '', p.t)); bpr.appendChild(el('span', 'sous', ' — ' + p.d));
            bpr.addEventListener('click', function () { envoyer60(0); });
            col.appendChild(bpr);
        } else {
            col.appendChild(el('span', 'ok', T.rienUrgent));
        }
        salut.appendChild(col); f.appendChild(salut);

        var pills = el('div', 'ac-pills');
        // RDV demandé : des clients demandent un RDV, ou de déplacer ou d'annuler un RDV (réponse dans l'Agenda)
        if (M.demandes > 0) {
            var pd = el('a', 'ac-pill dem'); pd.href = 'wbfAgenda.aspx'; pd.title = T.rdvDemandeTip;
            pd.setAttribute('aria-label', T.rdvDemande + ' : ' + M.demandes + ' — ' + T.rdvDemandeTip);
            pd.appendChild(el('b', '', T.rdvDemande)); pd.appendChild(el('span', 'ac-rond r', String(M.demandes)));
            pills.appendChild(pd);
        }
        // Activité à faire : rouge, jaune
        var pa = el('span', 'ac-pill'); pa.appendChild(el('b', '', T.activiteAFaire));
        [['r', nR, T.indR], ['y', nY, T.indY]].forEach(function (x) {
            var b = bouton('ac-rond ' + x[0] + (x[1] ? '' : ' vide'), String(x[1]));
            b.title = fmt(x[2], x[1]); b.setAttribute('aria-label', b.title);
            b.addEventListener('click', function () { var i = premier(x[0]); if (i >= 0) envoyer60(i); });
            pa.appendChild(b);
        });
        pills.appendChild(pa);
        // Messages : le centre de messages
        var pm = el('a', 'ac-pill'); pm.href = 'wbfMailbox.aspx'; pm.setAttribute('aria-label', T.msgAria); pm.title = T.msgAria;
        pm.appendChild(el('b', '', T.messages)); pm.appendChild(el('span', 'chv', '›'));
        pills.appendChild(pm);
        // Revenu en retard, Paiements en retard
        (M.entete || []).forEach(function (k) {
            var a = el('a', 'ac-pill mt' + (k.actif ? ' actif' : '')); a.href = k.url; a.title = k.sous;
            a.setAttribute('aria-label', k.lab + ' : ' + k.val + ' — ' + k.sous);
            a.appendChild(el('span', '', k.lab)); a.appendChild(el('b', '', k.val));
            pills.appendChild(a);
        });
        // Le compte d'opérations : l'œil montre ou masque le solde
        var B = M.banque || {};
        var pc = el('span', 'ac-pill cpt'); var tx = el('span', 'txt');
        tx.appendChild(el('span', '', T.compteOp));
        var lib = el('b', '', B.lib || ''); tx.appendChild(lib); pc.appendChild(tx);
        if (B.maj) pc.title = B.maj;
        if (B.aCompte) {
            if (s.bqV) lib.appendChild(el('b', 'solde', '· ' + B.solde));
            var oe = bouton('ac-oeil'); oe.innerHTML = OEIL;
            var t = s.bqV ? T.masquerMontant : T.voirMontant; oe.title = t; oe.setAttribute('aria-label', t);
            oe.addEventListener('click', function () { s.bqV = !s.bqV; garder('bqV', s.bqV); peindre(); });
            pc.appendChild(oe);
        } else {
            var br = el('a', 'ac-brancher', T.brancher); br.href = 'PlaidAccounts.aspx'; pc.appendChild(br);
        }
        pills.appendChild(pc);
        f.appendChild(pills);
        return f;
    }

    // =================== 2. L'agenda ===================
    function etatChip(r) {
        var c = r.etat === 'termine' ? ['#E3F3EA', '#0F5A3A', T.stTermine] : (r.etat === 'encours' ? ['#E3EBF7', '#143A73', T.stEnCours] : ['#E8EDF5', '#44536E', T.stAVenir]);
        var sp = el('span', 'ac-chip', c[2]); sp.style.background = c[0]; sp.style.color = c[1]; return sp;
    }
    function bordure(r) { return r.etat === 'termine' ? '#43B47A' : (r.etat === 'encours' ? '#1B4F9C' : '#AEBBCD'); }

    // Une ligne de RDV : heure, client, Facturer (RDV terminé), lieu, état, détail, + RDV.
    function ligneRdv(r, avecIni) {
        var boite = el('div', 'ac-rdv'); boite.style.borderLeftColor = bordure(r);
        var li = el('div', 'ligne'), ouvert = s.rdvOuv === r.id;
        function basculer() { s.rdvOuv = ouvert ? '' : r.id; peindre(); }
        var m = bouton('main'); m.setAttribute('aria-expanded', ouvert ? 'true' : 'false');
        m.appendChild(el('b', 'h', r.h));
        var qui = el('span', 'qui'); qui.appendChild(el('b', '', r.client)); if (r.court) qui.appendChild(el('span', '', ' · ' + r.court)); m.appendChild(qui);
        m.addEventListener('click', basculer); li.appendChild(m);
        if (avecIni && r.ini) { var ini = el('span', 'ac-ini', r.ini); ini.style.background = r.c; ini.title = r.empNom; li.appendChild(ini); }
        if (r.etat === 'termine' && r.cli) {
            var fa = bouton('fac', T.facturer); fa.setAttribute('aria-label', fmt(T.facturerAria, r.client));
            fa.addEventListener('click', acNouvelleFacture); li.appendChild(fa);
        }
        if (r.lieu) { var lu = el('span', 'ac-chip', r.lieu); lu.style.background = '#FBF1DC'; lu.style.color = '#7A5200'; li.appendChild(lu); }
        li.appendChild(etatChip(r));
        var cv = bouton('chv', chev(ouvert)); cv.setAttribute('aria-expanded', ouvert ? 'true' : 'false');
        cv.setAttribute('aria-label', fmt(T.voirDetail, r.client)); cv.addEventListener('click', basculer); li.appendChild(cv);
        var pl = bouton('plus', T.plusRdv); pl.title = fmt(T.nouveauRdvAvec, r.client); pl.setAttribute('aria-label', pl.title);
        pl.addEventListener('click', function () { nouveauRdv(cle(plus(dJ(r.jour), 7)), r.deb, r.cli, r.emp); });
        li.appendChild(pl);
        boite.appendChild(li);
        if (ouvert) {
            var det = el('div', 'ac-det');
            if (r.desc) det.appendChild(el('span', '', r.desc));
            var inf = el('div', 'ac-infos');
            [[T.iLieu, r.lieu], [T.iHeure, r.plage, r.duree], [T.iEmploye, r.empNom], [T.iType, r.typ]].forEach(function (x) {
                if (!x[1]) return;
                var c = el('span'); c.title = x[0] + ' : ' + x[1] + (x[2] ? ' ' + x[2] : '');
                c.appendChild(el('i', '', x[0])); c.appendChild(el('b', '', x[1])); if (x[2]) c.appendChild(el('small', '', x[2]));
                inf.appendChild(c);
            });
            if (inf.childNodes.length) det.appendChild(inf);
            var ob = bouton('ac-btn clair', T.ouvrirRdv);
            ob.addEventListener('click', function () { acOuvrirRdv('wbfAppointmentEdit.aspx?id=' + r.id, T.winRdv); });
            det.appendChild(ob); boite.appendChild(det);
        }
        return boite;
    }

    // Les 3 prochaines plages libres d'au moins une heure (jours ouvrables, 9 h à 17 h, pas de 30 min).
    function plagesLibres() {
        var cand = s.agEmp ? [s.agEmp] : (A.emps.length ? A.emps.map(function (e) { return e.v; }) : ['']);
        function libre(emp, liste, a, b) {
            return !liste.some(function (r) { return (!emp || !r.emp || r.emp === emp) && r.deb < b && r.fin > a; });
        }
        var out = [], OUV = 9 * 60, FERM = 17 * 60, PAS = 30, MIN = 60;
        for (var k = 0; k < 21 && out.length < 3; k++) {
            var d = plus(auj, k); if (d.getDay() === 0 || d.getDay() === 6 || d >= finRdv) continue;
            var j = cle(d), liste = A.rdv.filter(function (r) { return r.jour === j; });
            var depart = OUV;
            if (k === 0) depart = Math.max(OUV, Math.ceil(((A.maintenant || 0) + 1) / PAS) * PAS);
            var deb = null;
            for (var h = depart; h <= FERM; h += PAS) {
                var ok = h + PAS <= FERM && cand.some(function (e) { return libre(e, liste, h, h + PAS); });
                if (ok && deb === null) deb = h;
                if (!ok && deb !== null) { if (h - deb >= MIN && out.length < 3) out.push({ d: d, deb: deb, fin: h }); deb = null; }
            }
        }
        return out;
    }

    function peindreAgenda() {
        var sec = el('section', 'ac-carte');
        // --- Aujourd'hui ---
        var bj = el('div', 'ac-bloc'), tete = el('div', 'ac-btete');
        var liste = rdvDu(A.aujourdhui);
        var tt = el('div', 'titre');
        tt.appendChild(el('b', '', T.agAuj + ' · ' + jLong(auj)));
        tt.appendChild(el('span', '', fmt(T.agRdvH, liste.length, nbH(liste.reduce(function (t, r) { return t + (r.fin - r.deb); }, 0))) +
                                      (aEquipe && !s.agEmp ? ' · ' + fmt(T.agEmployes, A.emps.length) : '')));
        tete.appendChild(tt);
        var lib = el('div', 'ac-libres');
        if (aEquipe) {
            var se = el('select'); se.setAttribute('aria-label', T.agendaDe);
            A.emps.forEach(function (e) { var o = el('option', '', e.lab); o.value = e.v; se.appendChild(o); });
            var o0 = el('option', '', fmt(T.equipeN, A.emps.length)); o0.value = ''; se.appendChild(o0);
            se.value = s.agEmp;
            se.addEventListener('change', function () { s.agEmp = se.value; garder('agEmp', s.agEmp); peindre(); });
            lib.appendChild(se);
        }
        lib.appendChild(el('h2', '', T.plagesLibres));
        var chips = el('div', 'chips'); chips.setAttribute('role', 'group'); chips.setAttribute('aria-label', T.plagesAria);
        var pls = plagesLibres();
        pls.forEach(function (p) {
            var nom = cle(p.d) === A.aujourdhui ? T.agAujAbr : jCourt(p.d);
            var b = bouton('', nom + ' ' + fHc(p.deb) + '–' + fH(p.fin).replace(' h ', 'h') + ' · ' + nbH(p.fin - p.deb) + ' h');
            b.title = fmt(T.plageTip, jLong(p.d), fH(p.deb), fH(p.fin));
            b.addEventListener('click', function () { nouveauRdv(cle(p.d), p.deb, '', s.agEmp); });
            chips.appendChild(b);
        });
        if (!pls.length) chips.appendChild(el('span', '', T.plagesVide));
        lib.appendChild(chips); tete.appendChild(lib);
        var ag = el('a', 'ac-agbtn'); ag.href = 'wbfAgenda.aspx'; ag.innerHTML = CAL; ag.appendChild(document.createTextNode(T.agenda));
        ag.setAttribute('aria-label', T.agendaAria); ag.title = T.agendaTip; tete.appendChild(ag);
        tete.appendChild(boutonChev(s.rpJ, function () { s.rpJ = !s.rpJ; garder('rpJ', s.rpJ); peindre(); }));
        bj.appendChild(tete);
        if (s.rpJ) {
            if (aEquipe && !s.agEmp) {
                // Toute l'équipe : une rangée par employé
                var lanes = el('div', 'ac-lanes');
                var groupes = A.emps.map(function (e) { return { e: e, l: liste.filter(function (r) { return r.emp === e.v; }) }; });
                var sans = liste.filter(function (r) { return !A.emps.some(function (e) { return e.v === r.emp; }); });
                if (sans.length) groupes.push({ e: { v: '', lab: '—', ini: '?', c: '#5B6B86' }, l: sans });
                groupes.forEach(function (g) {
                    var ln = el('div', 'ac-lane'), lt = el('div', 'tete');
                    var ini = el('span', 'ac-ini', g.e.ini); ini.style.background = g.e.c; lt.appendChild(ini);
                    var nm = el('span'); nm.appendChild(el('b', '', g.e.lab));
                    nm.appendChild(el('small', '', fmt(T.agRdvH, g.l.length, nbH(g.l.reduce(function (t, r) { return t + (r.fin - r.deb); }, 0)))));
                    lt.appendChild(nm); ln.appendChild(lt);
                    g.l.forEach(function (r) {
                        var it = el('div', 'it'); it.style.borderLeftColor = bordure(r);
                        var q = bouton('q'); q.appendChild(el('b', '', r.h + ' · ' + r.client)); if (r.court) q.appendChild(el('span', '', r.court));
                        q.title = T.ouvrirRdv; q.addEventListener('click', function () { acOuvrirRdv('wbfAppointmentEdit.aspx?id=' + r.id, T.winRdv); });
                        it.appendChild(q);
                        var pl = bouton('plus', '+'); pl.title = fmt(T.nouveauRdvAvec, r.client); pl.setAttribute('aria-label', pl.title);
                        pl.addEventListener('click', function () { nouveauRdv(cle(plus(dJ(r.jour), 7)), r.deb, r.cli, r.emp); });
                        it.appendChild(pl); ln.appendChild(it);
                    });
                    if (!g.l.length) ln.appendChild(el('span', 'libre', T.libre));
                    lanes.appendChild(ln);
                });
                bj.appendChild(lanes);
            } else {
                if (!liste.length) bj.appendChild(el('div', 'ac-vide', T.agVide));
                liste.forEach(function (r) { bj.appendChild(ligneRdv(r, false)); });
            }
        }
        sec.appendChild(bj);

        // --- À venir ---
        var bv = el('div', 'ac-bloc'); bv.id = 'bloc-a-venir';
        var tv = el('div', 'ac-btete');
        var d8 = plus(auj, 8), d14 = plus(auj, 14);
        var PL = {
            sem: T.pSem,
            proch: fmt(T.pProch, d8.getMonth() === d14.getMonth() ? d8.getDate() + '–' + jAbr(d14) : jAbr(d8) + '–' + jAbr(d14)),
            mois: T.pMois, moisp: T.pMoisP
        };
        if (!PL[s.avP]) s.avP = 'sem';
        var jours = [];
        for (var k = 1; ; k++) {
            var d = plus(auj, k); if (d >= finRdv) break;
            var dans = s.avP === 'sem' ? k <= 7 : s.avP === 'proch' ? (k >= 8 && k <= 14)
                     : s.avP === 'mois' ? d.getMonth() === auj.getMonth() : d.getMonth() === (auj.getMonth() + 1) % 12;
            if (dans) jours.push(d);
        }
        var G = jours.map(function (d) { var l = rdvDu(cle(d)); return { d: d, l: l, min: l.reduce(function (t, r) { return t + (r.fin - r.deb); }, 0) }; })
                     .filter(function (g) { return g.l.length; });
        var nT = G.reduce(function (t, g) { return t + g.l.length; }, 0), mT = G.reduce(function (t, g) { return t + g.min; }, 0);
        var tvt = el('div', 'titre'); tvt.appendChild(el('b', '', T.aVenir));
        tvt.appendChild(el('span', '', fmt(T.aVenirPlanif, nT, nbH(mT)) + (aEquipe && !s.agEmp ? T.toutEquipe : '')));
        tv.appendChild(tvt);
        var ong = el('div', 'ac-onglets'); ong.setAttribute('role', 'tablist'); ong.setAttribute('aria-label', T.periode);
        Object.keys(PL).forEach(function (k) {
            var b = bouton('', PL[k]); b.setAttribute('role', 'tab'); b.setAttribute('aria-selected', s.avP === k ? 'true' : 'false');
            b.addEventListener('click', function () { s.avP = k; s.rpV = true; garder('avP', k); garder('rpV', true); peindre(); });
            ong.appendChild(b);
        });
        tv.appendChild(ong);
        tv.appendChild(boutonChev(s.rpV, function () { s.rpV = !s.rpV; garder('rpV', s.rpV); peindre(); }));
        bv.appendChild(tv);
        if (s.rpV) {
            if (!G.length) bv.appendChild(el('div', 'ac-vide', T.avVide));
            G.forEach(function (g) {
                var gt = el('div', 'ac-groupe'); gt.appendChild(el('b', '', jLong(g.d))); gt.appendChild(el('span', '', fmt(T.agRdvH, g.l.length, nbH(g.min))));
                bv.appendChild(gt);
                g.l.forEach(function (r) { bv.appendChild(ligneRdv(r, aEquipe && !s.agEmp)); });
            });
        }
        sec.appendChild(bv);
        return sec;
    }

    // =================== 3. Activités à faire ===================
    function peindreActivites() {
        var sec = el('section', 'ac-carte'); sec.id = 'activites-a-faire'; sec.setAttribute('aria-label', T.activites);
        var tA = el('div', 'ac-acttete');
        var h = el('h2', '', T.activites + ' '); h.appendChild(el('span', '', '(' + acts.length + ')')); tA.appendChild(h);
        var barre = el('div', 'ac-barre');
        [['r', nR, T.segR], ['y', nY, T.segY]].forEach(function (x) {
            if (!x[1]) return;
            var b = bouton(x[0] + (s.filtre && s.filtre !== x[0] ? ' eteint' : ''), String(x[1]));
            b.style.flexGrow = x[1]; b.setAttribute('aria-pressed', s.filtre === x[0] ? 'true' : 'false');
            b.setAttribute('aria-label', fmt(x[2], x[1])); b.title = b.getAttribute('aria-label');
            b.addEventListener('click', function () { s.filtre = s.filtre === x[0] ? '' : x[0]; s.rpA = true; peindre(); });
            barre.appendChild(b);
        });
        if (acts.length) tA.appendChild(barre);
        tA.appendChild(boutonChev(s.rpA, function () { s.rpA = !s.rpA; garder('rpA', s.rpA); peindre(); }));
        sec.appendChild(tA);
        if (!s.rpA) return sec;

        if (!acts.length) { sec.appendChild(el('div', 'ac-vide', T.toutFait)); return sec; }
        var leg = el('div', 'ac-legende');
        [['#E35D55', T.lRouge], ['#E3B341', T.lJaune]].forEach(function (x) { var sp = el('span'); var i = el('i'); i.style.background = x[0]; sp.appendChild(i); sp.appendChild(document.createTextNode(x[1])); leg.appendChild(sp); });
        sec.appendChild(leg);
        var liste = el('div'); liste.style.cssText = 'display:flex;flex-direction:column;gap:8px';
        acts.forEach(function (a, i) {
            if (s.filtre && a.u !== s.filtre) return;
            var ouvert = s.actOuv === i;
            var boite = el('div', 'ac-act ' + a.u); boite.id = 'tache-' + i;
            var b = bouton(); b.setAttribute('aria-expanded', ouvert ? 'true' : 'false');
            b.appendChild(el('span', 'num', String(i + 1)));
            var c = el('span', 'corps'); c.appendChild(el('b', '', a.t));
            var sous = a.d;
            if (a.u === 'r') { var p = sous.indexOf(' · '); sous = p > 0 ? sous.slice(0, p) + ' · ' + T.dateDepassee + sous.slice(p) : sous + ' · ' + T.dateDepassee; }
            c.appendChild(el('span', '', sous)); b.appendChild(c);
            if (i === 0) b.appendChild(el('span', 'p60', T.propose60));
            b.appendChild(el('span', 'chv', chev(ouvert)));
            b.addEventListener('click', function () { s.actOuv = ouvert ? -1 : i; if (ouvert && s.cible === i) { s.a60 = false; s.cible = -1; } peindre(); });
            boite.appendChild(b);
            if (ouvert) {
                var d = el('div', 'det');
                if (s.a60 && s.cible === i) {
                    var ar = el('div', 'a60-arrive'); ar.appendChild(svg60(a.u === 'r' ? '#E35D55' : '#E3B341', 44));
                    var tx = el('span', 'txt'); tx.appendChild(el('b', '', T.a60Ici)); tx.appendChild(el('span', '', a.det)); tx.appendChild(el('span', '', T.a60Choisir));
                    ar.appendChild(tx);
                    var mc = bouton('', T.merci60); mc.addEventListener('click', ramener60); ar.appendChild(mc);
                    d.appendChild(ar);
                } else {
                    var cs = el('div', 'conseil'); cs.appendChild(el('b', '', T.conseil60 + ' ')); cs.appendChild(document.createTextNode(a.det));
                    d.appendChild(cs);
                }
                if (a.btn && a.url) {
                    var ac = el('div', 'actions'); var go = el('a', 'ac-btn', a.btn); go.href = a.url; ac.appendChild(go); d.appendChild(ac);
                }
                boite.appendChild(d);
            }
            liste.appendChild(boite);
        });
        if (s.filtre) {
            var tout = bouton('ac-btn clair', T.tous); tout.style.alignSelf = 'flex-start';
            tout.addEventListener('click', function () { s.filtre = ''; peindre(); }); liste.appendChild(tout);
        }
        sec.appendChild(liste);
        return sec;
    }

    function peindre() {
        racine.innerHTML = '';
        racine.appendChild(peindre60());
        racine.appendChild(peindreAgenda());
        racine.appendChild(peindreActivites());
    }
    peindre();
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
