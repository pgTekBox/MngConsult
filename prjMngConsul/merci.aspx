<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="merci.aspx.vb" Inherits="MngConsul.merci" %>

<!DOCTYPE html>
<html lang="<%= Lang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("title") %></title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --brand: #006aff; --ok: #16a34a; --ok-weak: #f0fdf4;
        }
        html, body { height: 100%; margin: 0; }
        body { font-family: var(--font); color: var(--text);
               background: radial-gradient(1200px 600px at 20% 0%, #eff6ff 0%, transparent 45%), var(--bg);
               display: flex; align-items: center; justify-content: center; padding: 24px; }
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 18px;
                box-shadow: 0 18px 40px rgba(15,23,42,.10); padding: 34px 30px; max-width: 460px;
                width: 100%; text-align: center; }
        .check { width: 76px; height: 76px; border-radius: 50%; background: var(--ok-weak);
                 display: flex; align-items: center; justify-content: center; margin: 0 auto 18px;
                 border: 1px solid #bbf7d0; }
        h1 { font-size: 23px; font-weight: 900; margin: 0 0 8px; }
        .sub { font-size: 15px; color: var(--muted); line-height: 1.5; margin: 0 0 20px; }
        .ref { background: #f8fafc; border: 1px solid var(--line); border-radius: 12px;
               padding: 12px 14px; font-size: 13px; color: #334155; margin-bottom: 20px; }
        .ref .k { color: var(--muted); font-weight: 600; }
        .ref .v { font-family: ui-monospace, Menlo, Consolas, monospace; font-weight: 800; word-break: break-all; }
        .brand { display: flex; align-items: center; justify-content: center; gap: 12px; margin: 0 0 20px; }
        .brand .logo-sq { width: 48px; height: 48px; border-radius: 12px; flex: 0 0 48px;
            background: var(--brand); color: #fff; font-weight: 900; font-size: 22px;
            display: flex; align-items: center; justify-content: center; position: relative; overflow: hidden; }
        .brand .logo-sq img { position: absolute; inset: 0; width: 100%; height: 100%;
            object-fit: contain; background: #fff; border-radius: 12px; }
        .brand .co-name { font-size: 17px; font-weight: 800; color: var(--text); text-align: left; }
        .amount { font-size: 34px; font-weight: 900; color: var(--ok); margin: 0 0 6px; letter-spacing: -.5px; }
        .amount-lbl { font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .4px; margin-bottom: 18px; }
        .foot { font-size: 12.5px; color: var(--muted); }
        .foot a { color: var(--brand); font-weight: 700; text-decoration: none; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="card">

            <asp:Panel ID="pnlBrand" runat="server" Visible="false" CssClass="brand">
                <div class="logo-sq"><asp:Literal ID="litInitial" runat="server" /><asp:Literal ID="litLogoImg" runat="server" /></div>
                <div class="co-name"><asp:Literal ID="litCompany" runat="server" /></div>
            </asp:Panel>

            <div class="check">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 6 9 17l-5-5" />
                </svg>
            </div>
            <h1><%= L("title") %></h1>

            <asp:Panel ID="pnlAmount" runat="server" Visible="false">
                <div class="amount"><asp:Literal ID="litAmount" runat="server" /></div>
                <div class="amount-lbl"><%= L("amountLbl") %></div>
            </asp:Panel>

            <p class="sub"><%= L("sub") %></p>

            <asp:Panel ID="pnlRef" runat="server" Visible="false" CssClass="ref">
                <div class="k"><%= L("refLabel") %></div>
                <div class="v"><asp:Literal ID="litRef" runat="server" /></div>
            </asp:Panel>

            <div class="foot"><%= L("foot") %></div>
        </div>
    </form>
</body>
</html>
