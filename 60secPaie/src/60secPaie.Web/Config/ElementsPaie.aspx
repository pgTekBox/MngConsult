<%@ Page Title="Éléments de paie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="ElementsPaie.aspx.vb" Inherits="Paie60Sec.Web.PageElementsPaie" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <div class="sous-menu">
        <a runat="server" href="~/Config/Compagnie.aspx">Ma compagnie</a>
        <a runat="server" href="~/Config/ElementsPaie.aspx" class="actif">Éléments de paie</a>
        <a runat="server" href="~/Config/Utilisateurs.aspx">Utilisateurs</a>
    </div>

    <div class="deux-colonnes">
        <div class="carte">
            <div class="barre">
                <h2>Éléments de paie</h2>
                <a runat="server" href="~/Config/ElementsPaie.aspx" class="bouton secondaire">Nouvel élément</a>
            </div>
            <div class="table-defilante">
                <asp:Repeater ID="rptElements" runat="server">
                    <HeaderTemplate>
                        <table class="liste"><thead><tr><th>Nom</th><th>Catégorie</th><th>Statut</th></tr></thead><tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr class='<%# If(CBool(Eval("Actif")), "", "inactif") %>'>
                            <td><a href='ElementsPaie.aspx?id=<%# Eval("Id") %>'><%#: Eval("Description") %></a></td>
                            <td><%#: LibelleCategorie(Eval("CategorieCode")) %></td>
                            <td><%# If(CBool(Eval("Actif")), "Actif", "Inactif") %></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
            </div>
        </div>

        <div>
            <fieldset>
                <legend><asp:Literal ID="litTitreFormulaire" runat="server" /></legend>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDescription" CssClass="requis">Description</asp:Label>
                    <asp:TextBox ID="txtDescription" runat="server" MaxLength="100" /></div>
                <div class="champ" style="margin-top:12px"><asp:Label runat="server" AssociatedControlID="ddlCategorie" CssClass="requis">Catégorie de paie</asp:Label>
                    <asp:DropDownList ID="ddlCategorie" runat="server" AutoPostBack="true" /></div>
                <div class="champ" style="margin-top:12px"><asp:Label runat="server" AssociatedControlID="txtCompteGL">Compte de grand livre</asp:Label>
                    <asp:TextBox ID="txtCompteGL" runat="server" MaxLength="30" /></div>
                <div class="cases" style="margin-top:12px">
                    <span><asp:CheckBox ID="chkActif" runat="server" Text="Actif" Checked="true" /></span>
                    <span><asp:CheckBox ID="chkMasquer" runat="server" Text="Ne pas afficher sur le talon de paie" /></span>
                </div>
                <div class="actions">
                    <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
                    <asp:Button ID="btnSupprimer" runat="server" Text="Supprimer" CssClass="danger" Visible="false"
                        OnClientClick="return confirm('Supprimer cet élément de paie ?');" />
                </div>
            </fieldset>

            <div class="carte">
                <h2>Assujettissement de la catégorie</h2>
                <p class="note">Vous n'avez rien à configurer : la catégorie détermine les retenues, les cotisations de l'employeur et les cases des feuillets.</p>
                <asp:Literal ID="litMatrice" runat="server" />
            </div>
        </div>
    </div>
</asp:Content>
