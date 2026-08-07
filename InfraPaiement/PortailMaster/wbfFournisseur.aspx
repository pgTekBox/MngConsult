<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfFournisseur.aspx.vb" Inherits="PortailMaster.wbfFournisseur" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .section-title { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); margin: 26px 0 12px 0; }
        .section-title:first-of-type { margin-top: 4px; }
        .req { color: var(--danger); }
        .hint { font-size: 12px; color: var(--muted); margin-top: 6px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <div class="crumbs">
                <a href="wbfAbonnes.aspx">Abonnés</a> › <a id="lnkAbonne" runat="server">Abonné</a> ›
                <asp:HyperLink ID="lnkList" runat="server" Text="Fournisseurs" /> › <asp:Literal ID="litCrumb" runat="server" Text="Nouveau" />
            </div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouveau fournisseur" /></h1>
            <p class="sub"><asp:Literal ID="litMeta" runat="server" /></p>
        </div>
        <asp:HyperLink ID="btnBack" runat="server" CssClass="btn btn-ghost" Text="← Retour" />
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card">
        <div class="section-title">Identification</div>
        <div class="form-grid">
            <div class="field">
                <label>Type</label>
                <asp:DropDownList ID="ddlType" runat="server">
                    <asp:ListItem Value="Entreprise">Entreprise</asp:ListItem>
                    <asp:ListItem Value="Particulier">Particulier</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field">
                <label>Statut</label>
                <asp:DropDownList ID="ddlStatut" runat="server">
                    <asp:ListItem Value="Actif">Actif</asp:ListItem>
                    <asp:ListItem Value="Inactif">Inactif</asp:ListItem>
                    <asp:ListItem Value="Bloque">Bloqué</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field full">
                <label>Nom / Raison sociale <span class="req">*</span></label>
                <asp:TextBox ID="tbNom" runat="server" />
            </div>
            <div class="field full">
                <label>Référence externe</label>
                <asp:TextBox ID="tbReference" runat="server" />
                <div class="hint">Identifiant du fournisseur dans le logiciel de l'abonné (facultatif, unique par abonné).</div>
            </div>
        </div>

        <div class="section-title">Coordonnées</div>
        <div class="form-grid">
            <div class="field"><label>Courriel</label><asp:TextBox ID="tbCourriel" runat="server" TextMode="Email" /></div>
            <div class="field"><label>Téléphone</label><asp:TextBox ID="tbTelephone" runat="server" /></div>
            <div class="field full"><label>Adresse</label><asp:TextBox ID="tbAdresse1" runat="server" /></div>
            <div class="field full"><label>Complément d'adresse</label><asp:TextBox ID="tbAdresse2" runat="server" /></div>
            <div class="field"><label>Ville</label><asp:TextBox ID="tbVille" runat="server" /></div>
            <div class="field"><label>Province / État</label><asp:TextBox ID="tbProvince" runat="server" /></div>
            <div class="field"><label>Code postal</label><asp:TextBox ID="tbCodePostal" runat="server" /></div>
            <div class="field"><label>Pays</label><asp:TextBox ID="tbPays" runat="server" Text="Canada" /></div>
            <div class="field full"><label>Notes internes</label><asp:TextBox ID="tbNotes" runat="server" TextMode="MultiLine" /></div>
        </div>

        <div class="section-title">Coordonnées bancaires (EFT)</div>
        <div class="form-grid">
            <div class="field"><label>Institution (3)</label><asp:TextBox ID="tbBankInstitution" runat="server" MaxLength="3" /></div>
            <div class="field"><label>Transit (5)</label><asp:TextBox ID="tbBankTransit" runat="server" MaxLength="5" /></div>
            <div class="field"><label>N° de compte (12)</label><asp:TextBox ID="tbBankAccount" runat="server" MaxLength="12" /></div>
            <div class="field full"><div class="hint">Requis pour payer ce fournisseur (bénéficiaire) par dépôt CPA-005.</div></div>
        </div>

        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <asp:HyperLink ID="btnCancel" runat="server" CssClass="btn btn-ghost" Text="Annuler" />
        </div>
    </div>
</asp:Content>
