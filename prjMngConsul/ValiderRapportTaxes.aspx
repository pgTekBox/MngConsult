<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderRapportTaxes.aspx.vb" Inherits="MngConsul.ValiderRapportTaxes" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Rapport de taxes importé — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .tx-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .tx-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .tx-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .tx-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .tx-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .tx-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }

    .tx-wrap {
        max-height: 640px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.tx { width: 100%; border-collapse: collapse; font-size: 13px }
    table.tx th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.tx th.n, table.tx td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.tx td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a }
    table.tx tr.total td {
        background: #f8fafc; font-weight: 800; color: #0f172a;
        border-top: 1px solid #e2e8f0; border-bottom: 1px solid #e2e8f0;
    }
    table.tx tr.agence td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.tx th .st { display: block; font-weight: 600; text-transform: none; letter-spacing: 0; opacity: .8; margin-top: 2px }
    table.tx .zero { color: #cbd5e1 }
    table.tx td.lib { font-weight: 600 }

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
<div class="tx-page">

    <div class="tx-head">
        <div class="ico">🧮</div>
        <div>
            <h1>Rapport de taxes</h1>
            <div class="sub">ce que la source déclare avoir perçu et payé</div>
        </div>
    </div>

    <p class="tx-lede">
        Ce rapport ne crée rien et ne se valide pas : c'est une <b>pièce de contrôle</b>,
        et elle reste en préparation. Rien ici ne touche la comptabilité — aucune écriture,
        aucun compte de taxe, aucune déclaration. Il sert à confronter ce que la source
        déclare à ce que la reprise a repris.
    </p>
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="tax-rates,tax-summary" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
