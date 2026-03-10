<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfCustomers.aspx.vb" Inherits="MngConsul.wbfCustomers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — MngConsul
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
            gap: 12px;
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
            flex: 1 1 520px;
            justify-content: flex-end;
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

        .customer-list-wrap {
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
            padding: 16px;
        }

        .customer-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .customer-list-item {
            display: block;
            width: 100%;
        }

        .customer-item {
            display: flex;
            flex-direction: column;
            gap: 12px;
            width: 100%;
            box-sizing: border-box;
            border: 1px solid var(--mc-stroke);
            border-radius: 14px;
            background: #fff;
            padding: 14px;
        }

        .customer-top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .customer-main {
            min-width: 220px;
            flex: 1 1 320px;
        }

        .customer-name {
            font-size: 16px;
            font-weight: 900;
            color: var(--mc-text, #0f172a);
            line-height: 1.2;
        }

        .customer-sub {
            margin-top: 4px;
            color: var(--mc-muted);
            font-size: 14px;
            white-space: pre-line;
        }

        .customer-meta {
            display: grid;
            grid-template-columns: repeat(2, minmax(160px, 1fr));
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

        .customer-actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .customer-actions .btn {
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

            .customer-list-wrap {
                padding: 12px;
            }

            .customer-meta {
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

            .customer-actions {
                flex-direction: column;
            }

            .customer-actions .btn {
                width: 100%;
                min-width: 100%;
            }
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

    <div class="page-shell">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Clients</div>
                <div class="page-sub">Liste des clients</div>
            </div>

            <div class="actions">
                <asp:Button ID="btnAddCustomer" runat="server"
                    CssClass="btn primary"
                    Text="Ajouter Client"
                    CausesValidation="false"
                    OnClientClick="openCustomerWindow(0); return false;" />

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

                <telerik:RadListView ID="rlvClients" runat="server"
                    AllowPaging="True"
                    DataKeyNames="Id"
                    ItemPlaceholderID="itemPlaceholder">

                    <LayoutTemplate>
                        <div class="customer-list-wrap">
                            <div class="customer-list">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                       
                            <div class="customer-item">

                                

                                <div class="customer-meta">
                                    <div class="meta-box">
                                        <div class="meta-label">Nom</div>
                                        <div class="meta-value"><%# Eval("NameAllAdddress") %></div>
                                    </div>

                                    <div class="meta-box">
                                        <div class="meta-label">Créé le</div>
                                        <div class="meta-value"><%# Eval("Created", "{0:yyyy-MM-dd}") %></div>
                                    </div>
                                </div>

                                <div class="customer-actions">
                                    <asp:Button ID="btnEdit" runat="server"
                                        CssClass="btn"
                                        Text="Edit"
                                        OnClientClick='<%# "openCustomerWindow(" & Eval("Id") & "); return false;" %>' />

                                    <asp:Button ID="btnDelete" runat="server"
                                        CssClass="btn"
                                        Text="Delete"
                                        CommandName="DeleteClient"
                                        CommandArgument='<%# Eval("Id") %>' />
                                </div>

                            </div>
                        
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="empty-state">
                            Aucun client trouvé.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

    </div>

    <script type="text/javascript">
        function openCustomerWindow(id) {
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
            __doPostBack("<%= rlvClients.UniqueID %>", "");
        }
    </script>
</asp:Content>