<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfCompanyEdit.aspx.vb" Inherits="prjSec60Admin.wbfCompanyEdit" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Compagnie — Edit</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff; --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --primary: #2563eb; --danger: #dc2626; --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08); --radius: 16px;
        }
        html, body { height: 100%; margin: 0; }
        body { font-family: var(--font); color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%), var(--bg); }
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
        .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr; gap: 12px; }
        .mt12 { margin-top: 12px; }
        @media (max-width: 600px) { .grid, .grid3 { grid-template-columns: 1fr; } }
        .field label { display: block; font-size: 12px; color: #334155; margin-bottom: 6px; font-weight: 700; }
        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox, .field .rtbLike input.riTextBox {
            width: 100% !important; box-sizing: border-box; padding: 10px 12px !important;
            border: 1px solid var(--line) !important; border-radius: 12px !important;
            outline: none; background: #fff !important; font-family: var(--font); color: var(--text); }
        .field .rtbLike .riTextBox:focus, .field .rtbLike .riFocused .riTextBox {
            border-color: rgba(37,99,235,.5) !important; box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important; }
        .inp, .sel { width: 100%; box-sizing: border-box; padding: 10px 12px; border: 1px solid var(--line);
            border-radius: 12px; outline: none; background: #fff; font-family: var(--font); color: var(--text); font-size: 14px; }
        .inp:focus, .sel:focus { border-color: rgba(37,99,235,.5); box-shadow: 0 0 0 4px rgba(37,99,235,.12); }
        .check { display: inline-flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; color: var(--text); margin-top: 24px; }
        .btn { cursor: pointer; border: 1px solid var(--line); border-radius: 12px !important; padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10)); color: var(--text); font-weight: 800; font-family: var(--font); }
        .btn.primary { border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color: #1d4ed8; }
        .btn.danger { border-color: rgba(220,38,38,.4); background: rgba(220,38,38,.08); color: var(--danger); }
        .danger-card { border-color: rgba(220,38,38,.35) !important; }
        .danger-card .cardHead { background: rgba(220,38,38,.04); }
        .danger-card .h { color: var(--danger); }
        .msg { margin: 0; padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid var(--line); background: #fff; }
        .msg.bad { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger); }
        .msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: var(--ok); }
        .hint { font-size: 11px; color: var(--muted); margin-top: 4px; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" EnablePartialRendering="true" AsyncPostBackTimeout="300" />

        <div class="wrap">
            <div class="top">
                <div>
                    <div class="title"><asp:Literal ID="litTitle" runat="server" Text="Compagnie" /></div>
                    <div class="sub">Gérez les informations de la compagnie et son abonnement.</div>
                </div>
                <div class="bar">
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn" onclick="closeWin();">← Annuler</asp:HyperLink>
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <asp:HiddenField ID="hfGuid" runat="server" />
            <asp:HiddenField ID="hfSubId" runat="server" Value="0" />
            <asp:HiddenField ID="hfOrigName" runat="server" />

            <!-- Compagnie -->
            <div class="card">
                <div class="cardHead"><div class="h">Compagnie</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field"><label>Nom *</label>
                            <telerik:RadTextBox ID="txtName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                        <div class="field"><label>Raison sociale</label>
                            <telerik:RadTextBox ID="txtLegalName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                    </div>
                    <div class="grid3 mt12">
                        <div class="field"><label>Code</label>
                            <telerik:RadTextBox ID="txtCode" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                        <div class="field"><label>Structure</label>
                            <telerik:RadTextBox ID="txtStructure" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">ex. : solo, inc.</div></div>
                        <div class="field"><label>NEQ</label>
                            <telerik:RadTextBox ID="txtNEQ" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                    </div>
                    <div class="grid1 mt12">
                        <div class="field"><label>Numéro d'entreprise</label>
                            <telerik:RadTextBox ID="txtBusinessNumber" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                    </div>
                </div>
            </div>

            <!-- Abonnement -->
            <div class="card">
                <div class="cardHead"><div class="h">Abonnement</div></div>
                <div class="cardBody">
                    <div class="grid3">
                        <div class="field"><label>Forfait</label>
                            <asp:DropDownList ID="ddlPlan" runat="server" CssClass="sel" /></div>
                        <div class="field"><label>Statut</label>
                            <asp:DropDownList ID="ddlStatus" runat="server" CssClass="sel">
                                <asp:ListItem Text="Actif" Value="active" />
                                <asp:ListItem Text="Essai" Value="trial" />
                                <asp:ListItem Text="En pause" Value="paused" />
                                <asp:ListItem Text="Annulé" Value="cancelled" />
                                <asp:ListItem Text="Expiré" Value="expired" />
                            </asp:DropDownList></div>
                        <div class="field"><label>Montant</label>
                            <telerik:RadTextBox ID="txtAmount" runat="server" RenderMode="Lightweight" CssClass="rtbLike" /></div>
                    </div>
                    <div class="grid3 mt12">
                        <div class="field"><label>Devise</label>
                            <asp:DropDownList ID="ddlCurrency" runat="server" CssClass="sel">
                                <asp:ListItem Text="CAD" Value="CAD" />
                                <asp:ListItem Text="USD" Value="USD" />
                                <asp:ListItem Text="EUR" Value="EUR" />
                            </asp:DropDownList></div>
                        <div class="field"><label>Cycle</label>
                            <asp:DropDownList ID="ddlCycle" runat="server" CssClass="sel">
                                <asp:ListItem Text="Mensuel" Value="monthly" />
                                <asp:ListItem Text="Annuel" Value="annual" />
                            </asp:DropDownList></div>
                        <div class="field"><label>&nbsp;</label>
                            <label class="check">
                                <asp:CheckBox ID="cbTrial" runat="server" /><span>Période d'essai</span>
                            </label></div>
                    </div>
                    <div class="grid3 mt12">
                        <div class="field"><label>Date de début</label>
                            <asp:TextBox ID="txtStartDate" runat="server" CssClass="inp" placeholder="AAAA-MM-JJ" /></div>
                        <div class="field"><label>Prochaine facturation</label>
                            <asp:TextBox ID="txtNextBilling" runat="server" CssClass="inp" placeholder="AAAA-MM-JJ" /></div>
                        <div class="field"><label>Date de fin</label>
                            <asp:TextBox ID="txtEndDate" runat="server" CssClass="inp" placeholder="AAAA-MM-JJ" /></div>
                    </div>
                    <div class="grid3 mt12">
                        <div class="field"><label>Fin de la période d'essai</label>
                            <asp:TextBox ID="txtTrialEnd" runat="server" CssClass="inp" placeholder="AAAA-MM-JJ" /></div>
                    </div>
                    <div class="hint mt12">Laissez « Forfait » vide pour ne pas créer d'abonnement.</div>
                </div>
            </div>

            <!-- Zone de danger : suppression définitive -->
            <div class="card danger-card">
                <div class="cardHead"><div class="h">⚠ Zone de danger</div></div>
                <div class="cardBody">
                    <p class="hint" style="margin-top:0;">
                        La suppression efface <strong>DÉFINITIVEMENT</strong> la compagnie et toutes ses
                        données rattachées (clients, factures, écritures, produits, abonnement, etc.).
                        Cette action est <strong>irréversible</strong>.
                    </p>
                    <div class="field" style="margin-top:10px;">
                        <label>Pour confirmer, tapez le nom exact de la compagnie :
                            <strong><asp:Literal ID="litConfirmName" runat="server" /></strong></label>
                        <asp:TextBox ID="txtConfirmDelete" runat="server" CssClass="inp"
                            placeholder="Nom de la compagnie" autocomplete="off" />
                    </div>
                    <div style="margin-top:12px;">
                        <asp:Button ID="btnDelete" runat="server"
                            Text="Supprimer définitivement la compagnie"
                            CssClass="btn danger" CausesValidation="false"
                            OnClientClick="return confirmDelete();" />
                    </div>
                </div>
            </div>
        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var o = null;
                if (window.radWindow) o = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow) o = window.frameElement.radWindow;
                return o;
            }
            function closeWin() { var w = GetRadWindow(); if (w) w.close(); return false; }
            function confirmDelete() {
                return confirm('ATTENTION : cette action supprime DÉFINITIVEMENT la compagnie et TOUTES ses données. Cette opération est irréversible.\n\nÊtes-vous certain de vouloir continuer ?');
            }
        </script>
    </form>
</body>
</html>
