<%@ Page Title="Droits par activité" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabDroits.aspx.vb" Inherits="MngConsul.wbfCabDroits" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Droits par activité — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; width: 100% }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .cab-head { display: flex; align-items: center; gap: 14px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }

    .mrow { padding: 14px 16px; border-radius: 16px; background: var(--mc-page, #F2F5F9); margin-bottom: 10px }
    .mrow .nm { font-weight: 800; color: #0E1F3D; margin-bottom: 8px }
    .mrow .cbl label { display: inline-flex; align-items: center; gap: 5px; margin: 0 14px 6px 0; font-size: 13px; font-weight: 700; color: #44536E; white-space: nowrap }
    .actions { margin-top: 4px }
    .btn { height: 46px; padding: 0 20px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 15px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .msg { margin-top: 14px; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700; background: #E3F3EA; color: #0F5A3A }
    .vide { color: #44536E; font-size: 14px }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
    </section>

    <section class="boite">
        <asp:Repeater ID="rptMembres" runat="server" OnItemDataBound="rptMembres_ItemDataBound">
            <ItemTemplate>
                <div class="mrow">
                    <div class="nm"><asp:HiddenField ID="hfUser" runat="server" Value='<%# Eval("UserGUID") %>' /><%# NomMembre(Eval("FirstName"), Eval("LastName"), Eval("Email")) %></div>
                    <asp:CheckBoxList ID="cblDom" runat="server" RepeatDirection="Horizontal" RepeatLayout="Flow" CssClass="cbl" />
                </div>
            </ItemTemplate>
        </asp:Repeater>
        <asp:Literal ID="litVide" runat="server" />
        <div class="actions"><asp:Button ID="btnSave" runat="server" CssClass="btn" /></div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>
</div>
</asp:Content>
