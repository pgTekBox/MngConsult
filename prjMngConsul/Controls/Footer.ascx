<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="Footer.ascx.vb" Inherits="MngConsul.Controls.Footer" %>
 
<footer class="app-footer">
    <div class="footer-inner">

        <div class="footer-left">
            © <%= DateTime.Now.Year %>
            <asp:Literal runat="server" ID="litCompany" Text="60secondes — 9567-0048 Québec inc., Montréal." />
            <asp:Literal runat="server" ID="litDonnees" Text="Vos données restent au Canada." />
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
/* Le pied de page au style « Doux bleu marine » : filet, Nunito, liens bleu marine. */
.app-footer{
    background:#ffffff;
    border-top:1px solid var(--mc-line,#D5DDE8);
    font-family:var(--mc-font-titre, Nunito, system-ui, sans-serif);
}
.footer-inner{
    padding:22px 24px;
    display:flex;
    flex-wrap:wrap;
    align-items:center;
    justify-content:space-between;
    gap:10px 24px;
    font-size:15px;
    color:var(--mc-muted2,#44536E);
}
.footer-left{ flex:1 1 auto; }
.footer-right{
    display:flex;
    gap:24px;
}
.footer-right a{
    text-decoration:none;
    color:var(--mc-navy,#0E1F3D);
    font-weight:700;
    padding:6px 0;
}
.footer-right a:hover{
    color:var(--mc-primary,#1B4F9C);
}
@media(max-width:768px){
    .footer-inner{
        flex-direction:column;
        gap:8px;
        text-align:center;
    }
}
</style>
