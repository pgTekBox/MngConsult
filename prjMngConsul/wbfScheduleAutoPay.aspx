<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfScheduleAutoPay.aspx.vb" Inherits="MngConsul.wbfScheduleAutoPay" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Programmer auto-paiement — MngConsul</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-200: #e2e8f0; --slate-500: #64748b;
            --slate-700: #334155; --slate-800: #1e293b;
            --blue-600: #2563eb; --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444;
            --purple-500: #a855f7;
        }
        body {
            font-family: var(--font);
            color: var(--slate-800);
            background: #f6f7fb;
            padding: 16px;
        }
        .layout { max-width: 560px; margin: 0 auto; }

        .header-card {
            background: linear-gradient(135deg, rgba(168,85,247,.05), rgba(37,99,235,.05));
            border: 1px solid var(--slate-200);
            border-radius: 14px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .header-card h1 {
            font-size: 18px; font-weight: 800; margin: 0 0 6px 0;
            display: flex; align-items: center; gap: 8px;
        }
        .header-card .meta { font-size: 13px; color: var(--slate-500); }

        .info-block {
            background: #fff;
            border-radius: 12px;
            padding: 16px 18px;
            margin-bottom: 12px;
            box-shadow: 0 1px 3px rgba(15,23,42,.05);
        }
        .label { font-size: 11px; font-weight: 800; color: var(--slate-500); text-transform: uppercase; letter-spacing: .08em; margin-bottom: 4px; }
        .value { font-size: 15px; font-weight: 700; color: var(--slate-800); }
        .value.big { font-size: 22px; }

        .input-row {
            display: flex; align-items: center; gap: 10px; margin-bottom: 12px;
        }
        .input-row label { flex: 1; font-size: 13px; font-weight: 700; color: var(--slate-700); }
        .input-row input[type="date"] {
            padding: 8px 12px; border: 2px solid var(--slate-200);
            border-radius: 8px; font-size: 14px; font-family: var(--font);
        }

        .auth-pick {
            background: #fff;
            border: 2px solid var(--slate-200);
            border-radius: 12px;
            padding: 12px 16px;
            margin-bottom: 10px;
            cursor: pointer;
        }
        .auth-pick.selected {
            border-color: var(--purple-500);
            background: linear-gradient(135deg, rgba(168,85,247,.05), rgba(37,99,235,.05));
        }
        .auth-pick-radio {
            width: 16px; height: 16px; margin-right: 10px; vertical-align: middle;
            accent-color: var(--purple-500);
        }

        .alert {
            padding: 12px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px;
        }
        .alert.error { background: rgba(239,68,68,.08); border: 1px solid rgba(239,68,68,.3); color: var(--red-500); }
        .alert.success { background: rgba(16,185,129,.08); border: 1px solid rgba(16,185,129,.3); color: var(--green-600); }
        .alert.info { background: rgba(59,130,246,.06); border: 1px solid rgba(59,130,246,.25); color: var(--blue-600); }

        .btn-confirm {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, var(--purple-500), var(--blue-600));
            color: white; border: none; border-radius: 12px;
            font-size: 15px; font-weight: 800; cursor: pointer;
            display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-confirm:hover { box-shadow: 0 12px 24px rgba(168,85,247,.3); }
        .btn-confirm:disabled { opacity: .5; cursor: not-allowed; }
        .btn-secondary {
            padding: 10px 16px; background: #f1f5f9; color: var(--slate-700);
            border: 1px solid var(--slate-200); border-radius: 10px;
            font-size: 13px; font-weight: 700; cursor: pointer;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="layout">

            <div class="header-card">
                <h1>🤖 Programmer un paiement automatique</h1>
                <div class="meta">
                    Le paiement sera prélevé automatiquement à la date choisie via Stripe,
                    en utilisant l'autorisation que vous avez configurée pour ce fournisseur.
                </div>
            </div>

            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                <asp:Literal ID="litError" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="alert success">
                <asp:Literal ID="litSuccess" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlForm" runat="server">

                <!-- Resume facture -->
                <div class="info-block">
                    <div class="label">Facture à payer</div>
                    <div class="value"><asp:Literal ID="litInvoiceInfo" runat="server" /></div>
                    <div style="margin-top:12px;">
                        <div class="label">Reste à payer</div>
                        <div class="value big"><asp:Literal ID="litRestant" runat="server" /></div>
                    </div>
                </div>

                <!-- Choix de l'autorisation -->
                <div class="info-block">
                    <div class="label" style="margin-bottom: 8px;">Moyen de paiement à utiliser</div>
                    <asp:RadioButtonList ID="rblAuth" runat="server" RepeatLayout="Flow"
                        Style="display:flex; flex-direction:column; gap:8px;">
                    </asp:RadioButtonList>
                </div>

                <!-- Date du debit -->
                <div class="info-block">
                    <div class="input-row">
                        <label for="<%= tbAutoPayDate.ClientID %>">📅 Date du débit automatique</label>
                        <asp:TextBox ID="tbAutoPayDate" runat="server" TextMode="Date" />
                    </div>
                    <div style="font-size:11px; color:var(--slate-500);">
                        Par défaut : date d'échéance de la facture. Doit être aujourd'hui ou ultérieure.
                    </div>
                </div>

                <div class="alert info">
                    <strong>📧 Vous recevrez :</strong>
                    <ul style="margin: 8px 0 0 0; padding-left:18px;">
                        <li>Un email de préavis 24 h avant le débit (si carte)</li>
                        <li>Un email de préavis légal 3 jours avant le débit (si PAD)</li>
                        <li>Un email de confirmation après le débit</li>
                    </ul>
                </div>

                <asp:Button ID="btnConfirm" runat="server" Text="🤖 Programmer le paiement automatique"
                    CssClass="btn-confirm" CausesValidation="false" />

            </asp:Panel>

            <div style="text-align:center; margin-top:12px;">
                <asp:HyperLink ID="lnkClose" runat="server"
                    NavigateUrl="javascript:GetRadWindow().close();"
                    CssClass="btn-secondary"
                    Style="text-decoration:none;">Fermer</asp:HyperLink>
            </div>

        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }
        </script>
    </form>
</body>
</html>
