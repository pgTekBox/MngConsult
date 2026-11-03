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
                    <circle cx="128" cy="128" r="104" fill="#5E35C9" />
                    <circle cx="96" cy="120" r="16" fill="none" stroke="#FFFFFF" stroke-width="12" />
                    <path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round" />
                    <ellipse cx="162" cy="106" rx="15" ry="25" fill="none" stroke="#FFFFFF" stroke-width="12" transform="rotate(12 160 110)" />
                    <path d="M148 68 q16 -9 30 0" fill="none" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round" />
                    <path d="M108 170 q20 6 40 -6" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" />
                </svg>
                <span class="logo-text"><asp:Literal runat="server" ID="litAppName" Text="60secondes" /></span>
            </a>
            <nav class="portails" aria-label="Portails">
                <asp:Literal runat="server" ID="litPortails" />
            </nav>
            <%-- Contexte du client : profil (TA / Cie + nb d'employés) · métier, et l'essai --%>
            <asp:Literal runat="server" ID="litProfilMetier" />
        </div>
        <!-- Right -->
        <div class="header-right">
            <asp:Literal runat="server" ID="litFournisseurs" />
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
/* Contexte du client, à côté du logo : profil (TA / Cie) · métier + état de l'essai */
.hdr-ctx{
    display:flex;
    flex-direction:column;
    justify-content:center;
    line-height:1.15;
    min-width:0;
    padding-left:14px;
    border-left:1px solid var(--mc-line,#D5DDE8);
}
.hdr-ctx:empty{ display:none; }
.hdr-pm{ display:flex; flex-wrap:wrap; align-items:center; gap:2px 8px; }
.hdr-pm .hdr-prof{ display:inline-flex; align-items:center; gap:6px; font-size:16px; font-weight:800; white-space:nowrap; }
.hdr-pm .hdr-met{ font-size:16px; font-weight:800; white-space:nowrap; }
.hdr-pm .hdr-sep{ color:#AEBBCD; font-size:16px; font-weight:700; }
.hdr-nemp{
    width:22px; height:22px; box-sizing:border-box; border-radius:50%;
    background:var(--mc-navy,#0E1F3D); color:#FFFFFF; font-size:12px; font-weight:700;
    display:inline-flex; align-items:center; justify-content:center;
}
.hdr-essai{ font-size:13px; color:var(--mc-muted2,#44536E); white-space:nowrap; }
.hdr-essai.urg{ color:#A3261C; font-weight:800; }

/* « Fournisseurs connectés » : un bouton (nombre en vert) qui ouvre la liste des branchements */
.fourn-wrap{ position:relative; }
.fourn-btn{
    display:inline-flex; align-items:center; gap:6px;
    min-height:42px; box-sizing:border-box; padding:0 12px 0 7px;
    border:1px solid var(--mc-line,#D5DDE8); border-radius:999px;
    background:#FFFFFF; color:var(--mc-muted2,#44536E); cursor:pointer; font-family:inherit;
}
.fourn-btn:hover{ background:#F7F9FC; }
.fourn-btn .fourn-n{
    min-width:26px; height:26px; box-sizing:border-box; padding:0 6px; border-radius:999px;
    background:#43B47A; color:#FFFFFF; font-size:14px; font-weight:800;
    display:flex; align-items:center; justify-content:center;
}
.fourn-btn .fourn-lbl{ font-size:14px; font-weight:800; color:var(--mc-navy,#0E1F3D); white-space:nowrap; }
.fourn-btn .fourn-chv{ transition:transform .15s; }
.fourn-btn[aria-expanded="true"] .fourn-chv{ transform:rotate(180deg); }
.fourn-liste{
    position:absolute; left:0; top:52px; z-index:30;
    width:300px; max-width:calc(100vw - 32px); box-sizing:border-box;
    padding:14px; border-radius:18px; background:#FFFFFF;
    box-shadow:0 16px 40px rgba(14,31,61,.25); border:1px solid var(--mc-line,#D5DDE8);
    display:flex; flex-direction:column; gap:2px;
}
.fourn-liste[hidden]{ display:none; }
.fourn-liste > b{ font-size:15px; margin-bottom:4px; }
.fourn-it{ display:flex; align-items:center; gap:10px; padding:8px 0; border-top:1px solid #E3E9F1; }
.fourn-it .fourn-nom{ font-weight:800; font-size:14px; }
.fourn-it .fourn-det{ flex:1 1 auto; min-width:0; font-size:13px; color:var(--mc-muted2,#44536E); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.fourn-it .fourn-dot{ width:10px; height:10px; flex:0 0 10px; border-radius:50%; }
.fourn-it.on .fourn-dot{ background:#43B47A; }
.fourn-it.off .fourn-dot{ background:#C3CDDC; }
@media(max-width:1280px){
    .portails a, .portails span, .portails button{ padding:8px 12px; font-size:13px; }
    .hdr-pm .hdr-prof, .hdr-pm .hdr-met, .hdr-pm .hdr-sep{ font-size:14px; }
    .fourn-btn .fourn-lbl{ display:none; }
}
@media(max-width:1024px){
    .portails{ display:none; }
    .hdr-ctx{ display:none; }
}
</style>
<script>
(function(){
    // « Fournisseurs connectés » : ouvre/ferme la liste ; se ferme au clic dehors ou Échap.
    function fermerTout(sauf){
        document.querySelectorAll('[data-fourn-btn][aria-expanded="true"]').forEach(function(b){
            if(b===sauf) return;
            b.setAttribute('aria-expanded','false');
            var l=b.parentNode.querySelector('[data-fourn-liste]'); if(l) l.hidden=true;
        });
    }
    document.addEventListener('click', function(e){
        var b=e.target.closest('[data-fourn-btn]');
        if(b){
            var ouvert=b.getAttribute('aria-expanded')==='true';
            fermerTout(b);
            b.setAttribute('aria-expanded', ouvert?'false':'true');
            var l=b.parentNode.querySelector('[data-fourn-liste]'); if(l) l.hidden=ouvert;
            e.preventDefault(); return;
        }
        if(!e.target.closest('[data-fourn-liste]')) fermerTout(null);
    });
    document.addEventListener('keydown', function(e){ if(e.key==='Escape') fermerTout(null); });
})();
</script>
