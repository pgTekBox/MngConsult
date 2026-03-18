<%@ Page Language="vb" AutoEventWireup="false"   MaintainScrollPositionOnPostback="true" CodeBehind="wbfInvoiceEdit.aspx.vb" Inherits="MngConsul.wbfInvoiceEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
 <!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>


    <style>
        :root {
            --bg: #f6f8fc;
            --card: #fff;
            --text: #0f172a;
            --radius: var(--r-lg);
            --muted: #64748b;
            --line: #e2e8f0;
            --accent: #2563eb;
            --accent2: #06b6d4;
            --r-md: 14px;
            --r-lg: 18px;
            --r-xl: 22px;
            --shadow: 0 18px 50px rgba(2,6,23,.10);
        }

        html, body, form {
            height: 100%
        }

        body {
            margin: 0;
            background: var(--bg);
            font-family: system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
            color: var(--text);
        }


        .product-selector::after {
            content: "▾";
            float: right;
            color: #64748b;
        }

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

            .product-selector:active {
                background: #f1f5f9;
            }

        .customer-selector::after {
            content: "▾";
            float: right;
            color: #64748b;
        }

        .customer-selector {
            display: block;
            width: 100%;
            min-height: 38px;
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: #fff;
            cursor: pointer;
        }

            .customer-selector:active {
                background: #f1f5f9;
            }


        .product-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .customer-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .product-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .customer-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }

        .product-picker-title {
            font-size: 18px;
            font-weight: 800;
        }

        .product-picker-search,
.customer-picker-searchbar {
    display: flex;
    align-items: center;
    gap: 10px;
}






        .product-picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
        }
       


      
       

        .product-picker-close {
            border: 0;
            background: transparent;
            font-size: 24px;
            cursor: pointer;
        }

        

       .product-picker-close-inline,
