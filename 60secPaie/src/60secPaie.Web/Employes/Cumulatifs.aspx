<%@ Page Title="Cumulatifs de départ" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Cumulatifs.aspx.vb" Inherits="Paie60Sec.Web.PageCumulatifs" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Cumulatifs de départ de <asp:Literal ID="litEmploye" runat="server" /></h1>
    <p class="sous-titre">
        Si vous commencez à utiliser 60secPaie en cours d'année, inscrivez ici les montants déjà versés et retenus dans votre ancien système.
        Ils servent à respecter les maximums annuels (RRQ, AE, RQAP, CNESST) et s'ajoutent aux cumulatifs du talon de paie.
    </p>

    <fieldset>
        <legend>Année <asp:DropDownList ID="ddlAnnee" runat="server" AutoPostBack="true" Width="110" /></legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtBrut">Rémunération brute ($)</asp:Label>
                <asp:TextBox ID="txtBrut" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtImpotFed">Impôt fédéral retenu ($)</asp:Label>
                <asp:TextBox ID="txtImpotFed" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtImpotQc">Impôt du Québec retenu ($)</asp:Label>
                <asp:TextBox ID="txtImpotQc" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtGainsRRQ">Salaire admissible au RRQ ($)</asp:Label>
                <asp:TextBox ID="txtGainsRRQ" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtRRQ">Cotisation au RRQ (base + 1re suppl.) ($)</asp:Label>
                <asp:TextBox ID="txtRRQ" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtRRQ2">2e cotisation supplémentaire au RRQ ($)</asp:Label>
                <asp:TextBox ID="txtRRQ2" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAE">Cotisation à l'assurance-emploi ($)</asp:Label>
                <asp:TextBox ID="txtAE" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtRQAP">Cotisation au RQAP - employé ($)</asp:Label>
                <asp:TextBox ID="txtRQAP" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtRQAPEmployeur">Cotisation au RQAP - employeur ($)</asp:Label>
                <asp:TextBox ID="txtRQAPEmployeur" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtGainsCNESST">Salaire assurable CNESST ($)</asp:Label>
                <asp:TextBox ID="txtGainsCNESST" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtVacances">Solde de vacances à payer ($)</asp:Label>
                <asp:TextBox ID="txtVacances" runat="server" MaxLength="12" /></div>
        </div>
        <div class="actions">
            <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
            <asp:HyperLink ID="lnkFiche" runat="server">Retour à la fiche</asp:HyperLink>
        </div>
    </fieldset>
</asp:Content>
