<%@ Page Language="VB" AutoEventWireup="false"
    CodeBehind="wbfImportView.aspx.vb" Inherits="MngConsul.wbfImportView" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Visualisation staging — MngConsul</title>
    <style>
        :root {
            --mc-bg: #f6f7fb;
            --mc-card: #ffffff;
            --mc-muted: #64748b;
            --mc-text: #0f172a;
            --mc-stroke: rgba(15, 23, 42, .12);
            --mc-radius: 14px;
            --mc-font: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --mc-blue: #2563eb;
            --mc-cyan: #06b6d4;
        }

        *, *::before, *::after { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; height: auto; min-height: 100%; }
        body {
            font-family: var(--mc-font);
            color: var(--mc-text);
            background: var(--mc-bg);
        }

        .page-wrap { padding: 18px 20px 24px; max-width: 100%; }

        .pg-header { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; }
        .pg-header .pg-ico {
            width: 44px; height: 44px; border-radius: 12px;
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            border: 1px solid var(--mc-stroke);
            display: flex; align-items: center; justify-content: center; font-size: 20px;
        }
        .pg-header h1 { font-size: 18px; font-weight: 800; margin: 0; }
        .pg-header .pg-sub { font-size: 13px; color: var(--mc-muted); margin-top: 2px; }

        .iv-section {
            background: var(--mc-card);
            border: 1px solid var(--mc-stroke);
            border-radius: var(--mc-radius);
            padding: 16px 18px;
            margin-bottom: 14px;
        }
        .iv-section h2 { font-size: 14px; font-weight: 800; margin: 0 0 12px; }

        .iv-meta { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 10px; }
        .iv-meta .iv-cell {
            padding: 9px 12px; border: 1px solid var(--mc-stroke); border-radius: 10px;
            background: #fafafa;
        }
        .iv-meta .iv-label { font-size: 10px; color: var(--mc-muted); text-transform: uppercase; letter-spacing: .4px; font-weight: 700; }
        .iv-meta .iv-value { font-size: 13px; font-weight: 700; margin-top: 3px; word-break: break-word; }

        .iv-alert {
            padding: 11px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px;
            display: flex; align-items: flex-start; gap: 10px; border: 1px solid transparent;
        }
        .iv-alert-err { background: #fef2f2; color: #991b1b; border-color: #fecaca; }
        .iv-alert-wrn { background: #fffbeb; color: #92400e; border-color: #fde68a; }

        .tbl-wrap { overflow-x: auto; border: 1px solid var(--mc-stroke); border-radius: 10px; }
        .stg-tbl { width: 100%; border-collapse: collapse; font-size: 12px; }
        .stg-tbl thead th {
            background: var(--mc-blue); color: #fff; padding: 9px 12px;
            text-align: left; font-weight: 700; font-size: 11px;
            text-transform: uppercase; letter-spacing: .3px; white-space: nowrap;
        }
        .stg-tbl tbody td { padding: 7px 12px; border-bottom: 1px solid rgba(0, 0, 0, .05); vertical-align: top; }
        .stg-tbl tbody tr:nth-child(even) { background: rgba(37, 99, 235, .025); }
        .stg-tbl tbody tr:hover { background: rgba(37, 99, 235, .06); }

        .badge { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }
        .badge-pending  { background: #fffbeb; color: #92400e; border: 1px solid #fde68a; }
        .badge-migrated { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
        .badge-error    { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        .badge-skipped  { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }

        .iv-actions { display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap; }
        .iv-btn {
            padding: 8px 16px; border-radius: 10px; font-size: 13px; font-weight: 700;
            font-family: inherit; cursor: pointer;
            border: 1px solid var(--mc-stroke); background: #fff; color: var(--mc-text);
        }
        .iv-btn:hover { background: var(--mc-bg); }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <div class="page-wrap">

            <div class="pg-header">
                <div class="pg-ico">👁</div>
                <div>
                    <h1>Visualisation staging</h1>
                    <div class="pg-sub"><asp:Literal ID="litHeaderSub" runat="server" /></div>
                </div>
            </div>

            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="iv-alert iv-alert-err">
                <span>❌</span>&nbsp;<asp:Literal ID="litError" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlWarning" runat="server" Visible="false" CssClass="iv-alert iv-alert-wrn">
                <span>⚠️</span>&nbsp;<asp:Literal ID="litWarning" runat="server" />
            </asp:Panel>

            <asp:Panel ID="pnlContent" runat="server" Visible="false">

                <div class="iv-section">
                    <h2>Résumé du fichier</h2>
                    <div class="iv-meta">
                        <div class="iv-cell"><div class="iv-label">Id</div><div class="iv-value"><asp:Literal ID="litId" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Type</div><div class="iv-value"><asp:Literal ID="litType" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Fichier</div><div class="iv-value"><asp:Literal ID="litFileName" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Téléversé le</div><div class="iv-value"><asp:Literal ID="litUploadDate" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Statut</div><div class="iv-value"><asp:Literal ID="litStatus" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Lignes extraites</div><div class="iv-value"><asp:Literal ID="litRows" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Modèle IA</div><div class="iv-value"><asp:Literal ID="litModel" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Tokens in / out</div><div class="iv-value"><asp:Literal ID="litTokens" runat="server" /></div></div>
                        <div class="iv-cell"><div class="iv-label">Coût estimé</div><div class="iv-value"><asp:Literal ID="litCost" runat="server" /></div></div>
                    </div>
                </div>

                <asp:Panel ID="pnlParty" runat="server" Visible="false" CssClass="iv-section">
                    <h2><asp:Literal ID="litPartyTitle" runat="server" /></h2>
                    <div class="tbl-wrap">
                        <asp:GridView ID="gvParty" runat="server" CssClass="stg-tbl" AutoGenerateColumns="false">
                            <Columns>
                                <asp:BoundField DataField="LineNumber"           HeaderText="#" />
                                <asp:BoundField DataField="Name"                 HeaderText="Nom" />
                                <asp:BoundField DataField="Attention"            HeaderText="Contact" />
                                <asp:BoundField DataField="Address1"             HeaderText="Adresse 1" />
                                <asp:BoundField DataField="Address2"             HeaderText="Adresse 2" />
                                <asp:BoundField DataField="City"                 HeaderText="Ville" />
                                <asp:BoundField DataField="Province"             HeaderText="Province" />
                                <asp:BoundField DataField="PostalCode"           HeaderText="Code postal" />
                                <asp:BoundField DataField="Phone"                HeaderText="Téléphone" />
                                <asp:BoundField DataField="Email"                HeaderText="Courriel" />
                                <asp:BoundField DataField="TPS"                  HeaderText="TPS" />
                                <asp:BoundField DataField="TVQ"                  HeaderText="TVQ" />
                                <asp:BoundField DataField="Balance"              HeaderText="Solde"  DataFormatString="{0:N2}" />
                                <asp:BoundField DataField="CompteAuxClient"      HeaderText="Cpt. Aux. Client" />
                                <asp:BoundField DataField="CompteAuxFournisseur" HeaderText="Cpt. Aux. Fourn." />
                                <asp:TemplateField HeaderText="Statut">
                                    <ItemTemplate>
                                        <span class='<%# "badge badge-" & Convert.ToString(Eval("Status")).ToLowerInvariant() %>'><%# Eval("Status") %></span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </asp:Panel>

                <asp:Panel ID="pnlProduct" runat="server" Visible="false" CssClass="iv-section">
                    <h2>Produits / Services en staging</h2>
                    <div class="tbl-wrap">
                        <asp:GridView ID="gvProduct" runat="server" CssClass="stg-tbl" AutoGenerateColumns="false">
                            <Columns>
                                <asp:BoundField DataField="LineNumber"     HeaderText="#" />
                                <asp:BoundField DataField="Name"           HeaderText="Nom" />
                                <asp:BoundField DataField="Description"    HeaderText="Description" />
                                <asp:BoundField DataField="Price"          HeaderText="Prix"  DataFormatString="{0:N2}" />
                                <asp:BoundField DataField="RevenueAccount" HeaderText="Cpt. Vente" />
                                <asp:BoundField DataField="ExpenseAccount" HeaderText="Cpt. Achat" />
                                <asp:TemplateField HeaderText="Taxable">
                                    <ItemTemplate>
                                        <%# If(Eval("Taxable") Is DBNull.Value, "—", If(CBool(Eval("Taxable")), "Oui", "Non")) %>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Statut">
                                    <ItemTemplate>
                                        <span class='<%# "badge badge-" & Convert.ToString(Eval("Status")).ToLowerInvariant() %>'><%# Eval("Status") %></span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </asp:Panel>

                <asp:Panel ID="pnlMigrateResult" runat="server" Visible="false" CssClass="iv-alert iv-alert-ok"
                           style="background:#f0fdf4; color:#166534; border-color:#bbf7d0;">
                    <span>✅</span>&nbsp;<asp:Literal ID="litMigrateResult" runat="server" />
                </asp:Panel>

                <div class="iv-actions">
                    <asp:Button ID="btnMigrate" runat="server" Text="📤 Pousser vers production"
                                CssClass="iv-btn"
                                style="background:var(--mc-blue); color:#fff; border-color:var(--mc-blue);"
                                OnClientClick="return confirm('Pousser les lignes en attente vers la production ? Cette action est irréversible.');"
                                CausesValidation="false" />
                    <button type="button" class="iv-btn" onclick="closeWindow();">✕ Fermer</button>
                </div>

            </asp:Panel>

        </div>

    </form>

    <script>
        // Ferme la RadWindow parente si on est ouvert dans une, sinon ferme l'onglet
        function closeWindow() {
            try {
                var oWnd = GetRadWindow();
                if (oWnd) { oWnd.close(); return; }
            } catch (e) { /* ignore */ }
            window.close();
        }

        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow;
            else if (window.frameElement && window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }
    </script>
</body>
</html>
