<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ImportPlanComptable.aspx.vb" Inherits="MngConsul.ImportPlanComptable" %>
<%@ Register Src="~/Controls/EtapesReprise.ascx" TagPrefix="uc" TagName="EtapesReprise" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Importer le plan comptable — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .imp-page { max-width: 1150px; margin: 0 auto; padding: 16px }

    .imp-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .imp-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .imp-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .imp-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .imp-lede {
        font-size: 13.5px; color: #475569; margin: 0 0 18px;
        max-width: 760px; line-height: 1.6;
    }

    .step {
        background: #fff; border: 1px solid #e2e8f0; border-radius: 14px;
        padding: 20px; margin-bottom: 16px;
    }

    .step > h2 {
        font-size: 15px; font-weight: 800; margin: 0 0 3px; color: #0f172a;
        display: flex; align-items: center; gap: 9px;
    }

    .step > h2 .n {
        width: 24px; height: 24px; border-radius: 999px; flex: 0 0 auto;
        background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;
        font-size: 12px; display: flex; align-items: center; justify-content: center;
    }

    .step > .desc { font-size: 13px; color: #64748b; margin: 0 0 15px; padding-left: 33px }
    .step > .body { padding-left: 33px }

    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px }
    .grid3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px }

    .fld label { display: block; font-size: 12.5px; font-weight: 700; margin-bottom: 4px; color: #334155 }

    .fld select, .fld input[type=text] {
        width: 100%; padding: 8px 11px; border: 1px solid #cbd5e1;
        border-radius: 9px; font-size: 13px; font-family: inherit; background: #fff;
    }

    .fld .hint { font-size: 11.5px; color: #94a3b8; margin-top: 4px }

    /* Une seule ligne : la zone de dépôt n'a aucune raison d'occuper un tiers
       de l'écran, et le fichier choisi s'affiche dedans plutôt qu'en dessous. */
    .drop {
        display: flex; align-items: center; gap: 9px;
        border: 1.5px dashed #cbd5e1; border-radius: 10px; padding: 9px 13px;
        cursor: pointer; font-size: 13px; color: #475569;
        transition: border-color .15s, background .15s;
    }

    .drop:hover { border-color: #2563eb; background: rgba(37,99,235,.04) }
    .drop .di { font-size: 17px; line-height: 1 }
    .drop .dt { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .drop .dh { margin-left: auto; padding-left: 10px; font-size: 11.5px; color: #94a3b8; white-space: nowrap }

    /* Survol d'un fichier glissé. */
    .drop.over {
        border-style: solid; border-color: #2563eb;
        background: rgba(37,99,235,.08); color: #1d4ed8;
    }

    /* Un fichier est en place. */
    .drop.has { border-style: solid; border-color: #bfdbfe; background: rgba(37,99,235,.05) }
    .drop.has .dt b { color: #1e293b }

    .cbx { display: flex; align-items: center; gap: 7px; margin-top: 13px; font-size: 13px }

    .acts { display: flex; gap: 9px; flex-wrap: wrap; margin-top: 16px }

    .btn {
        padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700;
        border: 1px solid transparent; cursor: pointer; font-family: inherit;
    }

    .btn-p { background: #2563eb; color: #fff }
    .btn-s { background: #f1f5f9; color: #334155; border-color: #e2e8f0 }

    .alert {
        display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px;
        margin-bottom: 14px; font-size: 13.5px;
    }

    .alert .ai { flex: 0 0 auto; font-size: 16px }
    .alert-ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .alert-ko { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .alert-wa { background: #fffbeb; border: 1px solid #fde68a; color: #78350f }

    .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 4px }

    .stat { border: 1px solid #e2e8f0; border-radius: 11px; padding: 12px 14px; background: #fff }
    .stat .l { font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; color: #64748b }
    .stat .v { font-size: 23px; font-weight: 800; color: #0f172a; margin-top: 2px }
    .stat.wa { background: #fffbeb; border-color: #fde68a }
    .stat.wa .v { color: #b45309 }

    .tbl-wrap { overflow-x: auto; border: 1px solid #e2e8f0; border-radius: 12px; margin-top: 12px }

    table.g { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.g th { background: #f8fafc; text-align: left; padding: 9px 11px; font-weight: 700; color: #334155; white-space: nowrap; border-bottom: 1px solid #e2e8f0 }
    table.g td { padding: 7px 11px; border-bottom: 1px solid #f1f5f9; vertical-align: top }
    table.g tr:last-child td { border-bottom: 0 }
    table.g tr.row-ko td { background: #fef2f2 }
    table.g tr.row-info td { background: #f8fafc }

    table.map-table { border-collapse: collapse; font-size: 12.5px; margin-top: 6px }
    table.map-table th { text-align: left; padding: 5px 16px 5px 0; color: #64748b; font-weight: 700 }
    table.map-table td { padding: 4px 16px 4px 0; border-bottom: 1px solid #f1f5f9 }
    table.map-table .req { font-size: 10.5px; color: #b45309; font-weight: 700 }
    table.map-table .miss { color: #be123c; font-weight: 700 }
    table.map-table .none { color: #cbd5e1 }

    .pill { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap }
    .p-ok { background: #ecfdf5; color: #047857 }
    .p-ex { background: #eff6ff; color: #1d4ed8 }
    .p-ko { background: #fef2f2; color: #b91c1c }

    .note-staging {
        display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px;
        background: #f8fafc; border: 1px solid #e2e8f0; color: #475569;
        font-size: 13px; margin-top: 14px;
    }

    .note-staging p { margin: 0 }

    /* La suite du parcours. Sans cela l'écran ne dit nulle part où aller
       une fois le lot chargé, et l'étape suivante se cherche dans le menu. */
    .suite {
        display: flex; align-items: center; gap: 16px; flex-wrap: wrap;
        margin-top: 14px; padding: 14px 16px; border-radius: 11px;
        border: 1px solid #bfdbfe; background: linear-gradient(135deg, rgba(37,99,235,.07), rgba(6,182,212,.05));
    }

    .suite .txt { flex: 1 1 260px; min-width: 0 }
    .suite b { font-size: 13.5px; color: #1e293b }
    .suite p { margin: 3px 0 0; font-size: 12.5px; color: #475569 }

    .suite a {
        padding: 9px 16px; border-radius: 9px; font-size: 13px; font-weight: 700;
        background: #2563eb; color: #fff; text-decoration: none; white-space: nowrap;
    }

    .suite a:hover { background: #1d4ed8; color: #fff }

    /* ───── Aide ───── */
    .aide {
        margin-top: 14px; border: 1px solid #bfdbfe; border-radius: 12px;
        background: #f8fbff; overflow: hidden;
    }

    .aide > summary {
        cursor: pointer; padding: 12px 15px; font-size: 13.5px; font-weight: 700;
        color: #1d4ed8; list-style: none; display: flex; align-items: center; gap: 9px;
    }

    .aide > summary::-webkit-details-marker { display: none }
    .aide > summary:hover { background: #eff6ff }
    .aide .aide-ico { font-size: 15px }
    .aide .aide-chev { margin-left: auto; transition: transform .15s; font-size: 12px }
    .aide[open] .aide-chev { transform: rotate(180deg) }

    .aide-corps { padding: 4px 15px 16px; border-top: 1px solid #dbeafe }

    .aide-rapport { font-size: 13px; color: #334155; margin: 12px 0 0 }

    .aide-h {
        font-size: 12px; font-weight: 800; text-transform: uppercase;
        letter-spacing: .04em; color: #64748b; margin: 16px 0 7px;
    }

    .aide-p { font-size: 13px; color: #475569; margin: 0 0 8px; line-height: 1.55 }

    .aide-avert {
        display: flex; gap: 10px; margin-top: 12px; padding: 11px 13px;
        border-radius: 10px; background: #fffbeb; border: 1px solid #fde68a;
        color: #78350f; font-size: 13px; line-height: 1.55;
    }

    .aide-avert p { margin: 0 }
    .aide-avert span { flex: 0 0 auto }

    ol.aide-etapes { margin: 0; padding-left: 20px; font-size: 13px; color: #475569; line-height: 1.6 }
    ol.aide-etapes li { margin-bottom: 5px }

    ul.aide-astuces { margin: 0; padding-left: 20px; font-size: 13px; color: #475569; line-height: 1.6 }
    ul.aide-astuces li { margin-bottom: 5px }

    .col-wrap { overflow-x: auto; border: 1px solid #e2e8f0; border-radius: 10px; background: #fff }

    table.col-table { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.col-table th { background: #f8fafc; text-align: left; padding: 8px 11px; font-weight: 700; color: #334155; border-bottom: 1px solid #e2e8f0; white-space: nowrap }
    table.col-table td { padding: 7px 11px; border-bottom: 1px solid #f1f5f9; vertical-align: top }
    table.col-table tr:last-child td { border-bottom: 0 }
    table.col-table .kw { color: #64748b; font-size: 11.5px }

    .st-req { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 800; background: #fef2f2; color: #b91c1c; white-space: nowrap }
    .st-cle { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 800; background: #eff6ff; color: #1d4ed8; white-space: nowrap }
    .st-opt { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; background: #f1f5f9; color: #64748b; white-space: nowrap }

    .aide-modele {
        display: flex; align-items: center; gap: 14px; flex-wrap: wrap;
        margin-top: 16px; padding: 12px 14px; border-radius: 10px;
        background: #fff; border: 1px solid #e2e8f0;
    }

    .aide-modele > div { flex: 1 1 260px }
    .aide-modele b { font-size: 13px; color: #0f172a }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="imp-page">

    <uc:EtapesReprise ID="ucEtapes" runat="server" Etape="1" />

    <div class="imp-head">
        <div class="ico">📊</div>
        <div>
            <h1>Importer le plan comptable</h1>
            <div class="sub">Étape 1 de la reprise comptable</div>
        </div>
    </div>

    <p class="imp-lede">
        Déposez le plan comptable de votre ancien logiciel. Il sera lu, contrôlé et
        placé en préparation. <b>Rien n'est écrit dans votre plan comptable à cette
        étape</b> : la mise en correspondance des comptes se fait ensuite, et elle se
        décide avec votre comptable.
    </p>

    <!-- ══════════ MESSAGES ══════════ -->
    <asp:Panel ID="pnlSucces" runat="server" Visible="false" CssClass="alert alert-ok">
        <span class="ai">✅</span><div><asp:Literal ID="litSucces" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlAvertissement" runat="server" Visible="false" CssClass="alert alert-wa">
        <span class="ai">⚠️</span><div><asp:Literal ID="litAvertissement" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="alert alert-ko">
        <span class="ai">❌</span><div><asp:Literal ID="litErreur" runat="server" /></div>
    </asp:Panel>

    <!-- ══════════ 1 · D'OÙ VIENNENT LES DONNÉES ══════════ -->
    <div class="step">
        <h2><span class="n">1</span>D'où viennent vos données ?</h2>
        <p class="desc">Le séparateur et l'encodage sont ajustés pour vous — vous pouvez les changer.</p>
        <div class="body">
            <div class="grid3">
                <div class="fld">
                    <label>Logiciel d'origine</label>
                    <asp:DropDownList ID="ddlSysteme" runat="server" AutoPostBack="true" />
                </div>
                <div class="fld">
                    <label>Séparateur</label>
                    <asp:DropDownList ID="ddlSeparateur" runat="server">
                        <asp:ListItem Value=";" Text="Point-virgule  ;" />
                        <asp:ListItem Value="," Text="Virgule  ," />
                        <asp:ListItem Value="&#9;" Text="Tabulation" />
                    </asp:DropDownList>
                </div>
                <div class="fld">
                    <label>Encodage</label>
                    <asp:DropDownList ID="ddlEncodage" runat="server">
                        <asp:ListItem Value="UTF-8" Text="UTF-8" />
                        <asp:ListItem Value="Windows-1252" Text="Windows-1252 (ANSI)" />
                        <asp:ListItem Value="ISO-8859-1" Text="ISO-8859-1" />
                    </asp:DropDownList>
                    <div class="hint">Des accents en charabia = mauvais encodage</div>
                </div>
            </div>

            <div class="note-staging" style="margin-top:14px">
                <span>📍</span>
                <p>
                    Dans <b><asp:Literal ID="litNomSysteme" runat="server" /></b> :
                    <asp:Literal ID="litCheminExport" runat="server" />
                </p>
            </div>

            <!-- ── Aide : la partie propre au logiciel, puis ce qui vaut pour tous ── -->
            <asp:Panel ID="pnlAide" runat="server">
                <details class="aide" open>
                    <summary>
                        <span class="aide-ico">❓</span>
                        Comment sortir ce fichier de <b><asp:Literal ID="litAideTitre" runat="server" /></b>
                        <span class="aide-chev">▾</span>
                    </summary>
                    <div class="aide-corps">

                        <asp:Panel ID="pnlAideSysteme" runat="server">
                            <asp:Literal ID="litAideCorps" runat="server" />
                        </asp:Panel>

                        <asp:Panel ID="pnlAideAbsente" runat="server" Visible="false" CssClass="aide-avert" Style="background:#f8fafc;border-color:#e2e8f0;color:#475569">
                            <span>ℹ️</span>
                            <p><asp:Literal ID="litAideAbsente" runat="server" /></p>
                        </asp:Panel>

                        <h4 class="aide-h">Les colonnes attendues</h4>
                        <p class="aide-p">
                            Il faut de quoi identifier chaque compte : <b>son numéro, ou son nom</b>.
                            Le numéro sert de clé quand il existe, le nom le remplace sinon — beaucoup
                            de plans QuickBooks n'ont pas de numéros, et c'est parfaitement normal.
                            Une ligne qui n'a ni l'un ni l'autre est écartée.
                        </p>
                        <div class="col-wrap">
                            <asp:Literal ID="litTableauColonnes" runat="server" />
                        </div>

                        <p class="aide-p" style="margin-top:12px">
                            L'ordre des colonnes n'a pas d'importance : la page les reconnaît par leur
                            en-tête. Si aucun en-tête n'est reconnu, elle retombe sur l'ordre du tableau
                            ci-dessus. <b>Servez-vous du bouton « Voir un aperçu »</b> : il montre
                            exactement ce qu'elle a compris, avant que rien ne soit chargé.
                        </p>

                        <div class="aide-modele">
                            <div>
                                <b>Votre export ne ressemble à rien de tout ça ?</b>
                                <div class="aide-p" style="margin:2px 0 0">
                                    Partez du modèle, collez-y vos colonnes, et déposez-le.
                                </div>
                            </div>
                            <asp:Button ID="btnModele" runat="server" CssClass="btn btn-s"
                                Text="⬇ Télécharger un modèle CSV" CausesValidation="false" />
                        </div>
                    </div>
                </details>
            </asp:Panel>
        </div>
    </div>

    <!-- ══════════ 2 · LE FICHIER ══════════ -->
    <div class="step">
        <h2><span class="n">2</span>Le fichier</h2>
        <p class="desc">Un fichier CSV, une ligne par compte. 10 Mo au maximum.</p>
        <div class="body">

            <div class="drop" id="dropZone">
                <span class="di" id="dropIcone">📁</span>
                <span class="dt" id="dropTexte"><b>Glissez votre fichier ici</b> ou cliquez pour le choisir</span>
                <span class="dh" id="dropInfo">.csv ou .txt</span>
            </div>

            <asp:FileUpload ID="fuFichier" runat="server" Style="display:none" accept=".csv,.txt" />

            <div class="cbx">
                <asp:CheckBox ID="chkEntete" runat="server" Checked="true" />
                <label for="<%= chkEntete.ClientID %>">La première ligne contient les noms de colonnes</label>
            </div>

            <div class="acts">
                <asp:Button ID="btnApercu" runat="server" Text="Voir un aperçu" CssClass="btn btn-s" CausesValidation="false" />
                <asp:Button ID="btnCharger" runat="server" Text="Charger en préparation" CssClass="btn btn-p" CausesValidation="false" />
            </div>
        </div>
    </div>

    <!-- ══════════ APERÇU ══════════ -->
    <asp:Panel ID="pnlApercu" runat="server" Visible="false" CssClass="step">
        <h2><span class="n">👁</span>Aperçu</h2>
        <p class="desc"><asp:Literal ID="litApercuInfo" runat="server" /></p>
        <div class="body">

            <h3 style="font-size:13px;font-weight:800;margin:0 0 2px;color:#334155">Colonnes reconnues</h3>
            <asp:Literal ID="litCorrespondance" runat="server" />

            <div class="tbl-wrap">
                <asp:GridView ID="gvApercu" runat="server" AutoGenerateColumns="true"
                    CssClass="g" GridLines="None" UseAccessibleHeader="true" />
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ RÉSULTAT ══════════ -->
    <asp:Panel ID="pnlResultat" runat="server" Visible="false" CssClass="step">
        <h2><span class="n">✓</span>Résultat du chargement</h2>
        <div class="body">
            <div class="stats">
                <div class="stat">
                    <div class="l">Lignes lues</div>
                    <div class="v"><asp:Literal ID="litLues" runat="server" Text="0" /></div>
                </div>
                <div class="stat">
                    <div class="l">Comptes retenus</div>
                    <div class="v"><asp:Literal ID="litRetenues" runat="server" Text="0" /></div>
                </div>
                <div class="stat wa">
                    <div class="l">À regarder</div>
                    <div class="v"><asp:Literal ID="litAnomalies" runat="server" Text="0" /></div>
                </div>
            </div>

            <div class="note-staging">
                <span>🛡️</span>
                <p>
                    Ces comptes sont <b>en préparation</b>. Votre plan comptable n'a pas
                    changé. Vous pouvez recharger un autre fichier, ou abandonner ce lot,
                    sans aucune conséquence.
                </p>
            </div>

            <div class="suite">
                <div class="txt">
                    <b>Étape suivante — la correspondance des comptes</b>
                    <p>
                        Chaque compte lu doit maintenant être <b>lié</b> à un compte de votre
                        plan, <b>créé</b>, ou <b>ignoré</b>. Rien n'est écrit tant que vous
                        n'avez pas décidé.
                    </p>
                </div>
                <asp:HyperLink ID="hlCorrespondance" runat="server"
                    Text="Passer à la correspondance →" />
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ CE QUI EST EN PRÉPARATION ══════════ -->
    <asp:Panel ID="pnlLignes" runat="server" Visible="false" CssClass="step">
        <h2><span class="n">📋</span>Ce qui est en préparation</h2>
        <p class="desc">
            « Déjà au plan » n'est pas une erreur : ce compte existe chez vous, il sera
            mis en correspondance plutôt que créé.
        </p>
        <div class="body">

            <div class="fld" style="max-width:260px">
                <label>Afficher</label>
                <asp:DropDownList ID="ddlFiltre" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="" Text="Tout" />
                    <asp:ListItem Value="OK" Text="Nouveaux comptes" />
                    <asp:ListItem Value="EXISTE" Text="Déjà au plan" />
                    <asp:ListItem Value="DOUBLON_FICHIER" Text="Doublons du fichier" />
                    <asp:ListItem Value="INVALIDE" Text="Lignes invalides" />
                </asp:DropDownList>
            </div>

            <div class="tbl-wrap">
                <asp:GridView ID="gvLignes" runat="server" AutoGenerateColumns="false"
                    CssClass="g" GridLines="None" UseAccessibleHeader="true">
                    <Columns>
                        <asp:BoundField DataField="LigneNo" HeaderText="Ligne" />
                        <asp:BoundField DataField="Compte" HeaderText="Compte" />
                        <asp:BoundField DataField="Nom" HeaderText="Nom" />
                        <asp:BoundField DataField="TypeNormalise" HeaderText="Nature" />
                        <asp:BoundField DataField="Solde" HeaderText="Solde" DataFormatString="{0:N2}" />
                        <asp:BoundField DataField="Sens" HeaderText="Sens" />
                        <asp:TemplateField HeaderText="Verdict">
                            <ItemTemplate>
                                <span class='pill <%# PilleClasse(Eval("Statut")) %>'>
                                    <%# PilleTexte(Eval("Statut")) %></span>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="Anomalie" HeaderText="Détail" />
                        <asp:BoundField DataField="TypeSource" HeaderText="Type d'origine" />
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ LES LOTS PRÉCÉDENTS ══════════ -->
    <asp:Panel ID="pnlLots" runat="server" Visible="false" CssClass="step">
        <h2><span class="n">🗂</span>Chargements précédents</h2>
        <p class="desc">Chaque dépôt de fichier forme un lot, que l'on peut revoir ou abandonner.</p>
        <div class="body">
            <div class="tbl-wrap">
                <asp:GridView ID="gvLots" runat="server" AutoGenerateColumns="false"
                    CssClass="g" GridLines="None" UseAccessibleHeader="true" DataKeyNames="Id">
                    <Columns>
                        <asp:BoundField DataField="Id" HeaderText="Lot" />
                        <asp:BoundField DataField="Created" HeaderText="Date" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
                        <asp:BoundField DataField="SystemeSource" HeaderText="Origine" />
                        <asp:BoundField DataField="NomFichier" HeaderText="Fichier" />
                        <asp:BoundField DataField="NbLignesRetenues" HeaderText="Retenus" />
                        <asp:BoundField DataField="NbAnomalies" HeaderText="Anomalies" />
                        <asp:BoundField DataField="Statut" HeaderText="État" />
                        <asp:BoundField DataField="CreeParEmail" HeaderText="Par" />
                        <asp:TemplateField>
                            <ItemTemplate>
                                <asp:LinkButton runat="server" Text="Revoir" CommandName="Voir"
                                    CommandArgument='<%# Eval("Id") %>' CausesValidation="false" />
                                &nbsp;·&nbsp;
                                <asp:LinkButton runat="server" Text="Abandonner" CommandName="Supprimer"
                                    CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                    OnClientClick="if (!confirm('Abandonner ce lot et tout son contenu ?')) { return false; }" />
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </asp:Panel>

</div>

<script type="text/javascript">
    (function () {
        var input = document.getElementById('<%= fuFichier.ClientID %>');
        var zone = document.getElementById('dropZone');
        if (!input || !zone) return;

        var icone = document.getElementById('dropIcone');
        var texte = document.getElementById('dropTexte');
        var info = document.getElementById('dropInfo');

        zone.addEventListener('click', function () { input.click(); });

        // Sans cela le navigateur ouvre le fichier dans l'onglet et la page
        // en cours est perdue — y compris lorsque le dépôt tombe à côté.
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(function (n) {
            document.addEventListener(n, function (e) { e.preventDefault(); });
            zone.addEventListener(n, function (e) { e.preventDefault(); e.stopPropagation(); });
        });

        zone.addEventListener('dragenter', function () { zone.classList.add('over'); });
        zone.addEventListener('dragover', function () { zone.classList.add('over'); });
        zone.addEventListener('dragleave', function (e) {
            if (!zone.contains(e.relatedTarget)) zone.classList.remove('over');
        });

        zone.addEventListener('drop', function (e) {
            zone.classList.remove('over');

            var fs = e.dataTransfer && e.dataTransfer.files;
            if (!fs || !fs.length) return;

            if (!/\.(csv|txt)$/i.test(fs[0].name)) {
                alert('Seuls les fichiers .csv et .txt sont acceptés.');
                return;
            }

            // On ne garde que le premier : le champ n'en accepte qu'un, et lui
            // passer la liste entière est refusé par le navigateur.
            var d = new DataTransfer();
            d.items.add(fs[0]);
            input.files = d.files;

            // L'affectation par script ne déclenche pas l'évènement.
            input.dispatchEvent(new Event('change'));
        });

        input.addEventListener('change', function () {
            if (!this.files || !this.files.length) { reinitialiser(); return; }

            var f = this.files[0];
            icone.textContent = '📄';
            texte.innerHTML = '<b></b>';
            texte.firstChild.textContent = f.name;
            info.textContent = (f.size / 1024).toFixed(0) + ' Ko';
            zone.classList.add('has');
        });

        function reinitialiser() {
            icone.textContent = '📁';
            texte.innerHTML = '<b>Glissez votre fichier ici</b> ou cliquez pour le choisir';
            info.textContent = '.csv ou .txt';
            zone.classList.remove('has');
        }
    })();
</script>
</asp:Content>
