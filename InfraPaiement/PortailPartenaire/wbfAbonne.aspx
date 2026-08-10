<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAbonne.aspx.vb" Inherits="PortailPartenaire.wbfAbonne" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouvel abonné" /></h1>
            <p class="sub"><asp:Literal ID="litSub" runat="server" Text="Provisionnez un locataire rattaché à votre canal" /></p>
        </div>
        <a href="wbfAbonnes.aspx" class="btn btn-ghost">← Retour</a>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlErr" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litErr" runat="server" /></asp:Panel>

    <%-- ================= MODE CREATION ================= --%>
    <asp:Panel ID="pnlCreate" runat="server" Visible="false">
        <div class="card">
            <div class="form-grid">
                <div class="field full">
                    <label>Raison sociale *</label>
                    <asp:TextBox ID="tbNom" runat="server" placeholder="Ex. Boulangerie Tremblay inc." />
                </div>
                <div class="field">
                    <label>Nom d'affichage</label>
                    <asp:TextBox ID="tbNomAff" runat="server" />
                </div>
                <div class="field">
                    <label>N° d'entreprise (NEQ / BN)</label>
                    <asp:TextBox ID="tbNeq" runat="server" />
                </div>
                <div class="field">
                    <label>Courriel de contact</label>
                    <asp:TextBox ID="tbEmail" runat="server" TextMode="Email" />
                </div>
                <div class="field">
                    <label>Téléphone</label>
                    <asp:TextBox ID="tbTel" runat="server" />
                </div>
                <div class="field full">
                    <label>Adresse</label>
                    <asp:TextBox ID="tbAdr1" runat="server" placeholder="Numéro et rue" />
                </div>
                <div class="field">
                    <label>Ville</label>
                    <asp:TextBox ID="tbVille" runat="server" />
                </div>
                <div class="field">
                    <label>Province</label>
                    <asp:TextBox ID="tbProv" runat="server" placeholder="QC" />
                </div>
                <div class="field">
                    <label>Code postal</label>
                    <asp:TextBox ID="tbCp" runat="server" />
                </div>
            </div>
            <div class="form-actions">
                <asp:Button ID="btnCreate" runat="server" Text="Provisionner l'abonné" CssClass="btn btn-primary" OnClick="btnCreate_Click" />
                <a href="wbfAbonnes.aspx" class="btn btn-ghost">Annuler</a>
            </div>
        </div>
    </asp:Panel>

    <%-- ================= MODE CONSULTATION ================= --%>
    <asp:Panel ID="pnlView" runat="server" Visible="false">
        <div class="cards" style="grid-template-columns: 1.4fr 1fr; align-items:start">

            <div class="card">
                <h3 style="margin:0 0 14px">Coordonnées</h3>
                <table class="grid" style="border:none">
                    <tr><th style="width:180px; background:transparent; text-transform:none">Raison sociale</th><td><asp:Literal ID="litVNom" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Nom d'affichage</th><td><asp:Literal ID="litVNomAff" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">N° d'entreprise</th><td><asp:Literal ID="litVNeq" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Courriel</th><td><asp:Literal ID="litVEmail" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Téléphone</th><td><asp:Literal ID="litVTel" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Adresse</th><td><asp:Literal ID="litVAdr" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Statut</th><td><asp:Literal ID="litVStatut" runat="server" /></td></tr>
                </table>
            </div>

            <div class="card">
                <h3 style="margin:0 0 6px">Conformité KYB</h3>
                <p style="margin:0 0 12px"><asp:Literal ID="litVKyb" runat="server" /></p>
                <asp:Panel ID="pnlKybResult" runat="server" Visible="false"
                    style="background:#f8fafc; border:1px solid var(--line); border-radius:11px; padding:12px 14px; margin-bottom:14px; font-size:13px">
                    <asp:Literal ID="litKybMsg" runat="server" />
                </asp:Panel>
                <asp:Button ID="btnKyb" runat="server" Text="Lancer la vérification KYB" CssClass="btn btn-primary"
                    OnClick="btnKyb_Click" />
                <p class="sub" style="margin-top:12px; font-size:12px">
                    Vérifie l'entreprise (registre, listes de surveillance, adresse) via le fournisseur configuré (sandbox).
                </p>
            </div>

        </div>

        <div class="card" style="margin-top:18px">
            <h3 style="margin:0 0 6px">Intégration API</h3>
            <p class="sub" style="margin:0 0 12px">
                Pour agir au nom de cet abonné via l'API, utilisez votre clé partenaire et ciblez ce locataire avec l'en-tête
                <span class="mono">X-Abonne-Id</span>.
            </p>
            <table class="grid" style="border:none">
                <tr><th style="width:180px; background:transparent; text-transform:none">Identifiant abonné</th><td class="mono"><asp:Literal ID="litVId" runat="server" /></td></tr>
                <tr><th style="background:transparent; text-transform:none">Tenant GUID</th><td class="mono"><asp:Literal ID="litVGuid" runat="server" /></td></tr>
                <tr><th style="background:transparent; text-transform:none">En-tête à envoyer</th><td class="mono">X-Abonne-Id: <asp:Literal ID="litVId2" runat="server" /></td></tr>
            </table>
        </div>
    </asp:Panel>

</asp:Content>
