<%@ Page Title="Plan comptable par défaut" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfPlanComptableDefaut.aspx.vb"
    Inherits="prjSec60Admin.wbfPlanComptableDefaut" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Plan comptable par défaut — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pc-wrap { padding: 20px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
        .pc-wrap h1 { font-size: 22px; font-weight: 900; margin: 0 0 6px; color: #0f172a; }
        .pc-sub { color: #64748b; font-size: 13px; margin-bottom: 14px; max-width: 980px; line-height: 1.6; }
        .pc-sub b { color: #0f172a; }
        .pc-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 14px 16px; margin-bottom: 16px; }
        .pc-card h2 { font-size: 15px; font-weight: 900; margin: 0 0 4px; color: #0f172a; }
        .pc-card .aide { font-size: 12.5px; color: #64748b; margin: 0 0 12px; line-height: 1.55; }
        .pc-repere { display: flex; gap: 22px; flex-wrap: wrap; align-items: center; margin-bottom: 14px; }
        .pc-repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 800; }
        .pc-repere .bloc .v { font-size: 18px; font-weight: 900; color: #0f172a; font-variant-numeric: tabular-nums; }
        .pc-barre { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; }
        .pc-barre input[type=text] { padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 13px; width: 280px; }
        .pc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .pc-table th, .pc-table td { border-bottom: 1px solid #e2e8f0; padding: 6px 8px; text-align: left; vertical-align: top; }
        .pc-table th { background: #f8fafc; font-weight: 800; color: #0f172a; position: sticky; top: 0; white-space: nowrap; }
        .pc-table tr.classe td { background: #eff6ff; color: #1e3a8a; font-weight: 900; border-top: 1px solid #dbeafe; }
        .pc-table tr.inactif td { color: #94a3b8; }
        .pc-table td.num { font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 700; }
        .pc-table td.desc { color: #64748b; font-size: 12px; }
        .pill { display: inline-block; padding: 1px 7px; border-radius: 999px; font-size: 11px; font-weight: 800; border: 1px solid #e2e8f0; background: #f1f5f9; color: #475569; white-space: nowrap; }
        .pill.sys { background: #fef3c7; color: #92400e; border-color: #fcd34d; }
        .pill.off { background: #fef2f2; color: #991b1b; border-color: #fecaca; }
        .btn { display: inline-block; padding: 7px 14px; border-radius: 9px; border: 1px solid #cbd5e1; background: #fff; color: #0f172a; font-size: 13px; font-weight: 700; cursor: pointer; }
        .btn:hover { background: #f8fafc; }
        .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff; }
        .btn.primaire:hover { background: #1d4ed8; }
        .btn.danger { color: #b91c1c; border-color: #fecaca; }
        .btn.danger:hover { background: #fef2f2; }
        .btn.petit { padding: 2px 8px; font-size: 12px; border-radius: 7px; }
        .champs { display: flex; gap: 12px; flex-wrap: wrap; align-items: flex-end; }
        .champ label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 800; margin-bottom: 4px; }
        .champ input[type=text], .champ select { padding: 7px 9px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 13px; }
        .champ input.num { width: 90px; }
        .champ input.nom { width: 300px; }
        .champ input.desc { width: 420px; }
        .champ select { min-width: 200px; }
        .champ .case { font-size: 13px; padding: 8px 0; }
        .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 0 0 14px; line-height: 1.55; }
        .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
        .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }
        .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; }
        .pc-tbl-wrap { max-height: 70vh; overflow: auto; border: 1px solid #e2e8f0; border-radius: 10px; }
        .pc-note { font-size: 12.5px; color: #475569; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px 15px; line-height: 1.6; max-width: 980px; }
        .pc-note b { color: #0f172a; }

        /* L'assistant IA sur un compte QuickBooks candidat : bouton et fenêtre flottante (portés de l'ERP). */
        .ia-cpt { margin-left: 8px; padding: 1px 7px; border: 1px solid #c7d2fe; border-radius: 999px; background: #eef2ff; color: #4338ca; font-size: 10.5px; font-weight: 800; cursor: pointer; vertical-align: middle; white-space: nowrap; }
        .ia-cpt:hover { background: #e0e7ff; }
        .iac-overlay { position: fixed; inset: 0; z-index: 9000; background: rgba(15,23,42,.45); display: flex; align-items: center; justify-content: center; }
        .iac-overlay[hidden] { display: none; }
        .iac-dlg { position: fixed; width: min(760px, calc(100vw - 32px)); max-height: min(85vh, 900px); background: #fff; border-radius: 16px; box-shadow: 0 24px 60px rgba(2,6,23,.35); display: flex; flex-direction: column; overflow: hidden; font-size: 14px; }
        .iac-tete { display: flex; align-items: center; gap: 10px; padding: 12px 16px; background: #1e3a8a; color: #fff; cursor: move; user-select: none; touch-action: none; }
        .iac-tete b { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 15px; }
        .iac-tete small { opacity: .8; font-size: 11.5px; white-space: nowrap; }
        .iac-x { border: 0; background: rgba(255,255,255,.14); color: #fff; width: 30px; height: 30px; border-radius: 8px; font-size: 18px; cursor: pointer; }
        .iac-x:hover { background: rgba(255,255,255,.3); }
        .iac-corps { padding: 16px 20px; overflow: auto; line-height: 1.55; color: #0f172a; }
        .iac-corps h2 { font-size: 15px; margin: 14px 0 6px; color: #1e3a8a; }
        .iac-corps h2:first-child { margin-top: 0; }
        .iac-corps ul { margin: 4px 0 8px; padding-left: 20px; }
        .iac-corps p { margin: 6px 0; }
        .iac-attente { color: #64748b; font-style: italic; }
        .iac-erreur { color: #b91c1c; font-weight: 700; }
        .iac-pied { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 10px 16px; border-top: 1px solid #e2e8f0; background: #f8fafc; font-size: 12px; color: #64748b; }
        .iac-pied button { border: 1px solid #cbd5e1; background: #fff; border-radius: 8px; padding: 6px 12px; font-weight: 700; cursor: pointer; margin-left: 6px; }
        .iac-pied button:hover { background: #f1f5f9; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pc-wrap">
        <h1>Plan comptable par défaut</h1>
        <div class="pc-sub">
            Le plan que reçoit <b>chaque nouvelle compagnie</b> : c'est celui de la compagnie modèle
            (<code>00000000-0000-0000-0000-000000000001</code>), copié avec ses classes, ses journaux et ses paramètres
            au premier enregistrement des Paramètres de la compagnie (procédure s0500InitializeCompanyData).
            Ce que vous changez ici vaut pour les compagnies <b>créées ensuite</b> ; les compagnies existantes gardent leur plan.
        </div>

        <asp:Literal ID="litMsg" runat="server" />

        <div class="pc-card">
            <div class="pc-repere">
                <div class="bloc"><div class="l">Comptes</div><div class="v"><asp:Literal ID="litNbComptes" runat="server" /></div></div>
                <div class="bloc"><div class="l">Actifs</div><div class="v"><asp:Literal ID="litNbActifs" runat="server" /></div></div>
                <div class="bloc"><div class="l">Système</div><div class="v"><asp:Literal ID="litNbSysteme" runat="server" /></div></div>
                <div class="bloc"><div class="l">Classes</div><div class="v"><asp:Literal ID="litNbClasses" runat="server" /></div></div>
            </div>
            <div class="pc-barre">
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Numéro ou nom de compte…" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Chercher" CausesValidation="false" />
                <asp:Button ID="btnTout" runat="server" CssClass="btn" Text="Tout afficher" CausesValidation="false" />
                <asp:Button ID="btnTraduireTous" runat="server" CssClass="btn" Text="✨ Compléter par l'IA les alias sans l'autre langue" ToolTip="Pour chaque compte dont les alias QuickBooks n'existent que dans une langue, demande à l'IA le libellé officiel dans l'autre et le pose comme alias" CausesValidation="false"
                    OnClientClick="if (!confirm('Demander à l\'IA le nom QuickBooks manquant (français ou anglais) pour tous les comptes concernés, et poser les alias ?')) { return false; }" />
            </div>
            <div class="pc-tbl-wrap">
                <asp:Literal ID="litTableau" runat="server" />
            </div>
        </div>

        <div class="pc-card">
            <h2><asp:Literal ID="litTitreForm" runat="server" Text="Ajouter un compte au plan par défaut" /></h2>
            <p class="aide">
                Choisissez d'abord la classe : la sous-classe, le type de bilan et le sens se remplissent d'après elle.
                Le numéro doit être libre dans le plan modèle. Un compte <b>système</b> (utilisé par l'application elle-même)
                se corrige mais ne se supprime pas.
            </p>
            <asp:HiddenField ID="hfId" runat="server" />
            <div class="champs">
                <div class="champ"><label>Classe</label>
                    <asp:DropDownList ID="ddlClasseParent" runat="server" AutoPostBack="true" /></div>
                <div class="champ"><label>Sous-classe</label>
                    <asp:DropDownList ID="ddlClasse" runat="server" /></div>
                <div class="champ"><label>Numéro</label>
                    <asp:TextBox ID="txtNumero" runat="server" CssClass="num" MaxLength="10" /></div>
                <div class="champ"><label>Nom</label>
                    <asp:TextBox ID="txtNom" runat="server" CssClass="nom" MaxLength="150" /></div>
                <div class="champ"><label>Type de bilan</label>
                    <asp:DropDownList ID="ddlTypeBilan" runat="server">
                        <asp:ListItem Text="Actif" Value="A" />
                        <asp:ListItem Text="Passif" Value="P" />
                        <asp:ListItem Text="Capitaux propres" Value="CP" />
                        <asp:ListItem Text="Revenus" Value="R" />
                        <asp:ListItem Text="Charges" Value="C" />
                    </asp:DropDownList></div>
                <div class="champ"><label>Sens</label>
                    <asp:DropDownList ID="ddlSens" runat="server">
                        <asp:ListItem Text="Débiteur" Value="D" />
                        <asp:ListItem Text="Créditeur" Value="C" />
                    </asp:DropDownList></div>
                <div class="champ"><label>Actif</label>
                    <div class="case"><asp:CheckBox ID="chkActif" runat="server" Checked="true" Text=" visible dans les nouvelles compagnies" /></div></div>
            </div>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><label>Description</label>
                    <asp:TextBox ID="txtDescription" runat="server" CssClass="desc" MaxLength="250" /></div>
            </div>
            <asp:Panel ID="pnlAlias" runat="server" Visible="false" Style="margin-top:14px; padding-top:12px; border-top:1px dashed #e2e8f0">
                <p class="aide">
                    <b>Alias QuickBooks de ce compte.</b> Les noms que QuickBooks donne à ce compte, dans chaque langue, avec leur
                    sous-type (par exemple <i>UndepositedFunds</i>). Un compte d'ici peut en porter plusieurs ; un nom source ne mène
                    qu'à un seul compte. À la reprise d'un plan QuickBooks, un compte qui porte un de ces noms, ou ce sous-type s'il
                    ne désigne qu'un compte, est lié d'office à celui-ci, sans passer par l'IA.
                </p>
                <asp:Literal ID="litAliases" runat="server" />
                <div class="champs" style="margin-top:8px">
                    <div class="champ"><label>Langue</label>
                        <asp:DropDownList ID="ddlAliasLangue" runat="server">
                            <asp:ListItem Value="FR" Text="français" />
                            <asp:ListItem Value="EN" Text="anglais" />
                            <asp:ListItem Value="" Text="—" />
                        </asp:DropDownList></div>
                    <div class="champ"><label>Nom chez QuickBooks</label>
                        <asp:TextBox ID="txtAliasNom" runat="server" CssClass="nom" MaxLength="200" placeholder="Fonds non déposés" /></div>
                    <div class="champ"><label>Sous-type QBO</label>
                        <asp:TextBox ID="txtAliasSousType" runat="server" CssClass="nom" MaxLength="100" placeholder="UndepositedFunds" /></div>
                    <div class="champ"><asp:Button ID="btnAjouterAlias" runat="server" CssClass="btn" Text="Ajouter l'alias" CausesValidation="false" /></div>
                    <div class="champ"><asp:Button ID="btnTraduireAlias" runat="server" CssClass="btn" Text="✨ Compléter l'autre langue par l'IA" ToolTip="Demande à l'IA le libellé officiel de QuickBooks dans la langue qui manque, et le pose comme alias" CausesValidation="false" /></div>
                </div>
            </asp:Panel>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><asp:Button ID="btnSave" runat="server" CssClass="btn primaire" Text="Enregistrer" CausesValidation="false" /></div>
                <div class="champ"><asp:Button ID="btnAnnuler" runat="server" CssClass="btn" Text="Annuler" CausesValidation="false" Visible="false" /></div>
            </div>
        </div>

        <div class="pc-card">
            <h2>Ajouter depuis un import QuickBooks</h2>
            <p class="aide">
                Les comptes QuickBooks qu'une compagnie a décidé de <b>Créer</b> à l'étape 2 de sa reprise sont ceux qui
                n'ont aucun équivalent dans notre plan. Choisissez la compagnie, cochez ceux qui méritent d'entrer dans le
                plan par défaut, donnez-leur leur sous-classe, et ajoutez : chaque compte est créé dans le modèle avec son
                <b>alias QuickBooks</b>, et le prochain client QuickBooks se le voit lier d'office. Rien ne change chez la compagnie d'origine.
            </p>
            <div class="champs">
                <div class="champ"><label>Compagnie</label>
                    <asp:DropDownList ID="ddlCompagnie" runat="server" /></div>
                <div class="champ"><label>Montrer</label>
                    <asp:DropDownList ID="ddlFiltreCandidats" runat="server">
                        <asp:ListItem Value="CREER" Text="les comptes décidés « Créer » à l'étape 2" />
                        <asp:ListItem Value="SANS_JUMEAU" Text="les comptes sans jumeau chez la compagnie" />
                        <asp:ListItem Value="TOUS" Text="tout le plan QuickBooks en préparation" />
                    </asp:DropDownList></div>
                <div class="champ"><asp:Button ID="btnVoir" runat="server" CssClass="btn" Text="Voir les comptes" CausesValidation="false" /></div>
            </div>
            <div style="margin-top:12px">
                <asp:Literal ID="litCandidats" runat="server" />
            </div>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><asp:Button ID="btnAjouterModele" runat="server" CssClass="btn primaire" Text="Ajouter les comptes cochés au plan par défaut" CausesValidation="false" Visible="false"
                    OnClientClick="if (!confirm('Ajouter les comptes cochés au plan comptable par défaut ? Les prochaines compagnies les recevront.')) { return false; }" /></div>
            </div>
        </div>

        <div class="pc-card">
            <h2>Resynchroniser une compagnie avec le plan par défaut</h2>
            <p class="aide">
                Le plan d'une compagnie est copié du modèle à sa création et n'est jamais retouché ensuite. Ce bloc le remet
                au niveau du plan par défaut : <b>ajoute</b> les comptes du modèle qu'elle n'a pas (par numéro, dans la sous-classe
                de même code, alias compris), <b>aligne</b> sur les comptes communs les alias QuickBooks, les noms anglais et
                espagnol et la description (le nom français et l'état actif de la compagnie ne bougent pas), et, si vous le
                demandez, <b>retire</b> les comptes absents du modèle qui ne sont ni système ni référencés par une écriture,
                un modèle d'écriture ou une liaison de reprise. <b>Simuler</b> montre tout sans rien écrire.
            </p>
            <div class="champs">
                <div class="champ"><label>Compagnie</label>
                    <asp:DropDownList ID="ddlCieResync" runat="server" /></div>
                <div class="champ"><label>Comptes en trop</label>
                    <div class="case"><asp:CheckBox ID="chkSupprimerEnTrop" runat="server" Text=" retirer ceux qui ne sont ni système ni référencés" /></div></div>
                <div class="champ"><asp:Button ID="btnSimulerResync" runat="server" CssClass="btn" Text="Simuler" CausesValidation="false" /></div>
                <div class="champ"><asp:Button ID="btnAppliquerResync" runat="server" CssClass="btn primaire" Text="Appliquer" CausesValidation="false"
                    OnClientClick="if (!confirm('Resynchroniser le plan comptable de cette compagnie avec le plan par défaut ? Les ajouts et alignements sont réels.')) { return false; }" /></div>
            </div>
            <div style="margin-top:12px">
                <asp:Literal ID="litResync" runat="server" />
            </div>
        </div>

        <div class="iac-overlay" id="iacOverlay" hidden>
            <div class="iac-dlg" id="iacDlg" role="dialog" aria-modal="true" aria-labelledby="iacTitre">
                <div class="iac-tete" id="iacTete">
                    <b id="iacTitre">Assistant</b>
                    <small>✨ explication du compte QuickBooks</small>
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
            // ── Assistant sur un compte QuickBooks candidat : fenêtre flottante (déplaçable par sa barre) avec la réponse de l'IA. ──
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
                function ouvrir(nom, id, cie) {
                    titre.textContent = nom; corps.innerHTML = '<p class="iac-attente">L’assistant réfléchit… (une dizaine de secondes)</p>'; cout.textContent = ''; texteBrut = '';
                    overlay.hidden = false; dlg.style.left = ''; dlg.style.top = '';
                    fetch('AssistantCompteQBO.ashx', { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ stagingId: id, companyGuid: cie }) })
                        .then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); })
                        .then(function (x) {
                            if (x.ok) { texteBrut = x.j.reponse || ''; corps.innerHTML = html(texteBrut); if (typeof x.j.cout === 'number') cout.textContent = 'Coût des questions de cette compagnie ce mois-ci : ' + x.j.cout.toFixed(4) + ' US$'; }
                            else { corps.innerHTML = '<p class="iac-erreur">' + html(x.j.erreur || 'L’assistant n’a pas pu répondre.') + '</p>'; }
                        })
                        .catch(function () { corps.innerHTML = '<p class="iac-erreur">L’assistant n’a pas pu répondre. Réessayez dans un instant.</p>'; });
                }
                function fermer() { overlay.hidden = true; }
                document.addEventListener('click', function (e) {
                    var b = e.target.closest('button.ia-cpt'); if (!b) return;
                    e.preventDefault();
                    ouvrir(b.getAttribute('data-nom') || 'Compte QuickBooks', parseInt(b.getAttribute('data-id'), 10), b.getAttribute('data-cie'));
                });
                document.getElementById('iacFermer').addEventListener('click', fermer);
                document.getElementById('iacFermer2').addEventListener('click', fermer);
                overlay.addEventListener('click', function (e) { if (e.target === overlay) fermer(); });
                document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !overlay.hidden) fermer(); });
                document.getElementById('iacCopier').addEventListener('click', function () {
                    if (!texteBrut) return;
                    if (navigator.clipboard) navigator.clipboard.writeText(titre.textContent + '\n\n' + texteBrut);
                });
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

        <div class="pc-note">
            <b>Ce qui n'est pas ici.</b> Les classes et sous-classes (T120) et les journaux (T130) du modèle ne se modifient pas
            dans cette page. Les compagnies déjà créées ne sont jamais resynchronisées : un compte ajouté ici n'apparaît pas chez elles.
            Le drapeau <span class="pill sys">système</span> marque les comptes que l'application utilise elle-même
            (banque principale, taxes, comptes clients et fournisseurs…) : on peut les renommer, pas les retirer.
        </div>
    </div>
</asp:Content>
