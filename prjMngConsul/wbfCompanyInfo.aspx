<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfCompanyInfo.aspx.vb" Inherits="MngConsul.wbfCompanyInfo" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Compagnie — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        /* =========================
           PAGE
        ========================= */
        .page-head {
            padding: 20px 24px 12px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .page-title {
            font-weight: 900;
            font-size: 20px;
            line-height: 1.2;
            color: #0f172a;
        }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

        /* =========================
           ONGLETS
        ========================= */
        .tabs-bar {
            display: flex;
            gap: 0;
            padding: 16px 24px 0;
            background: #fff;
            border-bottom: 1px solid var(--mc-stroke);
            overflow-x: auto;
        }

        .tab-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            padding: 14px 28px;
            cursor: pointer;
            border: 1px solid var(--mc-stroke);
            border-bottom: none;
            border-radius: 12px 12px 0 0;
            background: #f8fafc;
            color: #64748b;
            font-weight: 700;
            font-size: 14px;
            white-space: nowrap;
            margin-right: 4px;
            transition: background .15s, color .15s;
            text-decoration: none;
        }

        .tab-item:hover {
            background: #f1f5f9;
            color: #0f172a;
        }

        .tab-item.active {
            background: #fff;
            color: #0f172a;
            border-color: var(--mc-stroke);
            border-bottom-color: #fff;
            margin-bottom: -1px;
            z-index: 1;
        }

        .tab-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
        }

        .tab-icon.blue   { background: linear-gradient(135deg, #2563eb, #3b82f6); }
        .tab-icon.teal   { background: linear-gradient(135deg, #0891b2, #06b6d4); }
        .tab-icon.green  { background: linear-gradient(135deg, #059669, #10b981); }
        .tab-icon.indigo { background: linear-gradient(135deg, #4338ca, #6366f1); }
        .tab-icon.purple { background: linear-gradient(135deg, #7c3aed, #a855f7); }

        /* =========================
           CONTENU
        ========================= */
        .tab-content {
            padding: 28px 24px;
            flex: 1 1 auto;
            overflow: auto;
        }

        /* =========================
           FORMULAIRE
        ========================= */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px 24px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group.full {
            grid-column: 1 / -1;
        }

        .form-label {
            font-size: 13px;
            font-weight: 700;
            color: #0f172a;
        }

        .form-input,
        .form-select {
            width: 100%;
            padding: 10px 14px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            font-size: 14px;
            color: #0f172a;
            background: #fff;
            outline: none;
            transition: border-color .15s, box-shadow .15s;
            box-sizing: border-box;
        }

        .form-input::placeholder {
            color: #94a3b8;
        }

        .form-input:focus,
        .form-select:focus {
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, .12);
        }

        .form-select {
            appearance: auto;
        }

        /* =========================
           ACTIONS
        ========================= */
        .form-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            padding: 16px 24px;
            border-top: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.85);
        }

        .btn-cancel {
            padding: 10px 20px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: #fff;
            color: #0f172a;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
        }

        .btn-cancel:hover {
            background: #f8fafc;
        }

        .btn-save {
            padding: 10px 24px;
            border: none;
            border-radius: 10px;
            background: #2563eb;
            color: #fff;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
        }

        .btn-save:hover {
            background: #1d4ed8;
        }

        /* =========================
           RESPONSIVE TABLETTE
        ========================= */
        @media (max-width: 1024px) {
            .tab-item {
                padding: 12px 18px;
            }

            .tab-content {
                padding: 20px 16px;
            }
        }

        /* =========================
           RESPONSIVE MOBILE
        ========================= */
        @media (max-width: 768px) {
            .page-head {
                padding: 14px 16px 10px;
            }

            .tabs-bar {
                padding: 12px 12px 0;
                gap: 4px;
            }

            .tab-item {
                padding: 10px 14px;
                font-size: 12px;
            }

            .tab-icon {
                width: 36px;
                height: 36px;
                font-size: 18px;
            }

            .form-grid {
                grid-template-columns: 1fr;
            }

            .form-group.full {
                grid-column: 1;
            }

            .tab-content {
                padding: 16px 12px;
            }

            .form-actions {
                padding: 12px 16px;
            }
        }

        @media (max-width: 480px) {
            .tab-item span.tab-label {
                display: none; /* cache le texte, garde seulement l'icône */
            }

            .tab-item {
                padding: 10px 12px;
            }
        }

    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro" />

    <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">

        <%-- EN-TÊTE --%>
        <div class="page-head">
            <div class="page-title">Compagnie Information</div>
            <div class="page-sub">Gestion complète des informations de l'entreprise</div>
        </div>

        <%-- ONGLETS --%>
        <div class="tabs-bar">

            <a class="tab-item active" href="#" onclick="showTab('generale'); return false;">
                <div class="tab-icon blue">🏢</div>
                <span class="tab-label">Générale</span>
            </a>

            <a class="tab-item" href="#" onclick="showTab('gouvernementale'); return false;">
                <div class="tab-icon teal">📄</div>
                <span class="tab-label">Gouvernementale</span>
            </a>

            <a class="tab-item" href="#" onclick="showTab('bancaire'); return false;">
                <div class="tab-icon green">💳</div>
                <span class="tab-label">Bancaire</span>
            </a>

            <a class="tab-item" href="#" onclick="showTab('actionnariale'); return false;">
                <div class="tab-icon indigo">👥</div>
                <span class="tab-label">Actionnariale</span>
            </a>

            <a class="tab-item" href="#" onclick="showTab('etatfinancier'); return false;">
                <div class="tab-icon purple">📊</div>
                <span class="tab-label">État-financier</span>
            </a>

        </div>

        <%-- ONGLET GÉNÉRALE --%>
        <div id="tab-generale" class="tab-content">
            <div class="form-grid">

                <div class="form-group">
                    <label class="form-label">Nom commercial</label>
                    <asp:TextBox ID="tbNomCommercial" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: Tech Solutions Inc." />
                </div>

                <div class="form-group">
                    <label class="form-label">Raison sociale</label>
                    <asp:TextBox ID="tbRaisonSociale" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: Tech Solutions Corporation" />
                </div>

                <div class="form-group">
                    <label class="form-label">Date d'incorporation</label>
                    <asp:TextBox ID="tbDateIncorporation" runat="server"
                        CssClass="form-input"
                        TextMode="Date" />
                </div>

                <div class="form-group">
                    <label class="form-label">Industrie</label>
                    <asp:TextBox ID="tbIndustrie" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: Technologie, Consultation" />
                </div>

                <div class="form-group full">
                    <label class="form-label">Adresse</label>
                    <asp:TextBox ID="tbAdresse" runat="server"
                        CssClass="form-input"
                        placeholder="123 Rue Principale" />
                </div>

                <div class="form-group">
                    <label class="form-label">Ville</label>
                    <asp:TextBox ID="tbVille" runat="server"
                        CssClass="form-input"
                        placeholder="Montréal" />
                </div>

                <div class="form-group">
                    <label class="form-label">Province</label>
                    <asp:DropDownList ID="ddlProvince" runat="server" CssClass="form-select">
                        <asp:ListItem Value="">Sélectionner</asp:ListItem>
                        <asp:ListItem Value="QC">Québec</asp:ListItem>
                        <asp:ListItem Value="ON">Ontario</asp:ListItem>
                        <asp:ListItem Value="BC">Colombie-Britannique</asp:ListItem>
                        <asp:ListItem Value="AB">Alberta</asp:ListItem>
                        <asp:ListItem Value="MB">Manitoba</asp:ListItem>
                        <asp:ListItem Value="SK">Saskatchewan</asp:ListItem>
                        <asp:ListItem Value="NS">Nouvelle-Écosse</asp:ListItem>
                        <asp:ListItem Value="NB">Nouveau-Brunswick</asp:ListItem>
                        <asp:ListItem Value="NL">Terre-Neuve</asp:ListItem>
                        <asp:ListItem Value="PE">Île-du-Prince-Édouard</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <div class="form-group">
                    <label class="form-label">Code postal</label>
                    <asp:TextBox ID="tbCodePostal" runat="server"
                        CssClass="form-input"
                        placeholder="H1H 1H1" />
                </div>

                <div class="form-group">
                    <label class="form-label">Téléphone</label>
                    <asp:TextBox ID="tbTelephone" runat="server"
                        CssClass="form-input"
                        placeholder="(514) 555-1234" />
                </div>

                <div class="form-group">
                    <label class="form-label">Courriel</label>
                    <asp:TextBox ID="tbCourriel" runat="server"
                        CssClass="form-input"
                        TextMode="Email"
                        placeholder="info@entreprise.com" />
                </div>

                <div class="form-group">
                    <label class="form-label">Site web</label>
                    <asp:TextBox ID="tbSiteWeb" runat="server"
                        CssClass="form-input"
                        placeholder="www.entreprise.com" />

                     
                </div>

            </div>
        </div>

        <%-- ONGLET GOUVERNEMENTALE --%>
        <div id="tab-gouvernementale" class="tab-content" style="display:none;">
            <div class="form-grid">

                <div class="form-group">
                    <label class="form-label">Numéro d'entreprise (NEQ)</label>
                    <asp:TextBox ID="tbNEQ" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 1234567890" />
                </div>

                <div class="form-group">
                    <label class="form-label">Numéro TPS</label>
                    <asp:TextBox ID="tbTPS" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 123456789 RT0001" />
                </div>

                <div class="form-group">
                    <label class="form-label">Numéro TVQ</label>
                    <asp:TextBox ID="tbTVQ" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 1234567890 TQ0001" />
                </div>

                <div class="form-group">
                    <label class="form-label">Année fiscale (début)</label>
                    <asp:TextBox ID="tbAnneeFiscale" runat="server"
                        CssClass="form-input"
                        TextMode="Date" />
                </div>

            </div>
        </div>

        <%-- ONGLET BANCAIRE --%>
        <div id="tab-bancaire" class="tab-content" style="display:none;">
            <div class="form-grid">

                <div class="form-group">
                    <label class="form-label">Institution bancaire</label>
                    <asp:TextBox ID="tbBanque" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: Banque Nationale" />
                </div>

                <div class="form-group">
                    <label class="form-label">Numéro de transit</label>
                    <asp:TextBox ID="tbTransit" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 12345" />
                </div>

                <div class="form-group">
                    <label class="form-label">Numéro d'institution</label>
                    <asp:TextBox ID="tbInstitution" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 006" />
                </div>

                <div class="form-group">
                    <label class="form-label">Numéro de compte</label>
                    <asp:TextBox ID="tbCompte" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 1234567" />
                </div>

            </div>
        </div>

        <%-- ONGLET ACTIONNARIALE --%>
        <div id="tab-actionnariale" class="tab-content" style="display:none;">
            <div class="form-grid">

                <div class="form-group">
                    <label class="form-label">Nom de l'actionnaire principal</label>
                    <asp:TextBox ID="tbActionnaire" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: Jean Tremblay" />
                </div>

                <div class="form-group">
                    <label class="form-label">Pourcentage de participation (%)</label>
                    <asp:TextBox ID="tbParticipation" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 51" />
                </div>

                <div class="form-group">
                    <label class="form-label">Type d'actions</label>
                    <asp:DropDownList ID="ddlTypeActions" runat="server" CssClass="form-select">
                        <asp:ListItem Value="">Sélectionner</asp:ListItem>
                        <asp:ListItem Value="ordinaires">Actions ordinaires</asp:ListItem>
                        <asp:ListItem Value="privilegiees">Actions privilégiées</asp:ListItem>
                        <asp:ListItem Value="mixtes">Mixtes</asp:ListItem>
                    </asp:DropDownList>
                </div>

                <div class="form-group">
                    <label class="form-label">Nombre d'actions émises</label>
                    <asp:TextBox ID="tbNbActions" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 1000" />
                </div>

            </div>
        </div>

        <%-- ONGLET ÉTAT-FINANCIER --%>
        <div id="tab-etatfinancier" class="tab-content" style="display:none;">
            <div class="form-grid">

                <div class="form-group">
                    <label class="form-label">Chiffre d'affaires annuel ($)</label>
                    <asp:TextBox ID="tbCA" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 500000" />
                </div>

                <div class="form-group">
                    <label class="form-label">Bénéfice net ($)</label>
                    <asp:TextBox ID="tbBenefice" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 75000" />
                </div>

                <div class="form-group">
                    <label class="form-label">Total actif ($)</label>
                    <asp:TextBox ID="tbActif" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 250000" />
                </div>

                <div class="form-group">
                    <label class="form-label">Total passif ($)</label>
                    <asp:TextBox ID="tbPassif" runat="server"
                        CssClass="form-input"
                        placeholder="Ex: 100000" />
                </div>

            </div>
        </div>

        <%-- BOUTONS --%>
        <div class="form-actions">
            <asp:Button ID="btnAnnuler" runat="server"
                CssClass="btn-cancel"
                Text="Annuler"
                CausesValidation="false" />

            <asp:Button ID="btnEnregistrer" runat="server"
                CssClass="btn-save"
                Text="Enregistrer" />
        </div>

    </telerik:RadAjaxPanel>

    <script type="text/javascript">
        function showTab(tabName) {
            // Cache tous les onglets
            var contents = document.querySelectorAll('.tab-content');
            contents.forEach(function (c) { c.style.display = 'none'; });

            // Désactive tous les liens
            var tabs = document.querySelectorAll('.tab-item');
            tabs.forEach(function (t) { t.classList.remove('active'); });

            // Affiche le bon onglet
            var target = document.getElementById('tab-' + tabName);
            if (target) target.style.display = 'block';

            // Active le bon lien
            event.currentTarget.classList.add('active');
        }
    </script>

</asp:Content>
