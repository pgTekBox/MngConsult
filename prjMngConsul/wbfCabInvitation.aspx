<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfCabInvitation.aspx.vb" Inherits="MngConsul.wbfCabInvitation" %>
<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Invitation — 60Sec-AI</title>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet" />
    <style>
        :root { --navy:#0E1F3D; --primary:#1B4F9C; --primary-dark:#143A73; --muted:#44536E; --line:#D5DDE8; --page:#F2F5F9; }
        * { box-sizing: border-box; }
        body { margin:0; min-height:100vh; background:var(--page); font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
               color:var(--navy); display:flex; align-items:center; justify-content:center; padding:24px; }
        .card { background:#fff; border-radius:24px; padding:28px 28px 24px; width:100%; max-width:420px; box-shadow:0 1px 3px rgba(14,31,61,.08); }
        .brand { display:flex; align-items:center; gap:10px; justify-content:center; margin-bottom:10px; }
        .brand .dot { width:34px; height:34px; border-radius:10px; background:var(--primary); color:#fff; display:flex; align-items:center; justify-content:center; font-weight:800; }
        .brand .name { font-size:20px; font-weight:800; }
        h1 { font-size:21px; font-weight:800; text-align:center; margin:12px 0 2px; }
        .sub { text-align:center; color:var(--muted); font-size:14px; margin:0 0 18px; }
        label { display:block; font-weight:700; font-size:13px; margin:12px 0 6px; }
        .ro { padding:10px 12px; border-radius:12px; background:var(--page); border:1px solid var(--line); font-weight:700; }
        input[type=password] { width:100%; height:44px; padding:0 12px; border:1px solid var(--line); border-radius:12px; font:inherit; font-size:15px; background:#fff; color:var(--navy); outline:none; }
        input[type=password]:focus { border-color:var(--primary); box-shadow:0 0 0 4px rgba(27,79,156,.14); }
        .btn { margin-top:18px; width:100%; height:46px; border:0; border-radius:999px; background:var(--primary); color:#fff; font:inherit; font-weight:800; font-size:15px; cursor:pointer; }
        .btn:hover { background:var(--primary-dark); }
        .msg { margin-top:14px; padding:10px 12px; border-radius:12px; font-size:13.5px; font-weight:700; }
        .msg.err { background:#FDECEA; color:#A3261C; }
        .msg.ok { background:#E3F3EA; color:#0F5A3A; }
        .foot { text-align:center; color:var(--muted); font-size:12px; margin-top:16px; }
        a { color:var(--primary); font-weight:700; text-decoration:none; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="card">
            <div class="brand"><span class="dot">60</span><span class="name">60Sec-AI</span></div>
            <asp:Panel ID="pnlForm" runat="server">
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <p class="sub"><asp:Literal ID="litSous" runat="server" /></p>

                <label><asp:Literal ID="litLblEmail" runat="server" /></label>
                <div class="ro"><asp:Literal ID="litEmail" runat="server" /></div>

                <label><asp:Literal ID="litLblPwd" runat="server" /></label>
                <asp:TextBox ID="txtPwd" runat="server" TextMode="Password" />

                <label><asp:Literal ID="litLblPwd2" runat="server" /></label>
                <asp:TextBox ID="txtPwd2" runat="server" TextMode="Password" />

                <asp:Button ID="btnActivate" runat="server" CssClass="btn" Text="Activer mon compte" />
            </asp:Panel>
            <asp:Literal ID="litMsg" runat="server" />
            <div class="foot"><asp:Literal ID="litFoot" runat="server" /></div>
        </div>
    </form>
</body>
</html>
