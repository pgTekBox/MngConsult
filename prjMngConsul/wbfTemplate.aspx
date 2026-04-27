<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfTemplate.aspx.vb" Inherits="MngConsul.wbfTemplate" %>

<%@ Register Src="~/usJournalTemplateList.ascx" TagPrefix="uc1" TagName="usJournalTemplateList" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <uc1:usJournalTemplateList runat="server" id="usJournalTemplateList" />



</asp:Content>
