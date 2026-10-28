<%@ Page Title="Mes dossiers" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabDossiers.aspx.vb" Inherits="MngConsul.wbfCabDossiers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Mes dossiers — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 1000px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }

    .cab-head { display: flex; align-items: center; gap: 14px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px;
        background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C);
        display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }

    .cab-outils { display: flex; align-items: center; gap: 12px; margin-top: 14px }
    .cab-recherche { flex: 1; display: flex; align-items: center; gap: 8px; padding: 0 14px; height: 40px; border-radius: 999px;
        background: var(--mc-page, #F2F5F9); border: 1px solid var(--mc-line, #D5DDE8); color: #44536E }
    .cab-recherche:focus-within { border-color: var(--mc-primary, #1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .cab-recherche input { flex: 1; border: 0; background: transparent; font: inherit; font-size: 14px; color: #0E1F3D; outline: none; min-width: 0 }
    .cab-compte { font-size: 13px; color: #44536E; white-space: nowrap }

    .doss-liste { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px }
    @media (max-width: 760px) { .doss-liste { grid-template-columns: 1fr } }
    .doss-carte { background: #fff; border-radius: 20px; padding: 18px 20px; display: flex; flex-direction: column; gap: 12px }
    .doss-carte[hidden] { display: none }
    .doss-top { display: flex; align-items: center; gap: 12px }
    .doss-av { width: 44px; height: 44px; border-radius: 50%; flex: 0 0 44px; background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73);
        font-weight: 800; font-size: 15px; display: flex; align-items: center; justify-content: center }
    .doss-top > div { flex: 1; min-width: 0 }
    .doss-carte h2 { font-size: 16px; font-weight: 800; margin: 0; color: #0E1F3D }
    .doss-sous { font-size: 13px; color: #44536E; margin-top: 1px }
    .doss-actions { margin-top: auto }
    .doss-entrer { display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; border-radius: 999px; text-decoration: none;
        font-weight: 800; color: #fff; background: var(--mc-primary, #1B4F9C) }
    .doss-entrer:hover { background: var(--mc-primary-dark, #143A73) }
    .doss-vide { background: #fff; border-radius: 20px; padding: 24px; text-align: center; color: #44536E; font-size: 14px }
    .doss-vide[hidden] { display: none }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">

    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
        <asp:Literal ID="litOutils" runat="server" />
    </section>

    <div class="doss-liste" id="dossListe">
        <asp:Literal ID="litListe" runat="server" />
    </div>
    <p class="doss-vide" id="dossVide" hidden><asp:Literal ID="litVide" runat="server" /></p>

</div>
<script type="text/javascript">
    (function () {
        var champ = document.getElementById('dossRecherche');
        var compte = document.getElementById('dossCompte');
        var vide = document.getElementById('dossVide');
        var cartes = Array.prototype.slice.call(document.querySelectorAll('#dossListe .doss-carte'));
        if (!champ || !compte) { return; }
        function normaliser(s) { return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, ''); }
        function filtrer() {
            var q = normaliser(champ.value.trim());
            var n = 0;
            cartes.forEach(function (c) {
                var ok = !q || normaliser(c.getAttribute('data-txt')).indexOf(q) >= 0;
                c.hidden = !ok; if (ok) { n++; }
            });
            compte.textContent = (n === 1 ? compte.getAttribute('data-un') : compte.getAttribute('data-plusieurs')).replace('{0}', n);
            if (vide) { vide.hidden = n > 0; }
        }
        champ.addEventListener('input', filtrer);
        filtrer();
    })();
</script>
</asp:Content>
