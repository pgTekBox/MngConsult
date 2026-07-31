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

/* Indicateur de connexion Plaid — même gabarit que les autres pastilles (hauteur 42px) */
.plaid-pill{
    display:inline-flex;
    align-items:center;
    gap:7px;
    height:42px;
    box-sizing:border-box;
    padding:0 14px;
    border-radius:12px;
    font-size:12px;
    font-weight:800;
    white-space:nowrap;
    max-width:220px;
    overflow:hidden;
    cursor:default;
}
.plaid-pill.on{ background:#ecfdf5; border:1px solid #a7f3d0; color:#047857; }
.plaid-pill.off{ background:#f1f5f9; border:1px solid #e2e8f0; color:#64748b; }
.plaid-pill .dot{ width:9px; height:9px; border-radius:50%; flex:0 0 9px; }
.plaid-pill.on .dot{ background:#10b981; box-shadow:0 0 0 3px rgba(16,185,129,.2); }
.plaid-pill.off .dot{ background:#94a3b8; }
.plaid-pill .lbl{ overflow:hidden; text-overflow:ellipsis; }

@media(max-width:768px){
    .plaid-pill{ max-width:150px; }
}
@media(max-width:560px){
    .plaid-pill{ display:none; }
}

/* Pastille : nb de fournisseurs connectés à Stripe (même gabarit, hauteur 42px) */
.stripe-hdr-pill{
    display:inline-flex;
    align-items:center;
    gap:7px;
    height:42px;
    box-sizing:border-box;
    padding:0 14px;
    border-radius:12px;
    font-size:12px;
    font-weight:800;
    white-space:nowrap;
    cursor:default;
}
.stripe-hdr-pill.on{ background:#eef2ff; border:1px solid #c7d2fe; color:#4338ca; }
.stripe-hdr-pill.off{ background:#f1f5f9; border:1px solid #e2e8f0; color:#64748b; }
.stripe-hdr-pill .dot{ width:9px; height:9px; border-radius:50%; flex:0 0 9px; }
.stripe-hdr-pill.on .dot{ background:#635bff; box-shadow:0 0 0 3px rgba(99,91,255,.2); }
.stripe-hdr-pill.off .dot{ background:#94a3b8; }
.stripe-hdr-pill .num{ font-weight:900; }

@media(max-width:768px){
    .stripe-hdr-pill .lbl{ display:none; }
}
@media(max-width:560px){
    .stripe-hdr-pill{ display:none; }
}
</style>
