<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ImportApideck.aspx.vb" Inherits="MngConsul.ImportApideck" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importer depuis QuickBooks — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .apd-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .apd-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .apd-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .apd-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .apd-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .apd-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 880px; line-height: 1.6 }

    h2.sect { font-size: 15px; font-weight: 800; color: #0f172a; margin: 24px 0 8px }
    h2.sect span { font-size: 12.5px; font-weight: 500; color: #64748b; margin-left: 8px }

    .bloc { border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 16px 18px }

    /* L'état de la liaison */
    .etat { display: flex; align-items: center; gap: 12px; flex-wrap: wrap }
    .pastille { width: 10px; height: 10px; border-radius: 50%; flex: none }
    .pastille.on { background: #10b981 } .pastille.off { background: #ef4444 }
    .pastille.mid { background: #f59e0b }
    .etat .txt { font-size: 13.5px; color: #0f172a; flex: 1; min-width: 260px; line-height: 1.5 }

    .btn {
        display: inline-block; padding: 8px 15px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600; cursor: pointer;
    }
    .btn:hover { background: #f8fafc }
    .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff }
    .btn.primaire:hover { background: #1d4ed8 }

    /* La barre au-dessus de la liste : tout cocher, tout décocher, et le
       décompte — pour savoir ce qui partira sans relire vingt cases. */
    .choix { display: flex; align-items: baseline; gap: 8px; margin-bottom: 10px; flex-wrap: wrap }

    .choix .lien {
        background: none; border: 0; padding: 0; font: inherit; font-size: 12.5px;
        font-weight: 700; color: #2563eb; cursor: pointer; text-decoration: underline;
    }

    .choix .lien:hover { color: #1d4ed8 }
    .choix .sep { color: #cbd5e1 }
    .choix .compte { margin-left: auto; font-size: 12px; color: #64748b }

    /* Le choix des ressources */
    .ress { column-count: 3; column-gap: 26px; margin-top: 4px }
    @media (max-width: 1100px) { .ress { column-count: 2 } }
    .ress label { display: block; break-inside: avoid; font-size: 13px; color: #0f172a; padding: 3px 0 }
    .ress input { margin-right: 7px }
    .ress .grp {
        break-inside: avoid; font-size: 11px; font-weight: 700; color: #64748b;
        text-transform: uppercase; letter-spacing: .3px; margin: 12px 0 4px;
    }
    .ress .grp:first-child { margin-top: 0 }
    .ress .vers { font-size: 11.5px; color: #047857; margin-left: 4px }

    .datebloc {
        display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
        margin-top: 14px; padding: 12px 14px; border-radius: 11px;
        background: #f8fafc; border: 1px solid #e2e8f0;
    }

    .datebloc label { font-size: 13px; font-weight: 700; color: #334155 }

    .datechamp {
        padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 9px;
        font-size: 13px; font-family: inherit; background: #fff;
    }

    .datebloc .aide { font-size: 12px; color: #64748b; flex: 1; min-width: 280px; line-height: 1.5 }

    .barre { display: flex; gap: 10px; align-items: center; margin-top: 16px; flex-wrap: wrap }
    .barre .aide { font-size: 12.5px; color: #64748b }

    /* Le compte rendu */
    table.res { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 4px }
    table.res th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; border-bottom: 1px solid #e2e8f0; padding: 7px 8px; font-weight: 700;
    }
    table.res td { border-bottom: 1px solid #f1f5f9; padding: 7px 8px; color: #0f172a }
    table.res td.n { text-align: right; font-variant-numeric: tabular-nums }
    table.res tr.ko td { background: #fef2f2 }
    table.res .ko-txt { color: #b91c1c }
    table.res .vers { color: #047857; font-size: 12px }

    .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 14px 0; line-height: 1.55 }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="apd-page">

    <div class="apd-head">
        <div class="ico">🔌</div>
        <div>
            <h1>Importer depuis QuickBooks</h1>
            <div class="sub">Lecture directe, par Apideck — sans export manuel</div>
        </div>
    </div>

    <p class="apd-lede">
        Plutôt que de demander au client d'exporter ses fichiers un à un, on lit sa comptabilité
        là où elle est. Il relie son QuickBooks une seule fois, puis chaque extraction ramène les
        données à jour. <b>Rien ne va en comptabilité</b> : tout se dépose en préparation, et les
        écrans d'import habituels prennent le relais pour décider ce qui est créé.
    </p>

    <asp:Literal ID="litMsg" runat="server" />

    <h2 class="sect">1. La liaison <span>une fois par compagnie</span></h2>
    <div class="bloc">
        <div class="etat">
            <span class="pastille" id="pastille" runat="server"></span>
            <div class="txt"><asp:Literal ID="litEtat" runat="server" /></div>
            <asp:Button ID="btnRelier" runat="server" CssClass="btn primaire" Text="Relier QuickBooks" CausesValidation="false" />
            <asp:Button ID="btnVerifier" runat="server" CssClass="btn" Text="Vérifier la liaison" CausesValidation="false" />
        </div>
    </div>

    <h2 class="sect">2. Ce qu'on rapatrie <span>tout est déposé en préparation</span></h2>
    <div class="bloc">
        <%-- Tout est coché d'avance : quand on ne veut qu'une ressource, il faut
             pouvoir vider la liste d'un geste plutôt que décocher vingt cases. --%>
        <div class="choix">
            <button type="button" class="lien" onclick="cocherRessources(false)">Tout décocher</button>
            <span class="sep">·</span>
            <button type="button" class="lien" onclick="cocherRessources(true)">Tout cocher</button>
            <span class="compte" id="compteRess"></span>
        </div>

        <asp:Literal ID="litRessources" runat="server" />

        <%-- Deux ressources demandent une date : la balance de vérification et le
             grand livre. QuickBooks les rend pour une période, et un rapport à la
             mauvaise date ressemble à s'y méprendre à un bon. --%>
        <div class="datebloc">
            <label for="<%= txtDateBalance.ClientID %>">Balance de vérification et grand livre arrêtés au</label>
            <asp:TextBox ID="txtDateBalance" runat="server" TextMode="Date" CssClass="datechamp" />
            <asp:DropDownList ID="ddlFrequenceTaxes" runat="server" CssClass="datechamp">
                <asp:ListItem Value="3" Text="Taxes déclarées par trimestre" Selected="True" />
                <asp:ListItem Value="1" Text="Taxes déclarées par mois" />
                <asp:ListItem Value="12" Text="Taxes déclarées par année" />
            </asp:DropDownList>
            <span class="aide">
                La date de bascule — la veille du premier jour tenu ici. QuickBooks exige une
                période : les comptes de résultats couvriront l'année civile jusqu'à cette date,
                les comptes de bilan porteront leur solde à cette date. Le grand livre, lui,
                est lu du 1er janvier à cette date.
                Les rapports de taxes, eux, sont rapatriés une déclaration à la fois —
                la fréquence est celle que vous produisez, et QuickBooks ne la dit nulle part.
            </span>
        </div>


        <div class="barre">
            <asp:Button ID="btnImporter" runat="server" CssClass="btn primaire" Text="Importer dans la préparation" CausesValidation="false" />
            <span class="aide">Une extraction volumineuse peut prendre quelques minutes.</span>
        </div>
    </div>

    <asp:Panel ID="pnlResultat" runat="server" Visible="false">
        <h2 class="sect">3. Ce qui est arrivé</h2>
        <div class="bloc"><asp:Literal ID="litResultat" runat="server" /></div>
    </asp:Panel>

    <h2 class="sect">Les extractions précédentes</h2>
    <div class="bloc"><asp:Literal ID="litHistorique" runat="server" /></div>

</div>

<script type="text/javascript">
    (function () {
        var compte = document.getElementById('compteRess');

        function cases() {
            return document.querySelectorAll("input[type='checkbox'][name='res']");
        }

        function dire() {
            if (!compte) return;
            var toutes = cases(), n = 0;
            for (var i = 0; i < toutes.length; i++) { if (toutes[i].checked) n++; }
            compte.textContent = n === 0
                ? 'aucune ressource choisie'
                : n + ' sur ' + toutes.length + ' choisie' + (n > 1 ? 's' : '');
        }

        // Appelée par les deux boutons ; le décompte suit aussi les clics à l'unité.
        window.cocherRessources = function (etat) {
            var toutes = cases();
            for (var i = 0; i < toutes.length; i++) { toutes[i].checked = etat; }
            dire();
        };

        var liste = cases();
        for (var i = 0; i < liste.length; i++) {
            liste[i].addEventListener('change', dire);
        }
        dire();
    })();
</script>
</asp:Content>
