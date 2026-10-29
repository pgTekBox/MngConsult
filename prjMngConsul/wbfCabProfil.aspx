<%@ Page Title="Profil du cabinet" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabProfil.aspx.vb" Inherits="MngConsul.wbfCabProfil" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Profil du cabinet — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 900px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .cab-head { display: flex; align-items: center; gap: 14px; margin-bottom: 4px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px; background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C); display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }

    .sec-t { font-size: 15px; font-weight: 800; color: #0E1F3D; margin: 16px 0 10px }
    .frm { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 12px 16px }
    .frm .full { grid-column: 1 / -1 }
    .frm label { display: block; font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #0E1F3D }
    .frm input[type=text], .frm textarea { width: 100%; padding: 10px 12px; border: 1px solid var(--mc-line, #D5DDE8); border-radius: 12px; font: inherit; font-size: 15px; background: #fff; color: #0E1F3D; outline: none; box-sizing: border-box }
    .frm input[type=text] { height: 42px }
    .frm textarea { min-height: 80px; resize: vertical }
    .frm input:focus, .frm textarea:focus { border-color: var(--mc-primary, #1B4F9C); box-shadow: 0 0 0 4px rgba(27,79,156,.14) }
    .cbl label { display: inline-flex; align-items: center; gap: 6px; margin-right: 16px; font-weight: 700; font-size: 14px; color: #0E1F3D }

    .toggle-row { display: flex; align-items: flex-start; gap: 10px; padding: 12px 14px; border-radius: 14px; background: var(--mc-page, #F2F5F9); margin-top: 10px }
    .toggle-row .tx { flex: 1 }
    .toggle-row .tx .t { font-weight: 800; color: #0E1F3D }
    .toggle-row .tx .s { font-size: 13px; color: #44536E; margin-top: 2px }

    .actions { display: flex; gap: 10px; margin-top: 16px }
    .btn { height: 46px; padding: 0 20px; border: 0; border-radius: 999px; background: var(--mc-primary, #1B4F9C); color: #fff; font: inherit; font-weight: 800; font-size: 15px; cursor: pointer }
    .btn:hover { background: var(--mc-primary-dark, #143A73) }
    .msg { margin-top: 14px; padding: 12px 14px; border-radius: 14px; font-size: 13.5px; font-weight: 700 }
    .msg.ok { background: #E3F3EA; color: #0F5A3A }
    .msg.err { background: #FDECEA; color: #A3261C }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21V5l8-3 8 3v16M9 21v-5h6v5M8 9h1M15 9h1M8 13h1M15 13h1"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>

        <div class="sec-t"><asp:Literal ID="litSecIdent" runat="server" /></div>
        <div class="frm">
            <div><label><asp:Literal ID="litLblNom" runat="server" /></label><asp:TextBox ID="txtNom" runat="server" /></div>
            <div><label><asp:Literal ID="litLblResp" runat="server" /></label><asp:TextBox ID="txtResp" runat="server" /></div>
            <div class="full"><label><asp:Literal ID="litLblDesc" runat="server" /></label><asp:TextBox ID="txtDesc" runat="server" TextMode="MultiLine" /></div>
            <div><label><asp:Literal ID="litLblVille" runat="server" /></label><asp:TextBox ID="txtVille" runat="server" /></div>
            <div><label><asp:Literal ID="litLblProv" runat="server" /></label><asp:TextBox ID="txtProv" runat="server" /></div>
            <div><label><asp:Literal ID="litLblMail" runat="server" /></label><asp:TextBox ID="txtMail" runat="server" /></div>
            <div><label><asp:Literal ID="litLblTel" runat="server" /></label><asp:TextBox ID="txtTel" runat="server" /></div>
            <div class="full"><label><asp:Literal ID="litLblSite" runat="server" /></label><asp:TextBox ID="txtSite" runat="server" /></div>
        </div>

        <div class="sec-t"><asp:Literal ID="litSecServ" runat="server" /></div>
        <div class="frm">
            <div><label><asp:Literal ID="litLblLangues" runat="server" /></label>
                <asp:CheckBoxList ID="cblLangues" runat="server" RepeatDirection="Horizontal" CssClass="cbl" /></div>
            <div><label><asp:Literal ID="litLblSpec" runat="server" /></label>
                <asp:CheckBoxList ID="cblSpec" runat="server" RepeatDirection="Horizontal" CssClass="cbl" /></div>
        </div>

        <div class="sec-t"><asp:Literal ID="litSecVis" runat="server" /></div>
        <div class="toggle-row">
            <asp:CheckBox ID="cbAccepte" runat="server" />
            <div class="tx"><div class="t"><asp:Literal ID="litAccepteT" runat="server" /></div><div class="s"><asp:Literal ID="litAccepteS" runat="server" /></div></div>
        </div>
        <div class="toggle-row">
            <asp:CheckBox ID="cbPublique" runat="server" />
            <div class="tx"><div class="t"><asp:Literal ID="litPubliqueT" runat="server" /></div><div class="s"><asp:Literal ID="litPubliqueS" runat="server" /></div></div>
        </div>

        <div class="actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn" />
        </div>
        <asp:Literal ID="litMsg" runat="server" />
    </section>
</div>
</asp:Content>
