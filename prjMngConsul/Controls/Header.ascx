<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="Header.ascx.vb" Inherits="MngConsul.Controls.Header" %>
<%@ Register Src="~/Controls/HeaderUser.ascx" TagPrefix="uc1" TagName="HeaderUser" %>
<%-- L'en-tête, au style « Doux bleu marine » retenu pour 60secondes : fond blanc,
     filet #D5DDE8, le visage « Le 60 » et le nom en Nunito, les portails en
     pastilles (Entreprise ; le bouton Cabinets certifiés, qui ouvre l'annuaire en
     fenêtre ; Paie et Paiements quand Web.config en donne l'adresse, Portail.*.Url), puis à droite les pastilles d'état,
     les langues en ronds, la compagnie, l'aide, la cloche et l'utilisateur. --%>
<header class="app-header">
    <div class="app-header-inner">
        <!-- Left -->
        <div class="header-left">
            <%-- ☰ : affiche ou masque le menu de gauche (la logique est dans LeftMenu.ascx) --%>
            <button type="button" class="burger60" data-menu-burger
                data-lbl-ouvrir="<%= MenuLbl(False) %>" data-lbl-fermer="<%= MenuLbl(True) %>"
                aria-label="<%= MenuLbl(True) %>" title="<%= MenuLbl(True) %>" aria-controls="appSidebar" aria-expanded="true">
                <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round">
                    <path class="i-b" d="M4 7h16M4 12h16M4 17h16" /><path class="i-x" d="M6 6l12 12M18 6L6 18" />
                </svg>
            </button>
            <a class="logo" href="~/Default.aspx" runat="server" id="lnkLogo">
                <svg class="logo-visage" aria-hidden="true" width="46" height="46" viewBox="0 0 256 256">
                    <defs><radialGradient id="hdrAv" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#C8F7F1" /><stop offset="1" stop-color="#3DDCCB" /></radialGradient></defs>
                    <circle cx="128" cy="128" r="104" fill="url(#hdrAv)" />
                    <ellipse cx="96" cy="62" rx="44" ry="20" fill="#FFFFFF" opacity=".45" transform="rotate(-20 96 62)" />
                    <circle cx="128" cy="128" r="102" fill="none" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="3" />
                    <circle cx="96" cy="120" r="16" fill="none" stroke="#06524C" stroke-width="12" />
                    <path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#06524C" stroke-width="12" stroke-linecap="round" />
                    <ellipse cx="160" cy="110" rx="15" ry="25" fill="none" stroke="#06524C" stroke-width="12" />
                    <path d="M99 166 q29 16 58 0" fill="none" stroke="#06524C" stroke-width="10" stroke-linecap="round" />
                </svg>
                <span class="logo-text"><asp:Literal runat="server" ID="litAppName" Text="60secondes" /></span>
            </a>
            <nav class="portails" aria-label="Portails">
                <asp:Literal runat="server" ID="litPortails" />
            </nav>
        </div>
        <!-- Right -->
        <div class="header-right">
            <asp:Literal runat="server" ID="litStripeStatus" />
            <asp:Literal runat="server" ID="litPlaidStatus" />
            <uc1:HeaderUser runat="server" id="HeaderUser" />
        </div>
    </div>
</header>
<style>
.app-header{
    background:#ffffff;
    border-bottom:1px solid var(--mc-line,#D5DDE8);
    position:sticky;
    top:0;
    z-index:20;
    font-family:var(--mc-font-titre, Nunito, system-ui, sans-serif);
    color:var(--mc-navy,#0E1F3D);
}
.app-header-inner{
    min-height:70px;
    padding:10px 24px;
    display:flex;
    align-items:center;
    justify-content:space-between;
    gap:14px;
    flex-wrap:wrap;
}
/* LEFT */
.header-left{
    display:flex;
    align-items:center;
    gap:14px;
    min-width:0;
}
.logo{
    display:flex;
    align-items:center;
    gap:10px;
    text-decoration:none;
    color:var(--mc-navy,#0E1F3D);
}
.logo-visage{ flex-shrink:0; display:block; }
.logo-text{
    font-weight:800;
    font-size:23px;
    letter-spacing:-.01em;
    white-space:nowrap;
}
/* Les portails : une barre arrondie, la pastille blanche pour celui où l'on est. */
.portails{
    display:flex;
    gap:4px;
    padding:4px;
    background:var(--mc-soft,#E8EDF5);
    border-radius:999px;
    margin-left:6px;
}
.portails:empty{ display:none; }
.portails a, .portails span, .portails button{
    padding:9px 16px;
    border-radius:999px;
    color:var(--mc-navy,#0E1F3D);
    text-decoration:none;
    font-weight:700;
    font-size:14px;
    white-space:nowrap;
    line-height:1.2;
}
.portails a:hover, .portails button:hover{ background:rgba(255,255,255,.6); }
/* Cabinets certifiés : un bouton qui ouvre l'annuaire en fenêtre (ouvrirFenetreApp) */
.portails button{ border:0; background:transparent; cursor:pointer; font-family:inherit; }
.portails .ici{
    background:#ffffff;
    box-shadow:0 1px 2px rgba(14,31,61,.12);
}
/* RIGHT */
.header-right{
    display:flex;
    align-items:center;
    gap:10px;
}
/* Pastilles d'état (Plaid, Stripe) : même gabarit que celles de HeaderUser — rondes, 42 px */
.plaid-pill, .stripe-hdr-pill{
    display:inline-flex;
    align-items:center;
    gap:7px;
    height:42px;
    box-sizing:border-box;
    padding:0 14px;
    border-radius:999px;
    font-size:12px;
    font-weight:800;
    white-space:nowrap;
    cursor:default;
}
.plaid-pill{ max-width:220px; overflow:hidden; }
.plaid-pill.on{ background:#ecfdf5; border:1px solid #a7f3d0; color:#047857; }
.plaid-pill.off{ background:var(--mc-soft,#E8EDF5); border:1px solid transparent; color:var(--mc-muted2,#44536E); }
.plaid-pill .dot, .stripe-hdr-pill .dot{ width:9px; height:9px; border-radius:50%; flex:0 0 9px; }
.plaid-pill.on .dot{ background:#10b981; box-shadow:0 0 0 3px rgba(16,185,129,.2); }
.plaid-pill.off .dot{ background:#94a3b8; }
.plaid-pill .lbl{ overflow:hidden; text-overflow:ellipsis; }
.stripe-hdr-pill.on{ background:#eef2ff; border:1px solid #c7d2fe; color:#4338ca; }
.stripe-hdr-pill.off{ background:var(--mc-soft,#E8EDF5); border:1px solid transparent; color:var(--mc-muted2,#44536E); }
.stripe-hdr-pill.on .dot{ background:#635bff; box-shadow:0 0 0 3px rgba(99,91,255,.2); }
.stripe-hdr-pill.off .dot{ background:#94a3b8; }
.stripe-hdr-pill .num{ font-weight:900; }
@media(max-width:1280px){
    .portails a, .portails span, .portails button{ padding:8px 12px; font-size:13px; }
    .plaid-pill{ max-width:150px; }
    .stripe-hdr-pill .lbl{ display:none; }
}
@media(max-width:1024px){
    .portails{ display:none; }
    .plaid-pill, .stripe-hdr-pill{ display:none; }
}
</style>
