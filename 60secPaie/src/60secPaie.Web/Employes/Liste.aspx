<%@ Page Title="Employés" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Liste.aspx.vb" Inherits="Paie60Sec.Web.PageEmployes" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <div>
            <h1>Employés</h1>
            <asp:CheckBox ID="chkInactifs" runat="server" AutoPostBack="true" Text="Afficher aussi les employés inactifs" />
        </div>
    </div>
    <p class="note">Les employés sont ceux de MngConsul : ils s'y ajoutent et s'y modifient (nom, adresse, poste, date d'embauche).
       Ici, vous configurez leur paie. Seuls les employés dont la paie est configurée sont proposés dans l'assistant de paie.</p>

    <div class="carte table-defilante">
        <asp:Repeater ID="rptEmployes" runat="server">
            <HeaderTemplate>
                <table class="liste"><thead><tr>
                    <th>Nom</th><th>Poste</th><th>Rémunération</th><th>Fréquence</th><th>Date d'embauche</th><th>Paie</th><th></th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr class='<%# If(CBool(Eval("Actif")), "", "inactif") %>'>
                    <td><a href='Fiche.aspx?id=<%# Eval("Id") %>'><%#: Eval("Nom") %>, <%#: Eval("Prenom") %></a></td>
                    <td><%#: Eval("Poste") %></td>
                    <td><%#: Remuneration(Eval("TauxHoraire"), Eval("SalaireAnnuel")) %></td>
                    <td><%#: LibellePeriodes(Eval("Periodes")) %></td>
                    <td><%#: TexteDate(Eval("DateEmbauche")) %></td>
                    <td><span class='etiquette <%# If(CBool(Eval("PaieConfiguree")), "C", "B") %>'><%# If(CBool(Eval("PaieConfiguree")), "Configurée", "À configurer") %></span></td>
                    <td><a href='Fiche.aspx?id=<%# Eval("Id") %>'>Paramètres de paie</a> &middot;
                        <a href='ElementsPaie.aspx?id=<%# Eval("Id") %>'>Éléments de paie</a> &middot;
                        <a href='Cumulatifs.aspx?id=<%# Eval("Id") %>'>Cumulatifs</a></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></FooterTemplate>
        </asp:Repeater>
        <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false" Text="Aucun employé pour cette compagnie. Ajoutez-les dans MngConsul." />
    </div>
</asp:Content>
