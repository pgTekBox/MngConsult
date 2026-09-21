<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ValiderGrandLivre.aspx.vb" Inherits="MngConsul.ValiderGrandLivre" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Grand livre importé — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .gl-page { max-width: 1320px; margin: 0 auto; padding: 16px }

    .gl-head { display: flex; align-items: center; gap: 14px; margin-bottom: 6px }
    .gl-head .ico {
        width: 46px; height: 46px; border-radius: 13px;
        background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(16,185,129,.10));
        border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 21px;
    }
    .gl-head h1 { font-size: 21px; font-weight: 800; margin: 0; color: #0f172a }
    .gl-head .sub { font-size: 13px; color: #64748b; margin-top: 2px }
    .gl-lede { font-size: 13.5px; color: #475569; margin: 0 0 16px; max-width: 920px; line-height: 1.6 }

    /* Ce que la source a arrêté, et ce qu'elle totalise. */
    .repere {
        display: flex; gap: 22px; flex-wrap: wrap; align-items: center;
        background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
        padding: 14px 16px; margin-bottom: 14px;
    }
    .repere .bloc .l { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: #64748b; font-weight: 700 }
    .repere .bloc .v { font-size: 17px; font-weight: 800; color: #0f172a; font-variant-numeric: tabular-nums }
    .repere .verdict { margin-left: auto; padding: 8px 13px; border-radius: 9px; font-size: 13px; font-weight: 700 }
    .repere .verdict.ok { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0 }
    .repere .verdict.ko { background: #fffbeb; color: #92400e; border: 1px solid #fde68a }

    /* Le filtre par compte : un grand livre se consulte compte par compte. */
    .filtre {
        display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
        margin-bottom: 12px; font-size: 13px; color: #475569;
    }
    .filtre select {
        padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 8px;
        font-size: 13px; background: #fff; color: #0f172a; min-width: 260px;
    }

    /* La grille défile ; l'entête reste. */
    .gl-wrap {
        max-height: 620px; overflow: auto;
        border: 1px solid #e2e8f0; border-radius: 12px; background: #fff;
    }
    table.gl { width: 100%; border-collapse: collapse; font-size: 12.5px }
    table.gl th {
        position: sticky; top: 0; z-index: 2;
        text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
        color: #64748b; background: #f8fafc; border-bottom: 1px solid #e2e8f0;
        padding: 9px 10px; font-weight: 700; white-space: nowrap;
    }
    table.gl th.n, table.gl td.n { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap }
    table.gl td { border-bottom: 1px solid #f1f5f9; padding: 7px 10px; color: #0f172a; vertical-align: top }
    table.gl td.memo { color: #64748b; max-width: 280px }

    table.gl tr.compte td {
        background: #eff6ff; border-top: 1px solid #dbeafe; border-bottom: 1px solid #dbeafe;
        font-weight: 800; color: #1e3a8a; font-size: 13px; padding: 9px 10px;
    }
    table.gl tr.soustotal td {
        background: #f8fafc; font-weight: 700; color: #334155;
        border-bottom: 1px solid #e2e8f0;
    }
    table.gl tfoot td {
        position: sticky; bottom: 0;
        font-weight: 800; background: #f1f5f9; border-top: 2px solid #cbd5e1; border-bottom: 0;
    }
    table.gl .zero { color: #cbd5e1 }

    .note {
        margin-top: 16px; padding: 12px 15px; border-radius: 10px;
        background: #f8fafc; border: 1px solid #e2e8f0;
        font-size: 12.5px; color: #475569; line-height: 1.6; max-width: 920px;
    }
    .note b { color: #0f172a }

    .rien {
        border: 1px dashed #cbd5e1; border-radius: 12px; padding: 30px; text-align: center;
        color: #64748b; font-size: 13.5px; background: #fff; line-height: 1.7;
    }
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="gl-page">

    <div class="gl-head">
        <div class="ico">📚</div>
        <div>
            <h1>Grand livre</h1>
            <div class="sub">chaque écriture, sous le compte qu'elle touche</div>
        </div>
    </div>

    <p class="gl-lede">
        Ce rapport ne crée rien et ne se valide pas : c'est une <b>pièce de contrôle</b>.
        Il montre, compte par compte, ce que la comptabilité source contient sur la période
        demandée — de quoi confronter une reprise à son origine, ligne à ligne.
    </p>

    <asp:Literal ID="litRepere" runat="server" />

    <asp:Panel ID="pnlFiltre" runat="server" CssClass="filtre" Visible="false">
        <span>Compte :</span>
        <asp:DropDownList ID="ddlCompte" runat="server" AutoPostBack="true" />
        <asp:Literal ID="litCompteur" runat="server" />
    </asp:Panel>

    <asp:Literal ID="litTableau" runat="server" />
    <asp:Literal ID="litNote" runat="server" />

</div>
</asp:Content>
