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
        <span class="company-icon" aria-hidden="true">🏢</span>
        <asp:DropDownList ID="ddlCompany" runat="server"
            CssClass="company-select"
            AutoPostBack="true" />
    </asp:Panel>

    <%-- Affichage simple si une seule compagnie --%>
    <asp:Panel ID="pnlCompanyLabel" runat="server" CssClass="company-label" Visible="false">
        <asp:Literal ID="litCompanyLogoLabel" runat="server" />
        <span class="company-icon" aria-hidden="true">🏢</span>
        <asp:Literal ID="litCompanyName" runat="server" />
    </asp:Panel>

    <div class="header-action" title="Notifications">
        🔔
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

        <a href="~/wbfLogout.aspx" runat="server" class="logout-btn" title="Déconnexion">⎋</a>
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
    border-radius:12px;
    background:#eff6ff;
    border:1px solid #bfdbfe;
    color:#1d4ed8;
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
    border-radius:12px;
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

/* === Sélecteur de langue === */
.lang-switch{
    display:flex;
    gap:2px;
    align-items:center;
    background:white;
    border:1px solid var(--border);
    border-radius:12px;
    padding:4px;
    height:42px;
    box-sizing:border-box;
}
.lang-switch a{
    padding:5px 9px;
    border-radius:8px;
    font-size:12px;
    font-weight:800;
    color:var(--muted);
    text-decoration:none;
    line-height:1;
}
.lang-switch a:hover{ background:#f1f5f9; }
.lang-switch a.active{
    background:var(--primary-weak,#eff6ff);
    color:var(--primary,#2563eb);
}

/* === Sélecteur de compagnie (DropDown) === */
.company-picker,
.company-label{
    display:flex;
    align-items:center;
    gap:8px;
    background:white;
    border:1px solid var(--border);
    border-radius:14px;
    padding:6px 12px;
    height:42px;
    box-sizing:border-box;
}

.company-icon{
    font-size:16px;
    flex-shrink:0;
}

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
    color:var(--text, #0f172a);
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
    border-radius:12px;
    border:1px solid var(--border);
    display:flex;
    align-items:center;
    justify-content:center;
    background:white;
    cursor:pointer;
}

/* === User === */
.header-user{
    display:flex;
    align-items:center;
    gap:10px;
    background:white;
    border:1px solid var(--border);
    border-radius:14px;
    padding:6px 10px;
    height:42px;
    box-sizing:border-box;
}

.user-avatar{
    width:34px;
    height:34px;
    border-radius:10px;
    background:linear-gradient(135deg,#2563eb,#06b6d4);
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
    color:var(--muted);
    white-space:nowrap;
}

.logout-btn{
    margin-left:6px;
    width:28px;
    height:28px;
    border-radius:8px;
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
