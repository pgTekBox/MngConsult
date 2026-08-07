<%@ Page Title="Détail d'une exécution" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobExecution.aspx.vb"
    Inherits="MngConsul.wbfJobExecution" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .exec-page { max-width: 1200px; margin: 0 auto; padding: 12px; }
        .exec-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .exec-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .exec-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .exec-card h3 {
            margin: 0 0 12px 0; font-size: 15px; color: #0f172a;
            padding-bottom: 8px; border-bottom: 1px solid #f1f5f9;
        }

        /* Bandeau d'en-tête avec statut */
        .header-banner {
            display: flex; gap: 16px; align-items: center;
            padding: 16px 20px; border-radius: 8px;
            margin-bottom: 16px; border-left: 6px solid;
        }
        .header-banner.statut-success {
            background: #f0fdf4; border-color: #16a34a;
        }
        .header-banner.statut-danger {
            background: #fef2f2; border-color: #dc2626;
        }
        .header-banner.statut-warning {
            background: #fffbeb; border-color: #f59e0b;
        }
        .header-banner.statut-info {
            background: #eff6ff; border-color: #0ea5e9;
        }

        .header-banner .icon {
            font-size: 32px; line-height: 1;
        }
        .header-banner .body {
            flex: 1;
        }
        .header-banner .body .titre {
            font-size: 18px; font-weight: 600; color: #0f172a;
        }
        .header-banner .body .meta {
            font-size: 13px; color: #475569; margin-top: 4px;
        }
        .header-banner .actions {
            display: flex; gap: 8px;
        }

        /* Grille metadata 2 colonnes */
        .meta-grid {
            display: grid;
            grid-template-columns: 180px 1fr 180px 1fr;
            gap: 8px 20px;
            font-size: 13px;
        }
        .meta-grid .lbl { color: #64748b; }
        .meta-grid .val { color: #0f172a; font-weight: 500; }
        .meta-grid .val .badge-systeme {
            background: #f3e8ff; color: #6b21a8;
            font-size: 10px; font-weight: 600;
            padding: 1px 6px; border-radius: 3px;
            margin-left: 6px;
        }

        /* Bloc code (params, stack trace) */
        .code-block {
            background: #0f172a; color: #e2e8f0;
            padding: 12px 16px; border-radius: 6px;
            font-family: 'Consolas', 'Monaco', monospace; font-size: 12px;
            white-space: pre-wrap; word-break: break-word;
            overflow-x: auto;
            line-height: 1.5;
        }
        .code-block.error { background: #1e1b29; color: #fecaca; }

        /* Pills */
        .pill {
            display: inline-block; padding: 2px 10px; border-radius: 999px;
            font-size: 12px; font-weight: 600;
        }
        .pill-large { padding: 4px 14px; font-size: 14px; }
        .pill-success  { background: #dcfce7; color: #166534; }
        .pill-warning  { background: #fef3c7; color: #92400e; }
        .pill-danger   { background: #fee2e2; color: #991b1b; }
        .pill-info     { background: #dbeafe; color: #1e40af; }
        .pill-neutral  { background: #f1f5f9; color: #475569; }
        .pill-running  {
            background: #dbeafe; color: #1e40af;
            animation: pulse 1.5s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }

        /* Filtre logs */
        .logs-filter {
            display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
            margin-bottom: 12px;
        }
        .niveau-tab {
            padding: 6px 14px; border-radius: 6px;
            font-size: 12px; font-weight: 600;
            cursor: pointer; user-select: none;
            border: 1px solid transparent;
            display: inline-flex; gap: 8px; align-items: center;
        }
        .niveau-tab:hover { background: #f1f5f9; }
        .niveau-tab.active {
            background: #0ea5e9; color: #fff; border-color: #0ea5e9;
        }
        .niveau-tab .count {
            background: rgba(255,255,255,0.3);
            padding: 1px 8px; border-radius: 999px; font-size: 11px;
        }
        .niveau-tab.active .count {
            background: rgba(255,255,255,0.4);
        }
        .niveau-tab.tab-DEBUG  { color: #64748b; }
        .niveau-tab.tab-INFO   { color: #0f172a; }
        .niveau-tab.tab-WARN   { color: #92400e; }
        .niveau-tab.tab-ERROR  { color: #991b1b; }
        .niveau-tab.tab-DEBUG.active { background: #64748b; border-color: #64748b; }
        .niveau-tab.tab-INFO.active  { background: #0f172a; border-color: #0f172a; }
        .niveau-tab.tab-WARN.active  { background: #f59e0b; border-color: #f59e0b; }
        .niveau-tab.tab-ERROR.active { background: #dc2626; border-color: #dc2626; }

        /* Log entries */
        .log-list {
            font-family: 'Consolas', 'Monaco', monospace; font-size: 12px;
        }
        .log-entry {
            display: grid;
            grid-template-columns: 90px 70px 1fr;
            gap: 12px;
            padding: 6px 12px; border-bottom: 1px solid #f1f5f9;
            align-items: start;
        }
        .log-entry:hover { background: #fafbfc; }
        .log-entry .horodatage {
            color: #94a3b8; white-space: nowrap;
        }
        .log-entry .niveau-badge {
            font-size: 10px; font-weight: 700;
            padding: 1px 6px; border-radius: 3px;
            text-align: center; height: fit-content;
        }
        .log-entry .niveau-DEBUG { background: #f1f5f9; color: #64748b; }
        .log-entry .niveau-INFO  { background: #dbeafe; color: #1e40af; }
        .log-entry .niveau-WARN  { background: #fef3c7; color: #92400e; }
        .log-entry .niveau-ERROR { background: #fee2e2; color: #991b1b; }
        .log-entry .message {
            color: #1e293b; word-break: break-word;
        }
        .log-entry .detail-toggle {
            color: #0ea5e9; cursor: pointer; font-size: 11px;
            font-family: -apple-system, sans-serif;
        }
        .log-entry .detail-content {
            display: none;
            background: #f8fafc; padding: 8px 12px;
            margin-top: 4px; border-radius: 4px;
            font-size: 11px; color: #475569;
            white-space: pre-wrap; word-break: break-word;
        }
        .log-entry.show-detail .detail-content { display: block; }

        .empty-state {
            text-align: center; padding: 30px;
            color: #64748b; font-size: 13px;
        }

        /* Toolbar haute */
        .toolbar-top {
            display: flex; gap: 8px; margin-bottom: 16px;
            align-items: center;
        }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting  AjaxControlID="rblNiveau">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phLogs" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="exec-page">

        <!-- Toolbar haute -->
        <div class="toolbar-top">
            <telerik:RadButton ID="btnRetour" runat="server" Skin="Bootstrap"
                Text="← Retour à l'historique" AutoPostBack="false"
                OnClientClicked="retour" />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="exec-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- Bandeau d'en-tête -->
        <asp:PlaceHolder ID="phHeader" runat="server">
            <div id="divBanner" runat="server" class="header-banner">
                <div class="icon">
                    <asp:Literal ID="litIcon" runat="server" />
                </div>
                <div class="body">
                    <div class="titre">
                        <asp:Literal ID="litTitre" runat="server" />
                    </div>
                    <div class="meta">
                        <asp:Literal ID="litHeaderMeta" runat="server" />
                    </div>
                </div>
                <div class="actions">
                    <telerik:RadButton ID="btnAnnuler" runat="server" Skin="Bootstrap"
                        Text="Annuler l'exécution" Visible="false"
                        OnClick="btnAnnuler_Click"
                        OnClientClicking="confirmerAnnulation" />
                    <telerik:RadButton ID="btnRelancer" runat="server" Skin="Bootstrap"
                        Text="Réessayer" Icon-PrimaryIconCssClass="rbRefresh"
                        Visible="false"
                        OnClick="btnRelancer_Click"
                        OnClientClicking="confirmerRelance" />
                </div>
            </div>
        </asp:PlaceHolder>

        <!-- Section : Métadonnées de l'exécution -->
        <div class="exec-card">
            <h3><asp:Literal ID="litLoc01" runat="server" /></h3>
            <div class="meta-grid">
                <div class="lbl"><asp:Literal ID="litLoc02" runat="server" /></div>
                <div class="val">
                    <asp:Literal ID="litJobNom" runat="server" />
                </div>
                <div class="lbl"><asp:Literal ID="litLoc03" runat="server" /></div>
                <div class="val">
                    <code><asp:Literal ID="litJobCode" runat="server" /></code>
                </div>

                <div class="lbl"><asp:Literal ID="litLoc04" runat="server" /></div>
                <div class="val"><asp:Literal ID="litScheduleNom" runat="server" /></div>
                <div class="lbl"><asp:Literal ID="litLoc05" runat="server" /></div>
                <div class="val"><asp:Literal ID="litTrigger" runat="server" /></div>

                <div class="lbl"><asp:Literal ID="litLoc06" runat="server" /></div>
                <div class="val"><asp:Literal ID="litDemarre" runat="server" /></div>
                <div class="lbl"><asp:Literal ID="litLoc07" runat="server" /></div>
                <div class="val"><asp:Literal ID="litTermine" runat="server" /></div>

                <div class="lbl"><asp:Literal ID="litLoc08" runat="server" /></div>
                <div class="val"><asp:Literal ID="litDuree" runat="server" /></div>
                <div class="lbl"><asp:Literal ID="litLoc09" runat="server" /></div>
                <div class="val"><asp:Literal ID="litTentative" runat="server" /></div>

                <div class="lbl"><asp:Literal ID="litLoc10" runat="server" /></div>
                <div class="val"><asp:Literal ID="litWorker" runat="server" /></div>
                <div class="lbl"><asp:Literal ID="litLoc11" runat="server" /></div>
                <div class="val"><asp:Literal ID="litLignesTraitees" runat="server" /></div>

                <div class="lbl"><asp:Literal ID="litLoc12" runat="server" /></div>
                <div class="val">
                    <asp:Literal ID="litHandlerType" runat="server" /> :
                    <code><asp:Literal ID="litHandlerName" runat="server" /></code>
                </div>
                <div class="lbl"><asp:Literal ID="litLoc13" runat="server" /></div>
                <div class="val"><asp:Literal ID="litLanceePar" runat="server" /></div>
            </div>
        </div>

        <!-- Section : Message de résultat -->
        <asp:PlaceHolder ID="phMessage" runat="server" Visible="false">
            <div class="exec-card">
                <h3><asp:Literal ID="litLoc14" runat="server" /></h3>
                <div style="font-size: 14px; color: #0f172a; padding: 8px 0;">
                    <asp:Literal ID="litResultatMessage" runat="server" />
                </div>
            </div>
        </asp:PlaceHolder>

        <!-- Section : Stack trace / détail erreur -->
        <asp:PlaceHolder ID="phDetail" runat="server" Visible="false">
            <div class="exec-card">
                <h3><asp:Literal ID="litLoc15" runat="server" /></h3>
                <div id="divDetailBlock" runat="server" class="code-block">
                    <asp:Literal ID="litResultatDetail" runat="server" />
                </div>
            </div>
        </asp:PlaceHolder>

        <!-- Section : Paramètres utilisés -->
        <asp:PlaceHolder ID="phParams" runat="server" Visible="false">
            <div class="exec-card">
                <h3><asp:Literal ID="litLoc16" runat="server" /></h3>
                <div class="code-block"><asp:Literal ID="litParamsUtilises" runat="server" /></div>
            </div>
        </asp:PlaceHolder>

        <!-- Section : Logs -->
        <div class="exec-card">
            <h3><asp:Literal ID="litLoc17" runat="server" /></h3>

            <div class="logs-filter">
                <asp:Literal ID="litFilterTabs" runat="server" />

                <asp:RadioButtonList ID="rblNiveau" runat="server" 
                    AutoPostBack="true"
                    OnSelectedIndexChanged="rblNiveau_Changed"
                    Style="display: none;" ClientIDMode="Static">
                    <asp:ListItem Text="Tous" Value="" Selected="True" />
                    <asp:ListItem Text="DEBUG" Value="DEBUG" />
                    <asp:ListItem Text="INFO" Value="INFO" />
                    <asp:ListItem Text="WARN" Value="WARN" />
                    <asp:ListItem Text="ERROR" Value="ERROR" />
                </asp:RadioButtonList>

                <asp:HiddenField ID="hfNiveauSelected"   runat="server" Value="" ClientIDMode="Static" />
            </div>

            <asp:PlaceHolder ID="phLogs" runat="server">
                <asp:PlaceHolder ID="phLogsEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        <asp:Literal ID="litLoc18" runat="server" />
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phLogsList" runat="server" Visible="false">
                    <div class="log-list">
                        <asp:Repeater ID="rpLogs" runat="server"
                            OnItemDataBound="rpLogs_ItemDataBound">
                            <ItemTemplate>
                                <div class="log-entry" id='log-<%# Eval("Id") %>'>
                                    <div class="horodatage">
                                        <%# Convert.ToDateTime(Eval("Horodatage")).ToString("HH:mm:ss.fff") %>
                                    </div>
                                    <div>
                                        <span class='niveau-badge niveau-<%# Eval("Niveau") %>'>
                                            <%# Eval("Niveau") %>
                                        </span>
                                    </div>
                                    <div>
                                        <div class="message">
                                            <%# Server.HtmlEncode(Eval("Message").ToString()) %>
                                            <asp:Literal ID="litToggleDetail" runat="server" />
                                        </div>
                                        <asp:Literal ID="litDetailBlock" runat="server" />
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </asp:PlaceHolder>
            </asp:PlaceHolder>
        </div>

    </div>

    <!-- Champ caché pour exposer JobIdContexte au JavaScript -->
    <asp:HiddenField ID="hfJobIdCtx"  runat="server" Value="0" ClientIDMode="Static" />

    <telerik:RadCodeBlock runat="server">
    <script type="text/javascript">
        var EXE_I18N = {
            confirmAnnul: "<%= T("Marquer cette exécution comme ANNULÉE ?\n\nNote : ce marqueur n'arrête pas physiquement le worker — c'est juste un statut.", "Mark this execution as CANCELLED?\n\nNote: this marker does not physically stop the worker — it is only a status.", "¿Marcar esta ejecución como CANCELADA?\n\nNota: este marcador no detiene físicamente el worker, es solo un estado.") %>",
            confirmRelance: "<%= T("Relancer cette exécution avec les mêmes paramètres ?\n\nUne nouvelle exécution sera créée en EN_COURS et le worker la prendra en charge.", "Retry this execution with the same parameters?\n\nA new execution will be created as RUNNING and the worker will pick it up.", "¿Reintentar esta ejecución con los mismos parámetros?\n\nSe creará una nueva ejecución como EN CURSO y el worker se encargará de ella.") %>"
        };

        function retour(sender, args) {
            // Si on est arrivé via QueryString JobId, retour vers monitoring filtré
            // Sinon retour vers monitoring général
            var hf = document.getElementById('hfJobIdCtx');
            var jobId = hf ? hf.value : "0";
            if (jobId && jobId !== "0") {
                window.location.href = "wbfJobMonitoring.aspx?JobId=" + jobId;
            } else {
                window.location.href = "wbfJobMonitoring.aspx";
            }
        }
        function confirmerAnnulation(sender, args) {
            args.set_cancel(!confirm(EXE_I18N.confirmAnnul));
        }
        function confirmerRelance(sender, args) {
            args.set_cancel(!confirm(EXE_I18N.confirmRelance));
        }

        // Toggle des détails de log
        function toggleLogDetail(logId) {
            var entry = document.getElementById('log-' + logId);
            if (entry) entry.classList.toggle('show-detail');
        }

        // Niveau filter clicks (les tabs sont des liens, on bascule le RadioButtonList)
        function selectNiveau(niveau) {
            var hf = document.getElementById('hfNiveauSelected');
            hf.value = niveau;
            // Trigger postback en cliquant le radio correspondant
            var rbl = document.querySelectorAll('rblNiveau input');
            for (var i = 0; i < rbl.length; i++) {
                if (rbl[i].value === niveau) {
                    rbl[i].checked = true;
                    rbl[i].dispatchEvent(new Event('change', { bubbles: true }));
                    return;
                }
            }
        }
    </script>
    </telerik:RadCodeBlock>

</asp:Content>
