<%@ Page Language="vb" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="wbfNewUser.aspx.vb" Inherits="MngConsul.wbfNewUser" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server"><%= L("pageTitle") %></asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .nu {
            --slate-50:#f8fafc; --slate-100:#f1f5f9; --slate-200:#e2e8f0; --slate-300:#cbd5e1;
            --slate-400:#94a3b8; --slate-500:#64748b; --slate-600:#475569; --slate-700:#334155; --slate-800:#1e293b;
            --blue-50:#eff6ff; --blue-100:#dbeafe; --blue-200:#bfdbfe; --blue-500:#3b82f6; --blue-600:#2563eb; --blue-700:#1d4ed8;
            --cyan-500:#06b6d4; --green-500:#10b981; --green-600:#059669; --red-500:#ef4444; --red-600:#dc2626;
            padding: 20px;
            color: var(--slate-800);
        }

        .nu .page-title h2 { font-size:24px; font-weight:800; margin:0 0 6px 0; }
        .nu .page-title p { color:var(--slate-600); margin:0 0 20px 0; font-size:14px; }

        .nu .progress-wrap { background:#fff; border:1px solid var(--slate-200); border-radius:14px; padding:16px 18px; margin-bottom:18px; box-shadow:0 6px 16px rgba(15,23,42,.05); }
        .nu .progress-head { display:flex; justify-content:space-between; align-items:center; margin-bottom:10px; }
        .nu .progress-head .lbl { font-size:13px; font-weight:800; color:var(--slate-700); }
        .nu .progress-head .pct { font-size:14px; font-weight:900; color:var(--blue-600); }
        .nu .progress-track { height:10px; background:var(--slate-200); border-radius:999px; overflow:hidden; }
        .nu .progress-fill { height:100%; width:0%; background:linear-gradient(90deg, var(--blue-500), var(--cyan-500)); border-radius:999px; transition:width .35s ease; }

        .nu .card { background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:0 8px 20px rgba(15,23,42,.05); margin-bottom:18px; }
        .nu .card-body { padding:24px; }

        .nu .section-label { font-size:11px; font-weight:800; color:var(--slate-400); text-transform:uppercase; letter-spacing:.1em; margin-bottom:14px; }
        .nu .card-title { font-size:18px; font-weight:800; color:var(--slate-800); margin:0 0 4px 0; }
        .nu .card-sub { font-size:13px; color:var(--slate-500); margin:0 0 16px 0; line-height:1.5; }

        .nu .form-grid { display:grid; grid-template-columns:1fr 1fr; gap:18px; }
        .nu .form-grid .full { grid-column:1 / -1; }
        @media (max-width:768px){ .nu .form-grid { grid-template-columns:1fr; } }

        .nu .field label { display:block; font-size:13px; font-weight:700; color:var(--slate-700); margin-bottom:7px; }
        .nu .field .locked { font-size:11px; font-weight:700; color:var(--slate-400); margin-left:6px; }
        .nu .field input[type="text"], .nu .field input[type="tel"], .nu .field input[type="email"], .nu .field input[type="date"] {
            width:100%; padding:12px 14px; border:2px solid var(--slate-200); border-radius:8px;
            font-size:14px; color:var(--slate-800); background:#fff; outline:none; transition:border-color .15s, box-shadow .15s;
        }
        .nu .field input:focus { border-color:var(--blue-500); box-shadow:0 0 0 3px rgba(59,130,246,.18); }
        .nu .field input[readonly] { background:var(--slate-50); color:var(--slate-500); cursor:not-allowed; }

        .nu .upload-card { border:2px dashed var(--blue-200); background:var(--blue-50); }
        .nu .upload-row { display:flex; flex-wrap:wrap; align-items:center; gap:12px; margin-top:12px; }
        .nu .upload-row input[type="file"] { font-size:13px; color:var(--slate-600); }

        .nu .dropzone { position:relative; margin-top:10px; border:2px dashed var(--blue-200); border-radius:12px;
            background:#fff; padding:22px 18px; text-align:center; cursor:pointer; transition:border-color .15s, background .15s; }
        .nu .dropzone:hover { border-color:var(--blue-500); background:var(--blue-50); }
        .nu .dropzone.drag { border-color:var(--blue-600); background:rgba(59,130,246,.10); }
        .nu .dropzone .dz-ico { font-size:26px; line-height:1; }
        .nu .dropzone .dz-text { font-size:13px; color:var(--slate-600); font-weight:600; margin-top:6px; }
        .nu .dropzone .dz-file { font-size:13px; color:var(--blue-600); font-weight:700; margin-top:6px; min-height:16px; word-break:break-all; }
        .nu .dropzone .dz-input { position:absolute; width:1px; height:1px; opacity:0; overflow:hidden; }
        .nu .upload-msg { margin-top:14px; padding:11px 14px; border-radius:10px; font-size:13px; font-weight:600; }
        .nu .upload-msg.ok { background:rgba(16,185,129,.08); border:1px solid rgba(16,185,129,.25); color:var(--green-600); }
        .nu .upload-msg.err { background:rgba(239,68,68,.08); border:1px solid rgba(239,68,68,.25); color:var(--red-600); }

        .nu .form-actions { display:flex; justify-content:flex-end; gap:12px; padding-top:20px; margin-top:8px; }

        .nu .btn { padding:11px 22px; border-radius:8px; font-weight:700; font-size:14px; border:none; cursor:pointer; transition:all .15s; }
        .nu .btn-secondary { background:var(--slate-100); color:var(--slate-700); }
        .nu .btn-secondary:hover { background:var(--slate-200); }
        .nu .btn-primary { background:linear-gradient(90deg, var(--blue-500), var(--blue-600)); color:#fff; }
        .nu .btn-primary:hover { box-shadow:0 8px 16px rgba(37,99,235,.3); transform:translateY(-1px); }

        .nu .msg-banner { padding:12px 16px; border-radius:12px; font-size:13px; font-weight:600; margin-bottom:14px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="nu">

        <asp:HiddenField ID="hfPlan" runat="server" />

        <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="msg-banner">
            <asp:Literal ID="litMessage" runat="server" />
        </asp:Panel>

        <div class="page-title">
            <h2><%= L("h2") %></h2>
            <p><%= L("subtitle") %></p>
        </div>

        <!-- Progression -->
        <div class="progress-wrap">
            <div class="progress-head">
                <span class="lbl"><%= L("progress") %></span>
                <span class="pct" id="progPct">0&nbsp;%</span>
            </div>
            <div class="progress-track"><div class="progress-fill" id="progFill"></div></div>
        </div>

        <!-- Remplissage automatique -->
        <div class="card upload-card">
            <div class="card-body">
                <p class="section-label"><%= L("autoFill") %></p>
                <h3 class="card-title"><%= L("uploadTitle") %></h3>
                <p class="card-sub"><%= L("uploadSub") %></p>
                <div id="dropZone" class="dropzone">
                    <div class="dz-ico" aria-hidden="true">⬆️</div>
                    <div class="dz-text"><%= L("dropZone") %></div>
                    <div class="dz-file" id="dzFile"></div>
                    <asp:FileUpload ID="fileDoc" runat="server" ClientIDMode="Static"
                        accept=".pdf,.png,.jpg,.jpeg,image/*,application/pdf" CssClass="dz-input" />
                </div>
                <div class="upload-row">
                    <asp:Button ID="btnExtract" runat="server" Text="Analyser le document"
                        CssClass="btn btn-primary" CausesValidation="false" />
                </div>
                <asp:Panel ID="pnlUpload" runat="server" Visible="false" CssClass="upload-msg">
                    <asp:Literal ID="litUpload" runat="server" />
                </asp:Panel>
            </div>
        </div>

        <!-- Identité -->
        <div class="card">
            <div class="card-body">
                <p class="section-label"><%= L("identity") %></p>
                <div class="form-grid">
                    <div class="field">
                        <label><%= L("firstName") %></label>
                        <asp:TextBox ID="txtFirstName" runat="server" CssClass="track" placeholder="Ex : Jean" />
                    </div>
                    <div class="field">
                        <label><%= L("lastName") %></label>
                        <asp:TextBox ID="txtLastName" runat="server" CssClass="track" placeholder="Ex : Tremblay" />
                    </div>
                    <div class="field">
                        <label><%= L("email") %> <span class="locked"><%= L("locked") %></span></label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="track" ReadOnly="true" TextMode="Email" />
                    </div>
                    <div class="field">
                        <label><%= L("phone") %></label>
                        <asp:TextBox ID="txtPhone" runat="server" CssClass="track" TextMode="Phone" placeholder="(514) 555-1234" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Entreprise -->
        <div class="card">
            <div class="card-body">
                <p class="section-label"><%= L("company") %></p>
                <div class="form-grid">
                    <div class="field">
                        <label><%= L("neq") %></label>
                        <asp:TextBox ID="txtNeq" runat="server" CssClass="track" placeholder="1234567890" />
                    </div>
                    <div class="field">
                        <label><%= L("legalName") %></label>
                        <asp:TextBox ID="txtLegalName" runat="server" CssClass="track" placeholder="Inc. / Ltée / …" />
                    </div>
                    <div class="field">
                        <label><%= L("incorpDate") %></label>
                        <asp:TextBox ID="txtIncorpDate" runat="server" CssClass="track" TextMode="Date" />
                    </div>
                    <div class="field">
                        <label><%= L("bn") %></label>
                        <asp:TextBox ID="txtBusinessNumber" runat="server" CssClass="track" placeholder="123456789" />
                    </div>
                    <div class="field">
                        <label><%= L("fiscalYearEnd") %></label>
                        <asp:TextBox ID="txtFiscalYearEnd" runat="server" CssClass="track" TextMode="Date" />
                    </div>
                    <div class="field">
                        <label><%= L("tps") %></label>
                        <asp:TextBox ID="txtTps" runat="server" CssClass="track" placeholder="123456789 RT0001" />
                    </div>
                    <div class="field">
                        <label><%= L("tvq") %></label>
                        <asp:TextBox ID="txtTvq" runat="server" CssClass="track" placeholder="1234567890 TQ0001" />
                    </div>
                    <div class="field">
                        <label><%= L("tvh") %></label>
                        <asp:TextBox ID="txtTvh" runat="server" CssClass="track" placeholder="123456789 RT0001" />
                    </div>
                </div>

                <div class="form-actions">
                    <asp:Button ID="btnRestart" runat="server" Text="Recommencer"
                        CssClass="btn btn-secondary" CausesValidation="false" />
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer et continuer →"
                        CssClass="btn btn-primary" />
                </div>
            </div>
        </div>

        <script type="text/javascript">
            (function () {
                function updateProgress() {
                    var fields = document.querySelectorAll('.track');
                    if (!fields.length) return;
                    var filled = 0;
                    fields.forEach(function (f) { if ((f.value || '').trim() !== '') filled++; });
                    var pct = Math.round((filled / fields.length) * 100);
                    var fill = document.getElementById('progFill');
                    var lbl = document.getElementById('progPct');
                    if (fill) fill.style.width = pct + '%';
                    if (lbl) lbl.innerHTML = pct + '&nbsp;%';
                }
                document.addEventListener('input', function (e) {
                    if (e.target && e.target.classList && e.target.classList.contains('track')) updateProgress();
                });
                document.addEventListener('DOMContentLoaded', updateProgress);
                window.addEventListener('load', updateProgress);
            })();

            // Glisser-déposer d'un document dans la zone de remplissage automatique.
            // Le fichier déposé est injecté dans le <input type=file> (via DataTransfer),
            // le postback « Analyser » fonctionne alors comme avec une sélection classique.
            (function () {
                function initDrop() {
                    var dz = document.getElementById('dropZone'),
                        inp = document.getElementById('fileDoc'),
                        lbl = document.getElementById('dzFile');
                    if (!dz || !inp) return;
                    function showName() { lbl.textContent = (inp.files && inp.files.length) ? inp.files[0].name : ''; }
                    dz.addEventListener('click', function () { inp.click(); });
                    inp.addEventListener('change', showName);
                    ['dragenter', 'dragover'].forEach(function (t) {
                        dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.add('drag'); });
                    });
                    ['dragleave', 'dragend', 'drop'].forEach(function (t) {
                        dz.addEventListener(t, function (e) { e.preventDefault(); e.stopPropagation(); dz.classList.remove('drag'); });
                    });
                    dz.addEventListener('drop', function (e) {
                        var files = e.dataTransfer && e.dataTransfer.files;
                        if (!files || !files.length) return;
                        try { var dt = new DataTransfer(); dt.items.add(files[0]); inp.files = dt.files; } catch (ex) { }
                        showName();
                    });
                }
                if (document.readyState !== 'loading') initDrop();
                else document.addEventListener('DOMContentLoaded', initDrop);
            })();
        </script>

    </div>
</asp:Content>
