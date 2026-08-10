<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfFournisseur.aspx.vb" Inherits="PortailABN.wbfFournisseur" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .backlink { display:inline-block; margin-bottom:14px; font-weight:700; text-decoration:none; color:var(--muted); }
        .backlink:hover { color:var(--primary); }
        .meta { color:var(--muted); font-size:13px; margin:0; }
        .sect { font-size:15px; font-weight:800; margin:26px 0 4px; }
        .sect-sub { color:var(--muted); font-size:13px; margin:0 0 14px; }
        .bank input { font-family:Consolas,monospace; }
        .eft-note { font-size:12px; color:var(--muted); margin-top:10px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <a href="wbfFournisseurs.aspx" class="backlink">← Fournisseurs</a>

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouveau fournisseur" /></h1>
            <p class="meta"><asp:Literal ID="litMeta" runat="server" /></p>
        </div>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card">
        <div class="form-grid">
            <div class="field"><label>Type</label>
                <asp:DropDownList ID="ddlType" runat="server">
                    <asp:ListItem Value="Entreprise">Entreprise</asp:ListItem>
                    <asp:ListItem Value="Particulier">Particulier</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field"><label>Statut</label>
                <asp:DropDownList ID="ddlStatut" runat="server">
                    <asp:ListItem Value="Actif">Actif</asp:ListItem>
                    <asp:ListItem Value="Inactif">Inactif</asp:ListItem>
                    <asp:ListItem Value="Bloque">Bloqué</asp:ListItem>
                </asp:DropDownList>
            </div>
            <div class="field full"><label>Nom / raison sociale *</label><asp:TextBox ID="tbNom" runat="server" /></div>
            <div class="field"><label>Référence externe (votre ID)</label><asp:TextBox ID="tbRef" runat="server" /></div>
            <div class="field"><label>Courriel</label><asp:TextBox ID="tbEmail" runat="server" TextMode="Email" /></div>
            <div class="field"><label>Téléphone</label><asp:TextBox ID="tbTel" runat="server" /></div>
            <div class="field"><label>Adresse</label><asp:TextBox ID="tbAdr1" runat="server" /></div>
            <div class="field"><label>Ville</label><asp:TextBox ID="tbVille" runat="server" /></div>
            <div class="field"><label>Province</label><asp:TextBox ID="tbProv" runat="server" /></div>
            <div class="field"><label>Code postal</label><asp:TextBox ID="tbCP" runat="server" /></div>
        </div>

        <div class="sect">Coordonnées bancaires (pour l'EFT)</div>
        <p class="sect-sub">Compte à <strong>créditer</strong> lors d'un décaissement. Requises pour inclure ce fournisseur dans un fichier CPA-005.</p>
        <div class="form-grid bank">
            <div class="field"><label>Institution (3 chiffres)</label><asp:TextBox ID="tbInst" runat="server" MaxLength="3" placeholder="815" /></div>
            <div class="field"><label>Transit (5 chiffres)</label><asp:TextBox ID="tbTransit" runat="server" MaxLength="5" placeholder="30000" /></div>
            <div class="field"><label>N° de compte (max 12)</label><asp:TextBox ID="tbAccount" runat="server" MaxLength="12" placeholder="1234567" /></div>
        </div>
        <div class="eft-note">Laissez les trois champs vides si vous ne connaissez pas encore les coordonnées ; le fournisseur ne sera simplement pas « prêt EFT ».</div>

        <div class="form-actions">
            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="Enregistrer" OnClick="btnSave_Click" />
            <a href="wbfFournisseurs.aspx" class="btn btn-ghost">Annuler</a>
        </div>
    </div>
</asp:Content>
