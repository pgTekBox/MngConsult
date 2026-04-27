<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" 
    CodeBehind="wbfJournal.aspx.vb" Inherits="MngConsul.wbfJournal" %>

<%@ Register Src="~/ucJournalList.ascx" TagPrefix="uc1" TagName="ucJournalList" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    
    <uc1:ucJournalList runat="server" ID="ucJournalList" />


</asp:Content>
