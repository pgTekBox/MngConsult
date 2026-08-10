<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfUtilisateurs.aspx.vb" Inherits="PortailABN.wbfUtilisateurs" %>

<asp:Content ID="cHead" ContentPlaceHolderID="head" runat="server">
    <style>
        .toolbar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }
        .toolbar input[type=text] { padding:10px 13px; border:1px solid var(--line); border-radius:11px; font-size:14px; font-family:var(--font); min-width:260px; }
        table.grid a.rowlink { font-weight:700; text-decoration:none; color:var(--text); }
        table.grid a.rowlink:hover { color:var(--primary); }
        .me { font-size:11px; font-weight:800; color:var(--secondary); background:rgba(79,70,229,.10); padding:2px 7px; border-radius:999px; margin-left:6px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="page-head">
        <div>
            <h1>Utilisateurs</h1>
            <p class="sub">Les personnes de votre organisation qui accèdent à cet espace.</p>
        </div>
        <div><a href="wbfUtilisateur.aspx" class="btn btn-primary">+ Ajouter un utilisateur</a></div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="toolbar">
        <asp:TextBox ID="tbSearch" runat="server" placeholder="Rechercher (nom, courriel)…" />
        <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" OnClick="btnSearch_Click" />
    </div>

    <div class="table-wrap">
        <asp:Repeater ID="rpt" runat="server">
            <HeaderTemplate>
                <table class="grid"><thead><tr>
                    <th>Nom</th><th>Courriel</th><th>Rôle</th><th>Statut</th><th>Dernière connexion</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td>
                        <a class="rowlink" href='wbfUtilisateur.aspx?id=<%# Eval("Id") %>'><%# NomAffiche(Container.DataItem) %></a>
                        <%# IIf(CInt(Eval("Id")) = MonId, "<span class=""me"">vous</span>", "") %>
                    </td>
                    <td class="muted"><%# Enc(Eval("Email")) %></td>
                    <td><span class='badge <%# IIf(CBool(Eval("IsAdmin")),"badge-encours","badge-neutre") %>'><%# IIf(CBool(Eval("IsAdmin")),"Administrateur","Utilisateur") %></span></td>
                    <td><span class='badge <%# IIf(CBool(Eval("IsActive")),"badge-actif","badge-neutre") %>'><%# IIf(CBool(Eval("IsActive")),"Actif","Désactivé") %></span></td>
                    <td class="muted"><%# FormatDt(Eval("LastLoginUtc")) %></td>
                    <td><a href='wbfUtilisateur.aspx?id=<%# Eval("Id") %>'>Modifier</a></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">Aucun utilisateur.</asp:Panel>
    </div>
</asp:Content>
