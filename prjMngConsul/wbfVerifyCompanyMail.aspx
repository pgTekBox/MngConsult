<%@ Page Language="vb" AutoEventWireup="false"
    CodeBehind="wbfVerifyCompanyMail.aspx.vb" Inherits="MngConsul.wbfVerifyCompanyMail" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Vérification du courriel — 60Sec-AI</title>
    <style>
        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; height: 100%; }

        :root {
            --font: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
            --slate-200: #e2e8f0; --slate-500: #64748b;
            --slate-600: #475569; --slate-800: #1e293b;
            --blue-500: #3b82f6;  --blue-600: #2563eb;
            --cyan-500: #06b6d4;
            --green-500: #10b981; --green-600: #059669;
            --red-500: #ef4444; --red-600: #dc2626;
            --orange-500: #f59e0b;
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
            text-align: center;
            padding: 48px 32px;
        }

        .icon {
            width: 80px; height: 80px;
            border-radius: 50%;
            display: inline-flex;
            align-items: center; justify-content: center;
            color: white;
            margin-bottom: 22px;
        }
        .icon.success { background: linear-gradient(135deg, var(--green-500), var(--green-600)); box-shadow: 0 12px 24px rgba(16,185,129,.3); }
        .icon.error   { background: linear-gradient(135deg, var(--red-500), var(--red-600));     box-shadow: 0 12px 24px rgba(239,68,68,.3); }
        .icon.warn    { background: linear-gradient(135deg, var(--orange-500), #d97706);          box-shadow: 0 12px 24px rgba(245,158,11,.3); }

        h1 {
            font-size: 24px; font-weight: 800;
            margin: 0 0 12px 0;
            letter-spacing: -0.3px;
        }
        p {
            color: var(--slate-600);
            line-height: 1.6;
            margin: 0 0 24px 0;
        }

        .btn {
            display: inline-block;
            padding: 13px 28px;
            background: linear-gradient(135deg, var(--blue-600), var(--cyan-500));
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 800;
            text-decoration: none;
            font-family: var(--font);
            cursor: pointer;
            transition: transform .12s, box-shadow .12s;
        }
        .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 12px 24px rgba(37,99,235,.3);
        }

        .actions { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="card">

            <!-- VUE : Vérification réussie -->
            <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                <div class="icon success">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <h1><%= L("successTitle") %></h1>
                <p>
                    <%= L("successBefore") %><strong><asp:Literal ID="litEmail" runat="server" /></strong><%= L("successAfter") %>
                </p>
                <div class="actions">
                    <asp:HyperLink ID="lnkSettings" runat="server"
                        NavigateUrl="~/wbfSetting.aspx" CssClass="btn" />
                </div>
            </asp:Panel>

            <!-- VUE : Lien expiré -->
            <asp:Panel ID="pnlExpired" runat="server" Visible="false">
                <div class="icon warn">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                </div>
                <h1><%= L("expiredTitle") %></h1>
                <p><%= L("expiredMsg") %></p>
                <div class="actions">
                    <asp:HyperLink ID="lnkSettingsExpired" runat="server"
                        NavigateUrl="~/wbfSetting.aspx" CssClass="btn" />
                </div>
            </asp:Panel>

            <!-- VUE : Déjà vérifié -->
            <asp:Panel ID="pnlAlready" runat="server" Visible="false">
                <div class="icon success">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
                <h1><%= L("alreadyTitle") %></h1>
                <p><%= L("alreadyMsg") %></p>
                <div class="actions">
                    <asp:HyperLink ID="lnkSettingsAlready" runat="server"
                        NavigateUrl="~/wbfSetting.aspx" CssClass="btn" />
                </div>
            </asp:Panel>

            <!-- VUE : Lien invalide -->
            <asp:Panel ID="pnlInvalid" runat="server" Visible="false">
                <div class="icon error">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"></circle>
                        <line x1="15" y1="9" x2="9" y2="15"></line>
                        <line x1="9" y1="9" x2="15" y2="15"></line>
                    </svg>
                </div>
                <h1><%= L("invalidTitle") %></h1>
                <p><%= L("invalidMsg") %></p>
                <div class="actions">
                    <asp:HyperLink ID="lnkSettingsInvalid" runat="server"
                        NavigateUrl="~/wbfSetting.aspx" CssClass="btn" />
                </div>
            </asp:Panel>

        </div>

    </form>
</body>
</html>
