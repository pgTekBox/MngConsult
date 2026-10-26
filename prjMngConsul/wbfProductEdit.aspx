<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfProductEdit.aspx.vb" Inherits="MngConsul.wbfProductEdit" %>

<!DOCTYPE html>
<html lang="<%= CurrentLang %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Produit — Édition</title>
    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb;
            --card: #fff;
            --text: #0E1F3D;
            --muted: #44536E;
            --line: #D5DDE8;
            --primary: #1B4F9C;
            --primary-weak: #E3EBF7;
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

        .wrap { max-width: 860px; margin: 20px auto; padding: 0 16px 28px; }

        .top {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px; flex-wrap: wrap; margin-bottom: 14px;
        }

        .title { font-size: 22px; font-weight: 900; letter-spacing: -.02em; }
        .sub   { font-size: 13px; color: var(--muted); margin-top: 3px; }
        .bar   { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }

        .card {
            background: var(--card); border: 1px solid rgba(226,232,240,.9);
            border-radius: var(--radius); box-shadow: var(--shadow);
            overflow: hidden; margin-bottom: 14px;
        }

        .cardHead {
            padding: 14px 16px; border-bottom: 1px solid var(--line);
            display: flex; justify-content: space-between; align-items: center;
            gap: 10px; flex-wrap: wrap;
        }
        .cardHead .h { font-weight: 900; }
        .cardBody { padding: 16px; }

        .grid  { display: grid; grid-template-columns: 1fr 1fr;         gap: 12px; }
        .grid1 { display: grid; grid-template-columns: 1fr;             gap: 12px; }
        .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr;     gap: 12px; }
        .grid4 { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; }

        .field label {
            display: block; font-size: 12px; color: #334155;
            margin-bottom: 6px; font-weight: 700;
        }

        .field input, .field textarea {
            width: 100%; padding: 10px 12px; border: 1px solid var(--line);
            border-radius: 12px; outline: none; background: #fff; box-sizing: border-box;
        }

        .field input:focus, .field textarea:focus {
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        .field .rtbLike { width: 100%; }
        .field .rtbLike .riTextBox,
        .field .rtbLike input.riTextBox {
            width: 100% !important; box-sizing: border-box;
            padding: 10px 12px !important; border: 1px solid var(--line) !important;
            border-radius: 12px !important; outline: none; background: #fff !important;
            font-family: var(--font); color: var(--text);
        }
        .field .rtbLike .riTextBox:focus,
        .field .rtbLike input.riTextBox:focus {
            border-color: rgba(37,99,235,.5) !important;
            box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }

        .field .RadDropDownList,
        .field .RadDropDownList_Metro { width: 100%; display: block; }

        .field .RadDropDownList_Metro .rddlInner {
            width: 100%; height: 33px;
            padding: 10px 40px 10px 12px !important;
            border-radius: 12px !important; background: #fff !important;
            box-sizing: border-box; display: flex; align-items: center;
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
            border-color: #1B4F9C !important;
            box-shadow: 0 0 0 3px rgba(37,99,235,.15) !important;
        }

        /* RadNumericTextBox */
        .field .RadInput .riTextBox,
        .field .RadInput input.riTextBox {
            width: 100% !important; box-sizing: border-box;
            padding: 10px 12px !important; border: 1px solid var(--line) !important;
            border-radius: 12px !important; outline: none; background: #fff !important;
            font-family: var(--font); color: var(--text); text-align: right;
        }
        .field .RadInput .riTextBox:focus {
            border-color: rgba(37,99,235,.5) !important;
            box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
        }

        .btn {
            cursor: pointer; border: 1px solid var(--line);
            border-radius: 12px !important; padding: 10px 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: var(--text); font-weight: 800; font-family: var(--font);
        }
        .btn.primary { border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color: #143A73; }
        .btn.danger { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger); }
        .btn:disabled { opacity: .6; cursor: not-allowed; }

        .msg { margin: 0 0 12px; padding: 10px 12px; border-radius: 10px; font-size: 13px; font-weight: 600; }
        .msg-ok  { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
        .msg-err { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }

        .info-row {
            display: flex; gap: 20px; flex-wrap: wrap;
            font-size: 12px; color: var(--muted); padding: 8px 0 0;
        }
        .info-row span { font-weight: 700; color: var(--text); }

        .chk-wrap {
            display: flex; align-items: center; gap: 8px; padding-top: 22px;
        }
        .chk-wrap input[type="checkbox"] { width: 18px; height: 18px; accent-color: var(--primary); }
        .chk-wrap label { font-size: 13px; font-weight: 700; color: var(--text); margin: 0; }

        /* Lieux du service : des puces à cocher */
        .pe-lieux { display: flex; flex-wrap: wrap; gap: 8px; }
        .pe-lieux input[type="checkbox"] { position: absolute; opacity: 0; width: 1px; height: 1px; }
        .pe-lieux label {
            display: inline-block !important; margin: 0 !important; padding: 8px 14px; cursor: pointer;
            border: 1px solid var(--line); border-radius: 999px; background: #fff;
            font-size: 14px !important; font-weight: 800 !important; color: var(--text);
        }
        .pe-lieux input[type="checkbox"]:checked + label { background: var(--primary-weak); border-color: var(--primary); }
        .pe-lieux input[type="checkbox"]:focus-visible + label { box-shadow: 0 0 0 3px rgba(27,79,156,.25); }
        .pe-off { opacity: .45; pointer-events: none; }

        .section-hint {
            font-size: 12px; color: var(--muted); padding: 0 0 10px;
            border-bottom: 1px dashed var(--line); margin-bottom: 12px;
        }
    </style>
    <%-- Signature « Portail du client » (voir css/edition-60s.css) --%>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap" />
    <link rel="stylesheet" href="css/edition-60s.css?v=2026102104" />
</head>
<body class="f60">
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
        <telerik:RadAjaxLoadingPanel ID="lp1" runat="server" Skin="Metro" />

        <telerik:RadAjaxPanel ID="rap1" runat="server" LoadingPanelID="lp1">

            <div class="wrap">

                <%-- En-tête --%>
                <div class="top">
                    <div>
                        <div class="f60-rub"><asp:Literal ID="litRubrique" runat="server" /></div>
                        <div class="title"><asp:Label ID="lblTitle" runat="server" Text="Nouveau produit" /></div>
                        <div class="sub"><asp:Label ID="lblSub" runat="server" Text="Remplissez les informations du produit" /></div>
                    </div>
                    <div class="bar">
                        <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                        <asp:Button ID="btnCancel" runat="server" Text="Fermer" CssClass="btn"
                            CausesValidation="false" OnClientClick="closeWin(); return false;" />
                    </div>
                </div>

                <asp:Label ID="lblMsg" runat="server" Visible="false" />

                <%-- ═══════════════════════════════════════════
                     CARTE 1 : Informations générales
                ═══════════════════════════════════════════ --%>
                <div class="card">
                    <div class="cardHead"><div class="h"><asp:Literal ID="litInfoGeneral" runat="server" /></div></div>
                    <div class="cardBody">

                        <div class="grid">
                            <div class="field">
                                <label><asp:Literal ID="litNameLabel" runat="server" /></label>
                                <telerik:RadTextBox ID="txtName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" MaxLength="500" />
                            </div>
                            <div class="field">
                                <label><asp:Literal ID="litCategory" runat="server" /></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlCategory" runat="server"
                                    DefaultMessage="Aucune catégorie" DropDownHeight="200px" />
                            </div>
                        </div>

                        <div style="margin-top:12px;">
                            <div class="field">
                                <label><asp:Literal ID="litDescription" runat="server" /></label>
                                <telerik:RadTextBox ID="txtDescription" runat="server" RenderMode="Lightweight"
                                    CssClass="rtbLike" TextMode="MultiLine" Rows="3" MaxLength="2000" />
                            </div>
                        </div>

                    </div>
                </div>

                <%-- ═══════════════════════════════════════════
                     CARTE 2 : Prix et quantités
                ═══════════════════════════════════════════ --%>
                <div class="card">
                    <div class="cardHead"><div class="h"><asp:Literal ID="litPriceQty" runat="server" /></div></div>
                    <div class="cardBody">
                        <div class="grid4">
                            <div class="field">
                                <label><asp:Literal ID="litUnitPrice" runat="server" /></label>
                                <telerik:RadNumericTextBox ID="txtPrix" runat="server" RenderMode="Lightweight"
                                    Type="Currency" NumberFormat-DecimalDigits="2" MinValue="0"
                                    Width="100%" />
                            </div>
                            <div class="field">
                                <label><asp:Literal ID="litDefaultQty" runat="server" /></label>
                                <telerik:RadNumericTextBox ID="txtDefaultQty" runat="server" RenderMode="Lightweight"
                                    Type="Number" NumberFormat-DecimalDigits="2" MinValue="0" Value="1"
                                    Width="100%" />
                            </div>
                            <div class="field">
                                <label><asp:Literal ID="litTaxStatus" runat="server" /></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlTaxeStatus" runat="server"
                                    DefaultMessage="Sélectionner…" DropDownHeight="110px">
                                    <Items>
                                        <telerik:DropDownListItem Text="Taxable" Value="1" />
                                        <telerik:DropDownListItem Text="Exempt" Value="2" />
                                        <telerik:DropDownListItem Text="Détaxé" Value="3" />
                                    </Items>
                                </telerik:RadDropDownList>
                            </div>
                            <div>
                                <div class="chk-wrap">
                                    <asp:CheckBox  ID="chkAddToNewInvoice" runat="server" ClientIDMode="Static" />
                                    <label for="chkAddToNewInvoice"><asp:Literal ID="litAddToInvoice" runat="server" /></label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <%-- ═══════════════════════════════════════════
                     CARTE : Rendez-vous (offert dans « Nouveau RDV », durée, lieux)
                ═══════════════════════════════════════════ --%>
                <div class="card">
                    <div class="cardHead"><div class="h"><asp:Literal ID="litRdv" runat="server" /></div></div>
                    <div class="cardBody">
                        <div class="grid">
                            <div class="chk-wrap" style="padding-top:0;">
                                <asp:CheckBox ID="chkRdv" runat="server" ClientIDMode="Static" onclick="peRdv();" />
                                <label for="chkRdv"><asp:Literal ID="litRdvOffert" runat="server" /></label>
                            </div>
                            <div class="field" id="peDuree">
                                <label><asp:Literal ID="litRdvDuree" runat="server" /></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlDuree" runat="server" DropDownHeight="250px" />
                            </div>
                        </div>
                        <div class="field" id="peLieux" style="margin-top:12px;">
                            <label><asp:Literal ID="litRdvLieux" runat="server" /></label>
                            <asp:CheckBoxList ID="cblLieux" runat="server" ClientIDMode="Static" RepeatLayout="Flow" RepeatDirection="Horizontal" CssClass="pe-lieux" />
                            <div class="section-hint" style="border:0;padding:6px 0 0;margin:0;">
                                <asp:Literal ID="litRdvLieuxHint" runat="server" />
                            </div>
                        </div>
                    </div>
                </div>

                <%-- ═══════════════════════════════════════════
                     CARTE 3 : Comptes du plan comptable
                ═══════════════════════════════════════════ --%>
                <div class="card">
                    <div class="cardHead"><div class="h"><asp:Literal ID="litGlAccounts" runat="server" /></div></div>
                    <div class="cardBody">
                        <div class="section-hint">
                            <asp:Literal ID="litGlHint" runat="server" />
                        </div>
                        <div class="grid">
                            <div class="field">
                                <label><asp:Literal ID="litSaleAccount" runat="server" /></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlCompteVente" runat="server"
                                    DefaultMessage="Utiliser le compte de la catégorie" DropDownHeight="250px" />
                            </div>
                            <div class="field">
                                <label><asp:Literal ID="litPurchaseAccount" runat="server" /></label>
                                <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlCompteAchat" runat="server"
                                    DefaultMessage="Utiliser le compte de la catégorie" DropDownHeight="250px" />
                            </div>
                        </div>
                    </div>
                </div>

                <%-- Actif + Info --%>
                <div class="card">
                    <div class="cardBody">
                        <div class="grid">
                            <div class="chk-wrap" style="padding-top:0;">
                                <asp:CheckBox  ID="chkActif" runat="server" Checked="true" ClientIDMode="Static" />
                                <label for="chkActif"><asp:Literal ID="litActiveProduct" runat="server" /></label>
                            </div>
                            <asp:Panel ID="pnlInfo" runat="server" Visible="false">
                                <div class="info-row">
                                    <div><asp:Literal ID="litIdLabel" runat="server" /> <span><asp:Label ID="tlblId" runat="server" /></span></div>
                                    <div><asp:Literal ID="litCreatedLabel" runat="server" /> <span><asp:Label ID="tlblCreated" runat="server" /></span></div>
                                </div>
                            </asp:Panel>
                        </div>
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
            // La durée ne sert que si le service est offert en rendez-vous
            function peRdv() {
                var cb = document.getElementById('chkRdv');
                var duree = document.getElementById('peDuree');
                if (cb && duree) duree.classList.toggle('pe-off', !cb.checked);
            }
            // Cocher un lieu offre le service en rendez-vous
            document.addEventListener('change', function (e) {
                var t = e.target;
                if (!t || t.type !== 'checkbox' || !t.checked || !t.closest('#cblLieux')) return;
                var cb = document.getElementById('chkRdv');
                if (cb && !cb.checked) { cb.checked = true; peRdv(); }
            });
            if (typeof Sys !== 'undefined' && Sys.Application) Sys.Application.add_load(peRdv);
        </script>

    </form>
</body>
</html>
