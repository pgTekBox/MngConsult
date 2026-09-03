<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfEftBatches.aspx.vb" Inherits="PortailMaster.wbfEftBatches" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
        .mono{font-family:Consolas,monospace}
        .badge-open{background:rgba(100,116,139,.16);color:#475569}
        .badge-gen{background:rgba(79,70,229,.12);color:var(--secondary)}
        .badge-sub{background:rgba(2,132,199,.12);color:#0284c7}
        .badge-appr{background:rgba(13,148,136,.14);color:#0f766e}
        .hint{font-size:12px;color:var(--muted);margin-top:6px}
        details.cfg{margin-bottom:22px}
        details.cfg summary{cursor:pointer;font-weight:800;font-size:15px;padding:4px 0}
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>EFT — Fichiers CPA-005</h1>
            <p class="sub">Génération des fichiers AFT (Norme 005) à soumettre à la banque parrain.</p>
        </div>
        <div style="display:flex;gap:10px;align-items:center">
            <asp:Button ID="btnExchange" runat="server" CssClass="btn" Text="Échanger avec la banque" OnClick="btnExchange_Click"
                ToolTip="Envoie les lots APPROUVÉS et traite les fichiers reçus (retours, relevés)." />
            <asp:Button ID="btnGenerate" runat="server" CssClass="btn btn-primary" Text="Générer un lot" OnClick="btnGenerate_Click" />
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <details class="cfg">
        <summary>Configuration émetteur (paramètres fournis par la banque)</summary>
        <div class="card">
            <div class="form-grid">
                <div class="field"><label>N° client émetteur</label><asp:TextBox ID="tbClientNumber" runat="server" CssClass="mono" /></div>
                <div class="field"><label>Centre de données</label><asp:TextBox ID="tbDataCentre" runat="server" CssClass="mono" /></div>
                <div class="field"><label>Nom court (15)</label><asp:TextBox ID="tbShortName" runat="server" /></div>
                <div class="field"><label>Nom long (30)</label><asp:TextBox ID="tbLongName" runat="server" /></div>
                <div class="field"><label>Compte de retour — Institution</label><asp:TextBox ID="tbRetInst" runat="server" CssClass="mono" /></div>
                <div class="field"><label>Transit</label><asp:TextBox ID="tbRetTransit" runat="server" CssClass="mono" /></div>
                <div class="field"><label>N° de compte</label><asp:TextBox ID="tbRetAccount" runat="server" CssClass="mono" /></div>
                <div class="field"><label>Code CPA débit / crédit</label>
                    <div style="display:flex;gap:8px"><asp:TextBox ID="tbCpaDebit" runat="server" CssClass="mono" style="width:80px" /><asp:TextBox ID="tbCpaCredit" runat="server" CssClass="mono" style="width:80px" /></div>
                </div>
                <div class="field"><label>Plafond par transaction ($)</label><asp:TextBox ID="tbMaxItem" runat="server" CssClass="mono" placeholder="aucun" /></div>
                <div class="field"><label>Plafond par fichier ($)</label><asp:TextBox ID="tbMaxFile" runat="server" CssClass="mono" placeholder="aucun" /></div>
                <div class="field"><label>Plafond quotidien ($)</label><asp:TextBox ID="tbMaxDaily" runat="server" CssClass="mono" placeholder="aucun" /></div>
            </div>
            <div class="form-actions"><asp:Button ID="btnSaveOrig" runat="server" CssClass="btn" Text="Enregistrer la configuration" OnClick="btnSaveOrig_Click" /></div>
            <div class="hint">Le prochain n° de création de fichier est géré automatiquement. Chaque client/fournisseur doit avoir ses coordonnées bancaires (institution / transit / compte) pour figurer dans le fichier.</div>
            <div class="hint">Plafonds : laissez vide pour « aucun plafond ». Ils sont vérifiés à la création du lot — tout dépassement annule le lot. Le plafond quotidien par abonné se règle sur la fiche de l'abonné.</div>
        </div>
    </details>

    <div class="table-wrap">
        <asp:Repeater ID="rptBatches" runat="server" OnItemCommand="rptBatches_ItemCommand">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>N° fichier</th><th>Statut</th>
                    <th class="num">Débits</th><th class="num">Crédits</th>
                    <th>Créé</th><th>Double contrôle</th><th>Fichier</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# String.Format("{0:D4}", Eval("FileCreationNumber")) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Status")) %>'><%# LabelStatut(Eval("Status")) %></span></td>
                    <td class="num"><%# Eval("CountDebit") %> · <%# Money(Eval("TotalDebitCents")) %></td>
                    <td class="num"><%# Eval("CountCredit") %> · <%# Money(Eval("TotalCreditCents")) %></td>
                    <td class="muted"><%# FormatDt(Eval("CreatedUtc")) %><br /><span class="muted" style="font-size:12px"><%# CreatorText(Container.DataItem) %></span></td>
                    <td class="muted" style="font-size:12px"><%# ApprovalText(Container.DataItem) %></td>
                    <td><a href='EftFile.ashx?batchId=<%# Eval("Id") %>'>Télécharger .005</a></td>
                    <td style="white-space:nowrap">
                        <asp:LinkButton runat="server" Text="Approuver" CommandName="approve" CommandArgument='<%# Eval("Id") %>'
                            style="margin-right:10px;font-weight:700"
                            Visible='<%# CanApprove(Container.DataItem) %>'
                            OnClientClick="return confirm('Approuver ce lot pour transmission à la banque ? Vous en êtes le second contrôle.');" />
                        <asp:LinkButton runat="server" Text="Marquer réglé" CommandName="settle" CommandArgument='<%# Eval("Id") %>'
                            Visible='<%# Eval("Status").ToString() <> "Settled" %>'
                            OnClientClick="return confirm('Confirmer le règlement bancaire de ce lot ? (règle toutes ses transactions)');" />
                        <asp:LinkButton runat="server" Text="Simuler accusé" CommandName="simack" CommandArgument='<%# Eval("Id") %>'
                            style="margin-left:10px"
                            Visible='<%# Eval("Status").ToString() <> "Settled" AndAlso Eval("Status").ToString() <> "Rejected" %>'
                            OnClientClick="return confirm('Simuler un accusé bancaire ACCEPTÉ pour ce lot (rejette le 1er item à l''intake) ?');" />
                        <asp:LinkButton runat="server" Text="Simuler retour" CommandName="simret" CommandArgument='<%# Eval("Id") %>'
                            style="margin-left:10px;color:var(--danger)"
                            OnClientClick="return confirm('Simuler un retour NSF pour ce lot ? (contre-passe ses transactions)');" />
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
            Aucun lot. Cliquez « Générer un lot » pour regrouper les transactions initiées.
        </asp:Panel>
    </div>

    <div class="card" style="margin-top:24px">
        <h3 style="margin:0 0 12px 0;font-size:16px">Retours de la banque (fichiers 005)</h3>
        <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
            <asp:FileUpload ID="fuReturn" runat="server" />
            <asp:Button ID="btnImport" runat="server" CssClass="btn" Text="Importer le fichier de retour" OnClick="btnImport_Click" />
        </div>
        <div class="hint">Fichier de retour (enregistrements E/F) : chaque retour est rapproché par référence croisée <span class="mono">P&lt;id&gt;</span> puis contre-passé au grand livre (gère le retour avant ou après règlement).</div>

        <div class="table-wrap" style="border:none;margin-top:16px">
            <asp:Repeater ID="rptReturns" runat="server">
                <HeaderTemplate>
                    <table class="grid"><thead><tr>
                        <th>Paiement</th><th>Type</th><th class="num">Montant</th><th>Motif</th><th>Statut</th><th>Détail</th><th>Importé</th>
                    </tr></thead><tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="mono"><%# If(IsDBNull(Eval("PaymentId")),"—",Eval("PaymentId").ToString()) %></td>
                        <td class="mono"><%# Server.HtmlEncode(If(Eval("RecordType"),"").ToString()) %></td>
                        <td class="num"><%# Money(Eval("AmountCents")) %></td>
                        <td class="muted"><%# Server.HtmlEncode(If(Eval("ReasonCode"),"").ToString()) %></td>
                        <td><span class='badge <%# BadgeReturn(Eval("Status")) %>'><%# Server.HtmlEncode(If(Eval("Status"),"").ToString()) %></span></td>
                        <td class="muted"><%# Server.HtmlEncode(If(Eval("Message"),"").ToString()) %></td>
                        <td class="muted"><%# FormatDt(Eval("ImportedUtc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoReturns" runat="server" Visible="false" CssClass="empty">Aucun retour importé.</asp:Panel>
        </div>
    </div>

    <div class="card" style="margin-top:24px">
        <h3 style="margin:0 0 12px 0;font-size:16px">Accusés de réception (banque)</h3>
        <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
            <asp:FileUpload ID="fuAck" runat="server" />
            <asp:Button ID="btnImportAck" runat="server" CssClass="btn" Text="Importer un accusé de réception" OnClick="btnImportAck_Click" />
        </div>
        <div class="hint">Après soumission d'un lot, la banque renvoie un accusé (<span class="mono">A|n°fichier|ACCEPTED/REJECTED</span> + lignes <span class="mono">R|P&lt;id&gt;|motif</span>). Le fichier accepté marque le lot « Accusé reçu » ; les items rejetés à l'intake sont contre-passés (distincts des retours NSF). Un fichier refusé contre-passe tout le lot.</div>

        <div class="table-wrap" style="border:none;margin-top:16px">
            <asp:Repeater ID="rptAck" runat="server">
                <HeaderTemplate>
                    <table class="grid"><thead><tr>
                        <th>Lot</th><th>N° fichier</th><th>Statut fichier</th><th class="num">Rejetés</th><th>Détail</th><th>Fichier</th><th>Reçu</th>
                    </tr></thead><tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="mono"><%# If(IsDBNull(Eval("BatchId")),"—",Eval("BatchId").ToString()) %></td>
                        <td class="mono"><%# If(IsDBNull(Eval("FileCreationNumber")),"—",String.Format("{0:D4}", Eval("FileCreationNumber"))) %></td>
                        <td><span class='badge <%# BadgeAck(Eval("FileStatus")) %>'><%# Server.HtmlEncode(If(Eval("FileStatus"),"").ToString()) %></span></td>
                        <td class="num"><%# Eval("RejectedCount") %></td>
                        <td class="muted"><%# Server.HtmlEncode(If(Eval("Message"),"").ToString()) %></td>
                        <td class="mono muted"><%# Server.HtmlEncode(If(Eval("FileName"),"").ToString()) %></td>
                        <td class="muted"><%# FormatDt(Eval("Utc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoAck" runat="server" Visible="false" CssClass="empty">Aucun accusé reçu.</asp:Panel>
        </div>
    </div>

    <div class="card" style="margin-top:24px">
        <h3 style="margin:0 0 12px 0;font-size:16px">Journal des échanges (banque)</h3>
        <div class="hint">Envoi des fichiers .005 vers la banque et réception/traitement des retours et relevés. Transport configuré dans <span class="mono">Web.config</span> (local ou SFTP/WinSCP).</div>
        <div class="table-wrap" style="border:none;margin-top:14px">
            <asp:Repeater ID="rptExchange" runat="server">
                <HeaderTemplate>
                    <table class="grid"><thead><tr>
                        <th>Sens</th><th>Fichier</th><th>Type</th><th>Lot</th><th class="num">Octets</th><th>Statut</th><th>Détail</th><th>Quand</th>
                    </tr></thead><tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td><%# If(Eval("Direction").ToString().Trim()="Out","↑ Envoi","↓ Réception") %></td>
                        <td class="mono"><%# Server.HtmlEncode(If(Eval("FileName"),"").ToString()) %></td>
                        <td class="mono"><%# Server.HtmlEncode(If(Eval("FileType"),"").ToString()) %></td>
                        <td class="mono"><%# If(IsDBNull(Eval("BatchId")),"—",Eval("BatchId").ToString()) %></td>
                        <td class="num muted"><%# If(IsDBNull(Eval("Bytes")),"—",Eval("Bytes").ToString()) %></td>
                        <td><span class='badge <%# If(Eval("Status").ToString()="Error","badge-rejete","badge-actif") %>'><%# Eval("Status") %></span></td>
                        <td class="muted"><%# Server.HtmlEncode(If(Eval("Message"),"").ToString()) %></td>
                        <td class="muted"><%# FormatDt(Eval("Utc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoExchange" runat="server" Visible="false" CssClass="empty">Aucun échange encore.</asp:Panel>
        </div>
    </div>
</asp:Content>
