<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderTaxes.aspx.vb" Inherits="MngConsul.ValiderTaxes" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Codes et taux de taxe — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .tx-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .tx-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .tx-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .tx-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .tx-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .tx-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .bloc.no .v { color: #b91c1c }
    .repere .bloc.mi .v { color: #b45309 }

    table.tx { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
               border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; margin-bottom: 16px }
    table.tx th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.tx th.n, table.tx td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.tx td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.tx tr.verif td { background: #fffbeb }
    table.tx tr.inconnu td { background: #fef2f2 }
    table.tx td.nom { font-weight: 600 }
    table.tx .fil { color: #64748b; font-weight: 400; font-size: 12px }
    table.tx .zero { color: #cbd5e1 }
    table.tx .anom { display: block; font-size: 12px; color: #b45309; margin-top: 3px }

    .etiq { display: inline-block; font-size: 11px; font-weight: 700; padding: 2px 7px;
            border-radius: 6px; letter-spacing: .2px; white-space: nowrap }
    .etiq.ok { background: #d1fae5; color: #065f46 }
    .etiq.verif { background: #fef3c7; color: #92400e }
    .etiq.man { background: #e0e7ff; color: #3730a3 }
    .etiq.src { background: #f1f5f9; color: #475569 }
    .etiq.inconnu { background: #fee2e2; color: #991b1b }

    .btn {
        display: inline-block; padding: 8px 15px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600; cursor: pointer;
    }
    .btn:hover { background: #f8fafc }
    .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff }
    .btn.primaire:hover { background: #1d4ed8 }
    .btn.danger { color: #b91c1c; border-color: #fecaca }
    .btn.danger:hover { background: #fef2f2 }
    .btn.petit { padding: 3px 9px; font-size: 12px; border-radius: 7px }

    .carte {
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 16px;
    }
    .carte h2 { font-size: 14px; font-weight: 800; margin: 0 0 4px; color: #0f172a }
    .carte .aide { font-size: 12.5px; color: #64748b; margin: 0 0 12px; line-height: 1.55 }
    .champs { display: flex; gap: 12px; flex-wrap: wrap; align-items: flex-end }
    .champ label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
                   color: #64748b; font-weight: 700; margin-bottom: 4px }
    .champ input[type=text] { padding: 7px 9px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 13px }
    .champ input.pct { width: 90px; text-align: right; font-variant-numeric: tabular-nums }
    .champ input.code { width: 130px }
    .champ input.nom { width: 300px }

    .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 14px 0; line-height: 1.55 }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af }

    .rien {
        border: 1px dashed #cbd5e1; border-radius: 12px; padding: 24px; text-align: center;
        color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7; margin-bottom: 16px;
    }
    .note {
        margin-top: 4px; padding: 12px 15px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px;
    }
    .note b { color: #0f172a }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="tx-page">

    <div class="tx-head">
        <div class="ico">🧮</div>
        <div>
            <h1>Codes et taux de taxe</h1>
            <div class="sub">ce que l'ancien logiciel appelle « TPS/TVQ QC », et ce que ça vaut en TPS et en TVQ</div>
        </div>
    </div>

    <p class="tx-lede">
        Chaque ligne de facture reprise porte un <b>code de taxe</b> de l'ancien logiciel, jamais le montant.
        C'est ce tableau qui dit à la répartition ce que vaut chaque code : tant de TPS, tant de TVQ.
        Les taux arrivent avec le bouton QuickBooks ; vous pouvez en <b>ajouter</b> ou en <b>corriger</b>
        à la main, ou les charger par fichier. Rien ici ne touche les taxes de votre comptabilité :
        ces taux ne servent qu'à couper les factures en préparation.
    </p>

    <asp:Literal ID="litMsg" runat="server" />
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="tax-rates" />

    <asp:Literal ID="litRepere" runat="server" />
    <asp:Literal ID="litInconnus" runat="server" />
    <asp:Literal ID="litTableau" runat="server" />

    <div class="carte">
        <h2><asp:Literal ID="litTitreForm" runat="server" Text="Ajouter ou corriger un taux" /></h2>
        <p class="aide">
            Le <b>code</b> est ce que les lignes de factures portent (par exemple « 8 », « TPS », « NON »).
            Les taux sont des pourcentages : TPS 5, TVQ 9,975. Un code sans taxe (exonéré, détaxé) se saisit avec 0 et 0.
        </p>
        <asp:HiddenField ID="hfId" runat="server" />
        <div class="champs">
            <div class="champ"><label>Code</label><asp:TextBox ID="txtCode" runat="server" CssClass="code" MaxLength="100" /></div>
            <div class="champ"><label>Nom</label><asp:TextBox ID="txtNom" runat="server" CssClass="nom" MaxLength="200" placeholder="TPS/TVQ QC - 9,975" /></div>
            <div class="champ"><label>TPS %</label><asp:TextBox ID="txtTPS" runat="server" CssClass="pct" Text="5" /></div>
            <div class="champ"><label>TVQ %</label><asp:TextBox ID="txtTVQ" runat="server" CssClass="pct" Text="9,975" /></div>
            <div class="champ"><asp:Button ID="btnSave" runat="server" CssClass="btn primaire" Text="Enregistrer le taux" CausesValidation="false" /></div>
            <div class="champ"><asp:Button ID="btnAnnuler" runat="server" CssClass="btn" Text="Annuler" CausesValidation="false" Visible="false" /></div>
        </div>
    </div>

    <div class="carte">
        <h2>Charger des taux par fichier</h2>
        <p class="aide">
            Un fichier .csv ou .txt, une taxe par ligne : <b>code ; nom ; TPS % ; TVQ %</b>
            (séparateur point-virgule, virgule ou tabulation ; une ligne d'en-tête est ignorée).
            Un code déjà présent est corrigé, un nouveau est ajouté.
        </p>
        <div class="champs">
            <div class="champ"><asp:FileUpload ID="fuFichier" runat="server" accept=".csv,.txt" /></div>
            <div class="champ"><asp:Button ID="btnImporter" runat="server" CssClass="btn" Text="Charger le fichier" CausesValidation="false" /></div>
            <span class="esp"></span>
            <div class="champ"><asp:Button ID="btnRepartir" runat="server" CssClass="btn" Text="Répartir les taxes des factures maintenant" ToolTip="Applique ces taux aux factures en préparation (même chose que le bouton de l'écran Factures)" CausesValidation="false" /></div>
        </div>
    </div>

    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
