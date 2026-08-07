<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfMailboxReset.aspx.vb" Inherits="MngConsul.wbfMailboxReset" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("title") %></title>
    <style>
        :root { --font: system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif; --text:#0f172a; --muted:#64748b; --line:#e2e8f0; --primary:#2563eb; }
        html,body { margin:0; height:100%; }
        body { font-family:var(--font); color:var(--text);
               background: radial-gradient(1000px 500px at 50% -10%, #eef2ff 0%, transparent 55%), #f6f7fb;
               display:flex; align-items:center; justify-content:center; min-height:100vh; }
        .card { width:420px; max-width:calc(100vw - 32px); background:#fff; border:1px solid var(--line);
                border-radius:18px; box-shadow:0 20px 50px rgba(15,23,42,.10); padding:28px 26px; }
        .brand { display:flex; align-items:center; gap:10px; margin-bottom:16px; }
        .brand .dot { width:12px; height:12px; border-radius:999px; background:var(--primary); box-shadow:0 0 0 6px rgba(37,99,235,.12); }
        .brand b { font-weight:900; letter-spacing:.2px; }
        h1 { font-size:19px; font-weight:900; margin:0 0 6px; }
        p.sub { margin:0 0 18px; color:var(--muted); font-size:14px; line-height:1.5; }
        .mono { font-family:ui-monospace,Consolas,monospace; font-weight:700; color:#0f172a; }
        label { display:block; font-size:12px; font-weight:800; color:#334155; margin:12px 0 4px; }
        input[type=password] { width:100%; padding:11px 12px; border:1px solid #cbd5e1; border-radius:10px; font:inherit; box-sizing:border-box; }
        .btn { width:100%; margin-top:18px; padding:12px; background:var(--primary); color:#fff; border:none; border-radius:10px; font-weight:800; font-size:15px; cursor:pointer; }
        .msg { margin-top:14px; padding:10px 14px; border-radius:10px; font-size:13px; font-weight:700; }
        .msg.err { background:rgba(239,68,68,.1); color:#dc2626; border:1px solid rgba(239,68,68,.3); }
        .msg.ok  { background:rgba(16,185,129,.12); color:#059669; border:1px solid rgba(16,185,129,.3); }
        .hint { font-size:12px; color:var(--muted); margin-top:8px; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="card">
            <div class="brand"><span class="dot"></span><b>60sec.ca</b></div>

            <asp:Panel ID="pnlForm" runat="server">
                <h1><%= L("title") %></h1>
                <p class="sub"><asp:Literal ID="litIntro" runat="server" /></p>

                <label><%= L("pwd") %></label>
                <asp:TextBox ID="txtPwd" runat="server" TextMode="Password" autocomplete="new-password" />
                <label><%= L("pwd2") %></label>
                <asp:TextBox ID="txtPwd2" runat="server" TextMode="Password" autocomplete="new-password" />
                <div class="hint"><%= L("rule") %></div>

                <asp:Button ID="btnSet" runat="server" CssClass="btn" Text="Définir le mot de passe" />

                <asp:Panel ID="pnlErr" runat="server" Visible="false">
                    <div class="msg err"><asp:Literal ID="litErr" runat="server" /></div>
                </asp:Panel>
            </asp:Panel>

            <asp:Panel ID="pnlInvalid" runat="server" Visible="false">
                <h1><%= L("invalidTitle") %></h1>
                <p class="sub"><%= L("invalidBody") %></p>
            </asp:Panel>

            <asp:Panel ID="pnlDone" runat="server" Visible="false">
                <h1><%= L("doneTitle") %></h1>
                <div class="msg ok"><asp:Literal ID="litDone" runat="server" /></div>
                <p class="hint"><%= L("doneHint") %></p>
            </asp:Panel>
        </div>
    </form>
</body>
</html>
