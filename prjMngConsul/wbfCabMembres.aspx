<%@ Page Title="Membres et sécurité" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabMembres.aspx.vb" Inherits="MngConsul.wbfCabMembres" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Membres et sécurité — Portail comptable
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
    .frm .full { grid-column: 1 / -1 }
    .frm label { display: block; font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #0E1F3D }
    .frm input[type=text], .frm select { width: 100%; height: 42px; padding: 0 12px; border: 1px solid var(--mc-line, #D5DDE8); border-radius: 12px; font: inherit; font-size: 15px; background: #fff; color: #0E1F3D; outline: none }
    .frm input:focus, .frm select:focus { border-color: var(--mc-primary, #1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .chkline { display: flex; align-items: center; gap: 8px; margin-top: 6px; font-weight: 700; font-size: 14px }
    .actions { display: flex; gap: 10px; margin-top: 14px }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .btn.sec { background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73) }

    .msg { margin-top: 14px; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700 }
    .msg.err { background: #FDECEA; color: #A3261C }
    .msg.ok { background: #E3F3EA; color: #0F5A3A }
    .invlink { display: flex; gap: 8px; align-items: center; margin-top: 8px }
    .invlink input { flex: 1; height: 38px; padding: 0 10px; border: 1px solid var(--mc-line, #D5DDE8); border-radius: 10px; font: inherit; font-size: 13px; color: #0E1F3D; background: #F7F9FC }

    .lst { display: flex; flex-direction: column; gap: 8px }
    .row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: 14px; background: var(--mc-page, #F2F5F9) }
    .row .av { width: 40px; height: 40px; border-radius: 50%; flex: 0 0 40px; background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73); font-weight: 800; display: flex; align-items: center; justify-content: center }
    .row .who { flex: 1; min-width: 0 }
    .row .who .nm { font-weight: 800; color: #0E1F3D }
    .row .who .em { font-size: 12.5px; color: #5B6B86 }
    .tag { font-size: 11.5px; font-weight: 800; padding: 3px 9px; border-radius: 999px; white-space: nowrap }
    .tag.role { background: #E3EBF7; color: #143A73 }
    .tag.team { background: #EDE9FE; color: #5B3FA6 }
    .tag.pending { background: #FBF1DC; color: #7A5200 }
    .tag.off { background: #FDECEA; color: #A3261C }
    .row .acts { display: flex; gap: 10px; align-items: center }
    .row .acts a { font-weight: 800; font-size: 13px; color: var(--mc-primary, #1B4F9C); text-decoration: none; cursor: pointer }
    .row .acts a.danger { color: #A3261C }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">

    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>

        <asp:Panel ID="pnlForm" runat="server">
            <h2 style="font-size:16px;font-weight:800;margin:14px 0 2px"><asp:Literal ID="litFormTitre" runat="server" /></h2>
            <div class="frm">
                <div>
                    <label><asp:Literal ID="litLblFirst" runat="server" /></label>
                    <asp:TextBox ID="txtFirst" runat="server" />
                </div>
                <div>
                    <label><asp:Literal ID="litLblLast" runat="server" /></label>
                    <asp:TextBox ID="txtLast" runat="server" />
                </div>
                <div>
                    <label><asp:Literal ID="litLblEmail" runat="server" /></label>
                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" />
                </div>
                <div>
                    <label><asp:Literal ID="litLblRole" runat="server" /></label>
                    <asp:DropDownList ID="ddlRole" runat="server" />
                </div>
                <div>
                    <label><asp:Literal ID="litLblEquipe" runat="server" /></label>
                    <asp:DropDownList ID="ddlEquipe" runat="server" />
                </div>
                <asp:Panel ID="pnlActive" runat="server" CssClass="chkline" Visible="false">
                    <asp:CheckBox ID="cbActive" runat="server" />
                    <asp:Literal ID="litLblActive" runat="server" />
                </asp:Panel>
            </div>
            <div class="actions">
                <asp:Button ID="btnSave" runat="server" CssClass="btn" />
                <asp:Button ID="btnCancel" runat="server" CssClass="btn sec" Visible="false" CausesValidation="false" />
            </div>
        </asp:Panel>

        <asp:Literal ID="litMsg" runat="server" />
    </section>

    <section class="boite">
        <h2 style="font-size:16px;font-weight:800;margin:0 0 12px"><asp:Literal ID="litListeTitre" runat="server" /></h2>
        <div class="lst">
            <asp:Repeater ID="rptMembres" runat="server">
                <ItemTemplate>
                    <div class="row">
                        <span class="av"><%# Initiales(Eval("FirstName"), Eval("LastName"), Eval("Email")) %></span>
                        <div class="who">
                            <div class="nm"><%# NomAffiche(Eval("FirstName"), Eval("LastName"), Eval("Email")) %><%# MoiTag(Eval("IsMe")) %></div>
                            <div class="em"><%# Server.HtmlEncode(Convert.ToString(Eval("Email"))) %></div>
                        </div>
                        <span class="tag role"><%# RoleLabel(Eval("Role")) %></span>
                        <%# TeamTag(Eval("EquipeNom")) %>
                        <%# StatutTag(Eval("Pending"), Eval("IsActive")) %>
                        <div class="acts">
                            <asp:LinkButton runat="server" CommandName="edit" CommandArgument='<%# Eval("MembreId") %>' Text='<%# LblModifier %>' />
                            <asp:LinkButton runat="server" CommandName="resend" CommandArgument='<%# Eval("MembreId") %>' Text='<%# LblRenvoyer %>' Visible='<%# Convert.ToBoolean(Eval("Pending")) %>' />
                            <asp:LinkButton runat="server" CssClass="danger" CommandName="toggle" CommandArgument='<%# Eval("MembreId") %>'
                                Visible='<%# Not Convert.ToBoolean(Eval("IsMe")) %>'
                                Text='<%# If(Convert.ToBoolean(Eval("IsActive")), LblDesactiver, LblActiver) %>'
                                OnClientClick='<%# ConfirmJs() %>' />
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
            <asp:Literal ID="litVide" runat="server" />
        </div>
    </section>

</div>
</asp:Content>
