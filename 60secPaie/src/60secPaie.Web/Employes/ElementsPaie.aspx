<%@ Page Title="Éléments de paie de l'employé" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="ElementsPaie.aspx.vb" Inherits="Paie60Sec.Web.PageEmployeElements" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Éléments de paie de <asp:Literal ID="litEmploye" runat="server" /></h1>
    <p class="sous-titre">Ces lignes sont proposées automatiquement à chaque paie. Vous pourrez toujours les ajuster dans l'assistant de paie.</p>

    <div class="carte table-defilante">
        <asp:Repeater ID="rptLignes" runat="server">
            <HeaderTemplate>
                <table class="liste"><thead><tr>
                    <th>Élément de paie</th><th>Catégorie</th><th class="num">Heures</th><th class="num">Taux horaire</th><th class="num">Montant</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td><%#: Eval("Description") %></td>
                    <td><%#: LibelleCategorie(Eval("CategorieCode")) %></td>
                    <td class="num"><%#: Nombre(Eval("Heures")) %></td>
                    <td class="num"><%#: If(Convert.ToDecimal(Eval("Taux")) > 0D, Argent(Eval("Taux")), "") %></td>
                    <td class="num"><%#: Argent(Eval("Total")) %></td>
                    <td><asp:LinkButton runat="server" CommandName="Supprimer" CommandArgument='<%# Eval("Id") %>'>Retirer</asp:LinkButton></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucune" runat="server" CssClass="note" Visible="false">
            Aucun élément récurrent. Sans gabarit, la paie proposera le salaire horaire (heures par semaine) ou le salaire annuel de la fiche.
        </asp:Label>
    </div>

    <fieldset>
        <legend>Ajouter un élément</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlElement">Élément de paie</asp:Label>
                <asp:DropDownList ID="ddlElement" runat="server" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtHeures">Heures</asp:Label>
                <asp:TextBox ID="txtHeures" runat="server" MaxLength="8" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTaux">Taux horaire ($)</asp:Label>
                <asp:TextBox ID="txtTaux" runat="server" MaxLength="10" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtMontant">ou montant fixe ($)</asp:Label>
                <asp:TextBox ID="txtMontant" runat="server" MaxLength="12" /></div>
        </div>
        <p class="note">Inscrivez des heures et un taux (le temps et demi et le temps double sont majorés automatiquement), ou un montant fixe.</p>
        <div class="actions">
            <asp:Button ID="btnAjouter" runat="server" Text="Ajouter" />
            <asp:HyperLink ID="lnkFiche" runat="server">Retour à la fiche</asp:HyperLink>
            <a runat="server" href="~/Employes/Liste.aspx">Liste des employés</a>
        </div>
    </fieldset>
</asp:Content>
