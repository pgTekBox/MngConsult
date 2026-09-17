<%@ Page Title="Dépôt direct" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="DepotDirect.aspx.vb" Inherits="Paie60Sec.Web.PageConfigDepotDirect" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("depot") %>

    <div class="avertissement">
        Ces renseignements vous sont remis par votre institution financière lorsque vous adhérez à son service de dépôt direct
        (transfert automatisé de fonds). Le fichier produit suit la <strong>norme 005 de Paiements Canada</strong> (1 464 caractères).
        Faites valider un <strong>fichier d'essai</strong> par votre institution avant le premier dépôt réel : certaines exigent un format qui leur est propre.
    </div>

    <fieldset>
        <legend>Paramètres du fichier de dépôt direct</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtEmetteur">Numéro d'émetteur (10 caractères)</asp:Label>
                <asp:TextBox ID="txtEmetteur" runat="server" MaxLength="10" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCentre">Centre de traitement de destination (5 chiffres)</asp:Label>
                <asp:TextBox ID="txtCentre" runat="server" MaxLength="5" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNomCourt">Nom abrégé de la compagnie (15 caractères)</asp:Label>
                <asp:TextBox ID="txtNomCourt" runat="server" MaxLength="15" />
                <div class="aide">Paraît sur le relevé bancaire de l'employé.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNomLong">Nom complet (30 caractères)</asp:Label>
                <asp:TextBox ID="txtNomLong" runat="server" MaxLength="30" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtProchain">Prochain numéro de fichier (1 à 9999)</asp:Label>
                <asp:TextBox ID="txtProchain" runat="server" MaxLength="4" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Compte de la compagnie (retours et règlement)</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtInstitution">Numéro d'institution (3 chiffres)</asp:Label>
                <asp:TextBox ID="txtInstitution" runat="server" MaxLength="3" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTransit">Numéro de transit (5 chiffres)</asp:Label>
                <asp:TextBox ID="txtTransit" runat="server" MaxLength="5" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCompte">Numéro de compte</asp:Label>
                <asp:TextBox ID="txtCompte" runat="server" MaxLength="12" autocomplete="off" />
                <div class="aide"><asp:Literal ID="litCompteActuel" runat="server" /></div></div>
        </div>
    </fieldset>

    <div class="actions"><asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" /></div>
</asp:Content>
