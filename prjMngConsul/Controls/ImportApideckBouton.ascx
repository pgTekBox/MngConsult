<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="ImportApideckBouton.ascx.vb" Inherits="MngConsul.ImportApideckBouton" %>

<%-- « Importer depuis QuickBooks » — le même bouton sur chaque écran d'import.
     Il ne rapatrie que ce que l'écran sait montrer (Ressources), par le moteur
     ApideckExtraction, et tout se dépose en préparation : rien n'est créé. --%>

<style>
    .apb {
        border: 1px solid #bfdbfe; border-radius: 12px; margin: 0 0 16px;
        background: linear-gradient(135deg, rgba(37,99,235,.06), rgba(16,185,129,.05));
        padding: 12px 15px;
    }

    .apb-row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap }

    .apb-ico {
        width: 34px; height: 34px; border-radius: 10px; flex: none;
        background: #fff; border: 1px solid #e2e8f0;
        display: flex; align-items: center; justify-content: center; font-size: 17px;
    }

    .apb-txt { flex: 1; min-width: 240px; font-size: 13px; color: #0f172a; line-height: 1.45 }
    .apb-txt b { font-weight: 800 }
    .apb-etat { display: block; color: #64748b; font-size: 12.5px }
    .apb-etat.off { color: #b45309 }
    .apb-etat.ko { color: #b91c1c }

    .apb-champ { display: flex; align-items: center; gap: 7px; font-size: 12.5px; color: #334155; font-weight: 700 }

    .apb-date {
        padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 9px;
        font-size: 13px; font-family: inherit; background: #fff; font-weight: 400;
    }

    .apb-btn {
        padding: 9px 15px; border-radius: 9px; font-size: 13px; font-weight: 700;
        border: 1px solid #2563eb; cursor: pointer; font-family: inherit;
        background: #2563eb; color: #fff; white-space: nowrap;
    }

    .apb-btn:hover { background: #1d4ed8 }
    .apb-btn[disabled] { background: #cbd5e1; border-color: #cbd5e1; color: #fff; cursor: not-allowed }

    .apb-lien { font-size: 12.5px; color: #1d4ed8; text-decoration: none; white-space: nowrap }
    .apb-lien:hover { text-decoration: underline }

    .apb-msg { border-radius: 10px; padding: 10px 13px; font-size: 13px; margin-top: 10px; line-height: 1.55 }
    .apb-msg.ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46 }
    .apb-msg.err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b }
    .apb-msg.info { background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af }
    .apb-msg ul { margin: 6px 0 0; padding-left: 18px }
    .apb-msg li { margin: 2px 0 }
    .apb-msg .ko { color: #b91c1c }
    .apb-msg .vers { color: #047857 }
</style>

<div class="apb">
    <div class="apb-row">
        <span class="apb-ico">🔌</span>
        <div class="apb-txt">
            <b>QuickBooks, en direct</b> — sans fichier à exporter
            <span class="apb-etat" id="spanEtat" runat="server"><asp:Literal ID="litEtat" runat="server" /></span>
        </div>

        <%-- Deux ressources sur six demandent une période : la date de bascule,
             la veille du premier jour tenu ici. Le champ n'apparaît que pour elles. --%>
        <asp:Panel ID="pnlDate" runat="server" CssClass="apb-champ" Visible="false">
            <asp:Label ID="lblDate" runat="server" AssociatedControlID="txtDate" Text="Arrêté au" />
            <asp:TextBox ID="txtDate" runat="server" TextMode="Date" CssClass="apb-date" />
        </asp:Panel>

        <asp:DropDownList ID="ddlFrequence" runat="server" CssClass="apb-date" Visible="false">
            <asp:ListItem Value="3" Text="Taxes par trimestre" Selected="True" />
            <asp:ListItem Value="1" Text="Taxes par mois" />
            <asp:ListItem Value="12" Text="Taxes par année" />
        </asp:DropDownList>

        <asp:Button ID="btnImporter" runat="server" CssClass="apb-btn" CausesValidation="false"
            Text="⬇ Importer depuis QuickBooks"
            OnClientClick="this.value='⏳ Extraction en cours…';" />
        <asp:HyperLink ID="hlLiaison" runat="server" CssClass="apb-lien" NavigateUrl="~/ImportApideck.aspx" Text="Gérer la liaison" />
    </div>

    <asp:Literal ID="litResultat" runat="server" />
</div>
