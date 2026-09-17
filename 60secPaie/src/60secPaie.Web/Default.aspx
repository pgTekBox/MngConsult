<%@ Page Title="Tableau de bord" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="Paie60Sec.Web.PageAccueil" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Tableau de bord</h1>
    <p class="sous-titre"><asp:Literal ID="litResume" runat="server" /></p>

    <asp:Panel ID="pnlBrouillon" runat="server" Visible="false" CssClass="avertissement">
        Une paie est en préparation (<asp:Literal ID="litBrouillon" runat="server" />).
        <asp:HyperLink ID="lnkBrouillon" runat="server">Continuer cette paie</asp:HyperLink>
    </asp:Panel>

    <div class="deux-colonnes">
        <div>
            <div class="grille-cartes">
                <div class="carte">
                    <h2>Faites vos paies</h2>
                    <p>L'assistant vous guide en 4 étapes : période, saisie, révision et confirmation.</p>
                    <a runat="server" href="~/Paie/Calculer.aspx" class="bouton">Calculer la paie</a>
                </div>
                <div class="carte">
                    <h2>Paiement des retenues</h2>
                    <asp:Literal ID="litRetenues" runat="server" />
                    <a runat="server" href="~/Remises/Payer.aspx" class="bouton secondaire">Payer</a>
                </div>
                <div class="carte">
                    <h2>Historique de paie</h2>
                    <p>Consultez le détail des paies déjà calculées et imprimez les talons de paie.</p>
                    <a runat="server" href="~/Paie/Historique.aspx" class="bouton secondaire">Consulter</a>
                </div>
                <div class="carte">
                    <h2>Employés</h2>
                    <p>Fiches, renseignements fiscaux (TD1, TP-1015.3) et éléments de paie récurrents.</p>
                    <a runat="server" href="~/Employes/Liste.aspx" class="bouton secondaire">Gérer</a>
                </div>
                <div class="carte">
                    <h2>Configuration</h2>
                    <p>Compagnie, taux de l'employeur (FSS, CNESST) et éléments de paie.</p>
                    <a runat="server" href="~/Config/Compagnie.aspx" class="bouton secondaire">Configurer</a>
                </div>
            </div>
        </div>

        <div class="carte">
            <h2>Activités récentes</h2>
            <asp:Repeater ID="rptActivites" runat="server">
                <HeaderTemplate><table class="liste"></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td class="note"><%#: Eval("DateHeure", "{0:yyyy-MM-dd HH:mm}") %></td>
                        <td>
                            <asp:HyperLink runat="server" NavigateUrl='<%# Eval("Lien") %>' Visible='<%# Not IsDBNull(Eval("Lien")) %>'><%#: Eval("Description") %></asp:HyperLink>
                            <asp:Literal runat="server" Mode="Encode" Text='<%# Eval("Description") %>' Visible='<%# IsDBNull(Eval("Lien")) %>' />
                            <div class="note"><%#: Eval("Utilisateur") %></div>
                        </td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></table></FooterTemplate>
            </asp:Repeater>
            <asp:Label ID="lblAucuneActivite" runat="server" CssClass="note" Visible="false">Aucune activité pour l'instant.</asp:Label>
        </div>
    </div>
</asp:Content>
