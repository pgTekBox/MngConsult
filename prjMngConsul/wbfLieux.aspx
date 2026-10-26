<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfLieux.aspx.vb" Inherits="MngConsul.wbfLieux" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <%= L("pageTitle") %>
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
    /* ── Produits et services › Lieux : la signature du gabarit « Portail du client »
       (comme Catégories de produits) : le titre sur le fond de la page, la fiche
       d'un lieu quand on en ajoute ou en modifie un, puis la liste. ── */
    .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
    .fc-tete .txt { flex: 1 1 260px }
    .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
    .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
    .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
    .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
    .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 }
    .fc-btn.primaire, input.fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
    .fc-btn.primaire:hover, input.fc-btn.primaire:hover { background: #143A73 }

    .li-msg { margin: 0 0 16px; padding: 12px 16px; border-radius: 16px; font-weight: 700 }
    .li-msg.ok { background: #E3F3EA; color: #0F5A3A }
    .li-msg.err { background: #FDECEA; color: #8A1F14 }

    /* La fiche d'un lieu */
    .li-fiche { padding: 18px; border-radius: 24px; background: #fff; margin-bottom: 16px }
    .li-fiche h2 { margin: 0 0 12px; font-size: 20px; font-weight: 800; color: #0E1F3D }
    .li-grille { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr) minmax(0, 1.6fr); gap: 12px 16px; align-items: end }
    .li-champ label { display: block; margin: 0 0 6px; font-size: 14px; font-weight: 800; color: #0E1F3D }
    .li-champ input[type=text], .li-champ select { width: 100%; min-height: 44px; padding: 0 14px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; font: inherit; font-size: 15px; font-weight: 700; color: #0E1F3D; box-sizing: border-box }
    .li-champ input[type=text]:focus, .li-champ select:focus { outline: none; border-color: #1B4F9C; box-shadow: 0 0 0 3px #DCE6F6 }
    .li-actif { display: flex; align-items: center; gap: 8px; margin-top: 12px; font-weight: 700 }
    .li-actif input { width: 18px; height: 18px; accent-color: #1B4F9C }
    .li-boutons { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 16px }

    /* La liste */
    .li-liste { padding: 6px 12px 12px; border-radius: 24px; background: #fff }
    .li-tete, .li-ligne { display: grid; grid-template-columns: minmax(0, 2fr) 170px minmax(0, 2fr) 110px 110px 100px; gap: 10px; align-items: center; padding: 10px 6px }
    .li-tete { font-size: 14px; font-weight: 800; color: #5B6B86 }
    .li-ligne { border-top: 1px solid #E3E9F1; font-size: 15px }
    .li-ligne:hover { background: #FAFCFF }
    .li-ligne b { font-weight: 800; color: #0E1F3D }
    .li-ligne .doux { color: #44536E }
    .li-type { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800; background: #E8EDF5; color: #143A73; white-space: nowrap }
    .li-etat { display: inline-flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 700 }
    .li-etat i { width: 10px; height: 10px; border-radius: 50%; display: inline-block }
    .li-actions { display: flex; justify-content: flex-end; gap: 4px }
    .li-actions .btn-icon { width: 40px; height: 40px; border: 0; border-radius: 10px; background-color: transparent !important; background-size: 22px 22px !important }
    .li-actions .btn-icon:hover { background-color: #F2F5F9 !important }
    .li-vide { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .li-pied { padding: 12px 6px 0; color: #44536E; font-size: 14px }

    @media (max-width: 860px) {
        .li-grille { grid-template-columns: 1fr }
        .li-tete { display: none }
        .li-ligne { grid-template-columns: minmax(0, 1fr) auto; }
        .li-ligne .c-adr, .li-ligne .c-nb { grid-column: 1 / -1 }
    }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <%-- Pas de RadAjaxPanel : la page porte des blocs de rendu (libellés traduits). --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litPageTitle" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div>
                <asp:Button ID="btnAdd" runat="server" CssClass="fc-btn primaire" CausesValidation="false" />
            </div>
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false">
            <div id="divMsg" runat="server" class="li-msg"></div>
        </asp:Panel>

        <%-- La fiche d'un lieu : nouveau (hfId = 0) ou existant --%>
        <asp:Panel ID="pnlFiche" runat="server" Visible="false" CssClass="li-fiche" DefaultButton="btnSave">
            <asp:HiddenField ID="hfId" runat="server" Value="0" />
            <h2><asp:Literal ID="litFicheTitre" runat="server" /></h2>
            <div class="li-grille">
                <div class="li-champ">
                    <label for="<%= txtNom.ClientID %>"><%= L("nom") %> *</label>
                    <asp:TextBox ID="txtNom" runat="server" MaxLength="150" />
                </div>
                <div class="li-champ">
                    <label for="<%= ddlType.ClientID %>"><%= L("type") %></label>
                    <asp:DropDownList ID="ddlType" runat="server" />
                </div>
                <div class="li-champ">
                    <label for="<%= txtAdresse.ClientID %>"><%= L("adresse") %></label>
                    <asp:TextBox ID="txtAdresse" runat="server" MaxLength="300" />
                </div>
            </div>
            <label class="li-actif">
                <asp:CheckBox ID="chkActif" runat="server" Checked="true" />
                <%= L("actifLong") %>
            </label>
            <div class="li-boutons">
                <asp:Button ID="btnSave" runat="server" CssClass="fc-btn primaire" />
                <asp:Button ID="btnCancel" runat="server" CssClass="fc-btn" CausesValidation="false" />
            </div>
        </asp:Panel>

        <div class="li-liste">
            <div class="li-tete">
                <div><%= L("colNom") %></div>
                <div><%= L("colType") %></div>
                <div><%= L("colAdresse") %></div>
                <div><%= L("colServices") %></div>
                <div><%= L("colActif") %></div>
                <div></div>
            </div>
            <asp:Repeater ID="rptLieux" runat="server">
                <ItemTemplate>
                    <div class="li-ligne">
                        <div><b><%# Server.HtmlEncode(Convert.ToString(Eval("Nom"))) %></b></div>
                        <div><span class="li-type"><%# Server.HtmlEncode(TypeTexte(Eval("TypeLieu"))) %></span></div>
                        <div class="c-adr doux"><%# Server.HtmlEncode(If(Convert.ToString(Eval("Adresse")) = "", "—", Convert.ToString(Eval("Adresse")))) %></div>
                        <div class="c-nb doux"><%# NbServicesTexte(Eval("NbServices")) %></div>
                        <div><%# ActifCell(Eval("Actif")) %></div>
                        <div class="li-actions">
                            <asp:Button ID="btnEdit" runat="server" CssClass="btn btn-icon btn-icon-edit" Text=""
                                CommandName="Modifier" CommandArgument='<%# Eval("Id") %>' CausesValidation="false" />
                            <asp:Button ID="btnDelete" runat="server" CssClass="btn btn-icon btn-icon-delete" Text=""
                                CommandName="Supprimer" CommandArgument='<%# Eval("Id") %>' CausesValidation="false"
                                OnClientClick='<%# ConfirmerSuppression() %>' />
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
            <asp:Panel ID="pnlVide" runat="server" Visible="false" CssClass="li-vide"><%= L("vide") %></asp:Panel>
            <div class="li-pied"><asp:Literal ID="litPied" runat="server" /></div>
        </div>
</asp:Content>
