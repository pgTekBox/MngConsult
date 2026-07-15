<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfCustomerPaymentLink.aspx.vb" Inherits="MngConsul.wbfCustomerPaymentLink" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Encaisser (Square)</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --brand: #006aff; --brand-weak: #eff6ff;
        }
        html, body { height: 100%; margin: 0; }
        body { font-family: var(--font); color: var(--text);
               background: radial-gradient(1200px 600px at 20% 0%, #eff6ff 0%, transparent 45%), var(--bg); }
        .wrap { max-width: 600px; margin: 22px auto; padding: 0 18px 30px; }
        .brand { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
        .brand .logo { width: 44px; height: 44px; border-radius: 12px; flex: 0 0 44px;
            background: linear-gradient(135deg, #006aff, #0052cc); display: flex; align-items: center; justify-content: center; }
        .brand h1 { font-size: 20px; font-weight: 900; margin: 0; }
        .brand .sub { font-size: 13px; color: var(--muted); margin-top: 2px; }
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 16px;
                box-shadow: 0 12px 28px rgba(15,23,42,.08); padding: 18px; margin-bottom: 14px; }
        .rowline { display: flex; justify-content: space-between; gap: 12px; padding: 6px 0; }
        .rowline .k { color: var(--muted); font-size: 13px; }
        .rowline .v { font-weight: 800; }
        .amount { font-size: 24px; font-weight: 900; color: var(--brand); }
        .notice { background: var(--brand-weak); border: 1px solid #bfdbfe; color: #1e40af;
                  border-radius: 12px; padding: 12px 14px; font-size: 12.5px; font-weight: 600; }
        .msg { border-radius: 10px; padding: 10px 12px; font-size: 13px; font-weight: 700; margin-bottom: 12px; }
        .msg-ok { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
        .msg-err { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
        .linkrow { display: flex; gap: 8px; align-items: center; }
        .linkrow input { flex: 1; padding: 10px 12px; border: 1px solid var(--line); border-radius: 10px;
            background: #f8fafc; font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 13px; }
        .lbl { font-size: 12px; font-weight: 700; color: #334155; margin: 0 0 6px; }
        .bar { display: flex; justify-content: flex-end; gap: 10px; margin-top: 8px; }
        .btn { cursor: pointer; border: 1px solid var(--line); border-radius: 12px; padding: 11px 18px;
               background: #fff; color: var(--text); font-weight: 800; font-family: var(--font); text-decoration: none; display: inline-block; }
        .btn.primary { border-color: var(--brand); background: var(--brand); color: #fff; }
        .btn.primary:disabled { opacity: .55; cursor: not-allowed; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="wrap">

            <div class="brand">
                <div class="logo">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
                        <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
                    </svg>
                </div>
                <div>
                    <h1><%= L("title") %></h1>
                    <div class="sub"><%= L("sub") %></div>
                </div>
            </div>

            <asp:Label ID="lblMsg" runat="server" Visible="false" />

            <div class="card">
                <div class="rowline"><span class="k"><%= L("customer") %></span><span class="v"><asp:Literal ID="litCustomer" runat="server" /></span></div>
                <div class="rowline"><span class="k"><%= L("invoice") %></span><span class="v">#<asp:Literal ID="litDoc" runat="server" /></span></div>
                <div class="rowline"><span class="k"><%= L("amount") %></span><span class="v amount"><asp:Literal ID="litAmount" runat="server" /></span></div>
            </div>

            <%-- Lien généré --%>
            <asp:Panel ID="pnlLink" runat="server" Visible="false" CssClass="card">
                <p class="lbl"><%= L("linkLabel") %></p>
                <div class="linkrow">
                    <asp:TextBox ID="txtLink" runat="server" ReadOnly="true" ClientIDMode="Static" />
                    <button type="button" class="btn" onclick="copyLink(); return false;"><%= L("copy") %></button>
                    <asp:HyperLink ID="lnkOpen" runat="server" CssClass="btn primary" Target="_blank"><%= L("open") %></asp:HyperLink>
                </div>
            </asp:Panel>

            <div class="notice"><%= L("payNotice") %></div>

            <div class="bar">
                <button type="button" class="btn" onclick="closeWin(); return false;"><%= L("close") %></button>
                <asp:Button ID="btnGenerate" runat="server" CssClass="btn primary" Text="Générer le lien" />
            </div>

        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var o = null;
                if (window.radWindow) o = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow) o = window.frameElement.radWindow;
                return o;
            }
            function closeWin() { var w = GetRadWindow(); if (w) w.close(); }
            function copyLink() {
                var t = document.getElementById("txtLink");
                if (!t) return;
                t.select(); t.setSelectionRange(0, 99999);
                try { document.execCommand("copy"); } catch (e) { }
            }
        </script>
    </form>
</body>
</html>
