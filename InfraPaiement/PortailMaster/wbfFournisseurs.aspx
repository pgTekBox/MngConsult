<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfFournisseurs.aspx.vb" Inherits="PortailMaster.wbfFournisseurs" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .crumbs { font-size: 13px; color: var(--muted); margin-bottom: 6px; }
        .crumbs a { text-decoration: none; font-weight: 600; }
        .filters { display: flex; gap: 10px; align-items: center; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input[type="text"], .filters select { padding: 10px 13px; border: 1px solid var(--line); border-radius: 11px; font-size: 14px; font-family: var(--font); outline: none; background: #fff; }
        .filters input[type="text"] { min-width: 240px; }
        .filters input:focus, .filters select:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(14,165,164,.13); }
        .count { color: var(--muted); font-size: 13px; margin-left: auto; }
        .muted { color: var(--muted); }
        .badge-inactif { background: rgba(100,116,139,.16); color: #475569; }
        .badge-type { background: rgba(100,116,139,.12); color: #475569; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <div class="crumbs"><a href="wbfAbonnes.aspx">Abonnés</a> › <a id="lnkAbonne" runat="server">Abonné</a> › Fournisseurs</div>
            <h1>Fournisseurs</h1>
            <p class="sub">Bénéficiaires des décaissements de <asp:Literal ID="litAbonne" runat="server" />.</p>
        </div>
        <asp:HyperLink ID="btnNew" runat="server" CssClass="btn btn-primary" Text="+ Nouveau fournisseur" />
    </div>

    <div class="filters">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel, réf.)…" />
        <asp:DropDownList ID="ddlStatut" runat="server">
            <asp:ListItem Value="">Tous les statuts</asp:ListItem>
            <asp:ListItem Value="Actif">Actif</asp:ListItem>
            <asp:ListItem Value="Inactif">Inactif</asp:ListItem>
            <asp:ListItem Value="Bloque">Bloqué</asp:ListItem>
        </asp:DropDownList>
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Filtrer" OnClick="btnSearch_Click" />
        <span class="count"><asp:Literal ID="litCount" runat="server" /></span>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="table-wrap">
        <asp:Repeater ID="rptList" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Nom</th><th>Type</th><th>Réf. externe</th><th>Courriel</th><th>Ville</th><th>Statut</th><th>Créé</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td><a class="rowlink" href='<%# ItemUrl(Eval("Id")) %>'><%# Server.HtmlEncode(If(Eval("Nom"), "").ToString()) %></a></td>
                    <td><span class="badge badge-type"><%# Server.HtmlEncode(If(Eval("TypeFournisseur"), "").ToString()) %></span></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("ReferenceExterne"), "").ToString()) %></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("CourrielContact"), "").ToString()) %></td>
                    <td class="muted"><%# Server.HtmlEncode(VilleProvince(Eval("Ville"), Eval("Province"))) %></td>
                    <td><span class='badge <%# BadgeStatut(Eval("Statut")) %>'><%# Server.HtmlEncode(LabelStatut(Eval("Statut"))) %></span></td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
            Aucun fournisseur ne correspond. <asp:HyperLink ID="lnkCreateFirst" runat="server" Text="Créer le premier fournisseur" />.
        </asp:Panel>
    </div>
</asp:Content>
