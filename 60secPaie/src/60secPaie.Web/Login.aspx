<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Login.aspx.vb" Inherits="Paie60Sec.Web.PageConnexion" %>
<!DOCTYPE html>
<html lang="<%= I18n.Langue %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>60secPaie</title>
    <link href="~/Content/site.css" rel="stylesheet" />
</head>
<body>
    <form runat="server" class="page-connexion">
        <div class="boite-connexion">
            <div class="langues"><asp:Literal ID="litLangues" runat="server" /></div>
            <span class="logo">60sec<span>Paie</span></span>

            <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="message erreur">
                <asp:Literal ID="litErreur" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlConnexion" runat="server" DefaultButton="btnConnexion">
                <p class="sous-titre">Connectez-vous avec votre compte MngConsul pour faire vos paies.</p>
                <div class="champ">
                    <asp:Label runat="server" AssociatedControlID="txtCourriel" Text="Courriel" />
                    <asp:TextBox ID="txtCourriel" runat="server" TextMode="Email" MaxLength="200" autocomplete="username" />
                </div>
                <div class="champ">
                    <asp:Label runat="server" AssociatedControlID="txtMotDePasse" Text="Mot de passe" />
                    <asp:TextBox ID="txtMotDePasse" runat="server" TextMode="Password" MaxLength="200" autocomplete="current-password" />
                </div>
                <asp:Button ID="btnConnexion" runat="server" Text="Me connecter" />
                <p class="note" style="margin-top:14px">Mot de passe oublié ? Réinitialisez-le à partir de la page de connexion de MngConsul.</p>
            </asp:Panel>
        </div>
    </form>
</body>
</html>
