<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomers.aspx.vb" Inherits="MngConsul.wbfCustomers" %>
<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — MngConsul
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
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Clients</div>
            <div class="page-sub">Liste des clients (RadGrid Telerik)</div>
        </div>

        <div class="actions">
            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (nom, email, téléphone…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
            <asp:Button ID="btnClear" runat="server" CssClass="btn" Text="Effacer" CausesValidation="false" />
        </div>
    </div>

    <div class="muted-note">
        Astuce: tu peux trier, filtrer et paginer. Le binding se fera dans le code-behind via <code>NeedDataSource</code>.
    </div>

    <div class="grid-wrap">
        <telerik:RadGrid ID="rgClients" runat="server"
            Skin="Silk"
            AutoGenerateColumns="False"
            AllowPaging="True"
            PageSize="25"
            AllowSorting="True"
            AllowFilteringByColumn="True"
            ShowGroupPanel="True"
             >

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
                                CommandName="EditClient" CommandArgument='<%# Eval("Id") %>' />
                            <asp:Button ID="btnDelete" runat="server" CssClass="btn" Text="Delete"
                                CommandName="DeleteClient" CommandArgument='<%# Eval("Id") %>' />
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>

                    
                    <telerik:GridBoundColumn DataField="Id" HeaderText="ID" UniqueName="CustomerId"
                        ReadOnly="True" FilterControlAltText="Filtrer ID" />

                    <telerik:GridBoundColumn DataField="Name" HeaderText="Nom" UniqueName="Name"
                        FilterControlAltText="Filtrer Nom" />

                    <telerik:GridBoundColumn DataField="Email" HeaderText="Email" UniqueName="Email"
                        FilterControlAltText="Filtrer Email" />

                    <telerik:GridBoundColumn DataField="Phone" HeaderText="Téléphone" UniqueName="Phone"
                        FilterControlAltText="Filtrer Téléphone" />

                    <telerik:GridBoundColumn DataField="City" HeaderText="Ville" UniqueName="City"
                        FilterControlAltText="Filtrer Ville" />

                    <telerik:GridBoundColumn DataField="StateId" HeaderText="Province" UniqueName="Province"
                        FilterControlAltText="Filtrer Province" />

                    <telerik:GridBoundColumn DataField="CountryId" HeaderText="Pays" UniqueName="Country"
                        FilterControlAltText="Filtrer Pays" />

                    

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
