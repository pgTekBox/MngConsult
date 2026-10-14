<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true" ValidateRequest="false"
    CodeBehind="wbfCabinetEdit.aspx.vb" Inherits="prjSec60Admin.wbfCabinetEdit" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Cabinet certifié — Edit</title>
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

        /* champs natifs (select, date, textarea) stylés comme les RadTextBox */
        .inp, .ta, .sel {
            width: 100%; box-sizing: border-box;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            outline: none; background: #fff;
            font-family: var(--font); color: var(--text); font-size: 14px;
        }
        .ta { min-height: 90px; resize: vertical; }
        .inp:focus, .ta:focus, .sel:focus {
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        .checks { display: flex; gap: 18px; flex-wrap: wrap; padding: 6px 0; }
        .check {
            display: inline-flex; align-items: center; gap: 8px;
            font-size: 14px; font-weight: 600; color: var(--text);
        }
        .check.tall { margin-top: 24px; }

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
            margin: 0 0 14px; padding: 10px 12px;
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
                        <asp:Literal ID="litTitle" runat="server" Text="Nouveau cabinet" />
                    </div>
                    <div class="sub">Ce que les utilisateurs de 60Sec-AI voient dans « Cabinets certifiés ».</div>
                </div>
                <div class="bar">
                    <asp:Button ID="btnDelete" runat="server" Text="Supprimer"
                        CssClass="btn danger" Visible="false"
                        OnClientClick="if (!confirm('Supprimer ce cabinet de l\'annuaire ?')) { return false; }" />
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
                <div class="cardHead"><div class="h">Le cabinet</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label>Nom du cabinet *</label>
                            <telerik:RadTextBox ID="txtNom" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="150" />
                        </div>
                        <div class="field">
                            <label>Responsable</label>
                            <telerik:RadTextBox ID="txtResponsable" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="150" />
                            <div class="hint">ex. : Geneviève Lachance, CPA</div>
                        </div>
                    </div>

                    <div class="grid3 mt12">
                        <div class="field">
                            <label>Ville</label>
                            <telerik:RadTextBox ID="txtVille" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="100" />
                        </div>
                        <div class="field">
                            <label>Province</label>
                            <asp:DropDownList ID="ddlProvince" runat="server" CssClass="sel">
                                <asp:ListItem Text="Québec" Value="QC" />
                                <asp:ListItem Text="Ontario" Value="ON" />
                                <asp:ListItem Text="Nouveau-Brunswick" Value="NB" />
                                <asp:ListItem Text="Nouvelle-Écosse" Value="NS" />
                                <asp:ListItem Text="Île-du-Prince-Édouard" Value="PE" />
                                <asp:ListItem Text="Terre-Neuve-et-Labrador" Value="NL" />
                                <asp:ListItem Text="Manitoba" Value="MB" />
                                <asp:ListItem Text="Saskatchewan" Value="SK" />
                                <asp:ListItem Text="Alberta" Value="AB" />
                                <asp:ListItem Text="Colombie-Britannique" Value="BC" />
                            </asp:DropDownList>
                        </div>
                        <div class="field">
                            <label>Certifié depuis</label>
                            <asp:TextBox ID="txtCertifieDepuis" runat="server" TextMode="Date" CssClass="inp" />
                            <div class="hint">L'année s'affiche sur la carte (« Certifié · 2026 »).</div>
                        </div>
                    </div>

                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Description (500 caractères)</label>
                            <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="ta" MaxLength="500" />
                            <div class="hint">Une phrase sur la clientèle et la façon de travailler, telle qu'elle paraît sur la carte.</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Joindre -->
            <div class="card">
                <div class="cardHead"><div class="h">Pour le joindre</div></div>
                <div class="cardBody">
                    <div class="grid3">
                        <div class="field">
                            <label>Courriel</label>
                            <telerik:RadTextBox ID="txtCourriel" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="200" />
                            <div class="hint">Le bouton « Écrire » de la carte.</div>
                        </div>
                        <div class="field">
                            <label>Téléphone</label>
                            <telerik:RadTextBox ID="txtTelephone" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="40" />
                        </div>
                        <div class="field">
                            <label>Site web</label>
                            <telerik:RadTextBox ID="txtSiteWeb" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="250" />
                            <div class="hint">Avec https://</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Langues, spécialités, statut -->
            <div class="card">
                <div class="cardHead"><div class="h">Langues, spécialités et statut</div></div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label>Langues parlées</label>
                            <div class="checks">
                                <label class="check"><asp:CheckBox ID="cbLangFR" runat="server" Checked="true" /><span>Français</span></label>
                                <label class="check"><asp:CheckBox ID="cbLangEN" runat="server" /><span>English</span></label>
                                <label class="check"><asp:CheckBox ID="cbLangES" runat="server" /><span>Español</span></label>
                            </div>
                        </div>
                        <div class="field">
                            <label>Statut</label>
                            <div class="checks">
                                <label class="check"><asp:CheckBox ID="cbActive" runat="server" Checked="true" /><span>Actif (visible dans 60Sec-AI)</span></label>
                            </div>
                            <div class="hint">Un cabinet inactif reste ici mais n'est plus proposé aux utilisateurs.</div>
                        </div>
                    </div>
                    <div class="grid1 mt12">
                        <div class="field">
                            <label>Spécialités</label>
                            <div class="checks">
                                <label class="check"><asp:CheckBox ID="cbSpecTA" runat="server" /><span>Travailleurs autonomes</span></label>
                                <label class="check"><asp:CheckBox ID="cbSpecSOC" runat="server" /><span>Sociétés</span></label>
                                <label class="check"><asp:CheckBox ID="cbSpecPAIE" runat="server" /><span>Paie et employés</span></label>
                                <label class="check"><asp:CheckBox ID="cbSpecCONSTR" runat="server" /><span>Construction</span></label>
                                <label class="check"><asp:CheckBox ID="cbSpecSANTE" runat="server" /><span>Santé et services</span></label>
                            </div>
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
