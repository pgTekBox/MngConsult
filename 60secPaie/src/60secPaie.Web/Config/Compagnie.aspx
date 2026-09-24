<%@ Page Title="Ma compagnie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Compagnie.aspx.vb" Inherits="Paie60Sec.Web.PageCompagnie" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("compagnie") %>

    <fieldset>
        <legend>Compagnie</legend>
        <asp:Literal ID="litIdentite" runat="server" />
        <p class="note">Le nom et les coordonnées de la compagnie se modifient dans MngConsul (paramètres de l'entreprise).</p>
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
                    <asp:ListItem Value="1">Annuelle (1 période)</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxVacances" CssClass="requis">Taux de vacances par défaut (%)</asp:Label>
                <asp:TextBox ID="txtTauxVacances" runat="server" MaxLength="6" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtProchainCheque">Prochain numéro de chèque</asp:Label>
                <asp:TextBox ID="txtProchainCheque" runat="server" MaxLength="9" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlFreqFederale">Fréquence de paiement des retenues fédérales</asp:Label>
                <asp:DropDownList ID="ddlFreqFederale" runat="server">
                    <asp:ListItem Value="M">Mensuelle (dû le 15 du mois suivant)</asp:ListItem>
                    <asp:ListItem Value="T">Trimestrielle (dû le 15 suivant le trimestre)</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlFreqQuebec">Fréquence de paiement des retenues à Revenu Québec</asp:Label>
                <asp:DropDownList ID="ddlFreqQuebec" runat="server">
                    <asp:ListItem Value="M">Mensuelle (dû le 15 du mois suivant)</asp:ListItem>
                    <asp:ListItem Value="T">Trimestrielle (dû le 15 suivant le trimestre)</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">La fréquence est celle que l'ARC et Revenu Québec vous ont attribuée.</div></div>
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
