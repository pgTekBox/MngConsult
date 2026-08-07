<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfGrandLivre.aspx.vb" Inherits="PortailMaster.wbfGrandLivre" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .tiles { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 16px; margin-bottom: 22px; }
        .tile { background: #fff; border: 1px solid var(--line); border-radius: 16px; padding: 18px 20px; }
        .tile .lbl { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; color: var(--muted); }
        .tile .val { font-size: 26px; font-weight: 800; margin-top: 6px; letter-spacing: -.02em; }
        .tile.solde .val { color: var(--primary); }
        .tile.reserve .val { color: var(--secondary); }
        .grid-2 { display: grid; grid-template-columns: 1.1fr 1.6fr; gap: 22px; align-items: start; }
        @media (max-width: 860px) { .grid-2 { grid-template-columns: 1fr; } }
        .card h3 { margin: 0 0 14px 0; font-size: 16px; }
        .money-input { position: relative; }
        .num { text-align: right; font-variant-numeric: tabular-nums; }
        .pos { color: var(--ok); font-weight: 700; }
        .neg { color: var(--danger); font-weight: 700; }
        .hint { font-size: 12px; color: var(--muted); margin-top: 6px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="crumbs">
                <a href="wbfAbonnes.aspx">Abonnés</a> ›
                <a id="lnkAbonne" runat="server">Abonné</a> › Grand livre
            </div>
            <h1>Grand livre</h1>
            <p class="sub">Solde et écritures de <asp:Literal ID="litAbonne" runat="server" />.</p>
        </div>
        <div style="display:flex; gap:10px; align-items:center">
            <a id="lnkPaiements" runat="server" class="btn btn-ghost">Paiements</a>
            <a id="lnkClients" runat="server" class="btn btn-ghost">Clients</a>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok">
        <asp:Literal ID="litOk" runat="server" />
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <div class="tiles">
        <div class="tile solde">
            <div class="lbl">Solde disponible</div>
            <div class="val"><asp:Literal ID="litSolde" runat="server" /></div>
        </div>
        <div class="tile reserve">
            <div class="lbl">Réserve</div>
            <div class="val"><asp:Literal ID="litReserve" runat="server" /></div>
        </div>
        <div class="tile">
            <div class="lbl">EFT en cours (entrant)</div>
            <div class="val"><asp:Literal ID="litEftIn" runat="server" /></div>
        </div>
        <div class="tile">
            <div class="lbl">EFT en cours (sortant)</div>
            <div class="val"><asp:Literal ID="litEftOut" runat="server" /></div>
        </div>
    </div>

    <div class="grid-2">

        <div class="card">
            <h3>Nouvelle écriture</h3>
            <div class="field">
                <label>Opération</label>
                <asp:DropDownList ID="ddlOperation" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlOperation_Changed">
                    <asp:ListItem Value="Encaissement">Encaissement (dépôt au solde)</asp:ListItem>
                    <asp:ListItem Value="Paiement">Paiement (sortie du solde)</asp:ListItem>
                    <asp:ListItem Value="MiseEnReserve">Mise en réserve</asp:ListItem>
                    <asp:ListItem Value="LiberationReserve">Libération de réserve</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field">
                <label>Montant (CAD)</label>
                <asp:TextBox ID="tbMontant" runat="server" CssClass="num" placeholder="0.00" />
            </div>
            <div class="field" id="rowFrais" runat="server">
                <label>Frais retenus (CAD)</label>
                <asp:TextBox ID="tbFrais" runat="server" CssClass="num" placeholder="0.00" Text="0" />
                <div class="hint">Portion de l'encaissement conservée par la plateforme (produit).</div>
            </div>
            <div class="field">
                <label>Description</label>
                <asp:TextBox ID="tbDescription" runat="server" />
            </div>
            <asp:HiddenField ID="hfIdem" runat="server" />
            <div class="form-actions">
                <asp:Button ID="btnPost" runat="server" CssClass="btn btn-primary" Text="Comptabiliser" OnClick="btnPost_Click" />
            </div>
        </div>

        <div class="card">
            <h3>Journal des écritures</h3>
            <div class="table-wrap" style="border:none">
                <asp:Repeater ID="rptJournal" runat="server">
                    <HeaderTemplate>
                        <table class="grid">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Type</th>
                                    <th>Description</th>
                                    <th class="num">Δ Solde</th>
                                    <th class="num">Δ Réserve</th>
                                </tr>
                            </thead>
                            <tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td class="muted"><%# FormatDate(Eval("EffectiveDate")) %></td>
                            <td><%# Server.HtmlEncode(LabelType(Eval("TxnType"))) %></td>
                            <td class="muted"><%# Server.HtmlEncode(If(Eval("Description"), "").ToString()) %></td>
                            <td class="num"><%# MoneyDelta(Eval("DeltaSoldeCents")) %></td>
                            <td class="num"><%# MoneyDelta(Eval("DeltaReserveCents")) %></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate>
                            </tbody>
                        </table>
                    </FooterTemplate>
                </asp:Repeater>
                <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                    Aucune écriture pour le moment. Comptabilisez un premier mouvement à gauche.
                </asp:Panel>
            </div>
        </div>

    </div>

</asp:Content>
