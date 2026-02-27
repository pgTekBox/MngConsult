<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfInvoiceEdit.aspx.vb" Inherits="MngConsul.wbfInvoiceEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Facture</title>

    <style>
        :root {
            --bg: #f6f8fc;
            --card: #ffffff;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --shadow: 0 18px 50px rgba(2,6,23,.10);
            --shadow2: 0 10px 26px rgba(2,6,23,.08);
            --accent: #2563eb;
            --accent2: #06b6d4;
            /* ✅ radius global (tout arrondi) */
            --r-xs: 10px;
            --r-sm: 12px;
            --r-md: 14px;
            --r-lg: 18px;
            --r-xl: 22px;
        }

        html, body, form {
            height: 100%
        }

        body {
            margin: 0;
            background: radial-gradient(900px 400px at 20% -10%, rgba(37,99,235,.12), transparent 60%), radial-gradient(900px 400px at 100% 0%, rgba(6,182,212,.10), transparent 60%), var(--bg);
            font-family: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
            color: var(--text);
        }

        /* ====== layout RadWindow ====== */
        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column;
        }

        /* ====== sticky top bar ====== */
        .topbar {
            position: sticky;
            top: 0;
            z-index: 5;
            padding: 14px 14px 12px;
            border-bottom: 1px solid rgba(226,232,240,.9);
            background: rgba(255,255,255,.80);
            backdrop-filter: blur(10px);
            border-radius: 0 0 var(--r-lg) var(--r-lg); /* ✅ arrondi */
        }

        .topbar-inner {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .title-wrap {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }

        .badge {
            width: 42px;
            height: 42px;
            border-radius: var(--r-lg); /* ✅ */
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, rgba(37,99,235,.16), rgba(6,182,212,.14));
            border: 1px solid rgba(37,99,235,.18);
            box-shadow: var(--shadow2);
            user-select: none;
        }

            .badge svg {
                width: 19px;
                height: 19px;
                opacity: .92
            }

        .title {
            margin: 0;
            font-size: 16px;
            font-weight: 950;
            line-height: 1.1;
            letter-spacing: .2px;
        }

        .sub {
            margin-top: 4px;
            color: var(--muted);
            font-size: 12px;
        }

            .sub b {
                color: var(--text);
                font-weight: 900
            }

        .actions {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }

        /* ====== content ====== */
        .content {
            flex: 1;
            overflow: auto;
            padding: 14px;
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        /* ====== cards ====== */
        .card {
            background: rgba(255,255,255,.92);
            border: 1px solid rgba(226,232,240,.95);
            border-radius: var(--r-xl); /* ✅ */
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .card-header {
            padding: 12px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            background: linear-gradient(180deg, rgba(255,255,255,.88), rgba(255,255,255,.72));
            border-bottom: 1px solid rgba(226,232,240,.85);
        }

        .card-title {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .dot {
            width: 10px;
            height: 10px;
            border-radius: 999px;
            background: linear-gradient(180deg, var(--accent), var(--accent2));
            box-shadow: 0 8px 22px rgba(37,99,235,.22);
        }

        .card-title h3 {
            margin: 0;
            font-size: 13px;
            font-weight: 950;
            letter-spacing: .35px;
            text-transform: uppercase;
        }

        .card-hint {
            font-size: 12px;
            color: var(--muted);
            white-space: nowrap;
        }

        .card-body {
            padding: 14px;
        }

        /* ====== form grids ====== */
        .row2 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }

        .row3 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }

        .row4 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
        }

        .field label {
            display: block;
            font-size: 12px;
            color: var(--muted);
            margin: 0 0 6px 2px;
        }

        /* ====== pill ====== */
        .pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 7px 10px;
            border-radius: 999px; /* ✅ */
            border: 1px solid rgba(226,232,240,.95);
            background: rgba(255,255,255,.9);
            color: var(--muted);
            font-size: 12px;
            box-shadow: 0 10px 22px rgba(2,6,23,.06);
        }

            .pill b {
                color: var(--text);
                font-weight: 950
            }

        /* ====== mobile grid scroll for RadGrid ====== */
        .grid-scroll {
            width: 100%;
            overflow: auto;
            -webkit-overflow-scrolling: touch;
            border-radius: var(--r-lg); /* ✅ */
            border: 1px solid rgba(226,232,240,.95);
            background: #fff;
        }

        .grid-min {
            min-width: 980px;
        }

        @media (min-width: 980px) {
            .grid-min {
                min-width: 100%;
            }
        }

        /* ====== footer totals ====== */
        .footerbar {
            position: sticky;
            bottom: 0;
            z-index: 4;
            border-top: 1px solid rgba(226,232,240,.9);
            background: rgba(255,255,255,.82);
            backdrop-filter: blur(10px);
            padding: 12px 14px;
            border-radius: var(--r-lg) var(--r-lg) 0 0; /* ✅ */
        }

        .footer-inner {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            flex-wrap: wrap;
        }

        .totals {
            display: flex;
            gap: 14px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }

        .tot {
            min-width: 150px;
            padding: 10px 12px;
            border-radius: var(--r-lg); /* ✅ */
            background: rgba(255,255,255,.95);
            border: 1px solid rgba(226,232,240,.95);
            box-shadow: 0 10px 24px rgba(2,6,23,.06);
            display: flex;
            flex-direction: column;
            align-items: flex-end;
        }

            .tot .lbl {
                font-size: 12px;
                color: var(--muted)
            }

            .tot .val {
                font-weight: 950;
                font-size: 14px
            }

            .tot.total {
                border-color: rgba(37,99,235,.22);
                background: linear-gradient(180deg, rgba(37,99,235,.08), rgba(6,182,212,.06));
            }

        /* ====== Telerik rounding (important) ======
       On force des rayons sur les wrappers Telerik les plus courants */
        .RadInput .riTextBox,
        .RadInputMgr,
        .RadPicker .rcTable,
        .RadPicker .rcCalPopup,
        .RadComboBox,
        .RadComboBox .rcbInput,
        .RadDropDownList,
        .RadNumericTextBox .riTextBox,
        .RadGrid,
        .RadGrid .rgMasterTable,
        .RadGrid .rgHeader,
        .RadGrid .rgRow,
        .RadGrid .rgAltRow {
            border-radius: var(--r-md) !important; /* ✅ */
        }

        /* Spacing comfortable */
        .RadInput, .RadPicker, .RadComboBox, .RadDropDownList {
            width: 100% !important;
        }

        /* ====== responsive ====== */
        @media (min-width: 840px) {
            .row2 {
                grid-template-columns: 1fr 1fr;
            }

            .row3 {
                grid-template-columns: 1fr 1fr 1fr;
            }

            .row4 {
                grid-template-columns: 1.2fr 1fr 1fr 1fr;
            }
        }

        @media (max-width: 520px) {
            .actions > * {
                width: 100% !important;
            }

            .card-hint {
                display: none;
            }

            .tot {
                min-width: 140px;
                align-items: flex-start;
            }
        }
    </style>
