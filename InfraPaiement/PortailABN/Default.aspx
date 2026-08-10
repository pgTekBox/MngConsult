<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Default.aspx.vb" Inherits="PortailABN.Default_aspx" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .kpi.solde .val { color: var(--ok); }
        .kpi.reserve .val { color: var(--secondary); }
        .kpi.eft .val { color: #0284c7; }
        .delta-pos { color: var(--ok); font-weight: 700; }
        .delta-neg { color: var(--danger); font-weight: 700; }
        .onboard { display:flex; align-items:center; gap:18px; background:linear-gradient(135deg, rgba(14,165,164,.08), rgba(79,70,229,.08));
                   border:1px solid rgba(79,70,229,.20); border-radius:16px; padding:18px 22px; margin-bottom:24px; }
        .onboard .ic { font-size:26px; }
        .onboard .txt { flex:1; }
        .onboard .txt strong { font-size:15px; }
        .onboard .txt p { margin:2px 0 0; color:var(--muted); font-size:13px; }
        .onboard .bar { height:8px; background:#eef2f7; border-radius:999px; overflow:hidden; margin-top:8px; max-width:320px; }
        .onboard .bar > span { display:block; height:100%; background:linear-gradient(135deg, var(--primary), var(--secondary)); }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Tableau de bord</h1>
            <p class="sub">Bienvenue, <asp:Literal ID="litHello" runat="server" />. Voici l'état de votre compte 60secPaiement.</p>
        </div>
        <div style="display:flex;gap:10px">
            <a href="wbfEncaissements.aspx" class="btn btn-primary">Encaisser un client</a>
            <a href="wbfDecaissements.aspx" class="btn">Payer un fournisseur</a>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <asp:Panel ID="pnlOnboard" runat="server" Visible="false" CssClass="onboard">
        <span class="ic">🚀</span>
        <div class="txt">
            <strong>Terminez la configuration de votre espace</strong>
            <p><asp:Literal ID="litOnboard" runat="server" /></p>
            <div class="bar"><span id="obBar" runat="server"></span></div>
        </div>
        <a href="wbfBienvenue.aspx" class="btn btn-primary">Continuer</a>
    </asp:Panel>

    <div class="cards" style="margin-bottom:26px">
        <div class="kpi solde">
            <div class="lbl">Solde disponible</div>
            <div class="val"><asp:Literal ID="litSolde" runat="server" /></div>
            <div class="hint">Fonds encaissés, disponibles pour vos décaissements.</div>
        </div>
        <div class="kpi reserve">
            <div class="lbl">Réservé (en cours)</div>
            <div class="val"><asp:Literal ID="litReserve" runat="server" /></div>
            <div class="hint">Décaissements initiés, pas encore réglés.</div>
        </div>
        <div class="kpi eft">
            <div class="lbl">EFT entrant en cours</div>
            <div class="val"><asp:Literal ID="litEftIn" runat="server" /></div>
            <div class="hint">Encaissements initiés, en attente de règlement.</div>
        </div>
        <div class="kpi eft">
            <div class="lbl">EFT sortant en cours</div>
            <div class="val"><asp:Literal ID="litEftOut" runat="server" /></div>
            <div class="hint">Décaissements en compensation bancaire.</div>
        </div>
    </div>

    <h3 style="margin:0 0 12px 0;font-size:16px">Activité récente</h3>
    <div class="table-wrap">
        <asp:Repeater ID="rptJournal" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Date</th><th>Type</th><th>Description</th>
                    <th class="num">Δ Solde</th><th class="num">Δ Réservé</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td class="muted"><%# FormatDate(Eval("EffectiveDate")) %></td>
                    <td><span class="badge badge-neutre"><%# Enc(Eval("TxnType")) %></span></td>
                    <td><%# Enc(Eval("Description")) %></td>
                    <td class="num"><%# DeltaHtml(Eval("DeltaSoldeCents")) %></td>
                    <td class="num"><%# DeltaHtml(Eval("DeltaReserveCents")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlNoJournal" runat="server" Visible="false" CssClass="empty">
            Aucun mouvement pour l'instant. Créez un client puis un encaissement pour démarrer.
        </asp:Panel>
    </div>
</asp:Content>
