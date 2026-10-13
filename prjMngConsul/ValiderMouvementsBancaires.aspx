<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderMouvementsBancaires.aspx.vb" Inherits="MngConsul.ValiderMouvementsBancaires" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Dépôts et virements bancaires importés — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .mb-page { padding: 16px }
    .mb-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .mb-head .ico { width: 46px; height: 46px; border-radius: 13px; border: 1px solid #D5DDE8;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        display: flex; align-items: center; justify-content: center; font-size: 21px }
    .mb-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .mb-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .mb-lede { font-size: 13.5px; color: #44536E; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .onglets { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px }
    .onglets a { display: inline-flex; align-items: baseline; gap: 7px; padding: 8px 14px; border-radius: 9px;
        border: 1px solid #cbd5e1; background: #fff; color: #0E1F3D; font-size: 13px; font-weight: 600; text-decoration: none }
    .onglets a:hover { background: #f8fafc }
    .onglets a.on { background: #1B4F9C; border-color: #1B4F9C; color: #fff }
    .onglets a .n { font-size: 11.5px; font-weight: 700; opacity: .75 }
    .onglets a .souci { color: #b45309; font-weight: 700 }
    .onglets a.on .souci { color: #fde68a }

    .repere { display: flex; gap: 18px; flex-wrap: wrap; margin: 0 0 14px; padding: 10px 14px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #D5DDE8; font-size: 12.5px; color: #44536E }
    .repere b { color: #0E1F3D }

    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; border: 1px solid #D5DDE8; border-radius: 12px; overflow: hidden }
    table.lst th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #44536E;
        background: #f8fafc; border-bottom: 1px solid #D5DDE8; padding: 9px 10px; font-weight: 700 }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0E1F3D; vertical-align: top }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8; font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst tr.ligne td { background: #fafbfc; font-size: 12.5px; color: #44536E; border-bottom: 1px dashed #D5DDE8 }
    table.lst tr.ligne td:first-child { padding-left: 28px }
    table.lst .vide { color: #cbd5e1; font-style: italic }
    .genre { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 700 }
    .genre.Depot { background: #d1fae5; color: #065f46 }
    .genre.Virement { background: #e0e7ff; color: #3730a3 }
    .verdict { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap }
    .verdict.NOUVEAU { background: #E3EBF7; color: #143A73 }
    .verdict.INVALIDE { background: #fee2e2; color: #991b1b }
    .note { margin-top: 16px; padding: 12px 15px; border-radius: 10px; background: #f8fafc; border: 1px solid #D5DDE8;
        font-size: 12.5px; color: #44536E; line-height: 1.6; max-width: 920px }
    .rien { border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center; color: #44536E; font-size: 13.5px; background: #fff; line-height: 1.7 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="mb-page">
    <div class="mb-head">
        <div class="ico">🏧</div>
        <div>
            <h1>Dépôts et virements bancaires</h1>
            <div class="sub">l'argent qui bouge entre comptes sans passer par une facture</div>
        </div>
    </div>
    <p class="mb-lede">
        Un dépôt regroupe des encaissements en banque ; un virement déplace des fonds d'un compte à
        l'autre. Ni l'un ni l'autre ne passe par une facture, et c'est ce qui les rend faciles à oublier
        dans une reprise. Cet écran les montre avec leurs lignes — d'où vient chaque montant déposé —
        pour contrôle. Rien ne s'applique à la comptabilité.
    </p>

    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="bank-movements" />

    <asp:Literal ID="litOnglets" runat="server" />
    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />
</div>
</asp:Content>
