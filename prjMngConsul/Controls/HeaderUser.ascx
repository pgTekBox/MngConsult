<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="HeaderUser.ascx.vb" Inherits="MngConsul.HeaderUser" %>

<div class="header-right">

    <%-- Pastille « fin de l'essai gratuit » (visible seulement pendant l'essai) --%>
    <asp:Panel ID="pnlTrial" runat="server" CssClass="trial-pill" Visible="false">
        <span class="trial-ico" aria-hidden="true">⏳</span>
        <asp:Literal ID="litTrial" runat="server" />
    </asp:Panel>

    <%-- Statut Square (visible seulement si un compte Square est connecté) --%>
    <asp:Panel ID="pnlSquare" runat="server" CssClass="square-pill" Visible="false"
        ToolTip="Compte Square connecté">
        <span class="square-dot" aria-hidden="true"></span>
        <asp:Literal ID="litSquare" runat="server" />
    </asp:Panel>

    <%-- Sélecteur de langue (FR / EN / ES) --%>
    <div class="lang-switch">
        <asp:Literal ID="litLang" runat="server" />
    </div>

    <%-- Sélecteur de compagnie (visible uniquement si comptable avec >1 compagnie) --%>
    <asp:Panel ID="pnlCompanyPicker" runat="server" CssClass="company-picker" Visible="false">
        <asp:Literal ID="litCompanyLogoPicker" runat="server" />
        <span class="company-icon" aria-hidden="true"><svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18z"/><path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2M10 6h4M10 10h4M10 14h4M10 18h4"/></svg></span>
        <asp:DropDownList ID="ddlCompany" runat="server"
            CssClass="company-select"
            AutoPostBack="true" />
    </asp:Panel>

    <%-- Affichage simple si une seule compagnie --%>
    <asp:Panel ID="pnlCompanyLabel" runat="server" CssClass="company-label" Visible="false">
        <asp:Literal ID="litCompanyLogoLabel" runat="server" />
        <span class="company-icon" aria-hidden="true"><svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18z"/><path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2M10 6h4M10 10h4M10 14h4M10 18h4"/></svg></span>
        <asp:Literal ID="litCompanyName" runat="server" />
    </asp:Panel>

    <%-- Aide en ligne de la section courante, dans une fenêtre à part (Aide/xxx.html?lang=). --%>
    <a id="lnkAide" runat="server" class="header-action header-aide" href="#" title="Aide"><svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01"/></svg></a>

    <div class="header-action" title="Notifications">
        <svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
    </div>

    <div class="header-user">
        <div class="user-avatar">
            <asp:Literal ID="litInitials" runat="server" Text="?" />
        </div>

        <div class="user-info">
            <div class="user-name">
                <asp:Literal ID="litUserName" runat="server" Text="Invité" />
            </div>
            <div class="user-role">
                <asp:Literal ID="litUserRole" runat="server" Text="" />
            </div>
        </div>

        <a href="~/wbfLogout.aspx" runat="server" class="logout-btn" title="Déconnexion"><svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5M21 12H9"/></svg></a>
    </div>

</div>


<style>

/* RIGHT */
.header-right{
    display:flex;
    align-items:center;
    gap:12px;
}

/* === Pastille essai gratuit === */
.trial-pill{
    display:flex;
    align-items:center;
    gap:7px;
    height:42px;
    box-sizing:border-box;
    padding:0 14px;
    border-radius:999px;
    background:#E3EBF7;
    border:1px solid #bfdbfe;
    color:#143A73;
    font-size:12px;
    font-weight:800;
    white-space:nowrap;
    cursor:default;
}
.trial-pill .trial-ico{ font-size:14px; line-height:1; }
/* Alerte quand il reste peu de jours */
.trial-pill.trial-pill--warn{
    background:#fff7ed;
    border-color:#fed7aa;
    color:#c2410c;
}
.trial-pill.trial-pill--danger{
    background:#fef2f2;
    border-color:#fecaca;
    color:#b91c1c;
}
@media(max-width:768px){
    .trial-pill .trial-lbl-long{ display:none; }
}
@media(max-width:560px){
    .trial-pill{ display:none; }
}

/* === Pastille statut Square === */
.square-pill{
    display:flex;
    align-items:center;
    gap:7px;
    height:42px;
    box-sizing:border-box;
    padding:0 14px;
    border-radius:999px;
    background:#ecfdf5;
    border:1px solid #a7f3d0;
    color:#047857;
    font-size:12px;
    font-weight:800;
    white-space:nowrap;
    cursor:default;
}
.square-pill .square-dot{
    width:9px;
    height:9px;
    border-radius:50%;
    background:#10b981;
    box-shadow:0 0 0 3px rgba(16,185,129,.2);
    flex-shrink:0;
}
@media(max-width:768px){
    .square-pill .square-lbl-long{ display:none; }
}
@media(max-width:560px){
    .square-pill{ display:none; }
}