</head>

<body>
    <form id="form1" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />

        <telerik:RadAjaxManager ID="Ram1" runat="server">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="btnSave">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="pnlMain" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="rgItems">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rgItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <!-- TOP -->
            <div class="topbar">
                <div class="topbar-inner">
                    <div class="title-wrap">
                        <div class="badge" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M7 7.5h10M7 11.5h10M7 15.5h6" stroke="rgba(15,23,42,.85)" stroke-width="2" stroke-linecap="round" />
                                <path d="M6.5 3.5h11A3.5 3.5 0 0 1 21 7v10a3.5 3.5 0 0 1-3.5 3.5h-11A3.5 3.5 0 0 1 3 17V7A3.5 3.5 0 0 1 6.5 3.5Z" stroke="rgba(15,23,42,.35)" stroke-width="1.8" />
                            </svg>
                        </div>
                        <div>
                            <h1 class="title">Édition de facture</h1>
                            <div class="sub">
                                No: <b>
                                    <asp:Label ID="lblInvoiceNo" runat="server" Text="(Auto)"></asp:Label></b>
                                &nbsp;•&nbsp; ID:
                                <asp:Label ID="lblInvoiceId" runat="server" Text=""></asp:Label>
                                &nbsp;•&nbsp; <span class="pill">Statut: <b>
                                    <asp:Label ID="lblStatusChip" runat="server" Text="Brouillon"></asp:Label></b></span>
                            </div>
                        </div>
                    </div>

                    <div class="actions">
                        <telerik:RadButton ID="btnSave" runat="server" Text="Enregistrer" Width="140px" />
                        <telerik:RadButton ID="btnSaveSend" runat="server" Text="Enregistrer &amp; Envoyer" Width="195px" />
                    </div>
                </div>
            </div>

            <!-- CONTENT -->
            <div class="content">
                <div class="container">

                    <!-- HEADER -->
                    <div class="card">


                        <div class="card-body">

                            <div class="row2">
                                <div class="field">
                                    <label>Client</label>
                                    <telerik:RadComboBox ID="ddlCustomer" runat="server"
                                        AutoPostBack="true"
                                        EmptyMessage="Sélectionner un client..."
                                        Filter="Contains"
                                        MarkFirstMatch="true"
                                        AllowCustomText="false"
                                        ShowMoreResultsBox="false"
                                        EnableLoadOnDemand="true"
                                         
                                        >



                                        <FooterTemplate>

                                            <div style="display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap;">

                                                <telerik:RadButton
                                                    ID="btnAddCustomer"
                                                    runat="server"
                                                    Text="+ Ajouter un client"
                                                    AutoPostBack="false" />

                                            </div>
                                        </FooterTemplate>
                                    </telerik:RadComboBox>
                                </div>

                                <div class="field">
                                    <div  style="height: 100%;display: flex; align-items: flex-end;">
                                    <telerik:RadLabel ID="rdLabel" runat="server"></telerik:RadLabel></div>
                                </div>

                              
                                 

                            </div>

                            <div style="height: 12px"></div>

                            <div class="row4">
                                <div class="field">
                                    <label>Date facture</label>
                                    <telerik:RadDatePicker ID="dpIssueDate" runat="server" />
                                </div>

                                <div class="field">
                                    <label>Date d’échéance</label>
                                    <telerik:RadDatePicker ID="dpDueDate" runat="server" />
                                </div>



                            </div>

                            <div style="height: 12px"></div>






                        </div>
                    </div>

                    <!-- ITEMS -->
                    <div class="card">
                        <div class="card-header">
                            <div class="card-title">
                                <span class="dot"></span>
                                <h3>Lignes</h3>
                            </div>
                            <div class="card-hint">Scroll horizontal sur mobile</div>
                        </div>

                        <div class="card-body">
                            <div class="grid-scroll">
                                <div class="grid-min">
                                    <telerik:RadGrid ID="rgItems" runat="server"
                                        Width="100%"
                                        Skin="Metro"
                                        AutoGenerateColumns="False"
                                        AllowPaging="True"
                                        PageSize="10"
                                        AllowSorting="True">

                                        <ClientSettings>
                                            <Scrolling AllowScroll="true" UseStaticHeaders="true" />
                                            <Selecting AllowRowSelect="false" />
                                        </ClientSettings>

                                        <MasterTableView DataKeyNames="LineId"
                                            CommandItemDisplay="Top"
                                            EditMode="InPlace"
                                            InsertItemPageIndexAction="ShowItemOnCurrentPage">

                                            <CommandItemSettings
                                                ShowAddNewRecordButton="True"
                                                AddNewRecordText="Ajouter une ligne"
                                                ShowRefreshButton="False"
                                                ShowExportToCsvButton="False"
                                                ShowExportToExcelButton="False"
                                                ShowExportToPdfButton="False" />

                                            <Columns>
                                                <telerik:GridEditCommandColumn ButtonType="LinkButton"
                                                    EditText="Modifier" UpdateText="OK" CancelText="Annuler" />

                                                <telerik:GridButtonColumn ButtonType="LinkButton" CommandName="Delete"
                                                    Text="Supprimer" ConfirmText="Supprimer cette ligne ?" />

                                                <telerik:GridTemplateColumn HeaderText="Code" UniqueName="ItemCode" HeaderStyle-Width="120px">
                                                    <ItemTemplate><%# Eval("ItemCode") %></ItemTemplate>
                                                    <EditItemTemplate>
                                                        <telerik:RadTextBox ID="txtItemCode" runat="server" Width="110px"
                                                            Text='<%# Bind("ItemCode") %>' />
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>

                                                <telerik:GridTemplateColumn HeaderText="Description" UniqueName="Description">
                                                    <ItemTemplate><%# Eval("Description") %></ItemTemplate>
                                                    <EditItemTemplate>
                                                        <telerik:RadTextBox ID="txtDesc" runat="server" Width="100%"
                                                            TextMode="MultiLine" Rows="2"
                                                            Text='<%# Bind("Description") %>' />
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>

                                                <telerik:GridTemplateColumn HeaderText="Qty" UniqueName="Qty" HeaderStyle-Width="90px" ItemStyle-HorizontalAlign="Right">
                                                    <ItemTemplate><%# Eval("Qty","{0:0.####}") %></ItemTemplate>
                                                    <EditItemTemplate>
                                                        <telerik:RadNumericTextBox ID="numQty" runat="server" Width="90px"
                                                            Value='<%# Bind("Qty") %>' MinValue="0">
                                                            <NumberFormat DecimalDigits="4" />
                                                        </telerik:RadNumericTextBox>
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>

                                                <telerik:GridTemplateColumn HeaderText="Prix unité" UniqueName="UnitPrice" HeaderStyle-Width="120px" ItemStyle-HorizontalAlign="Right">
                                                    <ItemTemplate><%# Eval("UnitPrice","{0:N2}") %></ItemTemplate>
                                                    <EditItemTemplate>
                                                        <telerik:RadNumericTextBox ID="numUnitPrice" runat="server" Width="120px"
                                                            Value='<%# Bind("UnitPrice") %>' MinValue="0">
                                                            <NumberFormat DecimalDigits="2" />
                                                        </telerik:RadNumericTextBox>
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>

                                                <telerik:GridTemplateColumn HeaderText="Taxable" UniqueName="Taxable" HeaderStyle-Width="90px" ItemStyle-HorizontalAlign="Center">
                                                    <ItemTemplate>
                                                        <asp:CheckBox ID="chkTaxableView" runat="server" Enabled="false" Checked='<%# Eval("Taxable") %>' />
                                                    </ItemTemplate>
                                                    <EditItemTemplate>
                                                        <asp:CheckBox ID="chkTaxable" runat="server" Checked='<%# Bind("Taxable") %>' />
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>

                                                <telerik:GridTemplateColumn HeaderText="Total ligne" UniqueName="LineTotal" HeaderStyle-Width="130px" ItemStyle-HorizontalAlign="Right">
                                                    <ItemTemplate><%# Eval("LineTotal","{0:N2}") %></ItemTemplate>
                                                    <EditItemTemplate>
                                                        <asp:Label ID="lblLineTotalEdit" runat="server" Text="(auto)" />
                                                    </EditItemTemplate>
                                                </telerik:GridTemplateColumn>
                                            </Columns>
                                        </MasterTableView>
                                    </telerik:RadGrid>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <!-- FOOTER TOTALS -->
            <div class="footerbar">
                <div class="footer-inner">
                    <div class="pill">Totaux</div>

                    <div class="totals">
                        <div class="tot">
                            <div class="lbl">Sous-total</div>
                            <div class="val">
                                <asp:Label ID="lblSubTotal" runat="server" Text="0.00" />
                            </div>
                        </div>
                        <div class="tot">
                            <div class="lbl">TPS</div>
                            <div class="val">
                                <asp:Label ID="lblTax1" runat="server" Text="0.00" />
                            </div>
                        </div>
                        <div class="tot">
                            <div class="lbl">TVQ</div>
                            <div class="val">
                                <asp:Label ID="lblTax2" runat="server" Text="0.00" />
                            </div>
                        </div>
                        <div class="tot total">
                            <div class="lbl">Total</div>
                            <div class="val">
                                <asp:Label ID="lblTotal" runat="server" Text="0.00" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </asp:Panel>
    </form>
</body>
</html>
