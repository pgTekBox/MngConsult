<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderRemisesDas.aspx.vb" Inherits="MngConsul.ValiderRemisesDas" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Remises de DAS importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .ds-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .ds-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .ds-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .ds-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .ds-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .ds-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .bloc .v.alerte { color: #92400e }

    /* Ce qui reste dû, par autorité : le chiffre de la bascule. */
    .dus { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 18px }
    .du {
        flex: 1 1 260px; background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px;
    }
    .du.federal { border-left: 4px solid #2563eb }
    .du.quebec  { border-left: 4px solid #0ea5e9 }
    .du.autre   { border-left: 4px solid #f59e0b }
    .du h2 { font-size: 14px; font-weight: 800; margin: 0 0 10px; color: #0f172a }
    .du .l2 { display: flex; justify-content: space-between; font-size: 12.5px; color: #64748b; padding: 2px 0 }
    .du .l2 b { color: #0f172a; font-variant-numeric: tabular-nums; font-weight: 600 }
    .du .reste {
        display: flex; justify-content: space-between; align-items: baseline;
        margin-top: 9px; padding-top: 9px; border-top: 1px solid #e2e8f0;
        font-size: 13px; font-weight: 800; color: #0f172a;
    }
    .du .reste .m { font-size: 18px; font-variant-numeric: tabular-nums }
    .du.autre .reste .m { color: #92400e }

    .tbl-wrap {
        max-height: 620px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.ds { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.ds th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.ds th.n, table.ds td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.ds td { border-bottom: 1px solid #f1f5f9; padding: 7px 10px; color: #0f172a; vertical-align: top }
    table.ds td.memo { color: #64748b; max-width: 300px }
    table.ds tr.aut td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.ds tr.aut.autre td { background: #fffbeb; color: #92400e; border-color: #fde68a }
    table.ds tfoot td {
        position: sticky; bottom: 0;
        font-weight: 800; background: #f1f5f9; border-top: 2px solid #cbd5e1; border-bottom: 0;
    }
    table.ds .zero { color: #cbd5e1 }
    table.ds .fil { color: #64748b }

    .past {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; white-space: nowrap;
    }
    .past.remise  { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0 }
    .past.retenue { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0 }

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
<div class="ds-page">

    <div class="ds-head">
        <div class="ico">🏛️</div>
        <div>
            <h1>Remises de DAS</h1>
            <div class="sub">ce qui a été retenu, ce qui a été versé, ce qui reste dû</div>
        </div>
    </div>

    <p class="ds-lede">
        Les déductions à la source s'accumulent à chaque paie et s'éteignent à chaque remise.
        Ce qui reste entre les deux est une <b>dette envers le fédéral et le Québec</b> — et
        c'est le chiffre que la bascule doit reprendre, sans quoi la première remise dans
        l'application sera fausse. Rien ici ne s'applique à la comptabilité.
    </p>
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="das" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litDus" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
