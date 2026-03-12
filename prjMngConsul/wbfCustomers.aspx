<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" MaintainScrollPositionOnPostback="true" CodeBehind="wbfCustomers.aspx.vb" Inherits="MngConsul.wbfCustomers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Clients — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* =========================
           MODAL JSON
        ========================= */
        .json-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, .45);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 99999;
        }

        .json-modal-box {
            width: min(1000px, 92vw);
            max-height: 85vh;
            background: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            box-shadow: 0 30px 80px rgba(0,0,0,.25);
            border: 1px solid rgba(0,0,0,.10);
        }

        .json-modal-header {
            padding: 14px 18px;
            background: #f8fafc;
            color: #0f172a;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 800;
            border-bottom: 1px solid rgba(0,0,0,.10);
        }

        .json-modal-close {
            border: 1px solid rgba(0,0,0,.14);
            background: #ffffff;
            color: #0f172a;
            font-size: 14px;
            cursor: pointer;
            border-radius: 10px;
            padding: 6px 10px;
            font-weight: 800;
        }

        .json-modal-close:hover {
            background: #f1f5f9;
        }

        .json-modal-content {
            flex: 1;
            overflow: auto;
            padding: 18px;
            font-family: Consolas, ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
            font-size: 13px;
            color: #0f172a;
            background: #ffffff;
            white-space: pre-wrap;
            word-break: break-word;
        }

        /* =========================
           PAGE
        ========================= */
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
            flex: 0 1 auto;
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

        .searchbox {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: flex-end;
            flex: 1 1 620px;
        }

        .searchbox .input,
        .searchbox input[type="text"] {
            min-width: 280px;
            flex: 1 1 320px;
        }

        .searchbox .btn,
        .searchbox input[type="submit"],
        .searchbox input[type="button"] {
            white-space: nowrap;
        }

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .full-grid {
            height: calc(100vh - 220px);
            min-height: 420px;
        }

        .list-shell {
            height: 100%;
            padding: 16px;
            box-sizing: border-box;
        }

        /* =========================
           BOUTONS
        ========================= */
        .grid .btn,
        .RadGrid .btn,
        .RadGrid input[type=submit],
        .RadGrid input[type=button],
        .listview-actions .btn,
        .listview-actions input[type=submit],
        .listview-actions input[type=button] {
            border-radius: 10px !important;
        }

        .btn:disabled,
        .btn[disabled],
        .RadGrid .btn:disabled,
        .RadGrid input[type=submit]:disabled,
        .RadGrid input[type=button]:disabled {
            background: #e5e7eb !important;
            color: #9ca3af !important;
            border-color: #d1d5db !important;
            cursor: not-allowed !important;
            opacity: .75;
            box-shadow: none !important;
            transform: none !important;
        }

        .btn:disabled:hover {
            background: #e5e7eb !important;
        }

        /* =========================
           LISTVIEW
        ========================= */
        .listview-list {
            height: 100%;
            display: flex;
            flex-direction: column;
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .06);
        }

        .listview-list-head {
            display: grid;
            grid-template-columns: minmax(280px, 1.7fr) 180px minmax(320px, 1fr);
            gap: 16px;
            padding: 14px 16px;
            font-weight: 800;
            font-size: 13px;
            color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky;
            top: 0;
            z-index: 2;
            box-sizing: border-box;
        }

        .listview-list-body {
            flex: 1 1 auto;
            min-height: 0;
            overflow: auto;
        }

        .listview-row {
            display: grid;
            grid-template-columns: minmax(280px, 1.7fr) 180px minmax(320px, 1fr);
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .listview-row:hover {
            background: #fafcff;
        }

      

        .listview-actions {
            display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: flex-end;  /* ← changer flex-start pour flex-end */
    align-items: center;
        }

        .listview-empty {
            padding: 24px;
            text-align: center;
            color: #64748b;
        }

        /* =========================
           PETIT DESKTOP
        ========================= */
        @media (max-width: 1200px) {
            .listview-list-head,
            .listview-row {
                grid-template-columns: minmax(220px, 1.5fr) 150px minmax(240px, 1fr);
                gap: 12px;
            }

            .full-grid {
                height: calc(100vh - 210px);
            }

            .list-shell {
                padding: 14px;
            }
        }

        /* =========================
           TABLETTE
        ========================= */
        @media (min-width: 769px) and (max-width: 1024px)  {
            .page-head {
                padding: 12px 14px;
            }

            .searchbox {
                width: 100%;
                justify-content: flex-start;
            }

            .searchbox .input,
            .searchbox input[type="text"] {
                min-width: 220px;
                flex: 1 1 260px;
            }

            .full-grid {
                height: calc(100vh - 205px);
                min-height: 360px;
            }

            .list-shell {
                padding: 12px;
            }

            .listview-list {
                border-radius: 14px;
            }

            .listview-list-head,
            .listview-row {
                grid-template-columns: minmax(180px, 1.4fr) 130px minmax(220px, 1fr);
                gap: 12px;
                padding: 12px 14px;
            }
        }

        /* =========================
           MOBILE LARGE
        ========================= */
        @media (min-width: 481px) and (max-width: 768px) {
            .json-modal-box {
                width: 96vw;
                max-height: 92vh;
                border-radius: 14px;
            }

            .json-modal-header {
                padding: 12px 14px;
                font-size: 14px;
            }

            .json-modal-content {
                padding: 14px;
                font-size: 12px;
            }

            .page-head {
                flex-direction: column;
                align-items: stretch;
                padding: 12px;
            }

            .page-head-left {
                width: 100%;
            }

            .searchbox {
                width: 100%;
                flex: none;
                justify-content: stretch;
            }

            .searchbox .input,
            .searchbox input[type="text"] {
                min-width: 100%;
                width: 100%;
                flex: 1 1 100%;
            }

            .searchbox .btn,
            .searchbox input[type="submit"],
            .searchbox input[type="button"] {
                flex: 1 1 calc(50% - 4px);
                min-width: 140px;
            }

            .full-grid {
                height: auto;
                min-height: 0;
            }

            .list-shell {
                height: auto;
                padding: 12px;
            }

            .listview-list {
                height: auto;
                min-height: 0;
                border-radius: 12px;
            }

            .listview-list-head {
                display: none;
            }

            .listview-list-body {
                overflow: visible;
            }

            .listview-row {
                grid-template-columns: 1fr;
                gap: 10px;
                padding: 14px;
            }

            .listview-file {
                order: 1;
            }

            .listview-status {
                order: 2;
                font-size: 13px;
            }

            .listview-status::before {
                content: "Créé : ";
                font-weight: 800;
                color: #0f172a;
            }

            .listview-actions {
                order: 3;
                margin-top: 4px;
            }
        }

        /* =========================
           PETIT MOBILE
        ========================= */
        @media (max-width: 480px) {
            .page-title {
                font-size: 17px;
            }

            .page-sub {
                font-size: 12px;
            }

            .searchbox .btn,
            .searchbox input[type="submit"],
            .searchbox input[type="button"] {
                flex: 1 1 100%;
                min-width: 100%;
            }

            .listview-row {
                padding: 12px;
            }

            .listview-actions {
                flex-direction: column;
                align-items: stretch;
            }

            .listview-actions .btn,
            .listview-actions input[type="submit"],
            .listview-actions input[type="button"] {
                width: 100%;
            }

            .json-modal-box {
                width: 100vw;
                height: 100vh;
                max-height: 100vh;
                border-radius: 0;
            }
        }
    </style>

    

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadWindowManager ID="rwmCustomers" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title">Clients</div>
                <div class="page-sub">Liste des clients</div>
            </div>

            <div class="searchbox">
                <asp:Button ID="btnAddCustomer" runat="server"
                    CssClass="btn"
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

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvClients" runat="server"
                    Skin="Metro"
                    DataKeyNames="Id"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div class="col-file">Nom</div>
                                <div class="col-status">Créé</div>
                                <div class="col-actions">Action</div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">
                            <div class="listview-file">
                                <%# Eval("NameAllAdddress") %>
                            </div>

                            <div class="listview-status">
                                <%# Eval("Created", "{0:yyyy-MM-dd}") %>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn"
                                    Text="Edit"
                                    CausesValidation="false"
                                    OnClientClick='<%# "openCustomerWindow(" & Eval("Id") & "); return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn"
                                    Text="Delete"
                                    CommandName="DeleteClient"
                                    CommandArgument='<%# Eval("Id") %>'
                                    CausesValidation="false" />
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            Aucun client trouvé.
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

    </telerik:RadAjaxPanel>

    <telerik:RadWindow ID="rwCustomer" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        Title="Ajouter / Modifier un Client"
        OnClientClose="rwCustomer_OnClientClose"
        ClientIDMode="Static">
    </telerik:RadWindow>

    <script type="text/javascript">
        function openCustomerWindow(id) {
            var wnd = $find("rwCustomer");
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
            __doPostBack("rlvClients", "");
        }
    </script>
</asp:Content>