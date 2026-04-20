<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfFluxTresorerie.aspx.vb" Inherits="MngConsul.wbfFluxTresorerie" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Flux de trésorerie — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* ═══════════════════════════════════════
           TOOLBAR
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
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
        }

        .filter-period {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
            padding: 10px 16px; border-bottom: 1px solid var(--mc-stroke); font-size: 13px;
        }

        .filter-period label {
            font-weight: 700; color: var(--mc-muted); font-size: 12px;
        }

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
        .ft-table {
            width: 100%; border-collapse: collapse; font-size: 14px;
        }

        .ft-table td { padding: 7px 14px; vertical-align: top; }

        /* Section (Exploitation, Investissement, Financement) */
        .ft-section {
            background: linear-gradient(135deg, #1e293b, #334155);
            color: #fff; font-weight: 800; font-size: 14px;
        }

        .ft-section td { padding: 12px 14px; }

        .ft-section-icon {
            display: inline-block; width: 24px; height: 24px;
            border-radius: 6px; text-align: center; line-height: 24px;
            font-size: 13px; margin-right: 8px;
        }

        .ico-exploit { background: rgba(37,99,235,.3); }
        .ico-invest  { background: rgba(245,158,11,.3); }
        .ico-finance { background: rgba(16,185,129,.3); }

        /* Sous-section */
        .ft-sub-header td {
            font-weight: 700; color: #334155; background: #f1f5f9;
            font-size: 13px; padding: 8px 14px 8px 28px;
            border-bottom: 1px solid #e2e8f0;
        }

        /* Ligne de détail */
        .ft-line td {
            border-bottom: 1px solid #f1f5f9; font-size: 13px;
        }

        .ft-line:hover td { background: #f8fafc; }

        .ft-line .item-name { padding-left: 44px; }

        .ft-line .item-num {
            font-family: 'Consolas', 'Courier New', monospace;
            color: #64748b; font-size: 12px; width: 70px; padding-left: 44px;
        }

        .ft-amount {
            text-align: right;
            font-family: 'Consolas', 'Courier New', monospace;
            font-weight: 600; width: 140px; white-space: nowrap;
        }

        /* Sous-total */
        .ft-sub-total td {
            font-weight: 700; font-size: 13px; padding: 6px 14px 6px 28px;
            border-top: 1px solid #cbd5e1; border-bottom: 1px solid #e2e8f0;
            color: #334155;
        }

        .ft-sub-total .ft-amount { font-weight: 800; }

        /* Total de section */
        .ft-total td {
            font-weight: 800; font-size: 14px; padding: 10px 14px;
            border-top: 2px solid #334155; border-bottom: 2px solid #334155;
            background: #f8fafc; color: #0f172a;
        }

        .ft-total .ft-amount { font-weight: 900; font-size: 15px; }

        /* Ligne de calcul */
        .ft-calc td {
            font-weight: 800; font-size: 14px; padding: 12px 14px;
            background: linear-gradient(135deg, rgba(37,99,235,.06), rgba(6,182,212,.04));
            border-top: 1px solid rgba(37,99,235,.15);
            border-bottom: 1px solid rgba(37,99,235,.15);
            color: #1e40af;
        }

        .ft-calc .ft-amount { font-weight: 900; font-size: 15px; color: #1e40af; }

        /* Grand total */
        .ft-grand td {
            font-weight: 900; font-size: 16px; padding: 14px;
            background: linear-gradient(135deg, #1e293b, #334155); color: #fff;
        }

        .ft-grand .ft-amount { font-size: 18px; font-weight: 900; }

        /* Encaisse début / fin */
        .ft-encaisse td {
            font-weight: 700; font-size: 14px; padding: 10px 14px;
            background: #f0fdf4; border-bottom: 1px solid #bbf7d0; color: #15803d;
        }

        .ft-encaisse .ft-amount { font-weight: 800; font-size: 15px; color: #15803d; }

        .ft-encaisse-fin td {
            font-weight: 900; font-size: 16px; padding: 14px;
            background: #065f46; color: #fff;
        }

        .ft-encaisse-fin .ft-amount { font-size: 18px; font-weight: 900; }

        /* Positif / Négatif */
        .amt-positive { color: #15803d; }
        .amt-negative { color: #dc2626; }
        .amt-zero { color: #94a3b8; }

        .ft-spacer td { padding: 8px; border: none; }

        /* Note explicative */
        .ft-note {
            margin-top: 20px; padding: 14px; background: #f8fafc;
            border: 1px solid #e2e8f0; border-radius: 10px;
            font-size: 12px; color: #64748b; line-height: 1.6;
        }

        .ft-note strong { color: #334155; }

        /* ═══════════════════════════════════════
           IMPRESSION
        ═══════════════════════════════════════ */
        @media print {
            .mc-app > *:not(.mc-shell),
            .mc-sidebar, .report-toolbar, .report-actions,
            .filter-period, .fab-add, .app-header, .topbar, .sidebar {
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
                font-size: 11px !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .report-body { padding: 0 !important; }
            .report-header { border-bottom-color: #000 !important; }

            .ft-section, .ft-grand, .ft-encaisse-fin {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .ft-sub-header td, .ft-encaisse td, .ft-calc td {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }

            .ft-table td { padding: 4px 10px; }
            .ft-note { break-inside: avoid; page-break-inside: avoid; }

            @page { size: letter portrait; margin: 1.5cm; }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Toolbar --%>
    <div class="report-toolbar">
        <div>
            <div class="report-title">État des flux de trésorerie</div>
            <div class="report-sub"><asp:Label ID="lblInfo" runat="server" /></div>
        </div>
        <div class="report-actions">
            <button type="button" class="btn" onclick="window.print(); return false;"
                style="border-color:rgba(37,99,235,.4); background:rgba(37,99,235,.08); color:#1d4ed8;">
                🖨 Imprimer / PDF
            </button>
        </div>
    </div>

    <%-- Période --%>
    <div class="filter-period">
        <label>Du :</label>
        <telerik:RadDatePicker ID="dpDateDebut" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <label>Au :</label>
        <telerik:RadDatePicker ID="dpDateFin" runat="server" RenderMode="Lightweight"
            Width="150px" DateInput-DateFormat="yyyy-MM-dd" />
        <asp:Button ID="btnGenerate" runat="server" CssClass="btn" Text="Générer" />
    </div>

    <div class="report-body">

        <%-- En-tête --%>
        <div class="report-header">
            <div class="company-name"><asp:Label ID="lblCompanyName" runat="server" Text="Mon entreprise" /></div>
            <h1>État des flux de trésorerie</h1>
            <div class="report-date">
                Période du <asp:Label ID="lblPeriodeDebut" runat="server" />
                au <asp:Label ID="lblPeriodeFin" runat="server" />
            </div>
        </div>

        <%-- Contenu --%>
        <asp:Literal ID="litReport" runat="server" />

        <%-- Note méthodologique --%>
        <div class="ft-note">
            <strong>Note :</strong> Cet état des flux de trésorerie est préparé selon la méthode indirecte.
            Le bénéfice net est ajusté pour les éléments sans effet sur la trésorerie (amortissement, créances douteuses)
            et pour les variations des éléments du fonds de roulement (comptes clients, stocks, fournisseurs, etc.).
        </div>

    </div>

</asp:Content>
