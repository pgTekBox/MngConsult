<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfPaiements.aspx.vb" Inherits="PortailMaster.wbfPaiements" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .grid-2 { display: grid; grid-template-columns: 1fr 1.7fr; gap: 22px; align-items: start; }
        @media (max-width: 900px) { .grid-2 { grid-template-columns: 1fr; } }
        .card h3 { margin: 0 0 14px 0; font-size: 16px; }
        .num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
        .filters { display: flex; gap: 10px; align-items: center; margin-bottom: 14px; flex-wrap: wrap; }
        .filters select, .filters input[type=text] { padding: 9px 12px; border: 1px solid var(--line); border-radius: 10px; font-size: 14px; font-family: var(--font); }
        .act a { font-weight: 700; text-decoration: none; font-size: 13px; }
        .act .ret { color: var(--danger); margin-left: 10px; }
        .badge-encours { background: rgba(2,132,199,.12); color: #0284c7; }
        .hint { font-size: 12px; color: var(--muted); margin-top: 6px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="crumbs">
                <a href="wbfAbonnes.aspx">Abonnés</a> ›
                <a id="lnkAbonne" runat="server">Abonné</a> › Paiements
            </div>
            <h1>Paiements EFT</h1>
            <p class="sub">Encaissements des clients de <asp:Literal ID="litAbonne" runat="server" />.</p>
        </div>
        <div style="display:flex; gap:10px; align-items:center">
            <a id="lnkGrandLivre" runat="server" class="btn btn-ghost">Grand livre</a>
            <asp:Button ID="btnBatch" runat="server" CssClass="btn" Text="Simuler le règlement (lot)" OnClick="btnBatch_Click" />
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="grid-2">

        <div class="card">
            <h3>Nouvel encaissement</h3>
            <div class="field">
                <label>Client (payeur)</label>
                <asp:DropDownList ID="ddlClient" runat="server" />
                <div class="hint" id="hintNoClient" runat="server" visible="false">Aucun client actif. Créez d'abord un client pour cet abonné.</div>
            </div>
            <div class="field">
                <label>Montant (CAD)</label>
                <asp:TextBox ID="tbMontant" runat="server" CssClass="num" placeholder="0.00" />
            </div>
            <div class="field">
                <label>Frais retenus (CAD)</label>
                <asp:TextBox ID="tbFrais" runat="server" CssClass="num" placeholder="0.00" Text="0" />
            </div>
            <div class="field">
                <label>Description</label>
                <asp:TextBox ID="tbDescription" runat="server" />
            </div>
            <div class="field">
                <label>Référence</label>
                <asp:TextBox ID="tbReference" runat="server" />
            </div>
            <asp:HiddenField ID="hfIdem" runat="server" />
            <div class="form-actions">
                <asp:Button ID="btnCreate" runat="server" CssClass="btn btn-primary" Text="Initier l'encaissement" OnClick="btnCreate_Click" />
            </div>
            <div class="hint">Règlement simulé à T+2. « Régler » force le règlement immédiat ; « Retour » simule un NSF.</div>
        </div>

        <div class="card">
            <h3>Paiements</h3>
            <div class="filters">
                <asp:DropDownList ID="ddlStatut" runat="server">
                    <asp:ListItem Value="">Tous les statuts</asp:ListItem>
                    <asp:ListItem Value="Initie">Initié</asp:ListItem>
                    <asp:ListItem Value="Regle">Réglé</asp:ListItem>
                    <asp:ListItem Value="Retourne">Retourné</asp:ListItem>
                </asp:DropDownList>
                <asp:TextBox ID="tbSearch" runat="server" placeholder="Client, référence…" />
                <asp:Button ID="btnFilter" runat="server" CssClass="btn" Text="Filtrer" OnClick="btnFilter_Click" />
                <span class="count" style="margin-left:auto;color:var(--muted);font-size:13px"><asp:Literal ID="litCount" runat="server" /></span>
            </div>

            <div class="table-wrap" style="border:none">
                <asp:Repeater ID="rptPay" runat="server" OnItemCommand="rptPay_ItemCommand">
                    <HeaderTemplate>
                        <table class="grid">
                            <thead><tr>
                                <th>Date</th><th>Client</th>
                                <th class="num">Montant</th><th class="num">Frais</th><th class="num">Net</th>
                                <th>Statut</th><th>Règlement</th><th></th>
                            </tr></thead><tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td class="muted"><%# FormatDate(Eval("InitiatedUtc")) %></td>
                            <td><%# Server.HtmlEncode(If(Eval("ClientNom"), "—").ToString()) %></td>
                            <td class="num"><%# Money(Eval("AmountCents")) %></td>
                            <td class="num muted"><%# Money(Eval("FeeCents")) %></td>
                            <td class="num"><%# Money(Eval("NetCents")) %></td>
                            <td><span class='badge <%# BadgeStatut(Eval("Status")) %>'><%# LabelStatut(Eval("Status")) %></span></td>
                            <td class="muted"><%# SettlementText(Container.DataItem) %></td>
                            <td class="act">
                                <asp:LinkButton runat="server" Text="Régler" CommandName="settle" CommandArgument='<%# Eval("Id") %>'
                                    Visible='<%# Eval("Status").ToString() = "Initie" %>' />
                                <asp:LinkButton runat="server" CssClass="ret" Text="Retour" CommandName="ret" CommandArgument='<%# Eval("Id") %>'
                                    Visible='<%# Eval("Status").ToString() = "Initie" %>'
                                    OnClientClick="return confirm('Simuler un retour NSF de ce paiement ?');" />
                            </td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
                <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                    Aucun paiement. Initiez un premier encaissement à gauche.
                </asp:Panel>
            </div>
        </div>

    </div>

</asp:Content>
