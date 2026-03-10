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

        .list-host {
            flex: 1 1 auto;
            min-height: 0;
            padding: 16px;
        }

        .list-card {
            height: 100%;
            min-height: 420px;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 10px 28px rgba(15, 23, 42, .06);
            display: flex;
            flex-direction: column;
        }

        .invoice-list-wrap {
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
            padding: 16px;
        }

        .invoice-list {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }

        .invoice-item {
            border: 1px solid var(--mc-stroke);
            border-radius: 14px;
            background: #fff;
            padding: 14px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .invoice-top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .invoice-main {
            min-width: 220px;
            flex: 1 1 320px;
        }

        .invoice-number {
            font-size: 16px;
            font-weight: 900;
            color: var(--mc-text, #0f172a);
            line-height: 1.2;
        }

        .invoice-name {
            margin-top: 4px;
            color: var(--mc-muted);
            font-size: 14px;
        }

        .invoice-status {
            display: inline-flex;
            align-items: center;
            padding: 6px 10px;
            border-radius: 999px;
            background: #f8fafc;
            border: 1px solid var(--mc-stroke);
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
        }

        .invoice-meta {
            display: grid;
            grid-template-columns: repeat(3, minmax(140px, 1fr));
            gap: 12px;
        }

        .meta-box {
            border: 1px solid var(--mc-stroke);
            border-radius: 12px;
            padding: 10px 12px;
            background: #f8fafc;
        }

        .meta-label {
            font-size: 11px;
            font-weight: 800;
            color: var(--mc-muted);
            text-transform: uppercase;
            letter-spacing: .04em;
            margin-bottom: 4px;
        }

        .meta-value {
            font-size: 14px;
            font-weight: 700;
            color: var(--mc-text, #0f172a);
        }

        .invoice-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .invoice-actions .btn {
            min-width: 110px;
        }

        .empty-state {
            padding: 28px;
            text-align: center;
            color: var(--mc-muted);
        }

        @media (max-width: 1024px) {
            .page-shell {
                min-height: auto;
            }

            .list-host {
                padding: 12px;
            }

            .invoice-meta {
                grid-template-columns: repeat(2, minmax(140px, 1fr));
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

            .list-host {
                padding: 12px;
            }

            .list-card {
                min-height: 360px;
                border-radius: 12px;
            }

            .invoice-list-wrap {
                padding: 12px;
            }

            .invoice-meta {
                grid-template-columns: 1fr;
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

            .invoice-actions {
                flex-direction: column;
            }

            .invoice-actions .btn {
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
                    <telerik:AjaxUpdatedControl ControlID="rlvClientsFactures" />
                </UpdatedControls>
            </telerik:AjaxSetting>

            <telerik:AjaxSetting AjaxControlID="btnClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvClientsFactures" />
                    <telerik:AjaxUpdatedControl ControlID="tbSearch" />
                </UpdatedControls>
            </telerik:AjaxSetting>

            <telerik:AjaxSetting AjaxControlID="rlvClientsFactures">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rlvClientsFactures" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadWindowManager ID="rwmCustomersInvoices" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

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

        <div class="list-host">
            <div class="list-card">

                <telerik:RadListView ID="rlvClientsFactures" runat="server"
                    AllowPaging="False"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder">

                    <LayoutTemplate>
                        <div class="invoice-list-wrap">
                            <div class="invoice-list">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="invoice-item">

                            <div class="invoice-top">
                                <div class="invoice-main">
                                    <div class="invoice-number">
                                        <%# Eval("DocumentNumber") %>
                                    </div>
                                    <div class="invoice-name">
                                        <%# Eval("Name") %>
                                    </div>
                                </div>

                                <div class="invoice-status">
                                    <%# Eval("Status") %>
                                </div>
                            </div>

                            <div class="invoice-meta">
                                <div class="meta-box">
                                    <div class="meta-label">Numéro</div>
                                    <div class="meta-value"><%# Eval("DocumentNumber") %></div>
                                </div>

                                <div class="meta-box">
                                    <div class="meta-label">Date</div>
                                    <div class="meta-value"><%# Eval("DocumentDate", "{0:yyyy-MM-dd}") %></div>
                                </div>

                                <div class="meta-box">
                                    <div class="meta-label">Total</div>
                                    <div class="meta-value"><%# Eval("Total", "{0:C2}") %></div>
                                </div>
                            </div>

                            <div class="invoice-actions">
                                <telerik:RadLinkButton ID="lnkEdit"
                                    runat="server"
                                    CssClass="btn"
                                    Text="Ouvrir"
                                    NavigateUrl='<%# Eval("Id", "~/wbfInvoiceEdit.aspx?InvoiceId={0}") %>'>
                                </telerik:RadLinkButton>

                                <asp:Button ID="btnDelete"
                                    runat="server"
                                    CssClass="btn"
                                    Text="Delete"
                                    CommandName="DeleteInvoice"
                                    CommandArgument='<%# Eval("Id") %>' />
                            </div>

                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="empty-state">
                            Aucune facture trouvée.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

    </div>

    <script type="text/javascript">
</script>

</asp:Content>