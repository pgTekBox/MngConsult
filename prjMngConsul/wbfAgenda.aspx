<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAgenda.aspx.vb" Inherits="MngConsul.wbfAgenda" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Agenda — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<%-- L'agenda, au modèle de la fenêtre « Tout l'agenda » de la page d'accueil 60secondes
     du 21 octobre : en-tête (période ‹ ›, Aujourd'hui, employé, + RDV), grille de
     5 jours ouvrables heure par heure, et à droite « Mettre à jour le RDV ».
     Couleurs : marine #0E1F3D, action #1B4F9C, bleu pâle #E3EBF7, bordures #D5DDE8. --%>
<style>
    .ag{ font-family:Nunito, system-ui, sans-serif; color:#0E1F3D; font-size:15px; line-height:1.4; background:#FFFFFF; border-radius:24px; overflow:hidden; display:flex; flex-direction:column; }
    .ag button, .ag select{ font-family:inherit; }
    .ag button{ cursor:pointer; }

    /* En-tête */
    .ag-tete{ display:flex; flex-wrap:wrap; align-items:center; gap:10px 12px; padding:14px 18px; border-bottom:1px solid #E3E9F1; }
    .ag-ico{ width:40px; height:40px; flex-shrink:0; border-radius:12px; background:#E3EBF7; color:#1B4F9C; display:flex; align-items:center; justify-content:center; }
    .ag-titre{ display:flex; flex-direction:column; line-height:1.15; margin-right:auto; }
    .ag-titre b{ font-size:20px; font-weight:800; } .ag-titre span{ font-size:13px; color:#44536E; }
    .ag-nav{ display:flex; align-items:center; gap:4px; padding:3px; border:1px solid #D5DDE8; border-radius:999px; }
    .ag-nav a{ width:34px; height:34px; border-radius:50%; background:#F2F5F9; color:#0E1F3D; font-size:18px; font-weight:800; display:flex; align-items:center; justify-content:center; text-decoration:none; }
    .ag-nav a:hover{ background:#E3EBF7; color:#0E1F3D; }
    .ag-nav b{ padding:0 10px; font-size:15px; white-space:nowrap; }
    .ag-pill{ min-height:40px; padding:0 14px; border:1px solid #D5DDE8; border-radius:999px; background:#FFFFFF; color:#44536E; font-weight:800; font-size:14px; display:flex; align-items:center; text-decoration:none; }
    .ag-pill:hover{ background:#F2F5F9; color:#0E1F3D; }
    .ag-pill.off{ opacity:.5; pointer-events:none; }
    .ag-tete select{ min-height:40px; max-width:240px; padding:0 10px; border:1px solid #AEBBCD; border-radius:999px; background:#FFFFFF; color:#0E1F3D; font-weight:800; font-size:14px; }
    .ag-plus{ min-height:44px; padding:0 18px; border:0; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-size:16px; font-weight:800; }
    .ag-plus:hover{ background:#143A73; }

    /* Légende */
    .ag-leg{ display:flex; flex-wrap:wrap; align-items:center; gap:6px 14px; padding:10px 18px; border-bottom:1px solid #E3E9F1; font-size:13px; color:#44536E; }
    .ag-leg .aide{ flex:1 1 300px; }
    .ag-chip{ padding:2px 9px; border-radius:999px; font-size:12px; font-weight:800; white-space:nowrap; display:inline-flex; align-items:center; gap:5px; }
    .ag-chip i{ width:8px; height:8px; border-radius:50%; display:inline-block; }
    .ag-emp{ display:inline-flex; align-items:center; gap:5px; font-size:12px; font-weight:700; color:#44536E; }
    .ag-emp i{ width:10px; height:10px; border-radius:3px; display:inline-block; }

    /* Corps : grille + panneau */
    .ag-corps{ display:flex; align-items:stretch; min-height:560px; }
    .ag-grille{ flex:1 1 auto; min-width:0; padding:10px 12px 16px 6px; overflow-x:auto; }
    .ag-cols{ display:grid; grid-template-columns:44px repeat(5, minmax(130px, 1fr)); gap:0 6px; min-width:720px; }
    .ag-jt{ position:sticky; top:0; z-index:2; min-height:44px; padding:4px 8px 6px; background:#FFFFFF; border-bottom:3px solid transparent; display:flex; flex-direction:column; justify-content:flex-end; }
    .ag-jt b{ font-size:15px; } .ag-jt span{ font-size:12px; color:#44536E; }
    .ag-jt.auj{ border-bottom-color:#1B4F9C; } .ag-jt.auj b{ color:#1B4F9C; }
    .ag-heures{ position:relative; }
    .ag-heures span{ position:absolute; right:6px; transform:translateY(-50%); font-size:11px; font-weight:700; color:#5B6B86; }
    .ag-col{ position:relative; border-radius:12px; background:#F7F9FC; cursor:copy; }
    .ag-col.auj{ background:#F2F6FC; }
    .ag-ligne-h{ position:absolute; left:0; right:0; border-top:1px solid #E3E9F1; pointer-events:none; }
    .ag-maint{ position:absolute; left:-3px; right:0; border-top:2px solid #E35D55; z-index:3; pointer-events:none; }
    .ag-maint::before{ content:""; position:absolute; left:-3px; top:-5px; width:8px; height:8px; border-radius:50%; background:#E35D55; }
    .ag-ev{ position:absolute; z-index:1; box-sizing:border-box; padding:3px 6px 3px 8px; border:1.5px solid #C9D5E6; border-left-width:5px; border-radius:10px; background:#FFFFFF; color:#0E1F3D; text-align:left; overflow:hidden; display:flex; flex-direction:column; gap:1px; cursor:pointer; }
    .ag-ev:hover{ box-shadow:0 4px 12px rgba(14,31,61,.15); z-index:4; }
    .ag-ev.sel{ border-color:#1B4F9C; border-width:2px; border-left-width:5px; background:#E3EBF7; z-index:4; }
    .ag-ev.termine{ background:#FBFCFE; }
    .ag-ev .l1{ font-size:12px; font-weight:800; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .ag-ev .l2{ font-size:11px; color:#44536E; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .ag-ev .ag-chip{ align-self:flex-start; font-size:10px; padding:1px 6px; }

    /* Panneau de droite */
    .ag-panneau{ flex:0 0 340px; box-sizing:border-box; padding:16px; border-left:1px solid #E3E9F1; background:#F7F9FC; display:flex; flex-direction:column; gap:12px; }
    .ag-panneau h2{ margin:0; font-size:12px; font-weight:800; letter-spacing:.06em; text-transform:uppercase; color:#44536E; }
    .ag-panneau p{ margin:0; font-size:14px; color:#44536E; }
    .ag-carte{ padding:12px 14px; border-radius:16px; background:#FFFFFF; border-left:5px solid #1B4F9C; display:flex; flex-direction:column; gap:2px; }
    .ag-carte b{ font-size:18px; } .ag-carte span{ font-size:13px; color:#44536E; }
    .ag-champ{ display:flex; flex-direction:column; gap:4px; font-size:13px; font-weight:800; color:#0E1F3D; }
    .ag-champ select{ min-height:42px; padding:0 10px; border:1px solid #AEBBCD; border-radius:12px; background:#FFFFFF; color:#0E1F3D; font-size:15px; font-weight:800; }
    .ag-deux{ display:grid; grid-template-columns:1fr 1fr; gap:10px; }
    .ag-libres{ display:flex; flex-wrap:wrap; gap:6px; }
    .ag-libres button{ min-height:30px; padding:0 10px; border:1.5px solid #43B47A; border-radius:999px; background:#FFFFFF; color:#0F5A3A; font-size:12px; font-weight:800; white-space:nowrap; }
    .ag-libres button:hover, .ag-libres button[aria-pressed="true"]{ background:#E3F3EA; }
    .ag-msg{ padding:8px 10px; border-radius:12px; font-size:13px; font-weight:700; }
    .ag-msg.conflit{ background:#FDECEA; color:#A3261C; }
    .ag-msg.change{ background:#E3EBF7; color:#143A73; }
    .ag-msg.info{ background:#E3F3EA; color:#0F5A3A; }
    .ag-btn{ min-height:44px; padding:0 18px; border:1px solid #1B4F9C; border-radius:999px; background:#1B4F9C; color:#FFFFFF; font-size:15px; font-weight:800; }
    .ag-btn:hover{ background:#143A73; }
    .ag-btn:disabled{ opacity:.45; cursor:default; background:#1B4F9C; }
    .ag-btn.clair{ background:#FFFFFF; color:#0E1F3D; border-color:#AEBBCD; }
    .ag-btn.clair:hover{ background:#F2F5F9; }
    .ag-btn.rouge{ background:#FFFFFF; color:#A3261C; border-color:#E35D55; }
    .ag-btn.rouge:hover{ background:#FDECEA; }
    .ag-rangee{ display:flex; flex-wrap:wrap; gap:8px; }
    .ag-rangee .ag-btn{ flex:1 1 auto; }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadWindowManager ID="rwmAgenda" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwAppointment" runat="server"
                ClientIDMode="Static"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="1300px"
                Height="700px"
                MinWidth="320"
                MinHeight="500"
                Title="Rendez-vous"
                OnClientClose="agOnApptClose">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <%-- Les changements faits dans le panneau reviennent au serveur par ce bouton caché. --%>
    <asp:HiddenField ID="hfAction" runat="server" ClientIDMode="Static" />
    <asp:HiddenField ID="hfData" runat="server" ClientIDMode="Static" />
    <asp:Button ID="btnAction" runat="server" ClientIDMode="Static" style="display:none" />

    <div class="ag" id="agAgenda"></div>

    <script type="text/javascript">
        // Fenêtre du rendez-vous (nouveau ou fiche complète) ; à la fermeture, l'agenda se recharge.
        function agOuvrirFiche(url) {
            var win = window.radopen(url, 'rwAppointment');
            if (!win) return;
            win.setSize(Math.min(1300, Math.floor(window.innerWidth * 0.98)), Math.min(700, Math.floor(window.innerHeight * 0.95)));
            win.center();
        }
        function agOnApptClose(sender, args) {
            setTimeout(function () { window.location.reload(); }, 50);
        }

        (function () {
            var M = <%= ModeleJson %>;
            var racine = document.getElementById('agAgenda');
            if (!M || !racine) return;
            var T = M.t;
            var CLE = '60s-accueil-choix';
            var choix = {};
            try { choix = JSON.parse(window.localStorage.getItem(CLE) || '{}') || {}; } catch (e) { choix = {}; }
            function garder(k, v) { choix[k] = v; try { window.localStorage.setItem(CLE, JSON.stringify(choix)); } catch (e) { } }

            // --- petits outils ---
            function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
            function bouton(cls, txt) { var b = el('button', cls, txt); b.type = 'button'; return b; }
            function fmt(s) { var a = arguments; return String(s).replace(/\{(\d)\}/g, function (m, i) { return a[+i + 1]; }); }
            function maj(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
            var LOC = M.lang === 'en' ? 'en-CA' : (M.lang === 'es' ? 'es-ES' : 'fr-CA');
            function pad(n) { return (n < 10 ? '0' : '') + n; }
            function dJ(s) { var p = s.split('-'); return new Date(+p[0], +p[1] - 1, +p[2]); }
            function jLong(s) { return maj(dJ(s).toLocaleDateString(LOC, { weekday: 'long', day: 'numeric', month: 'long' })); }
            function jCourt(s) { var d = dJ(s); return maj(d.toLocaleDateString(LOC, { weekday: 'short' }).replace('.', '')) + ' ' + d.getDate(); }
            function fH(min) {
                var h = Math.floor(min / 60), m = min % 60;
                if (M.lang === 'en') return new Date(2000, 0, 1, h, m).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
                if (M.lang === 'es') return h + ':' + pad(m);
                return h + ' h' + (m ? ' ' + pad(m) : '');
            }
            function fD(min) { var h = Math.floor(min / 60), m = min % 60; return h ? h + ' h' + (m ? ' ' + pad(m) : '') : m + ' min'; }
            function nbH(min) { var s = String(Math.round(min / 6) / 10); return M.lang === 'en' ? s : s.replace('.', ','); }
            var CAL = '<svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="17" rx="2"></rect><path d="M3 9h18M8 2v4M16 2v4"></path></svg>';

            // --- l'état ---
            var periode = M.jours.slice(0, 5);
            var empOk = function (v) { return M.emps.some(function (e) { return e.v === v; }); };
            var s = { emp: empOk(choix.agEmp) ? choix.agEmp : '', sel: null, ed: null };
            function visibles(j) {
                return M.rdv.filter(function (r) { return r.jour === j && (!s.emp || r.emp === s.emp); })
                            .sort(function (a, b) { return a.deb - b.deb || a.fin - b.fin; });
            }
            function nomEmp(v) { var e = M.emps.filter(function (x) { return x.v === v; })[0]; return e ? e.lab : T.aucunEmploye; }

            // Heures affichées : 8 h à 18 h, élargies aux RDV de la période.
            var H0 = 8 * 60, H1 = 18 * 60;
            M.rdv.forEach(function (r) { if (periode.indexOf(r.jour) >= 0) { H0 = Math.min(H0, Math.floor(r.deb / 60) * 60); H1 = Math.max(H1, Math.ceil(r.fin / 60) * 60); } });
            var PX = 62 / 60; // 62 px par heure

            // Libre si aucun RDV de l'employé (ou de personne, sans employé) ne chevauche [a, b).
            function libre(j, emp, a, b, sauf) {
                return !M.rdv.some(function (r) {
                    return r.jour === j && r.id !== sauf && (!emp || !r.emp || r.emp === emp) && r.deb < b && r.fin > a;
                });
            }
            // Les prochaines plages libres d'une durée donnée (jours ouvrables chargés, 8 h à 18 h, pas de 30 min).
            function plagesLibres(emp, duree, max, sauf) {
                var out = [];
                M.jours.forEach(function (j) {
                    if (out.length >= max) return;
                    var depart = 8 * 60;
                    if (j < M.aujourdhui) return;
                    if (j === M.aujourdhui) depart = Math.max(depart, Math.ceil((M.maintenant + 1) / 30) * 30);
                    for (var h = depart; h + duree <= 18 * 60 && out.length < max; h += 30) {
                        if (libre(j, emp, h, h + duree, sauf)) { out.push({ j: j, h: h }); h += Math.max(0, duree - 30) + 60; }
                    }
                });
                return out;
            }

            function envoyer(action, data) {
                document.getElementById('hfAction').value = action;
                document.getElementById('hfData').value = JSON.stringify(data);
                document.getElementById('btnAction').click();
            }

            // =================== En-tête ===================
            function peindreTete() {
                var t = el('div', 'ag-tete');
                var ico = el('span', 'ag-ico'); ico.innerHTML = CAL; t.appendChild(ico);
                var nT = 0, mT = 0;
                periode.forEach(function (j) { visibles(j).forEach(function (r) { nT++; mT += r.fin - r.deb; }); });
                var ti = el('span', 'ag-titre'); ti.appendChild(el('b', '', T.toutAgenda));
                ti.appendChild(el('span', '', fmt(T.resume, nT, nbH(mT)) + (s.emp ? ' · ' + nomEmp(s.emp) : (M.emps.length > 1 ? T.toutEquipe : ''))));
                t.appendChild(ti);

                function lien(debut) { var u = new URL(window.location.href); u.searchParams.set('debut', debut); return u.toString(); }
                var nav = el('div', 'ag-nav');
                var p = el('a', '', '‹'); p.href = lien(M.prec); p.setAttribute('aria-label', T.prec5); p.title = T.prec5; nav.appendChild(p);
                var d0 = dJ(periode[0]), d4 = dJ(periode[4]);
                var lib = d0.getMonth() === d4.getMonth()
                    ? fmt(T.periodeDuAu, d0.getDate(), d4.toLocaleDateString(LOC, { day: 'numeric', month: 'long', year: 'numeric' }))
                    : fmt(T.periodeDuAu, d0.toLocaleDateString(LOC, { day: 'numeric', month: 'long' }), d4.toLocaleDateString(LOC, { day: 'numeric', month: 'long', year: 'numeric' }));
                nav.appendChild(el('b', '', lib));
                var n = el('a', '', '›'); n.href = lien(M.suiv); n.setAttribute('aria-label', T.suiv5); n.title = T.suiv5; nav.appendChild(n);
                t.appendChild(nav);

                var ua = new URL(window.location.href); ua.searchParams.delete('debut');
                var auj = el('a', 'ag-pill' + (periode[0] === M.aujourdhui ? ' off' : ''), T.aujourdhui); auj.href = ua.toString(); t.appendChild(auj);

                if (M.emps.length) {
                    var se = el('select'); se.setAttribute('aria-label', T.employeAffiche);
                    var o0 = el('option', '', fmt(T.equipeN, M.emps.length)); o0.value = ''; se.appendChild(o0);
                    M.emps.forEach(function (e) { var o = el('option', '', e.lab); o.value = e.v; se.appendChild(o); });
                    se.value = s.emp;
                    se.addEventListener('change', function () { s.emp = se.value; garder('agEmp', s.emp); peindre(); });
                    t.appendChild(se);
                }
                var plus = bouton('ag-plus', T.plusRdv);
                plus.addEventListener('click', function () {
                    var p0 = plagesLibres(s.emp, 60, 1)[0];
                    nouveau(p0 ? p0.j : periode[0], p0 ? p0.h : 9 * 60);
                });
                t.appendChild(plus);
                return t;
            }

            function nouveau(j, min) {
                agOuvrirFiche('wbfAppointmentEdit.aspx?id=0&start=' + encodeURIComponent(j + 'T' + pad(Math.floor(min / 60)) + ':' + pad(min % 60) + ':00') + (s.emp ? '&emp=' + s.emp : ''));
            }

            // =================== Légende ===================
            var ETATS = { termine: ['#E3F3EA', '#0F5A3A', '#43B47A'], encours: ['#E3EBF7', '#143A73', '#1B4F9C'], avenir: ['#E8EDF5', '#44536E', '#8D9CB3'] };
            function chipEtat(etat) {
                var c = ETATS[etat] || ETATS.avenir;
                var sp = el('span', 'ag-chip', etat === 'termine' ? T.lTermine : etat === 'encours' ? T.lEnCours : T.lAVenir);
                sp.style.background = c[0]; sp.style.color = c[1]; return sp;
            }
            function peindreLegende() {
                var l = el('div', 'ag-leg');
                ['termine', 'encours', 'avenir'].forEach(function (k) { var c = chipEtat(k); var i = el('i'); i.style.background = ETATS[k][2]; c.insertBefore(i, c.firstChild); l.appendChild(c); });
                if (!s.emp && M.emps.length > 1) {
                    M.emps.forEach(function (e) { var sp = el('span', 'ag-emp'); var i = el('i'); i.style.background = e.c; sp.appendChild(i); sp.appendChild(document.createTextNode(e.lab)); l.appendChild(sp); });
                }
                l.appendChild(el('span', 'aide', T.aide));
                return l;
            }

            // =================== La grille ===================
            // Les RDV qui se chevauchent se partagent la largeur de la colonne.
            function voies(liste) {
                var fins = [], res = [];
                liste.forEach(function (r) {
                    var v = 0; while (fins[v] > r.deb) v++;
                    fins[v] = r.fin; res.push({ r: r, v: v });
                });
                res.forEach(function (x) {
                    var n = 1;
                    res.forEach(function (y) { if (y.r.deb < x.r.fin && y.r.fin > x.r.deb) n = Math.max(n, y.v + 1); });
                    x.n = n;
                });
                return res;
            }
            function peindreGrille() {
                var g = el('div', 'ag-grille'), cols = el('div', 'ag-cols');
                var haut = (H1 - H0) * PX;
                cols.appendChild(el('div'));
                periode.forEach(function (j) {
                    var l = visibles(j);
                    var jt = el('div', 'ag-jt' + (j === M.aujourdhui ? ' auj' : ''));
                    jt.appendChild(el('b', '', jCourt(j) + (j === M.aujourdhui ? ' · ' + T.auj : '')));
                    jt.appendChild(el('span', '', fmt(T.rdvH, l.length, nbH(l.reduce(function (t, r) { return t + (r.fin - r.deb); }, 0)))));
                    cols.appendChild(jt);
                });
                var hs = el('div', 'ag-heures'); hs.style.height = haut + 'px';
                for (var h = H0; h <= H1; h += 60) { var sp = el('span', '', fH(h).replace(/ h$/, ' h')); sp.style.top = ((h - H0) * PX) + 'px'; if (h > H0) hs.appendChild(sp); }
                cols.appendChild(hs);
                periode.forEach(function (j) {
                    var c = el('div', 'ag-col' + (j === M.aujourdhui ? ' auj' : '')); c.style.height = haut + 'px';
                    for (var h = H0 + 60; h < H1; h += 60) { var li = el('div', 'ag-ligne-h'); li.style.top = ((h - H0) * PX) + 'px'; c.appendChild(li); }
                    if (j === M.aujourdhui && M.maintenant > H0 && M.maintenant < H1) { var mt = el('div', 'ag-maint'); mt.style.top = ((M.maintenant - H0) * PX) + 'px'; c.appendChild(mt); }
                    // Une heure libre : nouveau RDV à cette heure (à la demi-heure près).
                    c.title = '';
                    c.addEventListener('click', function (ev) {
                        if (ev.target !== c) return;
                        var y = ev.offsetY, min = H0 + Math.floor(y / PX / 30) * 30;
                        nouveau(j, min);
                    });
                    c.addEventListener('mousemove', function (ev) {
                        if (ev.target !== c) return;
                        c.title = fmt(T.nouveauIci, jLong(j), fH(H0 + Math.floor(ev.offsetY / PX / 30) * 30));
                    });
                    voies(visibles(j)).forEach(function (x) {
                        var r = x.r, b = bouton('ag-ev ' + r.etat + (s.sel === r.id ? ' sel' : ''));
                        b.style.top = ((r.deb - H0) * PX + 1) + 'px';
                        b.style.height = Math.max(22, (r.fin - r.deb) * PX - 2) + 'px';
                        b.style.left = (x.v * 100 / x.n) + '%';
                        b.style.width = 'calc(' + (100 / x.n) + '% - 3px)';
                        b.style.borderLeftColor = r.c;
                        b.appendChild(el('span', 'l1', fH(r.deb) + '–' + fH(r.fin) + ' ' + r.client));
                        if (r.fin - r.deb >= 45 && r.objet) b.appendChild(el('span', 'l2', r.objet));
                        if (r.fin - r.deb >= 60) b.appendChild(chipEtat(r.etat));
                        b.title = fH(r.deb) + '–' + fH(r.fin) + ' · ' + r.client + (r.objet ? ' · ' + r.objet : '') + (r.empNom ? ' · ' + r.empNom : '');
                        b.addEventListener('click', function () { choisir(r); });
                        c.appendChild(b);
                    });
                    cols.appendChild(c);
                });
                g.appendChild(cols);
                return g;
            }

            // =================== Le panneau de droite ===================
            function choisir(r) {
                s.sel = r.id;
                s.ed = { r: r, j: r.jour, h: r.deb, d: r.fin - r.deb, e: r.emp, ech: '' };
                peindre();
            }
            function champ(lab, opts, val, onchange) {
                var l = el('label', 'ag-champ', lab), se = el('select');
                opts.forEach(function (o) { var op = el('option', '', o[1]); op.value = o[0]; se.appendChild(op); });
                se.value = String(val);
                se.addEventListener('change', function () { onchange(se.value); peindre(); });
                l.appendChild(se); return l;
            }
            function peindrePanneau() {
                var p = el('aside', 'ag-panneau');
                if (!s.ed) {
                    p.appendChild(el('h2', '', T.majAide));
                    p.appendChild(el('p', '', T.aide));
                    p.appendChild(el('h2', '', T.plagesLibres));
                    var pl = plagesLibres(s.emp, 60, 6);
                    var ch = el('div', 'ag-libres');
                    pl.forEach(function (x) {
                        var b = bouton('', jCourt(x.j) + ' · ' + fH(x.h)); b.title = fmt(T.nouveauIci, jLong(x.j), fH(x.h));
                        b.addEventListener('click', function () { nouveau(x.j, x.h); }); ch.appendChild(b);
                    });
                    if (!pl.length) p.appendChild(el('p', '', T.aucunePlage)); else p.appendChild(ch);
                    return p;
                }
                var ed = s.ed, r = ed.r;
                p.appendChild(el('h2', '', T.majTitre));
                var c = el('div', 'ag-carte'); c.style.borderLeftColor = r.c;
                c.appendChild(el('b', '', r.client));
                if (r.objet) c.appendChild(el('span', '', r.objet));
                var det = [jLong(r.jour) + ', ' + fH(r.deb) + '–' + fH(r.fin), r.lieu, r.empNom].filter(Boolean).join(' · ');
                c.appendChild(el('span', '', det));
                p.appendChild(c);
                if (r.etat === 'termine') p.appendChild(el('div', 'ag-msg info', T.facturable));

                p.appendChild(champ(T.jour, M.jours.map(function (j) { return [j, jLong(j)]; }), ed.j, function (v) { ed.j = v; ed.ech = ''; }));
                var heures = [], durees = [];
                for (var h = 6 * 60; h <= 21 * 60; h += 15) heures.push([h, fH(h)]);
                [15, 30, 45, 60, 75, 90, 105, 120, 150, 180, 210, 240, 300, 360, 480].forEach(function (d) { durees.push([d, fD(d)]); });
                if (!heures.some(function (x) { return x[0] === ed.h; })) heures.push([ed.h, fH(ed.h)]);
                if (!durees.some(function (x) { return x[0] === ed.d; })) durees.push([ed.d, fD(ed.d)]);
                var deux = el('div', 'ag-deux');
                deux.appendChild(champ(T.heure, heures.sort(function (a, b) { return a[0] - b[0]; }), ed.h, function (v) { ed.h = +v; ed.ech = ''; }));
                deux.appendChild(champ(T.duree, durees.sort(function (a, b) { return a[0] - b[0]; }), ed.d, function (v) { ed.d = +v; ed.ech = ''; }));
                p.appendChild(deux);
                if (M.emps.length) {
                    p.appendChild(champ(T.employe, [['', T.aucunEmploye]].concat(M.emps.map(function (e) { return [e.v, e.lab]; })), ed.e, function (v) { ed.e = v; ed.ech = ''; }));
                }

                // Plages libres pour ce RDV (même employé, même durée)
                var pl = plagesLibres(ed.e, ed.d, 4, r.id);
                if (pl.length) {
                    var bl = el('div', 'ag-champ', T.plageLibre), ch = el('div', 'ag-libres');
                    pl.forEach(function (x) {
                        var on = x.j === ed.j && x.h === ed.h;
                        var b = bouton('', jCourt(x.j) + ' · ' + fH(x.h)); b.setAttribute('aria-pressed', on ? 'true' : 'false');
                        b.addEventListener('click', function () { ed.j = x.j; ed.h = x.h; ed.ech = ''; peindre(); });
                        ch.appendChild(b);
                    });
                    bl.appendChild(ch); p.appendChild(bl);
                }

                // Échanger avec un autre RDV de la période
                var autres = M.rdv.filter(function (x) { return x.id !== r.id && periode.indexOf(x.jour) >= 0; })
                                  .sort(function (a, b) { return a.jour < b.jour ? -1 : a.jour > b.jour ? 1 : a.deb - b.deb; });
                if (autres.length) {
                    p.appendChild(champ(T.echanger, [['', T.aucunEchange]].concat(autres.map(function (x) { return [x.id, jCourt(x.jour) + ' ' + fH(x.deb) + ' · ' + x.client]; })), ed.ech,
                        function (v) { ed.ech = v; if (v) { ed.j = r.jour; ed.h = r.deb; ed.d = r.fin - r.deb; ed.e = r.emp; } }));
                }

                var change = ed.j !== r.jour || ed.h !== r.deb || ed.d !== r.fin - r.deb || ed.e !== r.emp;
                if (!ed.ech && change) {
                    var conf = M.rdv.filter(function (x) { return x.id !== r.id && x.jour === ed.j && (!ed.e || !x.emp || x.emp === ed.e) && x.deb < ed.h + ed.d && x.fin > ed.h; })[0];
                    if (conf) p.appendChild(el('div', 'ag-msg conflit', fmt(T.conflit, ed.e ? nomEmp(ed.e) : (conf.empNom || T.aucunEmploye), fH(conf.deb) + ' · ' + conf.client)));
                    p.appendChild(el('div', 'ag-msg change', fmt(T.changement, jLong(ed.j) + ', ' + fH(ed.h) + '–' + fH(ed.h + ed.d) + (M.emps.length ? ' · ' + nomEmp(ed.e) : ''))));
                }
                if (ed.ech) {
                    var o = M.rdv.filter(function (x) { return String(x.id) === String(ed.ech); })[0];
                    if (o) p.appendChild(el('div', 'ag-msg change', fmt(T.changement, r.client + ' → ' + jCourt(o.jour) + ' ' + fH(o.deb) + ' · ' + o.client + ' → ' + jCourt(r.jour) + ' ' + fH(r.deb))));
                }
                var en = bouton('ag-btn', T.enregistrer); en.disabled = !change && !ed.ech;
                en.addEventListener('click', function () {
                    en.disabled = true;
                    if (ed.ech) envoyer('echanger', { id: r.id, autre: +ed.ech });
                    else envoyer('maj', { id: r.id, jour: ed.j, deb: ed.h, duree: ed.d, emp: ed.e });
                });
                p.appendChild(en);
                var ra = el('div', 'ag-rangee');
                var fi = bouton('ag-btn clair', T.ficheComplete); fi.addEventListener('click', function () { agOuvrirFiche('wbfAppointmentEdit.aspx?id=' + r.id); });
                ra.appendChild(fi); p.appendChild(ra);
                var rb = el('div', 'ag-rangee');
                var an = bouton('ag-btn rouge', T.annulerRdv);
                an.addEventListener('click', function () { if (window.confirm(T.confirmAnnuler)) envoyer('annuler', { id: r.id }); });
                var fe = bouton('ag-btn clair', T.fermer); fe.addEventListener('click', function () { s.sel = null; s.ed = null; peindre(); });
                rb.appendChild(an); rb.appendChild(fe); p.appendChild(rb);
                return p;
            }

            function peindre() {
                var y = window.scrollY;
                racine.innerHTML = '';
                racine.appendChild(peindreTete());
                racine.appendChild(peindreLegende());
                var corps = el('div', 'ag-corps');
                corps.appendChild(peindreGrille());
                corps.appendChild(peindrePanneau());
                racine.appendChild(corps);
                window.scrollTo(0, y);
            }
            peindre();

            // =================== Les rappels ===================
            // Chaque minute, tant que la page est ouverte : un RDV d'aujourd'hui dont le rappel
            // est atteint (début − délai) et qui n'est pas commencé s'annonce 8 secondes en haut à droite.
            var vus = {};
            var CLOCHE = '<svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#D9A03C" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0"></path></svg>';
            function rappels() {
                var n = new Date(), j = n.getFullYear() + '-' + pad(n.getMonth() + 1) + '-' + pad(n.getDate()), m = n.getHours() * 60 + n.getMinutes();
                M.rdv.forEach(function (r) {
                    if (r.jour !== j || !(r.rappel >= 0) || vus[r.id] || m < r.deb - r.rappel || m >= r.deb) return;
                    vus[r.id] = 1;
                    var t = el('div', 'ag-rappel'); t.setAttribute('role', 'status');
                    t.style.cssText = 'position:fixed;top:' + (18 + 76 * document.querySelectorAll('.ag-rappel').length) + 'px;right:18px;z-index:100000;display:flex;gap:10px;align-items:flex-start;max-width:340px;padding:12px 16px;border-radius:16px;background:#0E1F3D;color:#FFFFFF;font-family:Nunito,sans-serif;box-shadow:0 12px 30px rgba(14,31,61,.35)';
                    var ic = el('span'); ic.innerHTML = CLOCHE; t.appendChild(ic);
                    var tx = el('span'); tx.style.cssText = 'display:flex;flex-direction:column;line-height:1.25';
                    tx.appendChild(el('b', '', r.client + (r.objet ? ' · ' + r.objet : '')));
                    tx.appendChild(el('span', '', fmt(T.rappelA, fH(r.deb))));
                    t.appendChild(tx); document.body.appendChild(t);
                    setTimeout(function () { t.remove(); }, 8000);
                });
            }
            rappels(); setInterval(rappels, 60000);
        })();
    </script>
</asp:Content>
