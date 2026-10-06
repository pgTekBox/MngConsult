<%@ Page Title="Ma compagnie" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Compagnie.aspx.vb" Inherits="Paie60Sec.Web.PageCompagnie" %>
<asp:Content ContentPlaceHolderID="Contenu" runat="server">
    <h1>Configuration</h1>
    <%= SousMenuConfig("compagnie") %>

    <fieldset>
        <legend>Compagnie</legend>
        <asp:Literal ID="litIdentite" runat="server" />
        <p class="note">Le nom et les coordonnées de la compagnie se modifient dans 60Sec (paramètres de l'entreprise).</p>
    </fieldset>

    <fieldset>
        <legend>Informations de paie</legend>
        <div class="champs">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlProvince" CssClass="requis">Province d'emploi</asp:Label>
                <asp:DropDownList ID="ddlProvince" runat="server" AutoPostBack="true" />
                <div class="aide">Province ou territoire de l'établissement où vos employés se présentent au travail. Elle décide des retenues, des remises et des feuillets.</div></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlPeriodes" CssClass="requis">Période de paie par défaut</asp:Label>
                <asp:DropDownList ID="ddlPeriodes" runat="server">
                    <asp:ListItem Value="52">Hebdomadaire (52 périodes)</asp:ListItem>
                    <asp:ListItem Value="26" Selected="True">Aux 2 semaines (26 périodes)</asp:ListItem>
                    <asp:ListItem Value="24">Bimensuel (24 périodes)</asp:ListItem>
                    <asp:ListItem Value="12">Mensuel (12 périodes)</asp:ListItem>
                    <asp:ListItem Value="1">Annuelle (1 période)</asp:ListItem>
                </asp:DropDownList></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxVacances" CssClass="requis">Taux de vacances par défaut (%)</asp:Label>
                <asp:TextBox ID="txtTauxVacances" runat="server" MaxLength="6" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtProchainCheque">Prochain numéro de chèque</asp:Label>
                <asp:TextBox ID="txtProchainCheque" runat="server" MaxLength="9" /></div>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlFreqFederale">Fréquence de paiement des retenues fédérales</asp:Label>
                <asp:DropDownList ID="ddlFreqFederale" runat="server">
                    <asp:ListItem Value="M">Mensuelle (dû le 15 du mois suivant)</asp:ListItem>
                    <asp:ListItem Value="T">Trimestrielle (dû le 15 suivant le trimestre)</asp:ListItem>
                </asp:DropDownList></div>
            <asp:PlaceHolder ID="phQuebecRemise" runat="server">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlFreqQuebec">Fréquence de paiement des retenues à Revenu Québec</asp:Label>
                <asp:DropDownList ID="ddlFreqQuebec" runat="server">
                    <asp:ListItem Value="M">Mensuelle (dû le 15 du mois suivant)</asp:ListItem>
                    <asp:ListItem Value="T">Trimestrielle (dû le 15 suivant le trimestre)</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">La fréquence est celle que l'ARC et Revenu Québec vous ont attribuée.</div></div>
            </asp:PlaceHolder>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNEFederal">Numéro d'entreprise fédéral (RP)</asp:Label>
                <asp:TextBox ID="txtNEFederal" runat="server" MaxLength="20" placeholder="123456789RP0001" /></div>
            <asp:PlaceHolder ID="phQuebecNumero" runat="server">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtNIRQ">Numéro d'identification Revenu Québec (RS)</asp:Label>
                <asp:TextBox ID="txtNIRQ" runat="server" MaxLength="20" placeholder="1234567890RS0001" /></div>
            </asp:PlaceHolder>
        </div>
        <asp:PlaceHolder ID="phHorsQuebecNote" runat="server" Visible="false">
        <p class="note">Hors Québec : l'impôt fédéral, l'impôt de la province ou du territoire, le RPC et l'assurance-emploi se remettent ensemble au Receveur général, à la fréquence que l'ARC vous a attribuée.
           Il n'y a pas de remise à Revenu Québec. La cotisation santé de l'employeur, là où il y en a une, et la prime de la commission des accidents du travail se paient à part.</p>
        </asp:PlaceHolder>
        <asp:PlaceHolder ID="phTerritoireNote" runat="server" Visible="false">
        <p class="note">Territoires du Nord-Ouest et Nunavut : l'impôt de 2 % sur la paie est retenu à l'employé à chaque paie. Il se remet au gouvernement du territoire et ne fait pas partie des remises au Receveur général.</p>
        </asp:PlaceHolder>
    </fieldset>

    <fieldset>
        <legend>Cotisations de l'employeur</legend>
        <div class="champs">
            <asp:PlaceHolder ID="phMasse" runat="server">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtMasse">Masse salariale totale estimée ($)</asp:Label>
                <asp:TextBox ID="txtMasse" runat="server" MaxLength="15" />
                <asp:PlaceHolder ID="phQuebecMasse" runat="server"><div class="aide">Sert à déterminer le taux de cotisation au FSS.</div></asp:PlaceHolder>
                <asp:PlaceHolder ID="phOntarioMasse" runat="server" Visible="false"><div class="aide">Rémunération totale versée en Ontario dans l'année. Sert à déterminer le taux de l'impôt-santé des employeurs (ISE).</div></asp:PlaceHolder></div>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phQuebecSecteur" runat="server">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlSecteur">Secteur d'activité (FSS)</asp:Label>
                <asp:DropDownList ID="ddlSecteur" runat="server">
                    <asp:ListItem Value="0">Général</asp:ListItem>
                    <asp:ListItem Value="1">Primaire et manufacturier</asp:ListItem>
                    <asp:ListItem Value="2">Secteur public</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">Taux FSS appliqué : <asp:Literal ID="litTauxFSS" runat="server" /></div></div>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phOntarioISE" runat="server" Visible="false">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="ddlISE">Exemption de l'impôt-santé des employeurs (ISE)</asp:Label>
                <asp:DropDownList ID="ddlISE" runat="server">
                    <asp:ListItem Value="1">Admissible à l'exemption</asp:ListItem>
                    <asp:ListItem Value="0">Non admissible (secteur public, groupe associé qui l'utilise déjà)</asp:ListItem>
                </asp:DropDownList>
                <div class="aide">Taux ISE appliqué à chaque paie : <asp:Literal ID="litTauxISE" runat="server" /></div>
                <div class="aide">L'employeur admissible ne paie l'ISE que sur la rémunération qui dépasse l'exemption ; le taux affiché est ramené sur toute la masse salariale.</div></div>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phSante" runat="server" Visible="false">
            <div class="champ"><asp:Label ID="lblTauxSante" runat="server" AssociatedControlID="txtTauxSante" />
                <asp:TextBox ID="txtTauxSante" runat="server" MaxLength="8" />
                <div class="aide">Taux effectif, en pourcentage de la rémunération, appliqué à chaque paie. Il dépend de votre masse salariale et de l'exemption de la province : 60secPaie ne le calcule pas. Prenez-le auprès de l'administration provinciale.</div>
                <div class="aide">Laissez 0 si votre masse salariale est sous le seuil d'exemption.</div></div>
            </asp:PlaceHolder>
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtFacteurAE" CssClass="requis">Facteur de cotisation de l'employeur à l'AE</asp:Label>
                <asp:TextBox ID="txtFacteurAE" runat="server" MaxLength="6" />
                <div class="aide">1,4 sauf si vous bénéficiez d'un taux réduit.</div></div>
            <asp:PlaceHolder ID="phQuebecCNESST" runat="server">
            <div class="champ"><asp:Label runat="server" AssociatedControlID="txtTauxCNESST">Taux de la CNESST ($ par 100 $ assurables)</asp:Label>
                <asp:TextBox ID="txtTauxCNESST" runat="server" MaxLength="8" />
                <div class="aide">Taux de versement périodique de votre décision de classification. Avec plusieurs unités, définissez-les dans « Unités CNESST » et affectez chaque employé à la sienne.</div>
                <div class="aide">Inscrit sur votre décision de classification.</div></div>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phAccidents" runat="server" Visible="false">
            <div class="champ"><asp:Label ID="lblTauxAccidents" runat="server" AssociatedControlID="txtTauxAccidents" />
                <asp:TextBox ID="txtTauxAccidents" runat="server" MaxLength="8" />
                <div class="aide"><asp:Literal ID="litAideAccidents" runat="server" /></div></div>
            </asp:PlaceHolder>
        </div>
        <asp:PlaceHolder ID="phQuebecCNT" runat="server">
        <div class="cases">
            <span><asp:CheckBox ID="chkCNT" runat="server" Text="Assujetti à la cotisation relative aux normes du travail (CNT)" /></span>
        </div>
        </asp:PlaceHolder>
    </fieldset>

    <div class="actions">
        <asp:Button ID="btnEnregistrer" runat="server" Text="Enregistrer" />
    </div>
</asp:Content>
