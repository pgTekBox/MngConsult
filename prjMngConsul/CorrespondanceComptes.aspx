<%@ Page Language="VB" AutoEventWireup="false" Async="true" MasterPageFile="~/Site.Master"
    CodeBehind="CorrespondanceComptes.aspx.vb" Inherits="MngConsul.CorrespondanceComptes" %>

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

    /* Ce que l'IA avance, et pourquoi. Deliberement discret : c'est un avis,
       pas un verdict. */
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
                                                         Eval("IACompte"), Eval("IANom"), Eval("IAConfiance"), Eval("IARaison")) %></td>

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
                                    <asp:TextBox runat="server" ID="txtCompte" CssClass="cpt-in" list="dlPlan"
                                        Text='<%# CompteChoisi(Eval("Action"), Eval("CompteCible"), Eval("ProposeCompte")) %>'
                                        onchange="majNom(this);" onkeyup="majNom(this);" />
                                    <span class="nom-cible"></span>
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
            <span style="font-size:12.5px;color:#64748b">
                Rien n'est écrit dans votre comptabilité : les décisions sont conservées à part.
            </span>
        </div>
    </asp:Panel>

    <datalist id="dlPlan"><asp:Literal ID="litPlanOptions" runat="server" /></datalist>
</div>

<script type="text/javascript">
    // Le plan de la compagnie, écrit par le serveur. Un Literal plutôt qu'un
    // bloc de code inline : sur les pages à panneau Telerik ceux-ci cassent le
    // rendu, et l'habitude vaut mieux que l'exception.
    var PLAN = <asp:Literal ID="litPlanJson" runat="server" Text="{}" />;

    // Affiche le nom du compte saisi, pour qu'on voie tout de suite si l'on
    // s'est trompé de numéro — c'est l'erreur qu'on ne rattrape plus après.
    function majNom(input) {
        var span = input.parentNode.querySelector('.nom-cible');
        if (!span) return;

        var v = (input.value || '').trim();
        if (v === '') { span.textContent = ''; span.className = 'nom-cible'; return; }

        if (PLAN.hasOwnProperty(v)) {
            span.textContent = PLAN[v];
            span.className = 'nom-cible';
        } else {
            span.textContent = 'ce numéro n’est pas à votre plan';
            span.className = 'nom-cible inconnu';
        }
    }

    (function () {
        var champs = document.querySelectorAll('input.cpt-in');
        for (var i = 0; i < champs.length; i++) { majNom(champs[i]); }
    })();
</script>
</asp:Content>
