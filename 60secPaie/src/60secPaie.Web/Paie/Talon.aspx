<%@ Page Title="Talon de paie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Talon.aspx.vb" Inherits="Paie60Sec.Web.PageTalon" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="actions sans-impression" style="margin-bottom:16px">
        <a href="javascript:window.print()" class="bouton">Imprimer le talon</a>
        <asp:HyperLink ID="lnkRetour" runat="server" CssClass="bouton secondaire">Retour au détail de la paie</asp:HyperLink>
    </div>
    <asp:Literal ID="litTalon" runat="server" />
</asp:Content>
