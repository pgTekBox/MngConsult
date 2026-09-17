<%@ Page Title="Déclaration des salaires CNESST" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="CNESST.aspx.vb" Inherits="Paie60Sec.Web.PageCNESST" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Rapports</h1>
    <%= SousMenuRapports("cnesst") %>

    <div class="barre">
        <div>
            <h2>Déclaration des salaires pour la CNESST, année
                <asp:DropDownList ID="ddlAnnee" runat="server" AutoPostBack="true" Width="110" /></h2>
            <p class="sous-titre">Salaires bruts versés, excédents du maximum assurable et versements périodiques de l'année.</p>
        </div>
        <div class="actions sans-impression">
            <asp:Button ID="btnCsv" runat="server" Text="Exporter en CSV" CssClass="secondaire" />
            <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
        </div>
    </div>

    <asp:Literal ID="litRapport" runat="server" />
    <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucune paie confirmée pour l'instant.</asp:Label>
</asp:Content>
