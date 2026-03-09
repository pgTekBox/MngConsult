<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomersInvoices.aspx.vb" Inherits="MngConsul.wbfCustomersInvoices" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Invoices — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .page-shell {
            min-height: calc(100vh - 120px);
            display: flex;
            flex-direction: column;
        }

        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .page-head-left {
            min-width: 220px;
            flex: 1 1 260px;
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
            justify-content: flex-end;
            flex: 1 1 520px;
        }

        .actions .input {
            min-width: 260px;
            flex: 1 1 280px;
        }

        .actions .btn {
            white-space: nowrap;
        }

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .grid-host {
            flex: 1 1 auto;
            min-height: 0;
            padding: 16px;
        }

        .grid-card {
            height: 100%;
            min-height: 420px;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 10px 28px rgba(15, 23, 42, .06);
        }

        .grid-scroll {
            height: 100%;
            overflow-x: auto;
            overflow-y: hidden;
            -webkit-overflow-scrolling: touch;
        }

        .full-grid {
            min-width: 980px;
            height: 100%;
        }

        .action-cell {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .action-cell .btn {
            min-width: 90px;
        }

        @media (max-width: 1024px) {
            .page-shell {
                min-height: auto;
            }

            .grid-host {
                padding: 12px;
            }

            .full-grid {
                min-width: 900px;
            }
        }

        @media (max-width: 768px) {
            .page-head {
                flex-direction: column;
                align-items: stretch;
                padding: 12px;
            }

            .page-head-left,
            .actions {
                width: 100%;
                flex: none;
            }

            .actions {
                justify-content: stretch;
            }

            .actions .input {
                min-width: 100%;
                width: 100%;
                flex: 1 1 100%;
            }

            .actions .btn {
                flex: 1 1 calc(50% - 4px);
                min-width: 140px;
            }

            .grid-host {
                padding: 12px;
            }

            .grid-card {
                min-height: 360px;
                border-radius: 12px;
            }

            .full-grid {
                min-width: 820px;
            }
        }

        @media (max-width: 480px) {
            .page-title {
                font-size: 17px;
            }

            .page-sub {
                font-size: 12px;
            }

            .actions .btn {
                flex: 1 1 100%;
                min-width: 100%;
            }

            .full-grid {
                min-width: 760px;
            }

            .action-cell {
                flex-direction: column;
                align-items: stretch;
            }

            .action-cell .btn {
                width: 100%;
                min-width: 100%;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxManager ID="ram1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="btnSearch">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rgClientsFactures" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rgClientsFactures" />
                    <telerik:AjaxUpdatedControl ControlID="tbSearch" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="rgClientsFactures">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rgClientsFactures" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>

        <PostBackControls>
        </PostBackControls>
    </telerik:RadAjaxManager>

    <telerik:RadWindowManager ID="rwmCustomersInvoices" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

  <%--  <telerik:RadWindow ID="rwCustomerInvoices" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        ClientIDMode="Static"
        DestroyOnClose="true"
       Width="90%"
    Height="90%"
    MinWidth="320px"
    MinHeight="420px"
        Title="Ajouter / Modifier un facture client"
        OnClientClose="rwCustomerInvoice_OnClientClose">
    </telerik:RadWindow>--%>

    <div class="page-shell">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Facture Client</div>
                <div class="page-sub">Liste des factures client</div>
            </div>

            <div class="actions">
                <asp:Button ID="btnAddCustomerInvoice" runat="server"
                    CssClass="btn primary"
                    Text="Ajouter Facture"
                    CausesValidation="false"
                    OnClientClick="openCustomerInvoiceWindow(0); return false;" />

                <asp:TextBox ID="tbSearch" runat="server"
                    CssClass="input"
                    placeholder="Rechercher (nom, email, téléphone…)" />

                <asp:Button ID="btnSearch" runat="server"
                    CssClass="btn"
                    Text="Rechercher" />

                <asp:Button ID="btnClear" runat="server"
                    CssClass="btn"
                    Text="Effacer"
                    CausesValidation="false" />
            </div>
        </div>

        <div class="grid-host">
            <div class="grid-card">
                <div class="grid-scroll">

                    <telerik:RadGrid ID="rgClientsFactures" runat="server"
                        Skin="Metro"
                        CssClass="full-grid"
                        AutoGenerateColumns="False"
                        ClientIDMode="Static"
                        AllowPaging="false"
                        PageSize="25"
                        AllowSorting="True"
                        Height="100%">

                        <ClientSettings AllowColumnsReorder="True" ReorderColumnsOnClient="True">
                            <Selecting AllowRowSelect="True" />
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

                                <telerik:GridTemplateColumn HeaderStyle-Width="220px" HeaderText="Actions" UniqueName="Actions" AllowFiltering="False">
                                    <ItemTemplate>
                                        <div class="action-cell">
                                           
                                            <telerik:RadLinkButton ID="RadLinkButton1"
                                                runat="server" Text="RadLinkButton" 
                                                NavigateUrl='<%# Eval("Id", "~/wbfInvoiceEdit.aspx?InvoiceId={0}") %>'>
                                                 

                                            </telerik:RadLinkButton>
                                            <asp:Button ID="btnDelete" runat="server" CssClass="btn" Text="Delete"
                                                CommandName="DeleteInvoice" CommandArgument='<%# Eval("Id") %>' />
                                        </div>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>

                                <telerik:GridBoundColumn DataField="DocumentNumber" HeaderStyle-Width="180px" HeaderText="Number" UniqueName="DocumentNumber" />
                                <telerik:GridBoundColumn DataField="Name" HeaderText="Supplier" UniqueName="Name" />
                                <telerik:GridBoundColumn DataField="Total" HeaderStyle-Width="140px" DataFormatString="{0:C2}" HeaderText="Total" UniqueName="Total" HeaderStyle-HorizontalAlign="Right" ItemStyle-HorizontalAlign="Right" />
                                <telerik:GridBoundColumn DataField="Status" HeaderStyle-Width="100px" HeaderText="Status" UniqueName="Status" />
                                <telerik:GridDateTimeColumn DataField="DocumentDate" HeaderStyle-Width="130px" HeaderText="Date" UniqueName="DocumentDate"
                                    DataFormatString="{0:yyyy-MM-dd}" />

                            </Columns>
                        </MasterTableView>

                    </telerik:RadGrid>

                </div>
            </div>
        </div>

    </div>
    <script type="text/javascript">
        //function sizeCustomerInvoiceWindow(wnd) {
        //    var vw = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
        //    var vh = Math.max(document.documentElement.clientHeight || 0, window.innerHeight || 0);

        //    if (vw <= 768) {
        //        wnd.set_width(Math.floor(vw * 0.96));
        //        wnd.set_height(Math.floor(vh * 0.92));
        //    } else if (vw <= 1200) {
        //        wnd.set_width(Math.floor(vw * 0.92));
        //        wnd.set_height(Math.floor(vh * 0.90));
        //    } else {
        //        wnd.set_width(1100);
        //        wnd.set_height(Math.floor(vh * 0.90));
        //    }

        //    wnd.center();
        //}

        //function openCustomerInvoiceWindow(id) {
        //    var wnd = $find("rwCustomerInvoices");
        //    var url = "wbfInvoiceEdit.aspx";

        //    if (id && id > 0) {
        //        url += "?InvoiceId=" + id;
        //        wnd.set_title("Modifier une facture client");
        //    } else {
        //        url += "?InvoiceId=0";
        //        wnd.set_title("Ajouter une facture client");
        //    }

        //    wnd.setUrl(url);
        //    sizeCustomerInvoiceWindow(wnd);
        //    wnd.show();
        //}

        //function rwCustomerInvoice_OnClientClose(sender, args) {
        //    var grid = $find("rgClientsFactures");
        //    if (grid) {
        //        grid.get_masterTableView().rebind();
        //    }
        //}

        //window.addEventListener("resize", function () {
        //    var wnd = $find("rwCustomerInvoices");
        //    if (wnd && wnd.isVisible()) {
        //        sizeCustomerInvoiceWindow(wnd);
        //    }
        //});
    </script>

</asp:Content>