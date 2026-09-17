<%@ Page Title="Historique des paiements de retenues" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Historique.aspx.vb" Inherits="Paie60Sec.Web.PageHistoriqueRemises" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Retenues</h1>
    <div class="sous-menu">
        <a runat="server" href="~/Remises/Payer.aspx">Paiement des retenues</a>
        <a runat="server" href="~/Remises/Historique.aspx" class="actif">Historique des paiements</a>
    </div>

    <div class="carte table-defilante">
        <asp:Repeater ID="rptRemises" runat="server">
            <HeaderTemplate>
                <table class="liste"><thead><tr>
                    <th>Date du paiement</th><th>Gouvernement</th><th>Retenues accumulées au</th><th>Paiement</th>
                    <th class="num">Paies</th><th class="num">Total</th><th>Statut</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr class='<%# If(Convert.ToString(Eval("Statut")) = "A", "inactif", "") %>'>
                    <td><a href='Detail.aspx?id=<%# Eval("Id") %>'><%#: TexteDate(Eval("DatePaiement")) %></a></td>
                    <td><%#: ServiceRemise.NomGouvernement(Eval("Gouvernement")) %></td>
                    <td><%#: TexteDate(Eval("DateFinPeriode")) %></td>
                    <td><%#: ModePaiement(Eval("ModePaiement"), Eval("NumeroCheque"), Eval("Reference")) %></td>
                    <td class="num"><%#: Eval("NbPaies") %></td>
                    <td class="num"><%#: Argent(Eval("Total")) %></td>
                    <td><span class='etiquette <%# If(Convert.ToString(Eval("Statut")) = "A", "A", "C") %>'><%# If(Convert.ToString(Eval("Statut")) = "A", "Annulé", "Payé") %></span></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucun paiement de retenues enregistré.</asp:Label>
    </div>
</asp:Content>
