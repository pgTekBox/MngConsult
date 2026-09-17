<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Login.aspx.vb" Inherits="Paie60Sec.Web.PageConnexion" %>
<!DOCTYPE html>
<html lang="<%= I18n.Langue %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>60secPaie</title>
    <link href="~/Content/site.css" rel="stylesheet" />
</head>
<body class="page-connexion">
    <form runat="server">
    <%-- La grille est sur un div INTERIEUR, pas sur le <form> : WebForms glisse
         juste après la balise un <div> caché (ViewState, EventValidation). Si le
         form est la grille, ce div devient une cellule et pousse tout le reste
         d'une rangée. --%>
    <div class="connexion-cadre">

        <%-- ---------- Le côté marque ----------
             Le même bleu et le même talon que la page de présentation : celui qui
             arrive ici depuis l'accueil doit reconnaître l'endroit, pas croire
             qu'il a changé de site. --%>
        <aside class="connexion-marque">
            <a runat="server" href="~/Accueil.aspx" class="logo">60sec<span translate="no">Paie</span></a>

            <div class="connexion-marque-corps">
                <h1>La paie, en quelques minutes.</h1>
                <ul class="connexion-points">
                    <li>Retenues calculées d'après les tables officielles de l'ARC et de Revenu Québec</li>
                    <li>Talons, T4 et RL-1 produits à partir de vos paies</li>
                    <li>Remises gouvernementales suivies d'une période à l'autre</li>
                </ul>
            </div>

            <p class="connexion-marque-pied">Un service de MngConsul</p>
        </aside>

        <%-- ---------- Le côté formulaire ---------- --%>
        <main class="connexion-panneau">
            <div class="connexion-boite">

                <div class="langues"><asp:Literal ID="litLangues" runat="server" /></div>

                <h2 class="connexion-titre">Connexion</h2>
                <p class="connexion-sous-titre">Connectez-vous avec votre compte MngConsul pour faire vos paies.</p>

                <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="message erreur">
                    <asp:Literal ID="litErreur" runat="server" />
                </asp:Panel>

                <asp:Panel ID="pnlConnexion" runat="server" DefaultButton="btnConnexion">
                    <div class="champ">
                        <asp:Label runat="server" AssociatedControlID="txtCourriel" Text="Courriel" />
                        <asp:TextBox ID="txtCourriel" runat="server" TextMode="Email" MaxLength="200"
                                     autocomplete="username" autofocus="autofocus" placeholder="vous@entreprise.ca" />
                    </div>
                    <div class="champ">
                        <asp:Label runat="server" AssociatedControlID="txtMotDePasse" Text="Mot de passe" />
                        <asp:TextBox ID="txtMotDePasse" runat="server" TextMode="Password" MaxLength="200"
                                     autocomplete="current-password" />
                    </div>

                    <asp:Button ID="btnConnexion" runat="server" Text="Me connecter" CssClass="connexion-bouton" />

                    <p class="note connexion-note">
                        Mot de passe oublié ? Réinitialisez-le à partir de la page de connexion de MngConsul.
                    </p>
                </asp:Panel>

                <div class="connexion-retour">
                    <a runat="server" href="~/Accueil.aspx">Qu'est-ce que 60secPaie ?</a>
                </div>

            </div>
        </main>

    </div>
    </form>
</body>
</html>
