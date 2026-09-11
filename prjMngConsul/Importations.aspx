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

    <h2 class="sect">Reprise comptable <span>le plan comptable, puis la balance de vérification</span></h2>
    <div class="grille duo"><asp:Literal ID="litParcours" runat="server" /></div>

    <h2 class="sect">Autres importations <span>indépendantes les unes des autres</span></h2>
    <div class="grille"><asp:Literal ID="litAutres" runat="server" /></div>

    <h2 class="sect">À construire <span>l'ordre d'une reprise complète</span></h2>
    <div class="grille"><asp:Literal ID="litAVenir" runat="server" /></div>

    <p class="note-bas">
        La note du plan comptable repose sur des essais
        de bout en bout, sur un vrai export QuickBooks. Les autres sont établies par
        lecture du code : elles disent ce que l'écran fait, pas ce qu'il ferait bien.
        Elles se corrigent dans <b>Importations.aspx.vb</b> ; celles des trois étapes du plan comptable, dans <b>Controls/EtapesReprise.ascx.vb</b>.
    </p>

</div>
</asp:Content>
