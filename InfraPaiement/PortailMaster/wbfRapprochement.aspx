<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfRapprochement.aspx.vb" Inherits="PortailMaster.wbfRapprochement" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:16px;margin-bottom:22px}
        .tile{background:#fff;border:1px solid var(--line);border-radius:16px;padding:16px 18px}
        .tile .lbl{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.03em;color:var(--muted)}
        .tile .val{font-size:23px;font-weight:800;margin-top:6px;letter-spacing:-.02em}
        .tile.diff.ok .val{color:var(--ok)} .tile.diff.bad .val{color:var(--danger)}
        .num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
        .mono{font-family:Consolas,monospace}.muted{color:var(--muted)}
        .pos{color:var(--ok)} .neg{color:var(--danger)}
        .section-lbl{font-size:13px;font-weight:800;text-transform:uppercase;letter-spacing:.04em;color:var(--muted);margin:26px 0 12px}
        .badge-unmatch{background:rgba(217,119,6,.14);color:#b45309}
        .hint{font-size:12px;color:var(--muted);margin-top:6px}
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Rapprochement bancaire</h1>
            <p class="sub">Compte fiducie (TRUST) : grand livre ↔ relevé bancaire.</p>
        </div>
        <asp:Button ID="btnReconcile" runat="server" CssClass="btn btn-primary" Text="Rapprocher automatiquement" OnClick="btnReconcile_Click" />
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="tiles">
        <div class="tile"><div class="lbl">Solde livre (fiducie)</div><div class="val"><asp:Literal ID="litLedger" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Total relevé</div><div class="val"><asp:Literal ID="litStmt" runat="server" /></div></div>
        <div class="tile diff" id="tileDiff" runat="server"><div class="lbl">Écart</div><div class="val"><asp:Literal ID="litDiff" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Lignes non rapprochées</div><div class="val"><asp:Literal ID="litUnmLines" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Mouvements livre non rapprochés</div><div class="val"><asp:Literal ID="litUnmMov" runat="server" /></div></div>
    </div>

    <div class="card" style="margin-bottom:6px">
        <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
            <asp:FileUpload ID="fuCsv" runat="server" />
            <asp:Button ID="btnImport" runat="server" CssClass="btn" Text="Importer le relevé (CSV)" OnClick="btnImport_Click" />
            <span style="color:var(--muted)">ou</span>
            <asp:Button ID="btnSimulate" runat="server" CssClass="btn" Text="Simuler le relevé" OnClick="btnSimulate_Click" />
        </div>
        <div class="hint">CSV attendu : <span class="mono">date,description,montant,référence</span> — montant signé (négatif = retrait). « Simuler » génère un relevé depuis les mouvements de fiducie non rapprochés (test).</div>
    </div>

    <div class="section-lbl">Lignes du relevé</div>
    <div class="table-wrap">
        <asp:Repeater ID="rptLines" runat="server">
            <HeaderTemplate><table class="grid"><thead><tr>
                <th>Date</th><th>Description</th><th class="num">Montant</th><th>Réf.</th><th>Statut</th><th>Écriture</th></tr></thead><tbody></HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="muted"><%# FormatDate(Eval("TxnDate")) %></td>
                    <td><%# Server.HtmlEncode(If(Eval("Description"),"").ToString()) %></td>
                    <td class="num"><%# MoneySigned(Eval("AmountCents")) %></td>
                    <td class="muted mono"><%# Server.HtmlEncode(If(Eval("Reference"),"").ToString()) %></td>
                    <td><span class='badge <%# If(Eval("Status").ToString()="Matched","badge-actif","badge-unmatch") %>'><%# If(Eval("Status").ToString()="Matched","Rapproché","Non rapproché") %></span></td>
                    <td class="mono muted"><%# If(IsDBNull(Eval("MatchedTxnId")),"—","#" & Eval("MatchedTxnId").ToString()) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoLines" runat="server" Visible="false" CssClass="empty">Aucune ligne de relevé. Importez un CSV ou simulez.</asp:Panel>
    </div>

    <div class="section-lbl">Mouvements de fiducie non rapprochés (grand livre)</div>
    <div class="table-wrap">
        <asp:Repeater ID="rptMov" runat="server">
            <HeaderTemplate><table class="grid"><thead><tr>
                <th>#</th><th>Date</th><th>Type</th><th>Description</th><th class="num">Montant fiducie</th></tr></thead><tbody></HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Eval("Id") %></td>
                    <td class="muted"><%# FormatDate(Eval("EffectiveDate")) %></td>
                    <td class="mono"><%# Server.HtmlEncode(If(Eval("TxnType"),"").ToString()) %></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("Description"),"").ToString()) %></td>
                    <td class="num"><%# MoneySigned(Eval("NetCents")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoMov" runat="server" Visible="false" CssClass="empty">Aucun mouvement non rapproché. 👍</asp:Panel>
    </div>
</asp:Content>
