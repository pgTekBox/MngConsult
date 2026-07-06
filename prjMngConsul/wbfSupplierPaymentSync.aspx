<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfSupplierPaymentSync.aspx.vb" Inherits="MngConsul.wbfSupplierPaymentSync" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Synchroniser paiements Stripe — 60Sec-AI</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc; --slate-100: #f1f5f9;
            --slate-200: #e2e8f0;
            --slate-500: #64748b; --slate-600: #475569;
            --slate-700: #334155; --slate-800: #1e293b;
            --blue-600: #2563eb; --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444; --amber-500: #f59e0b;
            --purple-500: #635BFF;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: #f6f7fb;
            padding: 16px;
        }

        .layout { max-width: 720px; margin: 0 auto; }

        .header-card {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 4px 12px rgba(15,23,42,.06);
            padding: 16px 20px;
            margin-bottom: 14px;
        }

        .header-card h1 {
            font-size: 16px;
            font-weight: 800;
            margin: 0 0 4px 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .header-card .meta {
            font-size: 12px;
            color: var(--slate-500);
        }

        .section-title {
            font-size: 12px;
            font-weight: 800;
            color: var(--slate-700);
            text-transform: uppercase;
            letter-spacing: .08em;
            margin: 18px 0 10px 4px;
        }

        .session-card {
            background: #fff;
            border-radius: 12px;
            border: 1px solid var(--slate-200);
            padding: 14px 18px;
            margin-bottom: 10px;
        }

        .session-card.synced {
            border-left: 4px solid var(--green-500);
        }
        .session-card.missing {
            border-left: 4px solid var(--amber-500);
            background: rgba(245,158,11,.04);
        }
        .session-card.unpaid {
            border-left: 4px solid var(--slate-500);
            background: var(--slate-50);
        }

        .session-id {
            font-family: monospace;
            font-size: 11px;
            color: var(--slate-500);
            margin-bottom: 4px;
            word-break: break-all;
        }

        .session-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 6px;
        }

        .session-amount {
            font-size: 16px;
            font-weight: 800;
            color: var(--slate-800);
        }

        .session-date {
            font-size: 12px;
            color: var(--slate-500);
        }

        .status-badges {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
            font-size: 11px;
            margin-top: 6px;
        }

        .badge {
            padding: 3px 8px;
            border-radius: 999px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        .badge-stripe-paid { background: rgba(99,91,255,.1); color: var(--purple-500); }
        .badge-stripe-unpaid { background: var(--slate-100); color: var(--slate-700); }
        .badge-bd-yes { background: rgba(16,185,129,.12); color: var(--green-600); }
        .badge-bd-no { background: rgba(245,158,11,.12); color: #92400e; }

        .action-row {
            margin-top: 10px;
        }

        .btn-import {
            padding: 8px 16px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 800;
            cursor: pointer;
        }
        .btn-import:hover {
            box-shadow: 0 6px 12px rgba(37,99,235,.25);
        }

        .empty-state {
            background: #fff;
            border-radius: 12px;
            padding: 32px 24px;
            text-align: center;
            color: var(--slate-500);
            font-size: 13px;
        }

        .alert {
            padding: 12px 14px;
            border-radius: 10px;
            font-size: 13px;
            margin-bottom: 14px;
        }
        .alert.info {
            background: rgba(59,130,246,.06);
            border: 1px solid rgba(59,130,246,.2);
            color: var(--blue-600);
        }
        .alert.success {
            background: rgba(16,185,129,.08);
            border: 1px solid rgba(16,185,129,.3);
            color: var(--green-600);
        }
        .alert.error {
            background: rgba(239,68,68,.08);
            border: 1px solid rgba(239,68,68,.3);
            color: var(--red-500);
        }

        .footer-bar {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            margin-top: 18px;
        }
        .btn-secondary {
            padding: 10px 20px;
            background: var(--slate-50);
            color: var(--slate-700);
            border: 1px solid var(--slate-200);
            border-radius: 10px;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="layout">

            <div class="header-card">
                <h1>🔄 Synchroniser les paiements Stripe</h1>
                <div class="meta">
                    Facture <strong><asp:Literal ID="litDocumentId" runat="server" /></strong>
                    · Fournisseur <strong><asp:Literal ID="litSupplierName" runat="server" /></strong>
                </div>
            </div>

            <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert info">
                <asp:Literal ID="litAlert" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                <asp:Literal ID="litError" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlSessionList" runat="server">
                <h3 class="section-title">Paiements Stripe trouvés</h3>
                <asp:Literal ID="litSessions" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
                Aucun paiement Stripe trouvé pour cette facture.
                <br/><br/>
                <small>Les paiements des 100 dernières sessions sur ce fournisseur ont été vérifiés.</small>
            </asp:Panel>

            <div class="footer-bar">
                <asp:Button ID="btnRefresh" runat="server"
                    Text="🔄 Vérifier à nouveau"
                    CssClass="btn-secondary"
                    CausesValidation="false" />
                <asp:HyperLink ID="lnkClose" runat="server"
                    NavigateUrl="javascript:window.close();"
                    CssClass="btn-secondary">Fermer</asp:HyperLink>
            </div>

        </div>

    </form>
</body>
</html>
