<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfMonCompte.aspx.vb" Inherits="PortailPartenaire.wbfMonCompte" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1>Mon compte</h1>
            <p class="sub">Vos informations et votre mot de passe</p>
        </div>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>

    <div class="card" style="margin-bottom:18px">
        <h3 style="margin:0 0 14px">Informations</h3>
        <div class="table-wrap">
            <table class="grid">
                <tbody>
                    <tr><td style="width:220px">Courriel</td><td class="mono"><asp:Literal ID="litEmail" runat="server" /></td></tr>
                    <tr><td>Nom</td><td><asp:Literal ID="litNom" runat="server" /></td></tr>
                    <tr><td>Organisation</td><td><asp:Literal ID="litPartenaire" runat="server" /></td></tr>
                    <tr><td>Rôle</td><td><asp:Literal ID="litRole" runat="server" /></td></tr>
                    <tr><td>Dernière connexion</td><td><asp:Literal ID="litLastLogin" runat="server" /></td></tr>
                    <tr><td>Compte créé le</td><td><asp:Literal ID="litCreated" runat="server" /></td></tr>
                </tbody>
            </table>
        </div>
        <p class="sub" style="margin:14px 0 0">
            Pour corriger votre nom ou votre courriel, écrivez à 60secPaiement : ces champs sont gérés
            par la plateforme.
        </p>
    </div>

    <div class="card">
        <h3 style="margin:0 0 6px">Changer mon mot de passe</h3>
        <p class="sub" style="margin:0 0 16px">
            Minimum 8 caractères. Vous resterez connecté après le changement ; utilisez le nouveau
            mot de passe à votre prochaine connexion.
        </p>

        <div style="display:flex; gap:12px; flex-wrap:wrap; align-items:flex-end">
            <div class="field" style="margin:0; flex:1; min-width:220px">
                <label>Nouveau mot de passe</label>
                <asp:TextBox ID="tbNew" runat="server" TextMode="Password" autocomplete="new-password" />
            </div>
            <div class="field" style="margin:0; flex:1; min-width:220px">
                <label>Confirmer le nouveau</label>
                <asp:TextBox ID="tbConfirm" runat="server" TextMode="Password" autocomplete="new-password" />
            </div>
            <asp:Button ID="btnChange" runat="server" Text="Changer le mot de passe"
                CssClass="btn btn-primary" OnClick="btnChange_Click" />
        </div>
    </div>

</asp:Content>
