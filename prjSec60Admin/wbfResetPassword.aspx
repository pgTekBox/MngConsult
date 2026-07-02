<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfResetPassword.aspx.vb"
    Inherits="prjSec60Admin.wbfResetPassword" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Réinitialisation — Sec60Admin</title>
    <style>
        :root {
            --font: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --primary: #2563eb; --danger: #dc2626; --ok: #16a34a;
            --shadow: 0 18px 50px rgba(2,6,23,.12);
        }
        * { box-sizing: border-box; }
        html, body { height: 100%; margin: 0; }
        body {
            font-family: var(--font); color: var(--text);
            background: radial-gradient(900px 450px at 20% 0%, rgba(37,99,235,.16), transparent 60%),
                        radial-gradient(900px 450px at 80% 0%, rgba(6,182,212,.12), transparent 60%), var(--bg);
            display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px;
        }
        .login-card { width: 100%; max-width: 400px; background: var(--card); border: 1px solid var(--line); border-radius: 18px; box-shadow: var(--shadow); padding: 28px; }
        .brand { display: flex; align-items: center; gap: 10px; margin-bottom: 6px; }
        .brand-dot { width: 12px; height: 12px; border-radius: 999px; background: var(--primary); box-shadow: 0 0 0 6px rgba(37,99,235,.14); }
        .brand-title { font-weight: 900; font-size: 18px; }
        .brand-sub { font-size: 12px; color: var(--muted); font-weight: 700; }
        h1 { font-size: 20px; margin: 14px 0 4px; }
        .lead { font-size: 13px; color: var(--muted); margin: 0 0 20px; }
        .field { margin-bottom: 14px; }
        .field label { display: block; font-size: 12px; color: #334155; margin-bottom: 6px; font-weight: 700; }
        .inp { width: 100%; padding: 11px 12px; border: 1px solid var(--line); border-radius: 12px; outline: none; background: #fff; color: var(--text); font-family: var(--font); font-size: 14px; }
        .inp:focus { border-color: rgba(37,99,235,.5); box-shadow: 0 0 0 4px rgba(37,99,235,.12); }
        .btn { width: 100%; cursor: pointer; border: 1px solid rgba(37,99,235,.4); border-radius: 12px; padding: 12px; background: var(--primary); color: #fff; font-weight: 800; font-size: 14px; font-family: var(--font); margin-top: 6px; }
        .btn:hover { filter: brightness(1.05); }
        .msg { margin: 0 0 16px; padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger); }
        .msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: var(--ok); }
        .linkrow { margin-top: 14px; text-align: center; }
        .linkrow a { color: var(--primary); font-size: 13px; font-weight: 700; text-decoration: none; }
        .linkrow a:hover { text-decoration: underline; }
        .foot { margin-top: 18px; font-size: 11px; color: var(--muted); text-align: center; }
    </style>
</head>
<body>
    <form id="form1" runat="server" defaultbutton="btnSave" defaultfocus="txtPassword">
        <div class="login-card">

            <div class="brand">
                <span class="brand-dot"></span>
                <span class="brand-title">Sec60Admin</span>
                <span class="brand-sub">Console</span>
            </div>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <%-- Formulaire de saisie du nouveau mot de passe --%>
            <asp:Panel ID="pnlForm" runat="server">
                <h1>Nouveau mot de passe</h1>
                <p class="lead">Choisissez un nouveau mot de passe pour votre compte.</p>

                <div class="field">
                    <label>Nouveau mot de passe</label>
                    <asp:TextBox ID="txtPassword" runat="server" CssClass="inp" TextMode="Password" placeholder="••••••••" />
                </div>
                <div class="field">
                    <label>Confirmation</label>
                    <asp:TextBox ID="txtPasswordConfirm" runat="server" CssClass="inp" TextMode="Password" placeholder="••••••••" />
                </div>

                <asp:Button ID="btnSave" runat="server" CssClass="btn" Text="Réinitialiser" />
            </asp:Panel>

            <div class="linkrow">
                <asp:HyperLink ID="lnkLogin" runat="server" NavigateUrl="~/wbfLogin.aspx">← Aller à la connexion</asp:HyperLink>
            </div>

            <div class="foot">© <%= DateTime.Now.Year %> Sec60Admin</div>

        </div>
    </form>
</body>
</html>
