<%@ Page Title="Plan comptable par défaut" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfPlanComptableDefaut.aspx.vb"
    Inherits="prjSec60Admin.wbfPlanComptableDefaut" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Plan comptable par défaut — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pc-wrap { padding: 20px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
        .pc-wrap h1 { font-size: 22px; font-weight: 900; margin: 0 0 6px; color: #0f172a; }
        .pc-sub { color: #64748b; font-size: 13px; margin-bottom: 14px; max-width: 980px; line-height: 1.6; }
        .pc-sub b { color: #0f172a; }
        .pc-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; padding: 14px 16px; margin-bottom: 16px; }
        .pc-card h2 { font-size: 15px; font-weight: 900; margin: 0 0 4px; color: #0f172a; }
        .pc-card .aide { font-size: 12.5px; color: #64748b; margin: 0 0 12px; line-height: 1.55; }
        .pc-repere { display: flex; gap: 22px; flex-wrap: wrap; align-items: center; margin-bottom: 14px; }
        .pc-repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 800; }
        .pc-repere .bloc .v { font-size: 18px; font-weight: 900; color: #0f172a; font-variant-numeric: tabular-nums; }
        .pc-barre { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; }
        .pc-barre input[type=text] { padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 13px; width: 280px; }
        .pc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .pc-table th, .pc-table td { border-bottom: 1px solid #e2e8f0; padding: 6px 8px; text-align: left; vertical-align: top; }
        .pc-table th { background: #f8fafc; font-weight: 800; color: #0f172a; position: sticky; top: 0; white-space: nowrap; }
        .pc-table tr.classe td { background: #eff6ff; color: #1e3a8a; font-weight: 900; border-top: 1px solid #dbeafe; }
        .pc-table tr.inactif td { color: #94a3b8; }
        .pc-table td.num { font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 700; }
        .pc-table td.desc { color: #64748b; font-size: 12px; }
        .pill { display: inline-block; padding: 1px 7px; border-radius: 999px; font-size: 11px; font-weight: 800; border: 1px solid #e2e8f0; background: #f1f5f9; color: #475569; white-space: nowrap; }
        .pill.sys { background: #fef3c7; color: #92400e; border-color: #fcd34d; }
        .pill.off { background: #fef2f2; color: #991b1b; border-color: #fecaca; }
        .btn { display: inline-block; padding: 7px 14px; border-radius: 9px; border: 1px solid #cbd5e1; background: #fff; color: #0f172a; font-size: 13px; font-weight: 700; cursor: pointer; }
        .btn:hover { background: #f8fafc; }
        .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff; }
        .btn.primaire:hover { background: #1d4ed8; }
        .btn.danger { color: #b91c1c; border-color: #fecaca; }
        .btn.danger:hover { background: #fef2f2; }
        .btn.petit { padding: 2px 8px; font-size: 12px; border-radius: 7px; }
        .champs { display: flex; gap: 12px; flex-wrap: wrap; align-items: flex-end; }
        .champ label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 800; margin-bottom: 4px; }
        .champ input[type=text], .champ select { padding: 7px 9px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 13px; }
        .champ input.num { width: 90px; }
        .champ input.nom { width: 300px; }
        .champ input.desc { width: 420px; }
        .champ select { min-width: 200px; }
        .champ .case { font-size: 13px; padding: 8px 0; }
        .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 0 0 14px; line-height: 1.55; }
        .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
        .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }
        .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; }
        .pc-tbl-wrap { max-height: 70vh; overflow: auto; border: 1px solid #e2e8f0; border-radius: 10px; }
        .pc-note { font-size: 12.5px; color: #475569; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px 15px; line-height: 1.6; max-width: 980px; }
        .pc-note b { color: #0f172a; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pc-wrap">
        <h1>Plan comptable par défaut</h1>
        <div class="pc-sub">
            Le plan que reçoit <b>chaque nouvelle compagnie</b> : c'est celui de la compagnie modèle
            (<code>00000000-0000-0000-0000-000000000001</code>), copié avec ses classes, ses journaux et ses paramètres
            au premier enregistrement des Paramètres de la compagnie (procédure s0500InitializeCompanyData).
            Ce que vous changez ici vaut pour les compagnies <b>créées ensuite</b> ; les compagnies existantes gardent leur plan.
        </div>

        <asp:Literal ID="litMsg" runat="server" />

        <div class="pc-card">
            <div class="pc-repere">
                <div class="bloc"><div class="l">Comptes</div><div class="v"><asp:Literal ID="litNbComptes" runat="server" /></div></div>
                <div class="bloc"><div class="l">Actifs</div><div class="v"><asp:Literal ID="litNbActifs" runat="server" /></div></div>
                <div class="bloc"><div class="l">Système</div><div class="v"><asp:Literal ID="litNbSysteme" runat="server" /></div></div>
                <div class="bloc"><div class="l">Classes</div><div class="v"><asp:Literal ID="litNbClasses" runat="server" /></div></div>
            </div>
            <div class="pc-barre">
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Numéro ou nom de compte…" />
                <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Chercher" CausesValidation="false" />
                <asp:Button ID="btnTout" runat="server" CssClass="btn" Text="Tout afficher" CausesValidation="false" />
            </div>
            <div class="pc-tbl-wrap">
                <asp:Literal ID="litTableau" runat="server" />
            </div>
        </div>

        <div class="pc-card">
            <h2><asp:Literal ID="litTitreForm" runat="server" Text="Ajouter un compte au plan par défaut" /></h2>
            <p class="aide">
                Choisissez d'abord la classe : la sous-classe, le type de bilan et le sens se remplissent d'après elle.
                Le numéro doit être libre dans le plan modèle. Un compte <b>système</b> (utilisé par l'application elle-même)
                se corrige mais ne se supprime pas.
            </p>
            <asp:HiddenField ID="hfId" runat="server" />
            <div class="champs">
                <div class="champ"><label>Classe</label>
                    <asp:DropDownList ID="ddlClasseParent" runat="server" AutoPostBack="true" /></div>
                <div class="champ"><label>Sous-classe</label>
                    <asp:DropDownList ID="ddlClasse" runat="server" /></div>
                <div class="champ"><label>Numéro</label>
                    <asp:TextBox ID="txtNumero" runat="server" CssClass="num" MaxLength="10" /></div>
                <div class="champ"><label>Nom</label>
                    <asp:TextBox ID="txtNom" runat="server" CssClass="nom" MaxLength="150" /></div>
                <div class="champ"><label>Type de bilan</label>
                    <asp:DropDownList ID="ddlTypeBilan" runat="server">
                        <asp:ListItem Text="Actif" Value="A" />
                        <asp:ListItem Text="Passif" Value="P" />
                        <asp:ListItem Text="Capitaux propres" Value="CP" />
                        <asp:ListItem Text="Revenus" Value="R" />
                        <asp:ListItem Text="Charges" Value="C" />
                    </asp:DropDownList></div>
                <div class="champ"><label>Sens</label>
                    <asp:DropDownList ID="ddlSens" runat="server">
                        <asp:ListItem Text="Débiteur" Value="D" />
                        <asp:ListItem Text="Créditeur" Value="C" />
                    </asp:DropDownList></div>
                <div class="champ"><label>Actif</label>
                    <div class="case"><asp:CheckBox ID="chkActif" runat="server" Checked="true" Text=" visible dans les nouvelles compagnies" /></div></div>
            </div>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><label>Description</label>
                    <asp:TextBox ID="txtDescription" runat="server" CssClass="desc" MaxLength="250" /></div>
            </div>
            <p class="aide" style="margin-top:12px">
                <b>Alias QuickBooks.</b> Le nom que QuickBooks donne à ce compte, en français et en anglais, et son sous-type
                (par exemple <i>UndepositedFunds</i>). À la reprise d'un plan QuickBooks, un compte qui porte ce nom ou ce sous-type
                est lié d'office à celui-ci, sans passer par l'IA. Laissez vide si aucun compte QuickBooks par défaut n'y correspond.
            </p>
            <div class="champs">
                <div class="champ"><label>Nom QBO (français)</label>
                    <asp:TextBox ID="txtQboFr" runat="server" CssClass="nom" MaxLength="200" placeholder="Fonds non déposés" /></div>
                <div class="champ"><label>Nom QBO (anglais)</label>
                    <asp:TextBox ID="txtQboEn" runat="server" CssClass="nom" MaxLength="200" placeholder="Undeposited Funds" /></div>
                <div class="champ"><label>Sous-type QBO</label>
                    <asp:TextBox ID="txtQboSousType" runat="server" CssClass="nom" MaxLength="100" placeholder="UndepositedFunds" /></div>
            </div>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><asp:Button ID="btnSave" runat="server" CssClass="btn primaire" Text="Enregistrer" CausesValidation="false" /></div>
                <div class="champ"><asp:Button ID="btnAnnuler" runat="server" CssClass="btn" Text="Annuler" CausesValidation="false" Visible="false" /></div>
            </div>
        </div>

        <div class="pc-card">
            <h2>Ajouter depuis un import QuickBooks</h2>
            <p class="aide">
                Les comptes QuickBooks qu'une compagnie a décidé de <b>Créer</b> à l'étape 2 de sa reprise sont ceux qui
                n'ont aucun équivalent dans notre plan. Choisissez la compagnie, cochez ceux qui méritent d'entrer dans le
                plan par défaut, donnez-leur leur sous-classe, et ajoutez : chaque compte est créé dans le modèle avec son
                <b>alias QuickBooks</b>, et le prochain client QuickBooks se le voit lier d'office. Rien ne change chez la compagnie d'origine.
            </p>
            <div class="champs">
                <div class="champ"><label>Compagnie</label>
                    <asp:DropDownList ID="ddlCompagnie" runat="server" /></div>
                <div class="champ"><asp:Button ID="btnVoir" runat="server" CssClass="btn" Text="Voir les candidats" CausesValidation="false" /></div>
            </div>
            <div style="margin-top:12px">
                <asp:Literal ID="litCandidats" runat="server" />
            </div>
            <div class="champs" style="margin-top:10px">
                <div class="champ"><asp:Button ID="btnAjouterModele" runat="server" CssClass="btn primaire" Text="Ajouter les comptes cochés au plan par défaut" CausesValidation="false" Visible="false"
                    OnClientClick="if (!confirm('Ajouter les comptes cochés au plan comptable par défaut ? Les prochaines compagnies les recevront.')) { return false; }" /></div>
            </div>
        </div>

        <div class="pc-note">
            <b>Ce qui n'est pas ici.</b> Les classes et sous-classes (T120) et les journaux (T130) du modèle ne se modifient pas
            dans cette page. Les compagnies déjà créées ne sont jamais resynchronisées : un compte ajouté ici n'apparaît pas chez elles.
            Le drapeau <span class="pill sys">système</span> marque les comptes que l'application utilise elle-même
            (banque principale, taxes, comptes clients et fournisseurs…) : on peut les renommer, pas les retirer.
        </div>
    </div>
</asp:Content>
