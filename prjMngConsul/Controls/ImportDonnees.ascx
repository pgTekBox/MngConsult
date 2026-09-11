<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="ImportDonnees.ascx.vb" Inherits="MngConsul.ImportDonnees" %>
<%@ Register Src="~/Controls/SourceDonnees.ascx" TagPrefix="uc" TagName="SourceDonnees" %>

<%-- L'importation des clients, des fournisseurs ou des produits et services :
     un même écran, trois usages. Chaque page le pose avec son Genre. --%>

<style>
    .idn { max-width: 1150px; margin: 0 auto; padding: 16px }

    .idn-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }

    .idn-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }

    .idn-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .idn-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }

    .idn-lede { font-size: 13.5px; color: #475569; margin: 0 0 18px; max-width: 760px; line-height: 1.6 }

    .idn-step { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 20px; margin-bottom: 16px }

    .idn-step > h2 {
        font-size: 15px; font-weight: 800; margin: 0 0 3px; color: #0f172a;
        display: flex; align-items: center; gap: 9px;
    }

    .idn-step > h2 .n {
        width: 24px; height: 24px; border-radius: 999px; flex: 0 0 auto;
        background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;
        font-size: 12px; display: flex; align-items: center; justify-content: center;
    }

    .idn-step > .desc { font-size: 13px; color: #64748b; margin: 0 0 15px; padding-left: 33px }
    .idn-step > .body { padding-left: 33px }

    /* Une seule ligne : la zone de dépôt n'a aucune raison d'occuper l'écran. */
    .idn-drop {
        display: flex; align-items: center; gap: 9px;
        border: 1.5px dashed #cbd5e1; border-radius: 10px; padding: 9px 13px;
        cursor: pointer; font-size: 13px; color: #475569;
        transition: border-color .15s, background .15s;
    }

    .idn-drop:hover { border-color: #2563eb; background: rgba(37,99,235,.04) }
    .idn-drop .di { font-size: 17px; line-height: 1 }
    .idn-drop .dt { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap }
    .idn-drop .dh { margin-left: auto; padding-left: 10px; font-size: 11.5px; color: #94a3b8; white-space: nowrap }
    .idn-drop.over { border-style: solid; border-color: #2563eb; background: rgba(37,99,235,.08); color: #1d4ed8 }
    .idn-drop.has { border-style: solid; border-color: #bfdbfe; background: rgba(37,99,235,.05) }
    .idn-drop.has .dt b { color: #1e293b }

    .idn-memo { font-size: 12.5px; color: #475569; margin-top: 8px }

    .idn-acts { display: flex; gap: 9px; flex-wrap: wrap; align-items: center; margin-top: 16px }

    .idn-btn {
        padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700;
        border: 1px solid transparent; cursor: pointer; font-family: inherit;
        text-decoration: none; display: inline-block;
    }

    .idn-btn.p { background: #2563eb; color: #fff }
    .idn-btn.p:hover { background: #1d4ed8; color: #fff }
    .idn-btn.s { background: #f1f5f9; color: #334155; border-color: #e2e8f0 }
    .idn-btn.s:hover { background: #e2e8f0; color: #334155 }
    .idn-btn.ia { background: #6d28d9; color: #fff }
    .idn-btn.ia:hover { background: #5b21b6 }
    .idn-btn.d { background: #fff; color: #b91c1c; border-color: #fecaca; margin-left: auto }
    .idn-btn.d:hover { background: #fef2f2 }

    .idn-hint { font-size: 12px; color: #64748b; margin: 12px 0 0; line-height: 1.5 }

    .idn-alert { display: flex; gap: 11px; padding: 12px 15px; border-radius: 11px; margin-bottom: 14px; font-size: 13.5px }
    .idn-alert .ai { flex: 0 0 auto; font-size: 16px }
    .idn-ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .idn-ko { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .idn-wa { background: #fffbeb; border: 1px solid #fde68a; color: #78350f }

    .idn-origine { font-size: 12.5px; color: #64748b; margin: 0 0 10px; line-height: 1.5 }

    .idn-chips { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px }
    .idn-chip { padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; background: #f1f5f9; color: #475569 }
    .idn-chip.new { background: #ecfdf5; color: #047857 }
    .idn-chip.ex { background: #eff6ff; color: #1d4ed8 }
    .idn-chip.wa { background: #fffbeb; color: #b45309 }
    .idn-chip.ok { background: #dcfce7; color: #166534 }
    .idn-chip.ko { background: #fef2f2; color: #b91c1c }

    .idn-tbl { overflow: auto; max-height: 540px; border: 1px solid #e2e8f0; border-radius: 12px }

    table.idn-g { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.idn-g th {
        background: #f8fafc; text-align: left; padding: 9px 11px; font-weight: 700; color: #334155;
        white-space: nowrap; border-bottom: 1px solid #e2e8f0; position: sticky; top: 0;
    }
    table.idn-g td { padding: 7px 11px; border-bottom: 1px solid #f1f5f9; vertical-align: top }
    table.idn-g tr:last-child td { border-bottom: 0 }
    table.idn-g .num { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums }

    .idn-pill { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; white-space: nowrap }
    .idn-pill.p-new { background: #ecfdf5; color: #047857 }
    .idn-pill.p-ex { background: #eff6ff; color: #1d4ed8 }
    .idn-pill.p-wa { background: #fffbeb; color: #b45309 }
    .idn-pill.p-ok { background: #dcfce7; color: #166534 }
    .idn-pill.p-gr { background: #f1f5f9; color: #64748b }
    .idn-pill.p-ko { background: #fef2f2; color: #b91c1c }
    .idn-det { display: block; font-size: 11px; color: #64748b; margin-top: 3px; max-width: 280px }

    table.idn-map { border-collapse: collapse; font-size: 12.5px; margin-top: 4px }
    table.idn-map th { text-align: left; padding: 5px 18px 5px 0; color: #64748b; font-weight: 700 }
    table.idn-map td { padding: 4px 18px 4px 0; border-bottom: 1px solid #f1f5f9 }
    table.idn-map .none { color: #cbd5e1 }
</style>

<div class="idn">

    <div class="idn-head">
        <div class="ico"><asp:Literal ID="litIcone" runat="server" /></div>
        <div>
            <h1><asp:Literal ID="litTitre" runat="server" /></h1>
            <div class="sub"><asp:Literal ID="litSousTitre" runat="server" /></div>
        </div>
    </div>

    <p class="idn-lede"><asp:Literal ID="litIntro" runat="server" /></p>

    <!-- ══════════ MESSAGES ══════════ -->
    <asp:Panel ID="pnlSucces" runat="server" Visible="false" CssClass="idn-alert idn-ok">
        <span class="ai">✅</span><div><asp:Literal ID="litSucces" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlAvert" runat="server" Visible="false" CssClass="idn-alert idn-wa">
        <span class="ai">⚠️</span><div><asp:Literal ID="litAvert" runat="server" /></div>
    </asp:Panel>
    <asp:Panel ID="pnlErreur" runat="server" Visible="false" CssClass="idn-alert idn-ko">
        <span class="ai">❌</span><div><asp:Literal ID="litErreur" runat="server" /></div>
    </asp:Panel>

    <!-- ══════════ CE QUI A ÉTÉ LU ══════════ -->
    <asp:Panel ID="pnlResultat" runat="server" Visible="false" CssClass="idn-step">
        <h2><span class="n">✓</span><asp:Literal ID="litResTitre" runat="server" /></h2>
        <div class="body">
            <asp:Literal ID="litOrigine" runat="server" />
            <asp:Literal ID="litChips" runat="server" />
            <asp:Literal ID="litLignes" runat="server" />

            <div class="idn-acts">
                <asp:Button ID="btnCreer" runat="server" CssClass="idn-btn p" CausesValidation="false" />
                <asp:HyperLink ID="hlListe" runat="server" CssClass="idn-btn s" Visible="false" />
                <asp:Button ID="btnAbandonner" runat="server" CssClass="idn-btn d" CausesValidation="false"
                    Text="🗑 Abandonner ce fichier"
                    OnClientClick="if (!confirm('Abandonner ce fichier et ses lignes en préparation ? Ce qui a déjà été créé dans l\'application reste en place.')) { return false; }" />
            </div>
        </div>
    </asp:Panel>

    <!-- ══════════ 1 · D'OÙ VIENNENT LES DONNÉES ══════════ -->
    <div class="idn-step">
        <uc:SourceDonnees ID="ucSource" runat="server" Numero="1" />
    </div>

    <!-- ══════════ 2 · LE FICHIER ══════════ -->
    <div class="idn-step">
        <h2><span class="n">2</span>Le fichier</h2>
        <p class="desc">Un fichier CSV ou texte, une ligne par <asp:Literal ID="litUn" runat="server" />. 10 Mo au maximum.</p>
        <div class="body">

            <div class="idn-drop" id="idnDrop">
                <span class="di" id="idnIcone">📁</span>
                <span class="dt" id="idnTexte"><b>Glissez votre fichier ici</b> ou cliquez pour le choisir</span>
                <span class="dh" id="idnInfo">.csv ou .txt</span>
            </div>
            <asp:FileUpload ID="fuFichier" runat="server" Style="display:none" accept=".csv,.txt" />

            <asp:Panel ID="pnlEnMemoire" runat="server" Visible="false" CssClass="idn-memo">
                <asp:Literal ID="litEnMemoire" runat="server" />
            </asp:Panel>

            <div class="idn-acts">
                <asp:Button ID="btnApercu" runat="server" Text="👁 Voir un aperçu" CssClass="idn-btn s" CausesValidation="false" />
                <asp:Button ID="btnIA" runat="server" Text="✨ Extraire avec l'IA" CssClass="idn-btn ia" CausesValidation="false"
                    OnClientClick="this.value='⏳ Extraction par l\'IA…';" />
                <asp:Button ID="btnLire" runat="server" Text="📥 Lire le fichier" CssClass="idn-btn p" CausesValidation="false" />
            </div>

            <p class="idn-hint">
                <b>Lire le fichier</b> reconnaît les colonnes par leur en-tête. Pour un fichier mal formé —
                lignes de titre, colonnes décalées, adresse en un seul bloc — <b>Extraire avec l'IA</b>
                confie la lecture à ChatGPT. Une ligne dont le nom ne figure pas dans le fichier est
                refusée, tout comme un montant qu'on n'y retrouve pas. Dans les deux cas, rien n'est
                créé avant que vous ne l'ayez décidé.
            </p>
        </div>
    </div>

    <!-- ══════════ APERÇU ══════════ -->
    <asp:Panel ID="pnlApercu" runat="server" Visible="false" CssClass="idn-step">
        <h2><span class="n">👁</span>Aperçu — ce que la lecture a compris</h2>
        <div class="body">
            <asp:Literal ID="litApercu" runat="server" />
        </div>
    </asp:Panel>

    <!-- ══════════ LES FICHIERS PRÉCÉDENTS ══════════ -->
    <asp:Panel ID="pnlFichiers" runat="server" Visible="false" CssClass="idn-step">
        <h2><span class="n">🗂</span>Fichiers déjà déposés</h2>
        <p class="desc">Chaque dépôt se revoit ou s'abandonne. Abandonner ne retire rien de ce qui a été créé.</p>
        <div class="body">
            <div class="idn-tbl">
                <asp:GridView ID="gvFichiers" runat="server" AutoGenerateColumns="false"
                    CssClass="idn-g" GridLines="None" UseAccessibleHeader="true">
                    <Columns>
                        <asp:BoundField DataField="UploadDate" HeaderText="Déposé le" DataFormatString="{0:yyyy-MM-dd HH:mm}" />
                        <asp:BoundField DataField="OriginalName" HeaderText="Fichier" />
                        <asp:BoundField DataField="Lecture" HeaderText="Lu par" />
                        <asp:BoundField DataField="Lignes" HeaderText="Lignes" />
                        <asp:BoundField DataField="Crees" HeaderText="Créés" />
                        <asp:BoundField DataField="EnAttente" HeaderText="En attente" />
                        <asp:TemplateField>
                            <ItemTemplate>
                                <asp:LinkButton runat="server" Text="Revoir" CommandName="Voir"
                                    CommandArgument='<%# Eval("Id") %>' CausesValidation="false" />
                                &nbsp;·&nbsp;
                                <asp:LinkButton runat="server" Text="Abandonner" CommandName="Supprimer"
                                    CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                    OnClientClick="if (!confirm('Abandonner ce fichier et ses lignes en préparation ?')) { return false; }" />
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
        var zone = document.getElementById('idnDrop');
        if (!input || !zone) return;

        var icone = document.getElementById('idnIcone');
        var texte = document.getElementById('idnTexte');
        var info = document.getElementById('idnInfo');

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

            var d = new DataTransfer();
            d.items.add(fs[0]);
            input.files = d.files;
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
