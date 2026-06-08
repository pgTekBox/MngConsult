<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAutoPayAuthorizations.aspx.vb" Inherits="MngConsul.wbfAutoPayAuthorizations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Autorisations auto-paiement — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .autopay-page {
            max-width: 1100px;
            margin: 0 auto;
            padding: 16px;
        }
        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 16px;
            margin-bottom: 16px;
            flex-wrap: wrap;
        }
        .page-title {
            font-size: 22px;
            font-weight: 800;
            color: #0f172a;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .page-tabs {
            display: flex;
            gap: 6px;
            margin-bottom: 18px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 0;
        }
        .page-tabs a {
            padding: 10px 16px;
            text-decoration: none;
            color: #64748b;
            font-weight: 700;
            font-size: 13px;
            border: none;
            border-bottom: 3px solid transparent;
            transition: color .15s, border-color .15s;
        }
        .page-tabs a:hover { color: #2563eb; }
        .page-tabs a.active {
            color: #2563eb;
            border-bottom-color: #2563eb;
        }

        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
            margin-bottom: 18px;
        }
        .stat-card {
            background: #fff;
            border-radius: 12px;
            padding: 14px 16px;
            box-shadow: 0 1px 3px rgba(15,23,42,.05);
        }
        .stat-card .stat-label {
            font-size: 11px;
            font-weight: 800;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: .08em;
            margin-bottom: 4px;
        }
        .stat-card .stat-value {
            font-size: 22px;
            font-weight: 900;
            color: #0f172a;
        }
        .stat-card.green .stat-value { color: #10b981; }
        .stat-card.red .stat-value { color: #ef4444; }
        .stat-card.amber .stat-value { color: #f59e0b; }

        .filter-bar {
            display: flex;
            gap: 10px;
            align-items: center;
            margin-bottom: 14px;
            flex-wrap: wrap;
        }
        .filter-bar label {
            font-size: 12px;
            font-weight: 700;
            color: #475569;
        }
        .filter-bar input[type="checkbox"] { width: 16px; height: 16px; }

        .auth-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .auth-card {
            background: #fff;
            border-radius: 12px;
            padding: 16px 20px;
            box-shadow: 0 1px 3px rgba(15,23,42,.05);
            border-left: 4px solid #10b981;
            display: grid;
            grid-template-columns: 1fr auto;
            gap: 14px;
            align-items: center;
        }
        .auth-card.revoked { border-left-color: #94a3b8; opacity: 0.65; }

        .auth-info { display: flex; flex-direction: column; gap: 4px; }
        .auth-supplier {
            font-size: 16px;
            font-weight: 800;
            color: #0f172a;
        }
        .auth-method {
            font-size: 13px;
            color: #475569;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .badge-method-card { background: #ede9fe; color: #6d28d9; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }
        .badge-method-acss { background: #dbeafe; color: #1d4ed8; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }
        .auth-meta {
            font-size: 11px;
            color: #94a3b8;
            display: flex;
            gap: 12px;
            margin-top: 4px;
            flex-wrap: wrap;
        }
        .auth-stats {
            font-size: 12px;
            color: #475569;
            display: flex;
            gap: 16px;
            margin-top: 6px;
        }
        .auth-stats strong { color: #0f172a; font-weight: 800; }

        .auth-actions {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .btn-revoke {
            padding: 8px 14px;
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
        }
        .btn-revoke:hover { background: #fca5a5; color: #7f1d1d; }
        .btn-disabled { opacity: .5; cursor: not-allowed; }

        .empty-state {
            background: #fff;
            border-radius: 12px;
            padding: 40px 24px;
            text-align: center;
            color: #64748b;
            font-size: 14px;
        }
        .alert {
            padding: 12px 14px;
            border-radius: 10px;
            font-size: 13px;
            margin-bottom: 14px;
        }
        .alert.success { background: rgba(16,185,129,.08); border: 1px solid rgba(16,185,129,.3); color: #047857; }
        .alert.error { background: rgba(239,68,68,.08); border: 1px solid rgba(239,68,68,.3); color: #b91c1c; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="autopay-page">

        <div class="page-header">
            <h1 class="page-title">🤖 Paiements automatiques fournisseurs</h1>
        </div>

        <div class="page-tabs">
            <a href="wbfAutoPayAuthorizations.aspx" class="active">🔐 Autorisations</a>
            <a href="wbfAutoPaySchedule.aspx">📅 Calendrier (30 j)</a>
            <a href="wbfAutoPayHistory.aspx">📜 Historique</a>
        </div>

        <asp:Panel ID="pnlAlert" runat="server" Visible="false">
            <div class="alert success">
                <asp:Literal ID="litAlert" runat="server" />
            </div>
        </asp:Panel>

        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert error">
                <asp:Literal ID="litError" runat="server" />
            </div>
        </asp:Panel>

        <!-- Stats -->
        <div class="stats-row">
            <div class="stat-card">
                <div class="stat-label">Autorisations actives</div>
                <div class="stat-value"><asp:Literal ID="litStatActive" runat="server" Text="0" /></div>
            </div>
            <div class="stat-card amber">
                <div class="stat-label">Programmées</div>
                <div class="stat-value"><asp:Literal ID="litStatScheduled" runat="server" Text="0" /></div>
            </div>
            <div class="stat-card green">
                <div class="stat-label">Réussies (mois)</div>
                <div class="stat-value"><asp:Literal ID="litStatSuccess" runat="server" Text="0" /></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Total cumulé (mois)</div>
                <div class="stat-value"><asp:Literal ID="litStatTotalAmount" runat="server" Text="0,00 $" /></div>
            </div>
        </div>

        <div class="filter-bar">
            <asp:CheckBox ID="chkShowRevoked" runat="server" ClientIDMode="Static" AutoPostBack="true"
                Text=" Inclure les autorisations révoquées" />
            <asp:Button ID="btnRefresh" runat="server" Text="🔄 Rafraîchir"
                CssClass="btn-revoke"
                Style="background:#dbeafe; color:#1d4ed8; border-color:#bfdbfe;"
                CausesValidation="false" />
        </div>

        <asp:Repeater ID="rptAuth" runat="server">
            <HeaderTemplate>
                <div class="auth-list">
            </HeaderTemplate>
            <ItemTemplate>
                <div class='auth-card <%# If(CBool(Eval("IsActive")), "", "revoked") %>'>
                    <div class="auth-info">
                        <div class="auth-supplier">
                            <%# Server.HtmlEncode(If(Eval("PartyName"), "Fournisseur").ToString()) %>
                        </div>
                        <div class="auth-method">
                            <%# RenderMethodBadge(Eval("PaymentMethodType"), Eval("CardBrand"), Eval("CardLast4"), Eval("BankAccountLast4")) %>
                        </div>
                        <div class="auth-meta">
                            <span>Autorisé le <%# Eval("AuthorizedDate", "{0:yyyy-MM-dd HH:mm}") %></span>
                            <span>Par : <%# Server.HtmlEncode(If(Eval("AuthorizedByName"), "").ToString().Trim()) %></span>
                            <%# If(IsDBNull(Eval("MaxAmountPerMonth")) OrElse Eval("MaxAmountPerMonth") Is Nothing, "",
                                    "<span>Plafond mensuel : " & FormatMoneyOrEmpty(Eval("MaxAmountPerMonth")) & "</span>") %>
                            <%# If(CBool(Eval("IsActive")), "",
                                    "<span style='color:#b91c1c; font-weight:700;'>Révoquée le " & FormatDate(Eval("RevokedDate")) & "</span>") %>
                        </div>
                        <div class="auth-stats">
                            <span>📅 <strong><%# Eval("ScheduledCount") %></strong> programmées</span>
                            <span>✅ <strong><%# Eval("SuccessCount") %></strong> réussies (vie)</span>
                            <span>💰 <strong><%# FormatMoneyOrEmpty(Eval("MonthToDateAmount")) %></strong> ce mois</span>
                        </div>
                    </div>
                    <div class="auth-actions">
                        <asp:Button runat="server"
                            CssClass='<%# If(CBool(Eval("IsActive")), "btn-revoke", "btn-revoke btn-disabled") %>'
                            Text="🚫 Révoquer"
                            CommandName="Revoke"
                            CommandArgument='<%# Eval("Id") %>'
                            Enabled='<%# CBool(Eval("IsActive")) %>'
                            CausesValidation="false"
                            OnClientClick='<%# "return confirm(""Confirmer la révocation de cette autorisation ?\n\nLes paiements programmés pour ce fournisseur seront annulés."");" %>' />
                    </div>
                </div>
            </ItemTemplate>
            <FooterTemplate>
                </div>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
            <p>Aucune autorisation d'auto-paiement configurée.</p>
            <small>Lors d'un paiement Stripe sur une facture fournisseur, cochez "Autoriser le paiement automatique" pour activer.</small>
        </asp:Panel>

    </div>
</asp:Content>
