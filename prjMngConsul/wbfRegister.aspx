<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfRegister.aspx.vb" Inherits="MngConsul.wbfRegister" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>" class="<%= If(EnFenetre, "en-fenetre", "") %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Inscription — 60Sec-AI</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-50: #f8fafc;  --slate-100: #f1f5f9;
            --slate-200: #D5DDE8; --slate-300: #cbd5e1;
            --slate-400: #94a3b8; --slate-500: #44536E;
            --slate-600: #44536E; --slate-700: #334155;
            --slate-800: #1e293b;
            --blue-500: #3b82f6;  --blue-600: #1B4F9C;  --blue-700: #143A73;
            --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444;
        }

        body {
            font-family: var(--font);
            color: var(--slate-800);
            min-height: 100vh;
            display: flex;
            align-items: flex-start;   /* + .card margin auto : centré, mais jamais coupé en haut si la carte dépasse l'écran */
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
            margin: auto 0;
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

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 18px;
            text-decoration: none;
            cursor: pointer;
        }
        .brand img { width: 48px; height: 48px; display: block; }
        .brand .brand-name {
            font-size: 28px;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: var(--slate-800);
        }
        .brand:hover { opacity: .85; }

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

        .success-card .abo-recap { margin-top: 20px; }
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

        /* Sélecteur de langue FR · EN · ES (en haut à droite de la carte) */
        .card { position: relative; }
        .card > .lang-switch + .card-header { padding-top: 60px; }   /* le logo passe sous le sélecteur */
        .lang-switch { position: absolute; top: 16px; right: 16px; display: inline-flex; gap: 2px; padding: 3px; border-radius: 999px; background: #fff; border: 1px solid var(--slate-200); }
        .lang-switch a { padding: 5px 11px; border-radius: 999px; font-size: 12px; font-weight: 800; color: var(--slate-600); text-decoration: none; letter-spacing: .03em; }
        .lang-switch a:hover { background: var(--slate-100); }
        .lang-switch a.on { background: var(--blue-600); color: #fff; }

        /* Forfait choisi : carte large, formulaire à gauche et récapitulatif à droite,
           pour que la page tienne en hauteur. */
        .card.card-large { max-width: 980px; }
        .card-large > .lang-switch + .card-header { padding-top: 28px; }
        .card-large .card-header { padding-bottom: 8px; }
        .card-large .brand { margin-bottom: 10px; }
        .card-large .reg-cols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); align-items: start; }
        .card-large .reg-recap { padding: 24px 32px 16px 0; }
        .card-large .reg-recap .abo-recap { margin: 0; padding: 14px 18px; }
        .card-large .reg-recap .abo-tab td { padding: 4px 0; }
        .card-large .reg-recap .abo-inclus ul { columns: 2; column-gap: 16px; }
        .card-large .reg-recap .abo-inclus li { break-inside: avoid; }
        /* Vue « Vérifiez votre courriel » : message à gauche, récapitulatif à droite */
        .card-large .success-card { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 32px; align-items: center; padding: 40px 32px; }
        .card-large .success-card .reg-recap { padding: 0; }
        @media (max-width: 860px) {
            .card-large .reg-cols, .card-large .success-card { grid-template-columns: minmax(0, 1fr); }
            .card-large .reg-cols .reg-recap { order: -1; padding: 16px 32px 0; }
            .card-large > .lang-switch + .card-header { padding-top: 60px; }   /* le logo sous le sélecteur */
            .card-large .reg-recap .abo-inclus ul { columns: 1; }
        }
        /* En fenêtre (cadre par-dessus la page d'accueil, ?popup=1) : seule la carte, sans fond
           ni ombre ; le cadre porte l'arrondi et l'ombre. Le × de la page d'accueil occupe le
           coin haut droit : le sélecteur de langue passe à gauche. */
        html.en-fenetre, html.en-fenetre body { height: auto; min-height: 0; background: #fff; }
        html.en-fenetre body { display: block; padding: 0; }
        html.en-fenetre .card { max-width: none; border-radius: 0; box-shadow: none; margin: 0; }
        html.en-fenetre .lang-switch { right: auto; left: 16px; }
    </style>
    <link href="css/abo-recap.css?v=2026112601" rel="stylesheet" />
    <script src="js/appPopup.js?v=2026111704"></script>
</head>

<body>
    <form id="form1" runat="server">

        <!-- VUE 1 : Formulaire d'inscription -->
        <asp:Panel ID="pnlForm" runat="server" CssClass="card">

            <%-- Langue de la page : FR · EN · ES (garde le forfait choisi ?ab=) --%>
            <nav class="lang-switch" aria-label="<%= L("langLabel") %>"><%= LiensLangues() %></nav>

            <div class="card-header">
                <a class="brand" href="LandingPage.aspx?lang=<%= CurrentLang %>" target="<%= If(EnFenetre, "_top", "_self") %>">
                    <img src="Images/logo.svg" alt="60Sec-AI" />
                    <span class="brand-name">60Sec-AI</span>
                </a>
                <h1><%= L("heading") %></h1>
                <p><%= SousTitre() %></p>
            </div>

            <%-- Avec un forfait choisi : formulaire à gauche, récapitulatif de l'abonnement
                 à droite (une seule colonne, récapitulatif en premier, sur écran étroit). --%>
            <div class="reg-cols">
            <div class="card-body">

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert error">
                    <asp:Literal ID="litError" runat="server" />
                </asp:Panel>

                <div class="field-row">
                    <div class="field">
                        <label for="<%= tbFirstName.ClientID %>"><%= L("firstName") %></label>
                        <asp:TextBox ID="tbFirstName" runat="server" />
                    </div>
                    <div class="field">
                        <label for="<%= tbLastName.ClientID %>"><%= L("lastName") %></label>
                        <asp:TextBox ID="tbLastName" runat="server" />
                    </div>
                </div>

                <div class="field">
                    <label for="<%= tbEmail.ClientID %>"><%= L("email") %></label>
                    <asp:TextBox ID="tbEmail" runat="server" TextMode="Email"
                        autofocus="autofocus" />
                </div>

                <div class="field">
                    <label for="<%= tbPassword.ClientID %>"><%= L("password") %></label>
                    <asp:TextBox ID="tbPassword" runat="server" TextMode="Password"
                        ClientIDMode="Static" />
                    <div class="strength-bar"><div id="strength-fill"></div></div>
                    <div class="strength-text" id="strength-text" style="color: var(--slate-500);">
                        <%= L("pwHint") %>
                    </div>
                </div>

                <div class="field">
                    <label for="<%= tbPasswordConfirm.ClientID %>"><%= L("passwordConfirm") %></label>
                    <asp:TextBox ID="tbPasswordConfirm" runat="server" TextMode="Password" />
                </div>

                <label class="terms">
                    <asp:CheckBox ID="cbTerms" runat="server" />
                    <span>
                        <%= L("termsBefore") %><a href="#"><%= L("termsCgu") %></a><%= L("termsMid") %><a href="#"><%= L("termsPrivacy") %></a><%= L("termsAfter") %>
                    </span>
                </label>

                <asp:Button ID="btnRegister" runat="server"
                    Text="Créer mon compte" CssClass="btn-submit" />

            </div>
            <%= If(PlanChoisi Is Nothing, "", "<aside class=""reg-recap"">" & PlanChoisiHtml() & "</aside>") %>
            </div>

            <div class="card-footer">
                <%= L("already") %>
                <asp:HyperLink ID="lnkLogin" runat="server" NavigateUrl="~/Default.aspx" />
            </div>

        </asp:Panel>


        <!-- VUE 2 : Confirmation après inscription -->
        <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="card">
            <div class="success-card">
              <div class="success-main">
                <div class="success-icon">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <h1><%= L("successTitle") %></h1>
                <p>
                    <%= L("successIntro") %>
                </p>
                <span class="email-shown">
                    <asp:Literal ID="litSuccessEmail" runat="server" />
                </span>
                <p style="margin-top: 18px;">
                    <%= L("successBody") %>
                </p>
                <p style="font-size: 12px; color: var(--slate-500);">
                    <%= L("resendPrompt") %>
                    <asp:LinkButton ID="lnkResend" runat="server" Style="color: var(--blue-600); font-weight: 700;" />.
                </p>
                <asp:Literal ID="litResendStatus" runat="server" />
                  <p style="margin-top: 18px;">
                  <asp:Button ID="btnFerme" runat="server"  
      Text="Vous pouvez fermer cette page." CssClass="btn-submit" CausesValidation="false" />
   </p>
              </div>
              <%= If(PlanChoisi Is Nothing, "", "<aside class=""reg-recap"">" & PlanChoisiHtml() & "</aside>") %>
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
                    var colors = ['#D5DDE8', '#ef4444', '#f59e0b', '#3b82f6', '#10b981'];
                    var labels = ['', '<%= L("strWeak") %>', '<%= L("strLow") %>', '<%= L("strGood") %>', '<%= L("strExcellent") %>'];

                    fill.style.width = widths[score];
                    fill.style.background = colors[score];
                    text.textContent = v.length === 0
                        ? '<%= L("pwHint") %>'
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
