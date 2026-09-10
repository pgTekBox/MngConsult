<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="AppliquerPlanComptable.aspx.vb" Inherits="MngConsul.AppliquerPlanComptable" %>

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

    .src-n { font-weight: 700; color: #0f172a }
    .nature { font-size: 11px; color: #94a3b8; text-transform: uppercase; letter-spacing: .3px }

    .cls-in { width: 100%; min-width: 260px; padding: 6px 8px; border: 1px solid #cbd5e1;
              border-radius: 8px; font-size: 12.5px; font-family: inherit }
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

    .lien-retour { font-size: 12.5px; color: #2563eb; text-decoration: none; margin-left: auto }
    .lien-retour:hover { text-decoration: underline }

    .alert { display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px;
             margin-bottom: 14px; font-size: 13.5px; line-height: 1.55 }
    .alert .ai { font-size: 17px; line-height: 1 }
    .alert-ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .alert-ko { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .alert-wa { background: #fffbeb; border: 1px solid #fde68a; color: #92400e }

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

    <asp:Panel ID="pnlSucces" runat="server" Visible="false" CssClass="alert alert-ok">
        <span class="ai">✅</span><div><asp:Literal ID="litSucces" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="alert alert-ko">
        <span class="ai">⛔</span><div><asp:Literal ID="litErreur" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlAvertissement" runat="server" Visible="false" CssClass="alert alert-wa">
        <span class="ai">⚠️</span><div><asp:Literal ID="litAvertissement" runat="server" /></div>
    </asp:Panel>

    <div class="card">
        <div class="bar-top">
            <div class="fld">
                <label>Lot à appliquer</label>
                <asp:DropDownList ID="ddlLot" runat="server" AutoPostBack="true" Width="420" />
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
                        <th style="width:300px">Classe — où le ranger</th>
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
                                    <div class="src-n"><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></div>
                                    <div class="nature"><%# Server.HtmlEncode(Convert.ToString(Eval("TypeNormalise"))) %></div>
                                </td>
                                <td>
                                    <asp:DropDownList runat="server" ID="ddlClasse" CssClass="cls-in" />
                                    <span class="plage">la plage de la classe fixe le numéro</span>
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
</asp:Content>
