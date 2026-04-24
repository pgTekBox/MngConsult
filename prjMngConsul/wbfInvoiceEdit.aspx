<%@ Page Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostback="true" CodeBehind="wbfInvoiceEdit.aspx.vb" Inherits="MngConsul.wbfInvoiceEdit" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Facture client — Édition</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

    <style>
 .badge-posted {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 999px;
    background: #ecfdf5;
    color: #059669;
    font-size: 12px;
    font-weight: 700;
    border: 1px solid #a7f3d0;
}

        .readonly {
     
    opacity: 0.85;
}
        .readonly-blocked {
    pointer-events: none;
}
.readonly input,
.readonly textarea {
    background-color: #f1f5f9 !important;
}

.no-arrow {
    text-align: center;
    font-weight: 700;
}

 


 
.no-arrow .rddlFakeInput   
   {
      padding-right: 30px;
     text-align: center;
     font-weight: 700;
     padding-right: 30px;
}
.no-arrow .rddlSelect {
     
     text-align: center;
     font-weight: 700;
    display: none !important;
}
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


        .product-selector,
        .customer-selector,
        .account-selector {
            display: block;
            width: 100%;
            min-height: 38px;
            padding: 8px 10px;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            background: #fff;
            cursor: pointer;
            box-sizing: border-box;
        }
        .clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2; /* nombre de lignes */
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
}
            .product-selectore::after,
            .customer-selector::after,
            .account-selector::after {
                content: "▾";
                float: right;
                color: #64748b;
            }

            .product-selector:active,
            .customer-selector:active,
            .account-selector:active {
                background: #f1f5f9;
            }

        .product-picker-overlay,
        .customer-picker-overlay,
        .account-picker-overlay {
            position: fixed;
            inset: 0;
            z-index: 99999;
            background: rgba(15, 23, 42, .35);
        }

        .product-picker-shell,
        .customer-picker-shell,
        .account-picker-shell {
            position: absolute;
            inset: 0;
            background: #fff;
            display: flex;
            flex-direction: column;
            height: 100%;
            min-height: 0;
        }
        .lblproductselect{
                padding: 0px;
               border: 0px;
               background-color: transparent;
              font-size: 25px;
        }
        .product-picker-title {
            font-size: 18px;
            font-weight: 800;
        }

        .product-picker-search,
        .product-picker-searchbar,
        .customer-picker-searchbar,
        .account-picker-searchbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px;
            border-bottom: 1px solid var(--line);
            background: #fff;
        }

        .product-picker-close {
            border: 0;
            background: transparent;
            font-size: 24px;
            cursor: pointer;
        }

        .product-picker-close-inline,
        .customer-picker-close-inline,
        .account-picker-close-inline {
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

            .product-picker-close-inline:active,
            .customer-picker-close-inline:active,
            .account-picker-close-inline:active {
                background: #f8fafc;
            }

        .product-picker-input,
        .customer-picker-input,
        .account-picker-input {
            width: 100%;
            max-width: 260px;
            min-width: 0;
            height: 44px;
            padding: 0 12px;
            border: 1px solid #cbd5e1;
            border-radius: 12px;
            box-sizing: border-box;
            font-size: 16px;
        }

        .product-picker-list,
        .customer-picker-list,
        .account-picker-list {
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

        .rw-page {
            height: 100%;
            display: flex;
            flex-direction: column;
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
            padding: 14px;
            padding-bottom: 90px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
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
            padding: 14px;
        }

        .row2,
        .row3,
        .row4 {
            display: grid;
            gap: 12px;
        }

        .qty-right input {
            text-align: right !important;
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
            width: 100% !important;
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

        .customer-card,
        .account-card {
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

        .product-account {
            font-size: 11px;
            font-weight: 600;
            text-align: right;
            color: grey;
        }

        .Contact-name {
            font-size: 16px;
            font-weight: 800;
            color: var(--accent);
        }

        .product-meta,
        .account-code {
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

        .BillingTo,
        .account-name {
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
            right: 190px;
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

         

        .items-headerRD {
            display: grid;
  grid-template-columns: 1fr 30px  190px 50px 80px 80px 45px 45px 90px;
  border: 1px solid var(--line);
  border-radius: var(--r-lg);
  overflow: hidden;
  margin-bottom: 8px;
   padding: 10px;
      font-size: 12px;
      font-weight: 900;
      color: var(--muted);
      background: #f8fafc;
      border-right: 1px solid var(--line);
        }

        .item-gridcutinv {
            display: grid;
            grid-template-columns: 1fr 30px 190px 50px 80px 80px 45px 45px 90px;
        }

        .row2 {
            grid-template-columns: 1fr 1fr;
        }

        .row3 {
            grid-template-columns: auto auto 1fr;
        }

        @media (min-width: 769px) {
            .row3 {
                grid-template-columns: auto auto 1fr;
            }
        }

        .row2 {
            grid-template-columns: 1fr 1fr;
        }

        .no-right-border {
    border-right: none !important;
}
        
        .no-left-border {
    border-left: none  !important;
        background-color: antiquewhite;
}
          .totals {
      display: grid;
    grid-template-columns: auto auto;  
    justify-content: end;             
    column-gap: 30px;    
    
  }
         
     
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

            .imgaction {
                margin-left: 14px;
            }

            .totals {
                display: grid;
                grid-template-columns: 1fr 85px 85px;
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
                        <telerik:AjaxUpdatedControl ControlID="lblSubTotal" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax1" />
                        <telerik:AjaxUpdatedControl ControlID="lblTax2" />
                        <telerik:AjaxUpdatedControl ControlID="lblTotal" />
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

           

            <div class="content">
                <div class="container">

                    <asp:Label ID="lblPostedBadge" runat="server" CssClass="badge-posted" Visible="false" Text="Comptabilisé 🔒"></asp:Label>
                    <div class="card">
                        <div class="card-body">

                            <div class="row2">
                                <div>
                                    <label>Client</label>
                                    <asp:Label ID="lblCustomer" runat="server" CssClass="customer-selector" Text="Select client"></asp:Label>
                                </div>

                                <div class="field">
                                    <div style="height: 100%; display: flex; align-items: flex-end;">
                                        <telerik:RadLabel ID="rdLabel" runat="server"></telerik:RadLabel>
                                    </div>
                                </div>
                            </div>

                            <div style="height: 12px"></div>

                            <div class="row3">
                                <div  style="width:160px">
                                    <label>Date facture</label>
                                    <telerik:RadDatePicker  Width="160px"  ID="dpIssueDate" runat="server" />
                                </div>

                                <div  style="width:160px">
                                    <label>Date d’échéance</label>
                                    <telerik:RadDatePicker   ID="dpDueDate" runat="server" />
                                </div>
                                <div >
                                    <br />
                                    <label>Comptabilisé</label><asp:CheckBox ID="chkPost" runat="server" />

                                </div>



                            </div>

                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <strong>Lignes</strong>
                        </div>

                        <div class="card-body">
                            <div class="items-headerRD">
                                <div>Produit</div>
                             <div></div>
                                <div style="text-align: center">Compte</div>
                                
                                <div style="text-align: center">Qty</div>
                                <div style="text-align: center">Prix unitaire</div>
                                <div style="text-align: right">Total</div>
                                <div style="text-align: center">Tx</div>
                                 <div style="text-align: center"></div>
                                <div style="text-align: center">Ordre</div>
                            </div>

                            <div class="items-wrap" style="display: block; padding: 0;">
                                <asp:Repeater ID="rpItems" runat="server">
                                    <ItemTemplate>
                                        <div class="item-row" style="border:none; padding-bottom: 5px;" >
                                            <div class="item-gridcutinv ">
                                                <asp:HiddenField ID="hidId" runat="server" Value='<%# Eval("Id") %>' />
                                                 <div class="cell no-right-border">
                                                    
                                                    <telerik:RadTextBox ID="txtDesc" runat="server"  CssClass="no-right-border clamp-2" 
                                                        TextMode="MultiLine" Rows="2"
                                                        Text='<%# Eval("Description") %>' />
                                                </div>
                                                <div class="cell no-left-border">
                                                     
                                                    <asp:Label ID="lblProduct" runat="server"  
                                                        CssClass="product-selector lblproductselect"
                                                        Text="▾"
                                                        OnClientClick='<%# "openProductPicker(this," & Eval("Id") & "); return false;" %>'>
                                                    </asp:Label>
                                                    <asp:HiddenField ID="hidProductId" runat="server" Value='<%# Eval("ProductId") %>' />
                                                </div>

                                             

                                                <div class="cell">
                                                    
                                                    <asp:Label ID="lblAccount" runat="server"
                                                        CssClass="account-selector js-account-selector"
                                                        Text='<%# Eval("AccountName") %>'>
                                                    </asp:Label>
                                                    <asp:HiddenField ID="hidAccountId" runat="server" Value='<%# Eval("AccountId") %>' />
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                     
                                                    
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numQty" runat="server"
                                                            Text='<%# FormatQty(Eval("Qty")) %>'
                                                            CssClass="num-right"
                                                            oninput="fixNumber(this)" onblur="formatQtyOnBlur(this)" onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                     
                                                    
                                                    <span class="qty-right">
                                                        <telerik:RadTextBox ID="numUnitPrice" runat="server"
                                                            Text='<%# FormatUnitPrice(Eval("UnitPrice")) %>'
                                                            CssClass="num-right"
                                                            oninput="fixNumber(this)" onblur="formatPrice(this)" onfocus="this.select()">
                                                        </telerik:RadTextBox>
                                                    </span>
                                                </div>

                                                <div class="cell" style="text-align: right">
                                                    <asp:Label ID="lblAmount" runat="server" CssClass="lbl-amount" Text='<%# Eval("Amount","{0:N2}") %>' />
                                                </div>
                                                <div class="cell" style="text-align: right">
                                                     <telerik:RadDropDownList ID="rdTaxeStatus"  OnClientItemSelected="onButtonClicked"  CssClass="no-arrow"    runat="server"  RenderMode="Auto" DropDownAutoWidth="Enabled" DropDownWidth="50px" Width="40px"></telerik:RadDropDownList>
                                                 </div>
                                                <div class="cell actions" style="text-align: center">
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
                                                </div>

                                                <div class="cell actions" style="text-align: center">
                                                    <telerik:RadImageButton ID="OrdreHaut"
                                                        runat="server"
                                                        CssClass="imgaction"
                                                        Text=""
                                                        Width="25px"
                                                         OnClientClicked ="onButtonClicked"
                                                        Height="35px"
                                                        Image-Url="~/Images/flechehaut.png" Image-Sizing="Stretch"
                                                        CommandName="OrdreHaut"
                                                        CommandArgument='<%# Eval("Id") %>'>
                                                    </telerik:RadImageButton>

                                                    <telerik:RadImageButton ID="OrdreBas"
                                                        runat="server"
                                                        Text=""
                                                        CssClass="imgaction"
                                                         OnClientClicked ="onButtonClicked"
                                                        Width="25px"
                                                        Height="35px"
                                                        Image-Url="~/Images/flechebas.png" Image-Sizing="Stretch"
                                                        CommandName="OrdreBas"
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

            <div class="footerbar">
                <div class="totals">
                    <div class="tot">
                        <asp:Label ID="lblCapSubTotal" runat="server" Text="Sous-total" />
                    </div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblSubTotal" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">TPS</div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblTax1" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">TVQ</div>
                    <div class="tot" style="justify-self: end;">
                        <strong>
                            <asp:Label ID="lblTax2" runat="server" Text="0.00" /></strong>
                    </div>

                    <div class="tot">Total</div>
                    <div class="tot" style="justify-self: end;">
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

            <telerik:RadButton ID="radSave" runat="server" OnClientClicked="onSaveClicked"  BackColor="lightgrey" Text="Enrgistrer" />

            <%-- Section overlay des Produits --%>
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
                                ItemPlaceholderID="itemPlaceholder">

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
                                    <div class="product-card" data-search='<%# Eval("Name").ToString().ToLower() %>' onclick="selectProduct('<%# Eval("Code") %>')">
                                        <div class="product-name"><%# Eval("Name") %></div>
                                        <div class="product-price"><%# Eval("Prix", "{0:C2}") %></div>
                                        <div></div>
                                        <div class="product-account"><%# Eval("account") %></div>
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

            <%-- Section overlay des Customer --%>
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
                                    <div class="customer-card" data-search='<%# Eval("search").ToString().ToLower() %>' onclick="selectCustomer('<%# Eval("Id") %>')">
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

            <%-- Section overlay des Comptes --%>
            <asp:HiddenField ID="hidSelectedAccountId" runat="server" />
            <div id="accountPickerOverlay" class="account-picker-overlay" style="display: none;">
                <div class="account-picker-shell">
                    <div class="account-picker-searchbar">
                        <input type="text" id="accountPickerSearch" oninput="filterAccountsClient()" class="account-picker-input" placeholder="Rechercher un compte..." />
                        <button type="button" class="account-picker-close-inline" onclick="closeAccountPicker()" aria-label="Fermer">✕</button>
                    </div>

                    <div id="accountPickerList" class="account-picker-list">
                        <div class="list-shell">
                            <telerik:RadListView ID="rlvAccounts" runat="server"
                                AllowPaging="false"
                                ItemPlaceholderID="itemaccountPlaceholder">

                                <LayoutTemplate>
                                    <div class="items-wrap">
                                        <asp:PlaceHolder ID="itemaccountPlaceholder" runat="server"></asp:PlaceHolder>
                                    </div>

                                    <div class="lv-footer">
                                        <telerik:RadButton ID="btnAddAccounts" runat="server" Text="Ajouter des comptes" CssClass="btn-add" />
                                    </div>
                                </LayoutTemplate>

                                <ItemTemplate>
                                    <div class="account-card" data-search='<%# Eval("search").ToString().ToLower() %>' onclick="selectAccount('<%# Eval("Id") %>')">
                                        <div class="account-code"><%# Eval("NoCompte") %></div>
                                        <div class="account-name"><%# Eval("Name") %></div>
                                    </div>
                                </ItemTemplate>

                                <EmptyDataTemplate>
                                    <div class="empty">Aucun compte trouvé.</div>
                                </EmptyDataTemplate>
                            </telerik:RadListView>
                        </div>
                    </div>
                </div>
            </div>

        </asp:Panel>

        <script type="text/javascript">


            var IS_READONLY = <%= chkPost.Checked.ToString().ToLower() %>;
            function onSaveClicked(sender, args) {

                // 👉 remet le flag à propre
                if (window.parent && window.parent.setInvoiceClean) {
                    window.parent.setInvoiceClean();
                }

                // ⚠️ ne pas annuler → laisse le postback / save serveur se faire
            }
            function onButtonClicked(sender, args) {
                 
               
                if (window.parent && window.parent.setInvoiceDirty) {
                    window.parent.setInvoiceDirty();
                }
            }

            /* Récupère la référence à la RadWindow parente (mode popup) */
            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement && window.frameElement.radWindow)
                    oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            /* Ferme la fenêtre courante (retour liste clients) */
            function closeWin() {
                var oWnd = GetRadWindow();
                if (oWnd) oWnd.close();
            }


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
                let v = el.value;
                if (v === "") return;
                let n = parseFloat(v);
                if (isNaN(n)) {
                    el.value = "";
                    return;
                }
                let dec = n.toFixed(2);
                if (dec.endsWith(".00")) {
                    el.value = parseInt(n);
                    return;
                }
                el.value = dec;
            }

            function fixNumber(el) {
                let v = (el.value || "").replace(/,/g, ".");
                v = v.replace(/[^0-9.]/g, "");
                const firstDot = v.indexOf(".");
                if (firstDot !== -1) {
                    let left = v.substring(0, firstDot);
                    let right = v.substring(firstDot + 1).replace(/\./g, "");
                    right = right.substring(0, 2);
                    v = left + "." + right;
                }
                el.value = v;
            }

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
            //Uncaught TypeError: ddl.get_value is not a function
              function getTaxStatus(row) {
                var ddlEl = row.querySelector("[id*='rdTaxeStatus']");
                if (!ddlEl) return 1;

                var ddl = $find(ddlEl.id);
                if (!ddl) return 1;

                  var item = ddl.get_selectedItem();
                  if (!item) return 1;

                  var taxStatus = parseInt(item.get_value(), 10);

                return isNaN(taxStatus) ? 1 : taxStatus;
            }

            function recalcTotals() {

                var subtotal = 0;
                var taxableSubtotal = 0;

                document.querySelectorAll(".item-row").forEach(function (row) {

                    if (row.getAttribute("data-deleted") === "1") return;

                    var amount = recalcRow(row);
                    subtotal += amount;


                    var taxStatus = getTaxStatus(row);

                    console.log("taxStatus", taxStatus);

                    

                    // 🔥 seulement TAXABLE (1)
                    if (taxStatus === 1) {
                        taxableSubtotal += amount;
                    }

                });

                subtotal = Math.round(subtotal * 100) / 100;
                taxableSubtotal = Math.round(taxableSubtotal * 100) / 100;

                var tps = Math.round(taxableSubtotal * TAX_TPS * 100) / 100;
                var tvq = Math.round(taxableSubtotal * TAX_TVQ * 100) / 100;

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

                document.querySelectorAll("[id*='rdTaxeStatus']").forEach(function (ddl) {

                    var combo = $find(ddl.id);
                    if (!combo || ddl.dataset.wired === "1") return;

                    ddl.dataset.wired = "1";

                    combo.add_selectedIndexChanged(function () {
                        recalcTotals();
                    });

                });




                document.querySelectorAll(".item-row input[id*='numQty'], .item-row input[id*='numUnitPrice']")
                    .forEach(function (inp) {
                        if (inp.dataset.wired === "1") return;
                        inp.dataset.wired = "1";

                        inp.addEventListener("input", function () {
                            var row = inp.closest(".item-row");
                            if (row) {
                                recalcRow(row);
                                recalcTotals();
                            }
                        });

                        inp.addEventListener("keyup", function () {
                            var row = inp.closest(".item-row");
                            if (row) {
                                recalcRow(row);
                                recalcTotals();
                            }
                        });
                    });

                recalcTotals();
            }

            function wireAccountSelectors() {
                document.querySelectorAll(".js-account-selector").forEach(function (el) {
                    if (el.dataset.wired === "1") return;
                    el.dataset.wired = "1";

                    el.addEventListener("click", function () {
                        var row = el.closest(".item-row");
                        if (!row) return;
                        var hidId = row.querySelector("input[id*='hidId']");
                        var itemId = hidId ? hidId.value : "0";

                        openAccountPicker(el, itemId);
                    });
                });
            }

            document.addEventListener("DOMContentLoaded", function () {
                wireInvoiceInputs();
                wireAccountSelectors();
            });

            if (window.Sys && Sys.Application) {
                Sys.Application.add_load(function () {
                    wireInvoiceInputs();
                    wireAccountSelectors();
                });
            }

            function normalizeText(str) {
                return (str || "")
                    .toLowerCase()
                    .normalize("NFD")
                    .replace(/[\u0300-\u036f]/g, "");
            }

            var currentProductLabel = null;
            var currentItemId = null;

            function closeProductPicker() {
                var overlay = document.getElementById("productPickerOverlay");
                if (overlay) overlay.style.display = "none";
                document.documentElement.classList.remove("no-page-scroll");
                document.body.classList.remove("no-page-scroll");
            }

            function openProductPicker(label, itemId) {
                if (IS_READONLY) return;
                currentItemId = itemId;
                currentProductLabel = label;
                var overlay = document.getElementById("productPickerOverlay");
                if (overlay) overlay.style.display = "block";
                if (window.parent && window.parent.setInvoiceDirty) {
                    window.parent.setInvoiceDirty();
                }
            }

            function selectProduct(productId) {
                document.getElementById("<%= hidSelectedProductId.ClientID %>").value = productId;
                if (!currentProductLabel) return;
                closeProductPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('PRODUCT|' + currentItemId.toString() + '|' + productId.toString());
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

            var currentCustomerLabel = null;

            function closeCustomerPicker() {
                var overlay = document.getElementById("customerPickerOverlay");
                if (overlay) overlay.style.display = "none";
                document.documentElement.classList.remove("no-page-scroll");
                document.body.classList.remove("no-page-scroll");
            }

            function openCustomerPicker(label) {
                if (IS_READONLY) return;
                currentCustomerLabel = label;
                var overlay = document.getElementById("customerPickerOverlay");
                if (overlay) overlay.style.display = "block";

                if (window.parent && window.parent.setInvoiceDirty) {
                    window.parent.setInvoiceDirty();
                }



            }

            function selectCustomer(customerId) {
                document.getElementById("<%= hidSelectedCustomerId.ClientID %>").value = customerId;
                closeCustomerPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                ajaxManager.ajaxRequest('CUSTOMER|' + customerId.toString());

                if (window.parent && window.parent.setInvoiceDirty) {
                    window.parent.setInvoiceDirty();
                }
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

            var currentAccountLabel = null;
            var currentAccountItemId = null;

            function closeAccountPicker() {
                var overlay = document.getElementById("accountPickerOverlay");
                if (overlay) overlay.style.display = "none";
                document.documentElement.classList.remove("no-page-scroll");
                document.body.classList.remove("no-page-scroll");
                console.log("Closed account picker");
                //currentAccountLabel = null;
                //currentAccountItemId = null;
            }

            function openAccountPicker(label, itemId) {
                currentAccountLabel = label;
                currentAccountItemId = itemId;
                console.log("Opening account picker 2 for item ID: " + itemId);
                var overlay = document.getElementById("accountPickerOverlay");
                if (overlay) overlay.style.display = "block";
                if (window.parent && window.parent.setInvoiceDirty) {
                    window.parent.setInvoiceDirty();
                }
            }

            function selectAccount(accountId) {
                console.log("Selected account ID: " + accountId);
                document.getElementById("<%= hidSelectedAccountId.ClientID %>").value = accountId;

                if (!currentAccountLabel) return;
                closeAccountPicker();
                var ajaxManager = $find("<%= Ram1.ClientID %>");
                var itemId = currentAccountItemId || 0;

                console.log("Sending AJAX request for item ID: " + itemId + " and account ID: " + accountId);
                ajaxManager.ajaxRequest('ACCOUNT|' + itemId.toString() + '|' + accountId.toString());
            }

            function filterAccountsClient() {
                var tb = document.getElementById("accountPickerSearch");
                var q = (tb ? tb.value : "").toLowerCase().trim();

                var cards = document.querySelectorAll("#accountPickerList .account-card");
                var visibleCount = 0;

                cards.forEach(function (card) {
                    var text = normalizeText(card.getAttribute("data-search"));
                    var show = q === "" || text.indexOf(q) !== -1;
                    card.style.display = show ? "" : "none";
                    if (show) visibleCount++;
                });

                toggleEmptyAccountsMessage(visibleCount === 0);
            }

            function toggleEmptyAccountsMessage(show) {
                var list = document.getElementById("accountPickerList");
                if (!list) return;

                var empty = document.getElementById("accountPickerEmptyJs");
                if (!empty) {
                    empty = document.createElement("div");
                    empty.id = "accountPickerEmptyJs";
                    empty.className = "empty";
                    empty.innerText = "Aucun compte trouvé.";
                    empty.style.display = "none";
                    list.appendChild(empty);
                }

                empty.style.display = show ? "block" : "none";
            }







        </script>
    </form>
</body>
</html>
