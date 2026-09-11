<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="ImportBalanceVerification.aspx.vb" Inherits="MngConsul.ImportBalanceVerification" %>
<%@ Register Src="~/Controls/SourceDonnees.ascx" TagPrefix="uc" TagName="SourceDonnees" %>

<asp:Content ID="titleContent" ContentPlaceHolderID="TitleContent" runat="server">
    Import Balance de Vérification
</asp:Content>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .pg-header { display:flex; align-items:center; gap:14px; }
    .pg-header .pg-ico {
        width:44px; height:44px; border-radius:12px;
        background:linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border:1px solid var(--mc-stroke);
        display:flex; align-items:center; justify-content:center; font-size:20px;
    }
    .pg-header h1 { font-size:20px; font-weight:800; margin:0; }
    .pg-header .pg-sub { font-size:13px; color:var(--mc-muted); margin-top:1px; }
    .imp-section { padding:20px; border-bottom:1px solid var(--mc-stroke); }
    .imp-section:last-child { border-bottom:none; }
    .imp-section h2 { font-size:15px; font-weight:800; margin:0 0 4px; }
    .imp-section .sec-desc { font-size:13px; color:var(--mc-muted); margin-bottom:16px; }
    .upload-zone {
        border:1.5px dashed var(--mc-stroke); border-radius:10px;
        display:flex; align-items:center; gap:9px; padding:9px 13px; transition:border-color .2s, background .2s; cursor:pointer;
    }
    .upload-zone:hover, .upload-zone.dragover { border-color:var(--mc-blue); background:rgba(37,99,235,.05); }
    .upload-zone .uz-ico { font-size:17px; line-height:1; }
    .upload-zone p { font-size:13px; color:var(--mc-muted); margin:0; }
    .upload-zone .uz-hint { font-size:11.5px; margin-left:auto; padding-left:10px; white-space:nowrap; opacity:.65; }
    .file-pill {
        display:flex; align-items:center; gap:10px; padding:7px 12px; margin-top:10px;
        background:linear-gradient(135deg, rgba(37,99,235,.07), rgba(6,182,212,.05));
        border:1px solid var(--mc-stroke); border-radius:12px;
    }
    .file-pill .fp-ico { font-size:17px; }
    .file-pill .fp-name { font-weight:700; font-size:13px; }
    .file-pill .fp-size { font-size:12px; color:var(--mc-muted); }
    .file-pill .fp-rm { margin-left:auto; color:#ef4444; cursor:pointer; font-size:16px; background:none; border:none; }
    .chk { display:flex; align-items:center; gap:8px; margin-top:12px; }
    .chk input[type="checkbox"] { width:16px; height:16px; accent-color:var(--mc-blue); }
    .chk label { font-size:13px; cursor:pointer; }
    .imp-actions { display:flex; gap:10px; margin-top:18px; justify-content:flex-end; flex-wrap:wrap; }
    .imp-btn {
        padding:10px 20px; border-radius:10px; font-size:14px; font-weight:700;
        font-family:inherit; cursor:pointer; border:none; display:inline-flex; align-items:center; gap:7px; transition:all .15s;
    }
    .imp-btn-primary { background:var(--mc-blue); color:#fff; }
    .imp-btn-primary:hover { filter:brightness(.92); }
    .imp-btn-secondary { background:#fff; color:var(--mc-text); border:1px solid var(--mc-stroke); }
    .imp-btn-secondary:hover { background:var(--mc-bg); }
    .imp-btn-danger { background:#ef4444; color:#fff; }
    .imp-btn-danger:hover { background:#dc2626; }
    .imp-alert {
        padding:12px 16px; border-radius:12px; font-size:13px; margin:16px 20px 0;
        display:flex; align-items:flex-start; gap:10px; border:1px solid transparent;
    }
    .imp-alert-ok  { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .imp-alert-err { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .imp-alert-wrn { background:#fffbeb; color:#92400e; border-color:#fde68a; }
    .imp-alert .al-ico { font-size:17px; flex-shrink:0; }
    .imp-alert .al-body { flex:1; }
    .imp-alert .al-title { font-weight:700; margin-bottom:2px; }
    .tbl-wrap { overflow-x:auto; border:1px solid var(--mc-stroke); border-radius:12px; }
    .imp-tbl { width:100%; border-collapse:collapse; font-size:13px; }
    .imp-tbl thead th {
        background:var(--mc-blue); color:#fff; padding:10px 14px;
        text-align:left; font-weight:700; font-size:12px; text-transform:uppercase; letter-spacing:.3px;
    }
    .imp-tbl tbody td { padding:8px 14px; border-bottom:1px solid rgba(0,0,0,.05); }
    .imp-tbl tbody tr:nth-child(even) { background:rgba(37,99,235,.025); }
    .imp-tbl tbody tr:hover { background:rgba(37,99,235,.06); }
    .tbl-info { font-size:12px; color:var(--mc-muted); margin-top:8px; display:flex; align-items:center; gap:6px; }
    .map-tbl { width:100%; font-size:12px; border-collapse:collapse; }
    .map-tbl th { background:rgba(37,99,235,.06); padding:8px 12px; text-align:left; font-weight:700; border-bottom:2px solid var(--mc-stroke); }
    .map-tbl td { padding:6px 12px; border-bottom:1px solid rgba(0,0,0,.04); }
    .c-csv { color:var(--mc-blue); font-weight:700; }
    .c-arr { color:var(--mc-muted); text-align:center; }
    .c-db  { color:#16a34a; font-weight:700; }
    .stats { display:flex; gap:12px; flex-wrap:wrap; }
    .stat { flex:1; min-width:110px; padding:16px; border-radius:14px; text-align:center; border:1px solid var(--mc-stroke); }
    .stat .sv { font-size:28px; font-weight:800; }
    .stat .sl { font-size:12px; color:var(--mc-muted); margin-top:3px; }
    .s-ok  { background:#f0fdf4; } .s-ok  .sv { color:#16a34a; }
    .s-wrn { background:#fffbeb; } .s-wrn .sv { color:#d97706; }
    .s-err { background:#fef2f2; } .s-err .sv { color:#dc2626; }
    .equil { padding:11px 14px; border-radius:12px; margin:16px 0 12px; font-size:13.5px; font-weight:700; border:1px solid transparent; }
    .equil.ok { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .equil.ko { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .imp-tbl .num { text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap; }
    .imp-tbl tfoot td { font-weight:800; padding:9px 14px; border-top:2px solid var(--mc-stroke); background:rgba(37,99,235,.04); }
    .imp-btn-ia { background:#6d28d9; color:#fff; }
    .imp-btn-ia:hover { background:#5b21b6; }
    .ia-hint { font-size:12px; color:var(--mc-muted); margin:14px 0 0; text-align:right; }
    .equil.ia { background:#f5f3ff; color:#5b21b6; border-color:#ddd6fe; font-weight:600; }
    .origine { font-size:12.5px; color:var(--mc-muted); margin:2px 0 12px; line-height:1.5; }
    .ctrl { border:1px solid var(--mc-stroke); border-radius:12px; padding:14px 16px; margin:14px 0; background:#fff; }
    .ctrl h3 { font-size:14px; font-weight:800; margin:0 0 4px; }
    .ctrl .ctx { font-size:12.5px; color:var(--mc-muted); margin:0 0 10px; line-height:1.5; }
    .ctrl .chips { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:10px; }
    .ctrl .chip { padding:4px 10px; border-radius:999px; font-size:12px; font-weight:700; }
    .grv { display:inline-block; padding:1px 8px; border-radius:999px; font-size:11px; font-weight:800; white-space:nowrap; }
    .grv-err { background:#fef2f2; color:#b91c1c; }
    .grv-ver { background:#fffbeb; color:#b45309; }
    .grv-inf { background:#f1f5f9; color:#64748b; }
    .ctrl .rien { padding:10px 12px; border-radius:10px; background:#f0fdf4; color:#166534; font-weight:700; font-size:13px; }
</style>
</asp:Content>

<asp:Content ID="mainContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="toolbar">
        <div class="pg-header">
            <div class="pg-ico">📋</div>
            <div>
                <h1>Import Balance de Vérification</h1>
                <div class="pg-sub">Migration → staging.BalanceVerification</div>
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="imp-alert imp-alert-ok">
        <span class="al-ico">✅</span><div class="al-body"><div class="al-title">C'est fait</div><asp:Literal ID="litSuccess" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="imp-alert imp-alert-err">
        <span class="al-ico">❌</span><div class="al-body"><div class="al-title">Erreur</div><asp:Literal ID="litError" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlWarning" runat="server" Visible="false" CssClass="imp-alert imp-alert-wrn">
        <span class="al-ico">⚠️</span><div class="al-body"><div class="al-title">Attention</div><asp:Literal ID="litWarning" runat="server" /></div>
    </asp:Panel>

    <asp:Panel ID="pnlResults" runat="server" Visible="false">
        <div class="imp-section">
            <h2><asp:Literal ID="litTitreResultat" runat="server" Text="Résultat de l'importation" /></h2>
            <asp:Literal ID="litOrigine" runat="server" />
            <asp:Panel ID="pnlStats" runat="server">
            <div class="stats">
                <div class="stat s-ok"><div class="sv"><asp:Literal ID="litInserted" runat="server" /></div><div class="sl">Insérées</div></div>
                <div class="stat s-wrn"><div class="sv"><asp:Literal ID="litSkipped" runat="server" /></div><div class="sl">Ignorées</div></div>
                <div class="stat s-err"><div class="sv"><asp:Literal ID="litErrors" runat="server" /></div><div class="sl">Erreurs</div></div>
            </div>
            </asp:Panel>
            <asp:Panel ID="pnlControle" runat="server" Visible="false">
                <asp:Literal ID="litControle" runat="server" />
            </asp:Panel>
            <asp:Panel ID="pnlBalance" runat="server" Visible="false">
                <asp:Literal ID="litEquilibre" runat="server" />
                <asp:Literal ID="litBalance" runat="server" />
            </asp:Panel>
            <asp:Panel ID="pnlErrorDetails" runat="server" Visible="false">
                <h2 style="margin-top:18px;">Détail des erreurs</h2>
                <div class="tbl-wrap" style="margin-top:10px;"><asp:GridView ID="gvErrors" runat="server" CssClass="imp-tbl" AutoGenerateColumns="true" /></div>
            </asp:Panel>
            <div class="imp-actions">
                <asp:Button ID="btnControle" runat="server" Text="🔍 Incohérences avec le plan comptable" CssClass="imp-btn imp-btn-primary" CausesValidation="false" />
                <asp:Button ID="btnReset" runat="server" Text="🔄 Nouvel import" CssClass="imp-btn imp-btn-secondary" />
                <asp:Button ID="btnTruncateTable" runat="server" Text="🗑 Supprimer la balance importée" CssClass="imp-btn imp-btn-danger"
                    OnClientClick="if (!confirm('Supprimer la balance importée de votre compagnie ?')) { return false; }" />
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ 1 · D'OÙ VIENNENT LES DONNÉES ══════════ -->
    <div class="imp-section">
        <uc:SourceDonnees ID="ucSource" runat="server" Donnees="BALANCE" Numero="1" />
    </div>

    <!-- ══════════ 2 · LE FICHIER ══════════ -->
    <asp:Panel ID="pnlUpload" runat="server">
        <div class="imp-section">
            <h2>2 — Le fichier</h2>
            <p class="sec-desc">La balance de vérification <strong>à la date de bascule</strong>, en CSV ou en texte. 10 Mo au maximum.</p>

            <div class="upload-zone" id="dropZone" onclick="document.getElementById('<%= fuCsvFile.ClientID %>').click();">
                <div class="uz-ico">📁</div>
                <p><strong>Glissez votre fichier ici</strong> ou cliquez pour parcourir</p>
                <p class="uz-hint">Formats : .csv, .txt | Max : 10 Mo</p>
            </div>
            <asp:FileUpload ID="fuCsvFile" runat="server" style="display:none;" onchange="showFileInfo(this);" accept=".csv,.txt" />
            <div id="fileInfoDiv" style="display:none;">
                <div class="file-pill">
                    <span class="fp-ico">📄</span>
                    <div><div class="fp-name" id="fileName"></div><div class="fp-size" id="fileSize"></div></div>
                    <button type="button" class="fp-rm" onclick="clearFile();">✕</button>
                </div>
            </div>

            <div class="chk"><asp:CheckBox ID="chkTruncate" runat="server" Checked="true" /><label for="<%= chkTruncate.ClientID %>">Remplacer la balance déjà importée</label></div>
            <p class="ia-hint">Fichier mal formaté ? <strong>Lire avec l'IA</strong> confie la lecture à ChatGPT. Chaque montant rendu est retrouvé dans le fichier d'origine avant d'être accepté.</p>
            <div class="imp-actions">
                <asp:Button ID="btnPreview" runat="server" Text="👁 Aperçu" CssClass="imp-btn imp-btn-secondary" />
                <asp:Button ID="btnIA" runat="server" Text="✨ Lire avec l'IA" CssClass="imp-btn imp-btn-ia" CausesValidation="false" OnClientClick="this.value='⏳ Lecture par l\'IA…';" />
                <asp:Button ID="btnImport" runat="server" Text="📥 Importer" CssClass="imp-btn imp-btn-primary" />
            </div>
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlPreview" runat="server" Visible="false">
        <div class="imp-section">
            <h2>Aperçu</h2>
            <div class="tbl-wrap"><asp:GridView ID="gvPreview" runat="server" CssClass="imp-tbl" AutoGenerateColumns="true" ShowHeaderWhenEmpty="true" /></div>
            <div class="tbl-info">📋 <asp:Literal ID="litPreviewInfo" runat="server" /></div>
        </div>
    </asp:Panel>

    <div class="imp-section">
        <h2>Correspondance des colonnes</h2>
        <p class="sec-desc">Colonnes reconnues. Les lignes de titre avant l'en-tête, la ligne <strong>TOTAL</strong> et le pied de page sont écartés d'eux-mêmes ; le total du fichier sert à contrôler la lecture.</p>
        <table class="map-tbl">
            <thead><tr><th>Colonne CSV</th><th></th><th>Champ SQL</th><th>Type</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td class="c-csv">Numéro de compte — facultatif</td><td class="c-arr">→</td><td class="c-db">Compte</td><td>VARCHAR(20)</td><td>Absent chez QuickBooks : le nom suffit</td></tr>
                <tr><td class="c-csv">Account Name / Nom du compte</td><td class="c-arr">→</td><td class="c-db">Description</td><td>VARCHAR(200)</td><td>Nom du compte</td></tr>
                <tr><td class="c-csv">Debit / Débit</td><td class="c-arr">→</td><td class="c-db">Debit</td><td>DECIMAL(15,2)</td><td>Solde débiteur — « 21,095.57 » comme « 21 095,57 »</td></tr>
                <tr><td class="c-csv">Credit / Crédit</td><td class="c-arr">→</td><td class="c-db">Credit</td><td>DECIMAL(15,2)</td><td>Solde créditeur</td></tr>
            </tbody>
        </table>
    </div>

    <script>
        (function(){
            var dz=document.getElementById('dropZone'); if(!dz)return;
            ['dragenter','dragover'].forEach(function(e){dz.addEventListener(e,function(ev){ev.preventDefault();dz.classList.add('dragover');});});
            ['dragleave','drop'].forEach(function(e){dz.addEventListener(e,function(ev){ev.preventDefault();dz.classList.remove('dragover');});});
            dz.addEventListener('drop',function(e){var fi=document.getElementById('<%= fuCsvFile.ClientID %>');if(e.dataTransfer.files.length>0){fi.files=e.dataTransfer.files;showFileInfo(fi);}});
        })();
        function showFileInfo(i){if(i.files&&i.files.length>0){var f=i.files[0];document.getElementById('fileName').textContent=f.name;document.getElementById('fileSize').textContent=f.size>1048576?(f.size/1048576).toFixed(2)+' Mo':(f.size/1024).toFixed(1)+' Ko';document.getElementById('fileInfoDiv').style.display='block';document.getElementById('dropZone').style.display='none';}}
        function clearFile(){document.getElementById('<%= fuCsvFile.ClientID %>').value='';document.getElementById('fileInfoDiv').style.display='none';document.getElementById('dropZone').style.display='';}
    </script>
</asp:Content>
