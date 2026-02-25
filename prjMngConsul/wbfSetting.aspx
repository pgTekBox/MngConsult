<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"  CodeBehind="wbfSetting.aspx.vb" Inherits="MngConsul.wbfSetting" %>
 

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

        .wrap{ padding:16px; }
        .card{
            background:#fff;
            border:1px solid var(--mc-stroke);
            border-radius:14px;
            box-shadow:0 12px 30px rgba(2,6,23,.06);
            overflow:hidden;
        }
        .card-b{ padding:14px; }

        .form-grid{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:12px;
        }
        @media (max-width: 820px){
            .form-grid{ grid-template-columns:1fr; }
        }
        .field label{
            display:block;
            font-size:12px;
            color:var(--mc-muted);
            margin-bottom:6px;
        }
        .hint{ color:var(--mc-muted); font-size:12px; margin-top:6px; }

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

        /* Telerik Tabs: petit ajustement visuel */
        .RadTabStrip{ margin-bottom:12px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Paramètres</div>
            <div class="page-sub">Entreprise, taxes, courriels et configuration PDF.</div>
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
        <div class="card">
            <div class="card-b">

                <telerik:RadTabStrip ID="tsSettings" runat="server"
                    MultiPageID="mpSettings"
                    SelectedIndex="0"
                    Skin="Metro"
                    Orientation="HorizontalTop">

                    <Tabs>
                        <telerik:RadTab Text="Entreprise" />
                        <telerik:RadTab Text="Taxes" />
                        <telerik:RadTab Text="Email" />
                        <telerik:RadTab Text="PDF" />
                    </Tabs>
                </telerik:RadTabStrip>

                <telerik:RadMultiPage ID="mpSettings" runat="server" SelectedIndex="0">

                    <!-- ENTREPRISE -->
                    <telerik:RadPageView ID="pvCompany" runat="server">
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
                    </telerik:RadPageView>

                    <!-- TAXES -->
                    <telerik:RadPageView ID="pvTaxes" runat="server">
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
                                <div class="hint">Standard Canada: 5%</div>
                            </div>

                            <div class="field">
                                <label>Taux TVQ (%)</label>
                                <telerik:RadNumericTextBox ID="ntbQSTRate" runat="server" Width="100%"
                                    NumberFormat-DecimalDigits="3" MinValue="0" MaxValue="99" Value="9.975" />
                                <div class="hint">Québec: 9.975%</div>
                            </div>

                            <div class="field">
                                <label>Arrondi taxes</label>
                                <telerik:RadComboBox ID="ddTaxRounding" runat="server" Width="100%" />
                                <div class="hint">Recommandé: 2 décimales (cent).</div>
                            </div>

                            <div class="field">
                                <label>Mode de taxes</label>
                                <telerik:RadComboBox ID="ddTaxMode" runat="server" Width="100%" />
                                <div class="hint">Taxes en sus vs incluses.</div>
                            </div>

                        </div>
                    </telerik:RadPageView>

                    <!-- EMAIL -->
                    <telerik:RadPageView ID="pvEmail" runat="server">
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
                                <telerik:RadNumericTextBox ID="ntbSmtpPort" runat="server" Width="100%"
                                    MinValue="1" MaxValue="65535" Value="587" />
                            </div>

                            <div class="field">
                                <label>SMTP User</label>
                                <telerik:RadTextBox ID="tbSmtpUser" runat="server" Width="100%" />
                            </div>

                            <div class="field">
                                <label>SMTP Password</label>
                                <telerik:RadTextBox ID="tbSmtpPass" runat="server" Width="100%" TextMode="Password" />
                                <div class="hint">Recommandé: stocker chiffré.</div>
                            </div>

                            <div class="field" style="grid-column:1/-1;">
                                <label>Signature / Pied de page</label>
                                <telerik:RadTextBox ID="tbMailSignature" runat="server" Width="100%"
                                    TextMode="MultiLine" Rows="5" />
                            </div>

                        </div>
                    </telerik:RadPageView>

                    <!-- PDF -->
                    <telerik:RadPageView ID="pvPdf" runat="server">
                        <div class="form-grid">

                            <div class="field">
                                <label>Nom du modèle PDF</label>
                                <telerik:RadTextBox ID="tbPdfTemplate" runat="server" Width="100%" Text="DefaultInvoiceTemplate" />
                            </div>

                            <div class="field">
                                <label>Logo (URL / chemin)</label>
                                <telerik:RadTextBox ID="tbLogoPath" runat="server" Width="100%" />
                            </div>

                            <div class="field" style="grid-column:1/-1;">
                                <label>Conditions de paiement (sur facture)</label>
                                <telerik:RadTextBox ID="tbPaymentTerms" runat="server" Width="100%"
                                    TextMode="MultiLine" Rows="3" Text="Payable sur réception" />
                            </div>

                            <div class="field" style="grid-column:1/-1;">
                                <label>Mentions / Notes</label>
                                <telerik:RadTextBox ID="tbInvoiceNotes" runat="server" Width="100%"
                                    TextMode="MultiLine" Rows="4" Text="Merci pour votre confiance!" />
                            </div>

                            <div class="field">
                                <label>Afficher tampon “PAYÉ”</label>
                                <telerik:RadComboBox ID="ddShowPaidStamp" runat="server" Width="100%" />
                            </div>

                            <div class="field">
                                <label>Email PDF après paiement</label>
                                <telerik:RadComboBox ID="ddEmailAfterPay" runat="server" Width="100%" />
                            </div>

                        </div>
                    </telerik:RadPageView>

                </telerik:RadMultiPage>

            </div>
        </div>
    </div>

</asp:Content>