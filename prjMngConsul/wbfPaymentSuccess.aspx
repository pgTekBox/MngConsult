<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfPaymentSuccess.aspx.vb" Inherits="MngConsul.wbfPaymentSuccess" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Paiement réussi — 60Sec-AI</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc;  --slate-200: #e2e8f0;
            --slate-500: #64748b; --slate-600: #475569;
            --slate-700: #334155; --slate-800: #1e293b;
            --blue-600: #2563eb;  --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            background:
                radial-gradient(900px 500px at 20% 10%, #ecfdf5 0%, transparent 60%),
                radial-gradient(900px 500px at 80% 90%, #ecfeff 0%, transparent 60%),
                #f6f7fb;
        }

        .card {
            width: 100%;
            max-width: 520px;
            background: #fff;
            border-radius: 24px;
            box-shadow: 0 20px 50px rgba(15,23,42,.15);
            overflow: hidden;
            text-align: center;
        }

        .card-top {
            padding: 48px 32px 32px 32px;
        }

        .check-icon {
            width: 96px; height: 96px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--green-500), var(--green-600));
            color: white;
            display: inline-flex;
            align-items: center; justify-content: center;
            margin-bottom: 24px;
            box-shadow: 0 16px 32px rgba(16,185,129,.35);
            animation: pop .5s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        @keyframes pop {
            0%   { transform: scale(0); }
            100% { transform: scale(1); }
        }

        h1 {
            font-size: 28px;
            font-weight: 800;
            margin: 0 0 8px 0;
            letter-spacing: -0.5px;
        }

        .subtitle {
            color: var(--slate-600);
            font-size: 15px;
            margin: 0 0 28px 0;
            line-height: 1.5;
        }

        .receipt {
            background: var(--slate-50);
            border-radius: 14px;
            padding: 18px 22px;
            text-align: left;
            margin-bottom: 24px;
        }

        .receipt h3 {
            font-size: 11px;
            font-weight: 800;
            color: var(--slate-500);
            text-transform: uppercase;
            letter-spacing: .1em;
            margin: 0 0 12px 0;
        }

        .receipt-row {
            display: flex;
            justify-content: space-between;
            padding: 6px 0;
            font-size: 14px;
        }
        .receipt-row .lbl { color: var(--slate-500); }
        .receipt-row .val { font-weight: 700; color: var(--slate-800); }
        .receipt-row.total {
            border-top: 1px solid var(--slate-200);
            padding-top: 12px;
            margin-top: 4px;
        }
        .receipt-row.total .val {
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            font-size: 18px;
            font-weight: 900;
        }

        .actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
            padding: 0 32px 36px 32px;
        }

        .btn {
            padding: 13px 28px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 800;
            font-family: var(--font);
            border: none;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: transform .12s, box-shadow .12s;
        }
        .btn:hover { transform: translateY(-1px); }

        .btn-primary {
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: white;
        }
        .btn-primary:hover { box-shadow: 0 12px 24px rgba(37,99,235,.3); }

        .btn-secondary {
            background: var(--slate-50);
            color: var(--slate-700);
            border: 1px solid var(--slate-200);
        }
        .btn-secondary:hover { background: #fff; box-shadow: 0 4px 12px rgba(15,23,42,.06); }

        .footer-info {
            background: var(--slate-50);
            border-top: 1px solid var(--slate-200);
            padding: 16px;
            text-align: center;
            font-size: 12px;
            color: var(--slate-500);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="card">

            <div class="card-top">

                <div class="check-icon">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>

                <h1><%= L("title") %></h1>
                <p class="subtitle">
                    <%= L("thanksLine") %><br/>
                    <%= L("subBefore") %><strong><asp:Literal ID="litPlanName" runat="server" /></strong><%= L("subAfter") %>
                </p>

                <div class="receipt">
                    <h3><%= L("receiptTitle") %></h3>

                    <div class="receipt-row">
                        <span class="lbl"><%= L("txnLabel") %></span>
                        <span class="val" style="font-family: monospace; font-size: 12px;">
                            <asp:Literal ID="litTransactionId" runat="server" />
                        </span>
                    </div>

                    <div class="receipt-row">
                        <span class="lbl"><%= L("dateLabel") %></span>
                        <span class="val">
                            <asp:Literal ID="litDate" runat="server" />
                        </span>
                    </div>

                    <div class="receipt-row">
                        <span class="lbl"><%= L("cardLabel") %></span>
                        <span class="val">
                            <asp:Literal ID="litCard" runat="server" />
                        </span>
                    </div>

                    <div class="receipt-row">
                        <span class="lbl"><%= L("planLabel") %></span>
                        <span class="val">
                            <asp:Literal ID="litPlanName2" runat="server" />
                        </span>
                    </div>

                    <div class="receipt-row">
                        <span class="lbl"><%= L("nextBillingLabel") %></span>
                        <span class="val">
                            <asp:Literal ID="litNextBilling" runat="server" />
                        </span>
                    </div>

                    <div class="receipt-row total">
                        <span class="lbl" style="font-weight: 800; color: var(--slate-800);"><%= L("amountLabel") %></span>
                        <span class="val">
                            <asp:Literal ID="litAmount" runat="server" />
                        </span>
                    </div>
                </div>

            </div>

            <div class="actions">
                <asp:HyperLink ID="lnkDashboard" runat="server"
                    NavigateUrl="~/wbfNewUser.aspx" CssClass="btn btn-primary" />
            </div>

            <div class="footer-info">
                <%= L("footer") %>
            </div>

        </div>

    </form>
</body>
</html>
