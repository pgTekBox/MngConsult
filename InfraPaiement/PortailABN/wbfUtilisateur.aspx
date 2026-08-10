<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfUtilisateur.aspx.vb" Inherits="PortailABN.wbfUtilisateur" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .backlink { display:inline-block; margin-bottom:14px; font-weight:700; text-decoration:none; color:var(--muted); }
        .backlink:hover { color:var(--primary); }
        .meta { color:var(--muted); font-size:13px; margin:0; }
        .chk { display:flex; align-items:center; gap:8px; }
        .chk-hint { font-size:12px; color:var(--muted); margin-top:4px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <a href="wbfUtilisateurs.aspx" class="backlink">← Utilisateurs</a>

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouvel utilisateur" /></h1>
            <p class="meta"><asp:Literal ID="litMeta" runat="server" /></p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card">
        <div class="form-grid">
            <div class="field"><label>Prénom</label><asp:TextBox ID="tbPrenom" runat="server" /></div>
            <div class="field"><label>Nom</label><asp:TextBox ID="tbNom" runat="server" /></div>
            <div class="field full"><label>Courriel *</label><asp:TextBox ID="tbEmail" runat="server" TextMode="Email" /></div>
            <div class="field full">
                <label><asp:Literal ID="litPwdLabel" runat="server" Text="Mot de passe *" /></label>
                <asp:TextBox ID="tbPassword" runat="server" TextMode="Password" placeholder="••••••••" />
                <div class="chk-hint"><asp:Literal ID="litPwdHint" runat="server" Text="Minimum 8 caractères." /></div>
            </div>
            <div class="field">
                <div class="chk"><asp:CheckBox ID="cbAdmin" runat="server" /><label style="margin:0">Administrateur</label></div>
                <div class="chk-hint">Peut gérer les utilisateurs, les clés d'API et les webhooks.</div>
            </div>
            <div class="field">
                <div class="chk"><asp:CheckBox ID="cbActif" runat="server" Checked="true" /><label style="margin:0">Compte actif</label></div>
                <div class="chk-hint">Un compte désactivé ne peut plus se connecter.</div>
            </div>
        </div>
        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <a href="wbfUtilisateurs.aspx" class="btn btn-ghost">Annuler</a>
        </div>
    </div>
</asp:Content>
