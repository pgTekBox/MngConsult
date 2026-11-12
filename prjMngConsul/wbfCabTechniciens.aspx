<%@ Page Title="Techniciens" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabTechniciens.aspx.vb" Inherits="MngConsul.wbfCabTechniciens" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Techniciens — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* Techniciens du cabinet (T379) — confiné sous #tec */
    #tec { color: #0E1F3D }
    #tec .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    #tec .tete { display: flex; align-items: center; gap: 14px }
    #tec .tete .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: #E8EDF5; color: #1B4F9C; display: flex; align-items: center; justify-content: center }
    #tec .tete h1 { font-size: 21px; font-weight: 800; margin: 0 }
    #tec .tete .sous { font-size: 13px; color: #44536E; margin-top: 2px }
    #tec .kpis { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-bottom: 16px }
    #tec .kpi { background: #fff; border-radius: 22px; padding: 14px 16px }
    #tec .kpi .lab { font-size: 13px; font-weight: 700; color: #44536E }
    #tec .kpi .val { font-size: 24px; font-weight: 800 }
    #tec .kpi.rouge .val { color: #A3261C }
    #tec h2 { font-size: 16px; font-weight: 800; margin: 0 0 10px }
    #tec .frm { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)) auto; gap: 10px 12px; align-items: end }
    #tec .frm label { display: block; font-weight: 700; font-size: 12.5px; margin-bottom: 5px }
    #tec .frm input, #tec select { width: 100%; height: 40px; padding: 0 10px; border: 1px solid #D5DDE8; border-radius: 12px; font: inherit; font-size: 14px; background: #fff; color: #0E1F3D; box-sizing: border-box }
    #tec .btn { height: 40px; padding: 0 16px; border: 0; border-radius: 999px; background: #1B4F9C; color: #fff; font: inherit; font-weight: 800; font-size: 13.5px; cursor: pointer; white-space: nowrap }
    #tec .btn:hover { background: #143A73 }
    #tec .btn.sec { background: #E3EBF7; color: #143A73 }
    #tec .btn.danger { background: #fff; color: #A3261C; border: 1px solid #E8B4AE }
    #tec .btn:disabled { opacity: .55; cursor: default }
    #tec .msg { margin-top: 12px; padding: 10px 14px; border-radius: 12px; font-size: 13.5px; font-weight: 700 }
    #tec .msg.ok { background: #E3F3EA; color: #0F5A3A }
    #tec .msg.err { background: #FDECEA; color: #A3261C }
    #tec .lien { display: flex; gap: 8px; margin-top: 8px }
    #tec .lien input { flex: 1; height: 36px; padding: 0 10px; border: 1px solid #D5DDE8; border-radius: 10px; font-size: 13px; background: #F7F9FC }
    #tec .carte { display: grid; grid-template-columns: 44px minmax(0, 1.4fr) minmax(0, 1fr) minmax(0, 1.6fr) auto; gap: 14px; align-items: center; padding: 14px; border-radius: 16px; background: #F2F5F9; margin-bottom: 8px }
    #tec .av { width: 44px; height: 44px; border-radius: 50%; background: #E3EBF7; color: #143A73; font-weight: 800; display: flex; align-items: center; justify-content: center }
    #tec .nm { font-weight: 800 }
    #tec .em, #tec .pt { font-size: 12.5px; color: #5B6B86 }
    #tec .tag { display: inline-block; font-size: 11.5px; font-weight: 800; padding: 2px 8px; border-radius: 999px; background: #FBF1DC; color: #7A5200; margin-left: 6px }
    #tec .lab2 { font-size: 11.5px; font-weight: 800; color: #5B6B86; text-transform: uppercase; letter-spacing: .03em; margin-bottom: 3px }
    #tec .doss { font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    #tec .charge { font-size: 12.5px; color: #44536E; margin-top: 3px }
    #tec .charge b.r { color: #A3261C }
    #tec .acts { display: flex; gap: 8px }
    #tec .vide { padding: 14px 4px; color: #44536E; font-weight: 700 }
    #tec .fond { position: fixed; inset: 0; background: rgba(14,31,61,.45); display: none; align-items: flex-start; justify-content: center; padding: 8vh 16px; z-index: 10000; overflow: auto }
    #tec .fond.ouvert { display: flex }
    #tec .fen { width: 100%; max-width: 560px; background: #fff; border-radius: 22px; padding: 20px 22px }
    #tec .fen h3 { margin: 0 0 12px; font-size: 18px; font-weight: 800 }
    #tec .fen .ligne { display: flex; align-items: center; gap: 10px; padding: 8px 4px; border-top: 1px solid #E3E9F1; font-size: 14px; cursor: pointer }
    #tec .fen .ligne input { width: 18px; height: 18px }
    #tec .fen .ligne span.autre { margin-left: auto; font-size: 12px; color: #7A5200 }
    #tec .fen .pied { display: flex; justify-content: flex-end; gap: 8px; margin-top: 14px }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="tec">
    <section class="boite">
        <div class="tete">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.8-3.6 3.4-5.5 6.5-5.5s5.7 1.9 6.5 5.5"/><path d="M17 11l1.5 1.5L22 9"/></svg></div>
            <div><h1 id="tecTitre"></h1><div class="sous" id="tecSous"></div></div>
        </div>
    </section>
    <div class="kpis" id="tecKpis"></div>
    <section class="boite" id="tecInvite" hidden></section>
    <section class="boite" id="tecListe"></section>

    <div class="fond" id="tecFond" onclick="if (event.target === this) tecFermer();">
        <div class="fen" role="dialog" aria-modal="true">
            <h3 id="tecFenTitre"></h3>
            <div id="tecFenCorps"></div>
            <div id="tecFenMsg"></div>
            <div class="pied">
                <button type="button" class="btn sec" id="tecFenFermer" onclick="tecFermer()"></button>
                <button type="button" class="btn" id="tecFenOk" onclick="tecEnregistrerDossiers()"></button>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    var TEC = <asp:Literal ID="litData" runat="server" />;
    var TL = <asp:Literal ID="litLabels" runat="server" />;
    var tecMembre = 0;

    function tEsc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
    function tFmt(s, a) { return String(s).replace('{0}', a); }
    function tInit(nom) { var p = String(nom || '?').split(/[\s-]+/).filter(Boolean); return ((p[0] || '?')[0] + (p.length > 1 ? p[p.length - 1][0] : '')).toUpperCase(); }
    async function tPost(data) {
        var body = Object.keys(data).map(function (k) { return k + '=' + encodeURIComponent(data[k]); }).join('&');
        var r = await fetch(location.pathname, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body, credentials: 'same-origin' });
        try { return await r.json(); } catch (e) { return { ok: false, erreur: TL.erreur }; }
    }
    function tSupOptions(sel) {
        return '<option value="">' + tEsc(TL.aucunSup) + '</option>' + TEC.sups.map(function (s) {
            return '<option value="' + s.id + '"' + (s.id === sel ? ' selected' : '') + '>' + tEsc(s.nom) + '</option>';
        }).join('');
    }

    function tecPeindre() {
        document.getElementById('tecTitre').textContent = TL.titre;
        document.getElementById('tecSous').textContent = TL.sous;
        var t = TEC.techs;
        var att = t.filter(function (x) { return x.attente; }).length;
        var tac = t.reduce(function (s, x) { return s + x.taches; }, 0);
        var ret = t.reduce(function (s, x) { return s + x.retard; }, 0);
        document.getElementById('tecKpis').innerHTML =
            [[TL.kTech, t.length, ''], [TL.kAttente, att, ''], [TL.kTaches, tac, ''], [TL.kRetard, ret, ret > 0 ? 'rouge' : '']]
            .map(function (k) { return '<div class="kpi ' + k[2] + '"><div class="lab">' + tEsc(k[0]) + '</div><div class="val">' + k[1] + '</div></div>'; }).join('');

        var inv = document.getElementById('tecInvite');
        if (TEC.gerer) {
            inv.hidden = false;
            inv.innerHTML = '<h2>' + tEsc(TL.inviter) + '</h2><div class="frm">' +
                '<div><label>' + tEsc(TL.prenom) + '</label><input type="text" id="tecPrenom" /></div>' +
                '<div><label>' + tEsc(TL.nom) + '</label><input type="text" id="tecNom" /></div>' +
                '<div><label>' + tEsc(TL.courriel) + '</label><input type="email" id="tecEmail" /></div>' +
                '<div><label>' + tEsc(TL.superviseur) + '</label><select id="tecSup">' + tSupOptions('') + '</select></div>' +
                '<div><button type="button" class="btn" id="tecInvBtn" onclick="tecInviter()">' + tEsc(TL.envoyer) + '</button></div>' +
                '</div><div id="tecInvMsg"></div>';
        }

        var h = '';
        if (!t.length) h = '<div class="vide">' + tEsc(TL.vide) + '</div>';
        t.forEach(function (x) {
            h += '<div class="carte"><div class="av">' + tEsc(tInit(x.nom)) + '</div>' +
                 '<div><div class="nm">' + tEsc(x.nom) + (x.attente ? '<span class="tag">' + tEsc(TL.attente) + '</span>' : '') + '</div>' +
                 '<div class="em">' + tEsc(x.email) + '</div>' +
                 '<div class="pt">' + tEsc(TL.connexion) + ' : ' + tEsc(x.connexion || TL.jamais) + '</div></div>' +
                 '<div><div class="lab2">' + tEsc(TL.superviseur) + '</div>' +
                 (TEC.gerer ? '<select onchange="tecSup(' + x.id + ', this)">' + tSupOptions(x.sup) + '</select>' : '<div>' + tEsc(x.supNom || '—') + '</div>') + '</div>' +
                 '<div><div class="lab2">' + tEsc(TL.dossiers) + ' (' + x.nbDossiers + ')</div>' +
                 '<div class="doss" title="' + tEsc(x.dossiers) + '">' + tEsc(x.dossiers || TL.aucunDossier) + '</div>' +
                 '<div class="charge">' + x.taches + ' ' + tEsc(TL.taches) + (x.retard ? ' · <b class="r">' + x.retard + ' ' + tEsc(TL.retard) + '</b>' : '') + '</div></div>' +
                 '<div class="acts">' + (TEC.gerer
                    ? '<button type="button" class="btn sec" onclick="tecDossiers(' + x.id + ')">' + tEsc(TL.gererDossiers) + '</button>' +
                      '<button type="button" class="btn danger" onclick="tecRetirer(' + x.id + ')">' + tEsc(TL.retirer) + '</button>'
                    : '') + '</div></div>';
        });
        document.getElementById('tecListe').innerHTML = h;
    }

    async function tecInviter() {
        var b = document.getElementById('tecInvBtn'), m = document.getElementById('tecInvMsg');
        b.disabled = true; m.innerHTML = '';
        var d = await tPost({ op: 'invite', prenom: document.getElementById('tecPrenom').value, nom: document.getElementById('tecNom').value,
                              email: document.getElementById('tecEmail').value, sup: document.getElementById('tecSup').value });
        b.disabled = false;
        if (!d.ok) { m.innerHTML = '<div class="msg err">' + tEsc(d.erreur) + '</div>'; return; }
        sessionStorage.setItem('tecLien', d.lien);
        location.reload();
    }

    async function tecSup(id, sel) {
        sel.disabled = true;
        var d = await tPost({ op: 'sup', id: id, sup: sel.value });
        sel.disabled = false;
        if (!d.ok) { alert(d.erreur); return; }
        var x = TEC.techs.find(function (t) { return t.id === id; }); if (x) x.sup = sel.value;
    }

    async function tecRetirer(id) {
        var x = TEC.techs.find(function (t) { return t.id === id; });
        if (!x || !confirm(tFmt(TL.confRetirer, x.nom))) return;
        var d = await tPost({ op: 'retirer', id: id });
        if (!d.ok) { alert(d.erreur); return; }
        location.reload();
    }

    async function tecDossiers(id) {
        tecMembre = id;
        var x = TEC.techs.find(function (t) { return t.id === id; });
        document.getElementById('tecFenTitre').textContent = tFmt(TL.dossiersDe, x ? x.nom : '');
        document.getElementById('tecFenFermer').textContent = TL.fermer;
        document.getElementById('tecFenOk').textContent = TL.enregistrer;
        document.getElementById('tecFenMsg').innerHTML = '';
        document.getElementById('tecFenCorps').innerHTML = '<div class="vide">' + tEsc(TL.chargement) + '</div>';
        document.getElementById('tecFond').classList.add('ouvert');
        var d = await tPost({ op: 'dossiers', id: id });
        if (!d.ok) { document.getElementById('tecFenMsg').innerHTML = '<div class="msg err">' + tEsc(d.erreur) + '</div>'; return; }
        document.getElementById('tecFenCorps').innerHTML = d.dossiers.map(function (o) {
            return '<label class="ligne"><input type="checkbox" value="' + o.id + '"' + (o.confie ? ' checked' : '') + ' /><span>' + tEsc(o.nom) + '</span>' +
                   (o.autre ? '<span class="autre">' + tEsc(tFmt(TL.dejaA, o.autre)) + '</span>' : '') + '</label>';
        }).join('') || '<div class="vide">' + tEsc(TL.aucunDossier) + '</div>';
    }

    async function tecEnregistrerDossiers() {
        var ids = Array.prototype.map.call(document.querySelectorAll('#tecFenCorps input:checked'), function (c) { return c.value; });
        var b = document.getElementById('tecFenOk'); b.disabled = true;
        var d = await tPost({ op: 'assign', id: tecMembre, guids: ids.join(',') });
        b.disabled = false;
        if (!d.ok) { document.getElementById('tecFenMsg').innerHTML = '<div class="msg err">' + tEsc(d.erreur) + '</div>'; return; }
        location.reload();
    }

    function tecFermer() { document.getElementById('tecFond').classList.remove('ouvert'); }
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') tecFermer(); });

    tecPeindre();
    // Après une invitation : le lien d'activation, copiable.
    (function () {
        var lien = null; try { lien = sessionStorage.getItem('tecLien'); sessionStorage.removeItem('tecLien'); } catch (e) { }
        var m = document.getElementById('tecInvMsg');
        if (lien && m) m.innerHTML = '<div class="msg ok">' + tEsc(TL.invOk) + '<div class="lien"><input type="text" readonly value="' + tEsc(lien) + '" onclick="this.select()" />' +
            '<button type="button" class="btn sec" onclick="navigator.clipboard.writeText(this.previousSibling.value)">' + tEsc(TL.copier) + '</button></div></div>';
    })();
</script>
</asp:Content>
