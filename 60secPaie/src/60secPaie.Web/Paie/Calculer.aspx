<%@ Page Title="Calculer la paie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Calculer.aspx.vb" Inherits="Paie60Sec.Web.PageCalculerPaie" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Calculer la paie</h1>
    <p class="sous-titre"><asp:Literal ID="litPeriode" runat="server" /></p>
    <asp:Literal ID="litEtapes" runat="server" />

    <asp:MultiView ID="mvEtapes" runat="server">

        <%-- Étape 1 : période --%>
        <asp:View ID="vwPeriode" runat="server">
            <asp:Panel ID="pnlBrouillon" runat="server" Visible="false" CssClass="carte">
                <h2>Une paie est déjà en préparation</h2>
                <p><asp:Literal ID="litBrouillon" runat="server" /></p>
                <div class="actions">
                    <asp:HyperLink ID="lnkReprendre" runat="server" CssClass="bouton">Continuer cette paie</asp:HyperLink>
                    <asp:Button ID="btnSupprimerBrouillon" runat="server" Text="Supprimer ce brouillon" CssClass="danger"
                        OnClientClick="return confirm('Supprimer la paie en préparation ?');" />
                </div>
            </asp:Panel>

            <asp:Panel ID="pnlNouvelle" runat="server">
                <fieldset>
                    <legend>Étape 1 de 4 : période de paie</legend>
                    <p class="note">En indiquant les dates suivantes, 60secPaie détermine la période de paie et prépare la paie de chaque employé actif.</p>
                    <div class="champs">
                        <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlPeriodes" CssClass="requis">Fréquence de paie</asp:Label>
                            <asp:DropDownList ID="ddlPeriodes" runat="server">
                                <asp:ListItem Value="52">Hebdomadaire (52 périodes)</asp:ListItem>
                                <asp:ListItem Value="26">Aux 2 semaines (26 périodes)</asp:ListItem>
                                <asp:ListItem Value="24">Bimensuel (24 périodes)</asp:ListItem>
                                <asp:ListItem Value="12">Mensuel (12 périodes)</asp:ListItem>
                                <asp:ListItem Value="1">Annuelle (1 période)</asp:ListItem>
                            </asp:DropDownList></div>
                        <div class="champ"><asp:Label runat="server" AssociatedControlID="txtFinPeriode" CssClass="requis">Heures travaillées jusqu'au</asp:Label>
                            <asp:TextBox ID="txtFinPeriode" runat="server" TextMode="Date" /></div>
                        <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDatePaie" CssClass="requis">Payer le</asp:Label>
                            <asp:TextBox ID="txtDatePaie" runat="server" TextMode="Date" /></div>
                    </div>
                    <div class="actions"><asp:Button ID="btnCreer" runat="server" Text="Continuer" /></div>
                </fieldset>
            </asp:Panel>
        </asp:View>

        <%-- Étape 2 : employés et saisie --%>
        <asp:View ID="vwSaisie" runat="server">
            <div class="carte table-defilante">
                <h2>Étape 2 de 4 : employés et rémunération</h2>
                <asp:Repeater ID="rptPaies" runat="server">
                    <HeaderTemplate>
                        <table class="liste"><thead><tr><th>Inclure</th><th>Employé</th><th>Lignes de paie</th><th class="num">Brut prévu</th><th></th></tr></thead><tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><asp:CheckBox ID="chkInclus" runat="server" Checked='<%# CBool(Eval("Inclus")) %>' />
                                <asp:HiddenField ID="hidPaieId" runat="server" Value='<%# Eval("Id") %>' /></td>
                            <td><%#: Eval("Nom") %>, <%#: Eval("Prenom") %></td>
                            <td><%#: Eval("Resume") %></td>
                            <td class="num"><%#: Argent(Eval("BrutPrevu")) %></td>
                            <td><a href='Calculer.aspx?lot=<%# Eval("LotPaieId") %>&amp;paie=<%# Eval("Id") %>'>Modifier les lignes</a></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
            </div>
            <div class="actions">
                <asp:Button ID="btnCalculer" runat="server" Text="Calculer la paie" />
                <asp:Button ID="btnSupprimerLot" runat="server" Text="Abandonner cette paie" CssClass="danger"
                    OnClientClick="return confirm('Supprimer la paie en préparation ?');" />
            </div>
        </asp:View>

        <%-- Étape 2 (suite) : lignes d'un employé --%>
        <asp:View ID="vwLignes" runat="server">
            <div class="carte table-defilante">
                <h2>Lignes de paie de <asp:Literal ID="litEmployeLignes" runat="server" /></h2>
                <asp:Repeater ID="rptLignes" runat="server">
                    <HeaderTemplate>
                        <table class="liste"><thead><tr><th>Élément de paie</th><th class="num">Heures</th><th class="num">Taux</th><th class="num">Montant</th><th></th></tr></thead><tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><%#: Eval("Description") %></td>
                            <td class="num"><%#: If(Convert.ToDecimal(Eval("Heures")) > 0D, Nombre(Eval("Heures")), "") %></td>
                            <td class="num"><%#: If(Convert.ToDecimal(Eval("Taux")) > 0D, Argent(Eval("Taux")), "") %></td>
                            <td class="num"><%#: Argent(Eval("Montant")) %></td>
                            <td><asp:LinkButton runat="server" CommandName="Supprimer" CommandArgument='<%# Eval("Id") %>'>Retirer</asp:LinkButton></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
                <asp:Label ID="lblAucuneLigne" runat="server" CssClass="note" Visible="false">Aucune ligne : cet employé ne sera pas payé.</asp:Label>
            </div>

            <fieldset>
                <legend>Ajouter une ligne</legend>
                <div class="champs">
                    <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlElement">Élément de paie</asp:Label>
                        <asp:DropDownList ID="ddlElement" runat="server" /></div>
                    <div class="champ"><asp:Label runat="server" AssociatedControlID="txtHeures">Heures</asp:Label>
                        <asp:TextBox ID="txtHeures" runat="server" MaxLength="8" /></div>
                    <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTaux">Taux horaire ($)</asp:Label>
                        <asp:TextBox ID="txtTaux" runat="server" MaxLength="10" /></div>
                    <div class="champ"><asp:Label runat="server" AssociatedControlID="txtMontant">ou montant ($)</asp:Label>
                        <asp:TextBox ID="txtMontant" runat="server" MaxLength="12" /></div>
                </div>
                <div class="actions">
                    <asp:Button ID="btnAjouterLigne" runat="server" Text="Ajouter la ligne" />
                    <asp:HyperLink ID="lnkRetourSaisie" runat="server" CssClass="bouton secondaire">Retour à la liste des employés</asp:HyperLink>
                </div>
            </fieldset>
        </asp:View>

        <%-- Étape 3 : révision --%>
        <asp:View ID="vwRevision" runat="server">
            <div class="carte">
                <h2>Étape 3 de 4 : révision des calculs</h2>
                <asp:Literal ID="litRevision" runat="server" />
            </div>
            <asp:Literal ID="litSommaire" runat="server" />
            <div class="actions">
                <asp:Button ID="btnConfirmer" runat="server" Text="Confirmer la paie"
                    OnClientClick="return confirm('Confirmer cette paie ? Elle sera ajoutée aux cumulatifs des employés.');" />
                <asp:HyperLink ID="lnkModifier" runat="server" CssClass="bouton secondaire">Modifier la saisie</asp:HyperLink>
            </div>
        </asp:View>

        <%-- Étape 4 : confirmation --%>
        <asp:View ID="vwConfirmation" runat="server">
            <div class="carte">
                <h2>Étape 4 de 4 : paie confirmée</h2>
                <p>La paie est enregistrée. Vous pouvez maintenant imprimer les talons de paie et émettre les paiements.</p>
                <asp:Literal ID="litConfirmation" runat="server" />
                <div class="actions">
                    <asp:HyperLink ID="lnkDetail" runat="server" CssClass="bouton">Voir le détail et les talons</asp:HyperLink>
                    <a runat="server" href="~/Default.aspx" class="bouton secondaire">Tableau de bord</a>
                </div>
            </div>
        </asp:View>
    </asp:MultiView>
</asp:Content>
