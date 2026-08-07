<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfWebhooks.aspx.vb" Inherits="PortailMaster.wbfWebhooks" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .mono { font-family: Consolas, monospace; }
        .badge-encours { background: rgba(2,132,199,.12); color: #0284c7; }
        .badge-off { background: rgba(100,116,139,.16); color: #475569; }
        .hint { font-size: 12px; color: var(--muted); margin-top: 6px; }
        .num { text-align: right; font-variant-numeric: tabular-nums; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="crumbs">
                <a href="wbfAbonnes.aspx">Abonnés</a> ›
                <a id="lnkAbonne" runat="server">Abonné</a> › Webhooks
            </div>
            <h1>Webhooks</h1>
            <p class="sub">Notifications de statut de paiement envoyées à l'application de <asp:Literal ID="litAbonne" runat="server" />.</p>
        </div>
        <asp:Button ID="btnProcess" runat="server" CssClass="btn" Text="Traiter la file maintenant" OnClick="btnProcess_Click" />
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:22px">
        <h3 style="margin:0 0 14px 0;font-size:16px">Endpoint</h3>
        <div class="form-grid">
            <div class="field full">
                <label>URL de notification (HTTPS)</label>
                <asp:TextBox ID="tbUrl" runat="server" placeholder="https://app.exemple.com/webhooks/60sec" />
            </div>
            <div class="field full">
                <label>Secret de signature</label>
                <asp:TextBox ID="tbSecret" runat="server" CssClass="mono" />
                <div class="hint">Sert à vérifier la signature <span class="mono">X-Webhook-Signature: sha256=HMAC(secret, corps)</span>. <asp:LinkButton ID="btnGenSecret" runat="server" Text="Générer un secret" OnClick="btnGenSecret_Click" CausesValidation="false" /></div>
            </div>
            <div class="field">
                <label><asp:CheckBox ID="cbActive" runat="server" Checked="true" /> Actif</label>
            </div>
        </div>
        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
        </div>
        <div class="hint">Événements : <span class="mono">payment.initiated</span>, <span class="mono">payment.settled</span>, <span class="mono">payment.returned</span>. Relances automatiques avec backoff (jusqu'à 5 tentatives).</div>
    </div>

    <div class="card">
        <h3 style="margin:0 0 14px 0;font-size:16px">Livraisons récentes</h3>
        <div class="table-wrap" style="border:none">
            <asp:Repeater ID="rptDeliveries" runat="server">
                <HeaderTemplate>
                    <table class="grid">
                        <thead><tr>
                            <th>#</th><th>Événement</th><th>Paiement</th><th>Statut</th>
                            <th class="num">Tent.</th><th>HTTP</th><th>Prochaine</th><th>Créée</th>
                        </tr></thead><tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="muted"><%# Eval("Id") %></td>
                        <td class="mono"><%# Server.HtmlEncode(If(Eval("EventType"),"").ToString()) %></td>
                        <td class="muted"><%# If(IsDBNull(Eval("PaymentId")),"—",Eval("PaymentId").ToString()) %></td>
                        <td><span class='badge <%# BadgeStatut(Eval("Status")) %>'><%# Server.HtmlEncode(If(Eval("Status"),"").ToString()) %></span></td>
                        <td class="num"><%# Eval("Attempts") %>/<%# Eval("MaxAttempts") %></td>
                        <td class="muted"><%# If(IsDBNull(Eval("ResponseStatus")),"—",Eval("ResponseStatus").ToString()) %></td>
                        <td class="muted"><%# FormatDt(Eval("NextAttemptUtc")) %></td>
                        <td class="muted"><%# FormatDt(Eval("CreatedUtc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                Aucune livraison pour le moment. Elles apparaissent quand un paiement change d'état.
            </asp:Panel>
        </div>
    </div>

</asp:Content>
