<%@ Page Title="Édition d'un job" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfJobEdit.aspx.vb"
    Inherits="prjSec60Admin.wbfJobEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        .edit-page { max-width: 1100px; margin: 0 auto; padding: 12px; }
        .edit-page h2 { color: #0f172a; margin: 0 0 8px 0; }
        .edit-page .subtitle { color: #64748b; font-size: 13px; margin-bottom: 16px; }

        .edit-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 16px 20px;
            margin-bottom: 16px;
        }
        .edit-card h3 {
            margin: 0 0 16px 0; font-size: 15px; color: #0f172a;
            padding-bottom: 8px; border-bottom: 1px solid #f1f5f9;
        }

        /* Form layout */
        .form-row {
            display: grid;
            grid-template-columns: 180px 1fr;
            gap: 12px 16px;
            align-items: start;
            margin-bottom: 12px;
        }
        .form-row > label {
            font-size: 13px; color: #475569; padding-top: 6px;
            font-weight: 500;
        }
        .form-row > label.required::after {
            content: " *"; color: #dc2626;
        }
        .form-row .hint {
            font-size: 11px; color: #94a3b8; margin-top: 4px;
            font-style: italic;
        }
        .form-row.two-col {
            grid-template-columns: 180px 1fr 180px 1fr;
        }

        /* Badge système */
        .badge-systeme {
            background: #f3e8ff; color: #6b21a8;
            font-size: 11px; font-weight: 600;
            padding: 3px 10px; border-radius: 4px;
            margin-left: 12px;
            vertical-align: middle;
        }

        /* Aide JSON */
        .json-help {
            background: #f8fafc; border-left: 3px solid #cbd5e1;
            padding: 8px 12px; font-size: 11px; color: #64748b;
            margin-top: 6px; border-radius: 4px;
            font-family: 'Consolas', 'Monaco', monospace;
        }

        /* Actions */
        .action-bar {
            display: flex; gap: 12px; justify-content: space-between;
            padding-top: 16px; border-top: 1px solid #e2e8f0; margin-top: 16px;
            align-items: center;
        }
        .action-bar .left, .action-bar .right { display: flex; gap: 8px; }

        /* Tableau schedules */
        .sched-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .sched-table th {
            background: #f1f5f9; color: #475569; font-weight: 600;
            font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px;
            padding: 8px 10px; text-align: left;
        }
        .sched-table td {
            padding: 8px 10px; border-bottom: 1px solid #f1f5f9;
        }
        .sched-table tr:hover td { background: #fafbfc; }

        /* Pills */
        .pill {
            display: inline-block; padding: 2px 8px; border-radius: 999px;
            font-size: 11px; font-weight: 600;
        }
        .pill-success  { background: #dcfce7; color: #166534; }
        .pill-warning  { background: #fef3c7; color: #92400e; }
        .pill-danger   { background: #fee2e2; color: #991b1b; }
        .pill-info     { background: #dbeafe; color: #1e40af; }
        .pill-neutral  { background: #f1f5f9; color: #475569; }

        /* État vide */
        .empty-state {
            text-align: center; padding: 30px;
            color: #64748b; font-size: 13px;
        }

        /* Mini bouton inline */
        .btn-mini {
            background: transparent; border: 1px solid #cbd5e1;
            border-radius: 4px; padding: 3px 10px;
            font-size: 11px; cursor: pointer;
            color: #475569;
        }
        .btn-mini:hover { background: #f1f5f9; }
        .btn-mini.danger { color: #dc2626; border-color: #fecaca; }
        .btn-mini.danger:hover { background: #fee2e2; }
    </style>

    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="ddlHandlerType">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phHandler" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="rpSchedules">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="phSchedSection" LoadingPanelID="ralp" />
                    <telerik:AjaxUpdatedControl ControlID="phStatus" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>

    <telerik:RadAjaxLoadingPanel ID="ralp" runat="server" Skin="Bootstrap" />

    <div class="edit-page">

        <h2>
            <asp:Literal ID="litTitre" runat="server" Text="Nouveau job" />
            <asp:Literal ID="litBadgeSysteme" runat="server" />
        </h2>
        <div class="subtitle">
            <asp:Literal ID="litSousTitre" runat="server"
                Text="Définir une nouvelle tâche planifiée." />
        </div>

        <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
            <div id="divStatus" runat="server" class="edit-card" style="border-left: 4px solid;">
                <asp:Literal ID="litStatus" runat="server" />
            </div>
        </asp:PlaceHolder>

        <!-- Section 1 : Informations de base -->
        <div class="edit-card">
            <h3>Informations de base</h3>

            <div class="form-row">
                <label class="required">Code (identifiant)</label>
                <div>
                    <telerik:RadTextBox ID="txtJobCode" runat="server" Skin="Bootstrap"
                        Width="320px" MaxLength="50"
                        EmptyMessage="Ex: IMPORT_BANQUE" />
                    <div class="hint">Lettres majuscules et underscores. Doit être unique.</div>
                </div>
            </div>

            <div class="form-row">
                <label class="required">Nom</label>
                <div>
                    <telerik:RadTextBox ID="txtNom" runat="server" Skin="Bootstrap"
                        Width="100%" MaxLength="200" />
                </div>
            </div>

            <div class="form-row">
                <label>Description</label>
                <div>
                    <telerik:RadTextBox ID="txtDescription" runat="server" Skin="Bootstrap"
                        Width="100%" MaxLength="1000" TextMode="MultiLine" Rows="2" />
                    <div class="hint">Optionnel. Décrit ce que le job fait pour les utilisateurs.</div>
                </div>
            </div>

            <div class="form-row">
                <label>Statut</label>
                <div>
                    <telerik:RadComboBox ID="ddlActif" runat="server" Skin="Bootstrap" Width="180px">
                        <Items>
                            <telerik:RadComboBoxItem Text="Actif" Value="1" Selected="true" />
                            <telerik:RadComboBoxItem Text="Inactif" Value="0" />
                        </Items>
                    </telerik:RadComboBox>
                    <div class="hint">Un job inactif ne sera pas exécuté, même si ses schedules sont actifs.</div>
                </div>
            </div>
        </div>

        <!-- Section 2 : Handler -->
        <div class="edit-card">
            <h3>Configuration du handler</h3>

            <div class="form-row">
                <label class="required">Type</label>
                <div>
                    <telerik:RadComboBox ID="ddlHandlerType" runat="server" Skin="Bootstrap"
                        Width="220px" AutoPostBack="true"
                        OnSelectedIndexChanged="ddlHandlerType_SelectedIndexChanged">
                        <Items>
                            <telerik:RadComboBoxItem Text="-- Choisir --" Value="" />
                            <telerik:RadComboBoxItem Text="Procédure stockée (SP)" Value="SP" />
                            <telerik:RadComboBoxItem Text="Connecteur externe" Value="CONNECTOR" />
                            <telerik:RadComboBoxItem Text="Envoi de courriel" Value="EMAIL" />
                            <telerik:RadComboBoxItem Text="Classe .NET custom" Value="CUSTOM" />
                        </Items>
                    </telerik:RadComboBox>
                </div>
            </div>

            <asp:PlaceHolder ID="phHandler" runat="server">
                <div class="form-row">
                    <label class="required">
                        <asp:Literal ID="litHandlerNameLabel" runat="server" Text="Nom du handler" />
                    </label>
                    <div>
                        <telerik:RadTextBox ID="txtHandlerName" runat="server" Skin="Bootstrap"
                            Width="100%" MaxLength="200" />
                        <div class="hint">
                            <asp:Literal ID="litHandlerHint" runat="server"
                                Text="Sélectionne d'abord un type de handler." />
                        </div>
                    </div>
                </div>

                <div class="form-row">
                    <label>Paramètres (JSON)</label>
                    <div>
                        <telerik:RadTextBox ID="txtHandlerParams" runat="server" Skin="Bootstrap"
                            Width="100%" TextMode="MultiLine" Rows="4"
                            EmptyMessage='{"@DateReference": "@TODAY"}' />
                        <div class="json-help">
                            <strong>Macros disponibles :</strong> @TODAY, @YESTERDAY, @TOMORROW, @END_OF_MONTH, @START_OF_MONTH, @USERID
                        </div>
                    </div>
                </div>
            </asp:PlaceHolder>
        </div>

        <!-- Section 3 : Comportement -->
        <div class="edit-card">
            <h3>Comportement à l'exécution</h3>

            <div class="form-row two-col">
                <label>Timeout (sec)</label>
                <div>
                    <telerik:RadNumericTextBox ID="txtTimeoutSeconds" runat="server" Skin="Bootstrap"
                        Width="120px" Value="300" MinValue="1" MaxValue="86400"
                        NumberFormat-DecimalDigits="0" />
                </div>
                <label>Nombre max de retries</label>
                <div>
                    <telerik:RadNumericTextBox ID="txtMaxRetries" runat="server" Skin="Bootstrap"
                        Width="120px" Value="0" MinValue="0" MaxValue="10"
                        NumberFormat-DecimalDigits="0" />
                </div>
            </div>

            <div class="form-row">
                <label>Délai entre retries (min)</label>
                <div>
                    <telerik:RadNumericTextBox ID="txtRetryDelayMin" runat="server" Skin="Bootstrap"
                        Width="120px" Value="5" MinValue="1" MaxValue="1440"
                        NumberFormat-DecimalDigits="0" />
                    <div class="hint">Ignoré si MaxRetries = 0.</div>
                </div>
            </div>
        </div>

        <!-- Action bar haute (Save/Cancel) -->
        <div class="edit-card">
            <div class="action-bar">
                <div class="left">
                    <telerik:RadButton ID="btnSupprimer" runat="server" Skin="Bootstrap"
                        Text="Supprimer" Icon-PrimaryIconCssClass="rbDelete"
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

        <!-- Section 4 : Schedules (visible seulement en mode édition) -->
        <asp:PlaceHolder ID="phSchedSection" runat="server" Visible="false">
            <div class="edit-card">
                <h3>Schedules associés</h3>

                <asp:PlaceHolder ID="phSchedEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        Aucun schedule configuré pour ce job.
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phSchedTable" runat="server" Visible="false">
                    <table class="sched-table">
                        <thead>
                            <tr>
                                <th>Nom</th>
                                <th>Type</th>
                                <th>Description</th>
                                <th>Prochaine exéc.</th>
                                <th>État</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpSchedules" runat="server"
                                OnItemCommand="rpSchedules_ItemCommand">
                                <ItemTemplate>
                                    <tr>
                                        <td><strong><%# Eval("Nom") %></strong></td>
                                        <td><%# Eval("ScheduleType") %></td>
                                        <td><%# Eval("DescriptionLisible") %></td>
                                        <td>
                                            <%# IIf(Convert.IsDBNull(Eval("ProchaineExec")),
                                                    "<span style='color:#94a3b8;'>—</span>",
                                                    Convert.ToDateTime(Eval("ProchaineExec")).ToString("yyyy-MM-dd HH:mm")) %>
                                        </td>
                                        <td>
                                            <%# If(Convert.ToBoolean(Eval("Pause")),
                                                   "<span class='pill pill-warning'>EN PAUSE</span>",
                                                   If(Convert.ToBoolean(Eval("Actif")),
                                                      "<span class='pill pill-success'>ACTIF</span>",
                                                      "<span class='pill pill-neutral'>INACTIF</span>")) %>
                                        </td>
                                        <td style="text-align:right;">
                                            <asp:LinkButton ID="btnEditSched" runat="server"
                                                CssClass="btn-mini"
                                                CommandName="EditSched"
                                                CommandArgument='<%# Eval("Id") %>'
                                                Text="Éditer" />
                                            <asp:LinkButton ID="btnTogglePause" runat="server"
                                                CssClass="btn-mini"
                                                CommandName="TogglePause"
                                                CommandArgument='<%# Eval("Id") %>'>
                                                <%# IIf(Convert.ToBoolean(Eval("Pause")), "Reprendre", "Pause") %>
                                            </asp:LinkButton>
                                            <asp:LinkButton ID="btnSupprSched" runat="server"
                                                CssClass="btn-mini danger"
                                                CommandName="SupprSched"
                                                CommandArgument='<%# Eval("Id") %>'
                                                Text="✕"
                                                OnClientClick="return confirm('Supprimer ce schedule ?');" />
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </asp:PlaceHolder>

                <div style="margin-top: 12px; text-align: right;">
                    <telerik:RadButton ID="btnAjouterSched" runat="server" Skin="Bootstrap"
                        Text="+ Ajouter un schedule" AutoPostBack="false"
                        OnClientClicked="ajouterSchedule" />
                </div>
            </div>

            <!-- Section 5 : Aperçu historique -->
            <div class="edit-card">
                <h3>Activité récente</h3>

                <asp:PlaceHolder ID="phHistEmpty" runat="server" Visible="false">
                    <div class="empty-state">
                        Aucune exécution n'a encore eu lieu pour ce job.
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phHistTable" runat="server" Visible="false">
                    <table class="sched-table">
                        <thead>
                            <tr>
                                <th>Démarré</th>
                                <th>Trigger</th>
                                <th>Statut</th>
                                <th>Durée</th>
                                <th>Lignes</th>
                                <th>Message</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rpHistorique" runat="server"
                                OnItemDataBound="rpHistorique_ItemDataBound">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Convert.ToDateTime(Eval("Demarre")).ToString("yyyy-MM-dd HH:mm:ss") %></td>
                                        <td><%# Eval("TriggerType") %></td>
                                        <td>
                                            <asp:Literal ID="litStatutPill" runat="server" />
                                        </td>
                                        <td><%# IIf(Convert.IsDBNull(Eval("DureeMs")), "—",
                                                    String.Format("{0:N0} ms", Eval("DureeMs"))) %></td>
                                        <td><%# IIf(Convert.IsDBNull(Eval("LignesTraitees")), "—",
                                                    Eval("LignesTraitees")) %></td>
                                        <td><%# IIf(Convert.IsDBNull(Eval("ResultatMessage")), "",
                                                    Server.HtmlEncode(Eval("ResultatMessage").ToString())) %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                    <div style="margin-top: 12px; text-align: right;">
                        <asp:HyperLink ID="lnkVoirHistorique" runat="server"
                            Text="Voir tout l'historique →"
                            CssClass="btn-mini" Style="text-decoration:none;" />
                    </div>
                </asp:PlaceHolder>
            </div>
        </asp:PlaceHolder>

    </div>

    <!-- Champ caché pour exposer le JobDefinitionId au JavaScript -->
    <asp:HiddenField ID="hfJobId"  runat="server" Value="0" ClientIDMode="Static" />

    <script type="text/javascript">
        function annuler(sender, args) {
            window.location.href = "wbfJobs.aspx";
        }
        function confirmerSuppression(sender, args) {
            args.set_cancel(!confirm("Supprimer définitivement ce job et tout son historique ?"));
        }
        function ajouterSchedule(sender, args) {
            var mhfJobId = document.getElementById('hfJobId');
            var jobId = mhfJobId ? mhfJobId.value : "0";
            window.location.href = "wbfJobSchedule.aspx?JobId=" + jobId + "&Id=0";
        }
    </script>

</asp:Content>
