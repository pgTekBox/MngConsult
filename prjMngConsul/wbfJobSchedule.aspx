<%@ Page Title="Édition d'un schedule" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobSchedule.aspx.vb"
    Inherits="MngConsul.wbfJobSchedule" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .sched-page { max-width: 1000px; margin: 0 auto; padding: 12px; }
        .sched-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .sched-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .sched-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .sched-card h3 {
            margin: 0 0 16px 0; font-size: 15px; color: #0f172a;
            padding-bottom: 8px; border-bottom: 1px solid #f1f5f9;
        }

        /* Form layout */
        .form-row {
            display: grid;
            grid-template-columns: 200px 1fr;
            gap: 12px 16px;
            align-items: center;
            margin-bottom: 12px;
        }
        .form-row > label {
            font-size: 13px; color: #475569;
            font-weight: 500;
        }
        .form-row > label.required::after {
            content: " *"; color: #dc2626;
        }
        .form-row .hint {
            font-size: 11px; color: #94a3b8; margin-top: 4px;
            font-style: italic;
        }

        /* Aperçu de la prochaine exécution */
        .preview-box {
            background: #f0f9ff;
            border: 1px solid #bae6fd;
            border-left: 4px solid #0ea5e9;
            border-radius: 8px;
            padding: 14px 16px;
            margin-bottom: 16px;
        }
        .preview-box.error {
            background: #fef2f2;
            border-color: #fecaca;
            border-left-color: #dc2626;
        }
        .preview-box .lbl {
            font-size: 11px; color: #0c4a6e;
            text-transform: uppercase; letter-spacing: 0.5px;
            font-weight: 600; margin-bottom: 4px;
        }
        .preview-box.error .lbl { color: #991b1b; }
        .preview-box .val {
            font-size: 18px; font-weight: 600; color: #0f172a;
            font-variant-numeric: tabular-nums;
        }
        .preview-box .meta {
            font-size: 11px; color: #475569; margin-top: 4px;
        }

        /* Cases à cocher des jours de la semaine — CSS pur */
        .jours-semaine {
            display: flex; gap: 8px; flex-wrap: wrap;
        }
        /* Cacher les checkboxes natives hors écran */
        .jour-cb {
            position: absolute;
            left: -9999px;
            width: 1px;
            height: 1px;
            opacity: 0;
        }
        .jour-pill {
            display: inline-block; padding: 6px 14px;
            border-radius: 999px; cursor: pointer;
            font-size: 12px; font-weight: 600;
            border: 1px solid #cbd5e1;
            color: #475569; background: #fff;
            user-select: none;
            transition: all 0.15s;
            margin: 0;
        }
        .jour-pill:hover { border-color: #94a3b8; }
        /* État sélectionné via CSS pur grâce au sélecteur :checked + label */
        .jour-cb:checked + .jour-pill {
            background: #0ea5e9; border-color: #0ea5e9; color: #fff;
        }
        /* Focus visible pour l'accessibilité (Tab + Espace) */
        .jour-cb:focus + .jour-pill {
            box-shadow: 0 0 0 3px rgba(14,165,233,0.25);
        }

        /* Aide CRON */
        .cron-help {
            background: #f8fafc; border-left: 3px solid #cbd5e1;
            padding: 8px 12px; font-size: 11px; color: #64748b;
            margin-top: 6px; border-radius: 4px;
        }
        .cron-help code {
            background: #fff; padding: 1px 4px; border-radius: 3px;
            border: 1px solid #e2e8f0; font-family: 'Consolas', 'Monaco', monospace;
        }
        .cron-help table { margin-top: 6px; font-size: 11px; }
        .cron-help table td { padding: 2px 8px 2px 0; }

        /* Action bar */
        .action-bar {
            display: flex; gap: 12px; justify-content: space-between;
            padding-top: 16px; border-top: 1px solid #e2e8f0; margin-top: 16px;
            align-items: center;
        }
        .action-bar .left, .action-bar .right { display: flex; gap: 8px; }

        .badge-job {
            background: #f3e8ff; color: #6b21a8;
            font-size: 11px; font-weight: 600;
            padding: 3px 10px; border-radius: 4px;
            display: inline-block; margin-bottom: 8px;
        }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="ddlScheduleType">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phChamps" />
                    <telerik:AjaxUpdatedControl ControlID="phPreview" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="btnApercu">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phPreview" LoadingPanelID="ralp" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="sched-page">

        <h2>
            <asp:Literal ID="litTitre" runat="server" Text="Nouveau schedule" />
        </h2>
        <div class="subtitle">
            <asp:Literal ID="litBadgeJob" runat="server" />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="sched-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- Aperçu de la prochaine exécution -->
        <asp:PlaceHolder ID="phPreview" runat="server">
            <div id="divPreview" runat="server" class="preview-box">
                <div class="lbl">Prochaine exécution prévue</div>
                <div class="val">
                    <asp:Literal ID="litProchaineExec" runat="server" Text="—" />
                </div>
                <div class="meta">
                    <asp:Literal ID="litProchaineExecMeta" runat="server" />
                </div>
            </div>
        </asp:PlaceHolder>

        <!-- Section 1 : Informations de base -->
        <div class="sched-card">
            <h3>Informations de base</h3>

            <div class="form-row">
                <label class="required">Nom du schedule</label>
                <div>
                    <telerik:RadTextBox ID="txtNom" runat="server" Skin="Bootstrap"
                        Width="100%" MaxLength="200"
                        EmptyMessage="Ex: Quotidien 7h, Fin de mois, ..." />
                </div>
            </div>

            <div class="form-row">
                <label class="required">Type de planification</label>
                <div>
                    <telerik:RadComboBox ID="ddlScheduleType" runat="server" Skin="Bootstrap"
                        Width="280px" AutoPostBack="true"
                        OnSelectedIndexChanged="ddlScheduleType_Changed">
                        <Items>
                            <telerik:RadComboBoxItem Text="Toutes les N minutes (INTERVAL)" Value="INTERVAL" />
                            <telerik:RadComboBoxItem Text="Quotidien (DAILY)" Value="DAILY" Selected="true" />
                            <telerik:RadComboBoxItem Text="Hebdomadaire (WEEKLY)" Value="WEEKLY" />
                            <telerik:RadComboBoxItem Text="Mensuel / Trimestriel / Semestriel / Annuel (MONTHLY)" Value="MONTHLY" />
                            <telerik:RadComboBoxItem Text="Expression CRON (avancé)" Value="CRON" />
                            <telerik:RadComboBoxItem Text="Une seule fois (ONCE)" Value="ONCE" />
                        </Items>
                    </telerik:RadComboBox>
                </div>
            </div>

            <!-- Champs dynamiques selon le type -->
            <asp:PlaceHolder ID="phChamps" runat="server">

                <!-- INTERVAL -->
                <asp:Panel ID="pnlInterval" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Toutes les ... minutes</label>
                        <div>
                            <telerik:RadNumericTextBox ID="txtIntervalMinutes" runat="server" Skin="Bootstrap"
                                Width="120px" MinValue="1" MaxValue="10080" Value="60"
                                NumberFormat-DecimalDigits="0" />
                            <div class="hint">Ex: 30 = toutes les 30 min, 1440 = 1 fois par jour.</div>
                        </div>
                    </div>
                </asp:Panel>

                <!-- DAILY -->
                <asp:Panel ID="pnlDaily" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Heure d'exécution</label>
                        <div>
                            <telerik:RadTimePicker ID="dpHeureDaily" runat="server" Skin="Bootstrap"
                                Width="120px">
                                <TimeView Interval="00:30:00" Skin="Bootstrap" />
                                <TimePopupButton CssClass="rcCalPopup" />
                            </telerik:RadTimePicker>
                        </div>
                    </div>
                </asp:Panel>

                <!-- WEEKLY -->
                <asp:Panel ID="pnlWeekly" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Heure d'exécution</label>
                        <div>
                            <telerik:RadTimePicker ID="dpHeureWeekly" runat="server" Skin="Bootstrap"
                                Width="120px">
                                <TimeView Interval="00:30:00" Skin="Bootstrap" />
                            </telerik:RadTimePicker>
                        </div>
                    </div>
                    <div class="form-row">
                        <label class="required">Jours de la semaine</label>
                        <div>
                            <div class="jours-semaine" id="joursSemaineGroup">
                                <input type="checkbox" ClientIDMode="Static"  id="cbLun" runat="server" value="1" class="jour-cb" />
                                <label class="jour-pill" for="cbLun">Lun</label>

                                <input type="checkbox" ClientIDMode="Static"  id="cbMar" runat="server" value="2" class="jour-cb" />
                                <label class="jour-pill" for="cbMar">Mar</label>

                                <input type="checkbox" ClientIDMode="Static" id="cbMer" runat="server" value="3" class="jour-cb" />
                                <label class="jour-pill" for="cbMer">Mer</label>

                                <input type="checkbox" ClientIDMode="Static" id="cbJeu" runat="server" value="4" class="jour-cb" />
                                <label class="jour-pill" for="cbJeu">Jeu</label>

                                <input type="checkbox" ClientIDMode="Static" id="cbVen" runat="server" value="5" class="jour-cb" />
                                <label class="jour-pill" for="cbVen">Ven</label>

                                <input type="checkbox" ClientIDMode="Static" id="cbSam" runat="server" value="6" class="jour-cb" />
                                <label class="jour-pill" for="cbSam">Sam</label>

                                <input type="checkbox" ClientIDMode="Static" id="cbDim" runat="server" value="7" class="jour-cb" />
                                <label class="jour-pill" for="cbDim">Dim</label>
                            </div>
                            <div class="hint" style="margin-top: 8px;">
                                Cliquez sur les pilules pour sélectionner les jours actifs.
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <!-- MONTHLY -->
                <asp:Panel ID="pnlMonthly" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Périodicité</label>
                        <div>
                            <telerik:RadComboBox ID="ddlIntervalleMois" runat="server" Skin="Bootstrap"
                                Width="220px">
                                <Items>
                                    <telerik:RadComboBoxItem Text="Tous les mois" Value="1" Selected="true" />
                                    <telerik:RadComboBoxItem Text="Tous les 3 mois (trimestriel)" Value="3" />
                                    <telerik:RadComboBoxItem Text="Tous les 6 mois (semestriel)" Value="6" />
                                    <telerik:RadComboBoxItem Text="Tous les 12 mois (annuel)" Value="12" />
                                </Items>
                            </telerik:RadComboBox>
                            <div class="hint">
                                Ex : trimestriel = remise des taxes ; annuel = T4 ou rapport fin d'exercice.
                            </div>
                        </div>
                    </div>
                    <div class="form-row">
                        <label class="required">Heure d'exécution</label>
                        <div>
                            <telerik:RadTimePicker ID="dpHeureMonthly" runat="server" Skin="Bootstrap"
                                Width="120px">
                                <TimeView Interval="00:30:00" Skin="Bootstrap" />
                            </telerik:RadTimePicker>
                        </div>
                    </div>
                    <div class="form-row">
                        <label class="required">Jour du mois</label>
                        <div>
                            <telerik:RadComboBox ID="ddlJourMois" runat="server" Skin="Bootstrap"
                                Width="200px">
                                <Items>
                                    <telerik:RadComboBoxItem Text="-1 — Dernier jour du mois" Value="-1" />
                                </Items>
                            </telerik:RadComboBox>
                            <div class="hint">
                                Ex: 15 = le 15 de chaque mois, -1 = dernier jour (28/30/31 selon le mois).
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <!-- CRON -->
                <asp:Panel ID="pnlCron" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Expression CRON</label>
                        <div>
                            <telerik:RadTextBox ID="txtCronExpression" runat="server" Skin="Bootstrap"
                                Width="300px" MaxLength="100"
                                EmptyMessage="0 8 * * 1-5" />
                            <div class="cron-help">
                                <div><strong>Format :</strong> <code>min hour day-of-month month day-of-week</code></div>
                                <table>
                                    <tr><td><code>0 8 * * *</code></td><td>Tous les jours à 8h00</td></tr>
                                    <tr><td><code>*/30 8-18 * * 1-5</code></td><td>Toutes les 30 min, 8h-18h, Lun-Ven</td></tr>
                                    <tr><td><code>0 0 1 * *</code></td><td>Le 1er du mois à minuit</td></tr>
                                    <tr><td><code>0 12 * * 0</code></td><td>Tous les dimanches midi</td></tr>
                                    <tr><td><code>0 22 * * 1-5</code></td><td>Lun-Ven 22h00</td></tr>
                                </table>
                                <div style="margin-top: 6px; color: #92400e;">
                                    ⚠ La prochaine exécution sera calculée par le service .NET au prochain cycle.
                                </div>
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <!-- ONCE -->
                <asp:Panel ID="pnlOnce" runat="server" Visible="false">
                    <div class="form-row">
                        <label class="required">Date et heure d'exécution</label>
                        <div>
                            <telerik:RadDateTimePicker ID="dpDateOnce" runat="server" Skin="Bootstrap"
                                Width="240px">
                            </telerik:RadDateTimePicker>
                            <div class="hint">Le schedule sera désactivé après cette unique exécution.</div>
                        </div>
                    </div>
                </asp:Panel>

            </asp:PlaceHolder>
        </div>

        <!-- Section 2 : Période de validité + état -->
        <div class="sched-card">
            <h3>Période de validité et état</h3>

            <div class="form-row">
                <label>Date de début</label>
                <div>
                    <telerik:RadDatePicker ID="dpDateDebut" runat="server" Skin="Bootstrap"
                        Width="160px" />
                    <div class="hint">Avant cette date, le schedule ne s'exécute pas. (Défaut : aujourd'hui)</div>
                </div>
            </div>

            <div class="form-row">
                <label>Date de fin</label>
                <div>
                    <telerik:RadDatePicker ID="dpDateFin" runat="server" Skin="Bootstrap"
                        Width="160px" />
                    <div class="hint">Optionnel. Vide = pas de fin.</div>
                </div>
            </div>

            <div class="form-row">
                <label>État</label>
                <div>
                    <telerik:RadComboBox ID="ddlEtat" runat="server" Skin="Bootstrap" Width="220px">
                        <Items>
                            <telerik:RadComboBoxItem Text="Actif" Value="ACTIF" Selected="true" />
                            <telerik:RadComboBoxItem Text="En pause (temporaire)" Value="PAUSE" />
                            <telerik:RadComboBoxItem Text="Inactif" Value="INACTIF" />
                        </Items>
                    </telerik:RadComboBox>
                    <div class="hint">
                        Pause = arrêt temporaire (réactivable rapidement). Inactif = désactivation longue durée.
                    </div>
                </div>
            </div>
        </div>

        <!-- Section 3 : Paramètres override (optionnel) -->
        <div class="sched-card">
            <h3>Paramètres spécifiques (override)</h3>
            <div class="form-row">
                <label>HandlerParams (JSON)</label>
                <div>
                    <telerik:RadTextBox ID="txtHandlerParams" runat="server" Skin="Bootstrap"
                        Width="100%" TextMode="MultiLine" Rows="3"
                        EmptyMessage='{"@DateReference": "@END_OF_MONTH"}' />
                    <div class="hint">
                        Optionnel. Si renseigné, ces paramètres remplacent ceux par défaut du job pour ce schedule.
                    </div>
                </div>
            </div>
        </div>

        <!-- Champ caché pour exposer le JobDefinitionId au JavaScript -->
        <asp:HiddenField ID="hfJobId"  runat="server" Value="0" ClientIDMode="Static" />

        <!-- Action bar -->
        <div class="sched-card">
            <div class="action-bar">
                <div class="left">
                    <telerik:RadButton ID="btnApercu" runat="server" Skin="Bootstrap"
                        Text="Calculer aperçu" Icon-PrimaryIconCssClass="rbRefresh"
                        OnClick="btnApercu_Click" />
                    <telerik:RadButton ID="btnSupprimer" runat="server" Skin="Bootstrap"
                        Text="Supprimer ce schedule" Icon-PrimaryIconCssClass="rbDelete"
                        CssClass="btn-danger" Visible="false"
                        OnClick="btnSupprimer_Click"
                        OnClientClicking="confirmerSuppression" />
                </div>
                <div class="right">
                    <telerik:RadButton ID="btnAnnuler" runat="server" Skin="Bootstrap"
                        Text="Annuler" AutoPostBack="false"
                        OnClientClicked="annuler" />
                    <telerik:RadButton ID="btnEnregistrer" runat="server" Skin="Bootstrap"
                        Text="Enregistrer" Icon-PrimaryIconCssClass="rbSave"
                        OnClick="btnEnregistrer_Click" />
                </div>
            </div>
        </div>

    </div>

    <script type="text/javascript">
        function annuler(sender, args) {
            // Lecture du JobId depuis le HiddenField rendu par ASP.NET
            var hfJobId = document.getElementById('hfJobId');
            var jobId = hfJobId ? hfJobId.value : "0";

            if (jobId && jobId !== "0") {
                window.location.href = "wbfJobEdit.aspx?Id=" + jobId;
            } else {
                window.location.href = "wbfJobs.aspx";
            }
        }
        function confirmerSuppression(sender, args) {
            args.set_cancel(!confirm("Supprimer définitivement ce schedule ?"));
        }

        // Note : les pilules de jours de semaine sont gérées en CSS pur
        // via le sélecteur .jour-cb:checked + .jour-pill — aucun JS nécessaire.
    </script>

</asp:Content>
