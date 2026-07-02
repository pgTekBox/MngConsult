<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true" ValidateRequest="false"
    CodeBehind="wbfPlanEdit.aspx.vb" Inherits="prjSec60Admin.wbfPlanEdit" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Forfait — Edit</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb; --card: #fff;
            --text: #0f172a; --muted: #64748b;
            --line: #e2e8f0; --primary: #2563eb;
            --danger: #dc2626; --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08);
            --radius: 16px;
        }
        html, body { height: 100%; margin: 0; }
        body {
            font-family: var(--font); color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%),
                        var(--bg);
        }
        .wrap { margin: 16px auto; padding: 0 16px 20px; }
        .top {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px; flex-wrap: wrap; margin-bottom: 14px;
        }
        .title { font-size: 20px; font-weight: 900; }
        .sub { font-size: 13px; color: var(--muted); margin-top: 3px; }
        .bar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }

        .card {
            background: var(--card);
            border: 1px solid rgba(226,232,240,.9);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden; margin-bottom: 14px;
        }
        .cardHead {
            padding: 14px 16px; border-bottom: 1px solid var(--line);
            display: flex; justify-content: space-between;
            align-items: center; gap: 10px; flex-wrap: wrap;
        }
        .cardHead .h { font-weight: 900; }
        .cardBody { padding: 16px; }

        .grid  { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr;     gap: 12px; }
        .mt12  { margin-top: 12px; }

        @media (max-width: 600px) { .grid, .grid3 { grid-template-columns: 1fr; } }

        .field label {
            display: block; font-size: 12px; color: #334155;
            margin-bottom: 6px; font-weight: 700;
        }
        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox,
        .field .rtbLike input.riTextBox {
            width: 100% !important; box-sizing: border-box;
            padding: 10px 12px !important;
            border: 1px solid var(--line) !important;
            border-radius: 12px !important;
            outline: none; background: #fff !important;
            font-family: var(--font); color: var(--text);
        }
        .field .rtbLike .riTextBox:focus,
        .field .rtbLike .riFocused .riTextBox {
            border-color: rgba(37,99,235,.5) !important;
            box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }

        /* champs natifs (select + textarea) stylés comme les RadTextBox */
        .inp, .ta, .sel {
            width: 100%; box-sizing: border-box;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            outline: none; background: #fff;
            font-family: var(--font); color: var(--text); font-size: 14px;
        }
        .ta { min-height: 70px; resize: vertical; }
        .inp:focus, .ta:focus, .sel:focus {
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        .check {
            display: inline-flex; align-items: center; gap: 8px;
            font-size: 14px; font-weight: 600; color: var(--text);
            margin-top: 24px;
        }

        .btn {
            cursor: pointer; border: 1px solid var(--line);
            border-radius: 12px !important; padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: var(--text); font-weight: 800; font-family: var(--font);
        }
        .btn.primary {
            border-color: rgba(37,99,235,.4);
            background: rgba(37,99,235,.08); color: #1d4ed8;
        }
        .btn.danger {
            border-color: rgba(220,38,38,.35);
            background: rgba(220,38,38,.08); color: var(--danger);
        }

        .msg {
            margin: 0; padding: 10px 12px;
            border-radius: 12px; font-weight: 700;
            font-size: 13px; border: 1px solid var(--line);
            background: #fff;
        }
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
                    <div class="title">
                        <asp:Literal ID="litTitle" runat="server" Text="Nouveau forfait" />
                    </div>
                    <div class="sub">Configurez le forfait, sa tarification et ses limites.</div>
                </div>
                <div class="bar">
                    <asp:Button ID="btnDelete" runat="server" Text="Supprimer"
                        CssClass="btn danger" Visible="false"
                        OnClientClick="return confirm('Supprimer ce forfait ?');" />
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn"
                        onclick="closeWin();">← Annuler</asp:HyperLink>
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <asp:HiddenField ID="hfId" runat="server" Value="0" />

            <!-- Identification -->
            <div class="card">
                <div class="cardHead"><div class="h">Identification</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label>Code *</label>
                            <telerik:RadTextBox ID="txtCode" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">Identifiant court (ex. : solo, comsolo). Peut être partagé entre cycles.</div>
                        </div>
                        <div class="field">
                            <label>Nom *</label>
                            <telerik:RadTextBox ID="txtName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>

                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Accroche (tagline)</label>
                            <telerik:RadTextBox ID="txtTagline" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>

                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Description courte</label>
                            <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="ta" />
                        </div>
                    </div>

                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Contenu mis en forme (affiché sur la page d'accueil)</label>
                            <telerik:RadEditor ID="reDescriptionLong" runat="server"
                                RenderMode="Lightweight" Skin="Bootstrap"
                                Width="100%" Height="320px"
                                EditModes="Design,Html,Preview"
                                ContentAreaMode="Div"
                                ToolbarMode="ShowOnFocus">
                                <Content></Content>
                            </telerik:RadEditor>
                            <div class="hint">Mise en forme riche (gras, listes, liens…) du forfait, affichée sur la LandingPage.</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tarification -->
            <div class="card">
                <div class="cardHead"><div class="h">Tarification</div></div>
                <div class="cardBody">
                    <div class="grid3">
                        <div class="field">
                            <label>Montant *</label>
                            <telerik:RadTextBox ID="txtAmount" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Devise</label>
                            <asp:DropDownList ID="ddlCurrency" runat="server" CssClass="sel">
                                <asp:ListItem Text="CAD" Value="CAD" />
                                <asp:ListItem Text="USD" Value="USD" />
                                <asp:ListItem Text="EUR" Value="EUR" />
                            </asp:DropDownList>
                        </div>
                        <div class="field">
                            <label>Cycle de facturation</label>
                            <asp:DropDownList ID="ddlBillingCycle" runat="server" CssClass="sel">
                                <asp:ListItem Text="Mensuel" Value="monthly" />
                                <asp:ListItem Text="Annuel" Value="annual" />
                            </asp:DropDownList>
                        </div>
                    </div>

                    <div class="grid mt12">
                        <div class="field">
                            <label>Jours d'essai</label>
                            <telerik:RadTextBox ID="txtTrialDays" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Ordre d'affichage</label>
                            <telerik:RadTextBox ID="txtDisplayOrder" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Stripe / Processeur -->
            <div class="card">
                <div class="cardHead"><div class="h">Processeur de paiement</div></div>
                <div class="cardBody">
                    <div class="grid3">
                        <div class="field">
                            <label>Processeur</label>
                            <telerik:RadTextBox ID="txtProcessorName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">ex. : stripe</div>
                        </div>
                        <div class="field">
                            <label>Stripe Product Id</label>
                            <telerik:RadTextBox ID="txtStripeProductId" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Stripe Price Id</label>
                            <telerik:RadTextBox ID="txtStripePriceId" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Limites -->
            <div class="card">
                <div class="cardHead"><div class="h">Limites</div></div>
                <div class="cardBody">
                    <div class="grid3">
                        <div class="field">
                            <label>Utilisateurs max</label>
                            <telerik:RadTextBox ID="txtMaxUsers" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">Laisser vide = illimité.</div>
                        </div>
                        <div class="field">
                            <label>Clients max</label>
                            <telerik:RadTextBox ID="txtMaxClients" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Documents max</label>
                            <telerik:RadTextBox ID="txtMaxDocuments" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                    <div class="grid mt12">
                        <div class="field">
                            <label>Stockage max (Mo)</label>
                            <telerik:RadTextBox ID="txtMaxStorageMB" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                        <div class="field">
                            <label>Tranche d'employés</label>
                            <telerik:RadTextBox ID="txtEmployeeRange" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">ex. : 1-19</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Affichage & options -->
            <div class="card">
                <div class="cardHead"><div class="h">Affichage &amp; options</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label>Texte du badge</label>
                            <telerik:RadTextBox ID="txtBadgeText" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                            <div class="hint">ex. : Le plus populaire</div>
                        </div>
                        <div class="field">
                            <label>Permissions / options</label>
                            <div style="display:flex; gap:24px; flex-wrap:wrap;">
                                <label class="check">
                                    <asp:CheckBox ID="cbRecommended" runat="server" />
                                    <span>Recommandé</span>
                                </label>
                                <label class="check">
                                    <asp:CheckBox ID="cbActive" runat="server" Checked="true" />
                                    <span>Actif</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Caractéristiques (Features)</label>
                            <asp:TextBox ID="txtFeatures" runat="server" TextMode="MultiLine" CssClass="ta" />
                            <div class="hint">Texte ou JSON listant les fonctionnalités incluses.</div>
                        </div>
                    </div>
                </div>
            </div>

        </div>

        <script type="text/javascript">
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
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
