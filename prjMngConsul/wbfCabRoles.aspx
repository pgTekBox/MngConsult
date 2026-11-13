<%@ Page Title="Rôles" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabRoles.aspx.vb" Inherits="MngConsul.wbfCabRoles" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Rôles — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* Rôles du cabinet (T382) — confiné sous #rol */
    #rol { color: #0E1F3D }
    #rol .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    #rol .tete { display: flex; align-items: center; gap: 14px }
    #rol .tete .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: #E8EDF5; color: #1B4F9C; display: flex; align-items: center; justify-content: center }
    #rol .tete h1 { font-size: 21px; font-weight: 800; margin: 0 }
    #rol .tete .sous { font-size: 13px; color: #44536E; margin-top: 2px }
    #rol .tete .btn { margin-left: auto }
    #rol .btn { height: 40px; padding: 0 16px; border: 0; border-radius: 999px; background: #1B4F9C; color: #fff; font: inherit; font-weight: 800; font-size: 13.5px; cursor: pointer; white-space: nowrap }
    #rol .btn:hover { background: #143A73 }
    #rol .btn.sec { background: #E3EBF7; color: #143A73 }
    #rol .btn:disabled { opacity: .55; cursor: default }
    #rol .ligne { display: grid; grid-template-columns: minmax(0, 1.3fr) minmax(0, 1fr) minmax(0, 1.6fr) auto; gap: 16px; align-items: center; padding: 14px 16px; border-radius: 16px; background: #F2F5F9; margin-bottom: 8px }
    #rol .nm { font-weight: 800; font-size: 15px }
    #rol .ds { font-size: 12.5px; color: #5B6B86; margin-top: 2px }
    #rol .tag { display: inline-block; font-size: 11.5px; font-weight: 800; padding: 2px 8px; border-radius: 999px; background: #E3EBF7; color: #143A73; margin-left: 6px; vertical-align: 1px }
    #rol .niv { display: inline-block; font-size: 12.5px; font-weight: 800; padding: 4px 10px; border-radius: 999px }
    #rol .niv.admin { background: #FDEEDB; color: #8A4B00 }
    #rol .niv.employe { background: #E3F3EA; color: #0F5A3A }
    #rol .niv.technicien { background: #EDE7FA; color: #4B2D8F }
    #rol .lab2 { font-size: 11.5px; font-weight: 800; color: #5B6B86; text-transform: uppercase; letter-spacing: .03em; margin-bottom: 3px }
    #rol .mb { font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    #rol .acts { display: flex; gap: 8px }
    #rol .rond { width: 40px; height: 40px; border-radius: 50%; border: 1px solid #D5DDE8; background: #fff; color: #1B4F9C; cursor: pointer; display: inline-flex; align-items: center; justify-content: center }
    #rol .rond:hover { background: #E3EBF7 }
    #rol .rond.danger { color: #A3261C; border-color: #E8B4AE }
    #rol .rond.danger:hover { background: #FDECEA }
    #rol .rond:disabled { opacity: .35; cursor: not-allowed; background: #fff }
    #rol .vide { padding: 14px 4px; color: #44536E; font-weight: 700 }
    #rol .msg { margin-top: 12px; padding: 10px 14px; border-radius: 12px; font-size: 13.5px; font-weight: 700 }
    #rol .msg.err { background: #FDECEA; color: #A3261C }
    #rol .fond { position: fixed; inset: 0; background: rgba(14,31,61,.45); display: none; align-items: flex-start; justify-content: center; padding: 8vh 16px; z-index: 10000; overflow: auto }
    #rol .fond.ouvert { display: flex }
    #rol .fen { width: 100%; max-width: 560px; background: #fff; border-radius: 22px; padding: 20px 22px }
    #rol .fen h3 { margin: 0 0 12px; font-size: 18px; font-weight: 800 }
    #rol .fen label { display: block; font-weight: 700; font-size: 12.5px; margin: 10px 0 5px }
    #rol .fen input, #rol .fen select, #rol .fen textarea { width: 100%; padding: 9px 10px; border: 1px solid #D5DDE8; border-radius: 12px; font: inherit; font-size: 14px; box-sizing: border-box; background: #fff; color: #0E1F3D }
    #rol .fen input, #rol .fen select { height: 40px; padding: 0 10px }
    #rol .fen textarea { min-height: 70px; resize: vertical }
    #rol .fen select:disabled { background: #F2F5F9; color: #7A879C }
    #rol .fen .aide { font-size: 12px; color: #5B6B86; margin-top: 4px }
    #rol .fen .pied { display: flex; justify-content: flex-end; gap: 8px; margin-top: 16px }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="rol">
    <section class="boite">
        <div class="tete">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg></div>
            <div><h1 id="rolTitre"></h1><div class="sous" id="rolSous"></div></div>
            <button type="button" class="btn" id="rolNouveau" onclick="rolOuvrir(0)" hidden></button>
        </div>
    </section>
    <section class="boite" id="rolListe"></section>

    <div class="fond" id="rolFond" onclick="if (event.target === this) rolFermer();">
        <div class="fen" role="dialog" aria-modal="true" aria-labelledby="rolFenTitre">
            <h3 id="rolFenTitre"></h3>
            <div id="rolFenCorps"></div>
            <div id="rolFenMsg"></div>
            <div class="pied">
                <button type="button" class="btn sec" id="rolFenFermer" onclick="rolFermer()"></button>
                <button type="button" class="btn" id="rolFenOk" onclick="rolEnregistrer()"></button>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    var ROL = <asp:Literal ID="litData" runat="server" />;
    var RL = <asp:Literal ID="litLabels" runat="server" />;
    var rolId = 0;

    function rEsc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
    function rFmt(s, a) { return String(s).replace('{0}', a); }
    async function rPost(data) {
        var body = Object.keys(data).map(function (k) { return k + '=' + encodeURIComponent(data[k]); }).join('&');
        var r = await fetch(location.pathname, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body, credentials: 'same-origin' });
        try { return await r.json(); } catch (e) { return { ok: false, erreur: RL.erreur }; }
    }
    function rNiveau(a) { return a === 'admin' ? RL.aAdminC : a === 'technicien' ? RL.aTechC : RL.aEmployeC; }
    var ICO_CRAYON = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>';
    var ICO_POUBELLE = '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/></svg>';

    function rolPeindre() {
        document.getElementById('rolTitre').textContent = RL.titre;
        document.getElementById('rolSous').textContent = RL.sous;
        var b = document.getElementById('rolNouveau');
        if (ROL.gerer) { b.hidden = false; b.textContent = '+ ' + RL.nouveau; }

        var h = ROL.roles.map(function (r) {
            var raison = r.systeme ? RL.baseAide : (r.nb > 0 ? rFmt(RL.utilise, r.nb) : RL.supprimer);
            return '<div class="ligne">' +
                '<div><div class="nm">' + rEsc(r.nom) + (r.systeme ? '<span class="tag">' + rEsc(RL.base) + '</span>' : '') + '</div>' +
                '<div class="ds">' + rEsc(r.description) + '</div></div>' +
                '<div><div class="lab2">' + rEsc(RL.acces) + '</div><span class="niv ' + rEsc(r.acces) + '">' + rEsc(rNiveau(r.acces)) + '</span></div>' +
                '<div><div class="lab2">' + rEsc(RL.membres) + ' (' + r.nb + ')</div><div class="mb" title="' + rEsc(r.membres) + '">' + rEsc(r.membres || RL.aucun) + '</div></div>' +
                '<div class="acts">' + (ROL.gerer
                    ? '<button type="button" class="rond" title="' + rEsc(RL.modifier) + '" aria-label="' + rEsc(RL.modifier) + '" onclick="rolOuvrir(' + r.id + ')">' + ICO_CRAYON + '</button>' +
                      '<button type="button" class="rond danger" title="' + rEsc(raison) + '" aria-label="' + rEsc(RL.supprimer) + '"' +
                          (r.systeme || r.nb > 0 ? ' disabled' : '') + ' onclick="rolSupprimer(' + r.id + ')">' + ICO_POUBELLE + '</button>'
                    : '') + '</div></div>';
        }).join('');
        document.getElementById('rolListe').innerHTML = h || '<div class="vide">' + rEsc(RL.vide) + '</div>';
    }

    function rolOuvrir(id) {
        rolId = id;
        var r = ROL.roles.find(function (x) { return x.id === id; }) || { nom: '', description: '', acces: 'employe', systeme: false, nb: 0 };
        document.getElementById('rolFenTitre').textContent = id ? rFmt(RL.titreModifier, r.nom) : RL.titreNouveau;
        document.getElementById('rolFenFermer').textContent = RL.fermer;
        document.getElementById('rolFenOk').textContent = RL.enregistrer;
        var opts = [['admin', RL.aAdmin], ['employe', RL.aEmploye], ['technicien', RL.aTech]].map(function (o) {
            return '<option value="' + o[0] + '"' + (o[0] === r.acces ? ' selected' : '') + '>' + rEsc(o[1]) + '</option>';
        }).join('');
        document.getElementById('rolFenCorps').innerHTML =
            '<label for="rolNom">' + rEsc(RL.nom) + '</label><input type="text" id="rolNom" maxlength="80" value="' + rEsc(r.nom) + '" />' +
            '<label for="rolDesc">' + rEsc(RL.description) + '</label><textarea id="rolDesc" maxlength="400">' + rEsc(r.description) + '</textarea>' +
            '<label for="rolAcces">' + rEsc(RL.acces) + '</label><select id="rolAcces"' + (r.systeme ? ' disabled' : '') + '>' + opts + '</select>' +
            '<div class="aide">' + rEsc(r.systeme ? RL.baseAide : (r.nb > 0 ? RL.accesAide : '')) + '</div>';
        document.getElementById('rolFenMsg').innerHTML = '';
        document.getElementById('rolFond').classList.add('ouvert');
        document.getElementById('rolNom').focus();
    }

    async function rolEnregistrer() {
        var b = document.getElementById('rolFenOk'); b.disabled = true;
        var d = await rPost({ op: 'save', id: rolId, nom: document.getElementById('rolNom').value,
                              description: document.getElementById('rolDesc').value, acces: document.getElementById('rolAcces').value });
        b.disabled = false;
        if (!d.ok) { document.getElementById('rolFenMsg').innerHTML = '<div class="msg err">' + rEsc(d.erreur) + '</div>'; return; }
        location.reload();
    }

    async function rolSupprimer(id) {
        var r = ROL.roles.find(function (x) { return x.id === id; });
        if (!r || !confirm(rFmt(RL.confSupprimer, r.nom))) return;
        var d = await rPost({ op: 'delete', id: id });
        if (!d.ok) { alert(d.erreur); return; }
        location.reload();
    }

    function rolFermer() { document.getElementById('rolFond').classList.remove('ouvert'); }
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') rolFermer(); });
    rolPeindre();
</script>
</asp:Content>
