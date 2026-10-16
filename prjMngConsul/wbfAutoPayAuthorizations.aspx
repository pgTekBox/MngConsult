<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAutoPayAuthorizations.aspx.vb" Inherits="MngConsul.wbfAutoPayAuthorizations" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Autorisations auto-paiement — 60Sec-AI
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
            color: #0E1F3D;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .page-tabs {
            display: flex;
            gap: 6px;
            margin-bottom: 18px;
            border-bottom: 1px solid #D5DDE8;
            padding-bottom: 0;
        }
        .page-tabs a {
            padding: 10px 16px;
            text-decoration: none;
            color: #44536E;
            font-weight: 700;
            font-size: 13px;
            border: none;
            border-bottom: 3px solid transparent;
            transition: color .15s, border-color .15s;
        }
        .page-tabs a:hover { color: #1B4F9C; }
        .page-tabs a.active {
            color: #1B4F9C;
            border-bottom-color: #1B4F9C;
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
            color: #44536E;
            text-transform: uppercase;
            letter-spacing: .08em;
            margin-bottom: 4px;
        }
        .stat-card .stat-value {
            font-size: 22px;
            font-weight: 900;
            color: #0E1F3D;
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
            color: #44536E;
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
            color: #0E1F3D;
        }
        .auth-method {
            font-size: 13px;
            color: #44536E;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .badge-method-card { background: #ede9fe; color: #6d28d9; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }
        .badge-method-acss { background: #D5DDE8; color: #143A73; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }
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
            color: #44536E;
            display: flex;
            gap: 16px;
            margin-top: 6px;
        }
        .auth-stats strong { color: #0E1F3D; font-weight: 800; }

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
            color: #44536E;
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
        /* ── La signature du gabarit « Portail du client » : le titre pose sur le fond,
           les trois pastilles de navigation, les compteurs, les filtres et les cartes
           en blanc arrondi. ── */
        .autopay-page { max-width: none; margin: 0; padding: 0; }
        .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px; }
        .fc-tete .txt { flex: 1 1 260px; }
        .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em; }
        .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D; }
        .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E; }
        .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px; }
        .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px !important; border: 1px solid #AEBBCD !important; border-radius: 999px !important; background: #fff !important; color: #0E1F3D !important; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer; }
        .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 !important; }
        .page-tabs { display: flex; flex-wrap: wrap; gap: 4px; padding: 4px; background: #E8EDF5; border-radius: 999px; border: 0; margin-bottom: 16px; width: max-content; max-width: 100%; }
        .page-tabs a { border: 0; border-radius: 999px; min-height: 36px; padding: 0 14px; display: inline-flex; align-items: center; gap: 6px; color: #0E1F3D; font-size: 14px; font-weight: 700; }
        .page-tabs a:hover { background: rgba(255,255,255,.6); color: #0E1F3D; }
        .page-tabs a.active { background: #fff; color: #0E1F3D; box-shadow: 0 1px 2px rgba(14,31,61,.12); border: 0; }
        .stats-row { gap: 12px; margin-bottom: 16px; }
        .stat-card { border-radius: 22px; box-shadow: none; padding: 14px 16px; }
        .stat-card .stat-label { text-transform: none; letter-spacing: 0; font-size: 14px; font-weight: 700; color: #44536E; }
        .stat-card .stat-value { font-size: 24px; font-weight: 800; color: #0E1F3D; }
        .stat-card.green .stat-value { color: #0F5A3A; }
        .stat-card.amber .stat-value { color: #7A5200; }
        .stat-card.red .stat-value { color: #A3261C; }
        .filter-bar { padding: 16px 18px; border-radius: 24px; background: #fff; margin-bottom: 16px; gap: 10px 16px; align-items: center; }
        .filter-bar label { font-size: 13px; font-weight: 800; color: #5B6B86; display: inline-flex; align-items: center; gap: 8px; }
        .filter-bar select, .filter-bar input[type=date] { min-height: 40px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; font: inherit; font-size: 14px; font-weight: 600; color: #0E1F3D; }
        .filter-bar input[type=submit], .filter-bar input[type=button] { min-height: 40px; padding: 0 18px !important; border-radius: 999px !important; border: 1px solid #1B4F9C !important; background: #1B4F9C !important; color: #fff !important; font-weight: 800; font-size: 14px; font-family: inherit; cursor: pointer; }
        .filter-bar input[type=submit]:hover, .filter-bar input[type=button]:hover { background: #143A73 !important; }
        .auth-card { border-radius: 20px; box-shadow: none; border-left-width: 5px; border-left-color: #43B47A; padding: 16px 20px; }
        .auth-card.revoked { border-left-color: #AEBBCD; }
        .auth-meta { font-size: 13px; color: #44536E; }
        .auth-stats { font-size: 13px; }
        .btn-revoke, input.btn-revoke { min-height: 40px; padding: 0 14px; border-radius: 999px; background: #fff; color: #A3261C; border: 1px solid #F1B9B4; font-size: 14px; font-weight: 800; font-family: inherit; }
        .btn-revoke:hover, input.btn-revoke:hover { background: #FDECEA; color: #A3261C; }
        .empty-state { border-radius: 24px; font-weight: 700; }
        .alert { border-radius: 16px; font-size: 14px; font-weight: 700; }
        .alert.success { background: #E3F3EA; border: 0; color: #0F5A3A; }
        .alert.error { background: #FDECEA; border: 0; color: #A3261C; }
        .history-table { border-radius: 24px; background: #fff; padding: 6px 12px 12px; overflow-x: auto; }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="autopay-page">

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre, le sous-titre. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique">Administration</div>
                <h1>Paiements automatiques fournisseurs</h1>
                <p>Vous autorisez une fois ; vos factures fournisseurs sont payées dans les limites que vous fixez.</p>
            </div>
            <div class="btns">
                <asp:Button ID="btnRefresh" runat="server" Text="Rafraîchir" CssClass="fc-btn" CausesValidation="false" />
            </div>
        </div>

        <div class="page-tabs">
            <a href="wbfAutoPayAuthorizations.aspx" class="active"><i class="ic ic-lock" aria-hidden="true"></i> Autorisations</a>
            <a href="wbfAutoPaySchedule.aspx"><i class="ic ic-calendar" aria-hidden="true"></i> Calendrier (30 j)</a>
            <a href="wbfAutoPayHistory.aspx"><i class="ic ic-scroll" aria-hidden="true"></i> Historique</a>
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
                            <span><i class="ic ic-calendar" aria-hidden="true"></i> <strong><%# Eval("ScheduledCount") %></strong> programmées</span>
                            <span><i class="ic ic-check-circle" aria-hidden="true"></i> <strong><%# Eval("SuccessCount") %></strong> réussies (vie)</span>
                            <span><i class="ic ic-coins" aria-hidden="true"></i> <strong><%# FormatMoneyOrEmpty(Eval("MonthToDateAmount")) %></strong> ce mois</span>
                        </div>
                    </div>
                    <div class="auth-actions">
                        <asp:Button runat="server"
                            CssClass='<%# If(CBool(Eval("IsActive")), "btn-revoke", "btn-revoke btn-disabled") %>'
                            Text="Révoquer"
                            CommandName="Revoke"
                            CommandArgument='<%# Eval("Id") %>'
                            Enabled='<%# CBool(Eval("IsActive")) %>'
                            CausesValidation="false"
                            OnClientClick='<%# "if (!confirm(""Confirmer la révocation de cette autorisation ?\n\nLes paiements programmés pour ce fournisseur seront annulés."")) { return false; }" %>' />
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
