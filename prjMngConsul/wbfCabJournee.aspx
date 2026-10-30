<%@ Page Title="Ma journée" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabJournee.aspx.vb" Inherits="MngConsul.wbfCabJournee" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Portail comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .jrn { width: 100%; display: flex; flex-direction: column; gap: 16px; color: #0E1F3D }
    .jrn button { font-family: inherit }

    .jrn-top { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 8px 16px }
    .jrn-top h1 { margin: 0; font-size: 28px; font-weight: 800; line-height: 1.15 }
    .jrn-top .sub { margin: 4px 0 0; font-size: 16px; color: #44536E }
    .jrn-echelle { padding: 6px 14px; border-radius: 999px; background: #0E1F3D; color: #E7C377; font-weight: 800; font-size: 14px; white-space: nowrap }

    .jrn-illus { display: flex; gap: 10px; align-items: center; padding: 10px 14px; border-radius: 14px;
        background: #FBF1DC; color: #7A5200; font-size: 13.5px; font-weight: 600 }
    .jrn-illus svg { flex: 0 0 18px }

    .jrn-card { background: #fff; border-radius: 24px; padding: 18px 20px; display: flex; flex-direction: column; gap: 10px }
    .jrn-card h2 { margin: 0; font-size: 19px; font-weight: 800 }
    .jrn-card .psous { font-size: 14px; color: #44536E }

    /* Santé */
    .jrn-sante { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px }
    .jrn-tile { border: 2px solid transparent; border-radius: 22px; padding: 14px 16px; text-align: left; cursor: pointer }
    .jrn-tile .n { font-size: 30px; font-weight: 800; line-height: 1 }
    .jrn-tile .l { font-weight: 700; margin-top: 4px }
    .jrn-tile .s { font-size: 12.5px; opacity: .8; margin-top: 2px }

    /* 60 conseille */
    .jrn-60 { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 14px; padding: 14px 18px; border-radius: 22px;
        background: #0E1F3D; color: #fff }
    .jrn-60 .tag { font-weight: 800; color: #E7C377; white-space: nowrap }
    .jrn-60 .txt { flex: 1 1 240px; font-weight: 700 }
    .jrn-60 .go { min-height: 40px; padding: 0 18px; border: 0; border-radius: 999px; background: #E7C377; color: #0E1F3D; font-weight: 800; cursor: pointer }

    /* Employés */
    .jrn-emp { width: 100%; display: grid; grid-template-columns: 40px minmax(0,1fr) minmax(0,1.3fr); gap: 6px 12px;
        align-items: center; padding: 10px 12px; border-radius: 18px; border: 2px solid transparent; background: #F2F5F9; color: #0E1F3D; text-align: left; cursor: pointer }
    .jrn-emp.on { border-color: #1B4F9C }
    .jrn-emp .av { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
        font-weight: 800; font-size: 13px; background: #E3EBF7; color: #143A73 }
    .jrn-emp .nom { font-weight: 800 }
    .jrn-emp .nom .demo { font-size: 11px; font-weight: 800; color: #7A5200; background: #FBF1DC; border-radius: 999px; padding: 1px 7px; margin-left: 6px }
    .jrn-emp .sous { font-size: 13px; color: #44536E }
    .jrn-bar { display: flex; height: 14px; border-radius: 999px; overflow: hidden; background: #E8EDF5 }
    .jrn-bar i { display: block }
    .jrn-emp .leg { display: flex; gap: 10px; font-size: 13.5px; font-weight: 800; margin-top: 4px }

    /* Filtres */
    .jrn-filt { padding: 10px 14px; border-radius: 18px; background: #fff; border: 1px solid #E3E9F1; display: flex; flex-direction: column; gap: 8px }
    .jrn-srch { flex: 1 1 240px; display: flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 12px; border: 1px solid #D5DDE8; border-radius: 12px; background: #F7F9FC }
    .jrn-srch input { border: 0; outline: none; flex-grow: 1; min-width: 0; background: transparent; color: #0E1F3D; font-size: 15px }
    .jrn-seg { display: flex; flex-wrap: wrap; gap: 2px; padding: 3px; background: #EEF2F7; border-radius: 11px }
    .jrn-seg button { min-height: 30px; padding: 0 11px; border: 0; border-radius: 9px; font-weight: 800; font-size: 14px; background: transparent; color: #44536E; cursor: pointer }
    .jrn-seg button.on { background: #fff; color: #0E1F3D; box-shadow: 0 1px 2px rgba(14,31,61,.12) }
    .jrn-lbl { flex: 0 0 74px; font-size: 12px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; color: #6A7891 }
    .jrn-chips { flex: 1 1 300px; display: flex; flex-wrap: wrap; gap: 6px }
    .jrn-chip { min-height: 30px; padding: 0 10px; border-radius: 9px; font-weight: 700; font-size: 13px; display: flex; align-items: center; gap: 6px; border: 1px solid #AEBBCD; background: #fff; color: #0E1F3D; cursor: pointer }
    .jrn-chip.on { background: #0E1F3D; color: #fff; border-color: #0E1F3D }
    .jrn-clear { display: flex; align-items: center; gap: 6px; min-height: 36px; padding: 0 12px; border: 0; border-radius: 10px; background: #FDEBEA; color: #A3261C; font-weight: 800; cursor: pointer }

    /* Liste */
    .jrn-grp { background: #fff; border-radius: 24px; padding: 16px; display: flex; flex-direction: column; gap: 8px }
    .jrn-grp > h3 { margin: 0 0 4px; display: flex; align-items: center; gap: 10px; font-size: 18px; font-weight: 800 }
    .jrn-grp > h3 .dot { width: 12px; height: 12px; border-radius: 50%; flex: 0 0 12px }
    .jrn-grp > h3 .c { font-weight: 700; color: #5B6B86; font-size: 15px }
    .jrn-row { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 14px; padding: 12px 14px; border-radius: 18px; background: #F2F5F9 }
    .jrn-row .c60 { width: 42px; height: 42px; flex: 0 0 42px; padding: 0; border: 0; background: none; display: flex; align-items: center; justify-content: center; cursor: pointer }
    .jrn-row .c60 i { width: 16px; height: 16px; border-radius: 50%; border: 2px solid #D5DDE8; box-sizing: border-box }
    .jrn-row .mid { flex: 1 1 260px; min-width: 0; display: flex; flex-direction: column; gap: 2px }
    .jrn-row .mid .a { font-weight: 800 }
    .jrn-row .mid .m { display: flex; flex-wrap: wrap; gap: 4px 8px; align-items: center; font-size: 14px; color: #44536E }
    .jrn-row .mid .m a, .jrn-row .mid .m .clk { padding: 0; border: 0; background: none; color: #1B4F9C; font-weight: 800; text-decoration: underline; cursor: pointer }
    .jrn-peut { padding: 3px 10px; border-radius: 999px; background: #FCE9D9; color: #8A4100; font-size: 13px; font-weight: 800; white-space: nowrap }
    .jrn-chipw { padding: 4px 12px; border-radius: 999px; font-size: 14px; font-weight: 800 }
    .jrn-do { min-height: 40px; padding: 0 16px; border-radius: 999px; font-weight: 800; border: 1px solid #1B4F9C; background: #1B4F9C; color: #fff; cursor: pointer }
    .jrn-do.ghost { background: #fff; color: #1B4F9C }
    .jrn-note { flex: 1 1 100%; display: flex; gap: 10px; align-items: flex-start; padding: 12px 14px; border-radius: 16px 16px 16px 4px; background: #fff; border: 1px solid #E7C377 }
    .jrn-note .tag { font-weight: 800; white-space: nowrap; color: #7A5200 }
    .jrn-done { margin: 0; color: #44536E; font-weight: 700 }
    .jrn-empty { padding: 24px; border-radius: 24px; background: #fff; text-align: center; color: #44536E; font-weight: 700 }

    /* Toast */
    .jrn-toast { position: fixed; left: 50%; bottom: 28px; transform: translateX(-50%); z-index: 60;
        background: #0E1F3D; color: #fff; padding: 12px 18px; border-radius: 999px; font-weight: 700;
        box-shadow: 0 8px 24px rgba(14,31,61,.3); opacity: 0; transition: opacity .2s; pointer-events: none; max-width: 90vw }
    .jrn-toast.show { opacity: 1 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="journee-app" class="jrn"></div>
<div id="jrn-toast" class="jrn-toast" role="status" aria-live="polite"></div>

<script>
(function () {
    var D = <asp:Literal ID="litData" runat="server" />;
    var L = <asp:Literal ID="litLabels" runat="server" />;
    var root = document.getElementById('journee-app');
    if (!root || !D) return;

    var emps = D.emps || [], actions = D.actions || [];
    var empById = {}; emps.forEach(function (e) { empById[e.id] = e; });

    var P = {
        r: { lab: L.urgent, bg: '#FDECEA', fg: '#A3261C', dot: '#E35D55', o: 0 },
        y: { lab: L.surveiller, bg: '#FBF1DC', fg: '#7A5200', dot: '#E3B341', o: 1 },
        g: { lab: L.bien, bg: '#E3F3EA', fg: '#0F5A3A', dot: '#43B47A', o: 2 }
    };
    function prioOf(a) {
        if (a.fait) return 'g';
        if (a.etat === 'w') return a.ech <= 1 ? 'y' : 'g';
        if (a.etat === 'b') return 'y';
        return a.ech <= 1 ? 'r' : (a.ech <= 7 ? 'y' : 'g');
    }
    actions.forEach(function (a) { a.pr = prioOf(a); });

    var st = { emp: 'tous', etat: '', prio: 'toutes', grp: 'prio', q: '', c60: '' };

    function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
    function fmt(t, n) { return String(t).replace('{n}', n); }
    function prenom(id) { var e = empById[id]; return e ? e.nom.split(' ')[0] : ''; }

    function echLab(d) {
        if (d >= 999) return L.sansEch;
        if (d < 0) return L.enRetard + ' · ' + fmt(L.ilYaJours, -d);
        if (d === 0) return L.aujourdhui;
        if (d === 1) return L.demain;
        if (d <= 7) return L.cetteSemaine;
        return fmt(L.dansJours, d);
    }
    function poids(a) { return (a.fait ? 9 : P[a.pr].o) * 1000 + (a.ech + 100); }

    // ---- sous-ensembles selon l'état des filtres ----
    function scopeEmp() { return st.emp === 'tous' ? actions : actions.filter(function (a) { return a.empId === st.emp; }); }
    function matchQ(a) {
        if (!st.q) return true;
        var h = (a.cliNom + ' ' + a.actNom + ' ' + (prenom(a.empId) || '') + ' ' + a.secteur).toLowerCase();
        return h.indexOf(st.q.toLowerCase()) >= 0;
    }
    function filtered() {
        return scopeEmp().filter(function (a) {
            return (st.prio === 'toutes' || a.pr === st.prio)
                && (!st.etat || a.etat === st.etat)
                && matchQ(a);
        });
    }

    // ---- barre de santé (r/y) pour un ensemble d'actions ouvertes ----
    function barre(list) {
        var o = list.filter(function (a) { return !a.fait; });
        var r = o.filter(function (a) { return a.pr === 'r'; }).length;
        var y = o.filter(function (a) { return a.pr === 'y'; }).length;
        var t = Math.max(1, o.length);
        return { r: r, y: y, wr: (r * 100 / t) + '%', wy: (y * 100 / t) + '%' };
    }

    function h(tag, attrs, inner) {
        var s = '<' + tag;
        for (var k in attrs) if (attrs[k] != null) s += ' ' + k + '="' + attrs[k] + '"';
        return s + '>' + (inner == null ? '' : inner) + '</' + tag + '>';
    }

    function render() {
        var open = scopeEmp().filter(function (a) { return !a.fait; });
        var urgA = open.filter(function (a) { return a.pr === 'r' && a.etat === 'a'; }).length;

        var html = '';

        // En-tête
        var echelle = emps.length <= 1 ? L.echelleSolo : fmt(L.echelleN, emps.length);
        html += '<div class="jrn-top">'
            + '<div style="flex:1 1 320px;min-width:0">'
            + '<h1>' + esc(L.bonjour) + ' ' + esc(D.prenom) + '!</h1>'
            + '<p class="sub">' + esc(L.sousTitre) + '</p></div>'
            + '<span class="jrn-echelle">' + esc(echelle) + '</span></div>';

        // Avis « illustratif » (uniquement en repli, quand il n'y a pas de tâche réelle)
        if (!D.reel) html += '<div class="jrn-illus">'
            + '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7A5200" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v4h1"/></svg>'
            + '<span>' + esc(L.illustratif) + '</span></div>';

        // 60 conseille
        var msg = urgA ? (urgA === 1 ? L.commencez1 : fmt(L.commencez, urgA)) : L.ordre;
        html += '<div class="jrn-60"><span class="tag">' + esc(L.conseille) + '</span>'
            + '<span class="txt">' + esc(msg) + '</span>'
            + (urgA ? '<button class="go" data-prio="r">' + esc(L.urgent) + ' →</button>' : '') + '</div>';

        // Panneau employés
        html += '<section class="jrn-card"><div style="display:flex;flex-wrap:wrap;align-items:center;gap:6px 12px">'
            + '<h2 style="flex-grow:1">' + esc(L.panTitre) + '</h2>'
            + '<span class="psous">' + esc(L.panSous) + '</span></div>';
        var persos = emps.map(function (e) {
            var list = actions.filter(function (a) { return a.empId === e.id; });
            var b = barre(list);
            var nOpen = list.filter(function (a) { return !a.fait; }).length;
            return { e: e, b: b, nOpen: nOpen };
        }).sort(function (a, b) { return b.b.r - a.b.r || b.b.y - a.b.y; });
        persos.forEach(function (x) {
            var on = st.emp === x.e.id;
            html += h('button', { 'class': 'jrn-emp' + (on ? ' on' : ''), 'data-emp': x.e.id, 'aria-pressed': on },
                '<span class="av">' + esc(x.e.init) + '</span>'
                + '<span style="display:flex;flex-direction:column;min-width:0">'
                + '<span class="nom">' + esc(x.e.nom) + (x.e.demo ? '<span class="demo">démo</span>' : '') + '</span>'
                + '<span class="sous">' + x.nOpen + ' ' + esc(L.aFaire) + '</span></span>'
                + '<span style="display:flex;flex-direction:column;gap:4px">'
                + '<span class="jrn-bar"><i style="width:' + x.b.wr + ';background:#E35D55"></i><i style="width:' + x.b.wy + ';background:#E3B341"></i></span>'
                + '<span class="leg"><span style="color:#A3261C">' + fmt(L.urgentN, x.b.r) + '</span><span style="color:#7A5200">' + fmt(L.surveillerN, x.b.y) + '</span></span></span>');
        });
        html += '</section>';

        // Barre de filtres
        html += '<section class="jrn-filt">';
        html += '<div style="display:flex;flex-wrap:wrap;gap:8px 12px;align-items:center">'
            + '<label class="jrn-srch"><svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#1B4F9C" stroke-width="2.4" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>'
            + '<input id="j-search" type="text" data-role="search" placeholder="' + esc(L.chercher) + '" value="' + esc(st.q) + '" aria-label="' + esc(L.chercher) + '"></label>'
            + '<div style="display:flex;flex-wrap:wrap;gap:6px 8px;align-items:center"><span class="jrn-lbl" style="flex:0 0 auto">' + esc(L.regrouper) + '</span>'
            + '<div class="jrn-seg">' + seg() + '</div></div>';
        var actif = st.etat || st.prio !== 'toutes' || st.emp !== 'tous' || st.q;
        if (actif) html += '<button class="jrn-clear" data-clear="1"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#A3261C" stroke-width="2.6" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>' + esc(L.effacer) + '</button>';
        html += '</div>';
        // ligne État
        var tousE = scopeEmp().filter(function (a) { return !a.fait && matchQ(a); });
        html += etatLine(tousE);
        // ligne Employé
        html += empLine();
        html += '</section>';

        // Liste groupée
        html += '<h2 style="margin:8px 0 0;font-size:20px;font-weight:800">' + esc(L.toutesActions) + '</h2>';
        var groupes = grouper(filtered());
        if (!groupes.length) html += '<div class="jrn-empty">' + esc(L.rienFiltres) + '</div>';
        groupes.forEach(function (g) {
            html += '<section class="jrn-grp"><h3><span class="dot" style="background:' + g.dot + '"></span>'
                + esc(g.lab) + '<span class="c">' + g.n + '</span></h3>';
            g.rows.forEach(function (a) { html += rowHtml(a); });
            html += '</section>';
        });

        // Faites aujourd'hui
        var faits = scopeEmp().filter(function (a) { return a.fait; }).length;
        if (faits) html += '<p class="jrn-done">✓ ' + esc(fmt(L.faitsN, faits)) + '</p>';

        root.innerHTML = html;
    }

    function tile(k, n, lab, sous) {
        var on = st.prio === k;
        return h('button', {
            'class': 'jrn-tile', 'data-prio': k, 'aria-pressed': on,
            style: 'background:' + P[k].bg + ';color:' + P[k].fg + (on ? ';border-color:' + P[k].fg : '')
        }, '<div class="n">' + n + '</div><div class="l">' + esc(lab) + '</div><div class="s">' + esc(sous) + '</div>');
    }

    function seg() {
        var vues = [['prio', L.gPrio], ['client', L.gClient], ['activite', L.gActivite], ['ech', L.gEch], ['emp', L.gEmp]];
        return vues.map(function (v) {
            var on = st.grp === v[0];
            return '<button data-grp="' + v[0] + '"' + (on ? ' class="on" aria-pressed="true"' : '') + '>' + esc(v[1]) + '</button>';
        }).join('');
    }

    function etatLine(scope) {
        var defs = [['', L.tous], ['a', L.etatA], ['w', L.etatW], ['b', L.etatB]];
        var chips = defs.map(function (d) {
            var n = d[0] === '' ? scope.length : scope.filter(function (a) { return a.etat === d[0]; }).length;
            var on = st.etat === d[0];
            return '<button class="jrn-chip' + (on ? ' on' : '') + '" data-etat="' + d[0] + '">' + esc(d[1]) + ' · ' + n + '</button>';
        }).join('');
        return '<div style="display:flex;flex-wrap:wrap;gap:6px 10px;align-items:center"><span class="jrn-lbl">' + esc(L.etat) + '</span><div class="jrn-chips">' + chips + '</div></div>';
    }

    function empLine() {
        var chips = '<button class="jrn-chip' + (st.emp === 'tous' ? ' on' : '') + '" data-emp="tous">' + esc(L.tous) + '</button>';
        emps.forEach(function (e) {
            var on = st.emp === e.id;
            chips += '<button class="jrn-chip' + (on ? ' on' : '') + '" data-emp="' + e.id + '">' + esc(prenom(e.id)) + '</button>';
        });
        return '<div style="display:flex;flex-wrap:wrap;gap:6px 10px;align-items:center"><span class="jrn-lbl">' + esc(L.employe) + '</span><div class="jrn-chips">' + chips + '</div></div>';
    }

    function grouper(list) {
        var KEY, LAB;
        if (st.grp === 'client') { KEY = function (a) { return a.cliNom; }; LAB = function (k) { return k; }; }
        else if (st.grp === 'activite') { KEY = function (a) { return a.sujet; }; LAB = function (k) { return k; }; }
        else if (st.grp === 'emp') { KEY = function (a) { return a.empId; }; LAB = function (k) { return empById[k] ? empById[k].nom : k; }; }
        else if (st.grp === 'ech') {
            KEY = function (a) { return a.fait ? 'fait' : (a.ech <= 1 ? 'a' : (a.ech <= 7 ? 'b' : 'c')); };
            LAB = function (k) { return { a: L.aujourdhui + ' / ' + L.demain, b: L.cetteSemaine, c: L.plusTard, fait: L.faitAuj }[k]; };
        } else {
            KEY = function (a) { return a.fait ? 'fait' : a.pr; };
            LAB = function (k) { return k === 'fait' ? L.faitAuj : (k === 'g' ? L.sansUrg : P[k].lab); };
        }
        var gm = {};
        list.forEach(function (a) { var k = KEY(a); (gm[k] = gm[k] || []).push(a); });
        return Object.keys(gm).map(function (k) {
            var l = gm[k].sort(function (a, b) { return poids(a) - poids(b); });
            var w = Math.min.apply(null, l.map(poids));
            var dotPr = l[0].fait ? 'g' : l[0].pr;
            return { lab: LAB(k), n: l.length, w: w, dot: (w >= 9000 || (st.grp === 'prio' && k === 'g')) ? '#AEBBCD' : P[dotPr].dot, rows: l };
        }).sort(function (a, b) { return a.w - b.w; });
    }

    function rowHtml(a) {
        var op = a.fait ? '.65' : '1';
        var c60col = a.fait ? '#FFFFFF' : P[a.pr].dot;
        var hasC = !!a.conseil;
        var open = hasC && st.c60 === a.id;
        // lien client
        var cli = a.cliGuid
            ? '<a href="wbfCabFiche.aspx?company=' + encodeURIComponent(a.cliGuid) + '">' + esc(a.cliNom) + '</a>'
            : '<button class="clk" data-demoopen="1">' + esc(a.cliNom) + '</button>';
        // pastille de conseil (bouton si un conseil existe, sinon simple point)
        var dot = hasC
            ? '<button class="c60" data-c60="' + a.id + '" aria-expanded="' + open + '" title="' + esc(L.conseille) + '"><i style="background:' + c60col + '"></i></button>'
            : '<span class="c60"><i style="background:' + c60col + '"></i></span>';
        // bouton d'action : réel (« Marquer comme fait ») ou illustratif
        var btn = '';
        if (!a.fait) {
            if (D.reel) {
                btn = '<button class="jrn-do" data-done="' + a.taskId + '">' + esc(L.faitBtn) + '</button>';
            } else {
                var lab = a.etat === 'w' ? L.suivreClient : (a.etat === 'b' ? L.demanderAcces : L.faireAvec);
                btn = '<button class="jrn-do' + (a.etat !== 'a' ? ' ghost' : '') + '" data-demoact="1">' + esc(lab) + '</button>';
            }
        }
        // méta : client · (secteur) · échéance · (employé)
        var meta = cli
            + (a.secteur ? '<span>' + esc(a.secteur) + '</span>' : '')
            + '<span>· ' + esc(echLab(a.ech)) + '</span>'
            + (st.emp === 'tous' ? '<span>· ' + esc(prenom(a.empId)) + '</span>' : '');
        // chips d'état
        var chip = '';
        if (a.fait) chip = '<span class="jrn-chipw" style="background:#E3F3EA;color:#0F5A3A">' + esc(L.faitAuj) + '</span>';
        else if (a.enCours) chip = '<span class="jrn-chipw" style="background:#E3EBF7;color:#143A73">' + esc(L.enCours) + '</span>';
        else if (a.etat === 'b') chip = '<span class="jrn-chipw" style="background:#FBF1DC;color:#7A5200">' + esc(L.etatB) + '</span>';
        var peut = a.peut ? '<span class="jrn-peut">' + esc(L.peutAgir) + ' : ' + esc(a.peut) + '</span>' : '';
        var note = open ? '<div class="jrn-note"><span class="tag">' + esc(L.conseille) + '</span><span style="color:#0E1F3D">' + esc(a.conseil) + '</span></div>' : '';
        return '<div class="jrn-row" style="opacity:' + op + '">'
            + dot
            + '<div class="mid"><span class="a">' + esc(a.actNom) + '</span><span class="m">' + meta + '</span></div>'
            + peut + chip + btn + note + '</div>';
    }

    // ---- Toast ----
    var toastEl = document.getElementById('jrn-toast'), toastT = null;
    function toast(msg) {
        if (!toastEl) return;
        toastEl.textContent = msg; toastEl.classList.add('show');
        clearTimeout(toastT); toastT = setTimeout(function () { toastEl.classList.remove('show'); }, 2600);
    }

    // ---- Interactions (délégation) ----
    function marquerFait(taskId) {
        var body = 'op=done&id=' + encodeURIComponent(taskId);
        fetch(window.location.href, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body })
            .then(function (r) { return r.json(); })
            .then(function (j) {
                if (!j || !j.ok) return toast(L.erreur);
                actions.forEach(function (a) {
                    if (String(a.taskId) === String(taskId)) { a.fait = true; a.etat = ''; a.enCours = false; a.pr = prioOf(a); }
                });
                render(); toast(L.faitOk);
            })
            .catch(function () { toast(L.erreur); });
    }

    root.addEventListener('click', function (ev) {
        var t = ev.target.closest ? ev.target.closest('[data-emp],[data-etat],[data-prio],[data-grp],[data-c60],[data-clear],[data-demoact],[data-demoopen],[data-done]') : null;
        if (!t) return;
        if (t.hasAttribute('data-clear')) { st.etat = ''; st.prio = 'toutes'; st.emp = 'tous'; st.q = ''; return render(); }
        if (t.hasAttribute('data-done')) { ev.preventDefault(); return marquerFait(t.getAttribute('data-done')); }
        if (t.hasAttribute('data-demoact')) { ev.preventDefault(); return toast(L.demoAction); }
        if (t.hasAttribute('data-demoopen')) { ev.preventDefault(); return toast(L.demoToast); }
        if (t.hasAttribute('data-c60')) { var id = t.getAttribute('data-c60'); st.c60 = st.c60 === id ? '' : id; return render(); }
        if (t.hasAttribute('data-grp')) { st.grp = t.getAttribute('data-grp'); return render(); }
        if (t.hasAttribute('data-prio')) { var k = t.getAttribute('data-prio'); st.prio = st.prio === k ? 'toutes' : k; return render(); }
        if (t.hasAttribute('data-etat')) { var e = t.getAttribute('data-etat'); st.etat = st.etat === e ? '' : e; return render(); }
        if (t.hasAttribute('data-emp')) { var m = t.getAttribute('data-emp'); st.emp = st.emp === m ? 'tous' : m; return render(); }
    });
    root.addEventListener('input', function (ev) {
        if (ev.target && ev.target.getAttribute('data-role') === 'search') {
            st.q = ev.target.value;
            render();
            var s = document.getElementById('j-search');
            if (s) { s.focus(); var v = s.value; s.value = ''; s.value = v; }
        }
    });

    render();
})();
</script>
</asp:Content>
