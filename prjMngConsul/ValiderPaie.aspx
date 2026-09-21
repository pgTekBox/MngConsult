<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderPaie.aspx.vb" Inherits="MngConsul.ValiderPaie" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paie importée — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .pa-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .pa-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .pa-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .pa-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .pa-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .pa-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .onglets { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px }
    .onglets a {
        display: inline-flex; align-items: baseline; gap: 7px;
        padding: 8px 14px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600; text-decoration: none;
    }
    .onglets a:hover { background: #f8fafc }
    .onglets a.on { background: #2563eb; border-color: #2563eb; color: #fff }
    .onglets a .n { font-size: 11.5px; font-weight: 700; opacity: .75 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .bloc .v.alerte { color: #991b1b }

    .tbl-wrap {
        max-height: 660px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.pa { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.pa th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.pa th.n, table.pa td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.pa td { border-bottom: 1px solid #f1f5f9; padding: 7px 10px; color: #0f172a; vertical-align: top }
    table.pa tr.lot td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.pa tr.paie > td { border-top: 1px solid #e2e8f0 }
    table.pa tr.paie.ko > td { background: #fffbeb }
    table.pa tr.ligne td { background: #fcfdff; font-size: 12px; color: #475569 }
    table.pa tr.ligne td.el { padding-left: 30px }
    table.pa tr.inactif td { color: #94a3b8 }
    table.pa tfoot td {
        position: sticky; bottom: 0;
        font-weight: 800; background: #f1f5f9; border-top: 2px solid #cbd5e1; border-bottom: 0;
    }
    table.pa .zero { color: #cbd5e1 }
    table.pa td.nom { font-weight: 600 }
    table.pa .fil { color: #64748b; font-weight: 400 }
    table.pa .neg { color: #991b1b }

    .past {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; margin-left: 7px; white-space: nowrap;
    }
    .past.ko  { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca }
    .past.off { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0 }
    .past.dd  { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0 }

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
<div class="pa-page">

    <div class="pa-head">
        <div class="ico">🧾</div>
        <div>
            <h1>Paie</h1>
            <div class="sub">ce qui a été versé, et ce qui a été retenu</div>
        </div>
    </div>

    <p class="pa-lede">
        Une paie reprise ne se recalcule pas : on reprend ce qui a <b>été</b> versé, pas ce
        qui aurait dû l'être. Les taux d'un exercice passé ne sont pas ceux d'aujourd'hui, et
        recalculer ferait diverger la reprise des T4 et relevés 1 déjà produits. L'équilibre
        — brut moins retenues égale net — est <b>vérifié, jamais corrigé</b>.
    </p>

    <asp:Literal ID="litOnglets" runat="server" />
    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
