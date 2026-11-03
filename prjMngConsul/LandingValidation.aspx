<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="LandingValidation.aspx.vb" Inherits="MngConsul.LandingValidation" %>
<!doctype html>
<html>
<head runat="server">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>60secondes</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap">
<style>
  :root{--encre:#0E1F3D;--encre2:#44536E;--fond:#F2F5F9;--filet:#E3E9F1;--marine:#1B4F9C;--marine-fonce:#143A73;--or:#D9A03C;--nuit:#0E1F3D}
  *{box-sizing:border-box}
  html,body{margin:0}
  body{background:var(--fond);color:var(--encre);font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;font-size:16px;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
  .carte{background:#fff;border:1px solid var(--filet);border-radius:22px;padding:34px 32px;max-width:520px;width:100%;box-shadow:0 20px 60px rgba(14,31,61,.10);text-align:center}
  .logo{display:inline-flex;align-items:center;gap:4px;font-weight:800;font-size:24px;letter-spacing:-.01em;margin-bottom:18px}
  .ico{width:56px;height:56px;border-radius:50%;background:var(--nuit);color:var(--or);display:grid;place-items:center;margin:0 auto 16px}
  .ico svg{width:28px;height:28px}
  h1{font-size:24px;font-weight:800;margin:0 0 10px}
  p{color:var(--encre2);line-height:1.5;margin:0 0 20px}
  .btn{display:inline-block;background:var(--marine);color:#fff;text-decoration:none;font-weight:800;border-radius:999px;padding:12px 24px}
  .btn:hover{background:var(--marine-fonce)}
  footer{margin-top:22px;color:#6A7891;font-size:13px}
</style>
</head>
<body>
  <form id="f" runat="server">
    <div class="carte">
      <span class="logo">
        <svg aria-hidden="true" width="40" height="40" viewBox="0 0 256 256"><circle cx="128" cy="128" r="104" fill="#5E35C9"/><circle cx="96" cy="120" r="16" fill="none" stroke="#FFFFFF" stroke-width="12"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round"/><ellipse cx="162" cy="106" rx="15" ry="25" fill="none" stroke="#FFFFFF" stroke-width="12" transform="rotate(12 160 110)"/><path d="M148 68 q16 -9 30 0" fill="none" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round"/><path d="M108 170 q20 6 40 -6" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/></svg>
        <span style="color:#000">secondes</span>
      </span>
      <div class="ico" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg></div>
      <h1><asp:Literal ID="litTitre" runat="server" /></h1>
      <p><asp:Literal ID="litMessage" runat="server" /></p>
      <a class="btn" href="LandingPage.aspx">60secondes.ca</a>
      <asp:Literal ID="litLang" runat="server" Visible="false" />
    </div>
  </form>
</body>
</html>
