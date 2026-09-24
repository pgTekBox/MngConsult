<%@ Page Title="Fiche de l'employé" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Fiche.aspx.vb" Inherits="Paie60Sec.Web.PageFicheEmploye" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <div class="barre">
        <h1><asp:Literal ID="litTitre" runat="server" /></h1>
        <asp:Panel ID="pnlLiens" runat="server" Visible="false" CssClass="actions">
            <asp:HyperLink ID="lnkElements" runat="server" CssClass="bouton secondaire">Éléments de paie</asp:HyperLink>
            <asp:HyperLink ID="lnkCumulatifs" runat="server" CssClass="bouton secondaire">Cumulatifs de départ</asp:HyperLink>
        </asp:Panel>
    </div>

    <fieldset>
        <legend>Employé (60Sec)</legend>
        <asp:Literal ID="litIdentite" runat="server" />
        <p class="note">Ces renseignements proviennent de 60Sec et s'y modifient.</p>
    </fieldset>

    <fieldset>
        <legend>Renseignements personnels pour la paie</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtDateNaissance" Text="Date de naissance" />
                <asp:TextBox ID="txtDateNaissance" runat="server" TextMode="Date" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlLangue" Text="Langue des talons et courriels" />
                <asp:DropDownList ID="ddlLangue" runat="server">
                    <asp:ListItem Value="FR">Français</asp:ListItem>
                    <asp:ListItem Value="EN">English</asp:ListItem>
                    <asp:ListItem Value="ES">Español</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNAS" Text="Numéro d'assurance sociale (NAS)" />
                <asp:TextBox ID="txtNAS" runat="server" MaxLength="11" autocomplete="off" />
                <div class="aide"><asp:Literal ID="litNasActuel" runat="server" /></div></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Informations de paie</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlPeriodes" Text="Période de paie" />
                <asp:DropDownList ID="ddlPeriodes" runat="server">
                    <asp:ListItem Value="">Par défaut (60Sec, sinon la compagnie)</asp:ListItem>
                    <asp:ListItem Value="52">Hebdomadaire (52 périodes)</asp:ListItem>
                    <asp:ListItem Value="26">Aux 2 semaines (26 périodes)</asp:ListItem>
                    <asp:ListItem Value="24">Bimensuel (24 périodes)</asp:ListItem>
                    <asp:ListItem Value="12">Mensuel (12 périodes)</asp:ListItem>
                    <asp:ListItem Value="1">Annuelle (1 période)</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtHeuresSemaine" Text="Heures par semaine" />
                <asp:TextBox ID="txtHeuresSemaine" runat="server" MaxLength="6" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxHoraire" Text="Taux horaire ($)" />
                <asp:TextBox ID="txtTauxHoraire" runat="server" MaxLength="10" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtSalaireAnnuel" Text="Salaire annuel ($)" />
                <asp:TextBox ID="txtSalaireAnnuel" runat="server" MaxLength="12" />
                <div class="aide">Utilisé si aucun taux horaire n'est inscrit.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxVacances" Text="Taux de vacances (%)" />
                <asp:TextBox ID="txtTauxVacances" runat="server" MaxLength="6" />
                <div class="aide">Vide = taux par défaut de la compagnie.</div></div>
        </div>
        <p class="note">Le taux horaire, le salaire et la fréquence proposés viennent de 60Sec lorsqu'ils y sont inscrits ; ce que vous enregistrez ici s'applique à la paie.</p>
    </fieldset>

    <fieldset>
        <legend>Exemptions (cas particuliers seulement)</legend>
        <div class="avertissement">
            <strong>Laissez tout décoché pour un employé ordinaire :</strong> toutes les retenues et cotisations sont calculées automatiquement.
            Une case cochée signifie que la retenue <strong>n'est pas calculée</strong> (elle sera à 0 $).
        </div>
        <div class="cases">
            <span><asp:CheckBox ID="chkExFed" runat="server" Text="Ne pas retenir l'impôt fédéral" /></span>
            <span><asp:CheckBox ID="chkExQc" runat="server" Text="Ne pas retenir l'impôt du Québec" /></span>
            <span><asp:CheckBox ID="chkExRRQ" runat="server" Text="Ne pas cotiser au RRQ" /></span>
            <span><asp:CheckBox ID="chkExRQAP" runat="server" Text="Ne pas cotiser au RQAP" /></span>
            <span><asp:CheckBox ID="chkExAE" runat="server" Text="Ne pas cotiser à l'assurance-emploi" /></span>
            <span><asp:CheckBox ID="chkExFSS" runat="server" Text="Exclure du FSS" /></span>
            <span><asp:CheckBox ID="chkExCNESST" runat="server" Text="Exclure de la CNESST / CNT" /></span>
        </div>
    </fieldset>

    <fieldset>
        <legend>Imposition fédérale</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTD1Montant">TD1 - Montant total de la demande ($)</asp:Label>
                <asp:TextBox ID="txtTD1Montant" runat="server" MaxLength="12" />
                <div class="aide">Vide = montant personnel de base (<asp:Literal ID="litBaseFed" runat="server" />).</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTD1Additionnel">TD1 - Impôt additionnel par paie ($)</asp:Label>
                <asp:TextBox ID="txtTD1Additionnel" runat="server" MaxLength="10" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTD1Zone">TD1 - Déduction pour zone visée, annuelle ($)</asp:Label>
                <asp:TextBox ID="txtTD1Zone" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTD1Deductions">T1213 - Déductions annuelles autorisées ($)</asp:Label>
                <asp:TextBox ID="txtTD1Deductions" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlDentaire">T4, case 45 - Soins dentaires offerts par l'employeur</asp:Label>
                <asp:DropDownList ID="ddlDentaire" runat="server">
                    <asp:ListItem Value="1">1 - Aucun accès</asp:ListItem>
                    <asp:ListItem Value="2">2 - Accès : employé seulement</asp:ListItem>
                    <asp:ListItem Value="3">3 - Accès : employé, conjoint et enfants à charge</asp:ListItem>
                    <asp:ListItem Value="4">4 - Accès : employé et conjoint</asp:ListItem>
                    <asp:ListItem Value="5">5 - Accès : employé et enfants à charge</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">Case obligatoire sur le T4 : accès au 31 décembre à une assurance dentaire de l'employeur.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTD1Credits">Autres crédits d'impôt fédéraux autorisés ($)</asp:Label>
                <asp:TextBox ID="txtTD1Credits" runat="server" MaxLength="12" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Imposition du Québec</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTPMontant">TP-1015.3 - Montant de la ligne 10 ($)</asp:Label>
                <asp:TextBox ID="txtTPMontant" runat="server" MaxLength="12" />
                <div class="aide">Vide = montant personnel de base (<asp:Literal ID="litBaseQc" runat="server" />).</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTPAdditionnel">Retenue supplémentaire par paie ($)</asp:Label>
                <asp:TextBox ID="txtTPAdditionnel" runat="server" MaxLength="10" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTPLigne19">TP-1015.3 - Déductions de la ligne 19 ($)</asp:Label>
                <asp:TextBox ID="txtTPLigne19" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTP1016Deductions">TP-1016 - Déductions annuelles autorisées ($)</asp:Label>
                <asp:TextBox ID="txtTP1016Deductions" runat="server" MaxLength="12" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTP1016Credits">TP-1016 - Crédits d'impôt autorisés ($)</asp:Label>
                <asp:TextBox ID="txtTP1016Credits" runat="server" MaxLength="12" /></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Paiement</legend>
        <div class="cases">
            <span><asp:CheckBox ID="chkDepot" runat="server" Text="Cet employé est payé par dépôt direct" /></span>
            <span><asp:CheckBox ID="chkTalonCourriel" runat="server" Text="Envoyer le talon de paie par courriel" /></span>
        </div>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTransit">Numéro de transit (5 chiffres)</asp:Label>
                <asp:TextBox ID="txtTransit" runat="server" MaxLength="5" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtInstitution">Numéro d'institution (3 chiffres)</asp:Label>
                <asp:TextBox ID="txtInstitution" runat="server" MaxLength="3" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtCompte">Numéro de compte</asp:Label>
                <asp:TextBox ID="txtCompte" runat="server" MaxLength="12" autocomplete="off" />
                <div class="aide"><asp:Literal ID="litCompteActuel" runat="server" /></div></div>
        </div>
    </fieldset>

    <fieldset>
        <legend>Notes</legend>
        <asp:TextBox ID="txtNote" runat="server" TextMode="MultiLine" />
    </fieldset>

    <div class="actions">
        <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
        <a runat="server" href="~/Employes/Liste.aspx">Annuler</a>
    </div>
</asp:Content>
