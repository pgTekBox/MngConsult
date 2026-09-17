<%@ Page Title="Historique de paie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Historique.aspx.vb" Inherits="Paie60Sec.Web.PageHistorique" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <div>
            <h1>Historique de paie</h1>
            <p class="sous-titre">Les paies de chaque période sont regroupées en lots.</p>
        </div>
        <a runat="server" href="~/Paie/Calculer.aspx" class="bouton">Calculer une paie</a>
    </div>

    <div class="carte table-defilante">
        <asp:Repeater ID="rptLots" runat="server">
            <HeaderTemplate>
                <table class="liste"><thead><tr>
                    <th>Date de paie</th><th>Période</th><th>Fréquence</th><th class="num">Employés</th>
                    <th class="num">Paie brute</th><th class="num">Paie nette</th><th class="num">Parts employeur</th><th>Statut</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr class='<%# If(Convert.ToString(Eval("Statut")) = "A", "inactif", "") %>'>
                    <td><a href='<%# LienLot(Eval("Id"), Eval("Statut")) %>'><%#: TexteDate(Eval("DatePaie")) %></a></td>
                    <td><%#: TexteDate(Eval("DateDebutPeriode")) %> au <%#: TexteDate(Eval("DateFinPeriode")) %></td>
                    <td><%#: LibellePeriodes(Eval("PeriodesParAnnee")) %></td>
                    <td class="num"><%#: Eval("NbEmployes") %></td>
                    <td class="num"><%#: Argent(Eval("Brut")) %></td>
                    <td class="num"><%#: Argent(Eval("Net")) %></td>
                    <td class="num"><%#: Argent(Eval("Employeur")) %></td>
                    <td><span class='etiquette <%#: Eval("Statut") %>'><%#: LibelleStatut(Eval("Statut")) %></span></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucune paie pour l'instant.</asp:Label>
    </div>
</asp:Content>
