<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfSupplierPaymentChoice.aspx.vb" Inherits="MngConsul.wbfSupplierPaymentChoice" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Payer le fournisseur — MngConsul</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc; --slate-100: #f1f5f9;
            --slate-200: #e2e8f0; --slate-300: #cbd5e1;
            --slate-400: #94a3b8; --slate-500: #64748b;
            --slate-600: #475569; --slate-700: #334155;
            --slate-800: #1e293b;
            --blue-500: #3b82f6; --blue-600: #2563eb;
            --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444;
            --amber-500: #f59e0b;
            --orange-500: #f97316;
            --purple-500: #a855f7;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: #f6f7fb;
            padding: 16px;
        }

        .layout {
            max-width: 640px;
            margin: 0 auto;
        }

        /* En-tête facture */
        .invoice-summary {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 4px 12px rgba(15,23,42,.06);
            padding: 18px 22px;
            margin-bottom: 18px;
        }
        .invoice-summary h2 {
            font-size: 11px;
            font-weight: 800;
            color: var(--slate-500);
            text-transform: uppercase;
            letter-spacing: .1em;
            margin: 0 0 8px 0;
        }
        .invoice-summary .supplier-name {
            font-size: 20px;
            font-weight: 800;
            color: var(--slate-800);
            margin: 0 0 8px 0;
        }
        .invoice-summary .amount-row {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            padding-top: 10px;
            border-top: 1px solid var(--slate-200);
        }
        .invoice-summary .amount-row .label {
            font-size: 13px;
            color: var(--slate-600);
        }
        .invoice-summary .amount-row .value {
            font-size: 24px;
            font-weight: 900;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        /* Titre section */
        .section-title {
            font-size: 13px;
            font-weight: 800;
            color: var(--slate-700);
            text-transform: uppercase;
            letter-spacing: .08em;
            margin: 0 0 12px 4px;
        }

        /* Cartes méthode de paiement */
        .method-card {
            background: #fff;
            border-radius: 14px;
            border: 2px solid var(--slate-200);
            padding: 16px 18px;
            margin-bottom: 12px;
            cursor: pointer;
            transition: border-color .15s, box-shadow .15s, transform .12s;
            position: relative;
        }
        .method-card:hover {
            border-color: var(--blue-500);
            box-shadow: 0 6px 16px rgba(37,99,235,.08);
            transform: translateY(-1px);
        }
        .method-card.selected {
            border-color: var(--blue-600);
            background: linear-gradient(135deg, rgba(37,99,235,.04), rgba(6,182,212,.06));
            box-shadow: 0 6px 18px rgba(37,99,235,.15);
        }

        .method-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .method-card-title {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 15px;
            font-weight: 800;
            color: var(--slate-800);
        }
        .method-icon {
            width: 32px; height: 32px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center; justify-content: center;
            color: white;
            flex-shrink: 0;
        }
        .method-icon.interac { background: linear-gradient(135deg, #FFB81C, #FFA000); }
        .method-icon.acss    { background: linear-gradient(135deg, #1976D2, #1565C0); }
        .method-icon.card    { background: linear-gradient(135deg, #7C3AED, #6D28D9); }

        .badge-recommended {
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .05em;
            padding: 3px 8px;
            border-radius: 999px;
            background: var(--green-500);
            color: white;
        }
        .badge-last-used {
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .05em;
            padding: 3px 8px;
            border-radius: 999px;
            background: var(--amber-500);
            color: white;
        }

        .method-card-desc {
            font-size: 12px;
            color: var(--slate-600);
            margin: 0 0 8px 0;
        }

        .method-card-details {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            font-size: 12px;
        }
        .detail-item {
            background: var(--slate-50);
            border-radius: 8px;
            padding: 8px 10px;
        }
        .detail-item .lbl {
            font-size: 10px;
            text-transform: uppercase;
            font-weight: 800;
            color: var(--slate-500);
            letter-spacing: .05em;
            margin-bottom: 2px;
        }
        .detail-item .val {
            font-weight: 700;
            color: var(--slate-800);
        }
        .detail-item.fee .val {
            color: var(--red-500);
        }
        .detail-item.time .val {
            color: var(--blue-600);
        }

        /* Radio buttons cachés visuellement */
        .method-radio {
            position: absolute;
            top: 16px;
            right: 16px;
            width: 22px; height: 22px;
            border-radius: 50%;
            border: 2px solid var(--slate-300);
            background: white;
            transition: border-color .15s, background .15s;
        }
        .method-card.selected .method-radio {
            border-color: var(--blue-600);
            background: var(--blue-600);
            box-shadow: inset 0 0 0 4px white;
        }

        /* Bloc total */
        .total-block {
            background: #fff;
            border-radius: 14px;
            padding: 16px 18px;
            margin: 18px 0;
            box-shadow: 0 4px 12px rgba(15,23,42,.04);
        }
        .total-row {
            display: flex;
            justify-content: space-between;
            font-size: 13px;
            padding: 4px 0;
            color: var(--slate-600);
        }
        .total-row .val { color: var(--slate-800); font-weight: 700; }
        .total-row.grand {
            border-top: 1px solid var(--slate-200);
            margin-top: 8px;
            padding-top: 12px;
            font-size: 15px;
        }
        .total-row.grand .lbl { font-weight: 800; color: var(--slate-800); }
        .total-row.grand .val {
            font-size: 20px;
            font-weight: 900;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        /* Alerte info */
        .alert {
            padding: 12px 14px;
            border-radius: 10px;
            font-size: 13px;
            margin-bottom: 14px;
        }
        .alert.warning {
            background: rgba(245,158,11,.08);
            border: 1px solid rgba(245,158,11,.3);
            color: #92400e;
        }
        .alert.error {
            background: rgba(239,68,68,.08);
            border: 1px solid rgba(239,68,68,.3);
            color: var(--red-500);
            font-weight: 600;
        }
        .alert.info {
            background: rgba(59,130,246,.06);
            border: 1px solid rgba(59,130,246,.25);
            color: var(--blue-600);
        }

        /* Bouton de paiement */
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
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }

        /* === Section autorisation auto-paiement === */
        .autopay-section {
            background: linear-gradient(135deg, rgba(168,85,247,.04), rgba(59,130,246,.04));
            border: 1px solid var(--slate-200);
            border-radius: 14px;
            padding: 14px 16px;
            margin: 18px 0;
        }
        .autopay-toggle {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            cursor: pointer;
            user-select: none;
        }
        .autopay-toggle input[type="checkbox"] {
            width: 18px;
            height: 18px;
            margin-top: 2px;
            accent-color: var(--purple-500);
            cursor: pointer;
            flex-shrink: 0;
        }
        .autopay-toggle-label {
            flex: 1;
            font-size: 13px;
            font-weight: 700;
            color: var(--slate-800);
        }
        .autopay-toggle-label .icon { margin-right: 6px; }
        .autopay-sublabel {
            display: block;
            font-size: 11px;
            color: var(--slate-500);
            font-weight: 500;
            margin-top: 2px;
        }
        .autopay-details {
            margin-top: 12px;
            padding-top: 12px;
            border-top: 1px dashed var(--slate-300);
            display: none;
        }
        .autopay-details.visible { display: block; }

        .autopay-cap-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }
        .autopay-cap-row label {
            flex: 1;
            font-size: 12px;
            color: var(--slate-700);
            font-weight: 600;
        }
        .autopay-cap-row input {
            width: 110px;
            padding: 6px 10px;
            border: 1.5px solid var(--slate-200);
            border-radius: 8px;
            font-size: 13px;
            font-weight: 700;
            text-align: right;
            font-family: var(--font);
        }
        .autopay-cap-row .unit {
            font-weight: 700;
            color: var(--slate-600);
            font-size: 13px;
        }

        .autopay-legal {
            background: var(--slate-50);
            border-radius: 10px;
            padding: 10px 12px;
            font-size: 11px;
            line-height: 1.5;
            color: var(--slate-600);
            margin-top: 10px;
        }
        .autopay-legal strong { color: var(--slate-800); }
        .autopay-legal ul {
            margin: 6px 0 2px 0;
            padding-left: 18px;
        }
        .autopay-legal li { margin: 2px 0; }

        .autopay-revoke-note {
            font-size: 11px;
            color: var(--slate-500);
            margin-top: 8px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="layout">

            <!-- En-tête facture -->
            <div class="invoice-summary">
                <h2>Facture à payer</h2>
                <div class="supplier-name">
                    <asp:Literal ID="litSupplierName" runat="server" />
                </div>
                <div style="font-size: 13px; color: var(--slate-500); margin-bottom: 4px;">
                    <asp:Literal ID="litInvoiceNumber" runat="server" />
                </div>
                <div class="amount-row">
                    <span class="label">Reste à payer</span>
                    <span class="value">
                        <asp:Literal ID="litAmount" runat="server" />
                    </span>
                </div>

                <!-- Saisie du montant à payer (paiement partiel possible) -->
                <div style="margin-top: 16px; padding-top: 14px; border-top: 1px solid var(--slate-200);">
                    <label style="display:block; font-size: 11px; font-weight: 800; color: var(--slate-500); text-transform: uppercase; letter-spacing: .08em; margin-bottom: 6px;">
                        💰 Montant à payer maintenant
                    </label>
                    <div style="display:flex; align-items:center; gap:8px;">
                        <input type="number" id="amountToPay"
                               step="0.01" min="0.01"
                               style="width:100%; padding:12px 14px; border:2px solid var(--slate-200); border-radius:10px; font-size:16px; font-weight:800; font-family: var(--font); text-align:right;"
                               oninput="onAmountChange()" />
                        <span style="font-weight: 800; font-size: 16px; color: var(--slate-700);">$</span>
                    </div>
                    <div id="amountHint" style="font-size: 11px; color: var(--slate-500); margin-top: 4px;">
                        Vous pouvez payer une partie ou la totalité (min 0,01 $, max <span id="maxAmountDisplay"></span> $)
                    </div>
                    <div id="amountError" style="font-size: 12px; color: var(--red-500); margin-top: 4px; font-weight: 700; display: none;"></div>
                </div>
            </div>

            <!-- Alerte si le fournisseur n'est pas encore Stripe Connect -->
            <asp:Panel ID="pnlNoStripe" runat="server" Visible="false" CssClass="alert error">
                ⚠️ Ce fournisseur n'est pas encore configuré pour recevoir des paiements Stripe.
                <br/><br/>
                <asp:HyperLink ID="lnkConfigure" runat="server" CssClass="btn-pay"
                    Style="display:inline-block; width:auto; padding:10px 20px; margin-top:8px; text-decoration:none;">
                    Configurer ce fournisseur →
                </asp:HyperLink>
            </asp:Panel>

            <!-- Alerte erreur générique -->
            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                <asp:Literal ID="litError" runat="server" />
            </asp:Panel>

            <h3 class="section-title">Choisir une méthode de paiement</h3>

            <!-- Carte de crédit / débit (incluant Interac) -->
            <div class="method-card" id="cardCard" onclick="selectMethod('card')">
                <div class="method-radio"></div>
                <div class="method-card-header">
                    <div class="method-card-title">
                        <div class="method-icon card">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="2" y="5" width="20" height="14" rx="2"/>
                                <path d="M2 10h20"/>
                            </svg>
                        </div>
                        <span>Carte de crédit ou débit</span>
                    </div>
                    <asp:Panel ID="pnlBadgeCard" runat="server" Visible="false">
                        <span class="badge-last-used">Dernière utilisée</span>
                    </asp:Panel>
                </div>
                <p class="method-card-desc">Visa, Mastercard, Amex, Visa Debit / MC Debit (incluant cartes Interac). Apple Pay et Google Pay supportés.</p>
                <div class="method-card-details">
                    <div class="detail-item fee">
                        <div class="lbl">Frais</div>
                        <div class="val"><asp:Literal ID="litFeeCard" runat="server" /></div>
                    </div>
                    <div class="detail-item time">
                        <div class="lbl">Délai</div>
                        <div class="val">Instantané</div>
                    </div>
                </div>
            </div>

            <!-- Carte ACSS Debit (PAD) -->
            <div class="method-card" id="cardAcss" onclick="selectMethod('acss_debit')">
                <div class="method-radio"></div>
                <div class="method-card-header">
                    <div class="method-card-title">
                        <div class="method-icon acss">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3"/>
                            </svg>
                        </div>
                        <span>ACSS Debit (PAD bancaire)</span>
                    </div>
                    <asp:Panel ID="pnlBadgeAcss" runat="server" Visible="false">
                        <span class="badge-last-used">Dernière utilisée</span>
                    </asp:Panel>
                </div>
                <p class="method-card-desc">Débit pré-autorisé canadien (PAD). Frais bas plafonnés à 12 $ — idéal pour gros montants.</p>
                <div class="method-card-details">
                    <div class="detail-item fee">
                        <div class="lbl">Frais</div>
                        <div class="val"><asp:Literal ID="litFeeAcss" runat="server" /></div>
                    </div>
                    <div class="detail-item time">
                        <div class="lbl">Délai</div>
                        <div class="val">3-5 jours ouvrables</div>
                    </div>
                </div>
            </div>

            <%-- pnlBadgeInterac + litFeeInterac maintenus pour compatibilite designer.vb mais cache --%>
            <asp:Panel ID="pnlBadgeInterac" runat="server" Visible="false" Style="display:none;">
                <asp:Literal ID="litFeeInterac" runat="server" />
            </asp:Panel>

            <!-- Total avec gross-up -->
            <div class="total-block">
                <div class="total-row">
                    <span class="lbl">Montant facture</span>
                    <%-- ID sur le span pour que le JS puisse mettre a jour le contenu dynamiquement --%>
                    <span class="val" id="invoiceAmountDisplay">
                        <asp:Literal ID="litAmountInvoice" runat="server" />
                    </span>
                </div>
                <div class="total-row">
                    <span class="lbl">Frais de transaction</span>
                    <span class="val" id="feeDisplay">—</span>
                </div>
                <div class="total-row grand">
                    <span class="lbl">Total à débourser</span>
                    <span class="val" id="totalDisplay">—</span>
                </div>
            </div>

            <!-- === Section autorisation paiement automatique === -->
            <%-- Masquee si une autorisation active existe deja pour ce fournisseur (pnlAutoPayExisting) --%>
            <asp:Panel ID="pnlAutoPaySection" runat="server" CssClass="autopay-section">

                <!-- Cas 1 : Pas d'autorisation existante -> proposer activation -->
                <asp:Panel ID="pnlAutoPayPropose" runat="server">
                    <label class="autopay-toggle" for="chkAuthorizeAutoPay">
                        <asp:CheckBox ID="chkAuthorizeAutoPay" runat="server" ClientIDMode="Static" />
                        <span class="autopay-toggle-label">
                            <span class="icon">🤖</span>Autoriser le paiement automatique pour
                            <asp:Literal ID="litAutoPaySupplierName" runat="server" />
                            <span class="autopay-sublabel">
                                Les prochaines factures seront prélevées automatiquement à leur date d'échéance.
                            </span>
                        </span>
                    </label>

                    <div id="autopayDetails" class="autopay-details">

                        <div class="autopay-cap-row">
                            <label for="txtMaxPerMonth">Plafond mensuel maximum (sécurité)</label>
                            <input type="number" id="txtMaxPerMonth" min="0" step="100"
                                   value="5000" placeholder="5000" />
                            <span class="unit">$ / mois</span>
                        </div>

                        <div class="autopay-legal" id="autopayLegalCard">
                            <strong>📋 Conditions — Carte de crédit/débit (MIT)</strong>
                            <ul>
                                <li>Le moyen de paiement choisi sera sauvegardé de manière sécurisée par Stripe.</li>
                                <li>Vous recevrez un <strong>email de préavis 24 h avant chaque débit</strong>.</li>
                                <li>Le débit n'aura lieu que pour les factures que vous aurez approuvées (saisies + comptabilisées).</li>
                                <li>Vous pouvez <strong>révoquer cette autorisation</strong> à tout moment depuis la page "Paiements automatiques".</li>
                                <li>Plafond mensuel défini ci-dessus respecté — toute facture dépassant le plafond restera en attente manuelle.</li>
                            </ul>
                        </div>

                        <div class="autopay-legal" id="autopayLegalAcss" style="display:none;">
                            <strong>📋 Convention PAD (Préautorisation de débit) — Règle H1 Paiements Canada</strong>
                            <ul>
                                <li>J'autorise les <strong>prélèvements de type Affaires</strong> à montants variables.</li>
                                <li>J'accepte un <strong>préavis raccourci de 3 jours</strong> avant chaque débit (conforme à la Règle H1).</li>
                                <li>Numéro de mandat Stripe : généré automatiquement après confirmation.</li>
                                <li>Droit de contestation : 10 jours, droit au remboursement : 90 jours.</li>
                                <li>Cette autorisation est révocable à tout moment.</li>
                            </ul>
                        </div>

                        <div class="autopay-revoke-note">
                            ℹ️ Vous gardez le contrôle total. Aucun débit sans préavis et sans facture comptabilisée.
                        </div>
                    </div>
                </asp:Panel>

                <!-- Cas 2 : Autorisation deja active -> indiquer + ne pas redemander -->
                <asp:Panel ID="pnlAutoPayExisting" runat="server" Visible="false">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <span style="font-size: 20px;">✅</span>
                        <div>
                            <div style="font-weight: 800; font-size: 13px; color: var(--green-600);">
                                Paiement automatique déjà activé pour ce fournisseur
                            </div>
                            <div style="font-size: 11px; color: var(--slate-500); margin-top: 2px;">
                                Méthode active :
                                <asp:Literal ID="litExistingMethod" runat="server" />
                                — révocable depuis la page "Paiements automatiques".
                            </div>
                        </div>
                    </div>
                </asp:Panel>

            </asp:Panel>

            <!-- Hidden fields pour méthode + montant choisis -->
            <asp:HiddenField ID="hfSelectedMethod" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hfAmountToPay" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hfAuthorizeAutoPay" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hfMaxAmountPerMonth" runat="server" ClientIDMode="Static" />

            <!-- Bouton de paiement -->
            <asp:Button ID="btnPay" runat="server"
                Text="Payer avec Stripe →"
                CssClass="btn-pay"
                CausesValidation="false"
                OnClientClick="return validateBeforeSubmit();" />

        </div>

        <script type="text/javascript">

            // Pré-données injectées par le code-behind
            window.maxAmount = parseFloat('<%= AmountForJs %>') || 0;
            window.currentAmount = window.maxAmount;  // par défaut, on paye le reste complet
            window.lastUsedMethod = '<%= LastUsedMethodForJs %>';

            // Calcul gross-up par méthode (2 méthodes : card + acss_debit)
            function calculateFees(method, amount) {
                if (method === 'acss_debit') {
                    var fee = Math.min(amount * 0.01, 12.00);
                    return { fee: fee, total: amount + fee };
                } else {
                    // 'card' (default) : 2.9% + 0.30 $
                    var grossUp = (amount + 0.30) / 0.971;
                    var fee = grossUp - amount;
                    return { fee: fee, total: grossUp };
                }
            }

            function formatMoney(value) {
                return value.toLocaleString('fr-CA', {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                }) + ' $';
            }

            // Helper : update du span "Montant facture" en haut du bloc total
            function setInvoiceAmountDisplay(value) {
                var el = document.getElementById('invoiceAmountDisplay');
                if (el) el.textContent = formatMoney(value);
            }

            // Quand le user change le montant à payer
            function onAmountChange() {
                var input = document.getElementById('amountToPay');
                var raw = parseFloat(input.value);
                var errorEl = document.getElementById('amountError');
                var btnPay = document.querySelector('.btn-pay');

                errorEl.style.display = 'none';
                errorEl.textContent = '';
                if (btnPay) btnPay.disabled = false;

                if (isNaN(raw) || raw <= 0) {
                    errorEl.style.display = 'block';
                    errorEl.textContent = '⚠ Le montant doit être supérieur à 0.';
                    if (btnPay) btnPay.disabled = true;
                    return;
                }
                if (raw > window.maxAmount + 0.001) {
                    errorEl.style.display = 'block';
                    errorEl.textContent = '⚠ Le montant ne peut dépasser ' + formatMoney(window.maxAmount);
                    if (btnPay) btnPay.disabled = true;
                    return;
                }

                window.currentAmount = Math.round(raw * 100) / 100;

                // Mettre à jour le hidden field pour postback
                document.getElementById('hfAmountToPay').value = window.currentAmount.toFixed(2);

                // Mettre à jour affichage du montant facture (span avec id)
                setInvoiceAmountDisplay(window.currentAmount);

                // Recalculer frais + total selon la methode choisie
                var currentMethod = document.getElementById('hfSelectedMethod').value;
                if (currentMethod) selectMethod(currentMethod);
            }

            function selectMethod(method) {
                // Visuel : sélection
                document.getElementById('cardAcss').classList.remove('selected');
                document.getElementById('cardCard').classList.remove('selected');

                if (method === 'acss_debit') {
                    document.getElementById('cardAcss').classList.add('selected');
                } else {
                    // 'card' par default (incluant l'ancien 'interac_present' migrere)
                    method = 'card';
                    document.getElementById('cardCard').classList.add('selected');
                }

                // Stocker dans hidden field pour postback
                document.getElementById('hfSelectedMethod').value = method;

                // Recalculer total avec le montant courant
                var calc = calculateFees(method, window.currentAmount);
                document.getElementById('feeDisplay').textContent = '+ ' + formatMoney(calc.fee);
                document.getElementById('totalDisplay').textContent = formatMoney(calc.total);

                // Mettre a jour le texte legal de l'autorisation selon la methode
                updateAutoPayLegal(method);
            }

            // === AutoPay : afficher / masquer detail selon case a cocher ===
            function onAutoPayToggle() {
                var chk = document.getElementById('chkAuthorizeAutoPay');
                if (!chk) return;
                var details = document.getElementById('autopayDetails');
                var hf = document.getElementById('hfAuthorizeAutoPay');
                if (chk.checked) {
                    details.classList.add('visible');
                    if (hf) hf.value = 'true';
                } else {
                    details.classList.remove('visible');
                    if (hf) hf.value = 'false';
                }
            }

            // Affiche le bon texte legal (carte vs acss)
            function updateAutoPayLegal(method) {
                var legalCard = document.getElementById('autopayLegalCard');
                var legalAcss = document.getElementById('autopayLegalAcss');
                if (!legalCard || !legalAcss) return;
                if (method === 'acss_debit') {
                    legalCard.style.display = 'none';
                    legalAcss.style.display = 'block';
                } else {
                    legalCard.style.display = 'block';
                    legalAcss.style.display = 'none';
                }
            }

            // Maj du hidden field plafond mensuel quand l'input change
            function onMaxMonthChange() {
                var input = document.getElementById('txtMaxPerMonth');
                var hf = document.getElementById('hfMaxAmountPerMonth');
                if (input && hf) hf.value = input.value || '';
            }

            function validateBeforeSubmit() {
                var selected = document.getElementById('hfSelectedMethod').value;
                if (!selected) {
                    alert('Veuillez choisir une méthode de paiement.');
                    return false;
                }
                var amt = parseFloat(document.getElementById('hfAmountToPay').value);
                if (isNaN(amt) || amt <= 0) {
                    alert('Veuillez saisir un montant valide.');
                    return false;
                }
                if (amt > window.maxAmount + 0.001) {
                    alert('Le montant dépasse le reste à payer.');
                    return false;
                }
                return true;
            }

            // Initialisation au chargement
            (function () {
                // Initialiser le champ de montant avec le ResteAPayer
                var amountField = document.getElementById('amountToPay');
                amountField.value = window.maxAmount.toFixed(2);
                amountField.max = window.maxAmount.toFixed(2);

                document.getElementById('maxAmountDisplay').textContent = formatMoney(window.maxAmount).replace(' $', '');
                document.getElementById('hfAmountToPay').value = window.maxAmount.toFixed(2);

                // Methode par defaut : 'card' (l'ancien 'interac_present' est migrere vers card)
                var initial = window.lastUsedMethod;
                if (initial === 'interac_present' || initial === 'interac' || !initial) {
                    initial = 'card';
                }
                selectMethod(initial);

                // AutoPay : brancher la case a cocher
                var chk = document.getElementById('chkAuthorizeAutoPay');
                if (chk) {
                    chk.addEventListener('change', onAutoPayToggle);
                    // Init hidden field
                    var hf = document.getElementById('hfAuthorizeAutoPay');
                    if (hf) hf.value = chk.checked ? 'true' : 'false';
                }

                // AutoPay : brancher l'input plafond
                var maxInput = document.getElementById('txtMaxPerMonth');
                if (maxInput) {
                    maxInput.addEventListener('input', onMaxMonthChange);
                    onMaxMonthChange();
                }
            })();

        </script>

    </form>
</body>
</html>
