<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfUtilisateur.aspx.vb" Inherits="PortailMaster.wbfUtilisateur" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .section-title { font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em;
                         color: var(--muted); margin: 26px 0 12px 0; }
        .section-title:first-of-type { margin-top: 4px; }
        .req { color: var(--danger); }
        .hint { font-size: 12px; color: var(--muted); margin-top: 6px; }
        .checks { display: flex; gap: 26px; flex-wrap: wrap; }
        .check label { display: inline-flex; align-items: center; gap: 8px; font-weight: 700; font-size: 14px; cursor: pointer; }
        .check .desc { font-size: 12px; color: var(--muted); font-weight: 400; margin-top: 4px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouvel utilisateur" /></h1>
            <p class="sub"><asp:Literal ID="litMeta" runat="server" Text="Créer un compte d'accès au portail maître." /></p>
        </div>
        <a class="btn btn-ghost" href="wbfUtilisateurs.aspx">← Retour à la liste</a>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok">
        <asp:Literal ID="litOk" runat="server" />
    </asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <div class="card">

        <div class="section-title">Identité</div>
        <div class="form-grid">
            <div class="field">
                <label>Prénom</label>
                <asp:TextBox ID="tbPrenom" runat="server" />
            </div>
            <div class="field">
                <label>Nom</label>
                <asp:TextBox ID="tbNom" runat="server" />
            </div>
            <div class="field full">
                <label>Courriel <span class="req">*</span></label>
                <asp:TextBox ID="tbEmail" runat="server" TextMode="Email" />
            </div>
        </div>

        <div class="section-title">Accès</div>
        <div class="checks">
            <div class="check">
                <label><asp:CheckBox ID="cbActif" runat="server" Checked="true" /> Compte actif</label>
                <div class="desc">Décoché : l'utilisateur ne peut plus se connecter.</div>
            </div>
            <div class="check">
                <label><asp:CheckBox ID="cbSuperAdmin" runat="server" /> Super-administrateur</label>
                <div class="desc">Peut gérer les utilisateurs du portail.</div>
            </div>
        </div>

        <div class="section-title">Mot de passe</div>
        <div class="form-grid">
            <div class="field full">
                <label><asp:Literal ID="litPwdLabel" runat="server" Text="Mot de passe" /></label>
                <asp:TextBox ID="tbPassword" runat="server" TextMode="Password" autocomplete="new-password" />
                <div class="hint"><asp:Literal ID="litPwdHint" runat="server" Text="Minimum 8 caractères." /></div>
            </div>
        </div>

        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <a class="btn btn-ghost" href="wbfUtilisateurs.aspx">Annuler</a>
        </div>

    </div>

</asp:Content>
