<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfLogin.aspx.vb" Inherits="MngConsul.wbfLogin" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Connexion — MngConsul</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --primary: #2563eb;
            --secondary: #06b6d4;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --danger: #dc2626;
            --shadow: 0 20px 50px rgba(15,23,42,.15);
        }
        * { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }
        body {
            font-family: var(--font);
            color: var(--text);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            background:
                radial-gradient(800px 500px at 20% 10%, #eef2ff 0%, transparent 60%),
                radial-gradient(800px 500px at 80% 90%, #ecfeff 0%, transparent 60%),
                #f6f7fb;
        }

        .login-card {
            width: 100%;
            max-width: 420px;
            background: #fff;
            border-radius: 20px;
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .login-header {
            padding: 32px 32px 8px 32px;
            text-align: center;
        }

        .login-logo {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            border-radius: 18px;
            color: white;
            font-size: 30px;
            font-weight: 800;
            display: inline-flex;
            align-items: center; justify-content: center;
            margin-bottom: 16px;
            box-shadow: 0 8px 20px rgba(37,99,235,.3);
        }

        .login-title {
            font-size: 24px;
            font-weight: 800;
            margin: 0 0 4px 0;
        }

        .login-sub {
            color: var(--muted);
            font-size: 14px;
            margin-bottom: 0;
        }

        .login-body {
            padding: 24px 32px 32px 32px;
        }

        .field {
            margin-bottom: 14px;
        }

        .field label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 6px;
        }

        .field input[type="text"],
        .field input[type="email"],
        .field input[type="password"] {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid var(--line);
            border-radius: 12px;
            font-size: 14px;
            font-family: var(--font);
            outline: none;
            background: #fff;
            transition: border-color .15s, box-shadow .15s;
        }

        .field input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        .check-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 8px 0 18px 0;
            font-size: 13px;
        }

        .check-row label {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            color: var(--muted);
        }

        .btn-login {
            width: 100%;
            padding: 13px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
            font-family: var(--font);
            transition: transform .12s, box-shadow .12s;
        }
        .btn-login:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 20px rgba(37,99,235,.3);
        }
        .btn-login:active { transform: translateY(0); }

        .login-error {
            padding: 10px 14px;
            background: rgba(220,38,38,.08);
            border: 1px solid rgba(220,38,38,.25);
            color: var(--danger);
            border-radius: 10px;
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 14px;
        }

        .login-footer {
            padding: 16px;
            text-align: center;
            font-size: 12px;
            color: var(--muted);
            background: #fafbfc;
            border-top: 1px solid var(--line);
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="login-card">

            <div class="login-header">
                <div class="login-logo">M</div>
                <h1 class="login-title">Bienvenue</h1>
                <p class="login-sub">Connectez-vous à MngConsul</p>
            </div>

            <div class="login-body">

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="login-error">
                    <asp:Literal ID="litError" runat="server" />
                </asp:Panel>

                <div class="field">
                    <label for="<%= tbEmail.ClientID %>">Courriel</label>
                    <asp:TextBox ID="tbEmail" runat="server" TextMode="Email"
                        placeholder="vous@exemple.com" autofocus="autofocus" />
                </div>

                <div class="field">
                    <label for="<%= tbPassword.ClientID %>">Mot de passe</label>
                    <asp:TextBox ID="tbPassword" runat="server" TextMode="Password"
                        placeholder="••••••••" />
                </div>

                <div class="check-row">
                    <label>
                        <asp:CheckBox ID="cbRemember" runat="server" />
                        <span>Se souvenir de moi</span>
                    </label>
                </div>

                <asp:Button ID="btnLogin" runat="server"
                    Text="Se connecter" CssClass="btn-login" />
            </div>

            <div class="login-footer">
                © 2026 MngConsul — Tous droits réservés
            </div>

        </div>
    </form>
</body>
</html>
