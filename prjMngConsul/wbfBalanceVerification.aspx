<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfBalanceVerification.aspx.vb" Inherits="MngConsul.wbfBalanceVerification" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Balance de vérification — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* ═══════════════════════════════════════
           TOOLBAR
        ═══════════════════════════════════════ */
        .report-toolbar {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px; flex-wrap: wrap; padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke); background: rgba(255,255,255,.75);
        }

        .report-title { font-weight: 900; font-size: 18px; }
        .report-sub { color: var(--mc-muted); font-size: 13px; margin-top: 4px; }

        .report-actions {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
        }

        .filter-period {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
            padding: 10px 16px; border-bottom: 1px solid var(--mc-stroke); font-size: 13px;
        }

        .filter-period label { font-weight: 700; color: var(--mc-muted); font-size: 12px; }

        .filter-period .riTextBox {
            padding: 8px 10px !important; border-radius: 10px !important;
            border: 1px solid var(--mc-stroke) !important; font-size: 13px; width: 130px !important;
        }

        /* ═══════════════════════════════════════
           RAPPORT
        ═══════════════════════════════════════ */
        .report-body { padding: 20px; }

        .report-header {
            text-align: center; margin-bottom: 28px; padding-bottom: 16px;
            border-bottom: 2px solid #0f172a;
        }

        .report-header h1 {
            font-size: 22px; font-weight: 900; margin: 0 0 4px; letter-spacing: -.02em;
        }

        .report-header .company-name {
            font-size: 16px; font-weight: 700; color: #334155; margin-bottom: 2px;
        }

        .report-header .report-date { font-size: 12px; color: #64748b; }

        /* ── Tableau ── */
        .bv-table {
            width: 100%; border-collapse: collapse; font-size: 13px;
        }

        .bv-table th {
            padding: 10px 14px; text-align: left; font-size: 12px;
            font-weight: 800; color: #fff; text-transform: uppercase;
            letter-spacing: .04em;
            background: linear-gradient(135deg, #1e293b, #334155);
        }

        .bv-table th.col-amount {
            text-align: right; width: 130px;
        }

        .bv-table td {
            padding: 7px 14px; border-bottom: 1px solid #f1f5f9; vertical-align: top;
        }

        .bv-table tr:hover td { background: #f8fafc; }

        /* Numéro de compte */
        .bv-table .col-num {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700; color: #334155; width: 80px;
        }

        /* Nom du compte */
        .bv-table .col-nom { font-weight: 500; }

        /* Classe */
        .bv-table .col-classe {
            font-size: 12px; color: #64748b;
        }

        /* Montants */
        .bv-table .col-debit,
        .bv-table .col-credit {
            text-align: right; width: 130px;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 600; white-space: nowrap;
        }

        .bv-table .col-debit { color: #0f172a; }
        .bv-table .col-credit { color: #0f172a; }

        .has-value { color: #0f172a !important; }
        .no-value { color: #cbd5e1 !important; }

        /* Ligne de section (classe parente) */
        .bv-section td {
            font-weight: 800; font-size: 13px; padding: 10px 14px;
            background: #f1f5f9; color: #334155;
            border-bottom: 1px solid #e2e8f0;
            border-top: 1px solid #e2e8f0;
        }

        /* Sous-total de section */
        .bv-sub-total td {
            font-weight: 700; font-size: 13px; padding: 8px 14px;
            border-top: 1px solid #cbd5e1;
            background: #fafbfc; color: #334155;
        }

        .bv-sub-total .col-debit,
        .bv-sub-total .col-credit {
            font-weight: 800;
        }

        /* Ligne du grand total */
        .bv-grand-total td {
            font-weight: 900; font-size: 15px; padding: 12px 14px;
            background: linear-gradient(135deg, #1e293b, #334155); color: #fff;
            border: none;
        }

        .bv-grand-total .col-debit,
        .bv-grand-total .col-credit {
            font-weight: 900; font-size: 16px; color: #fff;
        }

        /* Vérification d'équilibre */
        .bv-check td {
            font-weight: 700; font-size: 13px; padding: 12px 14px;
            text-align: center; border-top: 3px double #0f172a;
        }

        .bv-check-ok { color: #15803d; background: #f0fdf4; }
        .bv-check-err { color: #dc2626; background: #fef2f2; }

        /* Espaceur */
        .bv-spacer td { padding: 4px; border: none; }

        /* Stats en haut */
        .bv-stats {
            display: flex; gap: 20px; flex-wrap: wrap;
            margin-bottom: 20px;
        }

        .bv-stat {
            padding: 12px 18px; background: #fff;
            border: 1px solid #e2e8f0; border-radius: 12px;
            box-shadow: 0 2px 8px rgba(15,23,42,.04);
            min-width: 140px;
        }

        .bv-stat-label {
            font-size: 11px; font-weight: 700; color: #64748b;
            text-transform: uppercase; letter-spacing: .04em;
        }

        .bv-stat-value {
            font-size: 20px; font-weight: 900; color: #0f172a;
            margin-top: 4px; font-family: 'Consolas', 'Courier New', monospace;
        }

        .bv-stat-value.balanced { color: #15803d; }
        .bv-stat-value.unbalanced { color: #dc2626; }

        /* Options d'affichage */
        .bv-options {
            display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
            margin-bottom: 16px; font-size: 13px;
        }

        .bv-options label {
            display: flex; align-items: center; gap: 6px;
            font-weight: 600; color: #334155; cursor: pointer;
        }

        .bv-options input[type="checkbox"] {
            width: 16px; height: 16px; accent-color: #2563eb;
        }

        /* ═══════════════════════════════════════
           IMPRESSION
        ═══════════════════════════════════════ */
        @media print {
            .mc-app > *:not(.mc-shell),
            .mc-sidebar, .report-toolbar, .report-actions,
            .filter-period, .fab-add, .app-header, .topbar,
            .sidebar, .bv-options {
                display: none !important;
            }

            .mc-shell { display: block !important; padding: 0 !important; }

            .mc-maincol, .mc-card, .mc-mainwrap {
                background: #fff !important; border: none !important;
                box-shadow: none !important; border-radius: 0 !important;
                overflow: visible !important;
            }

            body {
                background: #fff !important; color: #000 !important;
                font-size: 10px !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .report-body { padding: 0 !important; }
            .report-header { border-bottom-color: #000 !important; }

            .bv-table th {
                background: #1e293b !important; color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bv-grand-total td {
                background: #1e293b !important; color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bv-section td, .bv-sub-total td {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .bv-table td { padding: 4px 10px; }
            .bv-stats { display: none; }

            @page { size: letter portrait; margin: 1.5cm; }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Toolbar --%>
    <div class="report-toolbar">
        <div>
            <div class="report-title">Balance de vérification</div>
            <div class="report-sub"><asp:Label ID="lblInfo" runat="server" /></div>
        </div>
        <div class="report-actions">
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <%-- Date --%>
    <div class="filter-period">
        <label>En date du :</label>
        <telerik:RadDatePicker ID="dpDate" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <asp:Button ID="btnGenerate" runat="server" CssClass="btn" Text="Générer" />
        <asp:CheckBox ID="chkHideZero" runat="server" Text="" AutoPostBack="true"
            OnCheckedChanged="chkHideZero_CheckedChanged" />
        <label for="<%= chkHideZero.ClientID %>" style="font-weight:600; color:#334155; cursor:pointer; font-size:13px;">
            Masquer les comptes à solde zéro
        </label>
    </div>

    <div class="report-body">

        <%-- En-tête --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>Balance de vérification</h1>
            <div class="report-date">Au <asp:Label ID="lblDate" runat="server" /></div>
        </div>

        <%-- Stats rapides --%>
        <div class="bv-stats">
            <div class="bv-stat">
                <div class="bv-stat-label">Total débits</div>
                <div class="bv-stat-value"><asp:Label ID="lblTotalDebit" runat="server" Text="—" /></div>
            </div>
            <div class="bv-stat">
                <div class="bv-stat-label">Total crédits</div>
                <div class="bv-stat-value"><asp:Label ID="lblTotalCredit" runat="server" Text="—" /></div>
            </div>
            <div class="bv-stat">
                <div class="bv-stat-label">Écart</div>
                <div class="bv-stat-value"><asp:Label ID="lblEcart" runat="server" Text="—" /></div>
            </div>
            <div class="bv-stat">
                <div class="bv-stat-label">Comptes</div>
                <div class="bv-stat-value"><asp:Label ID="lblNbComptes" runat="server" Text="—" /></div>
            </div>
        </div>

        <%-- Contenu --%>
        <asp:Literal ID="litReport" runat="server" />

    </div>

</asp:Content>
