<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderFeuillesTemps.aspx.vb" Inherits="MngConsul.ValiderFeuillesTemps" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Feuilles de temps importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .ft-page { max-width: 1320px; margin: 0 auto; padding: 16px }
    .ft-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .ft-head .ico { width: 46px; height: 46px; border-radius: 13px; border: 1px solid #e2e8f0;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        display: flex; align-items: center; justify-content: center; font-size: 21px }
    .ft-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .ft-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .ft-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }
    h2.sect { font-size: 15px; font-weight: 800; color: #0f172a; margin: 22px 0 8px }
    h2.sect span { font-size: 12.5px; font-weight: 500; color: #64748b; margin-left: 8px }
    table.lst { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.lst th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b;
        background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 9px 10px; font-weight: 700 }
    table.lst td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.lst td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.lst td.cle { font-size: 11.5px; color: #94a3b8; font-family: ui-monospace, Menlo, Consolas, monospace }
    table.lst tr.souci td { background: #fffbeb }
    table.lst .vide { color: #cbd5e1; font-style: italic }
    .pill { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap }
    .pill.Billable { background: #d1fae5; color: #065f46 }
    .pill.HasBeenBilled { background: #dbeafe; color: #1e40af }
    .pill.NotBillable { background: #f1f5f9; color: #64748b }
    .pill.INVALIDE { background: #fee2e2; color: #991b1b }
    .note { margin-top: 16px; padding: 12px 15px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px }
    .rien { border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center; color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="ft-page">
    <div class="ft-head">
        <div class="ico">⏱️</div>
        <div>
            <h1>Feuilles de temps</h1>
            <div class="sub">qui a travaillé pour qui, combien de temps, et si c'est facturé</div>
        </div>
    </div>
    <p class="ft-lede">
        Le temps saisi et pas encore facturé est de l'argent en attente : une reprise qui l'oublie
        le perd. Cet écran montre chaque activité — la personne, le client, l'article, la durée — et
        résume par personne ce qui reste facturable. Rien ne s'applique à la comptabilité.
    </p>

    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="time-activities" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />
</div>
</asp:Content>
