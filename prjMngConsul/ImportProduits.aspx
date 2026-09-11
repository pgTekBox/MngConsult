<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="ImportProduits.aspx.vb" Inherits="MngConsul.ImportProduits" %>
<%@ Register Src="~/Controls/ImportDonnees.ascx" TagPrefix="uc" TagName="ImportDonnees" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importer les produits et services — 60Sec-AI
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <uc:ImportDonnees ID="ucImport" runat="server" Genre="PRODUITS" />
</asp:Content>