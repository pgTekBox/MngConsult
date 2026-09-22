<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderBudgets.aspx.vb" Inherits="MngConsul.ValiderBudgets" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Budgets importés — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .bg-page { max-width: 1320px; margin: 0 auto; padding: 16px }
    .bg-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .bg-head .ico { width: 46px; height: 46px; border-radius: 13px; border: 1px solid #e2e8f0;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        display: flex; align-items: center; justify-content: center; font-size: 21px }
    .bg-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .bg-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .bg-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }
    h2.sect { font-size: 15px; font-weight: 800; color: #0f172a; margin: 22px 0 8px }
    h2.sect span { font-size: 12.5px; font-weight: 500; color: #64748b; margin-left: 8px }
    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.lst th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b;
        background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 9px 10px; font-weight: 700 }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8; font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst tr.on td { background: #eff6ff }
    table.lst tr.total td { font-weight: 800; background: #f8fafc; border-top: 2px solid #e2e8f0 }
    table.lst a { color: #1d4ed8; text-decoration: none; font-weight: 600 }
    table.lst a:hover { text-decoration: underline }
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
<div class="bg-page">
    <div class="bg-head">
        <div class="ico">🎯</div>
        <div>
            <h1>Budgets</h1>
            <div class="sub">ce que la source prévoyait, compte par compte et période par période</div>
        </div>
    </div>
    <p class="bg-lede">
        Un budget ne se comptabilise pas : il sert de repère. Cet écran montre chaque budget de la
        source, puis ses lignes — le compte, la période, le montant — pour qu'on puisse le reprendre
        ici à la main, ou décider qu'il n'a plus cours. Rien ne s'applique à la comptabilité.
    </p>

    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="budgets" />

    <asp:Literal ID="litListe" runat="server" />
    <asp:Literal ID="litLignes" runat="server" />
    <asp:Literal ID="litNote" runat="server" />
</div>
</asp:Content>
