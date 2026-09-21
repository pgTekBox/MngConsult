<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderNonRapprochees.aspx.vb" Inherits="MngConsul.ValiderNonRapprochees" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Opérations non rapprochées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .nr-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .nr-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .nr-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .nr-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .nr-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .nr-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 14px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .bloc .v.alerte { color: #92400e }

    .filtre { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; margin-bottom: 12px; font-size: 13px; color: #475569 }
    .filtre label { display: inline-flex; align-items: center; gap: 6px; cursor: pointer }

    .tbl-wrap {
        max-height: 640px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.nr { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.nr th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.nr th.n, table.nr td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.nr td { border-bottom: 1px solid #f1f5f9; padding: 7px 10px; color: #0f172a; vertical-align: top }
    table.nr td.memo { color: #64748b; max-width: 260px }
    table.nr tr.compte td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.nr tfoot td {
        position: sticky; bottom: 0;
        font-weight: 800; background: #f1f5f9; border-top: 2px solid #cbd5e1; border-bottom: 0;
    }
    table.nr .zero { color: #cbd5e1 }

    .past {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; white-space: nowrap;
    }
    .past.non { background: #fffbeb; color: #92400e; border: 1px solid #fde68a }
    .past.oui { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0 }

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
<div class="nr-page">

    <div class="nr-head">
        <div class="ico">🔍</div>
        <div>
            <h1>Opérations non rapprochées</h1>
            <div class="sub">ce que la source n'avait pas encore pointé</div>
        </div>
    </div>

    <p class="nr-lede">
        À la bascule, la base est vide : c'est donc le <b>pointage de la source</b> qui fait
        foi. Sans lui, le premier rapprochement bancaire est faux de tous les chèques émis
        avant la bascule et encaissés après. Cet écran montre ce que la comptabilité source
        tenait pour non pointé — rien ne s'applique à la comptabilité d'ici.
    </p>

    <asp:Literal ID="litRepere" runat="server" />

    <asp:Panel ID="pnlFiltre" runat="server" CssClass="filtre" Visible="false">
        <asp:CheckBox ID="chkToutes" runat="server" AutoPostBack="true"
                      Text=" Montrer aussi les opérations déjà pointées" />
        <asp:Literal ID="litCompteur" runat="server" />
    </asp:Panel>

    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
