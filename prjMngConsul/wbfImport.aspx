<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    Async="true" CodeBehind="wbfImport.aspx.vb" Inherits="MngConsul.wbfImport" %>

<asp:Content ID="titleContent" ContentPlaceHolderID="TitleContent" runat="server">
    Import — Clients / Fournisseurs / Produits
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

    .up-section { padding:20px; border-bottom:1px solid var(--mc-stroke); }
    .up-section:last-child { border-bottom:none; }
    .up-section h2 { font-size:15px; font-weight:800; margin:0 0 4px; }
    .up-section .sec-desc { font-size:13px; color:var(--mc-muted); margin-bottom:16px; }

    .type-row { margin-bottom:18px; }
    .type-row label { display:block; font-size:13px; font-weight:700; margin-bottom:6px; }
    .type-row select {
        width:100%; max-width:340px; padding:10px 12px; border:1px solid var(--mc-stroke);
        border-radius:10px; font-size:14px; font-family:inherit; background:#fff;
        color:var(--mc-text); outline:none; cursor:pointer;
    }
    .type-row select:focus { border-color:var(--mc-blue); box-shadow:0 0 0 3px rgba(37,99,235,.12); }
    .type-row .hint { font-size:12px; color:var(--mc-muted); margin-top:4px; }

    .upload-zone {
        border:2px dashed var(--mc-stroke); border-radius:14px;
        padding:40px 20px; text-align:center; transition:border-color .2s, background .2s; cursor:pointer;
    }
    .upload-zone:hover, .upload-zone.dragover { border-color:var(--mc-blue); background:rgba(37,99,235,.05); }
    .upload-zone .uz-ico { font-size:40px; margin-bottom:10px; }
    .upload-zone p { font-size:14px; color:var(--mc-muted); margin:0; }
    .upload-zone .uz-hint { font-size:12px; color:var(--mc-muted); margin-top:6px; opacity:.65; }

    .file-pill {
        display:flex; align-items:center; gap:12px; padding:12px 14px; margin-top:12px;
        background:linear-gradient(135deg, rgba(37,99,235,.07), rgba(6,182,212,.05));
        border:1px solid var(--mc-stroke); border-radius:12px;
    }
    .file-pill .fp-ico { font-size:26px; }
    .file-pill .fp-name { font-weight:700; font-size:14px; }
    .file-pill .fp-size { font-size:12px; color:var(--mc-muted); }
    .file-pill .fp-rm { margin-left:auto; color:#ef4444; cursor:pointer; font-size:16px; background:none; border:none; }

    .formats { display:flex; gap:10px; flex-wrap:wrap; margin-top:14px; }
    .fmt-tag {
        font-size:12px; padding:6px 12px; border-radius:999px;
        background:rgba(37,99,235,.08); color:var(--mc-blue); font-weight:700;
        border:1px solid rgba(37,99,235,.15);
    }

    .up-actions { display:flex; gap:10px; margin-top:18px; justify-content:flex-end; flex-wrap:wrap; }
    .up-btn {
        padding:10px 20px; border-radius:10px; font-size:14px; font-weight:700;
        font-family:inherit; cursor:pointer; border:none; display:inline-flex; align-items:center; gap:7px; transition:all .15s;
    }
    .up-btn-primary { background:var(--mc-blue); color:#fff; }
    .up-btn-primary:hover { filter:brightness(.92); }
    .up-btn-secondary { background:#fff; color:var(--mc-text); border:1px solid var(--mc-stroke); }
    .up-btn-secondary:hover { background:var(--mc-bg); }
    .up-btn-danger { background:#fff; color:#b91c1c; border:1px solid #fecaca; }
    .up-btn-danger:hover { background:#fef2f2; border-color:#fca5a5; }

    .up-alert {
        padding:12px 16px; border-radius:12px; font-size:13px; margin:16px 20px 0;
        display:flex; align-items:flex-start; gap:10px; border:1px solid transparent;
    }
    .up-alert-ok  { background:#f0fdf4; color:#166534; border-color:#bbf7d0; }
    .up-alert-err { background:#fef2f2; color:#991b1b; border-color:#fecaca; }
    .up-alert .al-ico { font-size:17px; flex-shrink:0; }
    .up-alert .al-body { flex:1; }
    .up-alert .al-title { font-weight:700; margin-bottom:2px; }
    .up-alert code { background:rgba(0,0,0,.05); padding:1px 6px; border-radius:4px; font-size:12px; }

    .tbl-wrap { overflow-x:auto; border:1px solid var(--mc-stroke); border-radius:12px; }
    .imp-tbl { width:100%; border-collapse:collapse; font-size:13px; }
    .imp-tbl thead th {
        background:var(--mc-blue); color:#fff; padding:10px 14px;
        text-align:left; font-weight:700; font-size:12px; text-transform:uppercase; letter-spacing:.3px;
    }
    .imp-tbl tbody td { padding:8px 14px; border-bottom:1px solid rgba(0,0,0,.05); }
    .imp-tbl tbody tr:nth-child(even) { background:rgba(37,99,235,.025); }
    .imp-tbl tbody tr:hover { background:rgba(37,99,235,.06); }
</style>
</asp:Content>

<asp:Content ID="mainContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="toolbar">
        <div class="pg-header">
            <div class="pg-ico">📥</div>
            <div>
                <h1>Import — Clients / Fournisseurs / Produits</h1>
                <div class="pg-sub">Téléversez un fichier — il sera déposé dans <code>staging.ImportFiles</code></div>
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="up-alert up-alert-ok">
        <span class="al-ico">✅</span>
        <div class="al-body">
            <div class="al-title">Fichier reçu</div>
            <asp:Literal ID="litSuccess" runat="server" />
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="up-alert up-alert-err">
        <span class="al-ico">❌</span>
        <div class="al-body">
            <div class="al-title">Erreur</div>
            <asp:Literal ID="litError" runat="server" />
        </div>
    </asp:Panel>

    <div class="up-section">
        <h2>1 — Type d'import</h2>
        <p class="sec-desc">Sélectionnez le type de données contenues dans le fichier.</p>

        <div class="type-row">
            <label for="<%= ddlTypeImport.ClientID %>">Type</label>
            <asp:DropDownList ID="ddlTypeImport" runat="server">
                <asp:ListItem Value="" Text="-- Choisir --" Selected="True" />
                <asp:ListItem Value="Client"      Text="👤 Liste de clients" />
                <asp:ListItem Value="Fournisseur" Text="🏢 Liste de fournisseurs" />
                <asp:ListItem Value="Produit"     Text="📦 Liste de produits" />
            </asp:DropDownList>
            <div class="hint">Le fichier sera étiqueté de ce type dans <code>staging.ImportFiles.TypeImport</code>.</div>
        </div>
    </div>

    <div class="up-section">
        <h2>2 — Fichier</h2>
        <p class="sec-desc">Glissez-déposez le fichier ou cliquez pour parcourir.</p>

        <div class="upload-zone" id="dropZone" onclick="document.getElementById('<%= fuImportFile.ClientID %>').click();">
            <div class="uz-ico">📁</div>
            <p><strong>Glissez votre fichier ici</strong> ou cliquez pour parcourir</p>
            <p class="uz-hint">Formats acceptés : .csv, .xlsx, .txt &nbsp;|&nbsp; Taille max : 50 Mo</p>
        </div>

        <asp:FileUpload ID="fuImportFile" runat="server" style="display:none;"
            onchange="showFileInfo(this);" accept=".csv,.xlsx,.txt" />

        <div id="fileInfoDiv" style="display:none;">
            <div class="file-pill">
                <span class="fp-ico" id="fileIcon">📄</span>
                <div>
                    <div class="fp-name" id="fileName"></div>
                    <div class="fp-size" id="fileSize"></div>
                </div>
                <button type="button" class="fp-rm" onclick="clearFile();" title="Retirer">✕</button>
            </div>
        </div>

        <div class="formats">
            <span class="fmt-tag">CSV</span>
            <span class="fmt-tag">Excel (.xlsx)</span>
            <span class="fmt-tag">TXT délimité</span>
        </div>

        <div class="up-actions">
            <asp:Button ID="btnUpload" runat="server" Text="📤 Téléverser dans staging" CssClass="up-btn up-btn-primary" />
            <asp:Button ID="btnReset"  runat="server" Text="🔄 Réinitialiser" CssClass="up-btn up-btn-secondary" CausesValidation="false" />
        </div>
    </div>

    <asp:Panel ID="pnlRecent" runat="server" Visible="false">
        <div class="up-section">
            <h2>Derniers fichiers importés</h2>
            <p class="sec-desc">10 derniers enregistrements dans <code>staging.ImportFiles</code>.</p>
            <div class="tbl-wrap">
                <asp:GridView ID="gvRecent" runat="server" CssClass="imp-tbl" AutoGenerateColumns="false">
                    <Columns>
                        <asp:BoundField DataField="Id"             HeaderText="#" />
                        <asp:BoundField DataField="TypeImport"     HeaderText="Type" />
                        <asp:BoundField DataField="OriginalName"   HeaderText="Fichier" />
                        <asp:BoundField DataField="FileExtension"  HeaderText="Format" />
                        <asp:BoundField DataField="FileSize"       HeaderText="Taille (o)"   DataFormatString="{0:N0}" />
                        <asp:BoundField DataField="UploadDate"     HeaderText="Date"         DataFormatString="{0:yyyy-MM-dd HH:mm}" />
                        <asp:BoundField DataField="Status"         HeaderText="Statut" />
                        <asp:BoundField DataField="InputTokens"    HeaderText="Tok. in"      DataFormatString="{0:N0}" />
                        <asp:BoundField DataField="OutputTokens"   HeaderText="Tok. out"     DataFormatString="{0:N0}" />
                        <asp:BoundField DataField="EstimatedCostUsd" HeaderText="Coût (USD)" DataFormatString="{0:0.0000}" />
                        <asp:TemplateField HeaderText="Action">
                            <ItemTemplate>
                                <asp:Button runat="server" Text="🤖 Traiter"
                                            CssClass="up-btn up-btn-secondary"
                                            CommandName="ProcessAI"
                                            CommandArgument='<%# Eval("Id") %>'

                                            CausesValidation="false" />
                                <asp:LinkButton runat="server" Text="👁 Voir"
                                                CssClass="up-btn up-btn-secondary"
                                                OnClientClick='<%# String.Format("openRadWindow({0}, ""rwImportView"", ""wbfImportView.aspx"", ""Détails import #{0}"", ""Détails import""); return false;", Eval("Id")) %>'
                                                Visible='<%# Not (Eval("InputTokens") Is DBNull.Value) %>'
                                                CausesValidation="false" />
                                <asp:Button runat="server" Text="🗑 Supprimer"
                                            CssClass="up-btn up-btn-danger"
                                            CommandName="DeleteImport"
                                            CommandArgument='<%# Eval("Id") %>'
                                            OnClientClick='<%# String.Format("return confirm(""Supprimer définitivement le fichier #{0} ({1}) et toutes les lignes staging associées ?"");", Eval("Id"), System.Web.HttpUtility.JavaScriptStringEncode(Convert.ToString(Eval("OriginalName")))) %>'
                                            CausesValidation="false" />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </asp:Panel>

    <telerik:RadWindowManager ID="rwmImport" runat="server" EnableShadow="true"></telerik:RadWindowManager>

    <telerik:RadWindow ID="rwImportView" runat="server"
                       Modal="true"
                       VisibleOnPageLoad="false"
                       Behaviors="Close,Move,Resize,Maximize"
                       Title="Visualisation staging"
                       ClientIDMode="Static">
    </telerik:RadWindow>

    <script src="js/RadWindows.js"></script>

    <script>
        (function () {
            var dz = document.getElementById('dropZone');
            if (!dz) return;
            ['dragenter', 'dragover'].forEach(function (e) {
                dz.addEventListener(e, function (ev) { ev.preventDefault(); dz.classList.add('dragover'); });
            });
            ['dragleave', 'drop'].forEach(function (e) {
                dz.addEventListener(e, function (ev) { ev.preventDefault(); dz.classList.remove('dragover'); });
            });
            dz.addEventListener('drop', function (e) {
                var fi = document.getElementById('<%= fuImportFile.ClientID %>');
                if (e.dataTransfer.files.length > 0) {
                    fi.files = e.dataTransfer.files;
                    showFileInfo(fi);
                }
            });
        })();

        function showFileInfo(input) {
            if (input.files && input.files.length > 0) {
                var f = input.files[0];
                document.getElementById('fileName').textContent = f.name;
                document.getElementById('fileSize').textContent =
                    f.size > 1048576
                        ? (f.size / 1048576).toFixed(2) + ' Mo'
                        : (f.size / 1024).toFixed(1) + ' Ko';
                var ext = (f.name.split('.').pop() || '').toLowerCase();
                document.getElementById('fileIcon').textContent = (ext === 'xlsx') ? '📊' : '📄';
                document.getElementById('fileInfoDiv').style.display = 'block';
                document.getElementById('dropZone').style.display = 'none';
            }
        }

        function clearFile() {
            document.getElementById('<%= fuImportFile.ClientID %>').value = '';
            document.getElementById('fileInfoDiv').style.display = 'none';
            document.getElementById('dropZone').style.display = 'block';
        }
    </script>
</asp:Content>
