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
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <div class="layout">

            <div class="brand">
                <div class="logo">M</div>
                <h1>MngConsul</h1>
            </div>

            <div class="dev-banner">
                <strong>🧪 Mode simulation</strong> — Pour tester un paiement réussi, utilisez la carte
                <strong>4242 4242 4242 4242</strong> avec n'importe quelle date d'expiration future et CVV.
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
                 DROITE : Formulaire carte de crédit
                 ===================================================== -->
            <div class="form-card">

                <h2>Informations de paiement</h2>
                <p class="form-sub">Entrez les détails de votre carte de crédit</p>

                <!-- Carte visuelle qui se met à jour avec les saisies -->
                <div class="card-visual">
                    <div class="card-brand-logo" id="cardBrandLogo">VISA</div>
                    <div class="card-chip"></div>
                    <div class="card-number" id="cardNumberDisplay">•••• •••• •••• ••••</div>
                    <div class="card-bottom">
                        <div>
                            <div class="lbl">Titulaire</div>
                            <div class="val" id="cardHolderDisplay">VOTRE NOM</div>
                        </div>
                        <div style="text-align: right;">
                            <div class="lbl">Expire</div>
                            <div class="val" id="cardExpiryDisplay">MM/AA</div>
                        </div>
                    </div>
                </div>

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                    <asp:Literal ID="litError" runat="server" />
                </asp:Panel>

                <div class="field">
                    <label>Nom du titulaire</label>
                    <asp:TextBox ID="tbCardHolder" runat="server"
                        placeholder="JEAN TREMBLAY"
                        ClientIDMode="Static" autocomplete="cc-name" />
                </div>

                <div class="field">
                    <label>Numéro de carte</label>
                    <asp:TextBox ID="tbCardNumber" runat="server"
                        placeholder="4242 4242 4242 4242"
                        ClientIDMode="Static"
                        autocomplete="cc-number"
                        MaxLength="23" />
                    <div class="test-card-hint">
                        💡 Carte de test : <code>4242 4242 4242 4242</code> · Toute autre carte sera refusée
                    </div>
                </div>

                <div class="field-row">
                    <div class="field">
                        <label>Date d'expiration</label>
                        <asp:TextBox ID="tbExpiry" runat="server"
                            placeholder="MM/AA"
                            ClientIDMode="Static"
                            autocomplete="cc-exp"
                            MaxLength="5" />
                    </div>
                    <div class="field">
                        <label>CVV</label>
                        <asp:TextBox ID="tbCvv" runat="server"
                            placeholder="123"
                            ClientIDMode="Static"
                            autocomplete="cc-csc"
                            MaxLength="4" />
                    </div>
                </div>

                <asp:Button ID="btnPay" runat="server" CssClass="btn-pay"
                    Text="🔒 Payer maintenant" />

                <div class="secure-info">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                    </svg>
                    Paiement sécurisé · Vos informations sont chiffrées
                </div>

            </div>

        </div>

        <script type="text/javascript">

            // ===== Formatage du numéro de carte =====
            (function () {
                var input = document.getElementById('tbCardNumber');
                var display = document.getElementById('cardNumberDisplay');
                var brandLogo = document.getElementById('cardBrandLogo');
                if (!input) return;

                input.addEventListener('input', function () {
                    var val = input.value.replace(/\D/g, '').substring(0, 19);
                    var formatted = val.match(/.{1,4}/g);
                    input.value = formatted ? formatted.join(' ') : '';

                    // Affichage sur la carte visuelle
                    var visual = (input.value + '•'.repeat(19)).substring(0, 19);
                    if (visual.length === 0) visual = '•••• •••• •••• ••••';
                    display.textContent = visual;

                    // Détection du type de carte
                    var firstDigit = val.charAt(0);
                    var firstTwo = val.substring(0, 2);
                    if (val.length === 0)              brandLogo.textContent = 'VISA';
                    else if (firstDigit === '4')       brandLogo.textContent = 'VISA';
                    else if (firstTwo >= '51' && firstTwo <= '55') brandLogo.textContent = 'MC';
                    else if (firstTwo === '34' || firstTwo === '37') brandLogo.textContent = 'AMEX';
                    else                               brandLogo.textContent = 'CARD';
                });
            })();

            // ===== Formatage de l'expiration MM/AA =====
            (function () {
                var input = document.getElementById('tbExpiry');
                var display = document.getElementById('cardExpiryDisplay');
                if (!input) return;

                input.addEventListener('input', function () {
                    var val = input.value.replace(/\D/g, '').substring(0, 4);
                    if (val.length >= 3) {
                        input.value = val.substring(0, 2) + '/' + val.substring(2);
                    } else {
                        input.value = val;
                    }
                    display.textContent = input.value || 'MM/AA';
                });
            })();

            // ===== CVV : chiffres uniquement =====
            (function () {
                var input = document.getElementById('tbCvv');
                if (!input) return;
                input.addEventListener('input', function () {
                    input.value = input.value.replace(/\D/g, '').substring(0, 4);
                });
            })();

            // ===== Nom du titulaire en majuscules sur la carte =====
            (function () {
                var input = document.getElementById('tbCardHolder');
                var display = document.getElementById('cardHolderDisplay');
                if (!input) return;
                input.addEventListener('input', function () {
                    display.textContent = input.value.toUpperCase() || 'VOTRE NOM';
                });
            })();

        </script>

    </form>
</body>
</html>
