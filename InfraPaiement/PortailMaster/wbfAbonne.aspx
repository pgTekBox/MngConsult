<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAbonne.aspx.vb" Inherits="PortailMaster.wbfAbonne" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .section-title { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em;
                         color: var(--muted); margin: 26px 0 12px 0; }
        .section-title:first-of-type { margin-top: 4px; }
        .req { color: var(--danger); }
        .meta { color: var(--muted); font-size: 13px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouvel abonné" /></h1>
            <p class="sub"><asp:Literal ID="litMeta" runat="server" Text="Créer une nouvelle entreprise abonnée." /></p>
        </div>
        <div style="display:flex; gap:10px; align-items:center">
            <asp:HyperLink ID="lnkGrandLivre" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkPaiements" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkFournisseurs" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkDecaissements" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkInterac" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkApiKeys" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkWebhooks" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkClients" runat="server" CssClass="btn" Visible="false" />
            <asp:HyperLink ID="lnkExport" runat="server" CssClass="btn" Visible="false" />
            <a class="btn btn-ghost" href="wbfAbonnes.aspx">← Retour à la liste</a>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok">
        <asp:Literal ID="litOk" runat="server" />
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <div class="card">

        <div class="section-title">Identification</div>
        <div class="form-grid">
            <div class="field full">
                <label>Raison sociale <span class="req">*</span></label>
                <asp:TextBox ID="tbRaisonSociale" runat="server" />
            </div>
            <div class="field">
                <label>Nom d'affichage</label>
                <asp:TextBox ID="tbNomAffichage" runat="server" />
            </div>
            <div class="field">
                <label>Numéro d'entreprise (NEQ / BN)</label>
                <asp:TextBox ID="tbNumeroEntreprise" runat="server" />
            </div>
        </div>

        <div class="section-title">Coordonnées</div>
        <div class="form-grid">
            <div class="field">
                <label>Courriel de contact</label>
                <asp:TextBox ID="tbCourriel" runat="server" TextMode="Email" />
            </div>
            <div class="field">
                <label>Téléphone</label>
                <asp:TextBox ID="tbTelephone" runat="server" />
            </div>
            <div class="field full">
                <label>Adresse</label>
                <asp:TextBox ID="tbAdresse1" runat="server" />
            </div>
            <div class="field full">
                <label>Complément d'adresse</label>
                <asp:TextBox ID="tbAdresse2" runat="server" />
            </div>
            <div class="field">
                <label>Ville</label>
                <asp:TextBox ID="tbVille" runat="server" />
            </div>
            <div class="field">
                <label>Province / État</label>
                <asp:TextBox ID="tbProvince" runat="server" />
            </div>
            <div class="field">
                <label>Code postal</label>
                <asp:TextBox ID="tbCodePostal" runat="server" />
            </div>
            <div class="field">
                <label>Pays</label>
                <asp:TextBox ID="tbPays" runat="server" Text="Canada" />
            </div>
        </div>

        <div class="section-title">Plateforme</div>
        <div class="form-grid">
            <div class="field">
                <label>Devise</label>
                <asp:DropDownList ID="ddlDevise" runat="server">
                    <asp:ListItem Value="CAD">CAD — Dollar canadien</asp:ListItem>
                    <asp:ListItem Value="USD">USD — Dollar américain</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field">
                <label>Statut</label>
                <asp:DropDownList ID="ddlStatut" runat="server">
                    <asp:ListItem Value="Prospect">Prospect</asp:ListItem>
                    <asp:ListItem Value="Actif">Actif</asp:ListItem>
                    <asp:ListItem Value="Suspendu">Suspendu</asp:ListItem>
                    <asp:ListItem Value="Ferme">Fermé</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field">
                <label>Statut KYB (conformité)</label>
                <asp:DropDownList ID="ddlKyb" runat="server">
                    <asp:ListItem Value="NonDebute">Non débuté</asp:ListItem>
                    <asp:ListItem Value="EnCours">En cours</asp:ListItem>
                    <asp:ListItem Value="Verifie">Vérifié</asp:ListItem>
                    <asp:ListItem Value="Rejete">Rejeté</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field full">
                <label>Notes internes</label>
                <asp:TextBox ID="tbNotes" runat="server" TextMode="MultiLine" />
            </div>
        </div>

        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <a class="btn btn-ghost" href="wbfAbonnes.aspx">Annuler</a>
        </div>

    </div>

    <asp:Panel ID="pnlKyb" runat="server" Visible="false" CssClass="card" style="margin-top:24px">
        <div class="section-title" style="margin-top:0">Vérification KYB (Know Your Business)</div>
        <asp:Literal ID="litKyb" runat="server" />
        <div class="form-actions">
            <asp:Button ID="btnRunKyb" runat="server" CssClass="btn btn-primary" Text="Lancer une vérification KYB (sandbox)" OnClick="btnRunKyb_Click"
                OnClientClick="return confirm('Lancer une vérification KYB via le fournisseur configuré (sandbox) ? Le statut KYB sera mis à jour selon le résultat.');" />
        </div>
        <div class="meta" style="margin-top:8px">Connecteur abstrait + fournisseur sandbox simulé (le vrai — Trulioo/Onfido — est gaté par le contrat). Déclencheurs de test : raison sociale contenant « REJECT » ou n° d'entreprise finissant par 0000 → Rejeté ; informations incomplètes → Revue.</div>
    </asp:Panel>

    <asp:Panel ID="pnlOffboard" runat="server" Visible="false" CssClass="card" style="margin-top:24px; border-color: rgba(220,38,38,.28)">
        <div class="section-title" style="margin-top:0; color:var(--danger)">Offboarding — clôture du compte</div>
        <asp:Literal ID="litPreflight" runat="server" />
        <div class="form-actions">
            <asp:Button ID="btnClose" runat="server" CssClass="btn" Text="Clôturer le compte" OnClick="btnClose_Click"
                OnClientClick="return confirm('Clôturer ce compte abonné ? Les accès (utilisateurs, clés API, webhook) seront désactivés et les contreparties gelées.');" />
            <asp:Button ID="btnReactivate" runat="server" CssClass="btn" Visible="false" Text="Réactiver le compte" OnClick="btnReactivate_Click"
                OnClientClick="return confirm('Réactiver ce compte clôturé ? Le statut repasse à Actif et les utilisateurs retrouvent l''accès. Les clés d''API restent révoquées, le webhook et les contreparties restent à ré-habiliter.');" />
            <asp:Button ID="btnAnonymize" runat="server" CssClass="btn" Text="Anonymiser les données" OnClick="btnAnonymize_Click"
                style="color:var(--danger)"
                OnClientClick="return confirm('ANONYMISER définitivement les données personnelles de cet abonné ? Action IRRÉVERSIBLE. Le grand livre et les paiements sont conservés.');" />
        </div>
        <div class="meta" style="margin-top:8px">
            La clôture est refusée tant que l'abonné détient des fonds ou a des paiements en cours. L'anonymisation
            (RGPD) n'est possible qu'après clôture et ne touche jamais le grand livre ni les paiements.
        </div>
        <asp:Literal ID="litAudit" runat="server" />
    </asp:Panel>

</asp:Content>
