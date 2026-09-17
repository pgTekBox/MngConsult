<%@ Page Title="Écritures comptables" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Ecritures.aspx.vb" Inherits="Paie60Sec.Web.PageEcritures" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Rapports</h1>
    <%= SousMenuRapports("ecritures") %>

    <asp:Panel runat="server" DefaultButton="btnAfficher" CssClass="sans-impression">
        <fieldset>
            <legend>Rapport d'écritures comptables</legend>
            <div class="champs">
                <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlLot">Paie</asp:Label>
                    <asp:DropDownList ID="ddlLot" runat="server" /></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDu">Paies payées du</asp:Label>
                    <asp:TextBox ID="txtDu" runat="server" TextMode="Date" /></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtAu">au</asp:Label>
                    <asp:TextBox ID="txtAu" runat="server" TextMode="Date" /></div>
            </div>
            <p class="note">Choisissez une paie précise, ou « Toutes les paies de la période » pour une écriture sommaire (un mois, par exemple).</p>
            <div class="actions">
                <asp:Button ID="btnAfficher" runat="server" Text="Afficher" />
                <asp:Button ID="btnCsv" runat="server" Text="Exporter en CSV" CssClass="secondaire" />
                <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
                <a runat="server" href="~/Config/PlanComptable.aspx">Définir les numéros de compte</a>
            </div>
        </fieldset>
    </asp:Panel>

    <asp:Panel ID="pnlRapport" runat="server" CssClass="carte table-defilante">
        <h2><asp:Literal ID="litTitre" runat="server" /></h2>
        <asp:Literal ID="litEcritures" runat="server" />
    </asp:Panel>
</asp:Content>
