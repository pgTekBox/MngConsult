<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderListes.aspx.vb" Inherits="MngConsul.ValiderListes" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Listes de structure importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .lst-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .lst-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .lst-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .lst-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .lst-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .lst-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    /* Les genres, en onglets */
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

    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
                border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.lst th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700;
    }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8;
                       font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst .vide { color: #cbd5e1; font-style: italic }

    .verdict {
        display: inline-block; padding: 2px 9px; border-radius: 999px;
        font-size: 11px; font-weight: 700; white-space: nowrap;
    }
    .verdict.NOUVEAU { background: #d1fae5; color: #065f46 }
    .verdict.DOUBLON { background: #fef3c7; color: #92400e }
    .verdict.INVALIDE { background: #fee2e2; color: #991b1b }

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
<div class="lst-page">

    <div class="lst-head">
        <div class="ico">🗂️</div>
        <div>
            <h1>Listes de structure</h1>
            <div class="sub">ce que la comptabilité source range à côté des comptes</div>
        </div>
    </div>

    <p class="lst-lede">
        Modes de paiement, catégories de suivi, départements et emplacements. Ces
        listes ne se créent nulle part dans 60Sec-AI — aucune n'a encore d'équivalent
        ici. Elles sont importées pour être vues :
        savoir ce que la comptabilité source contient avant de décider quoi en faire,
        et avoir la donnée sous la main le jour où la fonction existera.
    </p>

    <asp:Literal ID="litOnglets" runat="server" />
    <asp:Literal ID="litListe" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
