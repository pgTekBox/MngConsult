<%@ Page Title="Diagnostic Webhooks Stripe" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" MaintainScrollPositionOnPostback="true"
    CodeBehind="wbfStripeWebhookDiagnostic.aspx.vb" Inherits="prjSec60Admin.wbfStripeWebhookDiagnostic" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Diagnostic Webhooks Stripe — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .swd-wrap {
            padding: 20px;
            font-family: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            color: #1e293b;
        }
        .swd-wrap { --blue-600:#2563eb; --slate-50:#f8fafc; --slate-100:#f1f5f9; --slate-200:#e2e8f0;
            --slate-500:#64748b; --slate-600:#475569; --slate-700:#334155; --slate-800:#1e293b; --slate-900:#0f172a;
            --green-500:#10b981; --green-600:#059669; --red-500:#ef4444; --red-600:#dc2626;
            --amber-500:#f59e0b; --amber-100:#fef3c7; }

        .swd-wrap .layout { max-width: 1280px; margin: 0 auto; }

        .swd-wrap .page-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; flex-wrap:wrap; gap:12px; }
        .swd-wrap .page-title { font-size:22px; font-weight:900; color:var(--slate-900); display:flex; align-items:center; gap:10px; }
        .swd-wrap .page-subtitle { font-size:13px; color:var(--slate-500); margin-top:2px; }

        .swd-wrap .stats-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(160px, 1fr)); gap:12px; margin-bottom:18px; }
        .swd-wrap .stat-card { background:#fff; border-radius:12px; padding:16px 18px; border:1px solid var(--slate-200); }
        .swd-wrap .stat-card.processed { border-left:4px solid var(--green-500); }
        .swd-wrap .stat-card.failed { border-left:4px solid var(--red-500); }
        .swd-wrap .stat-card.pending { border-left:4px solid var(--amber-500); }
        .swd-wrap .stat-card.skipped { border-left:4px solid var(--slate-500); }
        .swd-wrap .stat-card.total { border-left:4px solid var(--blue-600); }
        .swd-wrap .stat-label { font-size:11px; font-weight:800; color:var(--slate-500); text-transform:uppercase; letter-spacing:.05em; margin-bottom:6px; }
        .swd-wrap .stat-value { font-size:28px; font-weight:900; color:var(--slate-900); line-height:1; }
        .swd-wrap .stat-sub { font-size:11px; color:var(--slate-500); margin-top:4px; }

        .swd-wrap .filter-bar { background:#fff; border-radius:12px; padding:14px 18px; display:flex; gap:12px; flex-wrap:wrap; align-items:end; border:1px solid var(--slate-200); margin-bottom:18px; }
        .swd-wrap .filter-group { display:flex; flex-direction:column; gap:4px; }
        .swd-wrap .filter-group label { font-size:11px; font-weight:700; color:var(--slate-600); text-transform:uppercase; letter-spacing:.04em; }
        .swd-wrap .filter-group select, .swd-wrap .filter-group input { padding:8px 10px; border:1px solid var(--slate-200); border-radius:8px; font-size:13px; min-width:140px; }
        .swd-wrap .btn { padding:9px 18px; background:var(--blue-600); color:#fff; border:none; border-radius:8px; font-size:13px; font-weight:700; cursor:pointer; }
        .swd-wrap .btn:hover { background:#1d4ed8; }
        .swd-wrap .btn-secondary { background:var(--slate-50); color:var(--slate-700); border:1px solid var(--slate-200); }
        .swd-wrap .btn-secondary:hover { background:#fff; }

        .swd-wrap .events-list { display:flex; flex-direction:column; gap:10px; }
        .swd-wrap .event-card { background:#fff; border-radius:12px; border:1px solid var(--slate-200); overflow:hidden; }
        .swd-wrap .event-card.processed { border-left:4px solid var(--green-500); }
        .swd-wrap .event-card.failed { border-left:4px solid var(--red-500); }
        .swd-wrap .event-card.received { border-left:4px solid var(--amber-500); }
        .swd-wrap .event-card.skipped { border-left:4px solid var(--slate-500); }
        .swd-wrap .event-header { display:grid; grid-template-columns:1fr auto auto auto; gap:12px; align-items:center; padding:12px 16px; font-size:13px; }
        @media (max-width:768px) { .swd-wrap .event-header { grid-template-columns:1fr; } }
        .swd-wrap .event-type { font-weight:800; color:var(--slate-800); }
        .swd-wrap .event-id { font-family:monospace; font-size:11px; color:var(--slate-500); word-break:break-all; }
        .swd-wrap .event-meta { font-size:11px; color:var(--slate-500); display:flex; gap:10px; flex-wrap:wrap; }
        .swd-wrap .event-status { display:inline-block; padding:4px 10px; border-radius:999px; font-size:11px; font-weight:800; text-transform:uppercase; letter-spacing:.04em; }
        .swd-wrap .event-status.processed { background:rgba(16,185,129,.12); color:var(--green-600); }
        .swd-wrap .event-status.failed { background:rgba(239,68,68,.12); color:var(--red-600); }
        .swd-wrap .event-status.received { background:var(--amber-100); color:#92400e; }
        .swd-wrap .event-status.skipped { background:var(--slate-100); color:var(--slate-700); }
        .swd-wrap .btn-toggle { background:transparent; border:1px solid var(--slate-200); border-radius:6px; padding:4px 10px; font-size:11px; cursor:pointer; color:var(--slate-600); }
        .swd-wrap .btn-toggle:hover { background:var(--slate-50); }
        .swd-wrap .event-details { display:none; padding:12px 16px; background:var(--slate-50); border-top:1px solid var(--slate-200); font-size:12px; }
        .swd-wrap .event-card.expanded .event-details { display:block; }
        .swd-wrap .detail-row { display:flex; gap:8px; padding:4px 0; font-size:12px; }
        .swd-wrap .detail-row .lbl { color:var(--slate-500); min-width:140px; font-weight:700; }
        .swd-wrap .detail-row .val { color:var(--slate-800); word-break:break-all; }
        .swd-wrap .error-box { background:rgba(239,68,68,.06); border:1px solid rgba(239,68,68,.2); border-radius:8px; padding:10px 12px; margin:10px 0; color:var(--red-600); font-family:monospace; font-size:11px; white-space:pre-wrap; }
        .swd-wrap .payload-box { background:#1e293b; color:#e2e8f0; border-radius:8px; padding:12px; margin-top:8px; max-height:400px; overflow:auto; font-family:'Consolas','Monaco',monospace; font-size:11px; line-height:1.5; white-space:pre-wrap; word-break:break-all; }
        .swd-wrap .empty-state { background:#fff; border-radius:12px; padding:48px 24px; text-align:center; color:var(--slate-500); font-size:14px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="swd-wrap">
        <div class="layout">

            <div class="page-header">
                <div>
                    <div class="page-title">⚙️ Diagnostic Webhooks Stripe</div>
                    <div class="page-subtitle">Surveillance des événements reçus de Stripe et leur traitement</div>
                </div>
                <div style="display:flex; gap:8px;">
                    <asp:HyperLink ID="lnkStripeDashboard" runat="server"
                        NavigateUrl="https://dashboard.stripe.com/test/webhooks"
                        Target="_blank"
                        CssClass="btn btn-secondary">
                        Dashboard Stripe ↗
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
                    <div class="stat-label">Total events</div>
                    <div class="stat-value"><asp:Literal ID="litTotalEvents" runat="server" Text="0" /></div>
                    <div class="stat-sub">Période choisie</div>
                </div>
                <div class="stat-card processed">
                    <div class="stat-label">Traités</div>
                    <div class="stat-value"><asp:Literal ID="litProcessedEvents" runat="server" Text="0" /></div>
                    <div class="stat-sub"><asp:Literal ID="litProcessedPct" runat="server" Text="" /></div>
                </div>
                <div class="stat-card failed">
                    <div class="stat-label">Échoués</div>
                    <div class="stat-value"><asp:Literal ID="litFailedEvents" runat="server" Text="0" /></div>
                    <div class="stat-sub"><asp:Literal ID="litFailedPct" runat="server" Text="" /></div>
                </div>
                <div class="stat-card pending">
                    <div class="stat-label">En cours</div>
                    <div class="stat-value"><asp:Literal ID="litPendingEvents" runat="server" Text="0" /></div>
                </div>
                <div class="stat-card skipped">
                    <div class="stat-label">Ignorés</div>
                    <div class="stat-value"><asp:Literal ID="litSkippedEvents" runat="server" Text="0" /></div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Dernier event</div>
                    <div class="stat-value" style="font-size:14px; padding-top:8px;">
                        <asp:Literal ID="litLastEvent" runat="server" Text="—" />
                    </div>
                </div>
            </div>

            <%-- FILTRES --%>
            <div class="filter-bar">
                <div class="filter-group">
                    <label>Statut</label>
                    <asp:DropDownList ID="ddlStatus" runat="server" AutoPostBack="false">
                        <asp:ListItem Value="all" Text="Tous" Selected="True" />
                        <asp:ListItem Value="processed" Text="Traités" />
                        <asp:ListItem Value="failed" Text="Échoués" />
                        <asp:ListItem Value="received" Text="En cours" />
                        <asp:ListItem Value="skipped" Text="Ignorés" />
                    </asp:DropDownList>
                </div>
                <div class="filter-group">
                    <label>Type d'event</label>
                    <asp:DropDownList ID="ddlEventType" runat="server">
                        <asp:ListItem Value="all" Text="Tous" Selected="True" />
                        <asp:ListItem Value="checkout.session" Text="Checkout sessions" />
                        <asp:ListItem Value="customer.subscription" Text="Subscriptions" />
                        <asp:ListItem Value="invoice" Text="Invoices" />
                        <asp:ListItem Value="payment_intent" Text="Payment intents" />
                        <asp:ListItem Value="account" Text="Comptes connectés" />
                        <asp:ListItem Value="charge" Text="Charges" />
                        <asp:ListItem Value="payout" Text="Payouts" />
                    </asp:DropDownList>
                </div>
                <div class="filter-group">
                    <label>Période</label>
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

            <%-- LISTE DES EVENTS --%>
            <div class="events-list">
                <asp:Literal ID="litEvents" runat="server" />
            </div>

            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
                Aucun événement webhook trouvé pour ces filtres.
            </asp:Panel>

        </div>
    </div>

    <script type="text/javascript">
        function toggleDetails(eventId) {
            var card = document.getElementById('event-' + eventId);
            if (card) {
                card.classList.toggle('expanded');
            }
        }

        function formatJson(json) {
            try {
                var obj = JSON.parse(json);
                return JSON.stringify(obj, null, 2);
            } catch (e) {
                return json;
            }
        }

        // Formatter tous les payloads JSON à l'affichage
        document.addEventListener('DOMContentLoaded', function () {
            var payloads = document.querySelectorAll('.payload-box');
            payloads.forEach(function (p) {
                p.textContent = formatJson(p.textContent);
            });
        });
    </script>
</asp:Content>
