<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" 
    CodeBehind="wbfJournal.aspx.vb" Inherits="MngConsul.wbfJournal" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <telerik:RadWindowManager ID="rwmJournal" runat="server" EnableShadow="true"></telerik:RadWindowManager>

        <telerik:RadWindow ID="rwCompte" runat="server"
        Modal="true"
        VisibleOnPageLoad="true"

        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        ClientIDMode="Static"
        Title="Ajouter / Modifier un écriture"
        NavigateUrl="wbfJournalList.aspx">
    </telerik:RadWindow>


</asp:Content>
