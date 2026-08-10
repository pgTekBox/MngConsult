<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfInterac.aspx.vb" Inherits="PortailMaster.wbfInterac" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap}
        .mono{font-family:Consolas,monospace}
        .badge-int-req{background:rgba(2,132,199,.12);color:#0284c7}
        .amt input{text-align:right;font-variant-numeric:tabular-nums}
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <a href="wbfAbonne.aspx?id=<%= AbonneIdPublic %>" class="btn btn-ghost" style="margin-bottom:14px;display:inline-block">← Fiche abonné</a>

    <div class="page-head">
        <div>
            <h1>Interac e-Transfer</h1>
            <p class="sub">Rail quasi-instantané (simulé) — <asp:Literal ID="litAbonne" runat="server" /></p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:24px">
        <div class="form-grid">
            <div class="field"><label>Sens</label>
                <asp:DropDownList ID="ddlDirection" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlDirection_SelectedIndexChanged">
                    <asp:ListItem Value="Entrant">Encaissement (demande à un client)</asp:ListItem>
                    <asp:ListItem Value="Sortant">Décaissement (virement à un fournisseur)</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field"><label><asp:Literal ID="litContrepartieLbl" runat="server" Text="Client" /></label>
                <asp:DropDownList ID="ddlContrepartie" runat="server" />
            </div>
            <div class="field amt"><label>Montant (CAD)</label><asp:TextBox ID="tbAmount" runat="server" placeholder="0,00" /></div>
            <div class="field amt"><label>Frais (CAD)</label><asp:TextBox ID="tbFee" runat="server" placeholder="0,00" /></div>
            <div class="field full"><label>Courriel Interac du bénéficiaire</label><asp:TextBox ID="tbEmail" runat="server" TextMode="Email" placeholder="destinataire@courriel.ca" /></div>
            <div class="field full"><label>Description</label><asp:TextBox ID="tbDesc" runat="server" /></div>
        </div>
        <asp:Panel ID="pnlNoContrepartie" runat="server" Visible="false" CssClass="msg-err">
            Aucune contrepartie active pour ce sens. Créez d'abord un client/fournisseur pour cet abonné.
        </asp:Panel>
        <div class="form-actions">
            <asp:Button ID="btnInitiate" runat="server" CssClass="btn btn-primary" Text="Initier le transfert Interac" OnClick="btnInitiate_Click" />
        </div>
        <div class="sub" style="font-size:12px;margin-top:8px">Interac règle individuellement (pas de lot). Simulez ensuite le dépôt (règlement) ou le refus (contre-passation) sur la ligne.</div>
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rptInterac" runat="server" OnItemCommand="rptInterac_ItemCommand">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>#</th><th>Sens</th><th>Contrepartie</th><th>Courriel Interac</th>
                    <th class="num">Montant</th><th class="num">Net</th><th>Statut</th><th>Initié</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono muted"><%# Eval("Id") %></td>
                    <td><%# If(Eval("Direction").ToString()="Entrant","↓ Encaissement","↑ Décaissement") %></td>
                    <td style="font-weight:700"><%# Enc(If(Eval("Direction").ToString()="Entrant", Eval("ClientNom"), Eval("FournisseurNom"))) %></td>
                    <td class="mono muted"><%# Enc(Eval("InteracEmail")) %></td>
                    <td class="num"><%# Money(Eval("AmountCents")) %></td>
                    <td class="num"><%# Money(Eval("NetCents")) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Status")) %>'><%# LabelStatut(Eval("Status")) %></span></td>
                    <td class="muted"><%# FormatDt(Eval("InitiatedUtc")) %></td>
                    <td style="white-space:nowrap">
                        <asp:LinkButton runat="server" Text="Simuler dépôt" CommandName="deposit" CommandArgument='<%# Eval("Id") %>'
                            Visible='<%# Eval("Status").ToString() = "Initie" %>'
                            OnClientClick="return confirm('Simuler le dépôt/encaissement de ce transfert ? (le règle au grand livre)');" />
                        <asp:LinkButton runat="server" Text="Simuler refus" CommandName="decline" CommandArgument='<%# Eval("Id") %>'
                            Visible='<%# Eval("Status").ToString() = "Initie" %>' style="margin-left:10px;color:var(--danger)"
                            OnClientClick="return confirm('Simuler le refus/expiration ? (contre-passe le transfert)');" />
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun transfert Interac pour cet abonné.</asp:Panel>
    </div>

    <div class="card" style="margin-top:24px">
        <h3 style="margin:0 0 12px 0;font-size:16px">Journal des évènements Interac</h3>
        <div class="table-wrap" style="border:none">
            <asp:Repeater ID="rptEvents" runat="server">
                <HeaderTemplate><table class="grid"><thead><tr><th>Paiement</th><th>Évènement</th><th>Détail</th><th>Quand</th></tr></thead><tbody></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="mono"><%# If(IsDBNull(Eval("PaymentId")),"—",Eval("PaymentId").ToString()) %></td>
                        <td><span class="badge badge-int-req"><%# Enc(Eval("EventType")) %></span></td>
                        <td class="muted"><%# Enc(Eval("Message")) %></td>
                        <td class="muted"><%# FormatDt(Eval("Utc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoEvents" runat="server" Visible="false" CssClass="empty">Aucun évènement.</asp:Panel>
        </div>
    </div>
</asp:Content>
