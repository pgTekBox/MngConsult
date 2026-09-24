<%@ Page Title="Nouvel employé" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Nouveau.aspx.vb" Inherits="Paie60Sec.Web.PageNouvelEmploye" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <h1>Nouvel employé</h1>
    </div>
    <p class="note">L'employé est créé dans la compagnie courante et apparaît aussitôt dans MngConsul, où son identité se modifie ensuite.
       Une fois créé, vous configurez sa paie dans sa fiche : NAS, période de paie, taux, exemptions, dépôt direct.</p>

    <fieldset>
        <legend>Identité</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtPrenom" CssClass="requis" Text="Prénom" />
                <asp:TextBox ID="txtPrenom" runat="server" MaxLength="150" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNom" CssClass="requis" Text="Nom de famille" />
                <asp:TextBox ID="txtNom" runat="server" MaxLength="150" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCode" Text="Code employé" />
                <asp:TextBox ID="txtCode" runat="server" MaxLength="50" />
                <div class="aide">Facultatif. Doit être unique dans la compagnie.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtPoste" Text="Poste" />
                <asp:TextBox ID="txtPoste" runat="server" MaxLength="150" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDateNaissance" Text="Date de naissance" />
                <asp:TextBox ID="txtDateNaissance" runat="server" TextMode="Date" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDateEmbauche" Text="Date d'embauche" />
                <asp:TextBox ID="txtDateEmbauche" runat="server" TextMode="Date" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Coordonnées</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAdresse1" Text="Adresse" />
                <asp:TextBox ID="txtAdresse1" runat="server" MaxLength="500" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAdresse2" Text="Adresse (suite)" />
                <asp:TextBox ID="txtAdresse2" runat="server" MaxLength="500" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtVille" Text="Ville" />
                <asp:TextBox ID="txtVille" runat="server" MaxLength="100" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlProvince" Text="Province" />
                <asp:DropDownList ID="ddlProvince" runat="server" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCodePostal" Text="Code postal" />
                <asp:TextBox ID="txtCodePostal" runat="server" MaxLength="20" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCourriel" Text="Courriel" />
                <asp:TextBox ID="txtCourriel" runat="server" MaxLength="200" TextMode="Email" />
                <div class="aide">Nécessaire pour envoyer le talon de paie par courriel.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTelephone" Text="Téléphone" />
                <asp:TextBox ID="txtTelephone" runat="server" MaxLength="50" TextMode="Phone" /></div>
        </div>
    </fieldset>

    <asp:Panel ID="pnlDoublon" runat="server" Visible="false" CssClass="avertissement">
        <asp:Literal ID="litDoublon" runat="server" />
        <div class="cases" style="margin-top:8px">
            <span><asp:CheckBox ID="chkMalgreDoublon" runat="server" Text="Il s'agit d'une autre personne : créer quand même" /></span>
        </div>
    </asp:Panel>

    <div class="actions">
        <asp:Button ID="btnCreer" runat="server" Text="Créer l'employé" />
        <a runat="server" href="~/Employes/Liste.aspx">Annuler</a>
    </div>
</asp:Content>
