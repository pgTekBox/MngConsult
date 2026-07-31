<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfSupplierPaymentDream.aspx.vb" Inherits="MngConsul.wbfSupplierPaymentDream" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>DreamPaiement EFT</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --teal: #0d9488; --teal-weak: #f0fdfa; --danger: #dc2626; --ok: #16a34a;
        }
        html, body { height: 100%; margin: 0; }
        body { font-family: var(--font); color: var(--text);
               background: radial-gradient(1200px 600px at 20% 0%, #ecfeff 0%, transparent 45%), var(--bg); }
        .wrap { max-width: 680px; margin: 22px auto; padding: 0 18px 30px; }
        .brand { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
        .brand .logo { width: 44px; height: 44px; border-radius: 12px; flex: 0 0 44px;
            background: linear-gradient(135deg, #0d9488, #0f766e); display: flex; align-items: center; justify-content: center; }
        .brand h1 { font-size: 20px; font-weight: 900; margin: 0; }
        .brand .sub { font-size: 13px; color: var(--muted); margin-top: 2px; }
        .card { background: var(--card); border: 1px solid var(--line); border-radius: 16px;
                box-shadow: 0 12px 28px rgba(15,23,42,.08); padding: 18px; margin-bottom: 14px; }
        .rowline { display: flex; justify-content: space-between; gap: 12px; padding: 6px 0; }
        .rowline .k { color: var(--muted); font-size: 13px; }
        .rowline .v { font-weight: 800; }
        .amount { font-size: 24px; font-weight: 900; color: var(--teal); }
        .sec-title { font-weight: 900; font-size: 14px; margin: 0 0 4px; }
        .sec-hint { font-size: 12px; color: var(--muted); margin: 0 0 12px; }
        .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .field { display: flex; flex-direction: column; gap: 5px; }
        .field label { font-size: 12px; font-weight: 700; color: #334155; }
        .field input, .field select { padding: 10px 12px; border: 1px solid var(--line); border-radius: 10px;
            outline: none; background: #fff; box-sizing: border-box; font-family: var(--font); font-size: 14px; }
        .field input:focus, .field select:focus { border-color: var(--teal); box-shadow: 0 0 0 3px rgba(13,148,136,.15); }
        .notice { background: var(--teal-weak); border: 1px solid #99f6e4; color: #0f766e;
                  border-radius: 12px; padding: 12px 14px; font-size: 12.5px; font-weight: 600; }
        .msg { border-radius: 10px; padding: 10px 12px; font-size: 13px; font-weight: 700; margin-bottom: 12px; }
        .msg-ok { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
        .msg-err { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
        .bar { display: flex; justify-content: flex-end; gap: 10px; margin-top: 8px; }
        .btn { cursor: pointer; border: 1px solid var(--line); border-radius: 12px; padding: 11px 18px;
               background: #fff; color: var(--text); font-weight: 800; font-family: var(--font); }
        .btn.primary { border-color: var(--teal); background: var(--teal); color: #fff; }
        .btn.primary:disabled { opacity: .55; cursor: not-allowed; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="wrap">

            <div class="brand">
                <div class="logo">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" y1="21" x2="21" y2="21" /><line x1="5" y1="21" x2="5" y2="10" />
                        <line x1="19" y1="21" x2="19" y2="10" /><line x1="9" y1="21" x2="9" y2="10" />
                        <line x1="15" y1="21" x2="15" y2="10" /><polygon points="12 2 21 8 3 8" />
                    </svg>
                </div>
                <div>
                    <h1>DreamPaiement EFT</h1>
                    <div class="sub"><%= L("sub") %></div>
                </div>
            </div>

            <asp:Label ID="lblMsg" runat="server" Visible="false" />

            <%-- Récapitulatif facture --%>
            <div class="card">
                <div class="rowline"><span class="k"><%= L("supplier") %></span><span class="v"><asp:Literal ID="litSupplier" runat="server" /></span></div>
                <div class="rowline"><span class="k"><%= L("invoice") %></span><span class="v">#<asp:Literal ID="litDoc" runat="server" /></span></div>
                <div class="rowline"><span class="k"><%= L("amount") %></span><span class="v amount"><asp:Literal ID="litAmount" runat="server" /></span></div>
            </div>

            <%-- Entreprise (bénéficiaire) : accountName + adresse = payeeAccountInfo côté Dream --%>
            <div class="card">
                <div class="sec-title"><%= L("companySection") %></div>
                <div class="sec-hint"><%= L("companyHint") %></div>
                <div class="grid2">
                    <div class="field"><label><%= L("companyName") %></label><asp:TextBox ID="txtAccountName" runat="server" /></div>
                    <div class="field"><label><%= L("address") %></label><asp:TextBox ID="txtAddress" runat="server" /></div>
                    <div class="field"><label><%= L("city") %></label><asp:TextBox ID="txtCity" runat="server" /></div>
                    <div class="field"><label><%= L("province") %></label><asp:TextBox ID="txtProvince" runat="server" MaxLength="2" /></div>
                    <div class="field"><label><%= L("postal") %></label><asp:TextBox ID="txtPostal" runat="server" /></div>
                </div>
            </div>

            <%-- Personne-contact : contactName + contactInfo = payeeUser côté Dream --%>
            <div class="card">
                <div class="sec-title"><%= L("contactSection") %></div>
                <div class="sec-hint"><%= L("contactHint") %></div>
                <div class="grid2">
                    <div class="field"><label><%= L("firstName") %></label><asp:TextBox ID="txtFirstName" runat="server" /></div>
                    <div class="field"><label><%= L("lastName") %></label><asp:TextBox ID="txtLastName" runat="server" /></div>
                    <div class="field"><label><%= L("email") %></label><asp:TextBox ID="txtEmail" runat="server" TextMode="Email" /></div>
                </div>
            </div>

            <%-- Compte bancaire EFT --%>
            <div class="card">
                <div class="sec-title"><%= L("bankSection") %></div>
                <div class="grid2">
                    <div class="field"><label><%= L("accountType") %></label>
                        <asp:DropDownList ID="ddlAccountType" runat="server">
                            <asp:ListItem Value="CHEQUING" Text="Chèque / Chequing" />
                            <asp:ListItem Value="SAVINGS" Text="Épargne / Savings" />
                        </asp:DropDownList>
                    </div>
                    <div class="field"><label><%= L("institution") %></label><asp:TextBox ID="txtInstitution" runat="server" MaxLength="3" placeholder="003" /></div>
                    <div class="field"><label><%= L("transit") %></label><asp:TextBox ID="txtTransit" runat="server" MaxLength="5" placeholder="12345" /></div>
                    <div class="field"><label><%= L("accountNumber") %></label><asp:TextBox ID="txtAccountNumber" runat="server" /></div>
                </div>
            </div>

            <div class="notice"><%= L("verifyNotice") %></div>

            <div class="bar">
                <button type="button" class="btn" onclick="closeWin(); return false;"><%= L("close") %></button>
                <asp:Button ID="btnPay" runat="server" CssClass="btn primary" Text="Payer par EFT" />
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
        </script>
    </form>
</body>
</html>
