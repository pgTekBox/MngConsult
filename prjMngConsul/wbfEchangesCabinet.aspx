<%@ Page Title="Messages du cabinet" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfEchangesCabinet.aspx.vb" Inherits="MngConsul.wbfEchangesCabinet" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Messages du cabinet — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .ec-page { padding: 0; max-width: 800px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .ec-head { display: flex; align-items: center; gap: 14px; margin-bottom: 4px }
    .ec-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .ec-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .ec-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .fil { display: flex; flex-direction: column; gap: 10px; margin-bottom: 16px }
    .bulle { max-width: 78%; padding: 10px 14px; border-radius: 16px; font-size: 14px; line-height: 1.45 }
    .bulle .meta { font-size: 11px; font-weight: 800; margin-bottom: 3px; opacity: .8 }
    .bulle.moi { align-self: flex-end; background: var(--mc-primary, #1B4F9C); color: #fff; border-bottom-right-radius: 4px }
    .bulle.cab { align-self: flex-start; background: var(--mc-page, #F2F5F9); color: #0E1F3D; border-bottom-left-radius: 4px }
    .envoi { display: flex; gap: 10px; align-items: flex-end }
    .ech-in { flex: 1; min-height: 60px; padding: 10px 12px; border: 1px solid var(--mc-line,#D5DDE8); border-radius: 14px; font: inherit; font-size: 14px; color: #0E1F3D; background: #fff; outline: none; box-sizing: border-box; resize: vertical }
    .ech-in:focus { border-color: var(--mc-primary,#1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .vide { color: #44536E; font-size: 14px }
    .msg { margin-top: 12px; padding: 10px 14px; border-radius: 12px; font-size: 13.5px; font-weight: 700; background: #E3F3EA; color: #0F5A3A }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="ec-page">
    <section class="boite">
        <div class="ec-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg></div>
            <div>
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
    </section>

    <section class="boite">
        <div class="fil"><asp:Literal ID="litFil" runat="server" /></div>
        <asp:Panel ID="pnlEnvoi" runat="server" CssClass="envoi">
            <asp:TextBox ID="txtRep" runat="server" TextMode="MultiLine" CssClass="ech-in" />
            <asp:Button ID="btnRep" runat="server" CssClass="btn" />
        </asp:Panel>
        <asp:Literal ID="litMsg" runat="server" />
    </section>
</div>
</asp:Content>
