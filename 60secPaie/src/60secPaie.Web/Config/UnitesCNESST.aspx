<%@ Page Title="Unités CNESST" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="UnitesCNESST.aspx.vb" Inherits="Paie60Sec.Web.PageConfigUnitesCNESST" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("unites") %>

    <p class="note">La CNESST classe votre entreprise dans une ou plusieurs <strong>unités de classification</strong> selon l'activité, chacune avec son taux.
       Inscrivez ici les unités de votre décision de classification. Dans la fiche de chaque employé, vous choisissez son unité ; sans unité,
       c'est le taux de versement périodique de la compagnie (Paramètres de paie) qui s'applique. La Déclaration des salaires se regroupe ensuite par unité.</p>

    <div class="carte table-defilante">
        <asp:Repeater ID="rptUnites" runat="server">
            <HeaderTemplate>
                <table class="liste"><thead><tr>
                    <th>Code</th><th>Description</th><th class="num">Taux ($ / 100 $)</th><th>Employés</th><th>Statut</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr class='<%# If(CBool(Eval("Actif")), "", "inactif") %>'>
                    <td><a href='UnitesCNESST.aspx?id=<%# Eval("Id") %>'><%#: Eval("Code") %></a></td>
                    <td><%#: Eval("Description") %></td>
                    <td class="num"><%#: Taux(Eval("Taux")) %></td>
                    <td><%#: Eval("NbEmployes") %></td>
                    <td><span class='etiquette <%# If(CBool(Eval("Actif")), "C", "B") %>'><%# If(CBool(Eval("Actif")), "Active", "Inactive") %></span></td>
                    <td><a href='UnitesCNESST.aspx?id=<%# Eval("Id") %>'>Modifier</a></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucune" runat="server" CssClass="note" Visible="false" Text="Aucune unité de classification. Avec une seule activité, vous n'en avez pas besoin : le taux de la compagnie suffit." />
    </div>

    <fieldset>
        <legend><asp:Literal ID="litTitreForm" runat="server" Text="Ajouter une unité" /></legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCode" CssClass="requis">Code de l'unité</asp:Label>
                <asp:TextBox ID="txtCode" runat="server" MaxLength="10" />
                <div class="aide">Tel qu'il paraît sur la décision de classification, ex. 80030.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDescription" CssClass="requis">Description</asp:Label>
                <asp:TextBox ID="txtDescription" runat="server" MaxLength="200" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTaux" CssClass="requis">Taux ($ par 100 $ assurables)</asp:Label>
                <asp:TextBox ID="txtTaux" runat="server" MaxLength="10" />
                <div class="aide">Le taux de l'unité pour l'année en cours.</div></div>
        </div>
        <div class="cases">
            <span><asp:CheckBox ID="chkActif" runat="server" Text="Active" Checked="true" /></span>
        </div>
        <div class="actions">
            <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
            <asp:Button ID="btnSupprimer" runat="server" Text="Supprimer" CssClass="danger" Visible="false"
                OnClientClick="if (!confirm('Supprimer cette unité ?')) { return false; }" />
            <a runat="server" href="~/Config/UnitesCNESST.aspx">Annuler</a>
        </div>
    </fieldset>
</asp:Content>
