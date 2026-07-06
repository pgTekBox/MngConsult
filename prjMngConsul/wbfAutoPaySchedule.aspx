<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAutoPaySchedule.aspx.vb" Inherits="MngConsul.wbfAutoPaySchedule" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Calendrier auto-paiement — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .autopay-page { max-width: 1100px; margin: 0 auto; padding: 16px; }
        .page-title { font-size: 22px; font-weight: 800; margin: 0 0 14px 0; display: flex; gap: 10px; align-items: center; }
        .page-tabs { display: flex; gap: 6px; margin-bottom: 18px; border-bottom: 1px solid #e2e8f0; }
        .page-tabs a {
            padding: 10px 16px; text-decoration: none; color: #64748b;
            font-weight: 700; font-size: 13px; border-bottom: 3px solid transparent;
        }
        .page-tabs a:hover { color: #2563eb; }
        .page-tabs a.active { color: #2563eb; border-bottom-color: #2563eb; }

        .filter-bar {
            display: flex; gap: 12px; align-items: center; margin-bottom: 14px;
            flex-wrap: wrap; background: #fff; padding: 12px 16px; border-radius: 12px;
        }
        .filter-bar label { font-size: 12px; font-weight: 700; color: #475569; }
        .filter-bar select, .filter-bar input[type="date"] {
            padding: 6px 10px; border: 1px solid #e2e8f0; border-radius: 8px;
            font-family: inherit; font-size: 13px;
        }

        .day-group {
            margin-bottom: 18px;
        }
        .day-header {
            display: flex; justify-content: space-between; align-items: center;
            padding: 8px 12px;
            background: linear-gradient(135deg, #2563eb, #06b6d4);
            color: #fff; font-weight: 800; border-radius: 8px;
            margin-bottom: 8px;
        }
        .day-header.today { background: linear-gradient(135deg, #f59e0b, #ef4444); }
        .day-header.past { background: #94a3b8; }

        .day-items { display: flex; flex-direction: column; gap: 8px; }
        .sched-card {
            background: #fff; border-radius: 10px; padding: 12px 16px;
            box-shadow: 0 1px 3px rgba(15,23,42,.05);
            display: grid; grid-template-columns: 1fr auto; gap: 10px; align-items: center;
        }
        .sched-card.planifie { border-left: 4px solid #2563eb; }
        .sched-card.encours { border-left: 4px solid #f59e0b; }
        .sched-card.paye { border-left: 4px solid #10b981; }
        .sched-card.echec { border-left: 4px solid #ef4444; }
        .sched-card.requires_3ds { border-left: 4px solid #a855f7; }

        .sched-supplier { font-weight: 800; color: #0f172a; font-size: 14px; }
        .sched-meta { font-size: 12px; color: #64748b; display: flex; gap: 12px; margin-top: 4px; flex-wrap: wrap; }
        .sched-amount { font-weight: 800; font-size: 16px; color: #0f172a; text-align: right; }
        .sched-status {
            display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px;
            font-weight: 700; text-transform: uppercase; letter-spacing: .04em;
        }
        .status-planifie { background: #dbeafe; color: #1d4ed8; }
        .status-encours { background: #fed7aa; color: #c2410c; }
        .status-paye { background: #d1fae5; color: #047857; }
        .status-echec { background: #fecaca; color: #b91c1c; }
        .status-requires_3ds { background: #ede9fe; color: #6d28d9; }
        .status-annule { background: #f1f5f9; color: #64748b; }

        .sched-actions { display: flex; gap: 6px; align-items: center; margin-top: 6px; }
        .btn-cancel {
            padding: 6px 10px; background: #fee2e2; color: #b91c1c;
            border: 1px solid #fecaca; border-radius: 6px;
            font-size: 11px; font-weight: 700; cursor: pointer;
        }
        .btn-cancel:hover { background: #fca5a5; color: #7f1d1d; }

        .empty-state {
            background: #fff; border-radius: 12px; padding: 40px 24px;
            text-align: center; color: #64748b; font-size: 14px;
        }
        .alert {
            padding: 12px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px;
        }
        .alert.success { background: rgba(16,185,129,.08); border: 1px solid rgba(16,185,129,.3); color: #047857; }
        .alert.error { background: rgba(239,68,68,.08); border: 1px solid rgba(239,68,68,.3); color: #b91c1c; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="autopay-page">

        <h1 class="page-title">📅 Calendrier des paiements automatiques</h1>

        <div class="page-tabs">
            <a href="wbfAutoPayAuthorizations.aspx">🔐 Autorisations</a>
            <a href="wbfAutoPaySchedule.aspx" class="active">📅 Calendrier (30 j)</a>
            <a href="wbfAutoPayHistory.aspx">📜 Historique</a>
        </div>

        <asp:Panel ID="pnlAlert" runat="server" Visible="false">
            <div class="alert success"><asp:Literal ID="litAlert" runat="server" /></div>
        </asp:Panel>
        <asp:Panel ID="pnlError" runat="server" Visible="false">
            <div class="alert error"><asp:Literal ID="litError" runat="server" /></div>
        </asp:Panel>

        <div class="filter-bar">
            <label>Status :
                <asp:DropDownList ID="ddlStatus" runat="server" AutoPostBack="true">
                    <asp:ListItem Value="" Text="Tous"></asp:ListItem>
                    <asp:ListItem Value="PLANIFIE" Text="Planifié"></asp:ListItem>
                    <asp:ListItem Value="EN_COURS" Text="En cours"></asp:ListItem>
                    <asp:ListItem Value="PAYE" Text="Payé"></asp:ListItem>
                    <asp:ListItem Value="ECHEC" Text="Échec"></asp:ListItem>
                    <asp:ListItem Value="REQUIRES_3DS" Text="Action requise (3DS)"></asp:ListItem>
                    <asp:ListItem Value="ANNULE" Text="Annulé"></asp:ListItem>
                </asp:DropDownList>
            </label>
            <label>Du :
                <asp:TextBox ID="tbFromDate" runat="server" TextMode="Date" />
            </label>
            <label>Au :
                <asp:TextBox ID="tbToDate" runat="server" TextMode="Date" />
            </label>
            <asp:Button ID="btnFilter" runat="server" Text="Filtrer" CssClass="btn-cancel"
                Style="background:#dbeafe; color:#1d4ed8; border-color:#bfdbfe;"
                CausesValidation="false" />
        </div>

        <asp:Literal ID="litCalendar" runat="server" />

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
            <p>Aucun paiement programmé sur cette plage.</p>
            <small>Modifiez les filtres ou élargissez la plage de dates.</small>
        </asp:Panel>

    </div>
</asp:Content>
