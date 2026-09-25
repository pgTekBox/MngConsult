<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" Async="true"
    CodeBehind="wbfAssistant.aspx.vb" Inherits="MngConsul.wbfAssistant" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("titre") %> — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .iap-grille { display: grid; grid-template-columns: minmax(0, 1fr) 380px; gap: 16px; align-items: start; padding: 16px; }
        @media (max-width: 1000px) { .iap-grille { grid-template-columns: 1fr; } }
        .iap-carte { background: #fff; border: 1px solid var(--mc-stroke); border-radius: 14px; padding: 16px; margin-bottom: 14px; }
        .iap-carte h2 { font-size: 16px; margin: 0 0 8px; }
        .iap-fil { max-height: 60vh; overflow: auto; padding: 4px 2px; }
        .iap-tour { margin: 0 0 12px; display: flex; gap: 10px; }
        .iap-tour.user { justify-content: flex-end; }
        .iap-bulle { max-width: 82%; padding: 10px 14px; border-radius: 12px; line-height: 1.55; font-size: 14px; white-space: pre-wrap; }
        .iap-tour.user .iap-bulle { background: var(--mc-blue); color: #fff; border-bottom-right-radius: 4px; }
        .iap-tour.assistant .iap-bulle { background: #f8fafc; border: 1px solid var(--mc-stroke); border-bottom-left-radius: 4px; }
        .iap-quand { font-size: 11px; color: var(--mc-muted); margin-top: 4px; }
        .iap-saisie textarea { width: 100%; min-height: 72px; box-sizing: border-box; border: 1px solid var(--mc-stroke); border-radius: 10px; padding: 10px; font: inherit; }
        .iap-actions { display: flex; gap: 8px; align-items: center; margin-top: 8px; flex-wrap: wrap; }
        .iap-vide { color: var(--mc-muted); font-size: 14px; padding: 12px 4px; }
        .iap-exemples button { background: #fff; border: 1px solid var(--mc-stroke); border-radius: 14px; padding: 4px 10px; font-size: 12.5px; cursor: pointer; margin: 0 6px 6px 0; color: var(--mc-blue); }
        .iap-profil { white-space: pre-wrap; font-family: Consolas, "Courier New", monospace; font-size: 12px; max-height: 320px; overflow: auto; background: #f8fafc; padding: 8px; border-radius: 6px; }
        .iap-note { font-size: 12.5px; color: var(--mc-muted); line-height: 1.5; }
        .iap-msg { padding: 10px 14px; border-radius: 10px; margin: 0 16px; font-weight: 700; }
        .iap-msg.ok { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }
        .iap-msg.err { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
        .iap-micro { width: 44px; height: 38px; border: 1px solid var(--mc-stroke); border-radius: 10px; background: #fff; color: var(--mc-blue); cursor: pointer; display: inline-flex; align-items: center; justify-content: center; padding: 0; }
        .iap-micro.actif { background: #C21F1F; border-color: #C21F1F; color: #fff; }
        .iap-micro[hidden] { display: none; }
        .iap-champ label { display: block; font-weight: 700; font-size: 13px; margin: 8px 0 4px; }
        .iap-champ textarea { width: 100%; box-sizing: border-box; border: 1px solid var(--mc-stroke); border-radius: 10px; padding: 8px; font: inherit; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="toolbar">
        <div>
            <div class="title">🤖 <%= L("titre") %></div>
            <div style="font-size:13px;color:var(--mc-muted)"><%= L("sousTitre") %></div>
        </div>
        <asp:Button ID="btnNouvelle" runat="server" CssClass="btn" CausesValidation="false" />
    </div>

    <asp:Literal ID="litMessage" runat="server" />

    <div class="iap-grille">
        <div class="iap-carte">
            <div class="iap-fil" id="fil">
                <asp:Literal ID="litMessages" runat="server" />
                <asp:Panel ID="pnlVide" runat="server" CssClass="iap-vide">
                    <p><%= L("aucune") %></p>
                    <div class="iap-exemples">
                        <button type="button" onclick="return exemple(this)"><%= L("ex1") %></button>
                        <button type="button" onclick="return exemple(this)"><%= L("ex2") %></button>
                        <button type="button" onclick="return exemple(this)"><%= L("ex3") %></button>
                        <button type="button" onclick="return exemple(this)"><%= L("ex4") %></button>
                        <button type="button" onclick="return exemple(this)"><%= L("ex5") %></button>
                    </div>
                </asp:Panel>
            </div>
            <div class="iap-saisie">
                <asp:TextBox ID="txtQuestion" runat="server" TextMode="MultiLine" />
                <div class="iap-actions">
                    <asp:Button ID="btnEnvoyer" runat="server" CssClass="btn" />
                    <button type="button" class="iap-micro" id="pageMicro" hidden title="<%= L("micro") %>" aria-label="<%= L("micro") %>"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><rect x="9" y="3" width="6" height="11" rx="3" fill="currentColor"/><path d="M6 11a6 6 0 0 0 12 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M12 17v3M9 20h6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg></button>
                    <span hidden id="pageTxtEcoute"><%= L("ecoute") %></span>
                    <span class="iap-note"><asp:Literal ID="litCout" runat="server" /></span>
                </div>
            </div>
        </div>

        <div>
            <div class="iap-carte">
                <h2><%= L("profil") %></h2>
                <p class="iap-note"><%= L("profilNote") %></p>
                <p class="iap-note"><asp:Literal ID="litProfilInfo" runat="server" /></p>
                <div class="iap-champ">
                    <label for="<%= txtParticularites.ClientID %>"><%= L("particularites") %></label>
                    <asp:TextBox ID="txtParticularites" runat="server" TextMode="MultiLine" Rows="6" />
                </div>
                <div class="iap-actions">
                    <asp:Button ID="btnParticularites" runat="server" CssClass="btn" />
                    <asp:Button ID="btnActualiser" runat="server" CssClass="btn" CausesValidation="false" />
                </div>
                <details style="margin-top:10px">
                    <summary><%= L("voirProfil") %></summary>
                    <div class="iap-profil"><asp:Literal ID="litProfil" runat="server" /></div>
                </details>
            </div>
            <div class="iap-carte">
                <h2><%= L("confidentialite") %></h2>
                <p class="iap-note"><%= L("confidentialiteTexte") %></p>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        (function () {
            var fil = document.getElementById('fil');
            if (fil) fil.scrollTop = fil.scrollHeight;
            var zone = document.getElementById('<%= txtQuestion.ClientID %>');
            if (zone) zone.addEventListener('keydown', function (e) {
                if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); document.getElementById('<%= btnEnvoyer.ClientID %>').click(); }
            });
        })();
        (function () {
            // Le micro de la page complète : la question dictée part comme si on avait cliqué « Envoyer ».
            var R = window.SpeechRecognition || window.webkitSpeechRecognition, m = document.getElementById('pageMicro');
            if (!R || !m) return;
            var zone = document.getElementById('<%= txtQuestion.ClientID %>'), initial = zone.getAttribute('placeholder') || '', rec = null, ecoute = false;
            var langue = { fr: 'fr-CA', en: 'en-CA', es: 'es-MX' }['<%= CurrentLang %>'] || 'fr-CA';
            m.hidden = false;
            m.addEventListener('click', function () {
                if (ecoute) { rec.stop(); return; }
                rec = new R(); rec.lang = langue; rec.interimResults = true; rec.continuous = false;
                var finale = '';
                rec.onresult = function (e) { var c = ''; for (var i = e.resultIndex; i < e.results.length; i++) { if (e.results[i].isFinal) finale += e.results[i][0].transcript; else c += e.results[i][0].transcript; } zone.value = (finale + ' ' + c).trim(); };
                rec.onerror = function () { ecoute = false; m.classList.remove('actif'); zone.setAttribute('placeholder', initial); };
                rec.onend = function () { ecoute = false; m.classList.remove('actif'); zone.setAttribute('placeholder', initial); if (finale.trim()) { zone.value = finale.trim(); document.getElementById('<%= btnEnvoyer.ClientID %>').click(); } };
                ecoute = true; m.classList.add('actif'); zone.setAttribute('placeholder', document.getElementById('pageTxtEcoute').textContent); zone.value = '';
                try { rec.start(); } catch (err) { ecoute = false; m.classList.remove('actif'); }
            });
        })();
        function exemple(b) {
            var zone = document.getElementById('<%= txtQuestion.ClientID %>');
            zone.value = b.textContent; zone.focus();
            return false;
        }
    </script>
</asp:Content>
