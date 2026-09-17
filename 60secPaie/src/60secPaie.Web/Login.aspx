<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Login.aspx.vb" Inherits="Paie60Sec.Web.PageConnexion" %>
<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Connexion - 60secPaie</title>
    <link href="~/Content/site.css" rel="stylesheet" />
</head>
<body>
    <form runat="server" class="page-connexion">
        <div class="boite-connexion">
            <span class="logo">60sec<span>Paie</span></span>

            <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="message erreur">
                <asp:Literal ID="litErreur" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlConnexion" runat="server" DefaultButton="btnConnexion">
                <p class="sous-titre">Connectez-vous pour faire vos paies.</p>
                <div class="champ">
                    <label for="<%= txtCourriel.ClientID %>">Courriel</label>
                    <asp:TextBox ID="txtCourriel" runat="server" TextMode="Email" MaxLength="256" autocomplete="username" />
                </div>
                <div class="champ">
                    <label for="<%= txtMotDePasse.ClientID %>">Mot de passe</label>
                    <asp:TextBox ID="txtMotDePasse" runat="server" TextMode="Password" MaxLength="200" autocomplete="current-password" />
                </div>
                <asp:Button ID="btnConnexion" runat="server" Text="Me connecter" />
            </asp:Panel>

            <asp:Panel ID="pnlCreation" runat="server" Visible="false" DefaultButton="btnCreer">
                <p class="sous-titre">Première utilisation : créez le compte administrateur.</p>
                <div class="champ">
                    <label for="<%= txtNom.ClientID %>">Votre nom</label>
                    <asp:TextBox ID="txtNom" runat="server" MaxLength="200" />
                </div>
                <div class="champ">
                    <label for="<%= txtCourrielAdmin.ClientID %>">Courriel</label>
                    <asp:TextBox ID="txtCourrielAdmin" runat="server" TextMode="Email" MaxLength="256" autocomplete="username" />
                </div>
                <div class="champ">
                    <label for="<%= txtMdp1.ClientID %>">Mot de passe (<%= MotsDePasse.LongueurMinimale %> caractères ou plus)</label>
                    <asp:TextBox ID="txtMdp1" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" />
                </div>
                <div class="champ">
                    <label for="<%= txtMdp2.ClientID %>">Confirmez le mot de passe</label>
                    <asp:TextBox ID="txtMdp2" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" />
                </div>
                <asp:Button ID="btnCreer" runat="server" Text="Créer le compte" />
            </asp:Panel>
        </div>
    </form>
</body>
</html>
