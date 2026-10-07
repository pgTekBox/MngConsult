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
        <p>La copie de l'employeur réunit tous les feuillets de l'année en un document, NAS complet (téléchargement journalisé).
           La copie de l'employé part par courriel, en PDF, aux employés qui reçoivent leur talon par courriel ; le lien « Feuillet » de chaque ligne
           permet aussi de le télécharger ou de l'envoyer un à un. Les copies du gouvernement réunissent les T4 (copie 1) et le Sommaire T4 pour l'ARC,
           puis les Relevés 1 (copie 1) et le Sommaire 1 pour Revenu Québec.</p>
        <p class="note"><asp:Literal ID="litFormulaires" runat="server" /></p>
        <div class="actions">
            <asp:Button ID="btnPdfTous" runat="server" Text="Télécharger tous les feuillets (PDF, copie de l'employeur)" CssClass="secondaire" />
            <asp:Button ID="btnPdfGouv" runat="server" Text="Télécharger les copies du gouvernement (T4 et Sommaire T4, Relevé 1 et Sommaire 1)" CssClass="secondaire" />
            <asp:Button ID="btnCourriels" runat="server" Text="Envoyer les feuillets par courriel" CssClass="secondaire"
                OnClientClick="return confirmerPuis(this, 'Envoyer les feuillets T4 et Relevé 1 par courriel aux employés qui reçoivent leur talon par courriel ?');" />
            <asp:CheckBox ID="chkRenvoyer" runat="server" Text="renvoyer aussi les feuillets déjà envoyés" />
        </div>
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
    <asp:Label ID="lblAucun" runat="server" CssClass="note" Visible="false">Aucune paie confirmée pour l'instant.</asp:Label>
</asp:Content>
