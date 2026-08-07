<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfEmployeeEdit.aspx.vb" Inherits="MngConsul.wbfEmployeeEdit" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><%= L("pageTitle") %></title>
    <style>
        :root { --font: system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif; --text:#0f172a; --muted:#64748b; --line:#e2e8f0; --primary:#2563eb; }
        html,body { margin:0; height:100%; }
        body { font-family:var(--font); color:var(--text); background:#f6f7fb; }
        .wrap { padding:18px 20px 90px; }
        h1 { font-size:18px; font-weight:900; margin:0 0 14px; }
        .grid { display:grid; grid-template-columns:1fr 1fr; gap:12px 16px; }
        .field { display:flex; flex-direction:column; gap:4px; }
        .field.full { grid-column:1 / -1; }
        label { font-size:12px; font-weight:800; color:#334155; }
        input[type=text], input[type=email], input[type=date], select {
            padding:9px 11px; border:1px solid #cbd5e1; border-radius:8px; font:inherit; box-sizing:border-box; width:100%;
        }
        .row-inline { display:flex; align-items:center; gap:10px; }
        .chk { display:flex; align-items:center; gap:8px; font-weight:700; font-size:13px; }
        .box-note { font-size:13px; color:#475569; background:#eff6ff; border:1px solid #dbeafe; border-radius:10px; padding:10px 12px; }
        .box-none { color:#94a3b8; font-style:italic; }
        .mono { font-family:ui-monospace,Consolas,monospace; font-weight:700; }
        .footer { position:fixed; left:0; right:0; bottom:0; background:#fff; border-top:1px solid var(--line); padding:12px 20px; display:flex; justify-content:flex-end; gap:10px; }
        .btn { padding:10px 18px; border-radius:10px; font-weight:800; font-size:14px; cursor:pointer; border:1px solid var(--line); background:#fff; color:#0f172a; text-decoration:none; display:inline-flex; align-items:center; }
        .btn.primary { background:var(--primary); border-color:var(--primary); color:#fff; }
        .msg { margin:0 0 12px; padding:10px 14px; border-radius:10px; font-size:13px; font-weight:700; }
        .msg.err { background:rgba(239,68,68,.1); color:#dc2626; border:1px solid rgba(239,68,68,.3); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="sm1" runat="server" />
        <div class="wrap">
            <h1><asp:Literal ID="litTitle" runat="server" /></h1>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <div class="msg err"><asp:Literal ID="litMsg" runat="server" /></div>
            </asp:Panel>

            <div class="grid">
                <div class="field"><label><%= L("empNumber") %></label><asp:TextBox ID="txtNumber" runat="server" /></div>
                <div class="field"><label><%= L("displayName") %></label><asp:TextBox ID="txtDisplay" runat="server" /></div>
                <div class="field"><label><%= L("firstName") %></label><asp:TextBox ID="txtFirst" runat="server" /></div>
                <div class="field"><label><%= L("lastName") %></label><asp:TextBox ID="txtLast" runat="server" /></div>
                <div class="field"><label><%= L("jobTitle") %></label><asp:TextBox ID="txtJob" runat="server" /></div>
                <div class="field"><label><%= L("department") %></label><asp:TextBox ID="txtDept" runat="server" /></div>
                <div class="field full"><label><%= L("extEmail") %></label><asp:TextBox ID="txtEmail" runat="server" TextMode="Email" /></div>
                <div class="field"><label><%= L("phone") %></label><asp:TextBox ID="txtPhone" runat="server" /></div>
                <div class="field"><label><%= L("mobile") %></label><asp:TextBox ID="txtMobile" runat="server" /></div>
                <div class="field"><label><%= L("city") %></label><asp:TextBox ID="txtCity" runat="server" /></div>
                <div class="field"><label><%= L("hireDate") %></label><asp:TextBox ID="txtHire" runat="server" TextMode="Date" /></div>
                <div class="field"><label><%= L("status") %></label><asp:TextBox ID="txtStatus" runat="server" /></div>
                <div class="field"><label><%= L("type") %></label><asp:TextBox ID="txtType" runat="server" /></div>
                <div class="field">
                    <label><%= L("color") %></label>
                    <div class="row-inline">
                        <input type="color" id="cpPick" value="#2563eb" oninput="document.getElementById('<%= txtColor.ClientID %>').value=this.value;" />
                        <asp:TextBox ID="txtColor" runat="server" CssClass="mono" />
                    </div>
                </div>
                <div class="field">
                    <label><%= L("active") %></label>
                    <label class="chk"><asp:CheckBox ID="chkActive" runat="server" Checked="true" /><%= L("activeYes") %></label>
                </div>

                <div class="field full">
                    <label><%= L("mailbox") %></label>
                    <div class="box-note">
                        <asp:Literal ID="litMailbox" runat="server" />
                    </div>
                </div>
            </div>
        </div>

        <div class="footer">
            <a href="#" class="btn" onclick="closeWin(); return false;"><%= L("cancel") %></a>
            <asp:Button ID="btnSave" runat="server" CssClass="btn primary" Text="Enregistrer" />
        </div>
    </form>

    <script type="text/javascript">
        function GetRadWindow() {
            var o = null;
            if (window.radWindow) o = window.radWindow;
            else if (window.frameElement && window.frameElement.radWindow) o = window.frameElement.radWindow;
            return o;
        }
        function closeWin() { var w = GetRadWindow(); if (w) w.close(); }
        // synchroniser le sélecteur de couleur au chargement
        (function () {
            var tb = document.getElementById('<%= txtColor.ClientID %>');
            var cp = document.getElementById('cpPick');
            if (tb && cp && /^#[0-9a-fA-F]{6}$/.test(tb.value)) cp.value = tb.value;
        })();
    </script>
</body>
</html>
