<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="AppliquerPlanComptable.aspx.vb" Inherits="MngConsul.AppliquerPlanComptable" %>
<%@ Register Src="~/Controls/EtapesReprise.ascx" TagPrefix="uc" TagName="EtapesReprise" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Créer les comptes au plan — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .app-page { max-width: 1280px; margin: 0 auto; padding: 16px }

    .app-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .app-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .app-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .app-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .app-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 820px; line-height: 1.6 }

    .card {
        background: #fff; border: 1px solid #e2e8f0; border-radius: 14px;
        padding: 18px 20px; margin-bottom: 16px;
    }

    .bar-top { display: flex; gap: 16px; align-items: flex-end; flex-wrap: wrap }

    .fld label { display: block; font-size: 12.5px; font-weight: 700; margin-bottom: 4px; color: #334155 }

    .fld select, .fld input[type=text] {
        padding: 8px 11px; border: 1px solid #cbd5e1; border-radius: 9px;
        font-size: 13px; font-family: inherit; background: #fff;
    }

    .compteurs { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin-top: 14px }

    .cpt { border: 1px solid #e2e8f0; border-radius: 10px; padding: 9px 12px; background: #fff }
    .cpt .l { font-size: 11px; color: #64748b; text-transform: uppercase; letter-spacing: .3px }
    .cpt .v { font-size: 19px; font-weight: 800; color: #0f172a }
    .cpt.att { background: #fffbeb; border-color: #fde68a }
    .cpt.att .v { color: #b45309 }
    .cpt.ok { background: #ecfdf5; border-color: #a7f3d0 }
    .cpt.ok .v { color: #047857 }

    /* Le seul ecran de la reprise qui touche la comptabilite. Il le dit. */
    .avert-ecrit {
        display: flex; gap: 12px; padding: 13px 16px; border-radius: 12px;
        background: #fff7ed; border: 1px solid #fed7aa; color: #7c2d12;
        font-size: 13px; line-height: 1.55; margin-bottom: 16px;
    }
    .avert-ecrit b { color: #7c2d12 }

    .tbl-wrap { overflow-x: auto; margin-top: 6px }

    table.t { border-collapse: collapse; width: 100%; font-size: 13px }
    table.t th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; font-weight: 800; padding: 8px 9px; border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }
    table.t td { padding: 8px 9px; border-bottom: 1px solid #f1f5f9; vertical-align: top }
    table.t tr:hover td { background: #f8fafc }

    .src-c { font-weight: 700; color: #0f172a; white-space: nowrap }
    .src-c .sans-num { font-weight: 500; color: #94a3b8; font-style: italic }
    .src-n { font-weight: 700; color: #0f172a }
    .nature { font-size: 11px; color: #64748b; white-space: nowrap }

    .cls-in { width: 100%; min-width: 260px; padding: 6px 8px; border: 1px solid #cbd5e1;
              border-radius: 8px; font-size: 12.5px; font-family: inherit; background: #fff }
    .cls-cell .cls-f { display: block; margin-bottom: 4px }
    .cls-cell .scls-f { display: block }
    .num-in { width: 82px; padding: 6px 8px; border: 1px solid #cbd5e1; border-radius: 8px;
              font-size: 12.5px; font-family: inherit; text-align: center }
    .nom-in { width: 100%; min-width: 200px; padding: 6px 8px; border: 1px solid #cbd5e1;
              border-radius: 8px; font-size: 12.5px; font-family: inherit }

    .plage { display: block; margin-top: 3px; font-size: 11px; color: #94a3b8 }

    .acts { display: flex; gap: 9px; flex-wrap: wrap; margin-top: 18px; align-items: center }

    .btn { padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700;
           border: 1px solid transparent; cursor: pointer; font-family: inherit }
    .btn-p { background: #2563eb; color: #fff }
    .btn-s { background: #f1f5f9; color: #334155; border-color: #e2e8f0 }
    .btn-go { background: #047857; color: #fff }
    .btn-go:hover { background: #065f46 }

    /* L'assistant sur un compte d'origine, comme à l'étape 2. */
    .ia-cpt { margin-left: 8px; padding: 1px 7px; border: 1px solid #c7d2fe; border-radius: 999px; background: #eef2ff; color: #4338ca; font-size: 10.5px; font-weight: 800; cursor: pointer; vertical-align: middle; white-space: nowrap }
    .ia-cpt:hover { background: #e0e7ff }
    .iac-overlay { position: fixed; inset: 0; z-index: 9000; background: rgba(15,23,42,.45); display: flex; align-items: center; justify-content: center }
    .iac-overlay[hidden] { display: none }
    .iac-dlg { position: fixed; width: min(760px, calc(100vw - 32px)); max-height: min(85vh, 900px); background: #fff; border-radius: 16px; box-shadow: 0 24px 60px rgba(2,6,23,.35); display: flex; flex-direction: column; overflow: hidden; font-size: 14px }
    .iac-tete { display: flex; align-items: center; gap: 10px; padding: 12px 16px; background: #1e3a8a; color: #fff; cursor: move; user-select: none; touch-action: none }
    .iac-tete b { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 15px }
    .iac-tete small { opacity: .8; font-size: 11.5px; white-space: nowrap }
    .iac-x { border: 0; background: rgba(255,255,255,.14); color: #fff; width: 30px; height: 30px; border-radius: 8px; font-size: 18px; cursor: pointer }
    .iac-x:hover { background: rgba(255,255,255,.3) }
    .iac-corps { padding: 16px 20px; overflow: auto; line-height: 1.55; color: #0f172a }
    .iac-corps h2 { font-size: 15px; margin: 14px 0 6px; color: #1e3a8a }
    .iac-corps h2:first-child { margin-top: 0 }
    .iac-corps ul { margin: 4px 0 8px; padding-left: 20px }
    .iac-corps p { margin: 6px 0 }
    .iac-attente { color: #64748b; font-style: italic }
    .iac-erreur { color: #b91c1c; font-weight: 700 }
    .iac-pied { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 10px 16px; border-top: 1px solid #e2e8f0; background: #f8fafc; font-size: 12px; color: #64748b }
    .iac-pied button { border: 1px solid #cbd5e1; background: #fff; border-radius: 8px; padding: 6px 12px; font-weight: 700; cursor: pointer; margin-left: 6px }
    .iac-pied button:hover { background: #f1f5f9 }

    .lien-retour { font-size: 12.5px; color: #2563eb; text-decoration: none; margin-left: auto }
    .lien-retour:hover { text-decoration: underline }

             margin-bottom: 14px; font-size: 13.5px; line-height: 1.55 }

    .vide { padding: 26px; text-align: center; color: #64748b; font-size: 13.5px }

    table.crees { border-collapse: collapse; margin-top: 10px; font-size: 13px }
    table.crees th { text-align: left; font-size: 11px; text-transform: uppercase; color: #64748b;
                     padding: 6px 12px 6px 0 }
    table.crees td { padding: 4px 12px 4px 0; border-bottom: 1px solid #f1f5f9 }
    table.crees td.n { font-weight: 800; color: #047857 }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="app-page">

    <uc:EtapesReprise ID="ucEtapes" runat="server" Etape="3" />

    <div class="app-head">
        <div class="ico">📗</div>
        <div>
            <h1>Créer les comptes au plan comptable</h1>
            <div class="sub">Étape 3 de la reprise comptable</div>
        </div>
    </div>

    <p class="app-lede">
        Les comptes que vous avez marqués <b>Créer</b> à l'étape précédente entrent ici
        dans votre plan comptable. Choisissez la classe de chacun — c'est elle qui donne
        au compte sa place dans vos états financiers. Le numéro peut être laissé vide :
        il sera attribué dans la plage de la classe.
    </p>

    <div class="avert-ecrit">
        <span>⚠️</span>
        <div>
            <b>C'est la première étape qui écrit dans votre comptabilité.</b>
            Tout ce qui précède restait en préparation et pouvait être abandonné sans
            conséquence. Les comptes créés ici existeront pour de bon. Rien n'est écrit
            tant que vous n'avez pas cliqué sur <b>Créer les comptes</b>.
        </div>
    </div>

    <div class="card">
        <div class="bar-top">
            <div class="fld">
                <label>Lot à appliquer</label>
            </div>
            <asp:HyperLink ID="hlRetour" runat="server" CssClass="lien-retour"
                Text="← revenir à la correspondance" />
        </div>

        <div class="compteurs">
            <div class="cpt att">
                <div class="l">À créer</div>
                <div class="v"><asp:Literal ID="litACreer" runat="server" Text="0" /></div>
            </div>
            <div class="cpt ok">
                <div class="l">Déjà créés</div>
                <div class="v"><asp:Literal ID="litDejaCrees" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">Liés</div>
                <div class="v"><asp:Literal ID="litLies" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">Ignorés</div>
                <div class="v"><asp:Literal ID="litIgnores" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">Encore à décider</div>
                <div class="v"><asp:Literal ID="litADecider" runat="server" Text="0" /></div>
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlAucunLot" runat="server" Visible="false" CssClass="card">
        <div class="vide">
            Aucun lot de plan comptable n'a encore été chargé.
            Commencez par l'étape 1, l'importation du fichier.
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlRien" runat="server" Visible="false" CssClass="card">
        <div class="vide">
            <b>Aucun compte à créer dans ce lot.</b><br />
            Soit tout a déjà été créé, soit les comptes sont tous liés à des comptes
            existants ou ignorés.
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlLignes" runat="server" Visible="false" CssClass="card">
        <div class="tbl-wrap">
            <table class="t">
                <thead>
                    <tr>
                        <th style="width:36px">#</th>
                        <th>Compte de l'ancien logiciel</th>
                        <th style="width:340px">Classe et sous-classe — où le ranger</th>
                        <th style="width:110px">Numéro</th>
                        <th style="width:260px">Nom du compte</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptLignes" runat="server">
                        <ItemTemplate>
                            <tr>
                                <td><%# Eval("LigneNo") %></td>
                                <td>
                                    <asp:HiddenField runat="server" ID="hfCleSource" Value='<%# Eval("CleSource") %>' />
                                    <asp:HiddenField runat="server" ID="hfNature" Value='<%# Eval("TypeNormalise") %>' />
                                    <%-- La même fiche qu'à l'étape 2 (T312) : numéro, nom, nature, type
                                         et sous-type QuickBooks, solde, origine, sous-compte, description. --%>
                                    <div class="src-c"><%# CleAffichee(Eval("Compte")) %></div>
                                    <div class="src-n"><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %><button type="button" class="ia-cpt" data-id='<%# Eval("StagingId") %>' title="Assistant : que représente ce compte et où le ranger ?" aria-label="Assistant pour ce compte">✨ Assistant</button></div>
                                    <%# FicheSource(Container.DataItem) %>
                                </td>
                                <td class="cls-cell">
                                    <%-- La classe, puis la sous-classe : la seconde se restreint à la
                                         première, comme à l'étape 2. C'est la sous-classe qui range le
                                         compte et fixe sa plage de numéros. --%>
                                    <asp:DropDownList runat="server" ID="ddlClasse" CssClass="cls-in cls-f" />
                                    <asp:DropDownList runat="server" ID="ddlSousClasse" CssClass="cls-in scls-f" />
                                    <span class="plage">la plage de la sous-classe fixe le numéro</span>
                                </td>
                                <td>
                                    <asp:TextBox runat="server" ID="txtNumero" CssClass="num-in" MaxLength="20"
                                        Text='<%# Eval("CompteCible") %>' placeholder="auto" />
                                </td>
                                <td>
                                    <asp:TextBox runat="server" ID="txtNom" CssClass="nom-in" MaxLength="150"
                                        Text='<%# Eval("NomPropose") %>' />
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>

        <div class="acts">
            <asp:Button ID="btnCreer" runat="server" CssClass="btn btn-go" CausesValidation="false"
                Text="Créer les comptes"
                OnClientClick="if (!confirm('Créer ces comptes dans votre plan comptable ?\n\nC&#39;est une écriture réelle : les comptes existeront pour de bon.')) { return false; }" />
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlCrees" runat="server" Visible="false" CssClass="card">
        <b style="font-size:14px">Comptes créés</b>
        <table class="crees">
            <thead>
                <tr><th>Numéro</th><th>Nom</th><th>Venait de</th></tr>
            </thead>
            <tbody>
                <asp:Repeater ID="rptCrees" runat="server">
                    <ItemTemplate>
                        <tr>
                            <td class="n"><%# Server.HtmlEncode(Convert.ToString(Eval("Compte"))) %></td>
                            <td><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></td>
                            <td><%# Server.HtmlEncode(Convert.ToString(Eval("CleSource"))) %></td>
                        </tr>
                    </ItemTemplate>
                </asp:Repeater>
            </tbody>
        </table>
    </asp:Panel>

</div>

<script type="text/javascript">
    // Classe, puis sous-classe : la seconde liste ne montre que les sous-classes
    // de la classe choisie (chaque option porte sa classe en data-parent). Choisir
    // une sous-classe sans classe remonte la classe d'elle-même.
    (function () {
        var lignes = document.querySelectorAll('tbody tr');
        for (var i = 0; i < lignes.length; i++) {
            (function (tr) {
                var cls = tr.querySelector('select.cls-f');
                var scl = tr.querySelector('select.scls-f');
                if (!cls || !scl) return;

                // Toutes les sous-classes, gardées à part : la liste visible en est un extrait.
                var toutes = [];
                for (var j = 0; j < scl.options.length; j++) {
                    var o = scl.options[j];
                    toutes.push({ v: o.value, t: o.textContent, p: o.getAttribute('data-parent') || '' });
                }

                function filtrer() {
                    var k = cls.value, courant = scl.value;
                    while (scl.firstChild) { scl.removeChild(scl.firstChild); }
                    for (var j = 0; j < toutes.length; j++) {
                        var s = toutes[j];
                        if (s.v !== '' && k !== '' && s.p !== k) continue;
                        var o = document.createElement('option');
                        o.value = s.v; o.textContent = s.t;
                        if (s.p) o.setAttribute('data-parent', s.p);
                        scl.appendChild(o);
                    }
                    scl.value = courant;
                    if (scl.value !== courant) scl.value = '';
                }

                cls.addEventListener('change', filtrer);
                scl.addEventListener('change', function () {
                    var o = scl.options[scl.selectedIndex];
                    var p = o ? o.getAttribute('data-parent') : '';
                    if (p && cls.value !== p) { cls.value = p; filtrer(); scl.value = o.value; }
                });
                filtrer();
            })(lignes[i]);
        }
    })();
</script>

<div class="iac-overlay" id="iacOverlay" hidden>
    <div class="iac-dlg" id="iacDlg" role="dialog" aria-modal="true" aria-labelledby="iacTitre">
        <div class="iac-tete" id="iacTete">
            <b id="iacTitre">Assistant</b>
            <small>✨ explication du compte</small>
            <button type="button" class="iac-x" id="iacFermer" title="Fermer" aria-label="Fermer">&times;</button>
        </div>
        <div class="iac-corps" id="iacCorps"></div>
        <div class="iac-pied">
            <span id="iacCout"></span>
            <span><button type="button" id="iacCopier">Copier</button><button type="button" id="iacFermer2">Fermer</button></span>
        </div>
    </div>
</div>

<script type="text/javascript">
    // ── Assistant sur un compte source : fenêtre flottante (déplaçable par sa barre) avec la réponse de l'IA. ──
    (function () {
        var overlay = document.getElementById('iacOverlay'), dlg = document.getElementById('iacDlg'), corps = document.getElementById('iacCorps');
        var titre = document.getElementById('iacTitre'), cout = document.getElementById('iacCout'), tete = document.getElementById('iacTete');
        if (!overlay) return;
        var texteBrut = '';
        function html(t) {
            var d = document.createElement('div'); d.textContent = t || ''; var s = d.innerHTML;
            s = s.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>');
            var lignes = s.split(/\r?\n/), out = [], liste = false;
            lignes.forEach(function (l) {
                var m;
                if ((m = l.match(/^\s*##+\s*(.+)$/))) { if (liste) { out.push('</ul>'); liste = false; } out.push('<h2>' + m[1] + '</h2>'); }
                else if ((m = l.match(/^\s*[-•]\s+(.+)$/))) { if (!liste) { out.push('<ul>'); liste = true; } out.push('<li>' + m[1] + '</li>'); }
                else if (l.trim() === '') { if (liste) { out.push('</ul>'); liste = false; } }
                else { if (liste) { out.push('</ul>'); liste = false; } out.push('<p>' + l + '</p>'); }
            });
            if (liste) out.push('</ul>');
            return out.join('');
        }
        function ouvrir(nom, id) {
            titre.textContent = nom; corps.innerHTML = '<p class="iac-attente">L’assistant réfléchit… (une dizaine de secondes)</p>'; cout.textContent = ''; texteBrut = '';
            overlay.hidden = false; dlg.style.left = ''; dlg.style.top = '';
            fetch('AssistantCompte.ashx', { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ stagingId: id }) })
                .then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); })
                .then(function (x) {
                    if (x.ok) { texteBrut = x.j.reponse || ''; corps.innerHTML = html(texteBrut); if (typeof x.j.cout === 'number') cout.textContent = 'Coût des questions ce mois-ci : ' + x.j.cout.toFixed(4) + ' US$'; }
                    else { corps.innerHTML = '<p class="iac-erreur">' + html(x.j.erreur || 'L’assistant n’a pas pu répondre.') + '</p>'; }
                })
                .catch(function () { corps.innerHTML = '<p class="iac-erreur">L’assistant n’a pas pu répondre. Réessayez dans un instant.</p>'; });
        }
        function fermer() { overlay.hidden = true; }
        document.addEventListener('click', function (e) {
            var b = e.target.closest('button.ia-cpt'); if (!b) return;
            e.preventDefault();
            var tr = b.closest('tr'), num = tr && tr.querySelector('.src-c') ? tr.querySelector('.src-c').textContent.trim() : '';
            var nom = b.parentNode.firstChild && b.parentNode.firstChild.nodeType === 3 ? b.parentNode.firstChild.textContent.trim() : '';
            ouvrir((num ? num + ' — ' : '') + nom, parseInt(b.getAttribute('data-id'), 10));
        });
        document.getElementById('iacFermer').addEventListener('click', fermer);
        document.getElementById('iacFermer2').addEventListener('click', fermer);
        overlay.addEventListener('click', function (e) { if (e.target === overlay) fermer(); });
        document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !overlay.hidden) fermer(); });
        document.getElementById('iacCopier').addEventListener('click', function () {
            if (!texteBrut) return;
            if (navigator.clipboard) navigator.clipboard.writeText(titre.textContent + '\n\n' + texteBrut);
        });
        // Déplacement par la barre de titre, borné à la fenêtre.
        var glisse = null;
        function placer(x, y) {
            var w = dlg.offsetWidth, h = dlg.offsetHeight;
            x = Math.max(0, Math.min(x, window.innerWidth - w)); y = Math.max(0, Math.min(y, window.innerHeight - h));
            dlg.style.left = x + 'px'; dlg.style.top = y + 'px';
        }
        tete.addEventListener('pointerdown', function (e) {
            if (e.target.closest('.iac-x')) return;
            var r = dlg.getBoundingClientRect(); glisse = { dx: e.clientX - r.left, dy: e.clientY - r.top };
            tete.setPointerCapture(e.pointerId); e.preventDefault();
        });
        tete.addEventListener('pointermove', function (e) { if (glisse) placer(e.clientX - glisse.dx, e.clientY - glisse.dy); });
        tete.addEventListener('pointerup', function () { glisse = null; });
        tete.addEventListener('pointercancel', function () { glisse = null; });
    })();
</script>
</asp:Content>
