<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomers.aspx.vb" Inherits="MngConsul.wbfCustomers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* Petites touches pour harmoniser avec le thème du Site.master */
        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .page-title {
            font-weight: 900;
            font-size: 18px;
            line-height: 1.2;
        }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

        .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .grid-wrap {
            padding: 16px;
        }

        .full-grid {
            height: calc(100vh - 220px);
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadWindowManager ID="rwmCustomers" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadWindow ID="rwCustomer" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        Title="Ajouter / Modifier un Client"
        OnClientClose="rwCustomer_OnClientClose">
    </telerik:RadWindow>


    <div class="page-head">
        <div>
            <div class="page-title">Clients</div>
            <div class="page-sub">Liste des clients (RadGrid Telerik)</div>
        </div>

        <div class="actions">
            <asp:Button ID="btnAddCustomer" runat="server"
                CssClass="btn primary"
                Text="Ajouter Client"
                CausesValidation="false"
                OnClientClick="openCustomerWindow(0); return false;" />
            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (nom, email, téléphone…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
            <asp:Button ID="btnClear" runat="server" CssClass="btn" Text="Effacer" CausesValidation="false" />
        </div>
    </div>



    <div class="full-grid">
        <telerik:RadGrid ID="rgClients" runat="server"
            Skin="Metro"
            AutoGenerateColumns="False"
            AllowPaging="True"
            PageSize="25"
            AllowSorting="True"
            Height="100%">
             <ClientSettings  AllowColumnsReorder="True" ReorderColumnsOnClient="True">
     <Selecting AllowRowSelect="True" />
     <Scrolling AllowScroll="true"  UseStaticHeaders="true" />
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
 

            
        </telerik:RadGrid>
    </div>

    <script type="text/javascript">
        function openSupplierWindow(id) {
            var wnd = $find("<%= rwCustomer.ClientID %>");
            var url = "wbfCustomerEdit.aspx";

            if (id && id > 0) {
                url += "?CustomerId=" + id;
                wnd.set_title("Modifier un client");
            } else {
                url += "?CustomerId=0";
                wnd.set_title("Ajouter un client");
            }

            wnd.setUrl(url);
            wnd.show();
        }

        function rwCustomer_OnClientClose(sender, args) {
            // Refresh la grid après fermeture
            var grid = $find("<%= rgClients.ClientID %>");
            if (grid) {
                grid.get_masterTableView().rebind();
            }
        }
    </script>
</asp:Content>
