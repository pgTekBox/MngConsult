<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="HeaderUser.ascx.vb" Inherits="MngConsul.HeaderUser" %>

<div class="header-right">
<telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server"  >
    <%-- Sélecteur de compagnie (visible uniquement si comptable avec >1 compagnie) --%>
    <asp:Panel ID="pnlCompanyPicker" runat="server" CssClass="company-picker" Visible="false">
        <span class="company-icon" aria-hidden="true">🏢</span>
        <asp:DropDownList ID="ddlCompany" runat="server"
            CssClass="company-select" 
            AutoPostBack="false" />
    </asp:Panel>
    </telerik:RadAjaxPanel>
    <%-- Affichage simple si une seule compagnie --%>
    <asp:Panel ID="pnlCompanyLabel" runat="server" CssClass="company-label" Visible="false">
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