/* === Sélecteur de langue : trois ronds, la langue courante sur fond doux (style « Doux bleu marine ») === */
.lang-switch{
    display:flex;
    gap:4px;
    align-items:center;
}
.lang-switch a{
    width:42px;
    height:42px;
    border-radius:50%;
    display:inline-flex;
    align-items:center;
    justify-content:center;
    font-size:13px;
    font-weight:700;
    color:var(--mc-muted2,#44536E);
    text-decoration:none;
    line-height:1;
    background:transparent;
}
.lang-switch a:hover{ background:var(--mc-soft,#E8EDF5); }
.lang-switch a.active{
    background:var(--mc-soft,#E8EDF5);
    color:var(--mc-navy,#0E1F3D);
}

/* === Sélecteur de compagnie (DropDown) === */
.company-picker,
.company-label{
    display:flex;
    align-items:center;
    gap:8px;
    background:white;
    border:1px solid var(--mc-line2,#AEBBCD);
    border-radius:999px;
    padding:6px 14px;
    color:var(--mc-navy,#0E1F3D);
    height:42px;
    box-sizing:border-box;
}

.company-icon{
    display:inline-flex;
    color:var(--mc-primary,#1B4F9C);
    flex-shrink:0;
}
.company-icon svg, .header-action svg, .logout-btn svg{ display:block; width:20px; height:20px; }
.logout-btn svg{ width:18px; height:18px; }

.company-logo{
    width:24px;
    height:24px;
    object-fit:contain;
    border-radius:6px;
    flex-shrink:0;
    display:inline-block;
    vertical-align:middle;
}

.company-select{
    border:none;
    background:transparent;
    font-family:inherit;
    font-size:13px;
    font-weight:700;
    color:var(--text, #0E1F3D);
    outline:none;
    padding:4px 6px;
    cursor:pointer;
    min-width:160px;
    max-width:240px;
    text-overflow:ellipsis;
}

.company-select:focus{
    color:var(--primary);
}

.company-label{
    font-size:13px;
    font-weight:700;
}

/* === Action (cloche) === */
.header-action{
    width:42px;
    height:42px;
    border-radius:50%;
    border:0;
    display:flex;
    align-items:center;
    justify-content:center;
    background:var(--mc-soft,#E8EDF5);
    color:var(--mc-navy,#0E1F3D);
    cursor:pointer;
}

.header-aide{
    font-weight:900;
    font-size:18px;
    color:var(--mc-primary,#1B4F9C);
    text-decoration:none;
}
.header-action:hover{ background:var(--mc-soft2,#E3EBF7); }

/* === User === */
.header-user{
    display:flex;
    align-items:center;
    gap:10px;
    background:white;
    border:1px solid var(--mc-line2,#AEBBCD);
    border-radius:999px;
    padding:4px 10px 4px 4px;
    height:46px;
    color:var(--mc-navy,#0E1F3D);
    box-sizing:border-box;
}

.header-user .user-avatar{
    width:36px;
    height:36px;
    border-radius:50%;
    background:var(--mc-primary,#1B4F9C);
    color:white;
    display:flex;
    align-items:center;
    justify-content:center;
    font-weight:800;
    font-size:13px;
    flex-shrink:0;
}

.user-info{
    line-height:1.2;
}

.user-name{
    font-size:14px;
    font-weight:700;
    white-space:nowrap;
}

.user-role{
    font-size:11px;
    color:var(--mc-muted2,#44536E);
    white-space:nowrap;
}

.logout-btn{
    margin-left:2px;
    width:30px;
    height:30px;
    border-radius:50%;
    display:inline-flex;
    align-items:center;
    justify-content:center;
    color:var(--muted);
    text-decoration:none;
    font-size:16px;
    transition:background .15s, color .15s;
}
.logout-btn:hover{
    background:rgba(220,38,38,.10);
    color:#dc2626;
}

@media(max-width:1024px){
    .company-select{ min-width:120px; max-width:160px; }
}

@media(max-width:768px){
    .user-info{
        display:none;
    }
    .company-picker, .company-label{
        padding:6px 10px;
    }
    .company-select{ min-width:90px; max-width:120px; font-size:12px; }
    .company-label{ font-size:12px; max-width:140px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
}

@media(max-width:560px){
    .company-picker, .company-label{
        display:none;
    }
}
</style>
