<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderRecurrentes.aspx.vb" Inherits="MngConsul.ValiderRecurrentes" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Transactions récurrentes importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .tr-page { max-width: 1320px; margin: 0 auto; padding: 16px }
    .tr-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .tr-head .ico { width: 46px; height: 46px; border-radius: 13px; border: 1px solid #e2e8f0;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        display: flex; align-items: center; justify-content: center; font-size: 21px }
    .tr-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .tr-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .tr-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }
    .repere { display: flex; gap: 18px; flex-wrap: wrap; margin: 0 0 14px; padding: 10px 14px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #e2e8f0; font-size: 12.5px; color: #475569 }
    .repere b { color: #0f172a }
    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.lst th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b;
        background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 9px 10px; font-weight: 700 }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8; font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst tr.inactif td { color: #94a3b8 }
    table.lst .vide { color: #cbd5e1; font-style: italic }
    .verdict { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap }
    .verdict.on { background: #d1fae5; color: #065f46 }
    .verdict.off { background: #f1f5f9; color: #64748b }
    .verdict.INVALIDE { background: #fee2e2; color: #991b1b }
    .note { margin-top: 16px; padding: 12px 15px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px }
    .rien { border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center; color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="tr-page">
    <div class="tr-head">
        <div class="ico">🔁</div>
        <div>
            <h1>Transactions récurrentes</h1>
            <div class="sub">ce que la source produit toute seule, à date fixe</div>
        </div>
    </div>
    <p class="tr-lede">
        Un loyer facturé le premier du mois, une écriture d'amortissement, un abonnement fournisseur :
        QuickBooks les génère sans qu'on y pense. Une reprise qui les oublie voit ces mouvements
        s'arrêter net à la bascule. Cet écran liste les modèles, leur cadence et leur prochaine
        échéance, pour qu'on les recrée ici en connaissance de cause. Rien ne s'applique à la comptabilité.
    </p>

    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="recurring-transactions" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />
</div>
</asp:Content>
