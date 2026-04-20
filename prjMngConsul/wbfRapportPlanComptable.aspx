<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfRapportPlanComptable.aspx.vb" Inherits="MngConsul.wbfRapportPlanComptable" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Rapport — Plan comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* ═══════════════════════════════════════
           ÉCRAN — Mise en page normale
        ═══════════════════════════════════════ */

        .report-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .report-title { font-weight: 900; font-size: 18px; }
        .report-sub { color: var(--mc-muted); font-size: 13px; margin-top: 4px; }

        .report-actions {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }

        .report-body {
            padding: 20px;
        }

        /* En-tête du rapport (visible surtout à l'impression) */
        .report-header {
            text-align: center;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 2px solid #0f172a;
        }

        .report-header h1 {
            font-size: 22px;
            font-weight: 900;
            margin: 0 0 4px;
            letter-spacing: -.02em;
        }

        .report-header .company-name {
            font-size: 16px;
            font-weight: 700;
            color: #334155;
            margin-bottom: 2px;
        }

        .report-header .report-date {
            font-size: 12px;
            color: #64748b;
        }

        /* Classe principale (Niveau 1) */
        .classe-group {
            margin-bottom: 20px;
            break-inside: avoid;
        }

        .classe-header {
            display: grid;
            grid-template-columns: 1fr auto;
            gap: 12px;
            align-items: center;
            padding: 10px 14px;
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff;
            border-radius: 10px 10px 0 0;
            font-weight: 800;
            font-size: 14px;
        }

        .classe-header .plage {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            opacity: .7;
        }

        .classe-header .badge-etat {
            display: inline-block;
            padding: 2px 10px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 700;
        }

        .badge-bilan   { background: rgba(37,99,235,.3); color: #bfdbfe; }
        .badge-resultat { background: rgba(22,163,74,.3);  color: #bbf7d0; }

        /* Sous-classe (Niveau 2) */
        .sous-classe-header {
            display: grid;
            grid-template-columns: 90px 1fr auto;
            gap: 12px;
            align-items: center;
            padding: 8px 14px;
            background: #f1f5f9;
            border-left: 3px solid #94a3b8;
            font-weight: 700;
            font-size: 13px;
            color: #334155;
        }

        .sous-classe-header .sc-code {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            color: #64748b;
        }

        .sous-classe-header .sc-plage {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 11px;
            color: #94a3b8;
        }

        /* Tableau des comptes */
        .comptes-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        .comptes-table th {
            padding: 6px 14px;
            text-align: left;
            font-size: 11px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: .04em;
            background: #fafbfc;
            border-bottom: 1px solid #e2e8f0;
        }

        .comptes-table td {
            padding: 7px 14px;
            border-bottom: 1px solid #f1f5f9;
            vertical-align: top;
        }

        .comptes-table tr:last-child td {
            border-bottom: none;
        }

        .comptes-table tr:hover td {
            background: #f8fafc;
        }

        .comptes-table .col-numero {
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
            color: #334155;
            width: 80px;
        }

        .comptes-table .col-nom {
            font-weight: 600;
        }

        .comptes-table .col-desc {
            color: #94a3b8;
            font-size: 12px;
        }

        .comptes-table .col-type {
            width: 50px;
            text-align: center;
        }

        .comptes-table .col-sens {
            width: 50px;
            text-align: center;
        }

        .badge-sm {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 700;
        }

        .badge-d { background: #fef3c7; color: #92400e; }
        .badge-c { background: #e0e7ff; color: #3730a3; }

        .comptes-table .col-actif { width: 50px; text-align: center; }

        .dot-actif {
            display: inline-block;
            width: 8px; height: 8px;
            border-radius: 50%;
        }
        .dot-oui { background: #22c55e; }
        .dot-non { background: #ef4444; }

        /* Compteur du groupe */
        .classe-footer {
            padding: 6px 14px;
            font-size: 12px;
            color: #64748b;
            background: #fafbfc;
            border-top: 1px solid #e2e8f0;
            border-radius: 0 0 10px 10px;
            text-align: right;
            font-weight: 600;
        }

        /* Sommaire */
        .summary-card {
            margin-top: 24px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
        }

        .summary-card .summary-head {
            padding: 10px 14px;
            background: #f8fafc;
            font-weight: 800;
            font-size: 14px;
            border-bottom: 1px solid #e2e8f0;
        }

        .summary-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        .summary-table td {
            padding: 8px 14px;
            border-bottom: 1px solid #f1f5f9;
        }

        .summary-table tr:last-child td {
            border-bottom: none;
            font-weight: 800;
            border-top: 2px solid #0f172a;
        }

        .summary-table .num {
            text-align: right;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 700;
        }


        /* ═══════════════════════════════════════
           IMPRESSION — @media print
        ═══════════════════════════════════════ */
        @media print {

            /* Cacher tout ce qui n'est pas le rapport */
            .mc-app > *:not(.mc-shell),
            .mc-sidebar,
            .report-toolbar,
            .report-actions,
            .fab-add,
            .app-header,
            .topbar,
            .sidebar {
                display: none !important;
            }

            /* Reset du layout master */
            .mc-shell {
                display: block !important;
                padding: 0 !important;
            }

            .mc-maincol,
            .mc-card,
            .mc-mainwrap {
                background: #fff !important;
                border: none !important;
                box-shadow: none !important;
                border-radius: 0 !important;
                overflow: visible !important;
            }

            body {
                background: #fff !important;
                color: #000 !important;
                font-size: 11px !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .report-body {
                padding: 0 !important;
            }

            .report-header {
                border-bottom-color: #000 !important;
            }

            .classe-group {
                break-inside: avoid;
                page-break-inside: avoid;
                margin-bottom: 14px;
            }

            .classe-header {
                background: #1e293b !important;
                color: #fff !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
                border-radius: 0 !important;
            }

            .sous-classe-header {
                background: #f1f5f9 !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .comptes-table th {
                background: #fafbfc !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .comptes-table td { padding: 4px 10px; }

            .summary-card { break-inside: avoid; page-break-inside: avoid; }

            @page {
                size: letter portrait;
                margin: 1.5cm;
            }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Toolbar (masqué à l'impression) --%>
    <div class="report-toolbar">
        <div>
            <div class="report-title">Plan comptable</div>
            <div class="report-sub">
                <asp:Label ID="lblInfo" runat="server" />
            </div>
        </div>
        <div class="report-actions">
            <asp:Button ID="btnFilterAll" runat="server" CssClass="btn" Text="Tous" CausesValidation="false" />
            <asp:Button ID="btnFilterBilan" runat="server" CssClass="btn" Text="Bilan" CausesValidation="false" />
            <asp:Button ID="btnFilterResultat" runat="server" CssClass="btn" Text="Résultats" CausesValidation="false" />
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <div class="report-body">

        <%-- En-tête du rapport --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>Plan comptable</h1>
            <div class="report-date">Généré le <asp:Label ID="lblDate" runat="server" /></div>
        </div>

        <%-- Contenu généré dynamiquement --%>
        <asp:PlaceHolder ID="phReport" runat="server" />

        <%-- Sommaire --%>
        <div class="summary-card">
            <div class="summary-head">Sommaire</div>
            <asp:Literal ID="litSummary" runat="server" />
        </div>

    </div>

</asp:Content>
