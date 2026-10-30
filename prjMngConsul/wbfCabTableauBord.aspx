<%@ Page Title="Tableau de bord du cabinet" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabTableauBord.aspx.vb" Inherits="MngConsul.wbfCabTableauBord" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Portail comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cab-page { padding: 0; width: 100% }
    .boite { background: #fff; border-radius: 24px; padding: 20px 24px; margin-bottom: 16px }

    .cab-head { display: flex; align-items: center; gap: 14px }
    .cab-head .ico { width: 46px; height: 46px; border-radius: 50%; flex: 0 0 46px;
        background: var(--mc-soft, #E8EDF5); color: var(--mc-primary, #1B4F9C);
        display: flex; align-items: center; justify-content: center }
    .cab-head > div.txt { flex: 1 }
    .cab-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0E1F3D }
    .cab-head .sub { font-size: 13px; color: #44536E; margin-top: 2px }
    .cab-echelle { padding: 6px 14px; border-radius: 999px; background: #0E1F3D; color: #E7C377;
        font-weight: 800; font-size: 13px; white-space: nowrap }

    .kpis { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 16px; margin-bottom: 16px }
    @media (max-width: 760px) { .kpis { grid-template-columns: repeat(2, 1fr) } }
    .kpi { background: #fff; border-radius: 20px; padding: 16px 18px }
    .kpi .n { font-size: 30px; font-weight: 800; color: #0E1F3D; line-height: 1 }
    .kpi .l { font-size: 13px; color: #44536E; margin-top: 6px }

    .doss-titre { font-size: 17px; font-weight: 800; color: #0E1F3D; margin: 0 0 12px }
    .doss { display: flex; flex-direction: column; gap: 8px }
    .doss-row { display: flex; align-items: center; gap: 12px; padding: 10px 12px; border-radius: 14px; background: var(--mc-page, #F2F5F9); text-decoration: none; color: #0E1F3D }
    .doss-row:hover { background: var(--mc-soft2, #E3EBF7) }
    .doss-av { width: 38px; height: 38px; border-radius: 50%; flex: 0 0 38px; background: var(--mc-soft2, #E3EBF7); color: var(--mc-primary-dark, #143A73);
        font-weight: 800; font-size: 14px; display: flex; align-items: center; justify-content: center }
    .doss-row .nom { flex: 1; font-weight: 700 }
    .doss-row .code { font-size: 12px; color: #5B6B86; font-weight: 700 }
    .doss-vide { color: #44536E; font-size: 14px }
    .doss-plus { display: inline-block; margin-top: 12px; font-weight: 800; color: var(--mc-primary, #1B4F9C); text-decoration: none }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cab-page">

    <section class="boite">
        <div class="cab-head">
            <div class="ico"><svg aria-hidden="true" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 21V5l8-3 8 3v16M9 21v-5h6v5"/></svg></div>
            <div class="txt">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <div class="sub"><asp:Literal ID="litSous" runat="server" /></div>
            </div>
            <asp:Literal ID="litEchelle" runat="server" />
        </div>
    </section>

    <div class="kpis"><asp:Literal ID="litKpis" runat="server" /></div>

    <section class="boite">
        <h2 class="doss-titre"><asp:Literal ID="litDossiersTitre" runat="server" /></h2>
        <div class="doss"><asp:Literal ID="litDossiers" runat="server" /></div>
        <asp:Literal ID="litPlus" runat="server" />
    </section>

</div>
</asp:Content>
