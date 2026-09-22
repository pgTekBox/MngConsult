<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderPiecesJointes.aspx.vb" Inherits="MngConsul.ValiderPiecesJointes" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Pièces jointes importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .pj-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .pj-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .pj-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .pj-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .pj-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .pj-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    /* Les entités porteuses, en onglets */
    .onglets { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px }
    .onglets a {
        display: inline-flex; align-items: baseline; gap: 7px;
        padding: 8px 14px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600;
        text-decoration: none;
    }
    .onglets a:hover { background: #f8fafc }
    .onglets a.on { background: #2563eb; border-color: #2563eb; color: #fff }
    .onglets a .n { font-size: 11.5px; font-weight: 700; opacity: .75 }
    .onglets a .souci { color: #b45309; font-weight: 700 }
    .onglets a.on .souci { color: #fde68a }

    .repere {
        display: flex; gap: 18px; flex-wrap: wrap; margin: 0 0 14px; padding: 10px 14px;
        border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; font-size: 12.5px; color: #475569;
    }
    .repere b { color: #0f172a }

    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
                border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.lst th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700;
    }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8;
                       font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst .vide { color: #cbd5e1; font-style: italic }
    table.lst .sous { display: block; font-size: 11.5px; color: #64748b; margin-top: 2px }
    table.lst a.fich { color: #1d4ed8; text-decoration: none; font-weight: 600 }
    table.lst a.fich:hover { text-decoration: underline }
    table.lst .lie { display: inline-block; padding: 1px 7px; border-radius: 999px; font-size: 10.5px;
                     font-weight: 800; background: #dcfce7; color: #166534; margin-left: 5px; white-space: nowrap }

    .verdict {
        display: inline-block; padding: 2px 9px; border-radius: 999px;
        font-size: 11px; font-weight: 700; white-space: nowrap;
    }
    .verdict.TELECHARGE { background: #d1fae5; color: #065f46 }
    .verdict.NOUVEAU { background: #eff6ff; color: #1d4ed8 }
    .verdict.SANS_LIEN, .verdict.TROP_GROS { background: #fef3c7; color: #92400e }
    .verdict.ECHEC { background: #fee2e2; color: #991b1b }
    .verdict.RATTACHE { background: #dcfce7; color: #166534 }

    .barre { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin: 0 0 16px }
    .barre .aide { font-size: 12.5px; color: #64748b }
    .btn {
        display: inline-block; padding: 8px 15px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit;
    }
    .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff }
    .btn.primaire:hover { background: #1d4ed8 }

    .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 0 0 14px; line-height: 1.55 }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }

    .note {
        margin-top: 16px; padding: 12px 15px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px;
    }

    .rien {
        border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center;
        color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7;
    }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="pj-page">

    <div class="pj-head">
        <div class="ico">📎</div>
        <div>
            <h1>Pièces jointes</h1>
            <div class="sub">tout ce que la comptabilité source a attaché, à qui que ce soit</div>
        </div>
    </div>

    <p class="pj-lede">
        Un contrat sur la fiche d'un client, une soumission scannée chez un fournisseur, une photo
        sur un article, le reçu d'une dépense : QuickBooks attache des fichiers à presque tout.
        Cet écran les rapatrie <b>par la passerelle</b>, entité par entité, et garde le
        <b>fichier lui-même</b> en préparation — pas seulement son nom. Rien ne s'applique à la
        comptabilité : on sait ce qu'il y a, et on peut l'ouvrir.
    </p>

    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="attachments-all" />

    <asp:Literal ID="litMsg" runat="server" />

    <%-- Le second geste : ce qui a un fichier et un tiers retrouvé rejoint la
         fiche du client ou du fournisseur (T057PartyDocument). Idempotent. --%>
    <div class="barre">
        <asp:Button ID="btnRattacher" runat="server" CssClass="btn primaire" CausesValidation="false"
            Text="📎 Rattacher aux fiches clients et fournisseurs"
            OnClientClick="if (!confirm('Copier sur la fiche de chaque client ou fournisseur retrouvé les fichiers qui lui appartiennent ? Les pièces déjà rattachées ne sont pas dupliquées.')) { return false; }" />
        <span class="aide">Les pièces des autres entités (factures, articles…) restent en préparation.</span>
    </div>

    <asp:Literal ID="litOnglets" runat="server" />
    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litListe" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
