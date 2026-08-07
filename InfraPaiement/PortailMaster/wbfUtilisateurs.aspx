<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfUtilisateurs.aspx.vb" Inherits="PortailMaster.wbfUtilisateurs" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .filters { display: flex; gap: 10px; align-items: center; margin-bottom: 18px; flex-wrap: wrap; }
        .filters input[type="text"] {
            padding: 10px 13px; border: 1px solid var(--line); border-radius: 11px;
            font-size: 14px; font-family: var(--font); outline: none; background: #fff; min-width: 260px;
        }
        .filters input:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(14,165,164,.13); }
        .count { color: var(--muted); font-size: 13px; margin-left: auto; }
        .muted { color: var(--muted); }
        .badge-super { background: rgba(79,70,229,.12); color: var(--secondary); }
        .badge-role  { background: rgba(100,116,139,.14); color: #475569; }
        .badge-inactif { background: rgba(100,116,139,.16); color: #475569; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Utilisateurs du portail</h1>
            <p class="sub">Comptes du personnel de la plateforme (accès au portail maître).</p>
        </div>
        <a class="btn btn-primary" href="wbfUtilisateur.aspx">+ Nouvel utilisateur</a>
    </div>

    <div class="filters">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel)…" />
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Filtrer" OnClick="btnSearch_Click" />
        <span class="count"><asp:Literal ID="litCount" runat="server" /></span>
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err">
        <asp:Literal ID="litError" runat="server" />
    </asp:Panel>

    <div class="table-wrap">
        <asp:Repeater ID="rptUsers" runat="server">
            <HeaderTemplate>
                <table class="grid">
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Courriel</th>
                            <th>Rôle</th>
                            <th>Statut</th>
                            <th>Dernière connexion</th>
                            <th>Créé</th>
                        </tr>
                    </thead>
                    <tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td><a class="rowlink" href='wbfUtilisateur.aspx?id=<%# Eval("Id") %>'><%# Server.HtmlEncode(NomComplet(Eval("FirstName"), Eval("LastName"))) %></a></td>
                    <td class="muted"><%# Server.HtmlEncode(If(Eval("Email"), "").ToString()) %></td>
                    <td><span class='badge <%# BadgeRole(Eval("IsSuperAdmin")) %>'><%# LabelRole(Eval("IsSuperAdmin")) %></span></td>
                    <td><span class='badge <%# BadgeActif(Eval("IsActive")) %>'><%# LabelActif(Eval("IsActive")) %></span></td>
                    <td class="muted"><%# FormatDateTime2(Eval("LastLoginUtc")) %></td>
                    <td class="muted"><%# FormatDate(Eval("CreatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate>
                    </tbody>
                </table>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
            Aucun utilisateur ne correspond. <a href="wbfUtilisateur.aspx">Créer un utilisateur</a>.
        </asp:Panel>
    </div>

</asp:Content>
