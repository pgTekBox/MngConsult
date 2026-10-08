<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="CorrespondanceComptes.aspx.vb" Inherits="MngConsul.CorrespondanceComptes" %>
<%@ Register Src="~/Controls/EtapesReprise.ascx" TagPrefix="uc" TagName="EtapesReprise" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Correspondance des comptes — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cor-page { padding: 16px }

    .cor-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .cor-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(16,185,129,.14), rgba(37,99,235,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .cor-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .cor-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .cor-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; line-height: 1.6 }
    .ia-note { font-size: 12.5px; color: #6b21a8; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 6px; padding: 8px 12px; margin: 0 0 14px; line-height: 1.55 }

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

    .avance { margin-top: 16px }

    .avance .lbl { display: flex; justify-content: space-between; font-size: 12.5px; color: #64748b; margin-bottom: 5px }
    .avance .lbl b { color: #0f172a }

    .piste { height: 8px; background: #f1f5f9; border-radius: 999px; overflow: hidden }
    .piste > div { height: 100%; background: linear-gradient(90deg, #2563eb, #06b6d4); border-radius: 999px; transition: width .3s }

    .compteurs { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin-top: 14px }

    .cpt { border: 1px solid #e2e8f0; border-radius: 10px; padding: 9px 12px; background: #fff }
    .cpt .l { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; color: #64748b }
    .cpt .v { font-size: 20px; font-weight: 800; color: #0f172a; margin-top: 1px }
    .cpt.att { background: #fffbeb; border-color: #fde68a } .cpt.att .v { color: #b45309 }
    .cpt.ok { background: #ecfdf5; border-color: #a7f3d0 } .cpt.ok .v { color: #047857 }

    .btn { padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700; border: 1px solid transparent; cursor: pointer; font-family: inherit }
    .btn-p { background: #2563eb; color: #fff }
    .btn-s { background: #f1f5f9; color: #334155; border-color: #e2e8f0 }

    .acts { display: flex; gap: 9px; flex-wrap: wrap; align-items: center }

    table.cor { width: 100%; min-width: 1900px; border-collapse: collapse; font-size: 12.5px }
    table.cor th { background: #f8fafc; text-align: left; padding: 9px 10px; font-weight: 700; color: #334155; white-space: nowrap; border-bottom: 1px solid #e2e8f0; position: sticky; top: 0; z-index: 1 }
    table.cor td { padding: 6px 10px; border-bottom: 1px solid #f1f5f9; vertical-align: middle }
    table.cor tr:last-child td { border-bottom: 0 }
    table.cor tr.decide td { background: #f8fafc }

    table.cor .src-c { font-weight: 700; color: #0f172a; white-space: nowrap }
    table.cor .sans-num { font-weight: 400; font-size: 11px; color: #94a3b8; font-style: italic; white-space: nowrap }
    table.cor .src-n { color: #475569 }
    /* Bouton Assistant sur chaque compte source, et la fenêtre flottante qui montre la réponse. */
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
    table.cor .nature { font-size: 11px; color: #64748b; white-space: nowrap }
    table.cor .solde { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums }

    table.cor select, table.cor input[type=text] {
        padding: 5px 8px; border: 1px solid #cbd5e1; border-radius: 7px;
        font-size: 12.5px; font-family: inherit; background: #fff;
    }

    table.cor input.cpt-in { width: 110px }
    table.cor input.note-in { width: 100% ; min-width: 120px }
    table.cor select.act { width: 120px }
    table.cor .avert-ign { margin-top: 4px; max-width: 220px; padding: 4px 6px; border-radius: 6px; background: #fffbeb; border: 1px solid #fde68a; color: #78350f; font-size: 11px; line-height: 1.35 }
    table.cor .avert-ign[hidden] { display: none }

    .nom-cible { font-size: 11.5px; color: #047857; display: block; margin-top: 2px; min-height: 14px }
    .nom-cible.inconnu { color: #b45309 }

    .pr { display: inline-block; padding: 1px 7px; border-radius: 999px; font-size: 10.5px; font-weight: 800; margin-right: 5px }
    .pr-sur { background: #ecfdf5; color: #047857 }
    .pr-moyen { background: #fffbeb; color: #b45309 }
    .pr-aucun { background: #f1f5f9; color: #64748b }
    .pr-ia { background: #f5f3ff; color: #6d28d9 }
    .lien-suite { padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700; background: #047857; color: #fff; text-decoration: none; white-space: nowrap }
    .lien-suite:hover { background: #065f46; color: #fff }

    /* Ce que l'IA avance, et pourquoi. Deliberement discret : c'est un avis,
       pas un verdict. */
    /* La classe du compte propose, sous son nom. */
    .cls-f { width: 100%; min-width: 320px; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 11.5px; font-family: inherit; background: #fff }
    .cls-cell .cls-f { display: block; margin-bottom: 4px }
    .cls-cell .scls-f { display: block }
    .scls-f { width: 100%; min-width: 320px; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 11.5px; font-family: inherit; background: #fff }
    .cpt-sel { width: 100%; min-width: 240px; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 12px; font-family: inherit; background: #fff }
    .cls { display: block; margin-top: 2px; font-size: 10.5px; color: #64748b; font-weight: 700; letter-spacing: .2px }
    .ia-raison { display: block; margin-top: 2px; font-size: 10.5px; color: #64748b; font-style: italic }
    .ia-conf { font-size: 10.5px; color: #6d28d9; font-weight: 700 }
    .ia-autre { display: block; margin-top: 3px; font-size: 10.5px; color: #6d28d9 }

    .btn-ia { background: #6d28d9; color: #fff; border-color: #6d28d9 }
    .btn-ia:hover { background: #5b21b6 }

    .tbl-wrap { overflow-x: auto; max-height: 75vh; overflow-y: auto; border: 1px solid #e2e8f0; border-radius: 12px }

    .vide { text-align: center; padding: 34px; color: #64748b; font-size: 13.5px }

    .rappel { display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px; background: #f8fafc; border: 1px solid #e2e8f0; color: #475569; font-size: 13px; margin-top: 14px }
    .rappel p { margin: 0 }

    .barre-bas {
        position: sticky; bottom: 0; background: rgba(255,255,255,.94);
        backdrop-filter: blur(8px); border-top: 1px solid #e2e8f0;
        padding: 12px 0; margin-top: 14px; display: flex; gap: 10px; align-items: center;
    }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="cor-page">

    <uc:EtapesReprise ID="ucEtapes" runat="server" Etape="2" />

    <div class="cor-head">
        <div class="ico">🔗</div>
        <div>
            <h1>Correspondance des comptes</h1>
            <div class="sub">Étape 2 de la reprise comptable</div>
        </div>
    </div>

    <p class="cor-lede">
        Pour chaque compte de l'ancien logiciel, choisissez le compte de votre plan qui lui correspond, ou créez-le.
        La page propose, <b>vous décidez</b> : rien n'est encore écrit dans votre comptabilité.
    </p>

    <asp:Panel ID="pnlAucunLot" runat="server" Visible="false" CssClass="card">
        <div class="vide">
            Aucun plan comptable n'a encore été chargé pour cette compagnie.<br />
            <a href="ImportPlanComptable.aspx">Commencez par l'étape 1 — importer le plan comptable</a>.
        </div>
    </asp:Panel>

    <!-- ══════════ AVANCEMENT ══════════ -->
    <div class="card">
        <div class="bar-top">
            <div class="fld">
                <label>Lot à traiter</label>
            </div>
            <div class="fld">
                <label>Afficher</label>
                <asp:DropDownList ID="ddlFiltre" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="" Text="Tout" />
                    <asp:ListItem Value="A_DECIDER" Text="À décider seulement" />
                    <asp:ListItem Value="DECIDE" Text="Déjà décidés" />
                    <asp:ListItem Value="ORIGINE:AJOUTE" Text="Ajoutés après l'ouverture" />
                    <asp:ListItem Value="ORIGINE:DEFAUT" Text="Par défaut dans QuickBooks" />
                </asp:DropDownList>
            </div>
            <div class="acts" style="margin-left:auto">
                <asp:Button ID="btnIA" runat="server" CssClass="btn btn-ia" CausesValidation="false"
                    Text="✨ Proposer avec l'IA"
                    OnClientClick="if (!confirm('Soumettre les comptes encore à décider et votre plan comptable à l&#39;IA ?\n\nElle ne fera que proposer : rien ne sera décidé à votre place.')) { return false; }" />
                <asp:Button ID="btnAccepter" runat="server" CssClass="btn btn-s" CausesValidation="false"
                    Text="Accepter les correspondances par numéro"
                    OnClientClick="if (!confirm('Retenir toutes les correspondances où le numéro de compte concorde ?')) { return false; }" />
            </div>
        </div>

        <p class="ia-note">
            ✨ <b>Proposer avec l'IA</b> lui soumet, pour chaque compte encore à décider : le nom
            complet, la nature, le type et le sous-type QuickBooks, l'origine (par défaut ou ajouté,
            et quand), le solde et la description — et votre plan entier : numéro, noms, nature,
            classe, sous-classe, sens et description. Elle rend un compte proposé, une confiance et
            une raison ; la page vérifie que le compte existe et que la nature concorde, et vous tranchez.
        </p>

        <div class="avance">
            <div class="lbl">
                <span>Avancement</span>
                <span><b><asp:Literal ID="litDecides" runat="server" Text="0" /></b>
                    sur <asp:Literal ID="litTotal" runat="server" Text="0" />
                    (<asp:Literal ID="litPct" runat="server" Text="0" />&nbsp;%)</span>
            </div>
            <div class="piste"><div id="divBarre" runat="server" style="width:0%"></div></div>
        </div>

        <div class="compteurs">
            <div class="cpt att">
                <div class="l">À décider</div>
                <div class="v"><asp:Literal ID="litADecider" runat="server" Text="0" /></div>
            </div>
            <div class="cpt ok">
                <div class="l">Liés</div>
                <div class="v"><asp:Literal ID="litLies" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">À créer</div>
                <div class="v"><asp:Literal ID="litACreer" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">Ignorés</div>
                <div class="v"><asp:Literal ID="litIgnores" runat="server" Text="0" /></div>
            </div>
            <div class="cpt">
                <div class="l">Comptes au plan</div>
                <div class="v"><asp:Literal ID="litNbComptesPlan" runat="server" Text="0" /></div>
            </div>
        </div>

        <asp:Panel ID="pnlTermine" runat="server" Visible="false" CssClass="rappel" style="background:#ecfdf5;border-color:#a7f3d0;color:#065f46">
            <span>🎉</span>
            <p>
                <b>Tous les comptes sont décidés.</b> La correspondance est prête à être
                relue et signée par votre comptable. Elle servira ensuite à rattacher
                les factures et les écritures que vous importerez.
            </p>
        </asp:Panel>
    </div>

    <!-- ══════════ LES LIGNES ══════════ -->
    <asp:Panel ID="pnlVide" runat="server" Visible="false" CssClass="card">
        <div class="vide">Rien à afficher avec ce filtre.</div>
    </asp:Panel>

    <asp:Panel ID="pnlLignes" runat="server" Visible="false" CssClass="card">

        <div class="tbl-wrap">
            <table class="cor">
                <thead>
                    <tr>
                        <th style="width:34px">#</th>
                        <th colspan="2">Compte de l'ancien logiciel</th>
                        <th class="solde">Solde</th>
                        <th>Ce que nous proposons</th>
                        <th style="width:130px">Action</th>
                        <th style="width:320px">Classe / Sous-classe</th>
                        <th style="width:240px">Compte chez vous</th>
                        <th>Note</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptLignes" runat="server">
                        <ItemTemplate>
                            <tr class='<%# If(EstDecide(Eval("Origine")), "decide", "") %>' data-cree='<%# If(EstCree(Container.DataItem), "1", "0") %>' data-solde='<%# If(Eval("Solde") Is DBNull.Value, "0", Convert.ToDecimal(Eval("Solde")).ToString(System.Globalization.CultureInfo.InvariantCulture)) %>'>
                                <td><%# Eval("LigneNo") %></td>
                                <td class="src-c"><%# CleAffichee(Eval("Compte"), Eval("TypeCle")) %></td>
                                <td>
                                    <div class="src-n"><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %><button type="button" class="ia-cpt" data-id='<%# Eval("StagingId") %>' title="Assistant : que représente ce compte et où le ranger ?" aria-label="Assistant pour ce compte">✨ Assistant</button></div>
                                    <%# FicheSource(Container.DataItem) %>
                                </td>
                                <td class="solde"><%# If(Eval("Solde") Is DBNull.Value, "", Convert.ToDecimal(Eval("Solde")).ToString("N2")) %></td>
                                <td><%# TexteCree(Container.DataItem) %><%# TexteLieDOffice(Container.DataItem) %><%# TexteProposition(Eval("Origine"), Eval("ProposeCompte"), Eval("ProposeNom"),
                                                         Eval("ProposeClasse"), Eval("ProposeClasseNom"),
                                                         Eval("IACompte"), Eval("IANom"), Eval("IAConfiance"), Eval("IARaison"),
                                                         Eval("IAClasse"), Eval("IAClasseNom")) %></td>

                                <td>
                                    <asp:HiddenField runat="server" ID="hfCleSource" Value='<%# Eval("CleSource") %>' />
                                    <asp:HiddenField runat="server" ID="hfTypeCle" Value='<%# Eval("TypeCle") %>' />
                                    <asp:HiddenField runat="server" ID="hfCompteSource" Value='<%# Eval("Compte") %>' />
                                    <asp:HiddenField runat="server" ID="hfNomSource" Value='<%# Eval("Nom") %>' />
                                    <asp:HiddenField runat="server" ID="hfTypeSource" Value='<%# Eval("TypeNormalise") %>' />

                                    <asp:DropDownList runat="server" ID="ddlAction" CssClass="act"
                                        SelectedValue='<%# ActionChoisie(Eval("Action"), Eval("Origine")) %>'>
                                        <asp:ListItem Value="" Text="— à décider" />
                                        <asp:ListItem Value="LIER" Text="Lier" />
                                        <asp:ListItem Value="CREER" Text="Créer" />
                                        <asp:ListItem Value="IGNORER" Text="Ignorer" />
                                    </asp:DropDownList>
                                    <div class="avert-ign" hidden>⚠️ <span class="avert-ign-t"></span></div>
                                </td>

                                <td class="cls-cell">
                                    <asp:DropDownList runat="server" ID="ddlClasseFiltre" CssClass="cls-f" />
                                    <select class="scls-f"></select>
                                </td>

                                <td>
                                    <select class="cpt-sel"></select>
                                    <asp:HiddenField runat="server" ID="hfCompte"
                                        Value='<%# CompteChoisi(Eval("Action"), Eval("CompteCible"), Eval("ProposeCompte")) %>' />
                                </td>

                                <td>
                                    <asp:TextBox runat="server" ID="txtNote" CssClass="note-in" MaxLength="500"
                                        Text='<%# Eval("Note") %>' />
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>
        </div>

        <div class="rappel">
            <span>💡</span>
            <p>
                <b>Lier</b> rattache le compte à un compte existant chez vous.
                <b>Créer</b> l'ajoutera à votre plan lors de l'application, sous un numéro
                attribué à l'étape suivante — un numéro que votre plan connaît déjà est refusé.
                <b>Ignorer</b> l'écarte — utile pour les comptes techniques de l'ancien
                logiciel. Un « Lier » vers un numéro que votre plan ne connaît pas
                n'est pas enregistré. <b>Un compte chez vous ne reçoit qu'un seul compte</b>
                de l'ancien logiciel : deux comptes liés au même fusionneraient leurs soldes
                sans que rien ne le dise, alors la page le refuse.
            </p>
        </div>

        <div class="barre-bas">
            <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer les correspondances"
                CssClass="btn btn-p" CausesValidation="false"
                OnClientClick="if (!ciblesUniques()) { return false; }" />
            <asp:HyperLink ID="hlAppliquer" runat="server" CssClass="lien-suite" Text="Créer les comptes au plan →" />
            <span style="font-size:12.5px;color:#64748b">
                Rien n'est écrit dans votre comptabilité : les décisions sont conservées à part.
            </span>
        </div>
    </asp:Panel>

</div>

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
<script type="text/javascript">
    // Le plan de la compagnie, écrit par le serveur. Un Literal plutôt qu'un
    // bloc de code inline : sur les pages à panneau Telerik ceux-ci cassent le
    // rendu, et l'habitude vaut mieux que l'exception.
    var PLAN = <asp:Literal ID="litPlanJson" runat="server" Text="{}" />;
    var LOGICIEL = '<asp:Literal ID="litLogiciel" runat="server" Text="l’ancien logiciel" />';
    // Comptes source utilisés par des lignes de factures ou des produits en préparation (T304) : { clé: [lignes, produits] }.
    var USAGES = <asp:Literal ID="litUsagesJson" runat="server" Text="{}" />;
    function cleSource(tr) { var h = tr.querySelector('input[type=hidden][id*=_hfCleSource_]'); return h ? h.value : ''; }
    function texteUsage(u) {
        var p = [];
        if (u[0] > 0) p.push(u[0] + ' ligne(s) de facture');
        if (u[1] > 0) p.push(u[1] + ' produit(s)');
        return p.join(' et ');
    }
    var PLAN_CLS = <asp:Literal ID="litPlanClsJson" runat="server" Text="{}" />;
    var PLAN_MERE = <asp:Literal ID="litPlanMereJson" runat="server" Text="{}" />;
    var SOUS_CLASSES = <asp:Literal ID="litSousClassesJson" runat="server" Text="[]" />;

    // Un compte chez nous ne reçoit qu'un seul compte de l'ancien logiciel
    // (T275). La base le refuse de toute façon ; ici on le dit avant l'envoi,
    // avec les lignes en cause, pour ne pas perdre la saisie de la page.
    function ciblesUniques() {
        var lignes = document.querySelectorAll('tbody tr');
        // Un compte que la reprise utilise ne s'ignore pas : ses factures et produits n'auraient aucun compte (T304).
        var ignoresUtilises = [];
        for (var u = 0; u < lignes.length; u++) {
            var trU = lignes[u];
            if (trU.getAttribute('data-cree') === '1') continue;
            var actU = trU.querySelector('select.act');
            if (!actU || actU.value !== 'IGNORER') continue;
            var usage = USAGES[cleSource(trU)];
            if (!usage) continue;
            var noU = trU.querySelector('td') ? trU.querySelector('td').textContent.trim() : String(u + 1);
            var srcU = trU.querySelector('.src-n');
            var nomU = srcU && srcU.firstChild && srcU.firstChild.nodeType === 3 ? srcU.firstChild.textContent.trim() : '';
            ignoresUtilises.push('ligne ' + noU + ' : « ' + nomU + ' » de ' + LOGICIEL + ' est utilisé par ' + texteUsage(usage));
        }
        if (ignoresUtilises.length > 0) {
            showAppMessage('Un compte de ' + LOGICIEL + ' utilisé par une facture ou un produit en préparation ne peut pas être ignoré : ces éléments n\'auraient aucun compte.\n\n'
                + ignoresUtilises.join('\n') + '\n\nLiez-le à un compte de 60sec, ou créez-le.', 'Enregistrement impossible');
            return false;
        }

        // Un compte qui porte un solde ne s'ignore pas : ce montant n'aurait nulle part où aller (T303).
        var ignoresAvecSolde = [];
        for (var s = 0; s < lignes.length; s++) {
            var trS = lignes[s];
            if (trS.getAttribute('data-cree') === '1') continue;
            var actS = trS.querySelector('select.act');
            if (!actS || actS.value !== 'IGNORER') continue;
            var solde = parseFloat(trS.getAttribute('data-solde') || '0');
            if (!solde) continue;
            var noS = trS.querySelector('td') ? trS.querySelector('td').textContent.trim() : String(s + 1);
            var srcS = trS.querySelector('.src-n');
            var nomS = srcS && srcS.firstChild && srcS.firstChild.nodeType === 3 ? srcS.firstChild.textContent.trim() : '';
            ignoresAvecSolde.push('ligne ' + noS + ' : « ' + nomS + ' » de ' + LOGICIEL + ' porte un solde de ' + solde.toLocaleString('fr-CA', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' $');
        }
        if (ignoresAvecSolde.length > 0) {
            showAppMessage('Un compte de ' + LOGICIEL + ' qui porte un solde ne peut pas être ignoré : ce montant disparaîtrait de la reprise.\n\n'
                + ignoresAvecSolde.join('\n') + '\n\nLiez-le à un compte de 60sec, ou créez-le.', 'Enregistrement impossible');
            return false;
        }
        var parCible = {};
        for (var i = 0; i < lignes.length; i++) {
            var tr = lignes[i];
            if (tr.getAttribute('data-cree') === '1') continue;
            var act = tr.querySelector('select.act');
            var hid = tr.querySelector('input[type=hidden][id*=_hfCompte_]');
            if (!act || !hid || act.value !== 'LIER' || hid.value === '') continue;
            var no = tr.querySelector('td') ? tr.querySelector('td').textContent.trim() : String(i + 1);
            var srcN = tr.querySelector('.src-n');
            var nom = srcN && srcN.firstChild && srcN.firstChild.nodeType === 3 ? srcN.firstChild.textContent.trim() : '';
            if (!parCible[hid.value]) parCible[hid.value] = [];
            parCible[hid.value].push('ligne ' + no + (nom ? ' (' + nom + ')' : ''));
        }
        var fautes = [];
        for (var c in parCible) {
            if (!parCible.hasOwnProperty(c) || parCible[c].length < 2) continue;
            fautes.push('Compte ' + c + (PLAN[c] ? ' — ' + PLAN[c] : '') + ' de 60sec : ' + parCible[c].join(', ') + ' de ' + LOGICIEL);
        }
        if (fautes.length > 0) {
            showAppMessage('Un compte de 60sec ne reçoit qu\'un seul compte de ' + LOGICIEL + '.\n\n'
                + fautes.join('\n') + '\n\nLiez les autres ailleurs, ou créez-les.', 'Enregistrement impossible');
            return false;
        }

        // « Créer » avec un compte choisi dans la liste : ce compte existe
        // déjà, on ne le crée pas une seconde fois (T276). C'est « Lier »
        // qu'il faut, ou laisser le compte vide.
        var creerPris = [];
        for (var k = 0; k < lignes.length; k++) {
            var tr2 = lignes[k];
            if (tr2.getAttribute('data-cree') === '1') continue;
            var act2 = tr2.querySelector('select.act');
            var hid2 = tr2.querySelector('input[type=hidden][id*=_hfCompte_]');
            if (!act2 || !hid2 || act2.value !== 'CREER' || hid2.value === '') continue;
            if (!PLAN.hasOwnProperty(hid2.value)) continue;
            var no2 = tr2.querySelector('td') ? tr2.querySelector('td').textContent.trim() : String(k + 1);
            creerPris.push('ligne ' + no2 + ' : le numéro ' + hid2.value + ' — ' + PLAN[hid2.value] + ' existe déjà');
        }
        if (creerPris.length > 0) {
            showAppMessage('« Créer » ne peut pas reprendre un numéro que votre plan 60sec connaît déjà.\n\n'
                + creerPris.join('\n')
                + '\n\nPour le rattacher à ce compte, choisissez « Lier ». Pour en créer un nouveau, laissez le compte vide : le numéro sera attribué à l\'étape suivante.', 'Enregistrement impossible');
            return false;
        }
        return true;
    }

    // Le plan se lit en trois crans : la grande classe, puis la sous-classe,
    // puis le compte. Chacun restreint le suivant. Sans cela le champ propose
    // les 227 comptes d'un coup, et on n'y retrouve rien.
    (function () {
        var lignes = document.querySelectorAll('tbody tr');
        var n = 0;

        for (var i = 0; i < lignes.length; i++) {
            (function (tr) {
                var cls = tr.querySelector('select.cls-f');
                var scl = tr.querySelector('select.scls-f');
                var sel = tr.querySelector('select.cpt-sel');
                var hid = tr.querySelector('input[type=hidden][id*=_hfCompte_]');
                // Compte déjà créé au plan (T277) : plus rien à choisir ici.
                if (tr.getAttribute('data-cree') === '1') {
                    if (scl) scl.style.display = 'none';
                    if (sel) sel.style.display = 'none';
                    return;
                }
                // Un compte qui porte un solde ne s'ignore pas (T303) : l'option est grisée,
                // sauf si c'est la décision déjà enregistrée, pour pouvoir la changer.
                var actI = tr.querySelector('select.act');
                if (actI && parseFloat(tr.getAttribute('data-solde') || '0')) {
                    var optI = actI.querySelector('option[value="IGNORER"]');
                    if (optI && actI.value !== 'IGNORER') { optI.disabled = true; optI.title = 'Ce compte porte un solde : il ne peut pas être ignoré.'; }
                }
                // Même chose pour un compte que des factures ou des produits en préparation utilisent (T304).
                var usageI = USAGES[cleSource(tr)];
                if (actI && usageI) {
                    var optU = actI.querySelector('option[value="IGNORER"]');
                    if (optU && actI.value !== 'IGNORER') { optU.disabled = true; optU.title = 'Ce compte est utilisé par ' + texteUsage(usageI) + ' en préparation : il ne peut pas être ignoré.'; }
                }
                // Revenus et dépenses à solde 0 : QuickBooks ne donne pas leur solde. Avertir, sans bloquer (T304).
                var avert = tr.querySelector('.avert-ign');
                var hfNat = tr.querySelector('input[type=hidden][id*=_hfTypeSource_]');
                var natureI = hfNat ? hfNat.value : '';
                function majAvertIgnorer() {
                    if (!avert || !actI) return;
                    var aRisque = actI.value === 'IGNORER' && (natureI === 'PRODUIT' || natureI === 'CHARGE')
                        && !parseFloat(tr.getAttribute('data-solde') || '0') && !usageI;
                    if (aRisque) {
                        avert.querySelector('.avert-ign-t').textContent = LOGICIEL + ' ne donne pas le solde des comptes de revenus et de dépenses : vérifiez que ce compte n\'a pas servi avant de l\'ignorer.';
                    }
                    avert.hidden = !aRisque;
                }
                if (actI) { actI.addEventListener('change', majAvertIgnorer); majAvertIgnorer(); }
                if (!cls || !scl || !sel || !hid) return;

                // 2e cran : les sous-classes de la classe choisie.
                function remplirSousClasses() {
                    var k = cls.value;
                    while (scl.firstChild) { scl.removeChild(scl.firstChild); }

                    var vide = document.createElement('option');
                    vide.value = '';
                    vide.textContent = (k === '') ? 'toute la classe' : 'toutes les sous-classes';
                    scl.appendChild(vide);

                    for (var j = 0; j < SOUS_CLASSES.length; j++) {
                        var s = SOUS_CLASSES[j];
                        if (k !== '' && String(s.p) !== k) continue;
                        var o = document.createElement('option');
                        o.value = String(s.i);
                        o.textContent = s.t;
                        scl.appendChild(o);
                    }
                }

                // 3e cran : les comptes de la sous-classe choisie. Le choix
                // voyage dans un champ cache : le menu est rempli par le
                // navigateur, le serveur ne connait pas ses options.
                function remplirComptes() {
                    var sc = scl.value;
                    var k = cls.value;
                    var courant = hid.value;

                    while (sel.firstChild) { sel.removeChild(sel.firstChild); }

                    var vide = document.createElement('option');
                    vide.value = '';
                    vide.textContent = '— aucun —';
                    sel.appendChild(vide);

                    var vu = false;
                    for (var c in PLAN) {
                        if (!PLAN.hasOwnProperty(c)) continue;
                        if (sc !== '') { if (String(PLAN_CLS[c]) !== sc) continue; }
                        else if (k !== '') { if (String(PLAN_MERE[c]) !== k) continue; }

                        var o = document.createElement('option');
                        o.value = c;
                        o.textContent = c + ' — ' + PLAN[c];
                        sel.appendChild(o);
                        if (c === courant) vu = true;
                    }

                    // Le compte deja retenu reste choisissable meme si le
                    // filtre l'exclut : sinon un simple coup d'oeil aux
                    // classes effacerait une decision prise.
                    if (courant !== '' && !vu && PLAN.hasOwnProperty(courant)) {
                        var g = document.createElement('option');
                        g.value = courant;
                        g.textContent = courant + ' — ' + PLAN[courant] + '  (hors filtre)';
                        sel.appendChild(g);
                    }

                    sel.value = courant;
                }

                sel.addEventListener('change', function () { hid.value = sel.value; });

                // « Créer » n'a pas de compte chez nous à choisir : le compte
                // n'existe pas encore. Le choix précédent est effacé, sinon un
                // « Lier » devenu « Créer » demanderait de recréer un compte
                // qui existe (T276).
                var act = tr.querySelector('select.act');
                if (act) {
                    act.addEventListener('change', function () {
                        if (act.value === 'CREER') { hid.value = ''; sel.value = ''; }
                    });
                }

                cls.addEventListener('change', function () { remplirSousClasses(); remplirComptes(); });
                scl.addEventListener('change', remplirComptes);

                remplirSousClasses();
                remplirComptes();
            })(lignes[i]);
        }
    })();

</script>
</asp:Content>
