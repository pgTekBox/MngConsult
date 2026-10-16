<%@ Page Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfAutoPaySchedule.aspx.vb" Inherits="MngConsul.wbfAutoPaySchedule" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Calendrier auto-paiement — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .autopay-page { max-width: 1100px; margin: 0 auto; padding: 16px; }
        .page-title { font-size: 22px; font-weight: 800; margin: 0 0 14px 0; display: flex; gap: 10px; align-items: center; }
        .page-tabs { display: flex; gap: 6px; margin-bottom: 18px; border-bottom: 1px solid #D5DDE8; }
        .page-tabs a {
            padding: 10px 16px; text-decoration: none; color: #44536E;
            font-weight: 700; font-size: 13px; border-bottom: 3px solid transparent;
        }
        .page-tabs a:hover { color: #1B4F9C; }
        .page-tabs a.active { color: #1B4F9C; border-bottom-color: #1B4F9C; }

        .filter-bar {
            display: flex; gap: 12px; align-items: center; margin-bottom: 14px;
            flex-wrap: wrap; background: #fff; padding: 12px 16px; border-radius: 12px;
        }
        .filter-bar label { font-size: 12px; font-weight: 700; color: #44536E; }
        .filter-bar select, .filter-bar input[type="date"] {
            padding: 6px 10px; border: 1px solid #D5DDE8; border-radius: 8px;
            font-family: inherit; font-size: 13px;
        }

        .day-group {
            margin-bottom: 18px;
        }
        .day-header {
            display: flex; justify-content: space-between; align-items: center;
            padding: 8px 12px;
            background: linear-gradient(135deg, #1B4F9C, #06b6d4);
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
        .sched-card.planifie { border-left: 4px solid #1B4F9C; }
        .sched-card.encours { border-left: 4px solid #f59e0b; }
        .sched-card.paye { border-left: 4px solid #10b981; }
        .sched-card.echec { border-left: 4px solid #ef4444; }
        .sched-card.requires_3ds { border-left: 4px solid #a855f7; }

        .sched-supplier { font-weight: 800; color: #0E1F3D; font-size: 14px; }
        .sched-meta { font-size: 12px; color: #44536E; display: flex; gap: 12px; margin-top: 4px; flex-wrap: wrap; }
        .sched-amount { font-weight: 800; font-size: 16px; color: #0E1F3D; text-align: right; }
        .sched-status {
            display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 11px;
            font-weight: 700; text-transform: uppercase; letter-spacing: .04em;
        }
        .status-planifie { background: #D5DDE8; color: #143A73; }
        .status-encours { background: #fed7aa; color: #c2410c; }
        .status-paye { background: #d1fae5; color: #047857; }
        .status-echec { background: #fecaca; color: #b91c1c; }
        .status-requires_3ds { background: #ede9fe; color: #6d28d9; }
        .status-annule { background: #f1f5f9; color: #44536E; }

        .sched-actions { display: flex; gap: 6px; align-items: center; margin-top: 6px; }
        .btn-cancel {
            padding: 6px 10px; background: #fee2e2; color: #b91c1c;
            border: 1px solid #fecaca; border-radius: 6px;
            font-size: 11px; font-weight: 700; cursor: pointer;
        }
        .btn-cancel:hover { background: #fca5a5; color: #7f1d1d; }

        .empty-state {
            background: #fff; border-radius: 12px; padding: 40px 24px;
            text-align: center; color: #44536E; font-size: 14px;
        }
        .alert {
            padding: 12px 14px; border-radius: 10px; font-size: 13px; margin-bottom: 14px;
        }
        .alert.success { background: rgba(16,185,129,.08); border: 1px solid rgba(16,185,129,.3); color: #047857; }
        .alert.error { background: rgba(239,68,68,.08); border: 1px solid rgba(239,68,68,.3); color: #b91c1c; }
        /* ── La signature du gabarit « Portail du client » : le titre pose sur le fond,
           les trois pastilles de navigation, les compteurs, les filtres et les cartes
           en blanc arrondi. ── */
        .autopay-page { max-width: none; margin: 0; padding: 0; }
        .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px; }
        .fc-tete .txt { flex: 1 1 260px; }
        .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em; }
        .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D; }
        .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E; }
        .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px; }
        .fc-btn, input.fc-btn { min-height: 44px; padding: 0 16px !important; border: 1px solid #AEBBCD !important; border-radius: 999px !important; background: #fff !important; color: #0E1F3D !important; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer; }
        .fc-btn:hover, input.fc-btn:hover { background: #F2F5F9 !important; }
        .page-tabs { display: flex; flex-wrap: wrap; gap: 4px; padding: 4px; background: #E8EDF5; border-radius: 999px; border: 0; margin-bottom: 16px; width: max-content; max-width: 100%; }
        .page-tabs a { border: 0; border-radius: 999px; min-height: 36px; padding: 0 14px; display: inline-flex; align-items: center; gap: 6px; color: #0E1F3D; font-size: 14px; font-weight: 700; }
        .page-tabs a:hover { background: rgba(255,255,255,.6); color: #0E1F3D; }
        .page-tabs a.active { background: #fff; color: #0E1F3D; box-shadow: 0 1px 2px rgba(14,31,61,.12); border: 0; }
        .stats-row { gap: 12px; margin-bottom: 16px; }
        .stat-card { border-radius: 22px; box-shadow: none; padding: 14px 16px; }
        .stat-card .stat-label { text-transform: none; letter-spacing: 0; font-size: 14px; font-weight: 700; color: #44536E; }
        .stat-card .stat-value { font-size: 24px; font-weight: 800; color: #0E1F3D; }
        .stat-card.green .stat-value { color: #0F5A3A; }
        .stat-card.amber .stat-value { color: #7A5200; }
        .stat-card.red .stat-value { color: #A3261C; }
        .filter-bar { padding: 16px 18px; border-radius: 24px; background: #fff; margin-bottom: 16px; gap: 10px 16px; align-items: center; }
        .filter-bar label { font-size: 13px; font-weight: 800; color: #5B6B86; display: inline-flex; align-items: center; gap: 8px; }
        .filter-bar select, .filter-bar input[type=date] { min-height: 40px; padding: 0 12px; border: 1px solid #AEBBCD; border-radius: 12px; background: #fff; font: inherit; font-size: 14px; font-weight: 600; color: #0E1F3D; }
        .filter-bar input[type=submit], .filter-bar input[type=button] { min-height: 40px; padding: 0 18px !important; border-radius: 999px !important; border: 1px solid #1B4F9C !important; background: #1B4F9C !important; color: #fff !important; font-weight: 800; font-size: 14px; font-family: inherit; cursor: pointer; }
        .filter-bar input[type=submit]:hover, .filter-bar input[type=button]:hover { background: #143A73 !important; }
        .auth-card { border-radius: 20px; box-shadow: none; border-left-width: 5px; border-left-color: #43B47A; padding: 16px 20px; }
        .auth-card.revoked { border-left-color: #AEBBCD; }
        .auth-meta { font-size: 13px; color: #44536E; }
        .auth-stats { font-size: 13px; }
        .btn-revoke, input.btn-revoke { min-height: 40px; padding: 0 14px; border-radius: 999px; background: #fff; color: #A3261C; border: 1px solid #F1B9B4; font-size: 14px; font-weight: 800; font-family: inherit; }
        .btn-revoke:hover, input.btn-revoke:hover { background: #FDECEA; color: #A3261C; }
        .empty-state { border-radius: 24px; font-weight: 700; }
        .alert { border-radius: 16px; font-size: 14px; font-weight: 700; }
        .alert.success { background: #E3F3EA; border: 0; color: #0F5A3A; }
        .alert.error { background: #FDECEA; border: 0; color: #A3261C; }
        .history-table { border-radius: 24px; background: #fff; padding: 6px 12px 12px; overflow-x: auto; }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="autopay-page">

        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre, le sous-titre. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique">Administration</div>
                <h1>Calendrier des paiements automatiques</h1>
                <p>Les paiements programmés des 30 prochains jours, jour par jour.</p>
            </div>
        </div>

        <div class="page-tabs">
            <a href="wbfAutoPayAuthorizations.aspx"><i class="ic ic-lock" aria-hidden="true"></i> Autorisations</a>
            <a href="wbfAutoPaySchedule.aspx" class="active"><i class="ic ic-calendar" aria-hidden="true"></i> Calendrier (30 j)</a>
            <a href="wbfAutoPayHistory.aspx"><i class="ic ic-scroll" aria-hidden="true"></i> Historique</a>
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
                Style="background:#D5DDE8; color:#143A73; border-color:#bfdbfe;"
                CausesValidation="false" />
        </div>

        <asp:Literal ID="litCalendar" runat="server" />

        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty-state">
            <p>Aucun paiement programmé sur cette plage.</p>
            <small>Modifiez les filtres ou élargissez la plage de dates.</small>
        </asp:Panel>

    </div>
</asp:Content>
