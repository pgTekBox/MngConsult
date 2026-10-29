<%@ Page Title="Équipes" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabEquipes.aspx.vb" Inherits="MngConsul.wbfCabEquipes" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Équipes — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 1000px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .cab-head { display: flex; align-items: center; gap: 14px; margin-bottom: 4px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }

    .frm { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 12px 16px; margin-top: 8px }
    .frm label { display: block; font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #0E1F3D }
    .frm input[type=text], .frm select { width: 100%; height: 42px; padding: 0 12px; border: 1px solid var(--mc-line, #D5DDE8); border-radius: 12px; font: inherit; font-size: 15px; background: #fff; color: #0E1F3D; outline: none }
    .frm input:focus, .frm select:focus { border-color: var(--mc-primary, #1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .actions { display: flex; gap: 10px; margin-top: 14px }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .btn.sec { background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73) }
    .msg { margin-top: 14px; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700 }
    .msg.err { background: #FDECEA; color: #A3261C }
    .msg.ok { background: #E3F3EA; color: #0F5A3A }

    .lst { display: flex; flex-direction: column; gap: 8px }
    .row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: 14px; background: var(--mc-page, #F2F5F9) }
    .row .who { flex: 1; min-width: 0 }
    .row .who .nm { font-weight: 800; color: #0E1F3D }
    .row .who .em { font-size: 12.5px; color: #5B6B86 }
    .tag { font-size: 11.5px; font-weight: 800; padding: 3px 9px; border-radius: 999px; background: #E3EBF7; color: #143A73; white-space: nowrap }
    .row .acts { display: flex; gap: 10px }
    .row .acts a { font-weight: 800; font-size: 13px; color: var(--mc-primary, #1B4F9C); text-decoration: none; cursor: pointer }
    .row .acts a.danger { color: #A3261C }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">

    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM2 20c0-3 3-5 6-5s6 2 6 5M17 11a3 3 0 1 0 0-6M22 20c0-2-2-4-4-4.5"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>

        <h2 style="font-size:16px;font-weight:800;margin:14px 0 2px"><asp:Literal ID="litFormTitre" runat="server" /></h2>
        <div class="frm">
            <div>
                <label><asp:Literal ID="litLblNom" runat="server" /></label>
                <asp:TextBox ID="txtNom" runat="server" />
            </div>
            <div>
                <label><asp:Literal ID="litLblResp" runat="server" /></label>
                <asp:DropDownList ID="ddlResp" runat="server" />
            </div>
        </div>
        <div class="actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn" />
            <asp:Button ID="btnCancel" runat="server" CssClass="btn sec" Visible="false" CausesValidation="false" />
        </div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>

    <section class="boite">
        <h2 style="font-size:16px;font-weight:800;margin:0 0 12px"><asp:Literal ID="litListeTitre" runat="server" /></h2>
        <div class="lst">
            <asp:Repeater ID="rptEquipes" runat="server">
                <ItemTemplate>
                    <div class="row">
                        <div class="who">
                            <div class="nm"><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></div>
                            <div class="em"><%# RespText(Eval("ResponsableNom")) %> · <%# NbText(Eval("NbMembres")) %></div>
                        </div>
                        <div class="acts">
                            <asp:LinkButton runat="server" CommandName="edit" CommandArgument='<%# Eval("Id") %>' Text='<%# LblModifier %>' />
                            <asp:LinkButton runat="server" CssClass="danger" CommandName="del" CommandArgument='<%# Eval("Id") %>' Text='<%# LblSupprimer %>' OnClientClick='<%# ConfirmJs() %>' />
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
            <asp:Literal ID="litVide" runat="server" />
        </div>
    </section>

</div>
</asp:Content>
