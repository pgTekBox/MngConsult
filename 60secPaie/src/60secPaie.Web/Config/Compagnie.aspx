<%@ Page Title="Ma compagnie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Compagnie.aspx.vb" Inherits="Paie60Sec.Web.PageCompagnie" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <div class="sous-menu">
        <a runat="server" href="~/Config/Compagnie.aspx" class="actif">Ma compagnie</a>
        <a runat="server" href="~/Config/ElementsPaie.aspx">Éléments de paie</a>
        <a runat="server" href="~/Config/Utilisateurs.aspx">Utilisateurs</a>
    </div>

    <fieldset>
        <legend>Informations de base</legend>
        <div class="champs">
            <div class="champ large"><asp:Label runat="server" AssociatedControlID="txtNom" CssClass="requis">Nom de la compagnie</asp:Label>
                <asp:TextBox ID="txtNom" runat="server" MaxLength="200" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAdresse1">Adresse - ligne 1</asp:Label>
                <asp:TextBox ID="txtAdresse1" runat="server" MaxLength="200" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAdresse2">Adresse - ligne 2</asp:Label>
                <asp:TextBox ID="txtAdresse2" runat="server" MaxLength="200" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtVille">Ville</asp:Label>
                <asp:TextBox ID="txtVille" runat="server" MaxLength="100" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCodePostal">Code postal</asp:Label>
                <asp:TextBox ID="txtCodePostal" runat="server" MaxLength="7" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTelephone">Téléphone</asp:Label>
                <asp:TextBox ID="txtTelephone" runat="server" MaxLength="30" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCourriel">Courriel</asp:Label>
                <asp:TextBox ID="txtCourriel" runat="server" MaxLength="256" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Informations de paie</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlPeriodes" CssClass="requis">Période de paie par défaut</asp:Label>
                <asp:DropDownList ID="ddlPeriodes" runat="server">
                    <asp:ListItem Value="52">Hebdomadaire (52 périodes)</asp:ListItem>
                    <asp:ListItem Value="26" Selected="True">Aux 2 semaines (26 périodes)</asp:ListItem>
                    <asp:ListItem Value="24">Bimensuel (24 périodes)</asp:ListItem>
                    <asp:ListItem Value="12">Mensuel (12 périodes)</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxVacances" CssClass="requis">Taux de vacances par défaut (%)</asp:Label>
                <asp:TextBox ID="txtTauxVacances" runat="server" MaxLength="6" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtProchainCheque">Prochain numéro de chèque</asp:Label>
                <asp:TextBox ID="txtProchainCheque" runat="server" MaxLength="9" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNEFederal">Numéro d'entreprise fédéral (RP)</asp:Label>
                <asp:TextBox ID="txtNEFederal" runat="server" MaxLength="20" placeholder="123456789RP0001" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNIRQ">Numéro d'identification Revenu Québec (RS)</asp:Label>
                <asp:TextBox ID="txtNIRQ" runat="server" MaxLength="20" placeholder="1234567890RS0001" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Cotisations de l'employeur</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtMasse">Masse salariale totale estimée ($)</asp:Label>
                <asp:TextBox ID="txtMasse" runat="server" MaxLength="15" />
                <div class="aide">Sert à déterminer le taux de cotisation au FSS.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlSecteur">Secteur d'activité (FSS)</asp:Label>
                <asp:DropDownList ID="ddlSecteur" runat="server">
                    <asp:ListItem Value="0">Général</asp:ListItem>
                    <asp:ListItem Value="1">Primaire et manufacturier</asp:ListItem>
                    <asp:ListItem Value="2">Secteur public</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">Taux FSS appliqué : <asp:Literal ID="litTauxFSS" runat="server" /></div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtFacteurAE" CssClass="requis">Facteur de cotisation de l'employeur à l'AE</asp:Label>
                <asp:TextBox ID="txtFacteurAE" runat="server" MaxLength="6" />
                <div class="aide">1,4 sauf si vous bénéficiez d'un taux réduit.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxCNESST">Taux de la CNESST ($ par 100 $ assurables)</asp:Label>
                <asp:TextBox ID="txtTauxCNESST" runat="server" MaxLength="8" />
                <div class="aide">Inscrit sur votre décision de classification.</div></div>
        </div>
        <div class="cases">
            <span><asp:CheckBox ID="chkCNT" runat="server" Text="Assujetti à la cotisation relative aux normes du travail (CNT)" /></span>
        </div>
    </fieldset>

    <div class="actions">
        <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
    </div>
</asp:Content>
