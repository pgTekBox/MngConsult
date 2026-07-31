<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="PlaidAccounts.aspx.vb"
    Inherits="MngConsul.PlaidAccounts" Async="true" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <script src="js/viewport.js"></script>

    <style>
        /* Wrappers redeviennent flex */
        .field-row1 {
            grid-column: 1;
            grid-row: 1;
            display: flex;
            align-items: center;
            gap: 2px;
            flex-wrap: nowrap;
        }

        .field-row2 {
            grid-column: 1;
            grid-row: 2;
            display: flex;
            align-items: center;
            gap: 2px;
        }


        .listview-list-head {
            display: grid;
            grid-template-columns: minmax(200px, 1.5fr) 140px 100px  80px 80px;
            gap: 16px;
            padding: 14px 16px;
            font-weight: 800;
            font-size: 13px;
            color: #0f172a;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            position: sticky;
            top: 0;
            z-index: 0;
            box-sizing: border-box;
        }

        .listview-row {
            display: grid;
            grid-template-columns: minmax(200px, 1.5fr) 140px 100px  80px  80px;
            gap: 16px;
            align-items: center;
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            background: #fff;
            box-sizing: border-box;
        }

        .field-status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 700;
        }

        .badge-active {
            background: #ecfdf5;
            color: #059669;
        }

        .badge-inactive {
            background: #fef2f2;
            color: #dc2626;
        }

        /* Import panel */
        .import-panel {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: center;
            padding: 14px 16px;
            border-top: 1px solid var(--mc-stroke);
            background: #f8fafc;
        }

            .import-panel label {
                font-weight: 700;
                font-size: 13px;
                color: #0f172a;
            }

            .import-panel .input,
            .import-panel select,
            .import-panel input[type="date"] {
                min-width: 140px;
            }

        .import-result {
            padding: 10px 16px;
            font-size: 13px;
            font-weight: 600;
        }

        .text-success {
            color: #059669;
        }

        .text-danger {
            color: #dc2626;
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <div class="page-head">
            <div class="page-head-left">
                <div class="page-title"><asp:Literal ID="litPageTitle" runat="server" /></div>
            </div>

            <div class="searchbox">
                <asp:Button ID="btnConnect" runat="server"
                    CssClass="btn btnAddRow"
                    Text=""
                    CausesValidation="false"
                    OnClientClick="openPlaidFromPage(); return false;" />
            </div>
        </div>

        <div class="full-grid">
            <div class="list-shell">

                <telerik:RadListView ID="rlvAccounts" runat="server"
                    Skin="Metro"
                    DataKeyNames="ItemId"
                    AllowPaging="false"
                    ItemPlaceholderID="itemPlaceholder"
                    ClientIDMode="Static">

                    <LayoutTemplate>
                        <div class="listview-list">
                            <div class="listview-list-head">
                                <div><asp:Literal ID="litColBank" runat="server" /></div>
                                <div><asp:Literal ID="litColBalance" runat="server" /></div>
                                <div><asp:Literal ID="litColDate" runat="server" /></div>
                                <div><asp:Literal ID="litColStatus" runat="server" /></div>
                                <div><asp:Literal ID="litColAction" runat="server" /></div>
                            </div>

                            <div class="listview-list-body">
                                <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                            </div>

                            <%-- Panel d'import en bas de la liste --%>
                            <div class="import-panel">
                                <label><asp:Literal ID="litLblAccount" runat="server" /></label>
                                <asp:DropDownList ID="ddlAccount" runat="server" CssClass="input"></asp:DropDownList>

                                <label><asp:Literal ID="litLblFrom" runat="server" /></label>
                                <asp:TextBox ID="txtStartDate" runat="server" CssClass="input" TextMode="Date"></asp:TextBox>

                                <label><asp:Literal ID="litLblTo" runat="server" /></label>
                                <asp:TextBox ID="txtEndDate" runat="server" CssClass="input" TextMode="Date"></asp:TextBox>

                                <asp:Button ID="btnImport" runat="server"
                                    CssClass="btn"
                                    Text=""
                                    CausesValidation="false" />
                            </div>

                            <asp:Label ID="lblResult" runat="server" CssClass="import-result" Visible="false"></asp:Label>
                        </div>
                    </LayoutTemplate>

                    <ItemTemplate>
                        <div class="listview-row">

                            
                                <div class="field-bank">
                                    <%# Eval("BankName") %> — <%# Eval("AccountName") %> <%# Eval("AccountNumber") %>
                                </div>
                          
                                <div class="field-date">
                                       <span class="field-total"><%# Eval("BalanceCurrent", "{0:C2}") %></span>
                               </div>
                           
                               
                                <div class="field-date">
                                    <%# Format(Eval("Created"), "yyyy-MM-dd") %>
                                </div>

                           

                            <div>
                                <span class='<%# If(CBool(Eval("Active")), "field-status-badge badge-active", "field-status-badge badge-inactive") %>'>
                                    <%# If(CBool(Eval("Active")), L("active"), L("inactive")) %>
                                </span>
                            </div>

                            <div class="listview-actions">
                                <asp:Button ID="btnDisconnect" runat="server"
                                    CssClass="btn btn-icon btn-icon-delete"
                                    Text=""
                                    ToolTip='<%# L("disconnect") %>'
                                    CommandName="Disconnect"
                                    CommandArgument='<%# Eval("ItemId") %>'
                                    Visible='<%# CBool(Eval("Active")) %>'
                                    OnClientClick="return confirm(L_CONFIRM_DISCONNECT);"
                                    CausesValidation="false" />
                            </div>
                        </div>
                    </ItemTemplate>

                    <EmptyDataTemplate>
                        <div class="listview-empty">
                            <asp:Literal ID="litEmpty" runat="server" />
                        </div>
                    </EmptyDataTemplate>

                </telerik:RadListView>

            </div>
        </div>

        <%-- FAB mobile --%>
        <button id="fabAdd" runat="server" class="fab-add" onclick="openPlaidFromPage(); return false;" title="">+</button>

    </telerik:RadAjaxPanel>

    <telerik:RadCodeBlock ID="rcbPlaidJs" runat="server">
        <script type="text/javascript">
            var L_CONFIRM_DISCONNECT = "<%= L("confirmDisconnect") %>";
        </script>
    </telerik:RadCodeBlock>

</asp:Content>
