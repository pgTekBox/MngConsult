<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfSupplierInvoinceEdit.aspx.vb" Inherits="MngConsul.wbfSupplierInvoinceEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Facture fournisseur — Édition</title>

    <style>
        /* =============================================
           VARIABLES
        ============================================= */
        :root {
            --bg: #f6f8fc;
            --card: #fff;
            --text: #0f172a;
            --radius: var(--r-lg);
            --muted: #64748b;
            --line: #e2e8f0;
            --accent: #2563eb;
            --accent2: #06b6d4;
            --supplier: #7c3aed;        /* violet — couleur distincte fournisseur */
            --supplier-weak: #f5f3ff;
            --r-md: 14px;
            --r-lg: 18px;
            --r-xl: 22px;
            --shadow: 0 18px 50px rgba(2,6,23,.10);
        }

        html, body, form { height: 100%; }

        body {
            margin: 0;
            background: var(--bg);
            font-family: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
            color: var(--text);
        }

        /* =============================================
           LAYOUT
        ============================================= */
        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column;
        }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 5;
            padding: 12px 16px;
            background: rgba(255,255,255,.92);
            border-bottom: 1px solid var(--line);
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .topbar-title {
            font-size: 16px;
            font-weight: 900;
            flex: 1;
        }

        /* Badge "Fournisseur" */
        .badge-supplier {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 800;
            background: var(--supplier-weak);
            color: var(--supplier);
            border: 1px solid rgba(124,58,237,.2);
        }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px;
            padding-bottom: 90px;
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        /* =============================================
           CARD
        ============================================= */
        .card {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--r-xl);
            box-shadow: var(--shadow);
        }

        .card-header {
            padding: 12px 14px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid var(--line);
        }

        .card-body { padding: 14px; }

        /* =============================================
           GRILLES FORMULAIRE
        ============================================= */
        .row2 { display: grid; gap: 12px; }
        .row4 { display: grid; gap: 12px; }

        /* =============================================
           SÉLECTEURS (fournisseur / produit)
        ============================================= */
        .supplier-selector {
            display: block;
            width: 100%;
            min-height: 38px;
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: var(--supplier-weak);
            cursor: pointer;
            font-weight: 700;
            color: var(--supplier);
        }
        .supplier-selector::after { content: "▾"; float: right; color: var(--supplier); }
        .supplier-selector:active  { background: #ede9fe; }

        .product-selector {
            display: block;
            width: 100%;
            min-height: 38px;
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: #fff;
            cursor: pointer;
        }
        .product-selector::after { content: "▾"; float: right; color: #64748b; }
        .product-selector:active  { background: #f1f5f9; }

        /* =============================================
           OVERLAYS (picker)
        ============================================= */
        .supplier-picker-overlay,
        .product-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15,23,42,.35);
        }

        .supplier-picker-shell,
        .product-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 14px;
            border-bottom: 1px solid var(--line);
        }

        .picker-input {
            flex: 1;
            height: 44px;
            padding: 0 12px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            box-sizing: border-box;
            font-size: 16px;
        }

        .picker-close-btn {
            margin-left: auto;
            width: 44px;
            height: 44px;
            flex: 0 0 44px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            background: #fff;
            font-size: 20px;
            line-height: 1;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .picker-close-btn:active { background: #f8fafc; }

        .picker-list {
            flex: 1 1 auto;
            min-height: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .list-shell {
            flex: 1 1 auto;
            min-height: 0;
            display: flex;
            flex-direction: column;
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .lv-footer {
            flex: 0 0 auto;
            padding: 14px 16px;
            background: #fff;
            border-top: 1px solid var(--line);
            text-align: right;
        }

        .items-wrap {
            flex: 1 1 auto;
            min-height: 0;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
            padding: 14px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 14px;
        }

        /* Carte produit dans le picker */
        .product-card {
            display: grid;
            grid-template-columns: 1fr auto;
            align-items: center;
            gap: 10px;
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }
        .product-name  { font-size: 15px; font-weight: 600; }
        .product-price { font-size: 16px; font-weight: 800; color: var(--accent); text-align: right; }

        /* Carte fournisseur dans le picker */
        .supplier-card {
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }
        .supplier-name    { font-size: 16px; font-weight: 800; color: var(--supplier); }
        .supplier-billing { font-size: 15px; font-weight: 600; }

        .empty { padding: 24px; color: var(--muted); text-align: center; }

        /* =============================================
           ITEMS (lignes de facture)
        ============================================= */
        .items-header { display: none; }

        .item-row {
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            background: #fff;
        }

        .qty-right input { text-align: right !important; }

        /* =============================================
           FOOTER TOTAUX
        ============================================= */
        .footerbar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid var(--line);
            padding: 8px 14px;
        }

        .RadInput, .RadPicker, .RadComboBox, .RadNumericTextBox {
            width: 100% !important;
        }

        .RadComboBoxDropDown, .rcbSlide {
            max-height: 220px !important;
            overflow-y: auto !important;
            overflow-x: hidden !important;
            -webkit-overflow-scrolling: touch !important;
            touch-action: pan-y !important;
        }

        /* FAB ajouter ligne */
        .fab-addline {
            position: fixed;
            right: 22px;
            bottom: 22px;
            z-index: 2000;
        }
        .fab-addline, .fab-addline span, .fab-addline img { display: block; }
        .fab-addline img { width: 56px; height: 56px; }

        /* Champ No référence fournisseur */
        .field-refno label {
            display: block;
            font-size: 12px;
            color: #334155;
            margin-bottom: 6px;
            font-weight: 700;
        }

        /* =============================================
           RESPONSIVE — TABLETTE 769–1024px
        ============================================= */
        @media (min-width: 769px) and (max-width: 1024px) {
            .row2 { grid-template-columns: 1fr 1fr; }
            .row4 { grid-template-columns: 1fr 1fr 1fr 1fr; }

            .items-header {
                display: grid;
                grid-template-columns: 140px 1fr 90px 90px 100px 120px;
                border: 1px solid var(--line);
                border-radius: var(--r-lg);
                overflow: hidden;
                margin-bottom: 8px;
            }
            .items-header div {
                padding: 10px;
                font-size: 12px;
                font-weight: 900;
                color: var(--muted);
                background: #f8fafc;
                border-right: 1px solid var(--line);
            }

            .item-grid {
                display: grid;
                grid-template-columns: 140px 1fr 90px 90px 100px 120px;
            }

            .cell {
                padding: 10px;
                border-bottom: 1px solid var(--line);
                border-right: 1px solid var(--line);
            }

            .m-label     { display: none; }
            .m-labelmoney { display: none; }

            .totals {
                display: flex;
                gap: 14px;
                flex-wrap: wrap;
                justify-content: flex-end;
            }

            .tot {
                min-width: 150px;
                padding: 10px;
                border: 1px solid var(--line);
                border-radius: var(--r-lg);
                text-align: right;
            }
        }

        /* =============================================
           RESPONSIVE — MOBILE ≤480px
        ============================================= */
        @media (max-width: 480px) {
            .fab-addline { right: 14px; bottom: 14px; }
            .fab-addline img { width: 52px; height: 52px; }
            .content { padding-bottom: 84px; }

            .RadComboBoxDropDown, .rcbSlide {
                max-width: calc(100vw - 24px) !important;
                box-sizing: border-box !important;
            }

            .item-grid {
                display: flex;
                flex-direction: column;
                gap: 10px;
                padding: 12px;
            }

            .cell { border: none; padding: 0; width: 100%; min-width: 0; }

            .m-label {
                display: block;
                font-size: 11px;
                color: var(--muted);
                margin-bottom: 4px;
                text-align: left;
            }
            .m-labelmoney {
                display: block;
                font-size: 14px;
                color: var(--text);
                margin-bottom: 4px;
                text-align: left;
            }

            .cellGrid3 {
                border: none;
                padding: 0;
                display: grid;
                grid-template-columns: 1fr 1fr 1fr;
            }

            .totals {
                display: grid;
                grid-template-columns: 1fr 85px 85px;
            }

            .tot { text-align: right; }

            .imgaction { margin-left: 14px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">

        <%-- ===== TELERIK GLOBAL ===== --%>
        <telerik:RadScriptManager
            ID="RadScriptManager1"
            runat="server"
            EnablePartialRendering="true"
            AsyncPostBackTimeout="300" />

        <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro" />

        <telerik:RadAjaxManager ID="Ram1" runat="server">
            <AjaxSettings>

                <%-- Refresh du label fournisseur + label adresse + lignes --%>
                <telerik:AjaxSetting AjaxControlID="Ram1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSupplier" />
                        <telerik:AjaxUpdatedControl ControlID="rdLabel" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <%-- Bouton ajouter ligne --%>
                <telerik:AjaxSetting AjaxControlID="btnAddLine">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

                <%-- Repeater lignes --%>
                <telerik:AjaxSetting AjaxControlID="rpItems">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="rpItems" />
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                    </UpdatedControls>
                </telerik:AjaxSetting>

            </AjaxSettings>
        </telerik:RadAjaxManager>

        <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

            <%-- ===== TOPBAR ===== --%>
            <div class="topbar">
                <span class="topbar-title">Facture fournisseur</span>
                <span class="badge-supplier">🏭 Fournisseur</span>
                <telerik:RadButton ID="radSave" runat="server" Text="Enregistrer" />
            </div>

            <%-- ===== CONTENU ===== --%>
            <div class="content">
                <div class="container">

                    <%-- CARD : EN-TÊTE FACTURE --%>
                    <div class="card">
                        <div class="card-header">
                            <strong>Informations de la facture</strong>
                            <%-- Numéro de facture fournisseur (référence externe) --%>
                            <div class="field-refno">
                                <label>No facture fournisseur</label>
                                <telerik:RadTextBox ID="txtRefNo" runat="server"
                                    RenderMode="Lightweight"
                                    EmptyMessage="Référence fournisseur…"
                                    Width="200px" />
                            </div>
                        </div>

                        <div class="card-body">

                            <div class="row2">
                                <%-- Sélecteur fournisseur (picker comme le customer picker de l'original) --%>
                                <div>
                                    <label>Fournisseur</label>
                                    <asp:Label ID="lblSupplier" runat="server"
                                        CssClass="supplier-selector"
                                        Text="Sélectionner un fournisseur" />
                                </div>

                                <%-- Adresse de facturation fournisseur --%>
                                <div>
                                    <div style="height:100%;display:flex;align-items:flex-end;">
                                        <telerik:RadLabel ID="rdLabel" runat="server" />
                                    </div>
                                </div>
                            </div>

                            <div style="height:12px;"></div>

                            <%-- Dates + No PO --%>
                            <div class="row4">
                                <div>
                                    <label>Date facture</label>
                                    <telerik:RadDatePicker ID="dpIssueDate" runat="server" />
                                </div>
                                <div>
                                    <label>Date d'échéance</label>
                                    <telerik:RadDatePicker ID="dpDueDate" runat="server" />
                                </div>
                                <div>
                                    <label>Date de réception</label>
                                    <telerik:RadDatePicker ID="dpReceivedDate" runat="server" />
                                </div>
                                <div>
                                    <label>No bon de commande</label>
                                    <telerik:RadTextBox ID="txtPoNumber" runat="server"
                                        RenderMode="Lightweight"
                                        EmptyMessage="PO-…" />
                                </div>
                            </div>

                        </div>
                    </div>

                    <%-- CARD : LIGNES --%>
                    <div class="card">
                        <div class="card-header">
                            <strong>Lignes de facture</strong>
                        </div>

                        <div class="card-body">

                            <%-- Entête colonnes desktop --%>
                            <div class="items-header">
                                <div>Produit / Service</div>
                                <div>Description</div>
                                <div style="text-align:right;">Qté</div>
                                <div style="text-align:right;">Prix unit.</div>
                                <div style="text-align:right;">Total</div>
                                <div style="text-align:center;">Action</div>
                            </div>

                            <div class="items-wrap">
                                <%-- Repeater des lignes — même structure que wbfInvoiceEdit --%>
                                <asp:Repeater ID="rpItems" runat="server">
                                    <ItemTemplate>

                                        <div class="item-row">
                                            <div class="item-grid">
                                                <asp:HiddenField ID="hidId" runat="server"
                                                    Value='<%# Eval("Id") %>' />

                                                <%-- Produit --%>
                                                <div class="cell">
                                                    <div class="m-label">Produit</div>
                                                    <asp:Label ID="lblProduct" runat="server"
                                                        CssClass="product-selector"
                                                        Text='<%# Eval("ProductName") %>' />
                                                    <asp:HiddenField ID="hidProductId" runat="server"
                                                        Value='<%# Eval("ProductId") %>' />
                                                </div>

                                                <%-- Description --%>
                                                <div class="cell">
                                                    <div class="m-label">Description</div>
                                                    <telerik:RadTextBox ID="txtDesc" runat="server"
                                                        TextMode="MultiLine" Rows="2"
                                                        Text='<%# Eval("Description") %>' />
                                                </div>

                                                <%-- Quantité --%>
                                                <div class="cellGrid3" style="text-align:right;">
                                                    <span class="m-labelmoney">Qté</span>
                                                    <span></span>
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numQty" runat="server"
                                                            Text='<%# FormatQty(Eval("Qty")) %>'
                                                            CssClass="num-right"
                                                            oninput="fixNumber(this)"
                                                            onblur="formatQtyOnBlur(this)"
                                                            onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <%-- Prix unitaire --%>
                                                <div class="cellGrid3" style="text-align:right;">
                                                    <span class="m-labelmoney">Prix unit.</span>
                                                    <span></span>
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numUnitPrice" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("UnitPrice")) %>'
                                                            CssClass="num-right"
                                                            oninput="fixNumber(this)"
                                                            onblur="formatPrice(this)"
                                                            onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <%-- Montant ligne --%>
                                                <div class="cellGrid3" style="text-align:right;">
                                                    <div class="m-labelmoney">Total</div>
                                                    <span></span>
                                                    <asp:Label ID="lblAmount" runat="server"
                                                        CssClass="lbl-amount"
                                                        Text='<%# Eval("Amount","{0:N2}") %>' />
                                                </div>

                                                <%-- Actions --%>
                                                <div class="cell actions" style="text-align:center;">
                                                    <telerik:RadImageButton ID="btnDeleteLine"
                                                        runat="server"
                                                        CssClass="imgaction"
                                                        Text=""
                                                        Width="25px" Height="35px"
                                                        Image-Url="~/Images/del200.png"
                                                        Image-Sizing="Stretch"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClicking="function(s,e){ if(!confirm('Supprimer cette ligne ?')) e.set_cancel(true); }">
                                                    </telerik:RadImageButton>

                                                    <telerik:RadImageButton ID="btnMoveUp"
                                                        runat="server"
                                                        CssClass="imgaction"
                                                        Text=""
                                                        Width="25px" Height="35px"
                                                        Image-Url="~/Images/flechehaut.png"
                                                        Image-Sizing="Stretch"
                                                        CommandName="Up"
                                                        CommandArgument='<%# Eval("Id") %>'>
                                                    </telerik:RadImageButton>

                                                    <telerik:RadImageButton ID="btnMoveDown"
                                                        runat="server"
                                                        CssClass="imgaction"
                                                        Text=""
                                                        Width="25px" Height="35px"
                                                        Image-Url="~/Images/flechebas.png"
                                                        Image-Sizing="Stretch"
                                                        CommandName="Down"
                                                        CommandArgument='<%# Eval("Id") %>'>
                                                    </telerik:RadImageButton>
                                                </div>

                                            </div>
                                        </div>

                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>

                        </div>
                    </div>

                </div>
            </div>

            <%-- ===== FOOTER TOTAUX ===== --%>
            <div class="footerbar">
                <div class="totals">
                    <div class="tot"><asp:Label ID="lblCapSubTotal" runat="server" Text="Sous-total" /></div>
                    <div class="tot"><strong><asp:Label ID="lblSubTotal" runat="server" Text="0.00" /></strong></div>
                    <div class="tot">TPS</div>
                    <div class="tot"><strong><asp:Label ID="lblTax1" runat="server" Text="0.00" /></strong></div>
                    <div class="tot">TVQ</div>
                    <div class="tot"><strong><asp:Label ID="lblTax2" runat="server" Text="0.00" /></strong></div>
                    <div class="tot">Total</div>
                    <div class="tot"><strong><asp:Label ID="lblTotal" runat="server" Text="0.00" /></strong></div>
                </div>
            </div>

            <%-- ===== FAB ajouter ligne ===== --%>
            <div class="fab-addline">
                <telerik:RadImageButton ID="btnAddLine"
                    runat="server"
                    Image-Url="~/Images/rondplus45.png"
                    Width="56px" Height="56px"
                    ToolTip="Ajouter une ligne">
                </telerik:RadImageButton>
            </div>

            <%-- ===== HIDDEN FIELDS ===== --%>
            <asp:HiddenField ID="hidSelectedProductId" runat="server" />
            <asp:HiddenField ID="hidSelectedSupplierId" runat="server" />

            <%-- ===== OVERLAY PRODUITS ===== --%>
            <div id="productPickerOverlay" class="product-picker-overlay" style="display:none;">
                <div class="product-picker-shell">

                    <div class="picker-searchbar">
                        <input type="text" id="productPickerSearch"
                            class="picker-input"
                            oninput="filterProductsClient()"
                            placeholder="Rechercher un produit…" />
                        <button type="button" class="picker-close-btn"
                            onclick="closeProductPicker()" aria-label="Fermer">✕</button>
                    </div>

                    <div id="productPickerList" class="picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvProducts" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemPlaceholder"
                                OnNeedDataSource="rlvProducts_NeedDataSource">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemPlaceholder" runat="server" />
                                    </div>
                                    <div class="lv-footer">
                                        <telerik:RadButton ID="btnAddProducts" runat="server"
                                            Text="Ajouter des produits"
                                            OnClick="btnAddProducts_Click" />
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="product-card"
                                        data-search='<%# Eval("Name").ToString().ToLower() %>'
                                        onclick="selectProduct('<%# Eval("Code") %>')">
                                        <div class="product-name"><%# Eval("Name") %></div>
                                        <div class="product-price"><%# Eval("Prix","{0:C2}") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty">Aucun produit trouvé.</div>
                                </EmptyDataTemplate>

                            </telerik:RadListView>
                        </div>
                    </div>

                </div>
            </div>

            <%-- ===== OVERLAY FOURNISSEURS ===== --%>
            <div id="supplierPickerOverlay" class="supplier-picker-overlay" style="display:none;">
                <div class="supplier-picker-shell">

                    <div class="picker-searchbar">
                        <input type="text" id="supplierPickerSearch"
                            class="picker-input"
                            oninput="filterSuppliersClient()"
                            placeholder="Rechercher un fournisseur…" />
                        <button type="button" class="picker-close-btn"
                            onclick="closeSupplierPicker()" aria-label="Fermer">✕</button>
                    </div>

                    <div id="supplierPickerList" class="picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvSuppliers" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemSupplierPlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemSupplierPlaceholder" runat="server" />
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="supplier-card"
                                        data-search='<%# Eval("search").ToString().ToLower() %>'
                                        onclick="selectSupplier('<%# Eval("Id") %>')">
                                        <div class="supplier-name"><%# Eval("ContactName") %></div>
                                        <div class="supplier-billing"><%# Eval("BillingTo") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty">Aucun fournisseur trouvé.</div>
                                </EmptyDataTemplate>

                            </telerik:RadListView>
                        </div>
                    </div>

                </div>
            </div>

        </asp:Panel>

        <%-- =====================================================
             JAVASCRIPT
        ===================================================== --%>
        <script type="text/javascript">

            // ===== UTILITAIRES NUMÉRIQUES =====

            function trimZeros(s) {
                s = (s || "").toString().trim();
                if (s === "") return "";
                if (s.endsWith(".")) s = s.slice(0, -1);
                if (s.indexOf(".") >= 0) {
                    s = s.replace(/0+$/, "");
                    s = s.replace(/\.$/, "");
                }
                return s;
            }

            function formatQtyOnBlur(el) {
                fixNumber(el);
                el.value = trimZeros(el.value);
            }

            function formatPrice(el) {
                fixNumber(el);
                var v = el.value;
                if (v === "") return;
                var n = parseFloat(v);
                if (isNaN(n)) { el.value = ""; return; }
                var dec = n.toFixed(2);
                if (dec.endsWith(".00")) { el.value = parseInt(n); return; }
                if (dec.match(/\.\d$/)) { el.value = dec + "0"; return; }
                el.value = dec;
            }

            function fixNumber(el) {
                var v = (el.value || "").replace(/,/g, ".");
                v = v.replace(/[^0-9.]/g, "");
                var firstDot = v.indexOf(".");
                if (firstDot !== -1) {
                    var left = v.substring(0, firstDot);
                    var right = v.substring(firstDot + 1).replace(/\./g, "").substring(0, 2);
                    v = left + "." + right;
                }
                el.value = v;
            }

            // ===== CALCUL TAXES =====

            var TAX_TPS = 0.05;
            var TAX_TVQ = 0.09975;

            function toNum(v) {
                if (v == null) return 0;
                v = ("" + v).replace(/\s/g, "").replace(",", ".");
                var n = parseFloat(v);
                return isNaN(n) ? 0 : n;
            }

            function fmt2(n) {
                n = (isNaN(n) || n == null) ? 0 : n;
                return n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            }

            function recalcRow(row) {
                var qtyEl = row.querySelector("input[id*='numQty']");
                var prEl  = row.querySelector("input[id*='numUnitPrice']");
                if (!qtyEl || !prEl) return 0;
                var amt = Math.round(toNum(qtyEl.value) * toNum(prEl.value) * 100) / 100;
                var lbl = row.querySelector(".lbl-amount");
                if (lbl) lbl.innerText = fmt2(amt);
                return amt;
            }

            function recalcTotals() {
                var subtotal = 0;
                document.querySelectorAll(".item-row").forEach(function (row) {
                    if (row.getAttribute("data-deleted") === "1") return;
                    subtotal += recalcRow(row);
                });
                subtotal = Math.round(subtotal * 100) / 100;
                var tps   = Math.round(subtotal * TAX_TPS * 100) / 100;
                var tvq   = Math.round(subtotal * TAX_TVQ * 100) / 100;
                var total = Math.round((subtotal + tps + tvq) * 100) / 100;

                var elSub = document.getElementById("<%= lblSubTotal.ClientID %>");
                var elTps = document.getElementById("<%= lblTax1.ClientID %>");
                var elTvq = document.getElementById("<%= lblTax2.ClientID %>");
                var elTot = document.getElementById("<%= lblTotal.ClientID %>");

                if (elSub) elSub.innerText = fmt2(subtotal);
                if (elTps) elTps.innerText = fmt2(tps);
                if (elTvq) elTvq.innerText = fmt2(tvq);
                if (elTot) elTot.innerText = fmt2(total);
            }

            function wireInvoiceInputs() {
                document.querySelectorAll(".item-row input[id*='numQty'], .item-row input[id*='numUnitPrice']")
                    .forEach(function (inp) {
                        if (inp.dataset.wired === "1") return;
                        inp.dataset.wired = "1";
                        inp.addEventListener("input", function () {
                            var row = inp.closest(".item-row");
                            if (row) { recalcRow(row); recalcTotals(); }
                        });
                        inp.addEventListener("keyup", function () {
                            var row = inp.closest(".item-row");
                            if (row) { recalcRow(row); recalcTotals(); }
                        });
                    });
                recalcTotals();
            }

            document.addEventListener("DOMContentLoaded", function () { wireInvoiceInputs(); });
            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(function () { wireInvoiceInputs(); });
            }

            // ===== PICKER PRODUITS =====

            var currentProductLabel = null;
            var currentItemId = null;

            function openProductPicker(label, itemId) {
                currentItemId = itemId;
                currentProductLabel = label;
                document.getElementById("productPickerOverlay").style.display = "block";
            }

            function closeProductPicker() {
                document.getElementById("productPickerOverlay").style.display = "none";
                currentProductLabel = null;
            }

            function selectProduct(productCode) {
                document.getElementById("<%= hidSelectedProductId.ClientID %>").value = productCode;
                closeProductPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('PRODUCT|' + currentItemId.toString() + '|' + productCode.toString());
            }

            function normalizeText(str) {
                return (str || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
            }

            function filterProductsClient() {
                var q = normalizeText((document.getElementById("productPickerSearch") || {}).value || "");
                var visible = 0;
                document.querySelectorAll("#productPickerList .product-card").forEach(function (card) {
                    var show = q === "" || normalizeText(card.getAttribute("data-search")).indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                    if (show) visible++;
                });
                toggleEmptyMsg("productPickerEmptyJs", "productPickerList", "Aucun produit trouvé.", visible === 0);
            }

            // ===== PICKER FOURNISSEURS =====

            var currentSupplierLabel = null;

            function openSupplierPicker(label) {
                currentSupplierLabel = label;
                document.getElementById("supplierPickerOverlay").style.display = "block";
            }

            function closeSupplierPicker() {
                document.getElementById("supplierPickerOverlay").style.display = "none";
                currentSupplierLabel = null;
            }

            function selectSupplier(supplierId) {
                document.getElementById("<%= hidSelectedSupplierId.ClientID %>").value = supplierId;
                closeSupplierPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('SUPPLIER|' + supplierId.toString());
            }

            function filterSuppliersClient() {
                var q = normalizeText((document.getElementById("supplierPickerSearch") || {}).value || "");
                var visible = 0;
                document.querySelectorAll("#supplierPickerList .supplier-card").forEach(function (card) {
                    var show = q === "" || normalizeText(card.getAttribute("data-search")).indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                    if (show) visible++;
                });
                toggleEmptyMsg("supplierPickerEmptyJs", "supplierPickerList", "Aucun fournisseur trouvé.", visible === 0);
            }

            // ===== HELPER message vide =====
            function toggleEmptyMsg(msgId, listId, text, show) {
                var list = document.getElementById(listId);
                if (!list) return;
                var empty = document.getElementById(msgId);
                if (!empty) {
                    empty = document.createElement("div");
                    empty.id = msgId;
                    empty.className = "empty";
                    empty.innerText = text;
                    empty.style.display = "none";
                    list.appendChild(empty);
                }
                empty.style.display = show ? "block" : "none";
            }

        </script>

    </form>
</body>
</html>
