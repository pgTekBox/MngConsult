<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliers.aspx.vb" Inherits="MngConsul.wbfSuppliers" %>
<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Fournisseurs — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* Petites touches pour harmoniser avec le thème du Site.master */
        .page-head{
            display:flex; align-items:flex-start; justify-content:space-between; gap:12px; flex-wrap:wrap;
            padding:14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }
        .page-title{
            font-weight:900;
            font-size:18px;
            line-height:1.2;
        }
        .page-sub{
            color: var(--mc-muted);
            font-size:13px;
            margin-top:4px;
        }
        .actions{
            display:flex; gap:8px; flex-wrap:wrap; align-items:center;
        }
        .muted-note{
            color: var(--mc-muted);
            font-size:12px;
            padding: 10px 16px 0 16px;
        }
        .grid-wrap{ padding:16px; }

        .full-grid{
         height: calc(100vh - 220px);
}

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Fournisseurs</div>
            <div class="page-sub">Liste des fournisseurs (RadGrid Telerik)</div>
        </div>

        <div class="actions">
            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (nom, email, téléphone…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
            <asp:Button ID="btnClear" runat="server" CssClass="btn" Text="Effacer" CausesValidation="false" />
        </div>
    </div>

   
   <%--   Skin="Silk"--%>
      <%--Skin="Bootstrap"--%>
      <%--Skin="MetroTouch"--%>
      <%--Skin="Sunset"--%>
      <%--Skin="MetroTouch"--%>


    <div class="full-grid">
        <telerik:RadGrid ID="rgFournisseurs" runat="server"
           Skin="Metro"
            AutoGenerateColumns="False"
            AllowPaging="True"
            PageSize="25"
            AllowSorting="True"
           Height="100%"
          
            >
            <ClientSettings>
            <Scrolling AllowScroll="true" UseStaticHeaders="true" />
        </ClientSettings>
            <MasterTableView DataKeyNames="Id" CommandItemDisplay="Top" EditMode="InPlace">
                <CommandItemSettings
                    ShowAddNewRecordButton="False"
                    ShowRefreshButton="False"
                    ShowExportToCsvButton="False"
                    ShowExportToExcelButton="False"
                    ShowExportToPdfButton="False" />

                <Columns>
                     
                    <telerik:GridTemplateColumn HeaderText="Actions" UniqueName="Actions" AllowFiltering="False">
                        <ItemTemplate>
                            <asp:Button ID="btnEdit" runat="server" CssClass="btn" Text="Edit"
                                CommandName="EditSupplier" CommandArgument='<%# Eval("Id") %>' />
                            <asp:Button ID="btnDelete" runat="server" CssClass="btn" Text="Delete"
                                CommandName="DeleteSupplier" CommandArgument='<%# Eval("Id") %>' />
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>


 <telerik:GridBoundColumn DataField="NameAllAdddress" HeaderText="Nom" UniqueName="NameAllAdddress"
      />

  
 

 

 <telerik:GridDateTimeColumn DataField="Created" HeaderText="Créé le" UniqueName="Created"
     PickerType="DatePicker" DataFormatString="{0:yyyy-MM-dd}" />

                </Columns>
            </MasterTableView>

            <ClientSettings AllowColumnsReorder="True" ReorderColumnsOnClient="True">
                <Selecting AllowRowSelect="True" />
                <Scrolling AllowScroll="True" UseStaticHeaders="True" />
            </ClientSettings>

            <PagerStyle Mode="NextPrevAndNumeric" />
        </telerik:RadGrid>
    </div>

</asp:Content>



 
