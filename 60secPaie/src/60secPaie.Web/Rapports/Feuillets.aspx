<%@ Page Title="T4 et Relevés 1" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Feuillets.aspx.vb" Inherits="Paie60Sec.Web.PageFeuillets" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Rapports</h1>
    <%= SousMenuRapports("feuillets") %>

    <div class="barre">
        <div>
            <h2><%: If(AvecQuebec, "Feuillets T4 et Relevés 1 de l'année", "Feuillets T4 de l'année") %>
                <asp:DropDownList ID="ddlAnnee" runat="server" AutoPostBack="true" Width="110" /></h2>
            <p class="sous-titre">Montants calculés à partir des paies confirmées et des cumulatifs de départ.</p>
        </div>
        <div class="actions sans-impression">
            <asp:Button ID="btnCsv" runat="server" Text="Exporter en CSV" CssClass="secondaire" />
            <a href="javascript:window.print()" class="bouton secondaire">Imprimer</a>
        </div>
    </div>

    <asp:Panel ID="pnlFeuillets" runat="server" CssClass="carte sans-impression">
        <h2>Feuillets en PDF et par courriel</h2>
        <p>Les boutons du haut réunissent tous les employés de l'année : les T4 en un document, les Relevés 1 en un autre, dans la copie choisie
           (NAS complet : téléchargement journalisé). Dans le tableau, chaque ligne a ses propres boutons « T4 », « Relevé 1 » et « Courriel ».
           La copie de l'employé part par courriel, en PDF, aux employés qui reçoivent leur talon par courriel. Les copies du gouvernement réunissent
           les T4 (copie 1) et le Sommaire T4 pour l'ARC, puis les Relevés 1 (copie 1) et le Sommaire 1 pour Revenu Québec.</p>
        <p class="note"><asp:Literal ID="litFormulaires" runat="server" /></p>
        <asp:Literal ID="litInstructions" runat="server" />
        <div class="actions">
            <label>Copie à télécharger
                <asp:DropDownList ID="ddlCopie" runat="server" AutoPostBack="true">
                    <asp:ListItem Text="Employeur" Value="employeur" />
                    <asp:ListItem Text="Employé" Value="employe" />
                </asp:DropDownList></label>
            <asp:Button ID="btnPdfT4" runat="server" Text="Télécharger tous les T4" CssClass="secondaire" />
            <asp:Button ID="btnPdfR1" runat="server" Text="Télécharger tous les Relevés 1" CssClass="secondaire" />
            <asp:Button ID="btnPdfGouv" runat="server" Text="Télécharger les copies du gouvernement" CssClass="secondaire" />
        </div>
        <div class="actions">
            <asp:Button ID="btnCourriels" runat="server" Text="Envoyer les feuillets par courriel" CssClass="secondaire"
                OnClientClick="return confirmerPuis(this, 'Envoyer les feuillets T4 et Relevé 1 par courriel aux employés qui reçoivent leur talon par courriel ?');" />
            <asp:CheckBox ID="chkRenvoyer" runat="server" Text="renvoyer aussi les feuillets déjà envoyés" />
        </div>
        <asp:HiddenField ID="hidEmploye" runat="server" />
        <asp:Button ID="btnCourrielUn" runat="server" Text="Envoyer" Style="display:none" />
    </asp:Panel>

    <asp:Panel ID="pnlContenu" runat="server">
        <% If AvecQuebec Then %>
        <div class="avertissement sans-impression">
            60secPaie calcule les montants de chaque case ; il ne transmet pas les feuillets. Saisissez-les dans <strong>Formulaires Web</strong> (ARC)
            et dans <strong>Mon dossier pour les entreprises</strong> (Revenu Québec), au plus tard le dernier jour de février.
            Vérifiez les cases avec les guides RC4120 (T4) et RL-1.G (Relevé 1) de l'année.
        </div>
        <% Else %>
        <div class="avertissement sans-impression">
            60secPaie calcule les montants de chaque case ; il ne transmet pas les feuillets. Saisissez-les dans <strong>Formulaires Web</strong> (ARC),
            au plus tard le dernier jour de février. Vérifiez les cases avec le guide RC4120 (T4) de l'année.
            Hors Québec, la case 22 réunit l'impôt fédéral et l'impôt de la province ou du territoire ; il n'y a pas de relevé provincial.
        </div>
        <% End If %>
        <div class="carte table-defilante"><asp:Literal ID="litTableau" runat="server" /></div>
        <asp:Literal ID="litSommaire" runat="server" />
    </asp:Panel>
    <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucune paie confirmée pour l'instant, ni cumulatifs de départ, ni formulaire officiel téléversé.</asp:Label>
</asp:Content>
