<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="Footer.ascx.vb" Inherits="MngConsul.Controls.Footer" %>
 
<footer class="app-footer">
    <div class="footer-inner">

        <div class="footer-left">
            © <%= DateTime.Now.Year %> 
            <asp:Literal runat="server" ID="litCompany" Text="396 7557 Canada Inc." />
        </div>

        <div class="footer-center">
            Version <asp:Literal runat="server" ID="litVersion" Text="1.0.0" />
        </div>

        <div class="footer-right">
            <a href="#">Support</a>
            <a href="#">Confidentialité</a>
            <a href="#">Conditions</a>
        </div>

    </div>
</footer>

<style>
.app-footer{
    background:white;
    border-top:1px solid var(--border);
   /* margin-top:30px;*/
}

.footer-inner{
    padding:16px 20px;
    display:flex;
    align-items:center;
    justify-content:space-between;
    font-size:13px;
    color:var(--muted);
}

.footer-right{
    display:flex;
    gap:16px;
}

.footer-right a{
    text-decoration:none;
    color:var(--muted);
    font-weight:600;
}

.footer-right a:hover{
    color:var(--primary);
}

@media(max-width:768px){
    .footer-inner{
        flex-direction:column;
        gap:8px;
        text-align:center;
    }
}
</style>
