<%@ Page Title="Diagnostic Connexions Plaid" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" MaintainScrollPositionOnPostback="true"
    CodeBehind="wbfPlaidDiagnostic.aspx.vb" Inherits="prjSec60Admin.wbfPlaidDiagnostic" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Diagnostic Connexions Plaid — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pld-wrap {
            padding: 20px;
            font-family: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            color: #1e293b;
        }
        .pld-wrap { --plaid:#111827; --blue-600:#2563eb; --slate-50:#f8fafc; --slate-100:#f1f5f9; --slate-200:#e2e8f0;
            --slate-500:#64748b; --slate-600:#475569; --slate-700:#334155; --slate-800:#1e293b; --slate-900:#0f172a;
            --green-500:#10b981; --green-600:#059669; --red-500:#ef4444; --red-600:#dc2626;
            --amber-500:#f59e0b; --amber-100:#fef3c7; }

        .pld-wrap .layout { max-width: 1280px; margin: 0 auto; }

        .pld-wrap .page-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; flex-wrap:wrap; gap:12px; }
        .pld-wrap .page-title { font-size:22px; font-weight:900; color:var(--slate-900); display:flex; align-items:center; gap:10px; }
        .pld-wrap .page-subtitle { font-size:13px; color:var(--slate-500); margin-top:2px; }

        .pld-wrap .stats-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(160px, 1fr)); gap:12px; margin-bottom:18px; }
        .pld-wrap .stat-card { background:#fff; border-radius:12px; padding:16px 18px; border:1px solid var(--slate-200); }
        .pld-wrap .stat-card.total { border-left:4px solid var(--green-500); }
        .pld-wrap .stat-card.items { border-left:4px solid var(--blue-600); }
        .pld-wrap .stat-card.errors { border-left:4px solid var(--red-500); }
        .pld-wrap .stat-card.neutral { border-left:4px solid var(--slate-500); }
        .pld-wrap .stat-label { font-size:11px; font-weight:800; color:var(--slate-500); text-transform:uppercase; letter-spacing:.05em; margin-bottom:6px; }
        .pld-wrap .stat-value { font-size:28px; font-weight:900; color:var(--slate-900); line-height:1; }
        .pld-wrap .stat-sub { font-size:11px; color:var(--slate-500); margin-top:4px; }

        .pld-wrap .filter-bar { background:#fff; border-radius:12px; padding:14px 18px; display:flex; gap:12px; flex-wrap:wrap; align-items:end; border:1px solid var(--slate-200); margin-bottom:18px; }
        .pld-wrap .filter-group { display:flex; flex-direction:column; gap:4px; }
        .pld-wrap .filter-group label { font-size:11px; font-weight:700; color:var(--slate-600); text-transform:uppercase; letter-spacing:.04em; }
        .pld-wrap .filter-group select, .pld-wrap .filter-group input { padding:8px 10px; border:1px solid var(--slate-200); border-radius:8px; font-size:13px; min-width:140px; }
        .pld-wrap .btn { padding:9px 18px; background:var(--blue-600); color:#fff; border:none; border-radius:8px; font-size:13px; font-weight:700; cursor:pointer; }
        .pld-wrap .btn:hover { background:#1d4ed8; }
        .pld-wrap .btn-secondary { background:var(--slate-50); color:var(--slate-700); border:1px solid var(--slate-200); }
        .pld-wrap .btn-secondary:hover { background:#fff; }

        .pld-wrap .section-title { font-size:14px; font-weight:900; color:var(--slate-800); margin:6px 2px 10px; display:flex; align-items:center; gap:8px; }

        .pld-wrap .events-list { display:flex; flex-direction:column; gap:10px; }
        .pld-wrap .event-card { background:#fff; border-radius:12px; border:1px solid var(--slate-200); overflow:hidden; }
        .pld-wrap .event-card.active { border-left:4px solid var(--green-500); }
        .pld-wrap .event-card.inactive { border-left:4px solid var(--slate-500); }
        .pld-wrap .event-header { display:grid; grid-template-columns:1fr auto auto auto; gap:12px; align-items:center; padding:12px 16px; font-size:13px; }
        @media (max-width:768px) { .pld-wrap .event-header { grid-template-columns:1fr; } }
        .pld-wrap .event-type { font-weight:800; color:var(--slate-800); }
        .pld-wrap .event-id { font-family:monospace; font-size:11px; color:var(--slate-500); word-break:break-all; }
        .pld-wrap .event-meta { font-size:11px; color:var(--slate-500); display:flex; gap:10px; flex-wrap:wrap; }
        .pld-wrap .event-amount { font-weight:800; color:var(--slate-900); font-size:14px; white-space:nowrap; }
        .pld-wrap .event-status { display:inline-block; padding:4px 10px; border-radius:999px; font-size:11px; font-weight:800; text-transform:uppercase; letter-spacing:.04em; }
        .pld-wrap .event-status.active { background:rgba(16,185,129,.12); color:var(--green-600); }
        .pld-wrap .event-status.inactive { background:var(--slate-100); color:var(--slate-700); }
        .pld-wrap .btn-toggle { background:transparent; border:1px solid var(--slate-200); border-radius:6px; padding:4px 10px; font-size:11px; cursor:pointer; color:var(--slate-600); }
        .pld-wrap .btn-toggle:hover { background:var(--slate-50); }
        .pld-wrap .event-details { display:none; padding:12px 16px; background:var(--slate-50); border-top:1px solid var(--slate-200); font-size:12px; }
        .pld-wrap .event-card.expanded .event-details { display:block; }
        .pld-wrap .detail-row { display:flex; gap:8px; padding:4px 0; font-size:12px; }
        .pld-wrap .detail-row .lbl { color:var(--slate-500); min-width:150px; font-weight:700; }
        .pld-wrap .detail-row .val { color:var(--slate-800); word-break:break-all; }
        .pld-wrap .error-box { background:rgba(239,68,68,.06); border:1px solid rgba(239,68,68,.2); border-radius:8px; padding:10px 12px; margin:10px 0; color:var(--red-600); font-family:monospace; font-size:11px; white-space:pre-wrap; }
        .pld-wrap .payload-box { background:#1e293b; color:#e2e8f0; border-radius:8px; padding:12px; margin-top:8px; max-height:400px; overflow:auto; font-family:'Consolas','Monaco',monospace; font-size:11px; line-height:1.5; white-space:pre-wrap; word-break:break-all; }
        .pld-wrap .empty-state { background:#fff; border-radius:12px; padding:36px 24px; text-align:center; color:var(--slate-500); font-size:14px; }

        .pld-wrap .log-list { display:flex; flex-direction:column; gap:8px; margin-top:6px; }
        .pld-wrap .log-item { background:#fff; border:1px solid var(--slate-200); border-left:4px solid var(--red-500); border-radius:10px; padding:10px 14px; }
        .pld-wrap .log-head { display:flex; gap:12px; justify-content:space-between; font-size:12px; color:var(--slate-500); flex-wrap:wrap; }
        .pld-wrap .log-msg { font-family:monospace; font-size:12px; color:var(--slate-800); margin-top:6px; white-space:pre-wrap; word-break:break-word; }
        .pld-wrap .section-sep { height:22px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pld-wrap">
        <div class="layout">

            <div class="page-header">
                <div>
                    <div class="page-title">🏦 Diagnostic Connexions Plaid</div>
                    <div class="page-subtitle">Santé des connexions bancaires (items/comptes) et journal de synchronisation</div>
                </div>
                <div style="display:flex; gap:8px;">
                    <asp:HyperLink ID="lnkPlaidDashboard" runat="server"
                        NavigateUrl="https://dashboard.plaid.com"
                        Target="_blank"
                        CssClass="btn btn-secondary">
                        Dashboard Plaid ↗
                    </asp:HyperLink>
                    <asp:Button ID="btnRefresh" runat="server"
                        Text="🔄 Actualiser"
                        CssClass="btn"
                        CausesValidation="false" />
                </div>
            </div>

            <%-- STATS --%>
            <div class="stats-grid">
                <div class="stat-card total">
                    <div class="stat-label">Comptes actifs</div>
                    <div class="stat-value"><asp:Literal ID="litActiveAccounts" runat="server" Text="0" /></div>
                    <div class="stat-sub"><asp:Literal ID="litTotalAccounts" runat="server" Text="" /></div>
                </div>
                <div class="stat-card items">
                    <div class="stat-label">Connexions (items)</div>
                    <div class="stat-value"><asp:Literal ID="litItems" runat="server" Text="0" /></div>
                    <div class="stat-sub">Items Plaid actifs</div>
                </div>
                <div class="stat-card neutral">
                    <div class="stat-label">Compagnies</div>
                    <div class="stat-value"><asp:Literal ID="litCompanies" runat="server" Text="0" /></div>
                    <div class="stat-sub">Connectées</div>
                </div>
                <div class="stat-card neutral">
                    <div class="stat-label">Institutions</div>
                    <div class="stat-value"><asp:Literal ID="litBanks" runat="server" Text="0" /></div>
                    <div class="stat-sub">Banques distinctes</div>
                </div>
                <div class="stat-card errors">
                    <div class="stat-label">Erreurs</div>
                    <div class="stat-value"><asp:Literal ID="litErrors" runat="server" Text="0" /></div>
                    <div class="stat-sub">Sur la période</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Dernier solde MAJ</div>
                    <div class="stat-value" style="font-size:14px; padding-top:8px;">
                        <asp:Literal ID="litLastBalance" runat="server" Text="—" />
                    </div>
                </div>
            </div>

            <%-- FILTRES --%>
            <div class="filter-bar">
                <div class="filter-group">
                    <label>Statut</label>
                    <asp:DropDownList ID="ddlStatus" runat="server" AutoPostBack="false">
                        <asp:ListItem Value="all" Text="Tous" Selected="True" />
                        <asp:ListItem Value="active" Text="Actifs" />
                        <asp:ListItem Value="inactive" Text="Inactifs" />
                    </asp:DropDownList>
                </div>
                <div class="filter-group">
                    <label>Recherche</label>
                    <asp:TextBox ID="txtSearch" runat="server" placeholder="Banque, compte, itemId…" />
                </div>
                <div class="filter-group">
                    <label>Période (erreurs)</label>
                    <asp:DropDownList ID="ddlSince" runat="server">
                        <asp:ListItem Value="24" Text="Dernières 24h" />
                        <asp:ListItem Value="168" Text="7 derniers jours" Selected="True" />
                        <asp:ListItem Value="720" Text="30 derniers jours" />
                        <asp:ListItem Value="2160" Text="90 derniers jours" />
                    </asp:DropDownList>
                </div>
                <div class="filter-group">
                    <label>&nbsp;</label>
                    <asp:Button ID="btnApply" runat="server"
                        Text="Appliquer filtres"
                        CssClass="btn"
                        CausesValidation="false" />
                </div>
            </div>

            <%-- COMPTES CONNECTÉS --%>
            <div class="section-title">🔗 Comptes connectés</div>
            <div class="events-list">
                <asp:Literal ID="litAccounts" runat="server" />
            </div>
            <asp:Panel ID="pnlAccountsEmpty" runat="server" Visible="false" CssClass="empty-state">
                Aucun compte Plaid connecté pour ces filtres.
            </asp:Panel>

            <div class="section-sep"></div>

            <%-- JOURNAL DE SYNCHRO --%>
            <div class="section-title">⚠️ Journal de synchronisation (erreurs)</div>
            <div class="log-list">
                <asp:Literal ID="litSyncLog" runat="server" />
            </div>
            <asp:Panel ID="pnlLogEmpty" runat="server" Visible="false" CssClass="empty-state">
                Aucune erreur de synchronisation sur la période.
            </asp:Panel>

        </div>
    </div>

    <script type="text/javascript">
        function toggleDetails(rowId) {
            var card = document.getElementById('acct-' + rowId);
            if (card) { card.classList.toggle('expanded'); }
        }

        function formatJson(json) {
            try { return JSON.stringify(JSON.parse(json), null, 2); } catch (e) { return json; }
        }

        document.addEventListener('DOMContentLoaded', function () {
            document.querySelectorAll('.payload-box').forEach(function (p) {
                p.textContent = formatJson(p.textContent);
            });
        });
    </script>
</asp:Content>
