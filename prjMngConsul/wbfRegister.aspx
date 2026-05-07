<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfRegister.aspx.vb" Inherits="MngConsul.wbfRegister" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Inscription — MngConsul</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc;  --slate-100: #f1f5f9;
            --slate-200: #e2e8f0; --slate-300: #cbd5e1;
            --slate-400: #94a3b8; --slate-500: #64748b;
            --slate-600: #475569; --slate-700: #334155;
            --slate-800: #1e293b;
            --blue-500: #3b82f6;  --blue-600: #2563eb;  --blue-700: #1d4ed8;
            --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444;
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
                radial-gradient(900px 500px at 20% 10%, #eef2ff 0%, transparent 60%),
                radial-gradient(900px 500px at 80% 90%, #ecfeff 0%, transparent 60%),
                #f6f7fb;
        }

        .card {
            width: 100%;
            max-width: 460px;
            background: #fff;
            border-radius: 24px;
            box-shadow: 0 20px 50px rgba(15,23,42,.15);
            overflow: hidden;
        }

        .card-header {
            padding: 36px 32px 12px 32px;
            text-align: center;
        }

        .logo {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            border-radius: 18px;
            color: white;
            font-size: 30px; font-weight: 800;
            display: inline-flex;
            align-items: center; justify-content: center;
            margin-bottom: 18px;
            box-shadow: 0 10px 24px rgba(37,99,235,.3);
        }

        .card-header h1 {
            font-size: 24px;
            font-weight: 800;
            margin: 0 0 6px 0;
            letter-spacing: -0.3px;
        }
        .card-header p {
            color: var(--slate-500);
            font-size: 14px;
            margin: 0;
        }

        .card-body { padding: 24px 32px 16px 32px; }

        .field { margin-bottom: 14px; }
        .field label {
            display: block;
            font-size: 13px;
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

        @media (max-width: 480px) {
            .field-row { grid-template-columns: 1fr; }
        }

        .field-hint {
            font-size: 11px;
            color: var(--slate-500);
            margin-top: 4px;
        }

        /* Strength meter */
        .strength-bar {
            height: 4px;
            border-radius: 999px;
            background: var(--slate-200);
            margin-top: 6px;
            overflow: hidden;
        }
        .strength-bar > div {
            height: 100%;
            width: 0%;
            border-radius: 999px;
            transition: width .25s, background .25s;
        }
        .strength-text {
            font-size: 11px;
            margin-top: 4px;
            font-weight: 600;
        }

        .terms {
            display: flex;
            align-items: flex-start;
            gap: 8px;
            font-size: 12px;
            color: var(--slate-600);
            margin: 14px 0 18px 0;
            line-height: 1.4;
        }
        .terms input { margin-top: 2px; }
        .terms a { color: var(--blue-600); text-decoration: none; font-weight: 600; }
        .terms a:hover { text-decoration: underline; }

        .btn-submit {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 800;
            font-family: var(--font);
            cursor: pointer;
            transition: transform .12s, box-shadow .12s;
        }
        .btn-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 12px 24px rgba(37,99,235,.3);
        }
        .btn-submit:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
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

        .card-footer {
            padding: 16px;
            text-align: center;
            font-size: 13px;
            color: var(--slate-500);
            background: var(--slate-50);
            border-top: 1px solid var(--slate-200);
        }
        .card-footer a {
            color: var(--blue-600);
            text-decoration: none;
            font-weight: 700;
        }
        .card-footer a:hover { text-decoration: underline; }

        /* Success state */
        .success-card { text-align: center; padding: 48px 32px; }
        .success-icon {
            width: 80px; height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--green-500), var(--green-600));
            color: white;
            display: inline-flex;
            align-items: center; justify-content: center;
            margin-bottom: 20px;
            box-shadow: 0 12px 24px rgba(16,185,129,.3);
        }
        .success-card h1 {
            font-size: 22px; font-weight: 800;
            margin: 0 0 10px 0;
        }
        .success-card p {
            color: var(--slate-600);
            line-height: 1.6;
            margin: 0 0 18px 0;
        }
        .success-card .email-shown {
            font-weight: 700;
            color: var(--blue-600);
            background: var(--slate-50);
            padding: 6px 12px;
            border-radius: 8px;
            display: inline-block;
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- VUE 1 : Formulaire d'inscription -->
        <asp:Panel ID="pnlForm" runat="server" CssClass="card">

            <div class="card-header">
                <div class="logo">M</div>
                <h1>Créer votre compte</h1>
                <p>Commencez en quelques secondes — gratuit, aucune carte requise</p>
            </div>

            <div class="card-body">

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                    <asp:Literal ID="litError" runat="server" />
                </asp:Panel>

                <div class="field-row">
                    <div class="field">
                        <label for="<%= tbFirstName.ClientID %>">Prénom</label>
                        <asp:TextBox ID="tbFirstName" runat="server" placeholder="Jean" />
                    </div>
                    <div class="field">
                        <label for="<%= tbLastName.ClientID %>">Nom</label>
                        <asp:TextBox ID="tbLastName" runat="server" placeholder="Tremblay" />
                    </div>
                </div>

                <div class="field">
                    <label for="<%= tbEmail.ClientID %>">Adresse courriel *</label>
                    <asp:TextBox ID="tbEmail" runat="server" TextMode="Email"
                        placeholder="vous@exemple.com" autofocus="autofocus" />
                </div>

                <div class="field">
                    <label for="<%= tbPassword.ClientID %>">Mot de passe *</label>
                    <asp:TextBox ID="tbPassword" runat="server" TextMode="Password"
                        placeholder="••••••••" ClientIDMode="Static" />
                    <div class="strength-bar"><div id="strength-fill"></div></div>
                    <div class="strength-text" id="strength-text" style="color: var(--slate-500);">
                        Minimum 8 caractères
                    </div>
                </div>

                <div class="field">
                    <label for="<%= tbPasswordConfirm.ClientID %>">Confirmer le mot de passe *</label>
                    <asp:TextBox ID="tbPasswordConfirm" runat="server" TextMode="Password"
                        placeholder="••••••••" />
                </div>

                <label class="terms">
                    <asp:CheckBox ID="cbTerms" runat="server" />
                    <span>
                        J'accepte les <a href="#">Conditions d'utilisation</a>
                        et la <a href="#">Politique de confidentialité</a> de MngConsul.
                    </span>
                </label>

                <asp:Button ID="btnRegister" runat="server"
                    Text="Créer mon compte" CssClass="btn-submit" />

            </div>

            <div class="card-footer">
                Déjà un compte ?
                <asp:HyperLink ID="lnkLogin" runat="server" NavigateUrl="~/wbfLogin.aspx">
                    Se connecter
                </asp:HyperLink>
            </div>

        </asp:Panel>


        <!-- VUE 2 : Confirmation après inscription -->
        <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="card">
            <div class="success-card">
                <div class="success-icon">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <h1>Vérifiez votre courriel</h1>
                <p>
                    Nous venons d'envoyer un lien d'activation à
                </p>
                <span class="email-shown">
                    <asp:Literal ID="litSuccessEmail" runat="server" />
                </span>
                <p style="margin-top: 18px;">
                    Cliquez sur le lien dans le courriel pour activer votre compte.
                    Le lien est valide pendant 24 heures.
                </p>
                <p style="font-size: 12px; color: var(--slate-500);">
                    Vous n'avez rien reçu ? Vérifiez vos courriels indésirables ou
                    <asp:LinkButton ID="lnkResend" runat="server" Style="color: var(--blue-600); font-weight: 700;">
                        renvoyer le lien
                    </asp:LinkButton>.
                </p>
            </div>
        </asp:Panel>

        <script type="text/javascript">

            // ===== Force de mot de passe =====
            (function () {
                var input = document.getElementById('tbPassword');
                if (!input) return;

                var fill = document.getElementById('strength-fill');
                var text = document.getElementById('strength-text');

                input.addEventListener('input', function () {
                    var v = input.value || '';
                    var score = 0;
                    if (v.length >= 8) score++;
                    if (/[a-z]/.test(v) && /[A-Z]/.test(v)) score++;
                    if (/[0-9]/.test(v)) score++;
                    if (/[^a-zA-Z0-9]/.test(v)) score++;

                    var widths = ['0%', '25%', '50%', '75%', '100%'];
                    var colors = ['#e2e8f0', '#ef4444', '#f59e0b', '#3b82f6', '#10b981'];
                    var labels = ['', 'Très faible', 'Faible', 'Bon', 'Excellent'];

                    fill.style.width = widths[score];
                    fill.style.background = colors[score];
                    text.textContent = v.length === 0
                        ? 'Minimum 8 caractères'
                        : labels[score];
                    text.style.color = score >= 3 ? '#10b981'
                        : score >= 2 ? '#f59e0b'
                            : score >= 1 ? '#ef4444'
                                : 'var(--slate-500)';
                });
            })();

        </script>

    </form>
</body>
</html>
