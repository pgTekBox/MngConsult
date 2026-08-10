<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfWebhooks.aspx.vb" Inherits="PortailABN.wbfWebhooks" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .evt { display:inline-block; font-family:Consolas,monospace; font-size:12px; background:#f1f5f9; color:#475569; padding:3px 8px; border-radius:8px; margin:2px 4px 2px 0; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Webhooks</h1>
            <p class="sub">Recevez les événements de paiement en temps réel sur votre serveur.</p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:22px">
        <div class="form-grid">
            <div class="field full"><label>URL de notification (HTTPS)</label>
                <asp:TextBox ID="tbUrl" runat="server" placeholder="https://votre-serveur.ca/webhooks/60sec" />
            </div>
            <div class="field full"><label>Secret de signature (HMAC-SHA256)</label>
                <asp:TextBox ID="tbSecret" runat="server" CssClass="mono" />
                <div style="margin-top:8px"><asp:CheckBox ID="cbActive" runat="server" Text=" Endpoint actif" /></div>
            </div>
        </div>
        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <asp:Button ID="btnGenSecret" runat="server" CssClass="btn" Text="Générer un secret" OnClick="btnGenSecret_Click" CausesValidation="false" />
        </div>
    </div>

    <div class="card">
        <h3 style="margin:0 0 10px 0;font-size:15px">Événements envoyés</h3>
        <div>
            <span class="evt">payment.initiated</span>
            <span class="evt">payment.settled</span>
            <span class="evt">payment.returned</span>
            <span class="evt">payout.initiated</span>
            <span class="evt">payout.settled</span>
            <span class="evt">payout.returned</span>
        </div>
        <p class="sub" style="margin-top:12px;font-size:13px">
            Chaque requête <span class="mono">POST</span> porte un en-tête <span class="mono">X-Webhook-Signature</span> =
            HMAC-SHA256 du corps, calculé avec votre secret. Vérifiez-le pour authentifier l'appel.
            Répondez <span class="mono">2xx</span> ; en cas d'échec, la livraison est réessayée (jusqu'à 5 fois, backoff).
        </p>
    </div>
</asp:Content>
