<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderSoldesBancaires.aspx.vb" Inherits="MngConsul.ValiderSoldesBancaires" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Soldes bancaires importés — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .sb-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .sb-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .sb-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .sb-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .sb-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .sb-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }

    table.sb { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
               border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.sb th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.sb th.n, table.sb td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.sb td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a }
    table.sb tfoot td { font-weight: 800; background: #f8fafc; border-top: 2px solid #e2e8f0; border-bottom: 0 }
    table.sb tr.genre td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.sb tr.inactif td { color: #94a3b8 }
    table.sb .zero { color: #cbd5e1 }
    table.sb td.nom { font-weight: 600 }
    table.sb .fil { color: #64748b; font-weight: 400 }

    .pastille {
        display: inline-block; padding: 1px 7px; border-radius: 999px;
        font-size: 11px; font-weight: 700; margin-left: 7px;
        background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0;
    }
    .pastille.off { background: #fef2f2; color: #991b1b; border-color: #fecaca }

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
<div class="sb-page">

    <div class="sb-head">
        <div class="ico">🏦</div>
        <div>
            <h1>Soldes bancaires</h1>
            <div class="sub">ce que la source porte en banque, et depuis quand</div>
        </div>
    </div>

    <p class="sb-lede">
        Ce relevé ne crée rien et ne se valide pas : c'est une <b>pièce de contrôle</b>,
        et elle reste en préparation. Elle dit quels comptes de banque et de carte de crédit
        la comptabilité source tient, et ce qu'ils portent — de quoi confronter une reprise
        à son origine avant le premier rapprochement.
    </p>
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="bank-accounts" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
