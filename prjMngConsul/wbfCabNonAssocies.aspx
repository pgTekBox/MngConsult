<%@ Page Title="Clients non associés" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabNonAssocies.aspx.vb" Inherits="MngConsul.wbfCabNonAssocies" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients non associés — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 1000px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .cab-head { display: flex; align-items: center; gap: 14px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .msg { margin: 8px 0 0; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700; background: #E3F3EA; color: #0F5A3A }

    .arow { display: grid; grid-template-columns: 1fr 220px auto; gap: 12px; align-items: center; padding: 12px 14px; border-radius: 14px; background: var(--mc-page, #F2F5F9); margin-bottom: 8px }
    @media (max-width: 680px) { .arow { grid-template-columns: 1fr 1fr } }
    .arow .doss .nm { font-weight: 800; color: #0E1F3D }
    .arow .doss .cd { font-size: 12.5px; color: #5B6B86; font-weight: 700 }
    .arow select { width: 100%; height: 40px; padding: 0 10px; border: 1px solid var(--mc-line, #D5DDE8); border-radius: 10px; font: inherit; font-size: 14px; background: #fff; color: #0E1F3D; outline: none }
    .arow .save { height: 40px; padding: 0 16px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 13px; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center }
    .arow .save:hover { background: var(--mc-primary-dark, #143A73) }
    .vide { color: #44536E; font-size: 14px }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21c0-4 4-6 8-6M18 14v6M15 17h6"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>

    <section class="boite">
        <asp:Repeater ID="rptDossiers" runat="server" OnItemDataBound="rptDossiers_ItemDataBound" OnItemCommand="rptDossiers_ItemCommand">
            <ItemTemplate>
                <div class="arow">
                    <div class="doss">
                        <div class="nm"><%# Server.HtmlEncode(Convert.ToString(Eval("Name"))) %></div>
                        <div class="cd"><%# Server.HtmlEncode(Convert.ToString(Eval("CompanyCode"))) %></div>
                    </div>
                    <asp:DropDownList ID="ddlMembre" runat="server" />
                    <asp:LinkButton ID="lnkConfier" runat="server" CssClass="save" CommandName="confier" CommandArgument='<%# Eval("CompanyGUID") %>' Text='<%# LblConfier %>' />
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <asp:Literal ID="litVide" runat="server" />
    </section>
</div>
</asp:Content>
