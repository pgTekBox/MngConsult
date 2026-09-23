<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Importations.aspx.vb" Inherits="MngConsul.Importations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importation des données — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .imp-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .imp-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .imp-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .imp-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .imp-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .imp-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 860px; line-height: 1.6 }

    /* Le compte rendu d'ensemble */
    .bilan { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 22px }

    .bil { border: 1px solid #e2e8f0; border-radius: 11px; padding: 11px 14px; background: #fff }
    .bil .l { font-size: 11px; color: #64748b; text-transform: uppercase; letter-spacing: .3px }
    .bil .v { font-size: 22px; font-weight: 800; color: #0f172a; margin-top: 2px }
    .bil.ok { background: #ecfdf5; border-color: #a7f3d0 } .bil.ok .v { color: #047857 }
    .bil.mi { background: #fffbeb; border-color: #fde68a } .bil.mi .v { color: #b45309 }
    .bil.no { background: #f8fafc } .bil.no .v { color: #64748b }

    h2.sect {
        font-size: 15px; font-weight: 800; color: #0f172a; margin: 26px 0 4px;
        display: flex; align-items: baseline; gap: 10px;
    }
    h2.sect span { font-size: 12.5px; font-weight: 500; color: #64748b }

    .grille { display: grid; grid-template-columns: repeat(auto-fill, minmax(400px, 1fr)); gap: 14px; margin-top: 12px }

    /* Plan comptable et balance de vérification : côte à côte, toujours. */
    .grille.duo { grid-template-columns: 1fr 1fr }

    .carte {
        background: #fff; border: 1px solid #e2e8f0; border-radius: 14px;
        padding: 15px 17px; display: flex; flex-direction: column;
    }

    .carte.inerte { background: #fbfcfd; border-style: dashed }

    .chef { display: flex; align-items: flex-start; gap: 11px; margin-bottom: 11px }

    .chef .ico {
        width: 34px; height: 34px; border-radius: 10px; background: #f1f5f9;
        display: flex; align-items: center; justify-content: center; font-size: 17px; flex: 0 0 auto;
    }

    .ident { flex: 1 1 auto; min-width: 0 }

    .etape {
        display: inline-block; font-size: 10px; font-weight: 800; letter-spacing: .4px;
        text-transform: uppercase; color: #1d4ed8; background: #eff6ff;
        padding: 1px 7px; border-radius: 999px; margin-bottom: 3px;
    }

    .titre { font-size: 14.5px; font-weight: 800; color: #0f172a; line-height: 1.25 }
    .src { font-size: 11.5px; color: #94a3b8; margin-top: 2px }

    .note { flex: 0 0 auto; text-align: right; line-height: 1 }
    .note b { font-size: 22px; font-weight: 800 }
    .note span { font-size: 11px; color: #94a3b8; margin-left: 1px }
    .note.vert b { color: #047857 }
    .note.jaune b { color: #b45309 }
    .note.orange b { color: #c2410c }
    .note.gris b { color: #94a3b8 }

    .jauge { height: 6px; background: #f1f5f9; border-radius: 999px; overflow: hidden; margin-bottom: 11px }
    .jauge > div { height: 100%; border-radius: 999px }
    .jauge .vert { background: linear-gradient(90deg, #10b981, #059669) }
    .jauge .jaune { background: linear-gradient(90deg, #f59e0b, #d97706) }
    .jauge .orange { background: linear-gradient(90deg, #fb923c, #ea580c) }
    .jauge .gris { background: #cbd5e1 }

    .dest { font-size: 11.5px; color: #64748b; margin-bottom: 9px; font-family: Consolas, monospace }

    .carte p { margin: 0 0 8px; font-size: 12.5px; line-height: 1.55 }
    .fait { color: #475569 }
    .fait b { color: #047857 }
    .manque { color: #475569 }
    .manque b { color: #b45309 }

    .ouvrir {
        align-self: flex-start; margin-top: auto; padding: 7px 14px; border-radius: 9px;
        font-size: 12.5px; font-weight: 700; background: #2563eb; color: #fff; text-decoration: none;
    }
    .ouvrir:hover { background: #1d4ed8; color: #fff }

    .absent {
        align-self: flex-start; margin-top: auto; font-size: 12px; color: #94a3b8;
        font-style: italic;
    }

    .note-bas {
        margin-top: 26px; padding-top: 12px; border-top: 1px solid #e2e8f0;
        font-size: 12.5px; color: #64748b; line-height: 1.6; max-width: 860px;
    }
    .vider {
        margin-top: 26px; padding: 16px 18px; border: 1px solid #fecaca;
        border-radius: 10px; background: #fef2f2;
        display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
    }
    .vider .txt { flex: 1 1 380px; font-size: 12.5px; color: #7f1d1d; line-height: 1.6 }
    .vider .txt b { color: #991b1b }
    .vider .btn {
        border: 1px solid #b91c1c; background: #fff; color: #b91c1c;
        padding: 9px 16px; border-radius: 8px; font-size: 13px; font-weight: 600;
        cursor: pointer;
    }
    .vider .btn:hover { background: #b91c1c; color: #fff }
    .vider .fait { font-size: 12.5px; color: #166534; font-weight: 600 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="imp-page">

    <div class="imp-head">
        <div class="ico">📥</div>
        <div>
            <h1>Importation des données</h1>
            <div class="sub">Reprendre une comptabilité tenue ailleurs</div>
        </div>
    </div>

    <p class="imp-lede">
        Tous les écrans d'importation s'atteignent d'ici. Chaque poste porte une note
        sur 10 qui décrit l'état réel du code, pas une intention : lire le fichier,
        contrôler ce qu'il contient, le mettre en préparation, puis l'appliquer pour
        de bon à la comptabilité. Un écran qui prépare sans jamais appliquer plafonne —
        les données restent en attente et la reprise n'avance pas.
    </p>

    <%-- Le plan de reprise : la méthode, étape par étape, dans une fenêtre
         par-dessus la page. Un document HTML autonome (PlanReprise.html),
         pour qu'on puisse aussi l'ouvrir seul ou l'imprimer. --%>
    <style>
        .plan-lien { display: flex; align-items: center; gap: 12px; padding: 12px 15px; margin: 0 0 18px;
            border: 1px solid #bfdbfe; border-radius: 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.06), rgba(16,185,129,.05)) }
        .plan-lien .ico { font-size: 20px; flex: none }
        .plan-lien .txt { flex: 1; font-size: 13px; color: #0f172a; line-height: 1.45 }
        .plan-lien .txt span { display: block; color: #64748b; font-size: 12.5px }
        .plan-lien button { padding: 8px 15px; border-radius: 9px; border: 1px solid #2563eb; background: #2563eb;
            color: #fff; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; white-space: nowrap }
        .plan-lien button:hover { background: #1d4ed8 }
        .plan-lien a { font-size: 12.5px; color: #1d4ed8; text-decoration: none; white-space: nowrap }
        .plan-lien a:hover { text-decoration: underline }

        .plan-voile { position: fixed; inset: 0; background: rgba(15,23,42,.55); z-index: 9000;
            display: none; align-items: center; justify-content: center; padding: 24px }
        .plan-voile.ouvert { display: flex }
        .plan-fen { width: min(1040px, 100%); height: min(92vh, 100%); background: #fff; border-radius: 16px;
            box-shadow: 0 30px 80px rgba(2,6,23,.35); display: flex; flex-direction: column; overflow: hidden }
        .plan-fen .barre { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border-bottom: 1px solid #e2e8f0; background: #f8fafc }
        .plan-fen .barre b { flex: 1; font-size: 14px; color: #0f172a }
        .plan-fen .barre a, .plan-fen .barre button { font-size: 12.5px; font-family: inherit; cursor: pointer }
        .plan-fen .barre a { color: #1d4ed8; text-decoration: none; margin-right: 8px }
        .plan-fen .barre button { border: 1px solid #cbd5e1; background: #fff; border-radius: 8px; padding: 6px 11px; color: #0f172a; font-weight: 700 }
        .plan-fen iframe { flex: 1; border: 0; width: 100% }
    </style>

    <div class="plan-lien">
        <span class="ico">🧭</span>
        <div class="txt">
            <b>Plan de reprise d'une comptabilité QuickBooks</b>
            <span>Fermeture au 31 décembre, rejeu de toutes les transactions de 2026 — la méthode, étape par étape, et l'état du code pour chacune.</span>
        </div>
        <button type="button" onclick="ouvrirPlan()">Lire le plan</button>
        <a href="PlanReprise.html" target="_blank">ouvrir dans un onglet</a>
    </div>

    <div class="plan-voile" id="planVoile" onclick="if (event.target === this) fermerPlan();">
        <div class="plan-fen" role="dialog" aria-modal="true" aria-label="Plan de reprise">
            <div class="barre">
                <b>Plan de reprise d'une comptabilité QuickBooks</b>
                <a href="PlanReprise.html" target="_blank">ouvrir dans un onglet</a>
                <button type="button" onclick="fermerPlan()">Fermer ✕</button>
            </div>
            <iframe id="planCadre" title="Plan de reprise"></iframe>
        </div>
    </div>

    <script type="text/javascript">
        function ouvrirPlan() {
            var cadre = document.getElementById('planCadre');
            if (!cadre.getAttribute('src')) cadre.setAttribute('src', 'PlanReprise.html');
            document.getElementById('planVoile').classList.add('ouvert');
            document.body.style.overflow = 'hidden';
        }
        function fermerPlan() {
            document.getElementById('planVoile').classList.remove('ouvert');
            document.body.style.overflow = '';
        }
        document.addEventListener('keydown', function (e) { if (e.key === 'Escape') fermerPlan(); });
    </script>

    <div class="bilan">
        <div class="bil"><div class="l">Postes recensés</div>
            <div class="v"><asp:Literal ID="litTotal" runat="server" Text="0" /></div></div>
        <div class="bil ok"><div class="l">Utilisables</div>
            <div class="v"><asp:Literal ID="litUtilisables" runat="server" Text="0" /></div></div>
        <div class="bil mi"><div class="l">Partiels</div>
            <div class="v"><asp:Literal ID="litPartiels" runat="server" Text="0" /></div></div>
        <div class="bil no"><div class="l">À faire</div>
            <div class="v"><asp:Literal ID="litAFaire" runat="server" Text="0" /></div></div>
    </div>

    <h2 class="sect">Lecture directe <span>sans demander d'export au client</span></h2>
    <div class="grille"><asp:Literal ID="litConnexion" runat="server" /></div>

    <h2 class="sect">Reprise comptable <span>le plan comptable, puis la balance de vérification</span></h2>
    <div class="grille duo"><asp:Literal ID="litParcours" runat="server" /></div>

    <h2 class="sect">Autres importations <span>indépendantes les unes des autres</span></h2>
    <div class="grille"><asp:Literal ID="litAutres" runat="server" /></div>

    <asp:Literal ID="litTitreAVenir" runat="server" />
    <div class="grille"><asp:Literal ID="litAVenir" runat="server" /></div>

    <p class="note-bas">
        La note du plan comptable repose sur des essais
        de bout en bout, sur un vrai export QuickBooks. Les autres sont établies par
        lecture du code : elles disent ce que l'écran fait, pas ce qu'il ferait bien.
        Elles se corrigent dans <b>Importations.aspx.vb</b> ; celles des trois étapes du plan comptable, dans <b>Controls/EtapesReprise.ascx.vb</b>.
    </p>

    <div class="vider">
        <div class="txt">
            <b>Vider la préparation.</b> Efface tout ce qui attend d'être validé pour
            <asp:Literal ID="litViderCie" runat="server" /> : ressources lues chez la source,
            fichiers importés, plan comptable, tiers, produits, factures et fiche d'entreprise.
            Les autres compagnies ne sont pas touchées, et rien de ce qui est déjà passé en
            comptabilité n'est retiré — seulement le brouillon.
            <asp:Literal ID="litViderEtat" runat="server" />
        </div>
        <asp:Button ID="btnVider" runat="server" CssClass="btn" Text="Vider les tables de préparation" />
    </div>

</div>
</asp:Content>
