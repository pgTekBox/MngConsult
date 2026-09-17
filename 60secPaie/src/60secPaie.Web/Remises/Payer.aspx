<%@ Page Title="Paiement des retenues" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Payer.aspx.vb" Inherits="Paie60Sec.Web.PagePayerRemise" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Retenues</h1>
    <div class="sous-menu">
        <a runat="server" href="~/Remises/Payer.aspx" class="actif">Paiement des retenues</a>
        <a runat="server" href="~/Remises/Historique.aspx">Historique des paiements</a>
    </div>

    <asp:Literal ID="litSoldes" runat="server" />

    <asp:Panel runat="server" DefaultButton="btnCalculer">
        <fieldset>
            <legend>Paiement des retenues sur salaire</legend>
            <div class="champs">
                <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlGouvernement" CssClass="requis">Gouvernement</asp:Label>
                    <asp:DropDownList ID="ddlGouvernement" runat="server" AutoPostBack="true">
                        <asp:ListItem Value="F">Fédéral - Receveur général du Canada</asp:ListItem>
                        <asp:ListItem Value="Q">Provincial - Revenu Québec</asp:ListItem>
                    </asp:DropDownList></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtFinPeriode" CssClass="requis">Retenues accumulées au</asp:Label>
                    <asp:TextBox ID="txtFinPeriode" runat="server" TextMode="Date" />
                    <div class="aide">Toutes les paies confirmées jusqu'à cette date, dont les retenues ne sont pas encore payées.</div></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDatePaiement" CssClass="requis">Date du paiement</asp:Label>
                    <asp:TextBox ID="txtDatePaiement" runat="server" TextMode="Date" /></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlMode">Mode de paiement</asp:Label>
                    <asp:DropDownList ID="ddlMode" runat="server">
                        <asp:ListItem Value="E">Paiement en ligne (institution financière, Mon dossier)</asp:ListItem>
                        <asp:ListItem Value="C">Chèque (le prochain numéro de chèque est attribué)</asp:ListItem>
                    </asp:DropDownList></div>
                <div class="champ"><asp:Label runat="server" AssociatedControlID="txtReference">Numéro de confirmation (facultatif)</asp:Label>
                    <asp:TextBox ID="txtReference" runat="server" MaxLength="60" /></div>
            </div>
            <div class="actions"><asp:Button ID="btnCalculer" runat="server" Text="Calculer les retenues" /></div>
        </fieldset>
    </asp:Panel>

    <asp:Panel ID="pnlApercu" runat="server" Visible="false" CssClass="carte">
        <h2><asp:Literal ID="litTitreApercu" runat="server" /></h2>
        <asp:Literal ID="litApercu" runat="server" />
        <p class="note" style="margin-top:12px">
            60secPaie ne transmet aucun paiement : effectuez-le auprès de votre institution financière ou dans Mon dossier,
            puis enregistrez-le ici pour que ces retenues ne soient plus à payer.
        </p>
        <div class="actions">
            <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer le paiement"
                OnClientClick="return confirm('Enregistrer ce paiement ? Les paies couvertes ne pourront plus être annulées.');" />
        </div>
    </asp:Panel>
</asp:Content>
