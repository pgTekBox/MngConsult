<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="ImportClients.aspx.vb" Inherits="MngConsul.ImportClients" %>
<%@ Register Src="~/Controls/ImportDonnees.ascx" TagPrefix="uc" TagName="ImportDonnees" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importer les clients — 60Sec-AI
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <uc:ImportDonnees ID="ucImport" runat="server" Genre="CLIENTS" />
</asp:Content>