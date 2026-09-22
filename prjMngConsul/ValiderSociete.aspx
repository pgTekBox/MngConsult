<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderSociete.aspx.vb" Inherits="MngConsul.ValiderSociete" %>
<%@ Register Src="~/Controls/ImportApideckBouton.ascx" TagPrefix="uc" TagName="ImportApideckBouton" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Comparer la fiche d'entreprise — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .soc-page { max-width: 1240px; margin: 0 auto; padding: 16px }

    .soc-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .soc-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .soc-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .soc-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .soc-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 900px; line-height: 1.6 }

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

    .bilan { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 16px }
    .bil { border: 1px solid #e2e8f0; border-radius: 11px; padding: 11px 14px; background: #fff }
    .bil .l { font-size: 11px; color: #64748b; text-transform: uppercase; letter-spacing: .3px }
    .bil .v { font-size: 22px; font-weight: 800; color: #0f172a; margin-top: 2px }
    .bil.ec { background: #fffbeb; border-color: #fde68a } .bil.ec .v { color: #b45309 }
    .bil.nv { background: #eff6ff; border-color: #bfdbfe } .bil.nv .v { color: #1d4ed8 }
    .bil.ok { background: #ecfdf5; border-color: #a7f3d0 } .bil.ok .v { color: #047857 }

    table.champs { width: 100%; border-collapse: collapse; font-size: 13px; background: #fff;
                   border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden }
    table.champs th {
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700;
    }
    table.champs td { border-bottom: 1px solid #f1f5f9; padding: 9px 10px; color: #0f172a; vertical-align: top }
    table.champs td.c { width: 34px; text-align: center }
    table.champs .lib { font-weight: 600 }
    table.champs .cle { font-size: 11px; color: #94a3b8; font-family: ui-monospace, Menlo, Consolas, monospace }
    table.champs .vide { color: #cbd5e1; font-style: italic }
    table.champs tr.ecart td { background: #fffbeb }
    table.champs tr.info td { color: #64748b }

    /* La valeur qui remplacerait l'autre : elle mérite d'être lue en premier. */
    table.champs td.src { font-weight: 600 }

    .verdict {
        display: inline-block; padding: 2px 9px; border-radius: 999px;
        font-size: 11px; font-weight: 700; white-space: nowrap;
    }
    .verdict.DIFFERENT { background: #fef3c7; color: #92400e }
    .verdict.ABSENT_ICI { background: #dbeafe; color: #1e40af }
    .verdict.IDENTIQUE { background: #d1fae5; color: #065f46 }
    .verdict.ABSENT_SOURCE { background: #f1f5f9; color: #64748b }

    .msg { padding: 11px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px }
    .msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .msg.no { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }

    .rien {
        border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center;
        color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7;
    }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="soc-page">

    <div class="soc-head">
        <div class="ico">🏢</div>
        <div>
            <h1>Fiche d'entreprise</h1>
            <div class="sub">ce que dit la source, ce que dit 60Sec-AI</div>
        </div>
    </div>

    <p class="soc-lede">
        Cet import-ci ne crée rien : le nom légal, l'adresse et le téléphone existent
        déjà ici. Chaque champ est donc montré des deux côtés. Cochez ceux dont vous
        voulez la valeur de la source — les autres restent tels quels. Les lignes
        grises sont des informations que la source connaît et que 60Sec-AI ne range
        nulle part : elles ne peuvent rien remplacer.
    </p>

    <asp:Literal ID="litMsg" runat="server" />
    <uc:ImportApideckBouton ID="ucApideck" runat="server" Ressources="company-info" />

    <div class="bilan">
        <div class="bil ec"><div class="l">Écarts</div>
            <div class="v"><asp:Literal ID="litEcarts" runat="server" Text="0" /></div></div>
        <div class="bil nv"><div class="l">Absents ici</div>
            <div class="v"><asp:Literal ID="litNouveaux" runat="server" Text="0" /></div></div>
        <div class="bil ok"><div class="l">Identiques</div>
            <div class="v"><asp:Literal ID="litIdentiques" runat="server" Text="0" /></div></div>
        <div class="bil"><div class="l">Absents à la source</div>
            <div class="v"><asp:Literal ID="litManquants" runat="server" Text="0" /></div></div>
    </div>

    <div class="barre">
        <button type="button" class="btn" onclick="cocherEcarts(true)">Cocher tous les écarts</button>
        <button type="button" class="btn" onclick="cocherEcarts(false)">Tout décocher</button>
        <span class="esp"></span>
        <asp:Button ID="btnAppliquer" runat="server" CssClass="btn primaire"
                    Text="Appliquer les champs cochés" />
    </div>

    <asp:Literal ID="litChamps" runat="server" />

    <script type="text/javascript">
        // Le raccourci utile : la plupart du temps on veut tout ce qui diffère,
        // et on décoche ensuite les deux ou trois exceptions.
        function cocherEcarts(valeur) {
            var b = document.querySelectorAll('input.sel');
            for (var i = 0; i < b.length; i++) { b[i].checked = valeur; }
        }
    </script>

</div>
</asp:Content>
