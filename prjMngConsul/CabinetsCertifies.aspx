<%@ Page Title="Cabinets certifiés" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="CabinetsCertifies.aspx.vb" Inherits="MngConsul.CabinetsCertifies" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Cabinets certifiés — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 960px }
    /* Les boîtes posent sur le fond de la page (FondDePage), comme dans le gabarit */
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }

    .cab-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .cab-head .ico {
        width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px;
        background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C);
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .cab-head > div { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .cab-fermer { font-size: 12.5px; font-family: inherit; cursor: pointer; border: 1px solid var(--mc-line2, #AEBBCD); background: #fff;
                  border-radius: 999px; padding: 6px 12px; color: #0E1F3D; font-weight: 700 }
    .cab-fermer:hover { background: var(--mc-soft, #E8EDF5) }
    .cab-lede { font-size: 13.5px; color: #44536E; margin: 10px 0 0; line-height: 1.6 }

    /* La recherche : un champ en pastille, et le décompte */
    .cab-outils { display: flex; align-items: center; gap: 12px; margin-top: 14px }
    .cab-recherche { flex: 1; display: flex; align-items: center; gap: 8px; padding: 0 14px; height: 40px; border-radius: 999px;
                     background: var(--mc-page, #F2F5F9); border: 1px solid var(--mc-line, #D5DDE8); color: #44536E }
    .cab-recherche:focus-within { border-color: var(--mc-primary, #1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .cab-recherche input { flex: 1; border: 0; background: transparent; font: inherit; font-size: 14px; color: #0E1F3D; outline: none; min-width: 0 }
    .cab-compte { font-size: 13px; color: #44536E; white-space: nowrap }

    /* Les cabinets : deux colonnes de cartes blanches, sans bordure */
    .cab-liste { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px }
    @media (max-width: 760px) { .cab-liste { grid-template-columns: 1fr } }
    .cab-carte { background: #fff; border-radius: 20px; padding: 18px 20px; display: flex; flex-direction: column; gap: 10px }
    .cab-carte[hidden] { display: none }
    .cab-top { display: flex; align-items: flex-start; gap: 12px }
    .cab-av { width: 44px; height: 44px; border-radius: 50%; flex: 0 0 44px; background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73);
              font-weight: 800; font-size: 15px; display: flex; align-items: center; justify-content: center }
    .cab-top > div { flex: 1; min-width: 0 }
    .cab-carte h2 { font-size: 16px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-resp { font-size: 13px; color: #44536E; margin-top: 1px }
    .cab-cert { display: inline-flex; align-items: center; gap: 5px; font-size: 11.5px; font-weight: 800; padding: 3px 9px; border-radius: 999px;
                background: #E3F6EC; color: #1F7A4D; white-space: nowrap }
    .cab-cert .ic { color: #1F7A4D }
    .cab-desc { font-size: 13.5px; color: #1e293b; line-height: 1.55; margin: 0 }
    .cab-badges { display: flex; flex-wrap: wrap; gap: 6px }
    .cab-badges span { display: inline-flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 700; padding: 3px 9px; border-radius: 999px;
                       background: var(--mc-page, #F2F5F9); color: #44536E }
    .cab-badges .lieu { background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73) }
    .cab-badges .lieu .ic { color: var(--mc-primary, #1B4F9C) }
    .cab-badges .lang { background: #FFF4D6; color: #7A5A00 }
    .cab-actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: auto; padding-top: 4px; font-size: 13px }
    .cab-actions a { display: inline-flex; align-items: center; gap: 6px; padding: 7px 12px; border-radius: 999px; text-decoration: none; font-weight: 700;
                     color: #fff; background: var(--mc-primary, #1B4F9C) }
    .cab-actions a:hover { background: var(--mc-primary-dark, #143A73) }
    .cab-actions a.sec { color: var(--mc-primary-dark, #143A73); background: var(--mc-soft2, #E3EBF7) }
    .cab-actions a.sec:hover { background: var(--mc-soft, #E8EDF5) }
    .cab-actions .tel { display: inline-flex; align-items: center; color: #44536E; padding: 7px 4px }
    .cab-vide { background: #fff; border-radius: 20px; padding: 24px; text-align: center; color: #44536E; font-size: 14px }
    .cab-vide[hidden] { display: none }
</style>
<asp:Literal ID="litPopupCss" runat="server" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">

    <section class="boite">
        <div class="cab-head">
            <div class="ico"><i class="ic ic-handshake" aria-hidden="true"></i></div>
            <div>
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
            <asp:Literal ID="litFermer" runat="server" />
        </div>
        <p class="cab-lede"><asp:Literal ID="litLede" runat="server" /></p>
        <asp:Literal ID="litOutils" runat="server" />
    </section>

    <div class="cab-liste" id="cabListe">
        <asp:Literal ID="litListe" runat="server" />
    </div>
    <p class="cab-vide" id="cabVide" hidden><asp:Literal ID="litVide" runat="server" /></p>

</div>
<script type="text/javascript">
    // La recherche filtre les cartes sur place (nom, responsable, ville, langues, spécialités, description).
    (function () {
        var champ = document.getElementById('cabRecherche');
        var compte = document.getElementById('cabCompte');
        var vide = document.getElementById('cabVide');
        var cartes = Array.prototype.slice.call(document.querySelectorAll('#cabListe .cab-carte'));
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
        // Dans la fenêtre : Échap ferme la fenêtre du parent, comme un clic sur Fermer.
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && window.parent && window.parent !== window && window.parent.fermerFenetreApp) { window.parent.fermerFenetreApp(); }
        });
    })();
</script>
</asp:Content>
