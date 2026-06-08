<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAutoPayHistory.aspx.vb" Inherits="MngConsul.wbfAutoPayHistory" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Historique auto-paiement — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .autopay-page { max-width: 1100px; margin: 0 auto; padding: 16px; }
        .page-title { font-size: 22px; font-weight: 800; margin: 0 0 14px 0; display: flex; gap: 10px; align-items: center; }
        .page-tabs { display: flex; gap: 6px; margin-bottom: 18px; border-bottom: 1px solid #e2e8f0; }
        .page-tabs a {
            padding: 10px 16px; text-decoration: none; color: #64748b;
            font-weight: 700; font-size: 13px; border-bottom: 3px solid transparent;
        }
        .page-tabs a:hover { color: #2563eb; }
        .page-tabs a.active { color: #2563eb; border-bottom-color: #2563eb; }

        .filter-bar {
            display: flex; gap: 12px; align-items: center; margin-bottom: 14px;
            flex-wrap: wrap; background: #fff; padding: 12px 16px; border-radius: 12px;
        }
        .filter-bar label { font-size: 12px; font-weight: 700; color: #475569; }
        .filter-bar select, .filter-bar input[type="date"] {
            padding: 6px 10px; border: 1px solid #e2e8f0; border-radius: 8px;
            font-family: inherit; font-size: 13px;
        }

        .history-table {
            background: #fff; border-radius: 12px; overflow: hidden;
            box-shadow: 0 1px 3px rgba(15,23,42,.05);
        }
        .history-table table { width: 100%; border-collapse: collapse; }
        .history-table th {
            background: #f8fafc; padding: 10px 12px; font-size: 11px;
            font-weight: 800; color: #475569; text-transform: uppercase;
            letter-spacing: .05em; text-align: left; border-bottom: 1px solid #e2e8f0;
        }
        .history-table td {
            padding: 10px 12px; font-size: 13px; border-bottom: 1px solid #f1f5f9;
            vertical-align: top;
        }
        .history-table tr:hover td { background: #f8fafc; }
        .row-success { border-left: 3px solid #10b981; }
        .row-failed { border-left: 3px solid #ef4444; }
        .row-pending, .row-requires_action { border-left: 3px solid #f59e0b; }
        .row-blocked_cap { border-left: 3px solid #94a3b8; }

        .result-badge {
            display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 10px;
            font-weight: 800; text-transform: uppercase; letter-spacing: .05em;
        }
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-failed { background: #fecaca; color: #b91c1c; }
        .badge-pending { background: #fef3c7; color: #92400e; }
        .badge-requires_action { background: #ede9fe; color: #6d28d9; }
        .badge-blocked_cap { background: #e2e8f0; color: #475569; }
        .badge-cancelled { background: #f1f5f9; color: #94a3b8; }

        .mono { font-family: monospace; font-size: 11px; color: #64748b; }

        .empty-state {
            background: #fff; border-radius: 12px; padding: 40px 24px;
            text-align: center; color: #64748b; font-size: 14px;
        }
        .alert {
            padding: 12px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px;
        }
        .alert.error { background: rgba(239,68,68,.08); border: 1px solid rgba(239,68,68,.3); color: #b91c1c; }

        @media (max-width: 768px) {
            .history-table { overflow-x: auto; }
            .history-table table { min-width: 700px; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="autopay-page">

        <h1 class="page-title">📜 Historique des paiements automatiques</h1>

        <div class="page-tabs">
            <a href="wbfAutoPayAuthorizations.aspx">🔐 Autorisations</a>
            <a href="wbfAutoPaySchedule.aspx">📅 Calendrier (30 j)</a>
            <a href="wbfAutoPayHistory.aspx" class="active">📜 Historique</a>
        </div>

        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert error"><asp:Literal ID="litError" runat="server" /></div>
        </asp:Panel>

        <div class="filter-bar">
            <label>Résultat :
                <asp:DropDownList ID="ddlResult" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="" Text="Tous"></asp:ListItem>
                    <asp:ListItem Value="SUCCESS" Text="Succès"></asp:ListItem>
                    <asp:ListItem Value="FAILED" Text="Échec"></asp:ListItem>
                    <asp:ListItem Value="REQUIRES_ACTION" Text="Action requise"></asp:ListItem>
                    <asp:ListItem Value="BLOCKED_CAP" Text="Bloqué (plafond)"></asp:ListItem>
                    <asp:ListItem Value="PENDING" Text="En attente"></asp:ListItem>
                </asp:DropDownList>
            </label>
            <label>Du :
                <asp:TextBox ID="tbFromDate" runat="server" TextMode="Date" />
            </label>
            <label>Au :
                <asp:TextBox ID="tbToDate" runat="server" TextMode="Date" />
            </label>
            <label>Max :
                <asp:DropDownList ID="ddlMaxRows" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="50" Text="50"></asp:ListItem>
                    <asp:ListItem Value="200" Selected="True" Text="200"></asp:ListItem>
                    <asp:ListItem Value="500" Text="500"></asp:ListItem>
                    <asp:ListItem Value="1000" Text="1000"></asp:ListItem>
                </asp:DropDownList>
            </label>
            <asp:Button ID="btnFilter" runat="server" Text="Filtrer"
                CssClass="result-badge badge-success"
                Style="background:#dbeafe; color:#1d4ed8; padding:8px 14px; cursor:pointer; border:none;"
                CausesValidation="false" />
        </div>

        <asp:Panel ID="pnlList" runat="server" CssClass="history-table">
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Fournisseur</th>
                        <th>Facture</th>
                        <th>Montant</th>
                        <th>Méthode</th>
                        <th>Résultat</th>
                        <th>Détails</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptHistory" runat="server">
                        <ItemTemplate>
                            <tr class='<%# "row-" & If(Eval("Result"), "").ToString().ToLower() %>'>
                                <td><%# Eval("AttemptDate", "{0:yyyy-MM-dd HH:mm}") %></td>
                                <td><%# Server.HtmlEncode(If(Eval("PartyName"), "").ToString()) %></td>
                                <td><%# Server.HtmlEncode(If(Eval("DocumentNumber"), Eval("DocumentId").ToString()).ToString()) %></td>
                                <td>
                                    <strong><%# FormatMoney(Eval("Amount")) %></strong>
                                    <div class="mono">+ <%# FormatMoney(Eval("FeeAmount")) %> frais</div>
                                </td>
                                <td><%# RenderMethodSmall(Eval("PaymentMethodType"), Eval("CardBrand"), Eval("CardLast4"), Eval("BankAccountLast4")) %></td>
                                <td>
                                    <span class='result-badge <%# "badge-" & If(Eval("Result"), "").ToString().ToLower() %>'>
                                        <%# Eval("Result") %>
                                    </span>
                                    <div class="mono">Essai #<%# Eval("AttemptNumber") %></div>
                                </td>
                                <td style="max-width:260px;">
                                    <%# RenderDetails(Container.DataItem) %>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </asp:Panel>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
            <p>Aucune tentative trouvée dans la période sélectionnée.</p>
        </asp:Panel>

    </div>
</asp:Content>
