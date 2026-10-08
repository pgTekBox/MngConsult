<%@ Page Title="Associer un compte du plan comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="AssocierCompte.aspx.vb" Inherits="MngConsul.AssocierCompte" %>
<%@ Register Src="~/Controls/EtapesReprise.ascx" TagPrefix="uc" TagName="EtapesReprise" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Associer un compte — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .asc-page { padding: 16px; max-width: 900px }

    .asc-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .asc-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(16,185,129,.14), rgba(37,99,235,.10));
        border: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .asc-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .asc-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .asc-head .sub a { color: #1d4ed8; text-decoration: none }
    .asc-head .sub a:hover { text-decoration: underline }

    .asc-lede { font-size: 13.5px; color: #475569; margin: 0 0 14px; line-height: 1.6 }

    /* La carte, telle que la maquette : l'assistant en tête, puis les deux colonnes, puis l'enjeu. */
    .asc-carte { background: #fff; border: 1px solid #cbd5e1; border-radius: 14px; overflow: hidden; margin-bottom: 14px }
    .asc-assist { display: flex; gap: 16px; align-items: flex-start; padding: 18px 20px; background: #f8fafc; border-bottom: 1px solid #e2e8f0 }
    .asc-avatar { position: relative; width: 60px; height: 60px; flex: 0 0 60px; border-radius: 50%;
                  background: #fde68a; border: 3px solid #fbbf24; display: flex; align-items: center; justify-content: center; font-size: 30px }
    .asc-avatar b { position: absolute; right: -4px; bottom: -4px; width: 24px; height: 24px; border-radius: 50%; background: #1e293b; color: #fff;
                    font-size: 11px; font-weight: 800; display: flex; align-items: center; justify-content: center; border: 2px solid #fff }
    .asc-assist .qui { display: flex; align-items: center; gap: 10px; font-size: 17px; font-weight: 800; color: #0f172a; margin-bottom: 8px }
    .asc-badge { font-size: 11.5px; font-weight: 800; padding: 3px 9px; border-radius: 999px; background: #fef3c7; color: #92400e; border: 1px solid #fcd34d }
    .asc-assist .dit { font-size: 14px; color: #1e293b; line-height: 1.55; background: #e2e8f0; border-radius: 10px; padding: 10px 14px }

    .asc-corps { padding: 18px 20px }
    .asc-corps h2 { font-size: 17px; font-weight: 800; margin: 0 0 14px; color: #0f172a }
    .asc-deux { display: grid; grid-template-columns: 1fr 44px 1.4fr; gap: 10px; align-items: start }
    .asc-fleche { display: flex; align-items: center; justify-content: center; height: 100%; min-height: 90px; font-size: 26px; color: #475569 }

    .asc-source { border: 1px solid #cbd5e1; border-radius: 12px; padding: 12px 14px; background: #fff }
    .asc-titre { font-size: 10.5px; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; color: #64748b; margin-bottom: 6px }
    .asc-source .num { font-size: 13.5px; color: #334155 }
    .asc-source .nom { font-size: 15px; font-weight: 800; color: #0f172a; margin: 2px 0 4px }
    .asc-source .meta { font-size: 12.5px; color: #64748b; line-height: 1.55 }
    .asc-source .meta b { color: #334155 }

    .asc-choix { display: flex; flex-direction: column; gap: 8px }
    .asc-opt { display: block; border: 1px solid #cbd5e1; border-radius: 12px; padding: 10px 12px; background: #fff; cursor: pointer }
    .asc-opt:hover { border-color: #93c5fd }
    .asc-opt.active { border-color: #2563eb; background: #eff6ff; box-shadow: 0 0 0 1px #2563eb inset }
    .asc-opt .ligne { display: flex; align-items: center; gap: 9px; font-size: 14.5px; color: #0f172a }
    .asc-opt .ligne input { margin: 0 }
    .asc-opt .ligne .num { color: #475569 }
    .asc-opt .ligne .nom { font-weight: 800 }
    .asc-opt .reco { display: inline-block; margin: 5px 0 0 25px; font-size: 11.5px; font-weight: 800; padding: 2px 8px; border-radius: 6px; background: #dcfce7; color: #166534 }
    .asc-opt .raison { margin: 5px 0 0 25px; font-size: 12.5px; color: #475569; line-height: 1.5 }
    .asc-opt .raison.mal { color: #b91c1c }

    .asc-enjeu { margin: 14px 0 0; display: flex; gap: 10px; align-items: flex-start; background: #fffbeb; border: 1px solid #fcd34d; border-radius: 10px; padding: 10px 14px; font-size: 13.5px; color: #78350f; line-height: 1.5 }
    .asc-enjeu[hidden] { display: none }
    .asc-enjeu .pic { font-size: 16px; line-height: 1.3 }

    .asc-actions { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 14px 20px; border-top: 1px solid #e2e8f0; background: #fff }
    .asc-actions .droite { display: flex; gap: 10px }
    .asc-btn { padding: 10px 16px; border-radius: 9px; font-size: 13.5px; font-weight: 700; border: 1px solid #cbd5e1; cursor: pointer; font-family: inherit; background: #fff; color: #0f172a }
    .asc-btn:hover { background: #f1f5f9 }
    .asc-btn.primaire { background: #2563eb; color: #fff; border-color: #2563eb }
    .asc-btn.primaire:hover { background: #1d4ed8 }

    .asc-progres { font-size: 12.5px; color: #64748b; margin: 0 0 10px }
    .asc-fin { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 22px 24px }
    .asc-fin h2 { font-size: 18px; font-weight: 800; margin: 0 0 8px; color: #0f172a }
    .asc-fin p { font-size: 13.5px; color: #475569; margin: 0 0 12px; line-height: 1.6 }
    .asc-fin .liens { display: flex; gap: 10px; flex-wrap: wrap; align-items: center }
    .asc-fin a.asc-btn { text-decoration: none; display: inline-block }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="asc-page">
    <uc:EtapesReprise ID="ucEtapes" runat="server" Etape="2" />

    <div class="asc-head">
        <div class="ico">🤝</div>
        <div>
            <h1>Associer un compte du plan comptable</h1>
            <div class="sub">Étape 2, un compte à la fois : l'assistant propose, vous décidez.
                <a href="CorrespondanceComptes.aspx">Voir la grille complète</a></div>
        </div>
    </div>

    <p class="asc-lede">
        Chaque compte de l'ancien logiciel encore « à décider » se présente ici avec son solde, les comptes de 60secondes qui lui
        ressemblent et ce que changerait une mauvaise association. Rien n'est écrit dans votre comptabilité : la décision se range
        en préparation, comme dans la grille.
    </p>

    <asp:HiddenField ID="hfCle" runat="server" />
    <asp:Literal ID="litProgres" runat="server" />

    <asp:Panel ID="pnlCarte" runat="server" CssClass="asc-carte">
        <asp:Literal ID="litCarte" runat="server" />
        <div class="asc-actions">
            <asp:Button ID="btnPlusTard" runat="server" CssClass="asc-btn" Text="Plus tard" CausesValidation="false" />
            <div class="droite">
                <asp:Button ID="btnCabinet" runat="server" CssClass="asc-btn" Text="Demander à mon cabinet certifié" CausesValidation="false"
                    OnClientClick="if (!confirm('Envoyer ce compte à votre cabinet certifié par courriel, avec le solde et les comptes proposés ? Le compte reste à décider ici.')) { return false; }" />
                <asp:Button ID="btnAssocier" runat="server" CssClass="asc-btn primaire" Text="Associer le compte"
                    OnClientClick="if (!ascVerifier()) { return false; }" />
            </div>
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlFin" runat="server" CssClass="asc-fin" Visible="false">
        <asp:Literal ID="litFin" runat="server" />
        <div class="liens">
            <asp:Button ID="btnReprendre" runat="server" CssClass="asc-btn" Text="Reprendre les comptes reportés" CausesValidation="false" Visible="false" />
            <a class="asc-btn" href="CorrespondanceComptes.aspx">Voir la grille de l'étape 2</a>
            <a class="asc-btn primaire" href="AppliquerPlanComptable.aspx">Créer les comptes au plan →</a>
        </div>
    </asp:Panel>
</div>

<script type="text/javascript">
    // Le choix se lit dans le groupe de boutons radio « cible » ; l'enjeu suit le choix.
    function ascChoisir(input) {
        var opts = document.querySelectorAll('.asc-opt');
        for (var i = 0; i < opts.length; i++) opts[i].classList.remove('active');
        var opt = input.closest('.asc-opt');
        if (opt) opt.classList.add('active');
        var enjeu = document.getElementById('ascEnjeu');
        if (!enjeu) return;
        var texte = opt ? (opt.getAttribute('data-enjeu') || '') : '';
        if (texte) { document.getElementById('ascEnjeuTexte').innerHTML = texte; enjeu.removeAttribute('hidden'); }
        else { enjeu.setAttribute('hidden', 'hidden'); }
    }
    function ascVerifier() {
        var coche = document.querySelector('input[name="cible"]:checked');
        if (!coche) {
            if (window.showAppMessage) { showAppMessage('Choisissez un compte de 60secondes, ou « Créer un nouveau compte », avant d\'associer.', 'Attention'); }
            else { alert('Choisissez un compte de 60secondes, ou « Créer un nouveau compte », avant d\'associer.'); }
            return false;
        }
        return true;
    }
    document.addEventListener('DOMContentLoaded', function () {
        var coche = document.querySelector('input[name="cible"]:checked');
        if (coche) ascChoisir(coche);
    });
</script>
</asp:Content>
