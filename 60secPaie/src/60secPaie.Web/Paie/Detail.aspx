<%@ Page Title="Détail de la paie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Detail.aspx.vb" Inherits="Paie60Sec.Web.PageDetailLot" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <div>
            <h1>Détail de la paie <asp:Literal ID="litStatut" runat="server" /></h1>
            <p class="sous-titre"><asp:Literal ID="litPeriode" runat="server" /></p>
        </div>
        <div class="actions sans-impression">
            <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
            <a runat="server" href="~/Paie/Historique.aspx" class="bouton secondaire">Historique</a>
        </div>
    </div>

    <div class="carte">
        <asp:Literal ID="litTableau" runat="server" />
    </div>
    <asp:Literal ID="litSommaire" runat="server" />

    <asp:Panel ID="pnlAnnuler" runat="server" Visible="false" CssClass="carte sans-impression">
        <h2>Annuler cette paie</h2>
        <p>La paie confirmée la plus récente peut être annulée, par exemple pour corriger une erreur. Elle sera retirée des cumulatifs ;
           les numéros de chèque déjà attribués ne sont pas réutilisés.</p>
        <asp:Button ID="btnAnnuler" runat="server" Text="Annuler la paie" CssClass="danger"
            OnClientClick="return confirm('Annuler définitivement cette paie ?');" />
    </asp:Panel>
</asp:Content>
