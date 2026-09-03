<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAbonne.aspx.vb" Inherits="PortailPartenaire.wbfAbonne" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litTitle" runat="server" Text="Nouvel abonné" /></h1>
            <p class="sub"><asp:Literal ID="litSub" runat="server" Text="Provisionnez un locataire rattaché à votre canal" /></p>
        </div>
        <a href="wbfAbonnes.aspx" class="btn btn-ghost">← Retour</a>
    </div>

    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlErr" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litErr" runat="server" /></asp:Panel>

    <%-- ================= MODE CREATION ================= --%>
    <asp:Panel ID="pnlCreate" runat="server" Visible="false">
        <div class="card">
            <div class="form-grid">
                <div class="field full">
                    <label>Raison sociale *</label>
                    <asp:TextBox ID="tbNom" runat="server" placeholder="Ex. Boulangerie Tremblay inc." />
                </div>
                <div class="field">
                    <label>Nom d'affichage</label>
                    <asp:TextBox ID="tbNomAff" runat="server" />
                </div>
                <div class="field">
                    <label>N° d'entreprise (NEQ / BN)</label>
                    <asp:TextBox ID="tbNeq" runat="server" />
                </div>
                <div class="field">
                    <label>Courriel de contact</label>
                    <asp:TextBox ID="tbEmail" runat="server" TextMode="Email" />
                </div>
                <div class="field">
                    <label>Téléphone</label>
                    <asp:TextBox ID="tbTel" runat="server" />
                </div>
                <div class="field full">
                    <label>Adresse</label>
                    <asp:TextBox ID="tbAdr1" runat="server" placeholder="Numéro et rue" />
                </div>
                <div class="field">
                    <label>Ville</label>
                    <asp:TextBox ID="tbVille" runat="server" />
                </div>
                <div class="field">
                    <label>Province</label>
                    <asp:TextBox ID="tbProv" runat="server" placeholder="QC" />
                </div>
                <div class="field">
                    <label>Code postal</label>
                    <asp:TextBox ID="tbCp" runat="server" />
                </div>
            </div>
            <div class="form-actions">
                <asp:Button ID="btnCreate" runat="server" Text="Provisionner l'abonné" CssClass="btn btn-primary" OnClick="btnCreate_Click" />
                <a href="wbfAbonnes.aspx" class="btn btn-ghost">Annuler</a>
            </div>
        </div>
    </asp:Panel>

    <%-- ================= MODE CONSULTATION ================= --%>
    <asp:Panel ID="pnlView" runat="server" Visible="false">
        <div class="cards" style="grid-template-columns: 1.4fr 1fr; align-items:start">

            <div class="card">
                <h3 style="margin:0 0 14px">Coordonnées</h3>
                <table class="grid" style="border:none">
                    <tr><th style="width:180px; background:transparent; text-transform:none">Raison sociale</th><td><asp:Literal ID="litVNom" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Nom d'affichage</th><td><asp:Literal ID="litVNomAff" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">N° d'entreprise</th><td><asp:Literal ID="litVNeq" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Courriel</th><td><asp:Literal ID="litVEmail" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Téléphone</th><td><asp:Literal ID="litVTel" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Adresse</th><td><asp:Literal ID="litVAdr" runat="server" /></td></tr>
                    <tr><th style="background:transparent; text-transform:none">Statut</th><td><asp:Literal ID="litVStatut" runat="server" /></td></tr>
                </table>
            </div>

            <div class="card">
                <h3 style="margin:0 0 6px">Conformité KYB</h3>
                <p style="margin:0 0 12px"><asp:Literal ID="litVKyb" runat="server" /></p>
                <asp:Panel ID="pnlKybResult" runat="server" Visible="false"
                    style="background:#f8fafc; border:1px solid var(--line); border-radius:11px; padding:12px 14px; margin-bottom:14px; font-size:13px">
                    <asp:Literal ID="litKybMsg" runat="server" />
                </asp:Panel>
                <asp:Button ID="btnKyb" runat="server" Text="Lancer la vérification KYB" CssClass="btn btn-primary"
                    OnClick="btnKyb_Click" />
                <p class="sub" style="margin-top:12px; font-size:12px">
                    Vérifie l'entreprise (registre, listes de surveillance, adresse) via le fournisseur configuré (sandbox).
                </p>
            </div>

        </div>

        <div class="card" style="margin-top:18px">
            <h3 style="margin:0 0 6px">Accès au portail abonné</h3>
            <p class="sub" style="margin:0 0 12px">
                Comptes avec lesquels cet abonné se connecte à son portail. Vous pouvez leur redonner
                un mot de passe sans connaître l'ancien.
            </p>

            <asp:Panel ID="pnlNewPwd" runat="server" Visible="false" CssClass="msg-ok" style="word-break:break-all; margin-bottom:12px">
                <b>Mot de passe (à transmettre maintenant, il ne sera plus affiché) :</b><br />
                <span class="mono" style="font-size:15px"><asp:Literal ID="litNewPwd" runat="server" /></span><br />
                <span class="sub">Pour <asp:Literal ID="litNewPwdUser" runat="server" />. Il pourra le changer dans « Mon compte » du portail abonné.</span>
            </asp:Panel>

            <asp:Repeater ID="rptUsers" runat="server" OnItemCommand="rptUsers_ItemCommand">
                <HeaderTemplate>
                    <table class="grid" style="margin-bottom:14px"><thead><tr>
                        <th>Courriel</th><th>Rôle</th><th>Statut</th><th>Dernière connexion</th><th>Mot de passe</th>
                    </tr></thead><tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td><%# Enc(Eval("Email")) %></td>
                        <td><%# IIf(CBool(Eval("IsAdmin")), "Admin", "Utilisateur") %></td>
                        <td><%# IIf(CBool(Eval("IsActive")), "<span class='badge badge-actif'>Actif</span>", "<span class='badge badge-ferme'>Inactif</span>") %></td>
                        <td><%# FormatDt(Eval("LastLoginUtc")) %></td>
                        <td style="white-space:nowrap">
                            <asp:LinkButton runat="server" Text="Réinitialiser" CommandName="resetpwd"
                                CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                OnClientClick='<%# ConfirmReset(Eval("Email")) %>' />
                        </td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoUsers" runat="server" Visible="false">
                <p class="sub">Aucun accès pour l'instant : cet abonné ne peut pas encore se connecter à son portail. Créez-lui un compte ci-dessous.</p>
            </asp:Panel>

            <div style="display:flex; gap:10px; align-items:flex-end; flex-wrap:wrap; margin-bottom:6px">
                <div class="field" style="margin:0; flex:1; min-width:200px">
                    <label>Mot de passe</label>
                    <asp:TextBox ID="tbUserPwd" runat="server" TextMode="Password" placeholder="laisser vide = généré" />
                </div>
            </div>
            <p class="sub" style="margin:0 0 14px; font-size:12px">
                Sert aussi bien à « Réinitialiser » qu'à la création ci-dessous. Vide = mot de passe fort généré et
                affiché une seule fois ; sinon 8 caractères minimum.
            </p>

            <div style="border-top:1px solid var(--line); padding-top:14px">
                <div style="display:flex; gap:10px; align-items:flex-end; flex-wrap:wrap">
                    <div class="field" style="margin:0; flex:2; min-width:220px">
                        <label>Courriel du nouvel accès</label>
                        <asp:TextBox ID="tbUserEmail" runat="server" TextMode="Email" placeholder="personne@entreprise.ca" />
                    </div>
                    <div class="field" style="margin:0; flex:1; min-width:140px">
                        <label>Prénom</label>
                        <asp:TextBox ID="tbUserFirst" runat="server" />
                    </div>
                    <div class="field" style="margin:0; flex:1; min-width:140px">
                        <label>Nom</label>
                        <asp:TextBox ID="tbUserLast" runat="server" />
                    </div>
                    <asp:Button ID="btnCreateUser" runat="server" Text="Créer l'accès" CssClass="btn btn-primary" OnClick="btnCreateUser_Click" />
                </div>
                <p class="sub" style="margin:10px 0 0; font-size:12px">
                    Le compte créé est administrateur de l'abonné : il pourra ensuite ajouter ses propres collègues.
                </p>
            </div>
        </div>

        <div class="card" style="margin-top:18px">
            <h3 style="margin:0 0 6px">Intégration API</h3>
            <p class="sub" style="margin:0 0 12px">
                Pour agir au nom de cet abonné via l'API, utilisez votre clé partenaire et ciblez ce locataire avec l'en-tête
                <span class="mono">X-Abonne-Id</span>.
            </p>
            <table class="grid" style="border:none">
                <tr><th style="width:180px; background:transparent; text-transform:none">Identifiant abonné</th><td class="mono"><asp:Literal ID="litVId" runat="server" /></td></tr>
                <tr><th style="background:transparent; text-transform:none">Tenant GUID</th><td class="mono"><asp:Literal ID="litVGuid" runat="server" /></td></tr>
                <tr><th style="background:transparent; text-transform:none">En-tête à envoyer</th><td class="mono">X-Abonne-Id: <asp:Literal ID="litVId2" runat="server" /></td></tr>
            </table>
        </div>
    </asp:Panel>

</asp:Content>
