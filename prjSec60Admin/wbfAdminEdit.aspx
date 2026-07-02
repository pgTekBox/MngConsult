<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfAdminEdit.aspx.vb" Inherits="prjSec60Admin.wbfAdminEdit" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Administrateur — Edit</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --primary: #2563eb; --danger: #dc2626; --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08); --radius: 16px;
        }
        html, body { height: 100%; margin: 0; }
        body {
            font-family: var(--font); color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%), var(--bg);
        }
        .wrap { margin: 16px auto; padding: 0 16px 20px; }
        .top { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; margin-bottom: 14px; }
        .title { font-size: 20px; font-weight: 900; }
        .sub { font-size: 13px; color: var(--muted); margin-top: 3px; }
        .bar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .card { background: var(--card); border: 1px solid rgba(226,232,240,.9); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; margin-bottom: 14px; }
        .cardHead { padding: 14px 16px; border-bottom: 1px solid var(--line); display: flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap; }
        .cardHead .h { font-weight: 900; }
        .cardBody { padding: 16px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr; gap: 12px; }
        @media (max-width: 600px) { .grid { grid-template-columns: 1fr; } }
        .field label { display: block; font-size: 12px; color: #334155; margin-bottom: 6px; font-weight: 700; }
        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox, .field .rtbLike input.riTextBox {
            width: 100% !important; box-sizing: border-box; padding: 10px 12px !important;
            border: 1px solid var(--line) !important; border-radius: 12px !important;
            outline: none; background: #fff !important; font-family: var(--font); color: var(--text);
        }
        .field .rtbLike .riTextBox:focus, .field .rtbLike .riFocused .riTextBox {
            border-color: rgba(37,99,235,.5) !important; box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }
        .check { display: inline-flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; color: var(--text); margin-top: 24px; }
        .btn { cursor: pointer; border: 1px solid var(--line); border-radius: 12px !important; padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10)); color: var(--text); font-weight: 800; font-family: var(--font); }
        .btn.primary { border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color: #1d4ed8; }
        .btn.danger { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger); }
        .msg { margin: 0; padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid var(--line); background: #fff; }
        .msg.bad { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger); }
        .msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: var(--ok); }
        .hint { font-size: 11px; color: var(--muted); margin-top: 4px; }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <telerik:RadScriptManager ID="RadScriptManager1" runat="server"
            EnablePartialRendering="true" AsyncPostBackTimeout="300" />

        <div class="wrap">

            <div class="top">
                <div>
                    <div class="title"><asp:Literal ID="litTitle" runat="server" Text="Nouvel administrateur" /></div>
                    <div class="sub">Gérez l'accès des administrateurs de la console.</div>
                </div>
                <div class="bar">
                    <asp:Button ID="btnDelete" runat="server" Text="Supprimer" CssClass="btn danger" Visible="false"
                        OnClientClick="return confirm('Supprimer cet administrateur ?');" />
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn" onclick="closeWin();">← Annuler</asp:HyperLink>
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <asp:HiddenField ID="hfId" runat="server" Value="0" />

            <div class="card">
                <div class="cardHead"><div class="h">Informations</div></div>
                <div class="cardBody">
                    <div class="grid1">
                        <div class="field">
                            <label>Courriel *</label>
                            <telerik:RadTextBox ID="txtEmail" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                    <div class="grid" style="margin-top:12px;">
                        <div class="field">
                            <label>Prénom</label>
                            <telerik:RadTextBox ID="txtFirstName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Nom</label>
                            <telerik:RadTextBox ID="txtLastName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="cardHead"><div class="h">Mot de passe</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label><asp:Literal ID="litPasswordLabel" runat="server" Text="Mot de passe *" /></label>
                            <telerik:RadTextBox ID="txtPassword" runat="server" TextMode="Password" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint"><asp:Literal ID="litPasswordHint" runat="server" Text="Minimum 8 caractères." /></div>
                        </div>
                        <div class="field">
                            <label>Confirmation du mot de passe</label>
                            <telerik:RadTextBox ID="txtPasswordConfirm" runat="server" TextMode="Password" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="cardHead"><div class="h">Statut</div></div>
                <div class="cardBody">
                    <label class="check">
                        <asp:CheckBox ID="cbActive" runat="server" Checked="true" />
                        <span>Compte actif</span>
                    </label>
                    <div class="hint">Un compte inactif ne peut pas se connecter à la console.</div>
                </div>
            </div>

        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }
            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
                return false;
            }
        </script>

    </form>
</body>
</html>
