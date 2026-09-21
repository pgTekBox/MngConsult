<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderInventaire.aspx.vb" Inherits="MngConsul.ValiderInventaire" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Inventaire importé — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .iv-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .iv-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .iv-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .iv-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .iv-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .iv-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .bloc .v.alerte { color: #92400e }

    /* Le contrôle croisé : la valeur calculée contre le solde au livre. */
    .ctrl { margin-bottom: 18px; border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 15px 16px }
    .ctrl h2 { font-size: 15px; font-weight: 800; margin: 0 0 3px; color: #0f172a }
    .ctrl .desc { font-size: 12.5px; color: #64748b; margin: 0 0 12px; line-height: 1.55 }
    .ctrl .verdict { padding: 11px 14px; border-radius: 10px; font-size: 13.5px; font-weight: 700; border: 1px solid transparent; margin-bottom: 8px }
    .ctrl .verdict.ok   { background: #f0fdf4; color: #166534; border-color: #bbf7d0 }
    .ctrl .verdict.ko   { background: #fffbeb; color: #92400e; border-color: #fde68a }
    .ctrl .verdict.rien { background: #f8fafc; color: #475569; border-color: #e2e8f0; font-weight: 600 }

    .tbl-wrap {
        max-height: 620px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.iv { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.iv th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.iv th.n, table.iv td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.iv td { border-bottom: 1px solid #f1f5f9; padding: 7px 10px; color: #0f172a; vertical-align: top }
    table.iv tr.ko td { background: #fffbeb }
    table.iv tr.inactif td { color: #94a3b8 }
    table.iv tfoot td {
        position: sticky; bottom: 0;
        font-weight: 800; background: #f1f5f9; border-top: 2px solid #cbd5e1; border-bottom: 0;
    }
    table.iv .zero { color: #cbd5e1 }
    table.iv .neg { color: #991b1b; font-weight: 700 }
    table.iv td.nom { font-weight: 600 }
    table.iv .fil { color: #64748b; font-weight: 400 }

    .past {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; margin-left: 7px; white-space: nowrap;
    }
    .past.ko   { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca }
    .past.warn { background: #fffbeb; color: #92400e; border: 1px solid #fde68a }
    .past.off  { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0 }
    .past.bas  { background: #eff6ff; color: #1e40af; border: 1px solid #bfdbfe }

    .note {
        margin-top: 16px; padding: 12px 15px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px;
    }
    .note b { color: #0f172a }

    .rien {
        border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center;
        color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7;
    }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="iv-page">

    <div class="iv-head">
        <div class="ico">📦</div>
        <div>
            <h1>Inventaire</h1>
            <div class="sub">ce qu'il reste en stock, et ce que ça vaut</div>
        </div>
    </div>

    <p class="iv-lede">
        Pour qui tient un inventaire permanent, la bascule doit reprendre trois choses par
        article : <b>combien il en reste</b>, <b>ce qu'il a coûté</b>, et donc ce qu'il vaut.
        Sans elles, le premier coût des marchandises vendues est faux — et la marge avec.
        Rien ici ne s'applique à la comptabilité.
    </p>

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litControle" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
