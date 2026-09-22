<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="ImportBalanceVerification.aspx.vb" Inherits="MngConsul.ImportBalanceVerification" %>
<%@ Register Src="~/Controls/SourceDonnees.ascx" TagPrefix="uc" TagName="SourceDonnees" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="titleContent" ContentPlaceHolderID="TitleContent" runat="server">
    Import Balance de Vérification
</asp:Content>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    /* La page reprend la mise en forme des autres écrans d'importation : une
       page centrée, des cartes blanches, des titres à pastille. Les classes
       propres à cet écran — équilibre, incohérences, pastilles de gravité — ne
       changent pas de nom : le code-behind les écrit lui-même. */

    .imp-page { max-width: 1150px; margin: 0 auto; padding: 16px }

    .imp-head { display:flex; align-items:center; gap:14px; margin-bottom:6px; }
    .imp-head .ico {
        width:46px; height:46px; border-radius:13px;
        background:linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border:1px solid #e2e8f0;
        display:flex; align-items:center; justify-content:center; font-size:21px;
    }
    .imp-head h1 { font-size:21px; font-weight:800; margin:0; color:#0f172a }
    .imp-head .sub { font-size:13px; color:#64748b; margin-top:2px }

    .imp-lede { font-size:13.5px; color:#475569; margin:0 0 18px; max-width:760px; line-height:1.6 }

    .imp-section {
        background:#fff; border:1px solid #e2e8f0; border-radius:14px;
        padding:20px; margin-bottom:16px;
    }

    .imp-section h2 {
        font-size:15px; font-weight:800; margin:0 0 3px; color:#0f172a;
        display:flex; align-items:center; gap:9px;
    }

    .imp-section h2 .n {
        width:24px; height:24px; border-radius:999px; flex:0 0 auto;
        background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe;
        font-size:12px; display:flex; align-items:center; justify-content:center;
    }

    .imp-section .sec-desc { font-size:13px; color:#64748b; margin:0 0 15px; padding-left:33px }
    .imp-section > .body { padding-left:33px }

    /* Section repliable : le titre devient la poignée, le chevron dit le sens. */
    details.imp-section > summary { list-style:none; cursor:pointer; border-radius:8px }
    details.imp-section > summary::-webkit-details-marker { display:none }
    details.imp-section > summary::marker { content: "" }
    details.imp-section > summary h2 { margin:0 }
    details.imp-section > summary:hover h2 { color:#1d4ed8 }
    details.imp-section[open] > summary h2 { margin-bottom:3px }
    .imp-chev { margin-left:auto; font-size:12px; color:#94a3b8; transition:transform .15s }
    details.imp-section[open] .imp-chev { transform:rotate(180deg) }

    .upload-zone {
        border:1.5px dashed #cbd5e1; border-radius:10px;
        display:flex; align-items:center; gap:9px; padding:9px 13px;
        transition:border-color .2s, background .2s; cursor:pointer;
    }
    .upload-zone:hover, .upload-zone.dragover { border-color:#2563eb; background:rgba(37,99,235,.05); }
    .upload-zone .uz-ico { font-size:17px; line-height:1; }
    .upload-zone p { font-size:13px; color:#64748b; margin:0; }
    .upload-zone .uz-hint { font-size:11.5px; margin-left:auto; padding-left:10px; white-space:nowrap; opacity:.65; }

    .file-pill {
        display:flex; align-items:center; gap:10px; padding:7px 12px; margin-top:10px;
        background:rgba(37,99,235,.05); border:1px solid #bfdbfe; border-radius:12px;
    }
    .file-pill .fp-ico { font-size:17px; }
    .file-pill .fp-name { font-weight:700; font-size:13px; }
    .file-pill .fp-size { font-size:12px; color:#64748b; }
    .file-pill .fp-rm { margin-left:auto; color:#ef4444; cursor:pointer; font-size:16px; background:none; border:none; }

    .chk { display:flex; align-items:center; gap:7px; margin-top:13px; font-size:13px }
    .chk input[type="checkbox"] { width:16px; height:16px; accent-color:#2563eb; }
    .chk label { cursor:pointer; }

    /* Les actions restent à gauche, sous ce qu'elles commandent — comme ailleurs. */
    .imp-actions { display:flex; gap:9px; flex-wrap:wrap; margin-top:16px; }

    .imp-btn {
        padding:9px 15px; border-radius:9px; font-size:13px; font-weight:700;
        border:1px solid transparent; cursor:pointer; font-family:inherit;
        display:inline-flex; align-items:center; gap:7px;
    }
    .imp-btn-primary { background:#2563eb; color:#fff; }
    .imp-btn-primary:hover { filter:brightness(.92); }
    .imp-btn-secondary { background:#f1f5f9; color:#334155; border-color:#e2e8f0; }
    .imp-btn-secondary:hover { background:#e2e8f0; }
    .imp-btn-danger { background:#fef2f2; color:#b91c1c; border-color:#fecaca; }
    .imp-btn-danger:hover { background:#fee2e2; }
    .imp-btn-ia { background:#6d28d9; color:#fff; }
    .imp-btn-ia:hover { background:#5b21b6; }

    .imp-alert {
        padding:12px 16px; border-radius:12px; font-size:13px; margin:0 0 16px;
        display:flex; align-items:flex-start; gap:10px; border:1px solid transparent;
    }
    .imp-alert-ok  { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .imp-alert-err { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .imp-alert-wrn { background:#fffbeb; color:#92400e; border-color:#fde68a; }
    .imp-alert .al-ico { font-size:17px; flex-shrink:0; }
    .imp-alert .al-body { flex:1; }
    .imp-alert .al-title { font-weight:700; margin-bottom:2px; }

    /* La grille défile dans son cadre, l'entête reste visible : une balance de
       deux cents comptes ne doit pas repousser les boutons hors de l'écran. */
    .tbl-wrap { overflow:auto; max-height:540px; border:1px solid #e2e8f0; border-radius:12px; margin-top:12px }

    .imp-tbl { width:100%; border-collapse:collapse; font-size:12.5px; }
    .imp-tbl thead th {
        background:#f8fafc; color:#334155; text-align:left; padding:9px 11px;
        font-weight:700; white-space:nowrap; border-bottom:1px solid #e2e8f0;
        position:sticky; top:0; z-index:1;
    }
    .imp-tbl tbody td { padding:7px 11px; border-bottom:1px solid #f1f5f9; vertical-align:top }
    .imp-tbl tbody tr:last-child td { border-bottom:0 }
    .imp-tbl tbody tr:hover { background:#f8fafc; }
    .imp-tbl .num { text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap; }
    .imp-tbl tfoot td { font-weight:800; padding:9px 11px; border-top:2px solid #e2e8f0; background:#f8fafc; }
    .tbl-info { font-size:12px; color:#94a3b8; margin-top:8px; display:flex; align-items:center; gap:6px; }

    .stats { display:flex; gap:12px; flex-wrap:wrap; }
    .stat { flex:1; min-width:110px; padding:14px 16px; border-radius:12px; border:1px solid #e2e8f0; }
    .stat .sv { font-size:26px; font-weight:800; color:#0f172a }
    .stat .sl { font-size:11.5px; color:#64748b; margin-top:2px; text-transform:uppercase; letter-spacing:.3px }
    .s-ok  { background:#f0fdf4; border-color:#bbf7d0 } .s-ok  .sv { color:#16a34a; }
    .s-wrn { background:#fffbeb; border-color:#fde68a } .s-wrn .sv { color:#d97706; }
    .s-err { background:#fef2f2; border-color:#fecaca } .s-err .sv { color:#dc2626; }

    .equil { padding:11px 14px; border-radius:12px; margin:16px 0 12px; font-size:13.5px; font-weight:700; border:1px solid transparent; }
    .equil.ok { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .equil.ko { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .equil.ia { background:#f5f3ff; color:#5b21b6; border-color:#ddd6fe; font-weight:600; }

    .ia-hint { font-size:12px; color:#94a3b8; margin:14px 0 0; }
    .origine { font-size:12.5px; color:#64748b; margin:2px 0 12px; line-height:1.5; }

    .ctrl { border:1px solid #e2e8f0; border-radius:12px; padding:14px 16px; margin:14px 0; background:#fff; }
    .ctrl h3 { font-size:14px; font-weight:800; margin:0 0 4px; }
    .ctrl .ctx { font-size:12.5px; color:#64748b; margin:0 0 10px; line-height:1.5; }
    .ctrl .chips { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:10px; }
    .ctrl .chip { padding:4px 10px; border-radius:999px; font-size:12px; font-weight:700; }
    .ctrl .rien { padding:10px 12px; border-radius:10px; background:#f0fdf4; color:#166534; font-weight:700; font-size:13px; }

    .grv { display:inline-block; padding:1px 8px; border-radius:999px; font-size:11px; font-weight:800; white-space:nowrap; }
    .grv-err { background:#fef2f2; color:#b91c1c; }
    .grv-ver { background:#fffbeb; color:#b45309; }
    .grv-inf { background:#f1f5f9; color:#64748b; }
</style>
</asp:Content>

<asp:Content ID="mainContent" ContentPlaceHolderID="MainContent" runat="server">
<div class="imp-page">

    <div class="imp-head">
        <div class="ico">⚖️</div>
        <div>
            <h1>Importer la balance de vérification</h1>
            <div class="sub">Les soldes d'ouverture de la reprise comptable</div>
        </div>
    </div>

    <p class="imp-lede">
        Déposez la balance de vérification de votre ancien logiciel, <b>arrêtée à la date
        de bascule</b>. Elle est lue, contrôlée et mise en préparation. <b>Aucune écriture
        n'est passée dans vos livres à cette étape</b> : la balance reste en préparation, à
        côté du plan comptable, et sert d'abord à vérifier que les deux exports concordent.
        La création des soldes d'ouverture, elle, reste à faire.
    </p>

    <!-- ══════════ MESSAGES ══════════ -->
    <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="imp-alert imp-alert-ok">
        <span class="al-ico">✅</span><div class="al-body"><div class="al-title">C'est fait</div><asp:Literal ID="litSuccess" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="imp-alert imp-alert-err">
        <span class="al-ico">❌</span><div class="al-body"><div class="al-title">Erreur</div><asp:Literal ID="litError" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlWarning" runat="server" Visible="false" CssClass="imp-alert imp-alert-wrn">
        <span class="al-ico">⚠️</span><div class="al-body"><div class="al-title">Attention</div><asp:Literal ID="litWarning" runat="server" /></div>
    </asp:Panel>

    <!-- ══════════ CE QUI A ÉTÉ LU ══════════ -->
    <%-- En premier, comme sur les autres écrans d'importation : ce qui vient
         d'être lu se vérifie avant tout le reste. --%>
    <asp:Panel ID="pnlResults" runat="server" Visible="false" CssClass="imp-section">
        <h2><span class="n">✓</span><asp:Literal ID="litTitreResultat" runat="server" Text="Ce qui a été lu — à vérifier" /></h2>
        <div class="body">
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
                <h3 style="font-size:13px;font-weight:800;margin:18px 0 0;color:#334155">Détail des erreurs</h3>
                <div class="tbl-wrap"><asp:GridView ID="gvErrors" runat="server" CssClass="imp-tbl" AutoGenerateColumns="true" /></div>
            </asp:Panel>

            <%-- Les actions sont sous ce qu'elles commandent : on décide après avoir
                 regardé, pas dans un encadré à part au bas de la page. --%>
            <div class="imp-actions">
                <asp:Button ID="btnControle" runat="server" Text="🔍 Incohérences avec le plan comptable" CssClass="imp-btn imp-btn-primary" CausesValidation="false" />
                <asp:Button ID="btnReset" runat="server" Text="🔄 Nouvel import" CssClass="imp-btn imp-btn-secondary" />
                <asp:Button ID="btnTruncateTable" runat="server" Text="🗑 Supprimer la balance importée" CssClass="imp-btn imp-btn-danger"
                    OnClientClick="if (!confirm('Supprimer la balance importée de votre compagnie ?')) { return false; }" />
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ 1 · LE FICHIER ET SON ORIGINE ══════════ -->
    <%-- Une seule boîte : dire d'où vient le fichier et le déposer sont un seul
         geste. Repliable, et refermée une fois la balance importée — ce qui
         compte est alors le résultat, plus haut. --%>
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="trial-balance" />

    <asp:Panel ID="pnlUpload" runat="server">
        <details class="imp-section" id="detFichier" runat="server" open="open">
            <summary>
                <h2><span class="n">1</span>Le fichier à importer<span class="imp-chev">▾</span></h2>
            </summary>
            <p class="sec-desc">
                Dites d'où vient l'export, puis déposez-le. Un fichier CSV ou texte,
                une ligne par compte. 10 Mo au maximum.
            </p>
            <div class="body">

                <uc:SourceDonnees ID="ucSource" runat="server" Donnees="BALANCE" AvecEntete="false" />

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

                <div class="chk">
                    <asp:CheckBox ID="chkTruncate" runat="server" Checked="true" />
                    <label for="<%= chkTruncate.ClientID %>">Remplacer la balance déjà importée</label>
                </div>

                <div class="imp-actions">
                    <asp:Button ID="btnPreview" runat="server" Text="👁 Voir un aperçu" CssClass="imp-btn imp-btn-secondary" />
                    <asp:Button ID="btnIA" runat="server" Text="✨ Lire avec l'IA" CssClass="imp-btn imp-btn-ia" CausesValidation="false" OnClientClick="this.value='⏳ Lecture par l\'IA…';" />
                    <asp:Button ID="btnImport" runat="server" Text="📥 Importer" CssClass="imp-btn imp-btn-primary" />
                </div>

                <p class="ia-hint">
                    <b>Importer</b> reconnaît les colonnes par leur en-tête ; les lignes de titre,
                    la ligne <b>TOTAL</b> et le pied de page sont écartés d'eux-mêmes, et le total
                    annoncé sert à contrôler la lecture. Pour un fichier mal formé,
                    <b>Lire avec l'IA</b> confie la lecture à ChatGPT : chaque montant rendu est
                    retrouvé dans le fichier d'origine avant d'être accepté.
                </p>
            </div>
        </details>
    </asp:Panel>

    <!-- ══════════ APERÇU ══════════ -->
    <asp:Panel ID="pnlPreview" runat="server" Visible="false" CssClass="imp-section">
        <h2><span class="n">👁</span>Aperçu — ce que la lecture a compris</h2>
        <div class="body">
            <div class="tbl-wrap"><asp:GridView ID="gvPreview" runat="server" CssClass="imp-tbl" AutoGenerateColumns="true" ShowHeaderWhenEmpty="true" /></div>
            <div class="tbl-info">📋 <asp:Literal ID="litPreviewInfo" runat="server" /></div>
        </div>
    </asp:Panel>

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

</div>
</asp:Content>
