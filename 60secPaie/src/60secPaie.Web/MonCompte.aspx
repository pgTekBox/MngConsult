<%@ Page Title="Mon compte" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="MonCompte.aspx.vb" Inherits="Paie60Sec.Web.PageMonCompte" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Mon compte</h1>
    <p class="sous-titre">Connecté en tant que <strong><asp:Literal ID="litCourriel" runat="server" /></strong></p>

    <asp:Panel runat="server" DefaultButton="btnEnregistrerNom">
        <fieldset>
            <legend>Mes informations</legend>
            <div class="champs">
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNom" CssClass="requis">Nom complet</asp:Label>
                    <asp:TextBox ID="txtNom" runat="server" MaxLength="200" /></div>
            </div>
            <div class="actions"><asp:Button ID="btnEnregistrerNom" runat="server" Text="Enregistrer" /></div>
        </fieldset>
    </asp:Panel>

    <asp:Panel runat="server" DefaultButton="btnChangerMotDePasse">
        <fieldset>
            <legend>Changer mon mot de passe</legend>
            <div class="champs">
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtActuel" CssClass="requis">Mot de passe actuel</asp:Label>
                    <asp:TextBox ID="txtActuel" runat="server" TextMode="Password" MaxLength="200" autocomplete="current-password" /></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNouveau" CssClass="requis">Nouveau mot de passe</asp:Label>
                    <asp:TextBox ID="txtNouveau" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" />
                    <div class="aide">Au moins <%= MotsDePasse.LongueurMinimale %> caractères. Une phrase facile à retenir est un bon choix.</div></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtConfirmation" CssClass="requis">Confirmez le nouveau mot de passe</asp:Label>
                    <asp:TextBox ID="txtConfirmation" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" /></div>
            </div>
            <div class="actions"><asp:Button ID="btnChangerMotDePasse" runat="server" Text="Changer le mot de passe" /></div>
        </fieldset>
    </asp:Panel>
</asp:Content>
