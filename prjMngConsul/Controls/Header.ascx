<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="Header.ascx.vb" Inherits="MngConsul.Controls.Header" %>
 
<header class="app-header">
    <div class="app-header-inner">

        <!-- Left -->
        <div class="header-left">
            <span class="logo-dot"></span>
            <span class="logo-text">
                <asp:Literal runat="server" ID="litAppName" Text="MngConsul" />
            </span>
            <span class="logo-tag">ERP</span>
        </div>

        <!-- Right -->
        <div class="header-right">

            <div class="header-action">
                🔔
            </div>

            <div class="header-user">
                <div class="user-avatar">PG</div>
                <div class="user-info">
                    <div class="user-name">
                        <asp:Literal runat="server" ID="litUserName" Text="Pierre" />
                    </div>
                    <div class="user-role">Administrateur</div>
                </div>
            </div>

        </div>

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
.header-right{
    display:flex;
    align-items:center;
    gap:14px;
}

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

.header-user{
    display:flex;
    align-items:center;
    gap:10px;
    background:white;
    border:1px solid var(--border);
    border-radius:14px;
    padding:6px 10px;
}

.user-avatar{
    width:34px;
    height:34px;
    border-radius:10px;
    background:var(--primary-weak);
    color:var(--primary);
    display:flex;
    align-items:center;
    justify-content:center;
    font-weight:800;
}

.user-name{
    font-size:14px;
    font-weight:700;
}

.user-role{
    font-size:11px;
    color:var(--muted);
}

@media(max-width:768px){
    .user-info{ display:none; }
}
</style>
