<%@ Page Title="Tous les dossiers" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabDossiers.aspx.vb" Inherits="MngConsul.wbfCabDossiers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Portail comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cl { width: 100%; display: flex; flex-direction: column; gap: 14px; color: #0E1F3D }
    .cl h1 { margin: 0; font-size: 28px; font-weight: 800; line-height: 1.15 }
    .cl .sub { margin: 4px 0 0; font-size: 16px; color: #44536E }

    .cl-filt { padding: 10px 14px; border-radius: 18px; background: #fff; border: 1px solid #E3E9F1; display: flex; flex-direction: column; gap: 8px }
    .cl-srch { flex: 1 1 240px; display: flex; align-items: center; gap: 8px; min-height: 40px; padding: 0 12px; border: 1px solid #D5DDE8; border-radius: 12px; background: #F7F9FC }
    .cl-srch input { border: 0; outline: none; flex-grow: 1; min-width: 0; background: transparent; color: #0E1F3D; font-size: 15px }
    .cl-seg { display: flex; flex-wrap: wrap; gap: 2px; padding: 3px; background: #EEF2F7; border-radius: 11px }
    .cl-seg button { display: flex; align-items: center; gap: 6px; min-height: 30px; padding: 0 11px; border: 0; border-radius: 9px; font-weight: 800; font-size: 14px; background: transparent; color: #44536E; cursor: pointer }
    .cl-seg button.on { background: #fff; color: #0E1F3D; box-shadow: 0 1px 3px rgba(14,31,61,.18) }
    .cl-seg .n { min-width: 20px; height: 20px; box-sizing: border-box; padding: 0 5px; border-radius: 10px; font-size: 11px; font-weight: 800; display: flex; align-items: center; justify-content: center; background: #fff; color: #44536E; border: 1px solid #D5DDE8 }
    .cl-lbl { flex: 0 0 74px; font-size: 12px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; color: #6A7891 }
    .cl-chips { flex: 1 1 300px; display: flex; flex-wrap: wrap; gap: 6px }
    .cl-chip { min-height: 30px; padding: 0 10px; border-radius: 9px; font-weight: 700; font-size: 13px; display: flex; align-items: center; gap: 6px; border: 1px solid #AEBBCD; background: #fff; color: #0E1F3D; cursor: pointer }
    .cl-chip.on { background: #0E1F3D; color: #fff; border-color: #0E1F3D }
    .cl-chip .dot { width: 9px; height: 9px; border-radius: 50% }

    .cl-sec { border-radius: 20px; background: #fff; border: 1px solid #E3E9F1; overflow: hidden }
    .cl-sec > h2 { margin: 0; padding: 12px 16px; display: flex; align-items: center; gap: 10px; font-size: 17px; font-weight: 800; border-bottom: 1px solid #E3E9F1 }
    .cl-sec > h2 .dot { width: 11px; height: 11px; border-radius: 50% }
    .cl-sec > h2 .c { font-weight: 700; color: #5B6B86; font-size: 14px }

    .cl-carte { width: 100%; display: flex; flex-wrap: wrap; align-items: center; gap: 8px 16px; padding: 12px 16px; border: 0; border-bottom: 1px solid #EEF2F7; background: #fff; color: #0E1F3D; text-align: left; text-decoration: none; cursor: pointer }
    .cl-carte:hover { background: #F7F9FC }
    .cl-ident { flex: 1 1 240px; min-width: 0; display: flex; align-items: center; gap: 12px }
    .cl-av { width: 40px; height: 40px; flex-shrink: 0; box-sizing: border-box; border-radius: 50%; border: 3px solid #AEBBCD; background: #E3EBF7; color: #143A73; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 14px }
    .cl-nom { min-width: 0; display: flex; flex-direction: column; line-height: 1.25 }
    .cl-nom .n1 { display: flex; align-items: center; gap: 8px; font-weight: 800; font-size: 16px }
    .cl-badge { padding: 1px 8px; border-radius: 999px; background: #FBF1DC; color: #7A5200; font-size: 11px; font-weight: 800 }
    .cl-nom .n2 { font-size: 13px; color: #5B6B86 }
    .cl-next { flex: 2 1 280px; min-width: 0; display: flex; flex-direction: column; line-height: 1.25 }
    .cl-next .q { font-size: 12px; font-weight: 800; letter-spacing: .04em; text-transform: uppercase }
    .cl-next .p { font-weight: 700; font-size: 15px }
    .cl-next .rien { font-size: 14px; color: #6A7891 }
    .cl-right { flex: 0 0 120px; display: flex; align-items: center; justify-content: flex-end; gap: 8px; margin-left: auto }
    .cl-nb { padding: 3px 10px; border-radius: 999px; background: #EEF2F7; color: #44536E; font-size: 13px; font-weight: 800; white-space: nowrap }
    .cl-empty { padding: 24px; border-radius: 20px; background: #fff; text-align: center; color: #44536E; font-weight: 700 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="clients-app" class="cl"></div>

<script>
(function () {
    var D = <asp:Literal ID="litData" runat="server" />;
    var L = <asp:Literal ID="litLabels" runat="server" />;
    var root = document.getElementById('clients-app');
    if (!root || !D) return;

    var clients = D.clients || [];
    var P = {
        r: { lab: L.urgent, dot: '#E35D55', fg: '#A3261C', hbg: '#FFF6F5' },
        y: { lab: L.surveiller, dot: '#E3B341', fg: '#7A5200', hbg: '#FFFBF0' },
        g: { lab: L.sansUrg, dot: '#AEBBCD', fg: '#5B6B86', hbg: '#F7F9FC' }
    };
    var st = { prio: 'toutes', secteur: 'tous', emp: 'tous', q: '' };

    function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
    function fmt(t, n) { return String(t).replace('{n}', n); }
    function norm(s) { return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }
    function init(nom) {
        var p = (nom || '').split(/[ \-]+/).filter(Boolean), s = '';
        for (var i = 0; i < p.length && s.length < 2; i++) if (/[a-zA-ZÀ-ÿ]/.test(p[i][0])) s += p[i][0].toUpperCase();
        return s || '?';
    }
    function echLab(d) {
        if (d >= 999) return '';
        if (d < 0) return L.enRetard + ' · ' + fmt(L.ilYaJours, -d);
        if (d === 0) return L.aujourdhui;
        if (d === 1) return L.demain;
        if (d <= 7) return L.cetteSemaine;
        return fmt(L.dansJours, d);
    }
    function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1) : ''; }

    // ensembles distincts (ordre d'apparition)
    var secteurs = [], emps = [];
    clients.forEach(function (c) {
        if (c.secteur && secteurs.indexOf(c.secteur) < 0) secteurs.push(c.secteur);
        if (c.empNom && emps.indexOf(c.empNom) < 0) emps.push(c.empNom);
    });

    function visibles() {
        return clients.filter(function (c) {
            return (st.prio === 'toutes' || c.pk === st.prio)
                && (st.secteur === 'tous' || c.secteur === st.secteur)
                && (st.emp === 'tous' || c.empNom === st.emp)
                && (!st.q || norm(c.nom).indexOf(norm(st.q)) >= 0);
        });
    }

    function render() {
        var html = '';
        html += '<div><h1>' + esc(L.titre) + '</h1><p class="sub">' + esc(L.sousTitre) + '</p></div>';

        // compteurs par pire priorité (sur tous les dossiers)
        var cr = clients.filter(function (c) { return c.pk === 'r'; }).length;
        var cy = clients.filter(function (c) { return c.pk === 'y'; }).length;

        // barre de recherche + filtres
        html += '<section class="cl-filt">';
        html += '<div style="display:flex;flex-wrap:wrap;gap:8px 12px;align-items:center">'
            + '<label class="cl-srch"><svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#1B4F9C" stroke-width="2.4" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>'
            + '<input id="cl-search" type="text" data-role="search" placeholder="' + esc(L.chercher) + '" value="' + esc(st.q) + '" aria-label="' + esc(L.chercher) + '"></label>'
            + '<div class="cl-seg" role="group">' + seg('toutes', L.tous, '', clients.length) + seg('r', L.urgent, '#E35D55', cr) + seg('y', L.surveiller, '#E3B341', cy) + '</div>'
            + '</div>';
        html += chipLine(L.secteur, 'secteur', ['tous'].concat(secteurs));
        html += chipLine(L.employe, 'emp', ['tous'].concat(emps));
        html += '</section>';

        // sections par priorité
        var list = visibles();
        ['r', 'y', 'g'].forEach(function (k) {
            var l = list.filter(function (c) { return c.pk === k; }).sort(function (a, b) { return a.nom.localeCompare(b.nom); });
            if (!l.length) return;
            var nTxt = l.length > 1 ? fmt(L.dossiersN, l.length) : fmt(L.dossierN, l.length);
            html += '<section class="cl-sec"><h2 style="background:' + P[k].hbg + '"><span class="dot" style="background:' + P[k].dot + '"></span>'
                + esc(P[k].lab) + '<span class="c">' + nTxt + '</span></h2>';
            l.forEach(function (c) { html += carte(c); });
            html += '</section>';
        });
        if (!list.length) html += '<div class="cl-empty">' + esc(L.rienFiltres) + '</div>';

        root.innerHTML = html;
    }

    function seg(k, lab, dot, n) {
        var on = st.prio === k;
        return '<button data-prio="' + k + '"' + (on ? ' class="on" aria-pressed="true"' : '') + '>'
            + (dot ? '<span style="width:9px;height:9px;border-radius:50%;background:' + dot + '"></span>' : '')
            + esc(lab) + '<span class="n">' + n + '</span></button>';
    }

    function chipLine(lbl, champ, vals) {
        var chips = vals.map(function (v) {
            var on = st[champ] === v;
            var lab = v === 'tous' ? L.tous : v;
            return '<button class="cl-chip' + (on ? ' on' : '') + '" data-' + champ + '="' + esc(v) + '">' + esc(lab) + '</button>';
        }).join('');
        return '<div style="display:flex;flex-wrap:wrap;gap:6px 10px;align-items:center"><span class="cl-lbl">' + esc(lbl) + '</span><div class="cl-chips">' + chips + '</div></div>';
    }

    function carte(c) {
        var pr = P[c.pk];
        var suivi = c.empNom ? ' · ' + L.suiviPar + ' ' + esc(c.empNom) : '';
        var badge = c.nouveau ? '<span class="cl-badge">' + esc(L.nouveau) + '</span>' : '';
        var next;
        if (c.prochaine) {
            next = '<span class="q" style="color:' + pr.fg + '">' + esc(cap(echLab(c.ech))) + '</span><span class="p">' + esc(c.prochaine) + '</span>';
        } else {
            next = '<span class="rien">' + esc(L.aucuneAction) + '</span>';
        }
        var nb = c.nb ? fmt('{n} ' + L.aFaire, c.nb) : L.rienAFaire;
        return '<a class="cl-carte" href="wbfCabFiche.aspx?company=' + encodeURIComponent(c.guid) + '" aria-label="' + esc(c.nom) + '">'
            + '<span class="cl-ident"><span class="cl-av" style="border-color:' + pr.dot + '">' + esc(init(c.nom)) + '</span>'
            + '<span class="cl-nom"><span class="n1">' + esc(c.nom) + badge + '</span><span class="n2">' + esc(c.secteur) + suivi + '</span></span></span>'
            + '<span class="cl-next">' + next + '</span>'
            + '<span class="cl-right"><span class="cl-nb">' + esc(nb) + '</span>'
            + '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#8796AE" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg></span></a>';
    }

    root.addEventListener('click', function (ev) {
        var t = ev.target.closest ? ev.target.closest('[data-prio],[data-secteur],[data-emp]') : null;
        if (!t) return;
        if (t.hasAttribute('data-prio')) { var k = t.getAttribute('data-prio'); st.prio = (st.prio === k ? 'toutes' : k); return render(); }
        if (t.hasAttribute('data-secteur')) { st.secteur = t.getAttribute('data-secteur'); return render(); }
        if (t.hasAttribute('data-emp')) { st.emp = t.getAttribute('data-emp'); return render(); }
    });
    root.addEventListener('input', function (ev) {
        if (ev.target && ev.target.getAttribute('data-role') === 'search') {
            st.q = ev.target.value;
            render();
            var s = document.getElementById('cl-search');
            if (s) { s.focus(); var v = s.value; s.value = ''; s.value = v; }
        }
    });

    render();
})();
</script>
</asp:Content>
