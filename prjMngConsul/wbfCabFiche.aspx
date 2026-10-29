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
    .tag.m { background: #E3EBF7; color: #143A73 }
    .tag.t { background: #EDE9FE; color: #5B3FA6 }
    .tag.none { background: #FBF1DC; color: #7A5200 }

    .qfq { display: grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap: 16px; margin-top: 4px }
    @media (max-width: 680px) { .qfq { grid-template-columns: 1fr } }
    .qfq .k { border-radius: 18px; padding: 16px 18px }
    .qfq .k .n { font-size: 28px; font-weight: 800; line-height: 1 }
    .qfq .k .l { font-size: 13px; font-weight: 700; margin-top: 6px }
    .qfq .cli { background: #E3F3EA } .qfq .cli .n, .qfq .cli .l { color: #0F5A3A }
    .qfq .cab { background: #FCE9D9 } .qfq .cab .n, .qfq .cab .l { color: #8A4100 }
    .qfq .par { background: #E3EBF7 } .qfq .par .n, .qfq .par .l { color: #143A73 }
    .secT { font-size: 15px; font-weight: 800; color: #0E1F3D; margin: 0 0 12px }

    .acts { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 4px }
    .btn { height: 44px; padding: 0 18px; border: 0; border-radius: 999px; font: inherit; font-weight: 800; font-size: 14px; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 6px }
    .btn.p { background: var(--mc-primary, #1B4F9C); color: #fff } .btn.p:hover { background: var(--mc-primary-dark, #143A73) }
    .btn.s { background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73) } .btn.s:hover { background: var(--mc-soft, #E8EDF5) }
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
        <div class="acts"><asp:Literal ID="litActions" runat="server" /></div>
    </section>

    <section class="boite">
        <h2 class="secT"><asp:Literal ID="litQfqT" runat="server" /></h2>
        <div class="qfq"><asp:Literal ID="litQfq" runat="server" /></div>
    </section>
</div>
</asp:Content>
