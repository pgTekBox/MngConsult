<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliersInvoices.aspx.vb" Inherits="MngConsul.wbfSuppliersInvoices" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
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

    <telerik:RadWindowManager ID="rwmSuppliersInvoices" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadWindow ID="rwSupplierInvoices" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        Title="Ajouter / Modifier un facture fournisseur"
        OnClientClose="rwSupplierInvoice_OnClientClose">
    </telerik:RadWindow>


    <div class="page-head">
        <div>
            <div class="page-title">Facture Fournisseurs</div>
            <div class="page-sub">Liste des factures fournisseurs </div>
        </div>

        <div class="actions">
            <asp:Button ID="btnAddSupplier" runat="server"
                CssClass="btn primary"
                Text="Ajouter Supplier"
                CausesValidation="false"
                OnClientClick="openSupplierInvoicesWindow(0); return false;" />
            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (nom, email, téléphone…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
            <asp:Button ID="btnClear" runat="server" CssClass="btn" Text="Effacer" CausesValidation="false" />
        </div>
    </div>



    <div class="full-grid">
       <telerik:RadGrid ID="rgFournisseursFactures" runat="server"
       Skin="Metro"
    AutoGenerateColumns="False"
    AllowPaging="false"
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

                    <telerik:GridTemplateColumn HeaderStyle-Width="200px" HeaderText="Actions" UniqueName="Actions" AllowFiltering="False">
                        <ItemTemplate>
                            <asp:Button ID="btnEdit" runat="server" CssClass="btn" Text="Edit"
                                OnClientClick='<%# "openSupplierInvoiceWindow(" & Eval("Id") & "); return false;" %>' />
                            <asp:Button ID="btnDelete" runat="server" CssClass="btn" Text="Delete"
                                CommandName="DeleteInvoice" CommandArgument='<%# Eval("Id") %>' />
                        </ItemTemplate>
                    </telerik:GridTemplateColumn>


                    <telerik:GridBoundColumn DataField="DocumentNumber" HeaderStyle-Width="200px" HeaderText="Number" UniqueName="DocumentNumber" />
                    <telerik:GridBoundColumn DataField="Name" HeaderText="Supplier" UniqueName="Name" />
                    <telerik:GridBoundColumn DataField="Total" HeaderStyle-Width="140px" DataFormatString="{0:C2}" HeaderText="Total" UniqueName="Total" HeaderStyle-HorizontalAlign="Right" ItemStyle-HorizontalAlign="Right" />

                    <telerik:GridBoundColumn DataField="Status" HeaderStyle-Width="70px" HeaderText="Status" UniqueName="Status" />


                    <telerik:GridDateTimeColumn DataField="DocumentDate" HeaderStyle-Width="130px" HeaderText="Date" UniqueName="DocumentDate"
                        DataFormatString="{0:yyyy-MM-dd}" />

                </Columns>
            </MasterTableView>


        </telerik:RadGrid>
         


    </div>


    <script type="text/javascript">
        function openSupplierInvoiceWindow(id) {
            var wnd = $find("<%= rwSupplierInvoices.ClientID %>");
            var url = "wbfSupplierInvoinceEdit.aspx";

            if (id && id > 0) {
                url += "?SupplierId=" + id;
                wnd.set_title("Modifier un fournisseur");
            } else {
                url += "?SupplierId=0";
                wnd.set_title("Ajouter un fournisseur");
            }

            wnd.setUrl(url);
            wnd.show();
        }

        function rwSupplierInvoice_OnClientClose(sender, args) {
            // Refresh la grid après fermeture
            var grid = $find("<%= rwSupplierInvoices.ClientID %>");
            if (grid) {
                grid.get_masterTableView().rebind();
            }
        }
</script>
</asp:Content>
