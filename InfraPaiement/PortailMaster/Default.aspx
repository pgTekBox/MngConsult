<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Default.aspx.vb" Inherits="PortailMaster.Default" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .card.link { text-decoration: none; color: inherit; display: block; transition: border-color .15s, transform .12s; }
        .card.link:hover { border-color: var(--primary); transform: translateY(-2px); }
        .card h3 { margin: 0 0 6px 0; font-size: 16px; }
        .card p { margin: 0; color: var(--muted); font-size: 13px; }
        .card .soon { display: inline-block; margin-top: 12px; font-size: 11px; font-weight: 700;
                      color: var(--secondary); background: rgba(79,70,229,.10); border-radius: 999px; padding: 3px 10px; }
        .card .go { display: inline-block; margin-top: 12px; font-size: 12px; font-weight: 800; color: var(--primary); }
        .tiles { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 28px; }
        .tile { background: #fff; border: 1px solid var(--line); border-radius: 16px; padding: 18px 20px; }
        .tile .lbl { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; color: var(--muted); }
        .tile .val { font-size: 24px; font-weight: 800; margin-top: 6px; letter-spacing: -.02em; }
        .inv-ok { color: var(--ok); font-weight: 800; }
        .inv-bad { color: var(--danger); font-weight: 800; }
        .section-lbl { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); margin: 4px 0 12px 0; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Bienvenue<asp:Literal ID="litHello" runat="server" /></h1>
            <p class="sub">Portail maître — gestion des abonnés de la plateforme de paiement.</p>
        </div>
    </div>

    <div class="section-lbl">Trésorerie de la plateforme</div>
    <div class="tiles">
        <div class="tile">
            <div class="lbl">En fiducie (banque)</div>
            <div class="val"><asp:Literal ID="litTrust" runat="server" /></div>
        </div>
        <div class="tile">
            <div class="lbl">Dû aux abonnés (solde + réserve)</div>
            <div class="val"><asp:Literal ID="litOwed" runat="server" /></div>
        </div>
        <div class="tile">
            <div class="lbl">Frais perçus</div>
            <div class="val"><asp:Literal ID="litFees" runat="server" /></div>
        </div>
        <div class="tile">
            <div class="lbl">Équilibre comptable</div>
            <div class="val"><asp:Literal ID="litInvariant" runat="server" /></div>
        </div>
    </div>

    <div class="section-lbl">Modules</div>
    <div class="cards">
        <a class="card link" href="wbfSupervision.aspx">
            <h3>Supervision</h3>
            <p>Volumes, statuts, paiements en souffrance, retours et webhooks en échec.</p>
            <span class="go">Ouvrir →</span>
        </a>
        <a class="card link" href="wbfAbonnes.aspx">
            <h3>Abonnés</h3>
            <p>Créer, activer et suivre les entreprises abonnées à la plateforme.</p>
            <span class="go">Ouvrir →</span>
        </a>
        <a class="card link" href="wbfEftBatches.aspx">
            <h3>EFT (CPA-005)</h3>
            <p>Génération des fichiers AFT, règlement et traitement des retours.</p>
            <span class="go">Ouvrir →</span>
        </a>
        <a class="card link" href="wbfRapprochement.aspx">
            <h3>Rapprochement bancaire</h3>
            <p>Fiducie ↔ relevé bancaire : écart et éléments non rapprochés.</p>
            <span class="go">Ouvrir →</span>
        </a>
        <div class="card">
            <h3>Transactions EFT</h3>
            <p>Encaissements clients et paiements fournisseurs par abonné.</p>
            <span class="soon">À venir</span>
        </div>
        <div class="card">
            <h3>Conformité (KYB)</h3>
            <p>Vérification d'identité des entreprises et suivi réglementaire.</p>
            <span class="soon">À venir</span>
        </div>
    </div>

</asp:Content>
