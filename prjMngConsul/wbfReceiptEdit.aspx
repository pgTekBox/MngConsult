<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfReceiptEdit.aspx.vb" Inherits="MngConsul.wbfReceiptEdit" %>
<%@ Register Src="~/Controls/ucReceiptEdit.ascx" TagPrefix="uc" TagName="ReceiptEdit" %>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="css/listvew.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <uc:ReceiptEdit runat="server" ID="ReceiptEdit1" />
</asp:Content>
