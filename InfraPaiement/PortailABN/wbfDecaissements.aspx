<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfDecaissements.aspx.vb" Inherits="PortailABN.wbfDecaissements" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        details.add { margin-bottom: 22px; }
        details.add summary { cursor: pointer; font-weight: 800; font-size: 15px; padding: 4px 0; color: var(--secondary); }
        .amt input { text-align: right; font-variant-numeric: tabular-nums; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Décaissements</h1>
            <p class="sub">Crédits EFT initiés vers vos fournisseurs (fonds sortants, retenus sur votre solde).</p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <details class="add" runat="server" id="detAdd">
        <summary>+ Nouveau décaissement</summary>
        <div class="card" style="margin-top:12px">
            <asp:Panel ID="pnlNoFourn" runat="server" Visible="false" CssClass="msg-err">
                Vous devez d'abord <a href="wbfFournisseurs.aspx">créer un fournisseur</a> avant d'initier un décaissement.
            </asp:Panel>
            <div class="form-grid">
                <div class="field"><label>Fournisseur (bénéficiaire) *</label>
                    <asp:DropDownList ID="ddlFourn" runat="server" />
                </div>
                <div class="field amt"><label>Montant (CAD) *</label><asp:TextBox ID="tbAmount" runat="server" placeholder="0,00" /></div>
                <div class="field amt"><label>Frais (CAD)</label><asp:TextBox ID="tbFee" runat="server" placeholder="0,00" /></div>
                <div class="field"><label>Règlement (jours ouvrés)</label><asp:TextBox ID="tbDays" runat="server" Text="2" /></div>
                <div class="field full"><label>Description</label><asp:TextBox ID="tbDesc" runat="server" /></div>
                <div class="field"><label>Référence</label><asp:TextBox ID="tbRef" runat="server" /></div>
            </div>
            <div class="form-actions">
                <asp:Button ID="btnInit" runat="server" CssClass="btn btn-primary" Text="Initier le décaissement" OnClick="btnInit_Click" />
            </div>
            <div class="hint" style="font-size:12px;color:var(--muted);margin-top:10px">
                Le montant est réservé sur votre solde dès l'initiation, puis décaissé au règlement (T+jours). Solde insuffisant = refus.
            </div>
        </div>
    </details>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>#</th><th>Fournisseur</th><th class="num">Montant</th><th class="num">Frais</th><th class="num">Net</th>
                    <th>Statut</th><th>Règlement prévu</th><th>Référence</th><th>Initié</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="mono muted"><%# Eval("Id") %></td>
                    <td style="font-weight:700"><%# Enc(Eval("FournisseurNom")) %></td>
                    <td class="num"><%# Money(Eval("AmountCents")) %></td>
                    <td class="num muted"><%# Money(Eval("FeeCents")) %></td>
                    <td class="num"><%# Money(Eval("NetCents")) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Status")) %>'><%# LabelStatut(Eval("Status")) %></span></td>
                    <td class="muted"><%# FormatDate(Eval("ExpectedSettlementDate")) %></td>
                    <td class="mono muted"><%# Enc(Eval("Reference")) %></td>
                    <td class="muted"><%# FormatDt(Eval("InitiatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun décaissement. Créez-en un ci-dessus.</asp:Panel>
    </div>
</asp:Content>
