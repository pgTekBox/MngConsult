<%@ Page Title="Utilisateurs" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Utilisateurs.aspx.vb" Inherits="Paie60Sec.Web.PageUtilisateurs" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("utilisateurs") %>

    <div class="deux-colonnes">
        <div class="carte">
            <div class="barre">
                <h2>Utilisateurs</h2>
                <a runat="server" href="~/Config/Utilisateurs.aspx" class="bouton secondaire">Nouvel utilisateur</a>
            </div>
            <div class="table-defilante">
                <asp:Repeater ID="rptUtilisateurs" runat="server">
                    <HeaderTemplate>
                        <table class="liste"><thead><tr><th>Nom</th><th>Courriel</th><th>Rôle</th><th>État</th></tr></thead><tbody>
                    </HeaderTemplate>
                    <ItemTemplate>
                        <tr class='<%# If(CBool(Eval("Actif")), "", "inactif") %>'>
                            <td><a href='Utilisateurs.aspx?id=<%# Eval("Id") %>'><%#: Eval("NomComplet") %></a></td>
                            <td><%#: Eval("Courriel") %></td>
                            <td><%# If(CBool(Eval("EstAdmin")), "Administrateur", "Utilisateur") %></td>
                            <td><%#: Etat(Eval("Actif"), Eval("VerrouilleJusqua"), Eval("DoitChangerMotDePasse")) %></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
            </div>
            <p class="note" style="margin-top:12px">
                Un <strong>administrateur</strong> gère les utilisateurs en plus de faire la paie. Gardez au moins deux administrateurs :
                si l'un oublie son mot de passe, l'autre peut le réinitialiser.
            </p>
        </div>

        <asp:Panel runat="server" DefaultButton="btnEnregistrer">
            <fieldset>
                <legend><asp:Literal ID="litTitreFormulaire" runat="server" /></legend>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNom" CssClass="requis">Nom complet</asp:Label>
                    <asp:TextBox ID="txtNom" runat="server" MaxLength="200" /></div>
                <div class="champ" style="margin-top:12px"><asp:Label runat="server" AssociatedControlID="txtCourriel" CssClass="requis">Courriel (sert à la connexion)</asp:Label>
                    <asp:TextBox ID="txtCourriel" runat="server" MaxLength="256" autocomplete="off" /></div>
                <div class="cases" style="margin-top:12px">
                    <span><asp:CheckBox ID="chkAdmin" runat="server" Text="Administrateur" /></span>
                    <span><asp:CheckBox ID="chkActif" runat="server" Text="Actif" Checked="true" /></span>
                </div>
                <div class="champ"><asp:Label ID="lblMotDePasse" runat="server" AssociatedControlID="txtMotDePasse">Mot de passe temporaire</asp:Label>
                    <asp:TextBox ID="txtMotDePasse" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" />
                    <div class="aide"><asp:Literal ID="litAideMotDePasse" runat="server" /></div></div>
                <div class="champ" style="margin-top:12px"><asp:Label runat="server" AssociatedControlID="txtConfirmation">Confirmez le mot de passe temporaire</asp:Label>
                    <asp:TextBox ID="txtConfirmation" runat="server" TextMode="Password" MaxLength="200" autocomplete="new-password" /></div>
                <div class="actions">
                    <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
                    <asp:Button ID="btnDeverrouiller" runat="server" Text="Déverrouiller le compte" CssClass="secondaire" Visible="false" />
                </div>
            </fieldset>
        </asp:Panel>
    </div>
</asp:Content>
