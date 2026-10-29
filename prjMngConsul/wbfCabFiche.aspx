<%@ Page Title="Fiche client" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabFiche.aspx.vb" Inherits="MngConsul.wbfCabFiche" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Fiche client — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; max-width: 1000px }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }
    .fiche-head { display: flex; align-items: center; gap: 14px }
    .fiche-head .av { width: 52px; height: 52px; border-radius: 50%; flex: 0 0 52px; background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73); font-weight: 800; font-size: 18px; display: flex; align-items: center; justify-content: center }
    .fiche-head .tx { flex: 1; min-width: 0 }
    .fiche-head h1 { font-size: 22px; font-weight: 800; margin: 0; color: #0E1F3D }
    .fiche-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .assign { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px }
    .tag { font-size: 12px; font-weight: 800; padding: 4px 11px; border-radius: 999px; white-space: nowrap }
    .tag.m { background: #E3EBF7; color: #143A73 } .tag.t { background: #EDE9FE; color: #5B3FA6 } .tag.none { background: #FBF1DC; color: #7A5200 }

    .onglets { display: flex; flex-wrap: wrap; gap: 6px; margin: 4px 0 0 }
    .onglets a { padding: 8px 14px; border-radius: 999px; text-decoration: none; font-weight: 800; font-size: 13.5px; color: #44536E; background: transparent }
    .onglets a:hover { background: var(--mc-page, #F2F5F9) }
    .onglets a.on { background: var(--mc-primary, #1B4F9C); color: #fff }

    .qfq { display: grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap: 16px; margin-top: 4px }
    @media (max-width: 680px) { .qfq { grid-template-columns: 1fr } }
    .qfq .k { border-radius: 18px; padding: 16px 18px }
    .qfq .k .n { font-size: 28px; font-weight: 800; line-height: 1 } .qfq .k .l { font-size: 13px; font-weight: 700; margin-top: 6px }
    .qfq .cli { background: #E3F3EA } .qfq .cli .n, .qfq .cli .l { color: #0F5A3A }
    .qfq .cab { background: #FCE9D9 } .qfq .cab .n, .qfq .cab .l { color: #8A4100 }
    .qfq .par { background: #E3EBF7 } .qfq .par .n, .qfq .par .l { color: #143A73 }
    .secT { font-size: 15px; font-weight: 800; color: #0E1F3D; margin: 0 0 12px }

    .acts { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 4px }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 6px }
    .btn.p { background: var(--mc-primary, #1B4F9C); color: #fff } .btn.p:hover { background: var(--mc-primary-dark, #143A73) }
    .btn.s { background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73) } .btn.s:hover { background: var(--mc-soft, #E8EDF5) }

    /* Tâches */
    .tfrm { display: grid; grid-template-columns: 2fr 1fr 1fr auto; gap: 10px; align-items: end; margin-bottom: 14px }
    @media (max-width: 760px) { .tfrm { grid-template-columns: 1fr 1fr } }
    .tfrm label { display: block; font-weight: 700; font-size: 12px; color: #44536E; margin-bottom: 4px }
    .tfrm input[type=text], .tfrm select { width: 100%; height: 40px; padding: 0 10px; border: 1px solid var(--mc-line,#D5DDE8); border-radius: 10px; font: inherit; font-size: 14px; background: #fff; outline: none; box-sizing: border-box }
    .trow { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: 14px; background: var(--mc-page,#F2F5F9); margin-bottom: 8px }
    .trow .ti { flex: 1; min-width: 0 }
    .trow .ti .nm { font-weight: 800; color: #0E1F3D }
    .trow .ti .me { font-size: 12.5px; color: #5B6B86; margin-top: 2px }
    .sbadge { font-size: 11.5px; font-weight: 800; padding: 3px 9px; border-radius: 999px; white-space: nowrap }
    .s-afaire { background: #E8EDF5; color: #143A73 } .s-encours { background: #FBF1DC; color: #7A5200 } .s-fait { background: #E3F3EA; color: #0F5A3A } .s-bloque { background: #FDECEA; color: #A3261C }
    .trow .sacts a { font-size: 12px; font-weight: 800; color: var(--mc-primary,#1B4F9C); text-decoration: none; margin-left: 10px; cursor: pointer }

    /* Journal */
    .jr { display: flex; flex-direction: column; gap: 2px }
    .jrow { display: flex; gap: 12px; padding: 8px 0; border-bottom: 1px solid #F0F3F8 }
    .jrow .jd { width: 150px; flex: 0 0 150px; font-size: 12px; color: #5B6B86; font-weight: 700 }
    .jrow .jt { flex: 1; font-size: 14px; color: #0E1F3D }
    .jrow .jt .jp { color: #5B6B86; font-size: 12px }
    .vide { color: #44536E; font-size: 14px }
    .avenir { color: #5B6B86; font-size: 14px; font-weight: 700 }
    .msg { margin-top: 12px; padding: 10px 14px; border-radius: 12px; font-size: 13.5px; font-weight: 700; background: #E3F3EA; color: #0F5A3A }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">
    <section class="boite">
        <div class="fiche-head">
            <span class="av"><asp:Literal ID="litInit" runat="server" /></span>
            <div class="tx">
                <h1><asp:Literal ID="litNom" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
        </div>
        <div class="assign"><asp:Literal ID="litAssign" runat="server" /></div>
        <div class="onglets"><asp:Literal ID="litOnglets" runat="server" /></div>
    </section>

    <section class="boite">
        <asp:Literal ID="litMsg" runat="server" />

        <%-- Onglet VUE --%>
        <asp:Panel ID="pnlVue" runat="server" Visible="false">
            <h2 class="secT"><asp:Literal ID="litQfqT" runat="server" /></h2>
            <div class="qfq"><asp:Literal ID="litQfq" runat="server" /></div>
            <div class="acts" style="margin-top:16px"><asp:Literal ID="litActions" runat="server" /></div>
        </asp:Panel>

        <%-- Onglet TÂCHES --%>
        <asp:Panel ID="pnlTaches" runat="server" Visible="false">
            <div class="tfrm">
                <div><label><asp:Literal ID="litLblTitre" runat="server" /></label><asp:TextBox ID="txtTitre" runat="server" /></div>
                <div><label><asp:Literal ID="litLblAssigne" runat="server" /></label><asp:DropDownList ID="ddlAssigne" runat="server" /></div>
                <div><label><asp:Literal ID="litLblEcheance" runat="server" /></label><asp:TextBox ID="txtEcheance" runat="server" TextMode="Date" /></div>
                <div><asp:Button ID="btnAddTache" runat="server" CssClass="btn p" /></div>
            </div>
            <asp:Repeater ID="rptTaches" runat="server" OnItemCommand="rptTaches_ItemCommand">
                <ItemTemplate>
                    <div class="trow">
                        <div class="ti">
                            <div class="nm"><%# Server.HtmlEncode(Convert.ToString(Eval("Titre"))) %></div>
                            <div class="me"><%# MetaTache(Eval("AssignedNom"), Eval("Echeance")) %></div>
                        </div>
                        <span class="sbadge s-<%# Convert.ToString(Eval("Statut")) %>"><%# StatutLabel(Eval("Statut")) %></span>
                        <div class="sacts">
                            <asp:LinkButton runat="server" CommandName="st" CommandArgument='<%# Eval("Id") & "|encours" %>' Text='<%# LblEnCours %>' />
                            <asp:LinkButton runat="server" CommandName="st" CommandArgument='<%# Eval("Id") & "|fait" %>' Text='<%# LblFait %>' />
                            <asp:LinkButton runat="server" CommandName="st" CommandArgument='<%# Eval("Id") & "|bloque" %>' Text='<%# LblBloque %>' />
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
            <asp:Literal ID="litTachesVide" runat="server" />
        </asp:Panel>

        <%-- Onglet JOURNAL --%>
        <asp:Panel ID="pnlJournal" runat="server" Visible="false">
            <div class="jr"><asp:Literal ID="litJournal" runat="server" /></div>
        </asp:Panel>

        <%-- Onglets à venir (Parts D/F) --%>
        <asp:Panel ID="pnlAvenir" runat="server" Visible="false">
            <div class="avenir"><asp:Literal ID="litAvenir" runat="server" /></div>
        </asp:Panel>
    </section>
</div>
</asp:Content>
