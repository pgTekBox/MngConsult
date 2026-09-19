<%@ Page Title="Feuillet T4 et Relevé 1" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Feuillet.aspx.vb" Inherits="Paie60Sec.Web.PageFeuillet" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
  <div class="talon-page">
    <div class="actions sans-impression" style="margin-bottom:16px">
        <a href="javascript:window.print()" class="bouton">Imprimer</a>
        <asp:HyperLink ID="lnkRetour" runat="server" CssClass="bouton secondaire">Retour aux feuillets</asp:HyperLink>
        <asp:Button ID="btnNas" runat="server" Text="Afficher le NAS complet" CssClass="secondaire" />
    </div>
    <asp:Literal ID="litFeuillet" runat="server" />
  </div>
</asp:Content>
