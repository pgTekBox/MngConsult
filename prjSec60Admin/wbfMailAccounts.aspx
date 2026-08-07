<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfMailAccounts.aspx.vb"
    Inherits="prjSec60Admin.wbfMailAccounts" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Comptes de courriel — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    <style>
        .listview-list-head, .listview-row {
            display: grid;
            grid-template-columns: 50px minmax(200px, 1fr) minmax(210px, 1.2fr) 130px 80px 210px;
            gap: 16px; align-items: center; box-sizing: border-box;
        }
        .listview-list-head {
            padding: 14px 16px; font-weight: 800; font-size: 13px; color: #0f172a;
            background: #f8fafc; border-bottom: 1px solid var(--mc-stroke);
        }
        .listview-row { padding: 14px 16px; border-bottom: 1px solid #eef2f7; background: #fff; }
        .co-avatar {
            width: 36px; height: 36px; border-radius: 10px;
            background: linear-gradient(135deg, #0ea5e9, #2563eb);
            color: #fff; display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 14px;
        }
        .co-name { font-weight: 700; }
        .co-meta { font-size: 12px; color: #64748b; }
        .mail-addr { font-weight: 700; color: #0f172a; font-family: ui-monospace, "Cascadia Code", Consolas, monospace; font-size: 13px; }
        .mail-none { color: #94a3b8; font-style: italic; }
        .badge {
            display: inline-flex; align-items: center; padding: 4px 10px;
            border-radius: 8px; font-size: 11px; font-weight: 800; white-space: nowrap;
        }
        .badge.active   { background: rgba(22,163,74,.10);  color: #16a34a; border: 1px solid rgba(22,163,74,.25); }
        .badge.inactive { background: rgba(217,119,6,.10);  color: #d97706; border: 1px solid rgba(217,119,6,.25); }
        .badge.none     { background: rgba(100,116,139,.10);color: #64748b; border: 1px solid rgba(100,116,139,.25); }
        .listview-actions { display: flex; gap: 8px; flex-wrap: wrap; }
        .pw-key { margin-left: 6px; font-size: 13px; }
        .btn-mini {
            display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px;
            border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer;
            border: 1px solid var(--mc-stroke); background: #fff; color: #0f172a; text-decoration: none;
        }
        .btn-mini:hover { background: #f8fafc; }
        .btn-mini.primary { background: #2563eb; border-color: #2563eb; color: #fff; }
        .btn-mini.primary:hover { background: #1d4ed8; }
        .btn-mini.warn { color: #b45309; border-color: rgba(217,119,6,.35); }
        .btn-mini.ok { color: #15803d; border-color: rgba(22,163,74,.35); }

        .section-title { font-weight: 800; font-size: 15px; margin: 26px 4px 10px; color: #0f172a; }
        .section-sub { font-size: 12px; color: #64748b; margin: 0 4px 12px; }

        /* table système */
        .sys-head, .sys-row {
            display: grid; grid-template-columns: minmax(220px,1fr) 160px 120px 140px;
            gap: 16px; align-items: center; padding: 12px 16px; box-sizing: border-box;
        }
        .sys-head { background: #f8fafc; font-weight: 800; font-size: 13px; border-bottom: 1px solid var(--mc-stroke); }
        .sys-row { background: #fff; border-bottom: 1px solid #eef2f7; }

        /* modale renommer */
        .rn-overlay {
            display: none; position: fixed; inset: 0; z-index: 1000;
            background: rgba(2,6,23,.45); align-items: center; justify-content: center;
        }
        .rn-overlay.open { display: flex; }
        .rn-card {
            width: 480px; max-width: calc(100vw - 32px); background: #fff;
            border-radius: 16px; box-shadow: 0 24px 60px rgba(2,6,23,.35); overflow: hidden;
        }
        .rn-wrap { padding: 20px 22px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
        .rn-lbl { font-size: 12px; font-weight: 800; color: #64748b; text-transform: uppercase; letter-spacing: .3px; }
        .rn-company { font-weight: 800; font-size: 16px; color: #0f172a; margin: 4px 0 18px; }
        .rn-row { display: flex; align-items: center; gap: 6px; }
        .rn-input {
            flex: 1; padding: 10px 12px; border: 1px solid var(--mc-stroke); border-radius: 10px;
            font-size: 14px; font-family: ui-monospace, Consolas, monospace;
        }
        .rn-domain { font-weight: 700; color: #475569; font-family: ui-monospace, Consolas, monospace; }
        .rn-msg { margin-top: 12px; font-size: 13px; font-weight: 700; min-height: 18px; }
        .rn-msg.err { color: #dc2626; }
        .rn-actions { margin-top: 22px; display: flex; justify-content: flex-end; gap: 10px; }

        @media (max-width: 1024px) {
            .listview-list-head, .listview-row { grid-template-columns: 40px 1fr 130px 190px; }
            .col-addr, .col-users { display: none; }
            .sys-head, .sys-row { grid-template-columns: 1fr 120px 140px; }
            .col-created { display: none; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Modale « Renommer l'adresse » (contrôles au niveau page) -->
    <div id="rnOverlay" class="rn-overlay">
        <div class="rn-card" role="dialog" aria-modal="true">
            <div class="rn-wrap">
                <div class="rn-lbl">Compagnie</div>
                <div class="rn-company"><asp:Literal ID="litRenameCompany" runat="server" ClientIDMode="Static" /></div>

                <div class="rn-lbl">Adresse @60sec.ca</div>
                <div class="rn-row" style="margin-top:6px;">
                    <asp:HiddenField ID="hfRenameGuid" runat="server" ClientIDMode="Static" />
                    <asp:TextBox ID="tbRenameLocal" runat="server" CssClass="rn-input" ClientIDMode="Static" />
                    <span class="rn-domain">@60sec.ca</span>
                </div>
                <asp:Label ID="lblRenameMsg" runat="server" CssClass="rn-msg" ClientIDMode="Static" />

                <div class="rn-actions">
                    <a href="#" class="btn-mini" onclick="closeRenameWin(); return false;">Annuler</a>
                    <asp:Button ID="btnSaveRename" runat="server" CssClass="btn-mini primary" Text="Enregistrer" />
                </div>
            </div>
        </div>
    </div>

    <!-- Modale « Mot de passe » (contrôles au niveau page) -->
    <div id="pwOverlay" class="rn-overlay">
        <div class="rn-card" role="dialog" aria-modal="true">
            <div class="rn-wrap">
                <div class="rn-lbl">Boîte de courriel</div>
                <div class="rn-company"><asp:Literal ID="litPwdAddr" runat="server" ClientIDMode="Static" /></div>

                <div class="rn-lbl">Mot de passe (IMAP / SMTP)</div>
                <div class="rn-row" style="margin-top:6px;">
                    <asp:HiddenField ID="hfPwdEmail" runat="server" ClientIDMode="Static" />
                    <asp:TextBox ID="tbPwd" runat="server" CssClass="rn-input" ClientIDMode="Static" autocomplete="new-password" />
                    <a href="#" class="btn-mini" onclick="genPwd(); return false;" title="Générer">Générer</a>
                </div>
                <div class="co-meta" style="margin-top:6px;">Ce mot de passe sert à connecter la boîte en IMAP et en SMTP.</div>
                <asp:Label ID="lblPwdMsg" runat="server" CssClass="rn-msg" ClientIDMode="Static" />

                <div class="rn-actions">
                    <asp:Button ID="btnRemovePwd" runat="server" CssClass="btn-mini warn" Text="Retirer" CausesValidation="false" />
                    <a href="#" class="btn-mini" onclick="closePwdModal(); return false;">Annuler</a>
                    <asp:Button ID="btnSavePwd" runat="server" CssClass="btn-mini primary" Text="Enregistrer" />
                </div>
            </div>
        </div>
    </div>

    <div class="page-head">
        <div class="page-head-left">
            <div class="page-title">Comptes de courriel</div>
        </div>
        <div class="searchbox">
            <div class="search-group">
                <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (compagnie, adresse)…" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                <asp:Button ID="btnClear" runat="server" CssClass="btn btn-icon btn-icon-clear" Text="" ToolTip="Effacer" CausesValidation="false" />
            </div>
        </div>
    </div>

    <!-- Comptes des compagnies -->
    <div class="full-grid">
        <div class="list-shell">
            <telerik:RadListView ID="rlvAccounts" runat="server" Skin="Metro" DataKeyNames="CompanyGUID"
                AllowPaging="false" ItemPlaceholderID="itemPlaceholder" ClientIDMode="Static">
                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="listview-list-head">
                            <div></div>
                            <div>Compagnie</div>
                            <div class="col-addr">Adresse @60sec.ca</div>
                            <div>État</div>
                            <div class="col-users">Logins</div>
                            <div>Actions</div>
                        </div>
                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <div class="listview-row">
                        <div><div class="co-avatar"><%# GetInitials(Eval("Name")) %></div></div>
                        <div>
                            <div class="co-name"><%# Eval("Name") %></div>
                            <div class="co-meta">Code : <%# IIf(Eval("CompanyCode") Is DBNull.Value OrElse Eval("CompanyCode").ToString()="", "—", Eval("CompanyCode")) %></div>
                        </div>
                        <div class="col-addr">
                            <span class='<%# IIf(CBool(Eval("HasMailbox")), "mail-addr", "mail-addr mail-none") %>'>
                                <%# IIf(CBool(Eval("HasMailbox")), Eval("Sec60Email"), "aucune") %>
                            </span>
                        </div>
                        <div>
                            <span class='<%# "badge " & StateClass(Eval("HasMailbox"), Eval("IsActive")) %>'><%# StateLabel(Eval("HasMailbox"), Eval("IsActive")) %></span>
                            <%# IIf(CBool(Eval("HasPassword")), "<span class=""pw-key"" title=""Mot de passe défini"">🔑</span>", "") %>
                        </div>
                        <div class="col-users co-meta"><%# Eval("UserCount") %></div>
                        <div class="listview-actions">
                            <asp:Button ID="btnAssign" runat="server" CssClass="btn-mini primary" Text="Attribuer"
                                CommandName="assign" CommandArgument='<%# Eval("CompanyGUID") %>'
                                Visible='<%# Not CBool(Eval("HasMailbox")) %>' CausesValidation="false" />

                            <asp:Button ID="btnRename" runat="server" CssClass="btn-mini" Text="Renommer"
                                Visible='<%# CBool(Eval("HasMailbox")) %>' CausesValidation="false"
                                OnClientClick='<%# "openRename(&#39;" & Eval("CompanyGUID").ToString() & "&#39;,&#39;" & JsEsc(Eval("Name")) & "&#39;,&#39;" & JsEsc(Eval("Sec60Email")) & "&#39;); return false;" %>' />

                            <asp:Button ID="btnPwd" runat="server" CssClass="btn-mini" Text="Mot de passe"
                                Visible='<%# CBool(Eval("HasMailbox")) %>' CausesValidation="false"
                                OnClientClick='<%# "openPwd(&#39;" & JsEsc(Eval("Sec60Email")) & "&#39;); return false;" %>' />

                            <asp:Button ID="btnDeact" runat="server" CssClass="btn-mini warn" Text="Désactiver"
                                CommandName="deactivate" CommandArgument='<%# Eval("Sec60Email") %>'
                                Visible='<%# CBool(Eval("HasMailbox")) AndAlso CBool(Eval("IsActive")) %>' CausesValidation="false" />

                            <asp:Button ID="btnAct" runat="server" CssClass="btn-mini ok" Text="Activer"
                                CommandName="activate" CommandArgument='<%# Eval("Sec60Email") %>'
                                Visible='<%# CBool(Eval("HasMailbox")) AndAlso Not CBool(Eval("IsActive")) %>' CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>
                <EmptyDataTemplate><div class="listview-empty">Aucune compagnie trouvée.</div></EmptyDataTemplate>
            </telerik:RadListView>
        </div>
    </div>

    <!-- Adresses système -->
    <div class="section-title">Adresses système</div>
    <div class="section-sub">Boîtes locales non rattachées à une compagnie (réception, scan, factures…).</div>
    <div class="full-grid">
        <div class="list-shell">
            <telerik:RadListView ID="rlvSystem" runat="server" Skin="Metro" DataKeyNames="Id"
                AllowPaging="false" ItemPlaceholderID="sysPlaceholder">
                <LayoutTemplate>
                    <div class="listview-list">
                        <div class="sys-head">
                            <div>Adresse</div>
                            <div class="col-created">Créée le</div>
                            <div>État</div>
                            <div>Actions</div>
                        </div>
                        <div class="listview-list-body">
                            <asp:PlaceHolder ID="sysPlaceholder" runat="server"></asp:PlaceHolder>
                        </div>
                    </div>
                </LayoutTemplate>
                <ItemTemplate>
                    <div class="sys-row">
                        <div class="mail-addr"><%# Eval("Email") %></div>
                        <div class="col-created co-meta"><%# FormatDate(Eval("CreatedAtUtc")) %></div>
                        <div>
                            <span class='<%# "badge " & IIf(CBool(Eval("IsActive")), "active", "inactive") %>'><%# IIf(CBool(Eval("IsActive")), "Actif", "Inactif") %></span>
                            <%# IIf(CBool(Eval("HasPassword")), "<span class=""pw-key"" title=""Mot de passe défini"">🔑</span>", "") %>
                        </div>
                        <div class="listview-actions">
                            <asp:Button ID="btnSysPwd" runat="server" CssClass="btn-mini" Text="Mot de passe" CausesValidation="false"
                                OnClientClick='<%# "openPwd(&#39;" & JsEsc(Eval("Email")) & "&#39;); return false;" %>' />
                            <asp:Button ID="btnSysDeact" runat="server" CssClass="btn-mini warn" Text="Désactiver"
                                CommandName="deactivate" CommandArgument='<%# Eval("Email") %>'
                                Visible='<%# CBool(Eval("IsActive")) %>' CausesValidation="false" />
                            <asp:Button ID="btnSysAct" runat="server" CssClass="btn-mini ok" Text="Activer"
                                CommandName="activate" CommandArgument='<%# Eval("Email") %>'
                                Visible='<%# Not CBool(Eval("IsActive")) %>' CausesValidation="false" />
                        </div>
                    </div>
                </ItemTemplate>
                <EmptyDataTemplate><div class="listview-empty">Aucune adresse système.</div></EmptyDataTemplate>
            </telerik:RadListView>
        </div>
    </div>

    <script type="text/javascript">
        function openRename(guid, name, email) {
            var local = (email || "").split("@")[0];
            var gh = document.getElementById('hfRenameGuid');
            var tb = document.getElementById('tbRenameLocal');
            var lc = document.getElementById('litRenameCompany');
            var msg = document.getElementById('lblRenameMsg');
            if (gh) gh.value = guid;
            if (tb) tb.value = local;
            if (lc) lc.innerHTML = name;
            if (msg) { msg.innerHTML = ''; msg.className = 'rn-msg'; }
            openRnModal();
            if (tb) { tb.focus(); tb.select(); }
            return false;
        }
        function openRnModal() {
            var ov = document.getElementById('rnOverlay');
            if (ov) ov.classList.add('open');
        }
        function closeRenameWin() {
            var ov = document.getElementById('rnOverlay');
            if (ov) ov.classList.remove('open');
            return false;
        }

        function openPwd(email) {
            var he = document.getElementById('hfPwdEmail');
            var la = document.getElementById('litPwdAddr');
            var tb = document.getElementById('tbPwd');
            var msg = document.getElementById('lblPwdMsg');
            if (he) he.value = email;
            if (la) la.innerHTML = email;
            if (tb) tb.value = '';
            if (msg) { msg.innerHTML = ''; msg.className = 'rn-msg'; }
            var ov = document.getElementById('pwOverlay');
            if (ov) ov.classList.add('open');
            if (tb) tb.focus();
            return false;
        }
        function openPwdModal() {
            var ov = document.getElementById('pwOverlay');
            if (ov) ov.classList.add('open');
        }
        function closePwdModal() {
            var ov = document.getElementById('pwOverlay');
            if (ov) ov.classList.remove('open');
            return false;
        }
        function genPwd() {
            var chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
            var out = '';
            var a = new Uint32Array(14);
            (window.crypto || window.msCrypto).getRandomValues(a);
            for (var i = 0; i < a.length; i++) out += chars[a[i] % chars.length];
            var tb = document.getElementById('tbPwd');
            if (tb) { tb.value = out; tb.focus(); tb.select(); }
            return false;
        }

        // Fermer sur clic hors carte / touche Échap
        (function () {
            ['rnOverlay', 'pwOverlay'].forEach(function (id) {
                var ov = document.getElementById(id);
                if (ov) ov.addEventListener('click', function (e) { if (e.target === ov) ov.classList.remove('open'); });
            });
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') { closeRenameWin(); closePwdModal(); }
            });
        })();
    </script>
</asp:Content>
