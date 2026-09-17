<%@ Page Title="Plan comptable" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PlanComptable.aspx.vb" Inherits="Paie60Sec.Web.PagePlanComptable" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("comptes") %>
    <p class="sous-titre">Numéros de compte de votre grand livre, utilisés par le rapport d'écritures comptables. Laissez vide ce que vous n'utilisez pas.</p>

    <div class="deux-colonnes">
        <fieldset>
            <legend>Comptes de la paie</legend>
            <asp:Repeater ID="rptComptes" runat="server">
                <HeaderTemplate><table class="liste"><thead><tr><th>Groupe</th><th>Compte</th><th style="width:160px">Numéro</th></tr></thead><tbody></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="note"><%#: Eval("Groupe") %></td>
                        <td><%#: Eval("Libelle") %><asp:HiddenField ID="hidCle" runat="server" Value='<%# Eval("Cle") %>' /></td>
                        <td><asp:TextBox ID="txtCompte" runat="server" MaxLength="30" Text='<%# Eval("Compte") %>' /></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
        </fieldset>

        <fieldset>
            <legend>Comptes des éléments de paie</legend>
            <p class="note">Compte de dépense d'un revenu, ou compte à payer d'une déduction. Vide = compte par défaut.</p>
            <asp:Repeater ID="rptElements" runat="server">
                <HeaderTemplate><table class="liste"><thead><tr><th>Élément</th><th style="width:140px">Numéro</th></tr></thead><tbody></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td><%#: Eval("Description") %><asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' /></td>
                        <td><asp:TextBox ID="txtCompte" runat="server" MaxLength="30" Text='<%# Eval("CompteGL") %>' /></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
        </fieldset>
    </div>

    <div class="actions"><asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" /></div>
</asp:Content>
