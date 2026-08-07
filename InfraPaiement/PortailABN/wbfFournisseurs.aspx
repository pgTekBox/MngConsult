<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfFournisseurs.aspx.vb" Inherits="PortailABN.wbfFournisseurs" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        details.add { margin-bottom: 22px; }
        details.add summary { cursor: pointer; font-weight: 800; font-size: 15px; padding: 4px 0; color: var(--secondary); }
        .toolbar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }
        .toolbar input[type=text] { padding:10px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font); min-width:260px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Fournisseurs</h1>
            <p class="sub">Les bénéficiaires de votre organisation (contreparties de décaissement EFT).</p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <details class="add" runat="server" id="detAdd">
        <summary>+ Ajouter un fournisseur</summary>
        <div class="card" style="margin-top:12px">
            <div class="form-grid">
                <div class="field"><label>Type</label>
                    <asp:DropDownList ID="ddlType" runat="server" CssClass="mono">
                        <asp:ListItem Value="Entreprise">Entreprise</asp:ListItem>
                        <asp:ListItem Value="Particulier">Particulier</asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div class="field"><label>Référence externe (votre ID)</label><asp:TextBox ID="tbRef" runat="server" /></div>
                <div class="field full"><label>Nom / raison sociale *</label><asp:TextBox ID="tbNom" runat="server" /></div>
                <div class="field"><label>Courriel</label><asp:TextBox ID="tbEmail" runat="server" TextMode="Email" /></div>
                <div class="field"><label>Téléphone</label><asp:TextBox ID="tbTel" runat="server" /></div>
                <div class="field"><label>Ville</label><asp:TextBox ID="tbVille" runat="server" /></div>
                <div class="field"><label>Province</label><asp:TextBox ID="tbProv" runat="server" /></div>
            </div>
            <div class="form-actions">
                <asp:Button ID="btnAdd" runat="server" CssClass="btn btn-primary" Text="Créer le fournisseur" OnClick="btnAdd_Click" />
            </div>
        </div>
    </details>

    <div class="toolbar">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel, référence)…" />
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" OnClick="btnSearch_Click" />
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Nom</th><th>Type</th><th>Référence</th><th>Courriel</th><th>Ville</th><th>Statut</th><th>Créé</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td style="font-weight:700"><%# Enc(Eval("Nom")) %></td>
                    <td class="muted"><%# Enc(Eval("TypeFournisseur")) %></td>
                    <td class="mono muted"><%# Enc(Eval("ReferenceExterne")) %></td>
                    <td class="muted"><%# Enc(Eval("CourrielContact")) %></td>
                    <td class="muted"><%# Enc(Eval("Ville")) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Statut")) %>'><%# Enc(Eval("Statut")) %></span></td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun fournisseur. Ajoutez-en un ci-dessus.</asp:Panel>
    </div>
</asp:Content>
