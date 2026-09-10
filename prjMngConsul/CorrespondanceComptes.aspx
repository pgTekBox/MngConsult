<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="CorrespondanceComptes.aspx.vb" Inherits="MngConsul.CorrespondanceComptes" %>
<%@ Register Src="~/Controls/EtapesReprise.ascx" TagPrefix="uc" TagName="EtapesReprise" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Correspondance des comptes — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .cor-page { max-width: 1280px; margin: 0 auto; padding: 16px }

    .cor-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .cor-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(16,185,129,.14), rgba(37,99,235,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .cor-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .cor-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .cor-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 800px; line-height: 1.6 }

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

    .alert { display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px; margin-bottom: 14px; font-size: 13.5px }
    .alert .ai { flex: 0 0 auto; font-size: 16px }
    .alert-ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .alert-ko { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .alert-wa { background: #fffbeb; border: 1px solid #fde68a; color: #78350f }

    .btn { padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700; border: 1px solid transparent; cursor: pointer; font-family: inherit }
    .btn-p { background: #2563eb; color: #fff }
    .btn-s { background: #f1f5f9; color: #334155; border-color: #e2e8f0 }

    .acts { display: flex; gap: 9px; flex-wrap: wrap; align-items: center }

    table.cor { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.cor th { background: #f8fafc; text-align: left; padding: 9px 10px; font-weight: 700; color: #334155; white-space: nowrap; border-bottom: 1px solid #e2e8f0; position: sticky; top: 0; z-index: 1 }
    table.cor td { padding: 6px 10px; border-bottom: 1px solid #f1f5f9; vertical-align: middle }
    table.cor tr:last-child td { border-bottom: 0 }
    table.cor tr.decide td { background: #f8fafc }

    table.cor .src-c { font-weight: 700; color: #0f172a; white-space: nowrap }
    table.cor .sans-num { font-weight: 400; font-size: 11px; color: #94a3b8; font-style: italic; white-space: nowrap }
    table.cor .src-n { color: #475569 }
    table.cor .nature { font-size: 11px; color: #64748b; white-space: nowrap }
    table.cor .solde { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums }

    table.cor select, table.cor input[type=text] {
        padding: 5px 8px; border: 1px solid #cbd5e1; border-radius: 7px;
        font-size: 12.5px; font-family: inherit; background: #fff;
    }

    table.cor input.cpt-in { width: 110px }
    table.cor input.note-in { width: 100% ; min-width: 120px }
    table.cor select.act { width: 108px }

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
    .cls-f { width: 100%; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 11.5px; font-family: inherit; background: #fff }
    .scls-f { width: 100%; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 11.5px; font-family: inherit; background: #fff }
    .cpt-sel { width: 100%; padding: 5px 6px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 12px; font-family: inherit; background: #fff }
    .cls { display: block; margin-top: 2px; font-size: 10.5px; color: #64748b; font-weight: 700; letter-spacing: .2px }
    .ia-raison { display: block; margin-top: 2px; font-size: 10.5px; color: #64748b; font-style: italic }
    .ia-conf { font-size: 10.5px; color: #6d28d9; font-weight: 700 }
    .ia-autre { display: block; margin-top: 3px; font-size: 10.5px; color: #6d28d9 }

    .btn-ia { background: #6d28d9; color: #fff; border-color: #6d28d9 }
    .btn-ia:hover { background: #5b21b6 }

    .tbl-wrap { overflow-x: auto; max-height: 640px; overflow-y: auto; border: 1px solid #e2e8f0; border-radius: 12px }

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
        Pour chaque compte de votre ancien logiciel, dites à quel compte de votre plan
        il correspond — ou s'il faut le créer. La page propose ce qu'elle peut,
        <b>elle ne tranche jamais à votre place</b> : une correspondance fausse
        déplacerait des montants sans que rien ne le signale. Rien n'est encore écrit
        dans votre comptabilité.
    </p>

    <asp:Panel ID="pnlSucces" runat="server" Visible="false" CssClass="alert alert-ok">
        <span class="ai">✅</span><div><asp:Literal ID="litSucces" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlAvertissement" runat="server" Visible="false" CssClass="alert alert-wa">
        <span class="ai">⚠️</span><div><asp:Literal ID="litAvertissement" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="alert alert-ko">
        <span class="ai">❌</span><div><asp:Literal ID="litErreur" runat="server" /></div>
    </asp:Panel>

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
                <asp:DropDownList ID="ddlLot" runat="server" AutoPostBack="true" Width="380" />
            </div>
            <div class="fld">
                <label>Afficher</label>
                <asp:DropDownList ID="ddlFiltre" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="" Text="Tout" />
                    <asp:ListItem Value="A_DECIDER" Text="À décider seulement" />
                    <asp:ListItem Value="DECIDE" Text="Déjà décidés" />
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
                        <th style="width:118px">Action</th>
                        <th style="width:210px">Classe</th>
                        <th style="width:210px">Sous-classe</th>
                        <th style="width:150px">Compte chez vous</th>
                        <th>Note</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptLignes" runat="server">
                        <ItemTemplate>
                            <tr class='<%# If(EstDecide(Eval("Origine")), "decide", "") %>'>
                                <td><%# Eval("LigneNo") %></td>
                                <td class="src-c"><%# CleAffichee(Eval("Compte"), Eval("TypeCle")) %></td>
                                <td>
                                    <div class="src-n"><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></div>
                                    <div class="nature"><%# Server.HtmlEncode(Convert.ToString(Eval("TypeNormalise"))) %></div>
                                </td>
                                <td class="solde"><%# If(Eval("Solde") Is DBNull.Value, "", Convert.ToDecimal(Eval("Solde")).ToString("N2")) %></td>
                                <td><%# TexteProposition(Eval("Origine"), Eval("ProposeCompte"), Eval("ProposeNom"),
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
                                        SelectedValue='<%# ActionChoisie(Eval("Action")) %>'>
                                        <asp:ListItem Value="" Text="— à décider" />
                                        <asp:ListItem Value="LIER" Text="Lier" />
                                        <asp:ListItem Value="CREER" Text="Créer" />
                                        <asp:ListItem Value="IGNORER" Text="Ignorer" />
                                    </asp:DropDownList>
                                </td>

                                <td>
                                    <asp:DropDownList runat="server" ID="ddlClasseFiltre" CssClass="cls-f" />
                                </td>

                                <td>
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
                <b>Créer</b> l'ajoutera à votre plan lors de l'application.
                <b>Ignorer</b> l'écarte — utile pour les comptes techniques de l'ancien
                logiciel. Un « Lier » vers un numéro que votre plan ne connaît pas
                n'est pas enregistré.
            </p>
        </div>

        <div class="barre-bas">
            <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer les correspondances"
                CssClass="btn btn-p" CausesValidation="false" />
            <asp:HyperLink ID="hlAppliquer" runat="server" CssClass="lien-suite" Text="Créer les comptes au plan →" />
            <span style="font-size:12.5px;color:#64748b">
                Rien n'est écrit dans votre comptabilité : les décisions sont conservées à part.
            </span>
        </div>
    </asp:Panel>

</div>

<script type="text/javascript">
    // Le plan de la compagnie, écrit par le serveur. Un Literal plutôt qu'un
    // bloc de code inline : sur les pages à panneau Telerik ceux-ci cassent le
    // rendu, et l'habitude vaut mieux que l'exception.
    var PLAN = <asp:Literal ID="litPlanJson" runat="server" Text="{}" />;
    var PLAN_CLS = <asp:Literal ID="litPlanClsJson" runat="server" Text="{}" />;
    var PLAN_MERE = <asp:Literal ID="litPlanMereJson" runat="server" Text="{}" />;
    var SOUS_CLASSES = <asp:Literal ID="litSousClassesJson" runat="server" Text="[]" />;

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

                cls.addEventListener('change', function () { remplirSousClasses(); remplirComptes(); });
                scl.addEventListener('change', remplirComptes);

                remplirSousClasses();
                remplirComptes();
            })(lignes[i]);
        }
    })();

</script>
</asp:Content>
