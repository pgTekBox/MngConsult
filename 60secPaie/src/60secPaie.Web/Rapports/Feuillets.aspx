<%@ Page Title="T4 et Relevés 1" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Feuillets.aspx.vb" Inherits="Paie60Sec.Web.PageFeuillets" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Rapports</h1>
    <%= SousMenuRapports("feuillets") %>

    <div class="barre">
        <div>
            <h2>Feuillets T4 et Relevés 1 de l'année
                <asp:DropDownList ID="ddlAnnee" runat="server" AutoPostBack="true" Width="110" /></h2>
            <p class="sous-titre">Montants calculés à partir des paies confirmées et des cumulatifs de départ.</p>
        </div>
        <div class="actions sans-impression">
            <asp:Button ID="btnCsv" runat="server" Text="Exporter en CSV" CssClass="secondaire" />
            <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
        </div>
    </div>

    <asp:Panel ID="pnlContenu" runat="server">
        <div class="avertissement sans-impression">
            60secPaie calcule les montants de chaque case ; il ne transmet pas les feuillets. Saisissez-les dans <strong>Formulaires Web</strong> (ARC)
            et dans <strong>Mon dossier pour les entreprises</strong> (Revenu Québec), au plus tard le dernier jour de février.
            Vérifiez les cases avec les guides RC4120 (T4) et RL-1.G (Relevé 1) de l'année.
        </div>
        <div class="carte table-defilante"><asp:Literal ID="litTableau" runat="server" /></div>
        <asp:Literal ID="litSommaire" runat="server" />
    </asp:Panel>
    <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucune paie confirmée pour l'instant.</asp:Label>
</asp:Content>
