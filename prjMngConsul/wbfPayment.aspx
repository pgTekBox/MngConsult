<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfPayment.aspx.vb" Inherits="MngConsul.wbfPayment" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Paiement — MngConsul</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc;  --slate-100: #f1f5f9;
            --slate-200: #e2e8f0; --slate-300: #cbd5e1;
            --slate-400: #94a3b8; --slate-500: #64748b;
            --slate-600: #475569; --slate-700: #334155;
            --slate-800: #1e293b; --slate-900: #0f172a;
            --blue-500: #3b82f6;  --blue-600: #2563eb;  --blue-700: #1d4ed8;
            --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444;
            --orange-100: #fef3c7;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            min-height: 100vh;
            background:
                radial-gradient(900px 500px at 20% 10%, #eef2ff 0%, transparent 60%),
                radial-gradient(900px 500px at 80% 90%, #ecfeff 0%, transparent 60%),
                #f6f7fb;
            padding: 24px;
        }

        .layout {
            max-width: 920px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }

        @media (max-width: 880px) {
            .layout { grid-template-columns: 1fr; }
        }

        /* Bandeau dev */
        .dev-banner {
            grid-column: 1 / -1;
            background: var(--orange-100);
            border: 1px solid #f59e0b;
            border-radius: 12px;
            padding: 12px 16px;
            font-size: 13px;
            color: #78350f;
            margin-bottom: 4px;
        }

        /* === Header logo === */
        .brand {
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 6px;
        }
        .brand .logo {
            width: 40px; height: 40px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            border-radius: 12px;
            color: white;
            display: inline-flex;
            align-items: center; justify-content: center;
            font-size: 20px; font-weight: 800;
        }
        .brand h1 {
            font-size: 18px;
            font-weight: 800;
            margin: 0;
        }

        /* === Récap forfait (gauche) === */
        .summary {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 12px 28px rgba(15,23,42,.08);
            padding: 28px;
            position: relative;
            overflow: hidden;
            align-self: start;
        }

        .summary::before {
            content: "";
            position: absolute;
            top: -40px; right: -40px;
            width: 160px; height: 160px;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(37,99,235,.08), rgba(6,182,212,.04));
        }

        .summary-content { position: relative; }

        .summary h2 {
            font-size: 13px;
            font-weight: 800;
            color: var(--slate-500);
            text-transform: uppercase;
            letter-spacing: .1em;
            margin: 0 0 8px 0;
        }

        .plan-name {
            font-size: 28px;
            font-weight: 800;
            margin: 0 0 4px 0;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .plan-tagline {
            font-size: 14px;
            color: var(--slate-500);
            margin: 0 0 24px 0;
        }

        .price-block {
            background: var(--slate-50);
            border-radius: 14px;
            padding: 18px 20px;
            margin-bottom: 20px;
        }

        .price-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
            padding: 4px 0;
        }
        .price-row .lbl { color: var(--slate-600); }
        .price-row .val { font-weight: 700; color: var(--slate-800); }

        .price-divider {
            height: 1px;
            background: var(--slate-200);
            margin: 10px 0;
        }

        .price-row.total .lbl { font-weight: 800; font-size: 15px; }
        .price-row.total .val {
            font-size: 22px;
            font-weight: 900;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .features {
            list-style: none;
            padding: 0; margin: 0;
        }
        .features li {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: var(--slate-700);
            padding: 6px 0;
        }
        .features svg {
            color: var(--green-500);
            flex-shrink: 0;
        }

        /* === Carte visuelle === */
        .card-visual {
            position: relative;
            margin-bottom: 18px;
            background: linear-gradient(135deg, #1e293b, #0f172a);
            border-radius: 16px;
            padding: 22px;
            color: white;
            box-shadow: 0 12px 28px rgba(15,23,42,.3);
            overflow: hidden;
            min-height: 180px;
        }
        .card-visual::before {
            content: "";
            position: absolute;
            top: -40px; right: -40px;
            width: 200px; height: 200px;
            border-radius: 50%;
            background: radial-gradient(circle at center, rgba(37,99,235,.4), transparent 70%);
        }
        .card-visual::after {
            content: "";
            position: absolute;
            bottom: -40px; left: -40px;
            width: 200px; height: 200px;
            border-radius: 50%;
            background: radial-gradient(circle at center, rgba(6,182,212,.3), transparent 70%);
        }

        .card-chip {
            width: 38px; height: 28px;
            background: linear-gradient(135deg, #fbbf24, #d97706);
            border-radius: 6px;
            margin-bottom: 22px;
            position: relative;
            z-index: 1;
        }

        .card-number {
            font-size: 19px;
            letter-spacing: 2px;
            font-weight: 600;
            font-family: "Courier New", monospace;
            margin-bottom: 18px;
            position: relative;
            z-index: 1;
        }

        .card-bottom {
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            position: relative;
            z-index: 1;
        }
        .card-bottom .lbl {
            opacity: 0.6;
            text-transform: uppercase;
            font-size: 9px;
            letter-spacing: 1px;
            margin-bottom: 3px;
        }
        .card-bottom .val { font-size: 13px; font-weight: 600; }

        .card-brand-logo {
            position: absolute;
            top: 18px; right: 22px;
            font-size: 18px;
            font-weight: 900;
            font-style: italic;
            opacity: 0.9;
            z-index: 2;
            letter-spacing: -1px;
        }

        /* === Formulaire (droite) === */
        .form-card {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 12px 28px rgba(15,23,42,.08);
            padding: 28px;
        }

        .form-card h2 {
            font-size: 20px;
            font-weight: 800;
            margin: 0 0 4px 0;
        }
        .form-card .form-sub {
            color: var(--slate-500);
            font-size: 13px;
            margin: 0 0 22px 0;
        }

        .field { margin-bottom: 14px; }

        .field label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: var(--slate-700);
            margin-bottom: 6px;
        }

        .field input {
            width: 100%;
            padding: 12px 14px;
            border: 2px solid var(--slate-200);
            border-radius: 10px;
            font-size: 14px;
            color: var(--slate-800);
            background: #fff;
            outline: none;
            font-family: var(--font);
            transition: border-color .15s, box-shadow .15s;
        }
        .field input:focus {
            border-color: var(--blue-500);
            box-shadow: 0 0 0 3px rgba(59,130,246,.18);
        }

        .field-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        .test-card-hint {
            margin: 8px 0 14px 0;
            padding: 10px 12px;
            background: rgba(59,130,246,.06);
            border: 1px solid rgba(59,130,246,.2);
            border-radius: 8px;
            font-size: 12px;
            color: var(--blue-700);
        }
        .test-card-hint code {
            background: rgba(59,130,246,.12);
            padding: 1px 6px;
            border-radius: 4px;
            font-family: "Courier New", monospace;
            font-weight: 700;
        }

        .alert {
            padding: 12px 14px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 14px;
        }
        .alert.error {
            background: rgba(239,68,68,.08);
            border: 1px solid rgba(239,68,68,.25);
            color: var(--red-500);
        }

        .btn-pay {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 800;
            font-family: var(--font);
            cursor: pointer;
            margin-top: 10px;
            transition: transform .12s, box-shadow .12s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        .btn-pay:hover {
            transform: translateY(-1px);
            box-shadow: 0 12px 24px rgba(37,99,235,.3);
        }
        .btn-pay:disabled {
            opacity: 0.7;
            cursor: not-allowed;
            transform: none;
        }

        .secure-info {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            font-size: 11px;
            color: var(--slate-500);
            margin-top: 14px;
        }

        /* === Bloc Stripe info === */
        .stripe-info {
            background: linear-gradient(135deg, rgba(99,91,255,.04), rgba(99,91,255,.08));
            border: 1px solid rgba(99,91,255,.15);
            border-radius: 14px;
            padding: 18px 20px;
            margin-bottom: 20px;
        }

        .stripe-logo-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 14px;
            padding-bottom: 14px;
            border-bottom: 1px solid rgba(99,91,255,.15);
        }

        .stripe-tagline {
            font-size: 13px;
            font-weight: 700;
            color: #635BFF;
        }

        .stripe-features-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .stripe-features-list li {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: var(--slate-700);
            padding: 5px 0;
        }

        .stripe-features-list svg {
            color: var(--green-500);
            flex-shrink: 0;
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <div class="layout">

            <div class="brand">
                <div class="logo">M</div>
                <h1>MngConsul</h1>
            </div>

            <!-- =====================================================
                 GAUCHE : Récapitulatif du forfait
                 ===================================================== -->
            <div class="summary">
                <div class="summary-content">
                    <h2>Votre forfait</h2>
                    <div class="plan-name">
                        <asp:Literal ID="litPlanName" runat="server" Text="Pro" />
                    </div>
                    <p class="plan-tagline">
                        <asp:Literal ID="litPlanTagline" runat="server" Text="Pour les professionnels exigeants" />
                    </p>

                    <div class="price-block">
                        <div class="price-row">
                            <span class="lbl">
                                <asp:Literal ID="litPlanLabel" runat="server" Text="Forfait Pro" />
                            </span>
                            <span class="val">
                                <asp:Literal ID="litPlanAmount" runat="server" Text="49,00 $" />
                            </span>
                        </div>
                        <div class="price-row">
                            <span class="lbl">TPS (5 %)</span>
                            <span class="val">
                                <asp:Literal ID="litTps" runat="server" Text="2,45 $" />
                            </span>
                        </div>
                        <div class="price-row">
                            <span class="lbl">TVQ (9,975 %)</span>
                            <span class="val">
                                <asp:Literal ID="litTvq" runat="server" Text="4,89 $" />
                            </span>
                        </div>
                        <div class="price-divider"></div>
                        <div class="price-row total">
                            <span class="lbl">Total mensuel</span>
                            <span class="val">
                                <asp:Literal ID="litTotal" runat="server" Text="56,34 $" />
                            </span>
                        </div>
                    </div>

                    <ul class="features">
                        <asp:Literal ID="litFeatures" runat="server" />
                    </ul>
                </div>
            </div>


            <!-- =====================================================
                 DROITE : Bloc paiement Stripe Checkout
                 ===================================================== -->
            <div class="form-card">

                <h2>Paiement sécurisé</h2>
                <p class="form-sub">Vous serez redirigé vers Stripe pour finaliser votre paiement.</p>

                <!-- Bloc d'information Stripe -->
                <div class="stripe-info">
                    <div class="stripe-logo-row">
                        <svg width="42" height="20" viewBox="0 0 60 25" fill="#635BFF" aria-label="Stripe">
                            <path d="M59.5,14.1c0-4.2-2-7.5-5.9-7.5s-6.3,3.3-6.3,7.4c0,4.9,2.8,7.4,6.8,7.4c2,0,3.5-0.4,4.6-1.1v-3.3c-1.1,0.6-2.4,0.9-4.1,0.9c-1.6,0-3-0.6-3.2-2.5h8.1C59.5,15.3,59.5,14.5,59.5,14.1z M51.3,12.6c0-1.8,1.1-2.6,2.1-2.6c1,0,2,0.8,2,2.6H51.3z M40.8,6.6c-1.6,0-2.7,0.8-3.2,1.3l-0.2-1H33.7v18.9l4.2-0.9l0-4.6c0.6,0.5,1.6,1.1,3.1,1.1c3.1,0,5.9-2.5,5.9-7.5C46.9,9.3,44,6.6,40.8,6.6z M39.8,17.6c-1,0-1.7-0.4-2-0.8l0-6.4c0.4-0.5,1-0.8,2-0.8c1.6,0,2.7,1.8,2.7,4C42.6,15.9,41.5,17.6,39.8,17.6z M32.1,5.6L27.9,6.5v3.4l4.2-0.9V5.6z M27.9,6.9h4.2v14.3h-4.2V6.9z M23.4,8l-0.3-1.2h-3.6v14.4h4.1v-9.7c1-1.3,2.6-1,3.1-0.9V6.8C26.3,6.6,24.4,6.2,23.4,8z M14.9,3.2l-4.1,0.9V18c0,2.5,1.9,4.3,4.3,4.3c1.3,0,2.3-0.2,2.9-0.5v-3.3c-0.5,0.2-3.1,1-3.1-1.5v-5.7h3.1V7.4h-3.1V3.2z M4.2,11c0-0.6,0.5-0.9,1.4-0.9c1.2,0,2.8,0.4,4.1,1.1V7.3c-1.4-0.6-2.7-0.8-4.1-0.8c-3.3,0-5.6,1.8-5.6,4.7c0,4.6,6.3,3.9,6.3,5.9c0,0.8-0.7,1-1.5,1c-1.3,0-3-0.5-4.4-1.2v4c1.5,0.6,3,0.9,4.4,0.9c3.4,0,5.8-1.7,5.8-4.7C10.6,12.2,4.2,13,4.2,11z"/>
                        </svg>
                        <span class="stripe-tagline">Paiement traité par Stripe</span>
                    </div>
                    <ul class="stripe-features-list">
                        <li>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                            Chiffrement SSL 256 bits
                        </li>
                        <li>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                            Conforme PCI-DSS
                        </li>
                        <li>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                            Apple Pay, Google Pay, Link supportés
                        </li>
                        <li>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                            Aucune carte stockée chez MngConsul
                        </li>
                    </ul>
                </div>

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                    <asp:Literal ID="litError" runat="server" />
                </asp:Panel>

                <asp:Button ID="btnPay" runat="server" CssClass="btn-pay"
                    Text="Payer avec Stripe →" />

                <div class="secure-info">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                    Vous serez redirigé vers checkout.stripe.com
                </div>

            </div>

        </div>

    </form>
</body>
</html>
