<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ImportSageComptes.aspx.vb" Inherits="MngConsul.ImportSageComptes" %>

<asp:Content ID="titleContent" ContentPlaceHolderID="TitleContent" runat="server">
    Import Plan Comptable — Sage 50
</asp:Content>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* ───── Page header ───── */
    .pg-header { display:flex; align-items:center; gap:14px; }
    .pg-header .pg-ico {
        width:44px; height:44px; border-radius:12px;
        background:linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border:1px solid var(--mc-stroke);
        display:flex; align-items:center; justify-content:center; font-size:20px;
    }
    .pg-header h1 { font-size:20px; font-weight:800; margin:0; }
    .pg-header .pg-sub { font-size:13px; color:var(--mc-muted); margin-top:1px; }

    /* ───── Sections ───── */
    .imp-section { padding:20px; border-bottom:1px solid var(--mc-stroke); }
    .imp-section:last-child { border-bottom:none; }
    .imp-section h2 { font-size:15px; font-weight:800; margin:0 0 4px; }
    .imp-section .sec-desc { font-size:13px; color:var(--mc-muted); margin-bottom:16px; }

    /* ───── Upload zone ───── */
    .upload-zone {
        border:2px dashed var(--mc-stroke); border-radius:14px;
        padding:32px 20px; text-align:center;
        transition:border-color .2s, background .2s; cursor:pointer;
    }
    .upload-zone:hover, .upload-zone.dragover {
        border-color:var(--mc-blue); background:rgba(37,99,235,.05);
    }
    .upload-zone .uz-ico { font-size:34px; margin-bottom:8px; }
    .upload-zone p { font-size:14px; color:var(--mc-muted); margin:0; }
    .upload-zone .uz-hint { font-size:12px; color:var(--mc-muted); margin-top:6px; opacity:.65; }

    /* ───── File info ───── */
    .file-pill {
        display:flex; align-items:center; gap:12px;
        padding:10px 14px; margin-top:12px;
        background:linear-gradient(135deg, rgba(37,99,235,.07), rgba(6,182,212,.05));
        border:1px solid var(--mc-stroke); border-radius:12px;
    }
    .file-pill .fp-ico { font-size:24px; }
    .file-pill .fp-name { font-weight:700; font-size:14px; }
    .file-pill .fp-size { font-size:12px; color:var(--mc-muted); }
    .file-pill .fp-rm {
        margin-left:auto; color:#ef4444; cursor:pointer;
        font-size:16px; background:none; border:none; font-family:inherit;
    }

    /* ───── Options ───── */
    .opts { display:grid; grid-template-columns:1fr 1fr; gap:14px; margin-top:14px; }
    @media (max-width:640px) { .opts { grid-template-columns:1fr; } }
    .opt label { display:block; font-size:13px; font-weight:700; margin-bottom:4px; }
    .opt select {
        width:100%; padding:9px 12px; border:1px solid var(--mc-stroke);
        border-radius:10px; font-size:13px; font-family:inherit; background:#fff;
        color:var(--mc-text); outline:none;
    }
    .opt select:focus { border-color:var(--mc-blue); box-shadow:0 0 0 3px rgba(37,99,235,.12); }
    .opt .hint { font-size:11px; color:var(--mc-muted); margin-top:3px; }

    /* ───── Checkbox ───── */
    .chk { display:flex; align-items:center; gap:8px; margin-top:12px; }
    .chk input[type="checkbox"] { width:16px; height:16px; accent-color:var(--mc-blue); }
    .chk label { font-size:13px; cursor:pointer; }

    /* ───── Buttons ───── */
    .imp-actions { display:flex; gap:10px; margin-top:18px; justify-content:flex-end; flex-wrap:wrap; }
    .imp-btn {
        padding:10px 20px; border-radius:10px; font-size:14px;
        font-weight:700; font-family:inherit; cursor:pointer;
        border:none; display:inline-flex; align-items:center; gap:7px;
        transition:all .15s;
    }
    .imp-btn-primary { background:var(--mc-blue); color:#fff; }
    .imp-btn-primary:hover { filter:brightness(.92); }
    .imp-btn-secondary { background:#fff; color:var(--mc-text); border:1px solid var(--mc-stroke); }
    .imp-btn-secondary:hover { background:var(--mc-bg); }
    .imp-btn-danger { background:#ef4444; color:#fff; }
    .imp-btn-danger:hover { background:#dc2626; }

    /* ───── Alerts ───── */
    .imp-alert {
        padding:12px 16px; border-radius:12px; font-size:13px;
        margin:16px 20px 0; display:flex; align-items:flex-start; gap:10px;
        border:1px solid transparent;
    }
    .imp-alert-ok  { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .imp-alert-err { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .imp-alert-wrn { background:#fffbeb; color:#92400e; border-color:#fde68a; }
    .imp-alert .al-ico { font-size:17px; flex-shrink:0; }
    .imp-alert .al-body { flex:1; }
    .imp-alert .al-title { font-weight:700; margin-bottom:2px; }

    /* ───── Tables ───── */
    .tbl-wrap { overflow-x:auto; border:1px solid var(--mc-stroke); border-radius:12px; }
    .imp-tbl { width:100%; border-collapse:collapse; font-size:13px; }
    .imp-tbl thead th {
        background:var(--mc-blue); color:#fff; padding:10px 14px;
        text-align:left; font-weight:700; font-size:12px;
        text-transform:uppercase; letter-spacing:.3px;
    }
    .imp-tbl tbody td { padding:8px 14px; border-bottom:1px solid rgba(0,0,0,.05); }
    .imp-tbl tbody tr:nth-child(even) { background:rgba(37,99,235,.025); }
    .imp-tbl tbody tr:hover { background:rgba(37,99,235,.06); }
    .tbl-info { font-size:12px; color:var(--mc-muted); margin-top:8px; display:flex; align-items:center; gap:6px; }

    /* ───── Mapping table ───── */
    .map-tbl { width:100%; font-size:12px; border-collapse:collapse; }
    .map-tbl th {
        background:rgba(37,99,235,.06); padding:8px 12px; text-align:left;
        font-weight:700; border-bottom:2px solid var(--mc-stroke);
    }
    .map-tbl td { padding:6px 12px; border-bottom:1px solid rgba(0,0,0,.04); }
    .c-csv { color:var(--mc-blue); font-weight:700; }
    .c-arr { color:var(--mc-muted); text-align:center; }
    .c-db  { color:#16a34a; font-weight:700; }

    /* ───── Stats ───── */
    .stats { display:flex; gap:12px; flex-wrap:wrap; }
    .stat {
        flex:1; min-width:110px; padding:16px;
        border-radius:14px; text-align:center;
        border:1px solid var(--mc-stroke);
    }
    .stat .sv { font-size:28px; font-weight:800; }
    .stat .sl { font-size:12px; color:var(--mc-muted); margin-top:3px; }
    .s-ok  { background:#f0fdf4; } .s-ok  .sv { color:#16a34a; }
    .s-wrn { background:#fffbeb; } .s-wrn .sv { color:#d97706; }
    .s-err { background:#fef2f2; } .s-err .sv { color:#dc2626; }
</style>
</asp:Content>

<asp:Content ID="mainContent" ContentPlaceHolderID="MainContent" runat="server">

    <!-- ═══ TOOLBAR ═══ -->
    <div class="toolbar">
        <div class="pg-header">
            <div class="pg-ico">📊</div>
            <div>
                <h1>Import Plan Comptable</h1>
                <div class="pg-sub">Migration Sage 50 → staging.SageComptes</div>
            </div>
        </div>
    </div>

    <!-- ═══ MESSAGES ═══ -->
    <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="imp-alert imp-alert-ok">
        <span class="al-ico">✅</span>
        <div class="al-body">
            <div class="al-title">Importation réussie</div>
            <asp:Literal ID="litSuccess" runat="server" />
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="imp-alert imp-alert-err">
        <span class="al-ico">❌</span>
        <div class="al-body">
            <div class="al-title">Erreur</div>
            <asp:Literal ID="litError" runat="server" />
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlWarning" runat="server" Visible="false" CssClass="imp-alert imp-alert-wrn">
        <span class="al-ico">⚠️</span>
        <div class="al-body">
            <div class="al-title">Attention</div>
            <asp:Literal ID="litWarning" runat="server" />
        </div>
    </asp:Panel>

    <!-- ═══ ÉTAPE 1 : UPLOAD ═══ -->
    <asp:Panel ID="pnlUpload" runat="server">
        <div class="imp-section">
            <h2>Étape 1 — Sélectionner le fichier CSV</h2>
            <p class="sec-desc">
                Exportez votre plan comptable depuis Sage 50 :
                <strong>Reports &gt; Lists &gt; Chart of Accounts &gt; Export CSV</strong>
            </p>

            <div class="upload-zone" id="dropZone" onclick="document.getElementById('<%= fuCsvFile.ClientID %>').click();">
                <div class="uz-ico">📁</div>
                <p><strong>Glissez votre fichier ici</strong> ou cliquez pour parcourir</p>
                <p class="uz-hint">Formats acceptés : .csv, .txt &nbsp;|&nbsp; Taille max : 10 Mo</p>
            </div>

            <asp:FileUpload ID="fuCsvFile" runat="server" style="display:none;"
                onchange="showFileInfo(this);" accept=".csv,.txt" />

            <div id="fileInfoDiv" style="display:none;">
                <div class="file-pill">
                    <span class="fp-ico">📄</span>
                    <div>
                        <div class="fp-name" id="fileName"></div>
                        <div class="fp-size" id="fileSize"></div>
                    </div>
                    <button type="button" class="fp-rm" onclick="clearFile();">✕</button>
                </div>
            </div>

            <div class="opts">
                <div class="opt">
                    <label>Séparateur</label>
                    <asp:DropDownList ID="ddlSeparator" runat="server">
                        <asp:ListItem Value=";" Text="Point-virgule ( ; ) — défaut Sage 50" Selected="True" />
                        <asp:ListItem Value="," Text="Virgule ( , )" />
                        <asp:ListItem Value="&#9;" Text="Tabulation" />
                    </asp:DropDownList>
                    <div class="hint">Sage 50 utilise généralement le point-virgule</div>
                </div>
                <div class="opt">
                    <label>Encodage</label>
                    <asp:DropDownList ID="ddlEncoding" runat="server">
                        <asp:ListItem Value="UTF-8" Text="UTF-8" />
                        <asp:ListItem Value="Windows-1252" Text="Windows-1252 (ANSI)" Selected="True" />
                        <asp:ListItem Value="ISO-8859-1" Text="ISO-8859-1 (Latin-1)" />
                    </asp:DropDownList>
                    <div class="hint">Sage 50 exporte souvent en Windows-1252</div>
                </div>
            </div>

            <div class="chk">
                <asp:CheckBox ID="chkHasHeader" runat="server" Checked="true" />
                <label for="<%= chkHasHeader.ClientID %>">Le fichier contient une ligne d'en-tête</label>
            </div>
            <div class="chk">
                <asp:CheckBox ID="chkTruncate" runat="server" Checked="false" />
                <label for="<%= chkTruncate.ClientID %>">Vider la table staging.SageComptes avant l'import</label>
            </div>

            <div class="imp-actions">
                <asp:Button ID="btnPreview" runat="server" Text="👁 Aperçu" CssClass="imp-btn imp-btn-secondary" />
                <asp:Button ID="btnImport" runat="server" Text="📥 Importer" CssClass="imp-btn imp-btn-primary" />
            </div>
        </div>
    </asp:Panel>

    <!-- ═══ MAPPING ═══ -->
    <div class="imp-section">
        <h2>Correspondance des colonnes</h2>
        <p class="sec-desc">Votre CSV doit contenir ces colonnes (l'ordre peut varier) :</p>
        <table class="map-tbl">
            <thead>
                <tr><th>Colonne CSV (Sage 50)</th><th></th><th>Champ SQL</th><th>Type</th><th>Description</th></tr>
            </thead>
            <tbody>
                <tr><td class="c-csv">Account Number</td><td class="c-arr">→</td><td class="c-db">SageAccountNumber</td><td>VARCHAR(20)</td><td>Numéro du compte</td></tr>
                <tr><td class="c-csv">Account Name</td><td class="c-arr">→</td><td class="c-db">SageAccountName</td><td>VARCHAR(200)</td><td>Nom du compte</td></tr>
                <tr><td class="c-csv">Account Type</td><td class="c-arr">→</td><td class="c-db">SageAccountType</td><td>VARCHAR(50)</td><td>Asset, Liability, Equity, Revenue, Expense</td></tr>
                <tr><td class="c-csv">Balance</td><td class="c-arr">→</td><td class="c-db">SageBalance</td><td>DECIMAL(15,2)</td><td>Solde du compte</td></tr>
                <tr><td class="c-csv">Balance Type</td><td class="c-arr">→</td><td class="c-db">SageBalanceType</td><td>VARCHAR(10)</td><td>Debit ou Credit</td></tr>
            </tbody>
        </table>
    </div>

    <!-- ═══ APERÇU ═══ -->
    <asp:Panel ID="pnlPreview" runat="server" Visible="false">
        <div class="imp-section">
            <h2>Aperçu des données</h2>
            <p class="sec-desc">Premières lignes du fichier — vérifiez le mapping.</p>
            <div class="tbl-wrap">
                <asp:GridView ID="gvPreview" runat="server" CssClass="imp-tbl"
                    AutoGenerateColumns="true" ShowHeaderWhenEmpty="true" />
            </div>
            <div class="tbl-info">
                📋 <asp:Literal ID="litPreviewInfo" runat="server" />
            </div>
        </div>
    </asp:Panel>

    <!-- ═══ RÉSULTATS ═══ -->
    <asp:Panel ID="pnlResults" runat="server" Visible="false">
        <div class="imp-section">
            <h2>Résultats de l'importation</h2>
            <div class="stats">
                <div class="stat s-ok">
                    <div class="sv"><asp:Literal ID="litInserted" runat="server" /></div>
                    <div class="sl">Lignes insérées</div>
                </div>
                <div class="stat s-wrn">
                    <div class="sv"><asp:Literal ID="litSkipped" runat="server" /></div>
                    <div class="sl">Lignes ignorées</div>
                </div>
                <div class="stat s-err">
                    <div class="sv"><asp:Literal ID="litErrors" runat="server" /></div>
                    <div class="sl">Erreurs</div>
                </div>
            </div>

            <asp:Panel ID="pnlErrorDetails" runat="server" Visible="false">
                <h2 style="margin-top:18px;">Détail des erreurs</h2>
                <div class="tbl-wrap" style="margin-top:10px;">
                    <asp:GridView ID="gvErrors" runat="server" CssClass="imp-tbl"
                        AutoGenerateColumns="true" />
                </div>
            </asp:Panel>

            <div class="imp-actions">
                <asp:Button ID="btnReset" runat="server" Text="🔄 Nouvel import" CssClass="imp-btn imp-btn-secondary" />
                <asp:Button ID="btnTruncateTable" runat="server" Text="🗑 Vider la table staging"
                    CssClass="imp-btn imp-btn-danger"
                    OnClientClick="return confirm('Êtes-vous sûr de vouloir vider la table staging.SageComptes ?');" />
            </div>
        </div>
    </asp:Panel>

    <!-- ═══ SCRIPT ═══ -->
    <script>
        (function () {
            var dz = document.getElementById('dropZone');
            if (!dz) return;

            ['dragenter', 'dragover'].forEach(function (evt) {
                dz.addEventListener(evt, function (e) { e.preventDefault(); dz.classList.add('dragover'); });
            });
            ['dragleave', 'drop'].forEach(function (evt) {
                dz.addEventListener(evt, function (e) { e.preventDefault(); dz.classList.remove('dragover'); });
            });
            dz.addEventListener('drop', function (e) {
                var fi = document.getElementById('<%= fuCsvFile.ClientID %>');
                if (e.dataTransfer.files.length > 0) { fi.files = e.dataTransfer.files; showFileInfo(fi); }
            });
        })();

        function showFileInfo(input) {
            if (input.files && input.files.length > 0) {
                var f = input.files[0];
                document.getElementById('fileName').textContent = f.name;
                var sz = f.size > 1048576 ? (f.size / 1048576).toFixed(2) + ' Mo' : (f.size / 1024).toFixed(1) + ' Ko';
                document.getElementById('fileSize').textContent = sz;
                document.getElementById('fileInfoDiv').style.display = 'block';
                document.getElementById('dropZone').style.display = 'none';
            }
        }
        function clearFile() {
            document.getElementById('<%= fuCsvFile.ClientID %>').value = '';
            document.getElementById('fileInfoDiv').style.display = 'none';
            document.getElementById('dropZone').style.display = 'block';
        }
    </script>

</asp:Content>
