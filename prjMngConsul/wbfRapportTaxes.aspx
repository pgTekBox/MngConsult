<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfRapportTaxes.aspx.vb" Inherits="MngConsul.wbfRapportTaxes" %>
<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Settings.aspx.vb" Inherits="MngConsul.Settings" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paramètres — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .page-head{
            display:flex; align-items:flex-start; justify-content:space-between;
            gap:12px; flex-wrap:wrap;
            padding:14px 16px;
            border-bottom:1px solid var(--mc-stroke);
            background:rgba(255,255,255,.75);
        }
        .page-title{ font-weight:900; font-size:18px; line-height:1.2; }
        .page-sub{ color:var(--mc-muted); font-size:13px; margin-top:4px; }
        .actions{ display:flex; gap:8px; flex-wrap:wrap; align-items:center; }

        .wrap{
            padding:16px;
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:16px;
        }
        @media (max-width: 980px){
            .wrap{ grid-template-columns:1fr; }
        }

        .card{
            background:#fff;
            border:1px solid var(--mc-stroke);
            border-radius:14px;
            box-shadow: 0 12px 30px rgba(2,6,23,.06);
            overflow:hidden;
        }
        .card-h{
            padding:14px 14px 10px 14px;
            border-bottom:1px solid var(--mc-stroke);
            display:flex;
            align-items:flex-start;
            justify-content:space-between;
            gap:12px;
        }
        .card-title{ font-weight:900; font-size:14px; }
        .card-desc{ color:var(--mc-muted); font-size:12px; margin-top:4px; }
        .card-b{ padding:14px; }

        .form-grid{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:12px;
        }
        @media (max-width: 640px){
            .form-grid{ grid-template-columns:1fr; }
        }
        .field label{
            display:block;
            font-size:12px;
            color:var(--mc-muted);
            margin-bottom:6px;
        }
        .hint{
            font-size:12px;
            color:var(--mc-muted);
            margin-top:6px;
        }

        /* Harmonisation avec tes classes existantes */
        .btn{ cursor:pointer; }
        .status-ok{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px;
            border-radius:999px;
            background:rgba(22,163,74,.10);
            color:#166534;
            border:1px solid rgba(22,163,74,.20);
            font-size:12px;
        }
        .status-err{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px;
            border-radius:999px;
            background:rgba(220,38,38,.10);
            color:#991b1b;
            border:1px solid rgba(220,38,38,.20);
            font-size:12px;
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Paramètres</div>
            <div class="page-sub">Configuration de l’entreprise, taxes, numérotation, courriels et documents.</div>
        </div>

        <div class="actions">
            <telerik:RadButton ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary"
                AutoPostBack="true" OnClick="btnSave_Click" />
            <telerik:RadButton ID="btnReload" runat="server" Text="Recharger" CssClass="btn"
                AutoPostBack="true" OnClick="btnReload_Click" />

            <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
                <asp:Literal ID="litStatus" runat="server" />
            </asp:PlaceHolder>
        </div>
    </div>

    <div class="wrap">

        <!-- Entreprise -->
        <div class="card">
            <div class="card-h">
                <div>
                    <div class="card-title">Entreprise</div>
                    <div class="card-desc">Nom légal, NEQ, coordonnées, adresse.</div>
                </div>
            </div>
            <div class="card-b">
                <div class="form-grid">
                    <div class="field">
                        <label>Nom légal</label>
                        <telerik:RadTextBox ID="tbLegalName" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>Nom commercial</label>
                        <telerik:RadTextBox ID="tbTradeName" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>NEQ</label>
                        <telerik:RadTextBox ID="tbNEQ" runat="server" Width="100%" />
                        <div class="hint">Optionnel si non applicable.</div>
                    </div>
                    <div class="field">
                        <label>Téléphone</label>
                        <telerik:RadTextBox ID="tbPhone" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>Adresse (ligne 1)</label>
                        <telerik:RadTextBox ID="tbAddr1" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>Adresse (ligne 2)</label>
                        <telerik:RadTextBox ID="tbAddr2" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>Ville</label>
                        <telerik:RadTextBox ID="tbCity" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>Province</label>
                        <telerik:RadComboBox ID="ddProvince" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>Code postal</label>
                        <telerik:RadTextBox ID="tbPostal" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>Pays</label>
                        <telerik:RadTextBox ID="tbCountry" runat="server" Width="100%" Text="Canada" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Taxes -->
        <div class="card">
            <div class="card-h">
                <div>
                    <div class="card-title">Taxes (TPS / TVQ)</div>
                    <div class="card-desc">Numéros de taxes et taux par défaut.</div>
                </div>
            </div>
            <div class="card-b">
                <div class="form-grid">
                    <div class="field">
                        <label>No TPS (GST)</label>
                        <telerik:RadTextBox ID="tbGST" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>No TVQ (QST)</label>
                        <telerik:RadTextBox ID="tbQST" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>Taux TPS (%)</label>
                        <telerik:RadNumericTextBox ID="ntbGSTRate" runat="server" Width="100%"
                            NumberFormat-DecimalDigits="3" MinValue="0" MaxValue="99" Value="5" />
                    </div>
                    <div class="field">
                        <label>Taux TVQ (%)</label>
                        <telerik:RadNumericTextBox ID="ntbQSTRate" runat="server" Width="100%"
                            NumberFormat-DecimalDigits="3" MinValue="0" MaxValue="99" Value="9.975" />
                    </div>

                    <div class="field">
                        <label>Arrondi taxes</label>
                        <telerik:RadComboBox ID="ddTaxRounding" runat="server" Width="100%" />
                        <div class="hint">Recommandé : arrondir au cent (2 décimales).</div>
                    </div>
                    <div class="field">
                        <label>Mode de taxes</label>
                        <telerik:RadComboBox ID="ddTaxMode" runat="server" Width="100%" />
                        <div class="hint">Ex. “Taxes en sus” vs “Taxes incluses”.</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Numérotation -->
        <div class="card">
            <div class="card-h">
                <div>
                    <div class="card-title">Numérotation</div>
                    <div class="card-desc">Préfixes et séquences (factures, reçus, paiements).</div>
                </div>
            </div>
            <div class="card-b">
                <div class="form-grid">
                    <div class="field">
                        <label>Préfixe Facture client</label>
                        <telerik:RadTextBox ID="tbInvPrefix" runat="server" Width="100%" Text="FC-" />
                    </div>
                    <div class="field">
                        <label>Prochain no Facture client</label>
                        <telerik:RadNumericTextBox ID="ntbInvNext" runat="server" Width="100%" MinValue="1" Value="1000" />
                    </div>

                    <div class="field">
                        <label>Préfixe Facture fournisseur</label>
                        <telerik:RadTextBox ID="tbSupInvPrefix" runat="server" Width="100%" Text="FF-" />
                    </div>
                    <div class="field">
                        <label>Prochain no Facture fournisseur</label>
                        <telerik:RadNumericTextBox ID="ntbSupInvNext" runat="server" Width="100%" MinValue="1" Value="5000" />
                    </div>

                    <div class="field">
                        <label>Préfixe Reçu</label>
                        <telerik:RadTextBox ID="tbReceiptPrefix" runat="server" Width="100%" Text="R-" />
                    </div>
                    <div class="field">
                        <label>Prochain no Reçu</label>
                        <telerik:RadNumericTextBox ID="ntbReceiptNext" runat="server" Width="100%" MinValue="1" Value="1" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Email / envoi -->
        <div class="card">
            <div class="card-h">
                <div>
                    <div class="card-title">Courriels</div>
                    <div class="card-desc">SMTP ou service d’envoi (ex: SendGrid), signature, “From”.</div>
                </div>
            </div>
            <div class="card-b">
                <div class="form-grid">
                    <div class="field">
                        <label>From name</label>
                        <telerik:RadTextBox ID="tbMailFromName" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>From email</label>
                        <telerik:RadTextBox ID="tbMailFromEmail" runat="server" Width="100%" />
                    </div>

                    <div class="field">
                        <label>SMTP Host</label>
                        <telerik:RadTextBox ID="tbSmtpHost" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>SMTP Port</label>
                        <telerik:RadNumericTextBox ID="ntbSmtpPort" runat="server" Width="100%" MinValue="1" MaxValue="65535" Value="587" />
                    </div>

                    <div class="field">
                        <label>SMTP User</label>
                        <telerik:RadTextBox ID="tbSmtpUser" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>SMTP Password</label>
                        <telerik:RadTextBox ID="tbSmtpPass" runat="server" Width="100%" TextMode="Password" />
                        <div class="hint">Stockage recommandé : chiffré (DPAPI / Always Encrypted / Secret store).</div>
                    </div>

                    <div class="field" style="grid-column:1/-1;">
                        <label>Signature / Pied de page</label>
                        <telerik:RadTextBox ID="tbMailSignature" runat="server" Width="100%" TextMode="MultiLine" Rows="4" />
                    </div>
                </div>
            </div>
        </div>

        <!-- PDF / Factures -->
        <div class="card" style="grid-column:1/-1;">
            <div class="card-h">
                <div>
                    <div class="card-title">PDF / Factures</div>
                    <div class="card-desc">Modèle, logo, mentions légales, conditions de paiement.</div>
                </div>
            </div>
            <div class="card-b">
                <div class="form-grid">
                    <div class="field">
                        <label>Nom du modèle PDF</label>
                        <telerik:RadTextBox ID="tbPdfTemplate" runat="server" Width="100%" Text="DefaultInvoiceTemplate" />
                    </div>
                    <div class="field">
                        <label>Logo URL / Chemin</label>
                        <telerik:RadTextBox ID="tbLogoPath" runat="server" Width="100%" />
                        <div class="hint">Ex: /assets/logo.png ou URL.</div>
                    </div>

                    <div class="field" style="grid-column:1/-1;">
                        <label>Conditions de paiement (affichées sur facture)</label>
                        <telerik:RadTextBox ID="tbPaymentTerms" runat="server" Width="100%" TextMode="MultiLine" Rows="3"
                            Text="Payable sur réception" />
                    </div>

                    <div class="field" style="grid-column:1/-1;">
                        <label>Mentions légales / Notes</label>
                        <telerik:RadTextBox ID="tbInvoiceNotes" runat="server" Width="100%" TextMode="MultiLine" Rows="4"
                            Text="Merci pour votre confiance!" />
                    </div>

                    <div class="field">
                        <label>Afficher statut “PAYÉ”</label>
                        <telerik:RadComboBox ID="ddShowPaidStamp" runat="server" Width="100%" />
                    </div>
                    <div class="field">
                        <label>Envoyer PDF par email après paiement</label>
                        <telerik:RadComboBox ID="ddEmailAfterPay" runat="server" Width="100%" />
                    </div>
                </div>
            </div>
        </div>

    </div>

</asp:Content>