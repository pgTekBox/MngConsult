<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderFactures.aspx.vb" Inherits="MngConsul.ValiderFactures" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Valider les factures importées — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .val-page { max-width: 1480px; margin: 0 auto; padding: 16px }

    .val-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .val-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .val-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .val-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .val-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 900px; line-height: 1.6 }

    .barre {
        display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
        padding: 12px 16px; margin-bottom: 16px;
    }
    .barre .esp { flex: 1 }

    .btn {
        display: inline-block; padding: 8px 15px; border-radius: 9px; border: 1px solid #cbd5e1;
        background: #fff; color: #0f172a; font-size: 13px; font-weight: 600; cursor: pointer;
    }
    .btn:hover { background: #f8fafc }
    .btn.primaire { background: #2563eb; border-color: #2563eb; color: #fff }
    .btn.primaire:hover { background: #1d4ed8 }
    .btn.danger { color: #b91c1c; border-color: #fecaca }
    .btn.danger:hover { background: #fef2f2 }

    /* Le compte rendu du lot */
    .bilan { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 16px }
    .bil { border: 1px solid #e2e8f0; border-radius: 11px; padding: 11px 14px; background: #fff }
    .bil .l { font-size: 11px; color: #64748b; text-transform: uppercase; letter-spacing: .3px }
    .bil .v { font-size: 22px; font-weight: 800; color: #0f172a; margin-top: 2px }
    .bil.ok { background: #ecfdf5; border-color: #a7f3d0 } .bil.ok .v { color: #047857 }
    .bil.mi { background: #fffbeb; border-color: #fde68a } .bil.mi .v { color: #b45309 }
    .bil.no { background: #fef2f2; border-color: #fecaca } .bil.no .v { color: #b91c1c }

    /* Les documents */
    table.docs { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
                 border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.docs th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700;
    }
    table.docs td { border-bottom: 1px solid #f1f5f9; padding: 8px 10px; color: #0f172a; vertical-align: top }
    table.docs td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.docs tr.migre td { background: #f8fafc; color: #64748b }
    table.docs tr.souci td { background: #fffbeb }
    table.docs tr.bloque td { background: #fef2f2 }

    .etiq { display: inline-block; font-size: 11px; font-weight: 700; padding: 2px 7px;
            border-radius: 6px; letter-spacing: .2px }
    .etiq.ok { background: #d1fae5; color: #065f46 }
    .etiq.existe { background: #fef3c7; color: #92400e }
    .etiq.anomalie { background: #fee2e2; color: #991b1b }
    .etiq.migre { background: #e0e7ff; color: #3730a3 }

    .anom { font-size: 12px; color: #b45309; display: block; margin-top: 3px }
    .sansTiers { font-size: 12px; color: #b91c1c }

    input.mt { width: 82px; padding: 4px 6px; border: 1px solid #cbd5e1; border-radius: 7px;
               font-size: 12.5px; text-align: right; font-variant-numeric: tabular-nums }
    select.tiers { max-width: 240px; padding: 4px 6px; border: 1px solid #fecaca; border-radius: 7px; font-size: 12.5px }

    details.lignes { margin-top: 4px }
    details.lignes summary { font-size: 12px; color: #2563eb; cursor: pointer }
    table.lig { width: 100%; border-collapse: collapse; font-size: 12px; margin: 6px 0 2px }
    table.lig th { text-align: left; color: #64748b; font-weight: 600; padding: 3px 6px;
                   border-bottom: 1px solid #e2e8f0; font-size: 11px }
    table.lig td { padding: 3px 6px; border-bottom: 1px solid #f8fafc }
    table.lig td.n { text-align: right; font-variant-numeric: tabular-nums }

    .msg { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 14px 0; line-height: 1.55 }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af }
    .vide { font-size: 13.5px; color: #64748b; padding: 22px; text-align: center;
            border: 1px dashed #cbd5e1; border-radius: 12px; background: #fff }

    /* L'état de paiement, à côté du solde. Rien ne s'affiche pour une facture
       entièrement due : c'est le cas ordinaire d'une reprise. */
    .pay {
        display: inline-block; margin-left: 6px; padding: 1px 7px; border-radius: 999px;
        font-size: 10.5px; font-weight: 800; background: #f1f5f9; color: #475569;
    }

    .pay.part { background: #fef3c7; color: #92400e }
</style>
<script>
    function toutCocher(source) {
        var cases = document.querySelectorAll("input[name='sel']");
        for (var i = 0; i < cases.length; i++) {
            if (!cases[i].disabled) { cases[i].checked = source.checked; }
        }
    }
</script>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="val-page">

    <div class="val-head">
        <div class="ico">🧾</div>
        <div>
            <h1>Valider les factures importées</h1>
            <div class="sub">Ce qui a été rapatrié attend votre accord</div>
        </div>
    </div>

    <p class="val-lede">
        Chaque facture est affichée avec son détail, son tiers et son verdict. Corrigez ce qui doit
        l'être, cochez ce que vous acceptez, et créez. Les documents sont créés
        <b>en brouillon</b> : rien n'est écrit au grand livre tant que vous ne les comptabilisez
        pas depuis les écrans habituels.
    </p>

    <asp:Literal ID="litMsg" runat="server" />

    <div class="barre">
        <asp:DropDownList ID="ddlType" runat="server" AutoPostBack="true" CssClass="btn">
            <asp:ListItem Value="1" Text="Factures clients" />
            <asp:ListItem Value="2" Text="Factures fournisseurs" />
        </asp:DropDownList>

        <%-- Ouvertes ou fermées : une facture déjà payée reprise telle quelle
             gonflerait les comptes clients d'un montant qui n'est plus dû. --%>
        <asp:DropDownList ID="ddlEtat" runat="server" AutoPostBack="true" CssClass="btn">
            <asp:ListItem Value="" Text="Toutes" />
            <asp:ListItem Value="O" Text="Ouvertes seulement" />
            <asp:ListItem Value="F" Text="Fermées seulement" />
        </asp:DropDownList>

        <span class="esp"></span>

        <asp:Button ID="btnEnregistrer" runat="server" CssClass="btn" Text="Enregistrer les corrections" CausesValidation="false" />
        <asp:Button ID="btnCreer" runat="server" CssClass="btn primaire" Text="Créer les documents cochés" CausesValidation="false" />
        <asp:Button ID="btnSupprimer" runat="server" CssClass="btn danger" Text="Retirer de la préparation" CausesValidation="false" />
    </div>

    <asp:Literal ID="litBilan" runat="server" />
    <asp:Literal ID="litDocs" runat="server" />

</div>
</asp:Content>
