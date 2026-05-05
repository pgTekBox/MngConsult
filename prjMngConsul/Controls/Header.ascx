<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="Header.ascx.vb" Inherits="MngConsul.Controls.Header" %>
<%@ Register Src="~/Controls/HeaderUser.ascx" TagPrefix="uc1" TagName="HeaderUser" %>


<header class="app-header">
    <div class="app-header-inner">

        <!-- Left -->
        <div class="header-left">
            <span class="logo-dot"></span>
            <span class="logo-text">
                <asp:Literal runat="server" ID="litAppName" Text="60sec" />
            </span>
            <span class="logo-tag">ERP</span>
        </div>

        <!-- Right -->

        <uc1:HeaderUser runat="server" id="HeaderUser" />

     

    </div>
</header>

<style>
.app-header{
    background:#ffffff;
    border-bottom:1px solid var(--border);
    position:sticky;
    top:0;
    z-index:20;
      height:64px;
}

.app-header-inner{
    /*hauteur de header*/
    height:100%;
    padding:0 20px;
    display:flex;
    align-items:center;
    justify-content:space-between;
}

/* LEFT */
.header-left{
    display:flex;
    align-items:center;
    gap:10px;
}

.logo-dot{
    width:10px;
    height:10px;
    background:var(--primary);
    border-radius:50%;
    box-shadow:0 0 0 6px rgba(37,99,235,.15);
}

.logo-text{
    font-weight:800;
    font-size:18px;
}

.logo-tag{
    font-size:11px;
    font-weight:700;
    color:var(--muted);
}

/* RIGHT */
 
 
</style>
