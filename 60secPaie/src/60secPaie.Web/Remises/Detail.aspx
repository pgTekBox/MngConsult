<%@ Page Title="Paiement de retenues" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Detail.aspx.vb" Inherits="Paie60Sec.Web.PageDetailRemise" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <div>
            <h1>Paiement des retenues <asp:Literal ID="litStatut" runat="server" /></h1>
            <p class="sous-titre"><asp:Literal ID="litEntete" runat="server" /></p>
        </div>
        <div class="actions sans-impression">
            <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
            <a runat="server" href="~/Remises/Historique.aspx" class="bouton secondaire">Historique</a>
        </div>
    </div>

    <div class="carte">
        <asp:Literal ID="litDetail" runat="server" />
    </div>

    <div class="carte">
        <h2>Renseignements pour le formulaire de versement</h2>
        <asp:Literal ID="litFormulaire" runat="server" />
    </div>

    <asp:Panel ID="pnlAnnuler" runat="server" Visible="false" CssClass="carte sans-impression">
        <h2>Annuler ce paiement</h2>
        <p>À utiliser si le paiement a été enregistré par erreur. Les retenues des paies couvertes redeviendront « à payer ».</p>
        <asp:Button ID="btnAnnuler" runat="server" Text="Annuler le paiement" CssClass="danger"
            OnClientClick="return confirm('Annuler ce paiement de retenues ?');" />
    </asp:Panel>
</asp:Content>
