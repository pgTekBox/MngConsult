<%@ Page Title="Demandes de clients" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabDemandes.aspx.vb" Inherits="MngConsul.wbfCabDemandes" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Demandes de clients — Portail comptable
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

    .drow { display: flex; align-items: center; gap: 12px; padding: 14px 16px; border-radius: 16px; background: var(--mc-page, #F2F5F9); margin-bottom: 10px }
    .drow .who { flex: 1; min-width: 0 }
    .drow .who .nm { font-weight: 800; color: #0E1F3D; font-size: 15px }
    .drow .who .mt { font-size: 13px; color: #44536E; margin-top: 2px }
    .drow .when { font-size: 12px; color: #5B6B86; font-weight: 700; white-space: nowrap }
    .drow .acts { display: flex; gap: 8px }
    .btn { height: 40px; padding: 0 16px; border: 0; border-radius: 999px; font: inherit; font-weight: 800; font-size: 13px; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center }
    .btn.ok { background: var(--mc-primary, #1B4F9C); color: #fff } .btn.ok:hover { background: var(--mc-primary-dark, #143A73) }
    .btn.no { background: #FDECEA; color: #A3261C } .btn.no:hover { background: #fbdcd7 }
    .vide { color: #44536E; font-size: 14px }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>

    <section class="boite">
        <asp:Repeater ID="rptDemandes" runat="server" OnItemCommand="rptDemandes_ItemCommand">
            <ItemTemplate>
                <div class="drow">
                    <div class="who">
                        <div class="nm"><%# Server.HtmlEncode(Convert.ToString(Eval("Name"))) %></div>
                        <div class="mt"><%# MsgText(Eval("Message")) %></div>
                    </div>
                    <span class="when"><%# DateText(Eval("RecueLe")) %></span>
                    <div class="acts">
                        <asp:LinkButton runat="server" CssClass="btn ok" CommandName="accepter" CommandArgument='<%# Eval("Id") %>' Text='<%# LblAccepter %>' />
                        <asp:LinkButton runat="server" CssClass="btn no" CommandName="refuser" CommandArgument='<%# Eval("Id") %>' Text='<%# LblRefuser %>' OnClientClick='<%# ConfirmJs() %>' />
                    </div>
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <asp:Literal ID="litVide" runat="server" />
    </section>
</div>
</asp:Content>
