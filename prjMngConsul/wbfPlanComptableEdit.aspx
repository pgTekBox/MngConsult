<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfPlanComptableEdit.aspx.vb" Inherits="MngConsul.wbfPlanComptableEdit" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Compte — Édition</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb;
            --card: #fff;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --primary: #2563eb;
            --primary-weak: #eff6ff;
            --danger: #dc2626;
            --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08);
            --radius: 16px;
        }

        html, body { height: 100%; margin: 0; }

        body {
            font-family: var(--font);
            color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%),
                        var(--bg);
        }

        .wrap {
            max-width: 800px;
            margin: 20px auto;
            padding: 0 16px 28px;
        }

        .top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }

        .title { font-size: 22px; font-weight: 900; letter-spacing: -.02em; }
        .sub   { font-size: 13px; color: var(--muted); margin-top: 3px; }
        .bar   { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }

        .card {
            background: var(--card);
            border: 1px solid rgba(226,232,240,.9);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 14px;
        }

        .cardHead {
            padding: 14px 16px;
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .cardHead .h { font-weight: 900; }
        .cardBody { padding: 16px; }

        /* Grilles */
        .grid  { display: grid; grid-template-columns: 1fr 1fr;         gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr;             gap: 12px; }
        .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr;     gap: 12px; }
        .grid4 { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; }

        /* Champs */
        .field label {
            display: block;
            font-size: 12px;
            color: #334155;
            margin-bottom: 6px;
            font-weight: 700;
        }

        .field input,
        .field textarea {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            outline: none;
            background: #fff;
            box-sizing: border-box;
        }

        .field input:focus,
        .field textarea:focus {
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        /* RadTextBox */
        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox,
        .field .rtbLike input.riTextBox {
            width: 100% !important;
            box-sizing: border-box;
            padding: 10px 12px !important;
            border: 1px solid var(--line) !important;
            border-radius: 12px !important;
            outline: none;
            background: #fff !important;
            font-family: var(--font);
            color: var(--text);
        }
        .field .rtbLike .riTextBox:focus,
        .field .rtbLike input.riTextBox:focus {
            border-color: rgba(37,99,235,.5) !important;
            box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }

        /* RadDropDownList */
        .field .RadDropDownList,
        .field .RadDropDownList_Metro { width: 100%; display: block; }

        .field .RadDropDownList_Metro .rddlInner {
            width: 100%;
            height: 33px;
            padding: 10px 40px 10px 12px !important;
            border-radius: 12px !important;
            background: #fff !important;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            box-shadow: none !important;
        }
        .field .RadDropDownList_Metro .rddlFakeInput {
            flex: 1; min-width: 0; overflow: hidden;
            text-overflow: ellipsis; white-space: nowrap;
            color: var(--text); line-height: 20px;
        }
        .field .RadDropDownList_Metro .rddlSelect {
            width: 36px; margin-left: auto;
            display: flex; align-items: center; justify-content: center;
            background: transparent !important; border: 0 !important;
        }
        .field .RadDropDownList_Metro .rddlInner.rddlFocused,
        .field .RadDropDownList_Metro .rddlInner.rddlExpanded {
            border-color: #2563eb !important;
            box-shadow: 0 0 0 3px rgba(37,99,235,.15) !important;
        }

        /* Boutons */
        .btn {
            cursor: pointer;
            border: 1px solid var(--line);
            border-radius: 12px !important;
            padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: var(--text);
            font-weight: 800;
            font-family: var(--font);
        }
        .btn.primary {
            border-color: rgba(37,99,235,.4);
            background: rgba(37,99,235,.08);
            color: #1d4ed8;
        }
        .btn.danger {
            border-color: rgba(220,38,38,.35);
            background: rgba(220,38,38,.08);
            color: var(--danger);
        }
        .btn:disabled { opacity: .6; cursor: not-allowed; }

        /* Messages */
        .msg {
            margin: 0; padding: 10px 12px;
            border-radius: 10px; font-size: 13px; font-weight: 600;
        }
        .msg-ok { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
        .msg-err { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }

        /* Info row */
        .info-row {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            font-size: 12px;
            color: var(--muted);
            padding: 8px 0 0;
        }
        .info-row span { font-weight: 700; color: var(--text); }

        /* Checkbox custom */
        .chk-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            padding-top: 22px;
        }
        .chk-wrap input[type="checkbox"] {
            width: 18px;
            height: 18px;
            accent-color: var(--primary);
        }
        .chk-wrap label {
            font-size: 13px;
            font-weight: 700;
            color: var(--text);
            margin: 0;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
        <telerik:RadAjaxLoadingPanel ID="lp1" runat="server" Skin="Metro" />

        <telerik:RadAjaxPanel ID="rap1" runat="server" LoadingPanelID="lp1">

            <div class="wrap">

                <%-- En-tête --%>
                <div class="top">
                    <div>
                        <div class="title">
                            <asp:Label ID="lblTitle" runat="server" Text="Nouveau compte" />
                        </div>
                        <div class="sub">
                            <asp:Label ID="lblSub" runat="server" Text="Remplissez les informations du compte" />
                        </div>
                    </div>
                    <div class="bar">
                        <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                        <asp:Button ID="btnCancel" runat="server" Text="Fermer" CssClass="btn"
                            CausesValidation="false"
                            OnClientClick="closeWin(); return false;" />
                    </div>
                </div>

                <%-- Message --%>
                <asp:Label ID="lblMsg" runat="server" Visible="false" />

                <%-- Carte : Informations du compte --%>
                <div class="card">
                    <div class="cardHead">
                        <div class="h">Informations du compte</div>
                    </div>
                    <div class="cardBody">
                        <div class="grid">

                            <div class="field">
                                <label>Numéro de compte *</label>
                                <telerik:RadTextBox ID="txtNumero" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="10" />
                            </div>

                            <div class="field">
                                <label>Nom du compte *</label>
                                <telerik:RadTextBox ID="txtNom" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="150" />
                            </div>

                            <div class="field">
                                <label>Classe (Niveau 1) *</label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlClasseParent" runat="server"
                                    DefaultMessage="Sélectionner…" DropDownHeight="200px"
                                    AutoPostBack="true" OnSelectedIndexChanged="rddlClasseParent_SelectedIndexChanged">
                                </telerik:RadDropDownList>
                            </div>

                            <div class="field">
                                <label>Sous-classe (Niveau 2) *</label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlClasse" runat="server"
                                    DefaultMessage="Sélectionner la classe d'abord…" DropDownHeight="200px">
                                </telerik:RadDropDownList>
                            </div>

                            <div class="field">
                                <label>Type au bilan</label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlTypeBilan" runat="server"
                                    DefaultMessage="Sélectionner…" DropDownHeight="160px">
                                    <Items>
                                        <telerik:DropDownListItem Text="Actif" Value="A" />
                                        <telerik:DropDownListItem Text="Passif" Value="P" />
                                        <telerik:DropDownListItem Text="Capitaux propres" Value="CP" />
                                        <telerik:DropDownListItem Text="Revenus" Value="R" />
                                        <telerik:DropDownListItem Text="Charges" Value="C" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>

                            <div class="field">
                                <label>Sens</label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlSens" runat="server"
                                    DefaultMessage="Sélectionner…" DropDownHeight="110px">
                                    <Items>
                                        <telerik:DropDownListItem Text="Débiteur" Value="D" />
                                        <telerik:DropDownListItem Text="Créditeur" Value="C" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>

                        </div>

                        <div style="margin-top: 12px;">
                            <div class="grid">
                                <div class="field">
                                    <label>Description</label>
                                    <telerik:RadTextBox ID="txtDescription" runat="server" RenderMode="Lightweight"
                                        CssClass="rtbLike" TextMode="MultiLine" Rows="3" MaxLength="250" />
                                </div>

                                <div>
                                    <div class="chk-wrap">
                                        <asp:CheckBox ID="chkActif"  runat="server" Checked="true" ClientIDMode="Static" />
                                        <label for="chkActif">Compte actif</label>
                                    </div>
                                    <div class="chk-wrap" style="padding-top: 10px;">
                                        <asp:CheckBox ID="chkSysteme" runat="server" Enabled="false" ClientIDMode="Static" />
                                        <label for="chkSysteme">Compte système (non supprimable)</label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <%-- Info (mode édition) --%>
                        <asp:Panel ID="pnlInfo" runat="server" Visible="false">
                            <div class="info-row">
                                <div>ID : <span><asp:Label ID="tlblId" runat="server" /></span></div>
                                <div>Créé le : <span><asp:Label ID="tlblCreated" runat="server" /></span></div>
                            </div>
                        </asp:Panel>

                    </div>
                </div>

            </div>

        </telerik:RadAjaxPanel>

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
            }
        </script>

    </form>
</body>
</html>