.customer-picker-close-inline {
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

            .product-picker-close-inline:active {
                background: #f8fafc;
            }
            .customer-picker-close-inline:active {
                background: #f8fafc;
            }




.product-picker-input,
.customer-picker-input {
    width: 100%;
    max-width: 200px;
    min-width: 0;
    height: 44px;
    padding: 0 12px;
    border: 1px solid #cbd5e1;
    border-radius: 12px;
    box-sizing: border-box;
    font-size: 16px;
}

        .product-picker-list {
            flex: 1 1 auto;
            min-height: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .customer-picker-list {
            flex: 1 1 auto;
            min-height: 0;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        .product-picker-item {
            padding: 14px 16px;
            border-bottom: 1px solid #f1f5f9;
            cursor: pointer;
        }

            .product-picker-item:active {
                background: #f8fafc;
            }





        /* layout */
        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column
        }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 5;
            padding: 14px;
            background: rgba(255,255,255,.9);
            border-bottom: 1px solid var(--line);
        }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px
        }

        .container {
            max-width: 1100px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px
        }

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

        .card-body {
            padding: 14px
        }

        .row2 {
            display: grid;
            gap: 12px
        }

        .row4 {
            display: grid;
            gap: 12px
        }

        .qty-right input {
            text-align: right !important;
        }





        /* ========= ITEMS RESPONSIVE ========= */



        .items-header {
            display: none
        }


        .item-row {
            border: 1px solid var(--line);
            border-radius: var(--r-lg);
            background: #fff;
        }
        /* footer totals */
        .footerbar {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid var(--line);
            padding: 8px 14px;
        }

        .RadComboBoxDropDown,
        .rcbSlide {
            max-height: 220px !important;
            overflow-y: auto !important;
            overflow-x: hidden !important;
            -webkit-overflow-scrolling: touch !important;
            touch-action: pan-y !important;
        }




        .RadInput, .RadPicker, .RadComboBox, .RadNumericTextBox {
            width: 100% !important
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

        .lv-header,
        .lv-footer {
            padding: 14px 16px;
            background: #fff;
        }

        .lv-header {
            border-bottom: 1px solid var(--line);
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }

        .lv-footer {
            flex: 0 0 auto;
            position: sticky;
            bottom: 0;
            z-index: 3;
            padding: 14px 16px;
            background: #fff;
            border-top: 1px solid var(--line);
            text-align: right;
        }

        .search-box {
            flex: 1;
            min-width: 240px;
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

        .customer-card {
            align-items: center;
            gap: 10px;
            border: 1px solid var(--line);
            border-radius: 12px;
            padding: 12px 14px;
            background: #fff;
            cursor: pointer;
        }


        .product-name {
            font-size: 15px;
            font-weight: 600;
        }

        .Contact-name {
            font-size: 16px;
            font-weight: 800;
            color: var(--accent);
        }

        .product-meta {
            color: var(--muted);
            font-size: 13px;
            margin-bottom: 6px;
        }

        .product-price {
            font-size: 16px;
            font-weight: 800;
            color: var(--accent);
            text-align: right;
        }

        .BillingTo {
            font-size: 15px;
            font-weight: 600;
        }

        .empty {
            padding: 24px;
            color: var(--muted);
            text-align: center;
        }

        .btn-add {
            min-width: 180px;
        }

        .fab-addline {
            position: fixed;
            right: 22px;
            bottom: 22px;
            z-index: 2000;
        }

            .fab-addline,
            .fab-addline span,
            .fab-addline img {
                display: block;
            }

                .fab-addline img {
                    width: 56px;
                    height: 56px;
                }

        .content {
            flex: 1;
            overflow: auto;
            padding: 14px;
            padding-bottom: 90px;
        }



        /* =========================
            TABLETTE — 769px à 1024px
         ========================= */
        @media (min-width: 769px) and (max-width: 1024px) {


            .imgaction {
                margin-left: 4px;
            }





            .totals {
                display: flex;
                gap: 14px;
                flex-wrap: wrap;
                justify-content: flex-end;
            }


            .row2 {
                grid-template-columns: 1fr 1fr
            }

            .row4 {
                grid-template-columns: 1fr 1fr 1fr 1fr
            }



            .qty-right input {
                text-align: right !important;
            }

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



            .m-label {
                display: none
            }

            .m-labelmoney {
                display: none
            }

            .tot {
                min-width: 150px;
                padding: 10px;
                border: 1px solid var(--line);
                border-radius: var(--r-lg);
                text-align: right;
            }
        }

        /* =========================
             MOBILE LARGE  grands smartphones en portrait
         ========================= */
        @media (min-width: 481px) and (max-width: 768px) {

            
        }




        /* =========================
         PETIT MOBILE — max 480px
           ========================= */
        @media (max-width: 480px) {


            .fab-addline {
                right: 14px;
                bottom: 14px;
            }

                .fab-addline img {
                    width: 52px;
                    height: 52px;
                }

            .content {
                padding-bottom: 84px;
            }



            .RadComboBoxDropDown,
            .rcbSlide {
                max-width: calc(100vw - 24px) !important;
                box-sizing: border-box !important;
            }


            .item-grid {
                display: flex;
                flex-direction: column;
                gap: 10px;
                padding: 12px;
            }

            .cell {
                border: none;
                padding: 0;
                width: 100%;
                min-width: 0;
            }



            .RadComboBoxDropDown,
            .rcbSlide {
                max-width: calc(100vw - 24px) !important;
                box-sizing: border-box !important;
            }



            .imgaction {
                margin-left: 14px;
            }





            .qty-right input {
                text-align: right !important;
            }

            .item-grid {
                display: flex;
                flex-direction: column;
                gap: 10px;
                padding: 12px;
            }

            .cellGrid3 {
                border: none;
                padding: 0;
                display: grid;
                grid-template-columns: 1fr 1fr 1fr;
            }


            .cell {
                border: none;
                padding: 0;
            }

            .m-label {
                display: block;
                font-size: 11px;
                color: var(--muted);
                margin-bottom: 4px;
                text-align: left
            }

            .m-labelmoney {
                display: block;
                font-size: 14px;
                color: var(--text);
                margin-bottom: 4px;
                text-align: left
            }

            .cell.actions {
                /*  display: flex;
                gap: 8px;
                flex-wrap: wrap;*/
            }

                .cell.actions > * {
                    flex: 1;
                    min-width: 140px;
                }

            .totals {
                display: grid;
                grid-template-columns: 1fr 85px 85px;
            }

            .tot {
                text-align: right;
            }

            .addactions {
                display: flex;
                align-items: center;
                justify-content: left;
                grid-row: span 4;
            }
        }
    </style>
 

</head>
<body>
    <form id="form1" runat="server">
         <telerik:RadScriptManager
     ID="RadScriptManager1"
     runat="server"
     EnablePartialRendering="true"
     AsyncPostBackTimeout="300" />
          <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>


    <telerik:RadAjaxManager ID="Ram1" runat="server">
        <AjaxSettings>

            <telerik:AjaxSetting AjaxControlID="Ram1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rpItems" />
                    <telerik:AjaxUpdatedControl ControlID="lblCustomer" />
                    <telerik:AjaxUpdatedControl ControlID="rdLabel" />
                </UpdatedControls>
            </telerik:AjaxSetting>






            <telerik:AjaxSetting AjaxControlID="btnAddLine">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="rpItems" />
                    <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                    <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                    <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                    <telerik:AjaxUpdatedControl ControlID="lblTotal" />
                </UpdatedControls>
            </telerik:AjaxSetting>

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

        <!-- TOP -->
        <div class="topbar">
            <strong>Édition de facture</strong>
        </div>

        <!-- CONTENT -->
        <div class="content">
            <div class="container">

                <!-- HEADER -->
                <div class="card">
                    <div class="card-body">

                        <div class="row2">

                            <div>
                                <label>Client</label>

                                <asp:Label ID="lblCustomer" runat="server" CssClass="customer-selector" Text="Select client"> </asp:Label>

                            </div>


                            <div class="field">
                                <div style="height: 100%; display: flex; align-items: flex-end;">
                                    <telerik:RadLabel ID="rdLabel" runat="server"></telerik:RadLabel>
                                </div>
                            </div>


                        </div>

                        <div style="height: 12px"></div>

                        <div class="row4">
                            <div>
                                <label>Date facture</label>
                                <telerik:RadDatePicker ID="dpIssueDate" runat="server" />
                            </div>

                            <div>
                                <label>Date d’échéance</label>
                                <telerik:RadDatePicker ID="dpDueDate" runat="server" />
                            </div>
                        </div>

                    </div>
                </div>

                <!-- ITEMS -->
                <div class="card">
                    <div class="card-header">
                        <strong>Lignes</strong>

                    </div>

                    <div class="card-body">

                        <!-- header desktop -->
                        <div class="items-header">

                            <div>Product</div>
                            <div>Description</div>
                            <div style="text-align: right">Qty</div>
                            <div style="text-align: right">Prix unité</div>
                            <div style="text-align: right">Total</div>
                            <div style="text-align: center">Action</div>
                        </div>

                        <div class="items-wrap">

                            <asp:Repeater ID="rpItems" runat="server">
                                <ItemTemplate>

                                    <div class="item-row">
                                        <div class="item-grid">
                                            <asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' />

                                            <div class="cell">
                                                <div class="m-label">Produit</div>

                                                <asp:Label ID="lblProduct" runat="server" CssClass="product-selector" Text='<%# Eval("ProductName") %>'> </asp:Label>

                                                <asp:HiddenField ID="hidProductId" runat="server" Value='<%# Eval("ProductId") %>' />

                                            </div>
                                            <div class="cell">
                                                <div class="m-label">Description</div>
                                                <telerik:RadTextBox ID="txtDesc" runat="server"
                                                    TextMode="MultiLine" Rows="2"
                                                    Text='<%# Eval("Description") %>' />
                                            </div>

                                            <div class="cellGrid3" style="text-align: right">
                                                <span class="m-labelmoney">Qty</span>
                                                <span></span>
                                                <span class="qty-right">
                                                    <telerik:RadTextBox ID="numQty" runat="server"
                                                        Text='<%# FormatQty(Eval("Qty")) %>'
                                                        CssClass="num-right"
                                                        oninput="fixNumber(this)" onblur="formatQtyOnBlur(this)" onfocus="this.select()">
                                                    </telerik:RadTextBox>



                                                </span>
                                            </div>

                                            <div class="cellGrid3" style="text-align: right">
                                                <span class="m-labelmoney">Prix unité</span>
                                                <span></span>
                                                <span class="qty-right">
                                                    <telerik:RadTextBox ID="numUnitPrice" runat="server"
                                                        Text='<%# FormatUnitPrice(Eval("UnitPrice")) %>'
                                                        CssClass="num-right"
                                                        oninput="fixNumber(this)" onblur="formatPrice(this)" onfocus="this.select()">
                                                    </telerik:RadTextBox>
                                                </span>
                                            </div>

                                            <div class="cellGrid3" style="text-align: right">
                                                <div class="m-labelmoney">Total</div>
                                                <span></span>
                                                <asp:Label ID="lblAmount" runat="server" CssClass="lbl-amount"
                                                    Text='<%# Eval("Amount","{0:N2}") %>' />
                                            </div>

                                            <div class="cell actions" style="text-align: center">
                                                <%--<div class="m-label">Action</div>--%>
                                                <telerik:RadImageButton ID="RadImageButton1"
                                                    runat="server"
                                                    Text=""
                                                    CssClass="imgaction"
                                                    Width="25px"
                                                    Height="35px"
                                                    Image-Url="~/Images/del200.png" Image-Sizing="Stretch"
                                                    CommandName="DeleteLine"
                                                    CommandArgument='<%# Eval("Id") %>'
                                                    OnClientClicking="function(s,e){ if(!confirm('Supprimer cette ligne ?')) e.set_cancel(true); }">
                                                </telerik:RadImageButton>

                                                <telerik:RadImageButton ID="RadImageButton2"
                                                    runat="server"
                                                    CssClass="imgaction"
                                                    Text=""
                                                    Width="25px"
                                                    Height="35px"
                                                    Image-Url="~/Images/flechehaut.png" Image-Sizing="Stretch"
                                                    CommandName="Up"
                                                    CommandArgument='<%# Eval("Id") %>'>
                                                </telerik:RadImageButton>
                                                <telerik:RadImageButton ID="RadImageButton3"
                                                    runat="server"
                                                    Text=""
                                                    CssClass="imgaction"
                                                    Width="25px"
                                                    Height="35px"
                                                    Image-Url="~/Images/flechebas.png" Image-Sizing="Stretch"
                                                    CommandName="Up"
                                                    CommandArgument='<%# Eval("Id") %>'>
                                                </telerik:RadImageButton>


                                                <%-- <telerik:RadButton ID="RadButton1" runat="server"
                                                        Text=""
                                                         Image-ImageUrl="~/Images/del200.png"
                                                        CommandName="DeleteLine"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        OnClientClicking="function(s,e){ if(!confirm('Supprimer cette ligne ?')) e.set_cancel(true); }" />--%>
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

        <!-- FOOTER -->
        <div class="footerbar">
            <div class="totals">



                <div class="tot">

                    <asp:Label ID="lblCapSubTotal" runat="server" Text="Sous-total" />
                </div>
                <div class="tot">
                    <strong>
                        <asp:Label ID="lblSubTotal" runat="server" Text="0.00" /></strong>
                </div>

                <div class="tot">
                    TPS

                </div>

                <div class="tot">
                    <strong>
                        <asp:Label ID="lblTax1" runat="server" Text="0.00" /></strong>
                </div>

                <div class="tot">
                    TVQ

                </div>
                <div class="tot">
                    <strong>
                        <asp:Label ID="lblTax2" runat="server" Text="0.00" /></strong>
                </div>

                <div class="tot">
                    Total

                </div>
                <div class="tot">
                    <strong>
                        <asp:Label ID="lblTotal" runat="server" Text="0.00" /></strong>
                </div>

            </div>

        </div>

        <div class="fab-addline">
            <telerik:RadImageButton ID="btnAddLine"
                runat="server"
                Image-Url="~/Images/rondplus45.png"
                Width="56px"
                Height="56px"
                ToolTip="Ajouter une ligne">
            </telerik:RadImageButton>
        </div>


        <telerik:RadButton ID="radSave" runat="server" BackColor="lightgrey" Text="Enrgistrer" />


        <%--Section overlay des Produits--%>

        <asp:HiddenField ID="hidSelectedProductId" runat="server" />
        <div id="productPickerOverlay" class="product-picker-overlay" style="display: none;">
            <div class="product-picker-shell">


                <div class="product-picker-search">
                    <input type="text" id="productPickerSearch" oninput="filterProductsClient()" class="product-picker-input" placeholder="Rechercher un produit..." />
                    <button type="button" class="product-picker-close-inline" onclick="closeProductPicker()" aria-label="Fermer">✕</button>
                </div>

                <div id="productPickerList" class="product-picker-list">
                    <div class="list-shell">
                        <telerik:RadListView ID="rlvProducts" runat="server"
                            AllowPaging="false"
                            ItemPlaceholderID="itemPlaceholder"
                            OnNeedDataSource="rlvProducts_NeedDataSource">

                            <LayoutTemplate>


                                <div class="items-wrap">
                                    <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                                </div>

                                <div class="lv-footer">
                                    <telerik:RadButton ID="btnAddProducts" runat="server" Text="Ajouter des produits"
                                        CssClass="btn-add" OnClick="btnAddProducts_Click" />
                                </div>
                            </LayoutTemplate>

                            <ItemTemplate>
                                <div class="product-card" data-search='<%# Eval("Name").ToString().ToLower() %>' onclick="selectProduct( '<%# Eval("Code") %>' )">
                                    <div class="product-name"><%# Eval("Name") %></div>
                                    <div class="product-price"><%# Eval("Prix", "{0:C2}") %></div>
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



        <%--Section overlay des Customer--%>
        <asp:HiddenField ID="hidSelectedCustomerId" runat="server" />
        <div id="customerPickerOverlay" class="customer-picker-overlay" style="display: none;">
            <div class="customer-picker-shell">


                <div class="customer-picker-searchbar">
                    <input type="text" id="customerPickerSearch" oninput="filterCustomersClient()" class="customer-picker-input" placeholder="Rechercher d'un client..." />
                     
                    <button type="button" class="customer-picker-close-inline" onclick="closeCustomerPicker()" aria-label="Fermer">✕</button>
                </div>

                <div id="customerPickerList" class="customer-picker-list">
                    <div class="list-shell">
                        <telerik:RadListView ID="rlvCustomers" runat="server"
                            AllowPaging="false"
                            ItemPlaceholderID="itemcustomerPlaceholder">

                            <LayoutTemplate>


                                <div class="items-wrap">
                                    <asp:PlaceHolder ID="itemcustomerPlaceholder" runat="server"></asp:PlaceHolder>
                                </div>

                                <div class="lv-footer">
                                    <telerik:RadButton ID="btnAddcustomers" runat="server" Text="Ajouter des clients" CssClass="btn-add" />
                                </div>
                            </LayoutTemplate>

                            <ItemTemplate>
                                <div class="customer-card" data-search='<%# Eval("search").ToString().ToLower() %>' onclick="selectCustomer( '<%# Eval("Id") %>' )">
                                    <div class="Contact-name"><%# Eval("ContactName") %></div>
                                    <div class="BillingTo"><%# Eval("BillingTo") %></div>
                                </div>
                            </ItemTemplate>

                            <EmptyDataTemplate>
                                <div class="empty">Aucun client trouvé.</div>
                            </EmptyDataTemplate>


                        </telerik:RadListView>
                    </div>

                </div>
            </div>
        </div>

    </asp:Panel>

    <script type="text/javascript">


        function trimZeros(s) {
            // suppose déjà . comme séparateur
            s = (s || "").toString().trim();
            if (s === "") return "";

            // si finit par ".", on l'enlève
            if (s.endsWith(".")) s = s.slice(0, -1);

            // enlever zéros à droite: 2.50 -> 2.5, 2.00 -> 2
            if (s.indexOf(".") >= 0) {
                s = s.replace(/0+$/, "");   // enlève zéros finaux
                s = s.replace(/\.$/, "");   // enlève le point s'il reste à la fin
            }
            return s;
        }

        function formatQtyOnBlur(el) {
            // 1) normalise comme ton fixNumber (accepte , et .)
            fixNumber(el);

            // 2) format: 2.0 -> 2
            el.value = trimZeros(el.value);

            // 3) (optionnel) si vide => 0
            // if(el.value === "") el.value = "0";
        }

        function formatPrice(el) {

            fixNumber(el);

            let v = el.value;

            if (v === "") return;

            let n = parseFloat(v);

            if (isNaN(n)) {
                el.value = "";
                return;
            }

            let dec = n.toFixed(2);

            // si .00 enlever
            if (dec.endsWith(".00")) {
                el.value = parseInt(n);
                return;
            }

            // si .x ajouter 0
            if (dec.match(/\.\d$/)) {
                el.value = dec + "0";
                return;
            }

            el.value = dec;
        }


        function fixNumber(el) {
            // 1) Normaliser virgule -> point
            let v = (el.value || "").replace(/,/g, ".");

            // 2) Garder seulement chiffres et points
            v = v.replace(/[^0-9.]/g, "");

            // 3) Garder un seul point
            const firstDot = v.indexOf(".");
            if (firstDot !== -1) {
                let left = v.substring(0, firstDot);
                let right = v.substring(firstDot + 1).replace(/\./g, "");

                // max 2 décimales
                right = right.substring(0, 2);

                v = left + "." + right;
            }


            el.value = v;
        }



        // ===== CONFIG TAXES =====
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
            var prEl = row.querySelector("input[id*='numUnitPrice']");
            if (!qtyEl || !prEl) return 0;

            var qty = toNum(qtyEl.value);
            var pr = toNum(prEl.value);

            var amt = Math.round(qty * pr * 100) / 100;

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

            var tps = Math.round(subtotal * TAX_TPS * 100) / 100;
            var tvq = Math.round(subtotal * TAX_TVQ * 100) / 100;
            var total = Math.round((subtotal + tps + tvq) * 100) / 100;

            // Labels server-side (ClientID)
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
            // Attache events à chaque input (1 seule fois)
            document.querySelectorAll(".item-row input[id*='numQty'], .item-row input[id*='numUnitPrice']")
                .forEach(function (inp) {
                    if (inp.dataset.wired === "1") return;
                    inp.dataset.wired = "1";

                    // input = à chaque modification (touche, collage, wheel, etc.)
                    inp.addEventListener("input", function () {
                        var row = inp.closest(".item-row");
                        if (row) {
                            recalcRow(row);
                            recalcTotals();
                        }
                    });

                    // fallback
                    inp.addEventListener("keyup", function () {
                        var row = inp.closest(".item-row");
                        if (row) {
                            recalcRow(row);
                            recalcTotals();
                        }
                    });
                });

            // Calcul initial
            recalcTotals();
        }

        // 1) Load initial
        document.addEventListener("DOMContentLoaded", function () {
            wireInvoiceInputs();
        });

        // 2) Après RadAjax (UpdatePanel/Telerik)
        if (window.Sys && Sys.Application) {
            Sys.Application.add_load(function () {
                wireInvoiceInputs();
            });
        }

        // Optionnel: helper si tu veux marquer une ligne supprimée sans rebind
        function markRowDeleted(buttonEl) {
            var row = buttonEl.closest(".item-row");
            if (row) {
                row.setAttribute("data-deleted", "1");
                row.style.display = "none";
                recalcTotals();
            }
        }


        //====================================================
        var currentProductCombo = null;
        var productPickerItems = [];

        function closeProductPicker() {
            var overlay = document.getElementById("productPickerOverlay");
            if (overlay) {
                overlay.style.display = "none";
            }

            document.documentElement.classList.remove("no-page-scroll");
            document.body.classList.remove("no-page-scroll");

            currentProductCombo = null;
        }

        function resizeProductPickerToViewport() {
            var shell = document.querySelector(".product-picker-shell");
            if (!shell) return;

            if (window.visualViewport) {
                shell.style.height = window.visualViewport.height + "px";
            } else {
                shell.style.height = window.innerHeight + "px";
            }
        }


        function renderProductPickerItems(items) {
            var list = document.getElementById("productPickerList");
            if (!list) return;

            list.innerHTML = "";

            items.forEach(function (item) {
                var div = document.createElement("div");
                div.className = "product-picker-item";
                div.textContent = item.text;
                div.dataset.value = item.value;

                div.addEventListener("click", function () {
                    selectProductFromPicker(item.value, item.text);
                });

                list.appendChild(div);
            });
        }

        function filterProductPicker() {
            var q = document.getElementById("productPickerSearch").value.toLowerCase();

            var filtered = productPickerItems.filter(function (x) {
                return x.text.toLowerCase().indexOf(q) >= 0;
            });

            renderProductPickerItems(filtered);
        }

        function selectProductFromPicker(value, text) {
            if (!currentProductCombo) return;

            var combo = currentProductCombo;

            combo.clearSelection();
            var item = combo.findItemByValue(value);

            if (item) {
                item.select();
                combo.set_text(text);
            } else {
                combo.set_text(text);
            }

            closeProductPicker();

            __doPostBack(combo.get_uniqueID(), "");
        }

        if (window.visualViewport) {
            window.visualViewport.addEventListener("resize", function () {
                resizeProductPickerToViewport();
            });
        } else {
            window.addEventListener("resize", function () {
                resizeProductPickerToViewport();
            });
        }


        var currentProductLabel = null;
        var currentItemId = null;
        function openProductPicker(label, itemId) {
            currentItemId = itemId;
            currentProductLabel = label;

            var overlay = document.getElementById("productPickerOverlay");

            if (overlay) {
                overlay.style.display = "block";
            }

        }
        function selectProduct(productId) {

            // met l'id dans le hiddenfield
            document.getElementById("<%= hidSelectedProductId.ClientID %>").value = productId;

            if (!currentProductLabel) return;


            // ferme la popup
            closeProductPicker();


            var ajaxManager = $find("<%= Ram1.ClientID %>");
            ajaxManager.ajaxRequest('PRODUCT|' + currentItemId.toString() + '|' + productId.toString());



        }

        function selectProductold(productId, productName) {



            currentProductLabel.innerText = productName;

            var row = currentProductLabel.closest(".item-row");

            if (row) {
                var hidden = row.querySelector("input[id*='hidProductId']");
                if (hidden) {
                    hidden.value = productId;
                }
            }

            closeProductPicker();
        }

        function normalizeText(str) {
            return (str || "")
                .toLowerCase()
                .normalize("NFD")
                .replace(/[\u0300-\u036f]/g, "");
        }

        function filterProductsClient() {
            var tb = document.getElementById("productPickerSearch");
            var q = (tb ? tb.value : "").toLowerCase().trim();

            var cards = document.querySelectorAll("#productPickerList .product-card");
            var visibleCount = 0;

            cards.forEach(function (card) {
                var text = normalizeText(card.getAttribute("data-search"));
                var show = q === "" || text.indexOf(q) !== -1;

                card.style.display = show ? "" : "none";

                if (show) visibleCount++;
            });

            toggleEmptyProductsMessage(visibleCount === 0);
        }

        function toggleEmptyProductsMessage(show) {
            var list = document.getElementById("productPickerList");
            if (!list) return;

            var empty = document.getElementById("productPickerEmptyJs");

            if (!empty) {
                empty = document.createElement("div");
                empty.id = "productPickerEmptyJs";
                empty.className = "empty";
                empty.innerText = "Aucun produit trouvé.";
                empty.style.display = "none";
                list.appendChild(empty);
            }

            empty.style.display = show ? "block" : "none";
        }
        //==========SECTION OVERLAY CUSTOMER=========================================

        var currentCustomerCombo = null;
        var CustomerPickerItems = [];

        function closeCustomerPicker() {
            var overlay = document.getElementById("customerPickerOverlay");
            if (overlay) {
                overlay.style.display = "none";
            }

            document.documentElement.classList.remove("no-page-scroll");
            document.body.classList.remove("no-page-scroll");

            currentCustomerCombo = null;
        }

        function resizeCustomerPickerToViewport() {
            var shell = document.querySelector(".customer-picker-shell");
            if (!shell) return;

            if (window.visualViewport) {
                shell.style.height = window.visualViewport.height + "px";
            } else {
                shell.style.height = window.innerHeight + "px";
            }
        }



        function renderCustomerPickerItems(items) {
            var list = document.getElementById("customerPickerList");
            if (!list) return;

            list.innerHTML = "";

            items.forEach(function (item) {
                var div = document.createElement("div");
                div.className = "customer-picker-item";
                div.textContent = item.text;
                div.dataset.value = item.value;

                div.addEventListener("click", function () {
                    selectCustomerFromPicker(item.value, item.text);
                });

                list.appendChild(div);
            });
        }

        function filterCustomerPicker() {
            var q = document.getElementById("customerPickerSearch").value.toLowerCase();

            var filtered = customerPickerItems.filter(function (x) {
                return x.text.toLowerCase().indexOf(q) >= 0;
            });

            renderCustomerPickerItems(filtered);
        }

        function selectCustomerFromPicker(value, text) {
            if (!currentCustomerCombo) return;

            var combo = currentCustomerCombo;

            combo.clearSelection();
            var item = combo.findItemByValue(value);

            if (item) {
                item.select();
                combo.set_text(text);
            } else {
                combo.set_text(text);
            }

            closeCustomerPicker();

            __doPostBack(combo.get_uniqueID(), "");
        }

        if (window.visualViewport) {
            window.visualViewport.addEventListener("resize", function () {
                resizeCustomerPickerToViewport();
            });
        } else {
            window.addEventListener("resize", function () {
                resizeCustomerPickerToViewport();
            });
        }


        var currentCustomerLabel = null;
        var currentCustomerId = null;
        function openCustomerPicker(label, itemId) {
            currentCustomerId = itemId;
            currentCustomerLabel = label;

            var overlay = document.getElementById("customerPickerOverlay");

            if (overlay) {
                overlay.style.display = "block";
            }

        }
        function selectCustomer(customerId) {

            // met l'id dans le hiddenfield
            document.getElementById("<%= hidSelectedCustomerId.ClientID %>").value = customerId;

            if (!currentCustomerLabel) return;


            // ferme la popup
            closeCustomerPicker();


            var ajaxManager = $find("<%= Ram1.ClientID %>");
            ajaxManager.ajaxRequest('CUSTOMER|' + customerId.toString());



        }

        function selectCustomerold(productId, productName) {



            currentProductLabel.innerText = productName;

            var row = currentProductLabel.closest(".item-row");

            if (row) {
                var hidden = row.querySelector("input[id*='hidProductId']");
                if (hidden) {
                    hidden.value = productId;
                }
            }

            closeProductPicker();
        }



        function filterCustomersClient() {
            var tb = document.getElementById("customerPickerSearch");
            var q = (tb ? tb.value : "").toLowerCase().trim();

            var cards = document.querySelectorAll("#customerPickerList .customer-card");
            var visibleCount = 0;

            cards.forEach(function (card) {
                var text = normalizeText(card.getAttribute("data-search"));
                var show = q === "" || text.indexOf(q) !== -1;

                card.style.display = show ? "" : "none";

                if (show) visibleCount++;
            });

            toggleEmptyCustomersMessage(visibleCount === 0);
        }

        function toggleEmptyCustomersMessage(show) {
            var list = document.getElementById("customerPickerList");
            if (!list) return;

            var empty = document.getElementById("customerPickerEmptyJs");

            if (!empty) {
                empty = document.createElement("div");
                empty.id = "customerPickerEmptyJs";
                empty.className = "empty";
                empty.innerText = "Aucun client trouvé.";
                empty.style.display = "none";
                list.appendChild(empty);
            }

            empty.style.display = show ? "block" : "none";
        }

    </script>
        </form>
    </body>
    </html>


