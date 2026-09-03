<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfPartenaires.aspx.vb" Inherits="PortailMaster.wbfPartenaires" %>

<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <h1><asp:Literal ID="litHead" runat="server" Text="Partenaires" /></h1>
            <p class="sub"><asp:Literal ID="litSub" runat="server" Text="Canaux de distribution / revente (Modèle B)" /></p>
        </div>
        <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn btn-ghost" NavigateUrl="wbfPartenaires.aspx" Text="← Tous les partenaires" Visible="false" />
    </div>

    <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="msg-err"><asp:Literal ID="litError" runat="server" /></asp:Panel>
    <asp:Panel ID="pnlOk" runat="server" Visible="false" CssClass="msg-ok"><asp:Literal ID="litOk" runat="server" /></asp:Panel>

    <%-- ================= LISTE ================= --%>
    <asp:Panel ID="pnlList" runat="server" Visible="false">
        <div class="card" style="margin-bottom:18px">
            <h3 style="margin:0 0 14px">Nouveau partenaire</h3>
            <div class="form-grid">
                <div class="field"><label>Raison sociale *</label><asp:TextBox ID="tbNom" runat="server" /></div>
                <div class="field"><label>Nom d'affichage</label><asp:TextBox ID="tbNomAff" runat="server" /></div>
                <div class="field"><label>Courriel de contact</label><asp:TextBox ID="tbCourriel" runat="server" TextMode="Email" /></div>
                <div class="field"><label>Téléphone</label><asp:TextBox ID="tbTel" runat="server" /></div>
                <div class="field full"><label>Notes</label><asp:TextBox ID="tbNotes" runat="server" TextMode="MultiLine" /></div>
            </div>
            <div class="form-actions">
                <asp:Button ID="btnCreatePartner" runat="server" Text="Créer le partenaire" CssClass="btn btn-primary" OnClick="btnCreatePartner_Click" />
            </div>
        </div>

        <asp:Repeater ID="rptPartenaires" runat="server">
            <HeaderTemplate>
                <div class="table-wrap"><table class="grid"><thead><tr>
                    <th>Raison sociale</th><th>Courriel</th><th>Abonnés</th><th>Statut</th><th>Créé</th>
                </tr></thead><tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td><a class="rowlink" href='wbfPartenaires.aspx?id=<%# Eval("Id") %>'><%# Enc(Eval("RaisonSociale")) %></a></td>
                    <td><%# Enc(Eval("CourrielContact")) %></td>
                    <td><%# Eval("NbAbonnes") %></td>
                    <td><%# StatutBadge(Eval("Statut")) %></td>
                    <td><%# FormatDate(Eval("CreatedUtc")) %></td>
                </tr>
            </ItemTemplate>
            <FooterTemplate></tbody></table></div></FooterTemplate>
        </asp:Repeater>
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
            <div class="table-wrap"><div class="empty">Aucun partenaire. Créez-en un ci-dessus.</div></div>
        </asp:Panel>
    </asp:Panel>

    <%-- ================= DÉTAIL ================= --%>
    <asp:Panel ID="pnlDetail" runat="server" Visible="false">

        <div class="card" style="margin-bottom:18px">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:16px">
                <div>
                    <div style="margin-bottom:6px"><asp:Literal ID="litStatutBadge" runat="server" /></div>
                    <p class="sub" style="margin:0"><asp:Literal ID="litPMeta" runat="server" /></p>
                </div>
                <asp:Button ID="btnToggleStatut" runat="server" CssClass="btn" OnClick="btnToggleStatut_Click" CausesValidation="false" />
            </div>
        </div>

        <div class="cards" style="grid-template-columns:1fr 1fr; align-items:start">

            <%-- Utilisateurs --%>
            <div class="card">
                <h3 style="margin:0 0 12px">Utilisateurs du portail</h3>
                <asp:Panel ID="pnlNewPwd" runat="server" Visible="false" CssClass="msg-ok" style="word-break:break-all; margin-bottom:12px">
                    <b>Nouveau mot de passe (à transmettre maintenant, il ne sera plus affiché) :</b><br />
                    <span class="mono" style="font-size:15px"><asp:Literal ID="litNewPwd" runat="server" /></span><br />
                    <span class="sub">Pour <asp:Literal ID="litNewPwdUser" runat="server" />. Demandez-lui de le changer dans « Mon compte » dès sa connexion.</span>
                </asp:Panel>
                <asp:Repeater ID="rptUsers" runat="server" OnItemCommand="rptUsers_ItemCommand">
                    <HeaderTemplate><table class="grid" style="margin-bottom:14px"><thead><tr><th>Courriel</th><th>Rôle</th><th>Statut</th><th>Mot de passe</th></tr></thead><tbody></HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td><%# Enc(Eval("Email")) %></td>
                            <td><%# IIf(CBool(Eval("IsAdmin")), "Admin", "Utilisateur") %></td>
                            <td><%# IIf(CBool(Eval("IsActive")), "<span class='badge badge-actif'>Actif</span>", "<span class='badge badge-ferme'>Inactif</span>") %></td>
                            <td style="white-space:nowrap">
                                <asp:LinkButton runat="server" Text="Réinitialiser" CommandName="resetpwd"
                                    CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                    OnClientClick='<%# ConfirmReset(Eval("Email")) %>' />
                            </td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
                <asp:Panel ID="pnlNoUsers" runat="server" Visible="false"><p class="sub">Aucun utilisateur.</p></asp:Panel>

                <div style="border-top:1px solid var(--line); padding-top:14px; margin-top:4px">
                    <div class="form-grid">
                        <div class="field"><label>Courriel *</label><asp:TextBox ID="tbUserEmail" runat="server" TextMode="Email" /></div>
                        <div class="field"><label>Mot de passe *</label><asp:TextBox ID="tbUserPwd" runat="server" TextMode="Password" /></div>
                        <div class="field"><label>Prénom</label><asp:TextBox ID="tbUserFirst" runat="server" /></div>
                        <div class="field"><label>Nom</label><asp:TextBox ID="tbUserLast" runat="server" /></div>
                    </div>
                    <div style="margin:10px 0"><label style="font-size:13px"><asp:CheckBox ID="cbUserAdmin" runat="server" Checked="true" /> Administrateur (peut gérer les clés d'API)</label></div>
                    <asp:Button ID="btnCreateUser" runat="server" Text="Ajouter l'utilisateur" CssClass="btn btn-primary" OnClick="btnCreateUser_Click" />
                </div>
            </div>

            <%-- Clés d'API partenaire --%>
            <div class="card">
                <h3 style="margin:0 0 12px">Clés d'API partenaire</h3>
                <asp:Panel ID="pnlNewKey" runat="server" Visible="false" CssClass="msg-ok" style="word-break:break-all; margin-bottom:12px">
                    <b>Nouvelle clé (à copier maintenant) :</b><br /><span class="mono"><asp:Literal ID="litNewKey" runat="server" /></span>
                </asp:Panel>
                <asp:Repeater ID="rptKeys" runat="server" OnItemCommand="rptKeys_ItemCommand">
                    <HeaderTemplate><table class="grid" style="margin-bottom:14px"><thead><tr><th>Préfixe</th><th>Env.</th><th>Statut</th><th></th></tr></thead><tbody></HeaderTemplate>
                    <ItemTemplate>
                        <tr>
                            <td class="mono"><%# Enc(Eval("Prefix")) %>…</td>
                            <td><%# Enc(Eval("Environment")) %></td>
                            <td><%# IIf(CBool(Eval("IsActive")), "<span class='badge badge-actif'>Active</span>", "<span class='badge badge-ferme'>Révoquée</span>") %></td>
                            <td class="num"><asp:LinkButton runat="server" CssClass="btn" CommandName="revoke" CommandArgument='<%# Eval("Id") %>' Visible='<%# CBool(Eval("IsActive")) %>' Text="Révoquer" OnClientClick="return confirm('Révoquer cette clé ?');" /></td>
                        </tr>
                    </ItemTemplate>
                    <FooterTemplate></tbody></table></FooterTemplate>
                </asp:Repeater>
                <asp:Panel ID="pnlNoKeys" runat="server" Visible="false"><p class="sub">Aucune clé.</p></asp:Panel>
                <div style="border-top:1px solid var(--line); padding-top:14px; margin-top:4px; display:flex; gap:10px; align-items:flex-end; flex-wrap:wrap">
                    <div class="field" style="margin:0"><label>Environnement</label>
                        <asp:DropDownList ID="ddlEnv" runat="server">
                            <asp:ListItem Value="test" Text="Test" /><asp:ListItem Value="live" Text="Production" />
                        </asp:DropDownList>
                    </div>
                    <div class="field" style="margin:0; flex:1; min-width:160px"><label>Libellé</label><asp:TextBox ID="tbKeyLabel" runat="server" /></div>
                    <asp:Button ID="btnGenKey" runat="server" Text="Générer" CssClass="btn btn-primary" OnClick="btnGenKey_Click" />
                </div>
            </div>

        </div>

        <%-- Abonnés provisionnés --%>
        <div class="card" style="margin-top:18px">
            <h3 style="margin:0 0 12px">Abonnés provisionnés (<asp:Literal ID="litNbAbonnes" runat="server" Text="0" />)</h3>
            <asp:Repeater ID="rptTenants" runat="server">
                <HeaderTemplate><table class="grid"><thead><tr><th>Abonné</th><th>Courriel</th><th>Statut</th><th>KYB</th><th>Créé</th></tr></thead><tbody></HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td><a class="rowlink" href='wbfAbonne.aspx?id=<%# Eval("Id") %>'><%# Enc(Eval("RaisonSociale")) %></a></td>
                        <td><%# Enc(Eval("CourrielContact")) %></td>
                        <td><%# StatutBadge(Eval("Statut")) %></td>
                        <td><%# KybBadge(Eval("StatutKYB")) %></td>
                        <td><%# FormatDate(Eval("CreatedUtc")) %></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></FooterTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlNoTenants" runat="server" Visible="false"><p class="sub">Aucun abonné provisionné par ce partenaire.</p></asp:Panel>
        </div>

    </asp:Panel>

</asp:Content>
