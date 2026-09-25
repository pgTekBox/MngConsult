<%@ Page Title="Assistant" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" Async="true" CodeBehind="Assistant.aspx.vb" Inherits="Paie60Sec.Web.PageAssistant" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <style>
        .ia-grille { display: grid; grid-template-columns: minmax(0, 1fr) 360px; gap: 16px; align-items: start; }
        @media (max-width: 1000px) { .ia-grille { grid-template-columns: 1fr; } }
        .ia-fil { max-height: 60vh; overflow: auto; padding: 4px 2px; }
        .ia-tour { margin: 0 0 12px; display: flex; gap: 10px; }
        .ia-tour.user { justify-content: flex-end; }
        .ia-bulle { max-width: 82%; padding: 10px 14px; border-radius: 12px; line-height: 1.55; font-size: 14px; white-space: pre-wrap; }
        .ia-tour.user .ia-bulle { background: var(--accent); color: #fff; border-bottom-right-radius: 4px; }
        .ia-tour.assistant .ia-bulle { background: var(--fond); border: 1px solid var(--bord); border-bottom-left-radius: 4px; }
        .ia-quand { font-size: 11px; color: var(--encre-douce); margin-top: 4px; }
        .ia-saisie textarea { width: 100%; min-height: 72px; box-sizing: border-box; }
        .ia-vide { color: var(--encre-douce); font-size: 14px; padding: 12px 4px; }
        .ia-exemples button { background: #fff; border: 1px solid var(--bord); border-radius: 14px; padding: 4px 10px; font-size: 12.5px; cursor: pointer; margin: 0 6px 6px 0; color: var(--accent-fonce); }
        .ia-legende { font-size: 12.5px; columns: 2; column-gap: 12px; }
        .ia-legende div { break-inside: avoid; }
        .ia-profil { white-space: pre-wrap; font-family: Consolas, "Courier New", monospace; font-size: 12px; max-height: 320px; overflow: auto; background: var(--fond); padding: 8px; border-radius: 6px; }
        .ia-confidentialite { font-size: 12px; color: var(--encre-douce); line-height: 1.5; }
    </style>

    <div class="barre">
        <div>
            <h1>Assistant</h1>
            <p class="sous-titre">Posez vos questions sur la paie de cette compagnie : l'assistant connaît le guide de 60secPaie et le profil de la compagnie.</p>
        </div>
        <div class="actions sans-impression">
            <asp:Button ID="btnNouvelle" runat="server" Text="Nouvelle conversation" CssClass="secondaire" CausesValidation="false" />
        </div>
    </div>

    <div class="ia-grille">
        <div class="carte">
            <div class="ia-fil" id="fil">
                <asp:Literal ID="litMessages" runat="server" />
                <asp:Panel ID="pnlVide" runat="server" CssClass="ia-vide">
                    <p>Aucune question pour l'instant. Par exemple :</p>
                    <div class="ia-exemples">
                        <button type="button" onclick="return exemple(this)">Pourquoi le RRQ d'un employé est-il à 0 ?</button>
                        <button type="button" onclick="return exemple(this)">Comment ajouter l'assurance collective ?</button>
                        <button type="button" onclick="return exemple(this)">Quand dois-je payer mes retenues ?</button>
                        <button type="button" onclick="return exemple(this)">Comment produire le fichier de dépôt direct ?</button>
                        <button type="button" onclick="return exemple(this)">Que faire pour un employé qui quitte ?</button>
                    </div>
                </asp:Panel>
            </div>
            <div class="ia-saisie">
                <asp:TextBox ID="txtQuestion" runat="server" TextMode="MultiLine" placeholder="Votre question… (Ctrl+Entrée pour envoyer)" />
                <div class="actions">
                    <asp:Button ID="btnEnvoyer" runat="server" Text="Envoyer" />
                    <button type="button" class="ia-micro" id="pageMicro" hidden style="width:44px" title="Poser la question à voix haute" aria-label="Poser la question à voix haute"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><rect x="9" y="3" width="6" height="11" rx="3" fill="currentColor"/><path d="M6 11a6 6 0 0 0 12 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M12 17v3M9 20h6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg></button>
                    <span hidden id="pageTxtEcoute">Je vous écoute… parlez, puis faites une pause.</span>
                    <span class="note"><asp:Literal ID="litCout" runat="server" /></span>
                </div>
            </div>
        </div>

        <div>
            <div class="carte">
                <h2>Profil de la compagnie</h2>
                <p class="note">Ce que l'assistant sait de cette compagnie. Il est généré depuis vos données et refait automatiquement quand elles changent.</p>
                <p class="aide"><asp:Literal ID="litProfilInfo" runat="server" /></p>
                <div class="champ">
                    <asp:Label runat="server" AssociatedControlID="txtParticularites" Text="Particularités (écrites par vous)" />
                    <asp:TextBox ID="txtParticularites" runat="server" TextMode="MultiLine" Rows="6" placeholder="Ce que le logiciel ne sait pas : mutuelle de prévention, employés saisonniers, habitudes de paie, ententes particulières…" />
                </div>
                <div class="actions">
                    <asp:Button ID="btnParticularites" runat="server" Text="Enregistrer les particularités" CssClass="secondaire" />
                    <asp:Button ID="btnActualiser" runat="server" Text="Actualiser le profil" CssClass="secondaire" CausesValidation="false" />
                </div>
                <details style="margin-top:10px">
                    <summary>Codes des employés (visibles ici seulement)</summary>
                    <div class="ia-legende"><asp:Literal ID="litLegende" runat="server" /></div>
                </details>
                <details style="margin-top:6px">
                    <summary>Voir le profil envoyé à l'assistant</summary>
                    <div class="ia-profil"><asp:Literal ID="litProfil" runat="server" /></div>
                </details>
            </div>
            <div class="carte">
                <h2>Confidentialité</h2>
                <p class="ia-confidentialite">
                    Chaque question part vers OpenAI avec le guide de 60secPaie et le profil ci-dessus. Les employés y sont désignés par un code
                    (E1, E2…), jamais par leur nom. Aucun NAS, numéro de compte, courriel ni adresse n'est envoyé. Ne les écrivez pas dans vos questions.
                    Les échanges sont conservés par 60secPaie pour améliorer l'assistant. Ses réponses ne remplacent pas l'avis d'un comptable.
                </p>
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
            var zone = document.getElementById('<%= txtQuestion.ClientID %>'), initial = zone.getAttribute('placeholder'), rec = null, ecoute = false;
            var langue = { fr: 'fr-CA', en: 'en-CA', es: 'es-MX' }[document.documentElement.lang] || 'fr-CA';
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
