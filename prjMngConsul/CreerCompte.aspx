<%@ Page Title="Créer un compte du plan comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="CreerCompte.aspx.vb" Inherits="MngConsul.CreerCompte" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Créer un compte — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* Même gabarit que la fenêtre « Associer un compte » (AssocierCompte.aspx). */
    .asc-page { padding: 0 }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }

    .asc-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .asc-head .ico {
        width: 46px; height: 46px; border-radius: 50%;
        background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); border: 0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .asc-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .asc-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .asc-lede { font-size: 13.5px; color: #44536E; margin: 10px 0 0; line-height: 1.6 }

    .asc-carte { background: #fff; border: 0; border-radius: 24px; overflow: hidden; margin-bottom: 16px }
    .asc-corps { padding: 18px 20px }
    .asc-corps h2 { font-size: 17px; font-weight: 800; margin: 0 0 14px; color: #0E1F3D }
    .asc-deux { display: grid; grid-template-columns: 1fr 44px 1.4fr; gap: 10px; align-items: start }
    .asc-fleche { display: flex; align-items: center; justify-content: center; height: 100%; min-height: 90px; font-size: 26px; color: #44536E }
    @media (max-width: 720px) { .asc-deux { grid-template-columns: 1fr } .asc-fleche { min-height: 0; transform: rotate(90deg) } }

    .asc-source { border: 1px solid #cbd5e1; border-radius: 12px; padding: 12px 14px; background: #fff }
    .asc-titre { font-size: 10.5px; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; color: #44536E; margin-bottom: 6px }
    .asc-source .num { font-size: 13.5px; color: #334155 }
    .asc-source .nom { font-size: 15px; font-weight: 800; color: #0E1F3D; margin: 2px 0 4px }
    .asc-source .meta { font-size: 12.5px; color: #44536E; line-height: 1.55 }
    .asc-source .meta b { color: #334155 }

    /* Le nouveau compte : classe, sous-classe, nom. */
    .cc-form { border: 1px solid #1B4F9C; box-shadow: 0 0 0 1px #1B4F9C inset; background: #F5F8FD; border-radius: 12px; padding: 12px 14px; display: flex; flex-direction: column; gap: 12px }
    .cc-champ label { display: block; font-size: 12.5px; font-weight: 800; color: #0E1F3D; margin-bottom: 4px }
    .cc-champ select, .cc-champ input[type=text] {
        width: 100%; box-sizing: border-box; padding: 9px 11px; border: 1px solid #cbd5e1; border-radius: 9px;
        font-size: 14px; font-family: inherit; color: #0E1F3D; background: #fff
    }
    .cc-champ select:focus, .cc-champ input[type=text]:focus { outline: 2px solid #93c5fd; border-color: #1B4F9C }
    .cc-champ select:disabled { background: #f1f5f9; color: #94a3b8 }
    .cc-aide { font-size: 12px; color: #44536E; margin-top: 4px; line-height: 1.45 }
    .cc-numero { font-size: 13px; color: #334155; background: #fff; border: 1px dashed #cbd5e1; border-radius: 9px; padding: 8px 11px }
    .cc-numero b { color: #0E1F3D }

    .asc-actions { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 14px 20px; border-top: 1px solid #D5DDE8; background: #fff }
    .asc-actions .droite { display: flex; gap: 10px }
    .asc-btn { padding: 10px 16px; border-radius: 9px; font-size: 13.5px; font-weight: 700; border: 1px solid #cbd5e1; cursor: pointer; font-family: inherit; background: #fff; color: #0E1F3D }
    .asc-btn:hover { background: #f1f5f9 }
    .asc-btn.primaire { background: #1B4F9C; color: #fff; border-color: #1B4F9C }
    .asc-btn.primaire:hover { background: #143A73 }

    .asc-progres { font-size: 12.5px; color: #44536E; margin: 0 0 10px }
    .asc-fin { background: #fff; border: 0; border-radius: 24px; padding: 22px 24px }
    .asc-fin h2 { font-size: 18px; font-weight: 800; margin: 0 0 8px; color: #0E1F3D }
    .asc-fin p { font-size: 13.5px; color: #44536E; margin: 0 0 12px; line-height: 1.6 }
    .asc-fin .liens { display: flex; gap: 10px; flex-wrap: wrap; align-items: center }
    .asc-fin a.asc-btn { text-decoration: none; display: inline-block }
</style>
<asp:Literal ID="litPopupCss" runat="server" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="asc-page">
    <section class="boite">
    <div class="asc-head">
        <div class="ico"><i class="ic ic-plus" aria-hidden="true"></i></div>
        <div>
            <h1>Créer un compte au plan comptable</h1>
            <div class="sub">Un compte à la fois : choisissez sa classe, sa sous-classe et son nom.</div>
        </div>
    </div>
    <p class="asc-lede">
        Chaque compte de l'ancien logiciel marqué « Créer » se présente ici. La sous-classe lui donne sa place dans vos états
        financiers ; le numéro s'attribue tout seul dans la plage de la sous-classe. Le compte est créé pour de bon dans votre plan.
    </p>
    </section>

    <asp:HiddenField ID="hfCle" runat="server" />
    <asp:Literal ID="litProgres" runat="server" />

    <asp:Panel ID="pnlCarte" runat="server" CssClass="asc-carte">
        <asp:Literal ID="litCarte" runat="server" />
        <div class="asc-actions">
            <asp:Button ID="btnPlusTard" runat="server" CssClass="asc-btn" Text="Plus tard" CausesValidation="false" />
            <div class="droite">
                <asp:Button ID="btnCreer" runat="server" CssClass="asc-btn primaire" Text="Créer le compte"
                    OnClientClick="if (!ccVerifier()) { return false; }" />
            </div>
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlFin" runat="server" CssClass="asc-fin" Visible="false">
        <asp:Literal ID="litFin" runat="server" />
        <div class="liens">
            <asp:Button ID="btnReprendre" runat="server" CssClass="asc-btn" Text="Reprendre les comptes reportés" CausesValidation="false" Visible="false" />
            <asp:Button ID="btnFermer" runat="server" CssClass="asc-btn primaire" Text="Fermer" Visible="false" CausesValidation="false" OnClientClick="ccFermer(); return false;" />
        </div>
    </asp:Panel>
</div>

<script type="text/javascript">
    // La classe filtre les sous-classes ; la sous-classe montre la plage où le numéro sera pris.
    function ccChoisirClasse() {
        var classe = document.getElementById('ccClasse');
        var sous = document.getElementById('ccSousClasse');
        if (!classe || !sous) return;
        var parent = classe.value, visibles = 0, seule = null;
        for (var i = 0; i < sous.options.length; i++) {
            var o = sous.options[i];
            if (!o.value) continue;
            var montre = parent !== '' && o.getAttribute('data-parent') === parent;
            o.hidden = !montre; o.disabled = !montre;
            if (montre) { visibles++; seule = o; }
        }
        var choisie = sous.options[sous.selectedIndex];
        if (!choisie || choisie.disabled) sous.value = '';
        if (visibles === 1 && seule) sous.value = seule.value;
        sous.disabled = (parent === '');
        ccChoisirSousClasse();
    }
    function ccChoisirSousClasse() {
        var sous = document.getElementById('ccSousClasse');
        var num = document.getElementById('ccNumero');
        if (!sous || !num) return;
        var o = sous.options[sous.selectedIndex];
        if (o && o.value) {
            num.innerHTML = 'Numéro : <b>attribué automatiquement</b> entre ' + o.getAttribute('data-debut') + ' et ' + o.getAttribute('data-fin') + '.';
        } else {
            num.innerHTML = 'Numéro : attribué automatiquement, une fois la sous-classe choisie.';
        }
    }
    function ccMessage(texte) {
        if (window.showAppMessage) showAppMessage(texte, 'Attention'); else alert(texte);
    }
    function ccVerifier() {
        var sous = document.getElementById('ccSousClasse');
        var nom = document.getElementById('ccNom');
        if (!sous || !sous.value) { ccMessage('Choisissez la classe, puis la sous-classe du nouveau compte.'); return false; }
        if (!nom || !nom.value.trim()) { ccMessage('Donnez un nom au nouveau compte.'); if (nom) nom.focus(); return false; }
        return true;
    }
    function ccFermer() {
        try { if (window.parent && window.parent !== window && window.parent.fermerFenetre) { window.parent.fermerFenetre(); return; } } catch (e) { }
        window.location.href = 'Importation2.aspx';
    }
    document.addEventListener('DOMContentLoaded', function () {
        var classe = document.getElementById('ccClasse');
        if (classe) { ccChoisirClasse(); }
    });
</script>
</asp:Content>
