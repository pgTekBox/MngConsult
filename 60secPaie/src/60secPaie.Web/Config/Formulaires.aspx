<%@ Page Title="Formulaires officiels" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Formulaires.aspx.vb" Inherits="Paie60Sec.Web.PageConfigFormulaires" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("formulaires") %>

    <div class="avertissement">
        Téléchargez le T4 à remplir de l'année sur le site de l'ARC (fichier « t4-fill-AAf.pdf ») et le Relevé 1 à remplir
        sur celui de Revenu Québec, puis téléversez-les ici. Dès qu'ils sont en place, les feuillets de l'année sortent sur ces formulaires :
        copie de l'employé, copie de l'employeur, copies du gouvernement et pièce jointe des courriels. Sans formulaire, 60secPaie garde sa propre mise en page.
        Les formulaires changent chaque année : téléversez ceux de l'année des feuillets. Ceux que l'administration de la plateforme téléverse dans sa console valent pour toutes les compagnies ; ceux d'ici les remplacent pour la vôtre.
    </div>

    <fieldset>
        <legend>Téléverser un formulaire</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlAnnee">Année des feuillets</asp:Label>
                <asp:DropDownList ID="ddlAnnee" runat="server" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlType">Formulaire</asp:Label>
                <asp:DropDownList ID="ddlType" runat="server">
                    <asp:ListItem Value="T4" Text="T4 (ARC)" />
                    <asp:ListItem Value="R1" Text="Relevé 1 (Revenu Québec)" />
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="fuFichier">Fichier PDF</asp:Label>
                <asp:FileUpload ID="fuFichier" runat="server" />
                <div class="aide">Le formulaire officiel, tel que téléchargé ; 10 Mo au plus. Le fichier est vérifié : il doit porter les champs du feuillet.</div></div>
        </div>
        <div class="actions">
            <asp:Button ID="btnTeleverser" runat="server" Text="Téléverser" />
        </div>
    </fieldset>

    <h2>Formulaires en place</h2>
    <asp:Repeater ID="rptFormulaires" runat="server">
        <HeaderTemplate><table class="liste"><thead><tr><th>Année</th><th>Formulaire</th><th>Fichier</th><th>Téléversé le</th><th>Par</th><th class="num">Taille</th><th></th></tr></thead><tbody></HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td><%# Eval("Annee") %></td>
                <td><%# LibelleType(Eval("Type")) %></td>
                <td><%# Server.HtmlEncode(Convert.ToString(Eval("NomFichier"))) %></td>
                <td><%# TexteDate(Eval("TeleverseLe")) %></td>
                <td><%# Server.HtmlEncode(Convert.ToString(Eval("TeleversePar"))) %></td>
                <td class="num"><%# Taille(Eval("Taille")) %></td>
                <td><asp:LinkButton runat="server" CommandName="Supprimer" CommandArgument='<%# Convert.ToString(Eval("Annee")) & "|" & Convert.ToString(Eval("Type")) %>' CausesValidation="false"
                        OnClientClick="return confirmerPuis(this, 'Retirer ce formulaire ? Les feuillets de cette année reprendront la mise en page de 60secPaie.');">Retirer</asp:LinkButton></td>
            </tr>
        </ItemTemplate>
        <FooterTemplate></tbody></table></FooterTemplate>
    </asp:Repeater>
    <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucun formulaire téléversé : les feuillets sortent sur la mise en page de 60secPaie.</asp:Label>
    <p class="note"><asp:Literal ID="litPlateforme" runat="server" /></p>
</asp:Content>