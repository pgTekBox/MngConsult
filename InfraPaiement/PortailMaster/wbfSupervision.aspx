<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfSupervision.aspx.vb" Inherits="PortailMaster.wbfSupervision" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .section-lbl{font-size:13px;font-weight:800;text-transform:uppercase;letter-spacing:.04em;color:var(--muted);margin:26px 0 12px}
        .tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:16px}
        .tile{background:#fff;border:1px solid var(--line);border-radius:16px;padding:16px 18px}
        .tile .lbl{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.03em;color:var(--muted)}
        .tile .val{font-size:23px;font-weight:800;margin-top:6px;letter-spacing:-.02em}
        .tile.warn{border-color:rgba(217,119,6,.4);background:rgba(217,119,6,.05)}
        .tile.warn .val{color:#b45309}
        .tile.ok .val{color:var(--ok)}
        .num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
        .mono{font-family:Consolas,monospace}
        .muted{color:var(--muted)}
        .badge-encours{background:rgba(2,132,199,.12);color:#0284c7}
        .badge-open{background:rgba(100,116,139,.16);color:#475569}
        .late{color:var(--danger);font-weight:700}
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Supervision</h1>
            <p class="sub">Vue opérationnelle de la plateforme de paiement.</p>
        </div>
        <asp:HyperLink runat="server" CssClass="btn btn-ghost" NavigateUrl="wbfEftBatches.aspx" Text="EFT / Lots" />
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="section-lbl">Trésorerie</div>
    <div class="tiles">
        <div class="tile"><div class="lbl">En fiducie</div><div class="val"><asp:Literal ID="litTrust" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Dû aux abonnés</div><div class="val"><asp:Literal ID="litOwed" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Frais perçus</div><div class="val"><asp:Literal ID="litFees" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Équilibre comptable</div><div class="val"><asp:Literal ID="litInvariant" runat="server" /></div></div>
    </div>

    <div class="section-lbl">Volumes & statuts</div>
    <div class="tiles">
        <div class="tile"><div class="lbl">Encaissements réglés</div><div class="val"><asp:Literal ID="litVolIn" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Décaissements réglés</div><div class="val"><asp:Literal ID="litVolOut" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Réglés / Initiés</div><div class="val"><asp:Literal ID="litRegle" runat="server" /> / <asp:Literal ID="litInitie" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Retours (taux)</div><div class="val"><asp:Literal ID="litReturns" runat="server" /></div></div>
    </div>

    <div class="section-lbl">À surveiller</div>
    <div class="tiles">
        <div class="tile" id="tileOverdue" runat="server"><div class="lbl">Paiements en souffrance</div><div class="val"><asp:Literal ID="litOverdue" runat="server" /></div></div>
        <div class="tile" id="tileWh" runat="server"><div class="lbl">Webhooks en échec</div><div class="val"><asp:Literal ID="litWhIssues" runat="server" /></div></div>
        <div class="tile" id="tileKyb" runat="server"><div class="lbl">KYB à traiter</div><div class="val"><asp:Literal ID="litKyb" runat="server" /></div></div>
        <div class="tile"><div class="lbl">Lots EFT ouverts</div><div class="val"><asp:Literal ID="litBatches" runat="server" /></div></div>
    </div>

    <div class="section-lbl">Paiements en souffrance (initiés, échus)</div>
    <div class="table-wrap">
        <asp:Repeater ID="rptOverdue" runat="server">
            <HeaderTemplate><table class="grid"><thead><tr>
                <th>#</th><th>Abonné</th><th>Sens</th><th class="num">Montant</th><th>Réf.</th><th>Prévu</th><th class="num">Retard</th></tr></thead><tbody></HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Eval("Id") %></td>
                    <td><%# Server.HtmlEncode(If(Eval("Abonne"),"").ToString()) %></td>
                    <td><%# Server.HtmlEncode(If(Eval("Direction"),"").ToString()) %></td>
                    <td class="num"><%# Money(Eval("AmountCents")) %></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("Reference"),"").ToString()) %></td>
                    <td class="muted"><%# FormatDate(Eval("ExpectedSettlementDate")) %></td>
                    <td class="num"><span class="late"><%# Eval("JoursRetard") %> j</span></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoOverdue" runat="server" Visible="false" CssClass="empty">Aucun paiement en souffrance. 👍</asp:Panel>
    </div>

    <div class="section-lbl">Webhooks en échec</div>
    <div class="table-wrap">
        <asp:Repeater ID="rptWh" runat="server">
            <HeaderTemplate><table class="grid"><thead><tr>
                <th>#</th><th>Abonné</th><th>Événement</th><th>Statut</th><th class="num">Tent.</th><th>HTTP</th><th>Erreur</th></tr></thead><tbody></HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Eval("Id") %></td>
                    <td><%# Server.HtmlEncode(If(Eval("Abonne"),"").ToString()) %></td>
                    <td class="mono"><%# Server.HtmlEncode(If(Eval("EventType"),"").ToString()) %></td>
                    <td><span class='badge <%# If(Eval("Status").ToString()="Abandoned","badge-rejete","badge-encours") %>'><%# Eval("Status") %></span></td>
                    <td class="num"><%# Eval("Attempts") %>/<%# Eval("MaxAttempts") %></td>
                    <td class="muted"><%# If(IsDBNull(Eval("ResponseStatus")),"—",Eval("ResponseStatus").ToString()) %></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("LastError"),"").ToString()) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoWh" runat="server" Visible="false" CssClass="empty">Aucun webhook en échec. 👍</asp:Panel>
    </div>

    <div class="section-lbl">Retours récents</div>
    <div class="table-wrap">
        <asp:Repeater ID="rptReturns" runat="server">
            <HeaderTemplate><table class="grid"><thead><tr>
                <th>#</th><th>Paiement</th><th>Type</th><th class="num">Montant</th><th>Motif</th><th>Statut</th><th>Importé</th></tr></thead><tbody></HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono"><%# Eval("Id") %></td>
                    <td class="mono"><%# If(IsDBNull(Eval("PaymentId")),"—",Eval("PaymentId").ToString()) %></td>
                    <td class="mono"><%# Server.HtmlEncode(If(Eval("RecordType"),"").ToString()) %></td>
                    <td class="num"><%# Money(Eval("AmountCents")) %></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("Message"),"").ToString()) %></td>
                    <td><span class='badge <%# If(Eval("Status").ToString()="Processed","badge-actif","badge-open") %>'><%# Eval("Status") %></span></td>
                    <td class="muted"><%# FormatDt(Eval("ImportedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoReturns" runat="server" Visible="false" CssClass="empty">Aucun retour.</asp:Panel>
    </div>
</asp:Content>
