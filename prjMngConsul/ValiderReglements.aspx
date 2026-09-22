<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderReglements.aspx.vb" Inherits="MngConsul.ValiderReglements" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Règlements importés — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .rg-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .rg-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .rg-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .rg-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .rg-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .rg-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

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
    .repere .bloc .v.alerte { color: #92400e }

    .tbl-wrap {
        max-height: 640px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.rg { width: 100%; border-collapse: collapse; font-size: 13px }
    table.rg th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.rg th.n, table.rg td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.rg td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a }
    table.rg tr.mvt > td { border-top: 1px solid #e2e8f0 }
    table.rg tr.imput td { background: #fcfdff; font-size: 12.5px; color: #475569 }
    table.rg tr.imput td.doc { padding-left: 30px }
    table.rg tfoot td { font-weight: 800; background: #f8fafc; border-top: 2px solid #cbd5e1; border-bottom: 0 }
    table.rg .zero { color: #cbd5e1 }
    table.rg td.ref { font-weight: 600 }
    table.rg .fil { color: #64748b; font-weight: 400 }

    .past {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; margin-left: 7px; white-space: nowrap;
    }
    .past.acompte { background: #fffbeb; color: #92400e; border: 1px solid #fde68a }
    .past.partiel { background: #eff6ff; color: #1e40af; border: 1px solid #bfdbfe }
    .past.absent  { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca }
    .past.solde   { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0 }

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
<div class="rg-page">

    <div class="rg-head">
        <div class="ico">💵</div>
        <div>
            <h1>Acomptes et règlements partiels</h1>
            <div class="sub">l'argent reçu ou versé, et ce qu'il règle vraiment</div>
        </div>
    </div>

    <p class="rg-lede">
        Un montant encaissé ne dit rien tant qu'on ne sait pas ce qu'il règle. Cet écran
        montre chaque mouvement avec ses <b>imputations</b> : ce qui solde une facture,
        ce qui n'en paie qu'une part, et ce qui ne règle encore rien — l'<b>acompte</b>.
        C'est ce dernier qui fait diverger la balance âgée du solde des factures.
    </p>
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="payments,bill-payments,refunds" />

    <asp:Literal ID="litOnglets" runat="server" />
    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
