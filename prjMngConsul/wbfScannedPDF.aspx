<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" 
    Async="true" MaintainScrollPositionOnPostback="true" CodeBehind="wbfScannedPDF.aspx.vb" 
    Inherits="MngConsul.wbfScannedPDF" %>

<%@ Register Src="~/Controls/jsonViewer.ascx" TagPrefix="uc1" TagName="jsonViewer" %>


<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Pdf Factures clients — 60Sec-AI
</asp:Content>


<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

      <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />
    
    <script src="js/viewport.js"></script>

      <style>
      

        .listview-list-head {
        display: grid;
        grid-template-columns: minmax(180px, 1fr) 29px 1fr;
        gap: 16px;
        padding: 14px 16px;
        font-weight: 800;
        font-size: 13px;
        color: #0f172a;
        background: #f8fafc;
        border-bottom: 1px solid var(--mc-stroke);
        position: sticky;
        top: 0;
        z-index: 0;
        box-sizing: border-box;
    }



    .listview-row {
        display: grid;
        grid-template-columns: minmax(180px, 1fr) 29px 1fr;
        gap: 16px;
        align-items: center;
        padding: 14px 16px;
        border-bottom: 1px solid #eef2f7;
        background: #fff;
        box-sizing: border-box;
    }

       

  

      
      .colh-actions{
          text-align:center;
      }
     
      
 
      
 
 

      .grid .btn 
        {
          border-radius: 10px !important;
      }

      /* ===== ÉTAT DISABLED PRO ===== */
.btn:disabled,
.btn[disabled] {

    background:#e5e7eb !important;   /* gris doux */
    color:#9ca3af !important;        /* texte gris */
    border-color:#d1d5db !important;

    cursor:not-allowed !important;
    opacity:.75;
    box-shadow:none !important;
    transform:none !important;
}

/* empêche hover */
.btn:disabled:hover{
    background:#e5e7eb !important;
}
  
 

.pdf-file {
    min-width: 0;
    word-break: break-word;
    color: #0f172a;
    font-weight: 600;
}
   


        /* =========================
            TABLETTE — 769px à 1024px
         ========================= */
          @media (min-width: 769px) and (max-width: 1024px) {

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

              .btn{
                      padding: 5px 2px;
                      font-size: 12px;
              }

                  .listview-list-head {
    display: grid;
    grid-template-columns: minmax(180px, 1fr)  1fr;
    gap: 0px;
    padding: 0px 0px;
    font-weight: 800;
    font-size: 13px;
    color: #0f172a;
    background: #f8fafc;
    border-bottom: 1px solid var(--mc-stroke);
    position: sticky;
    top: 0;
    z-index: 0;
    box-sizing: border-box;
}
              .listview-row {
    display: grid;
    grid-template-columns: minmax(180px, 1fr) 1fr;
    gap: 0px;
    align-items: center;
    padding: 0px 0px;
    border-bottom: 1px solid #eef2f7;
    background: #fff;
    box-sizing: border-box;
}



        .field-status{
    display:none
} 
                .colh-status{
    display:none
} 
          }

/*
@media (max-width: 900px) {
   

      
}*/
  </style>

    

</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">


      <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"> </telerik:RadAjaxLoadingPanel>

 
    
     <telerik:RadAjaxPanel ID="RadAjaxPanel1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1">
  
         
        


    <div class="page-head">
        <div class="page-head-left">
             <div class="page-title">Scanned PDF </div>
       </div>

        <div class="searchbox">

          <telerik:RadAsyncUpload ID="rauInvoicePdf" runat="server"
                AllowedFileExtensions=".pdf"
                MaxFileInputsCount="1"
                AutoPostBackOnUpload="true"
                MultipleFileSelection="Disabled"
                TemporaryFolder="~/App_Data/RadUploadTemp"
                TargetFolder="~/App_Data/TempUploads"
                Skin="Metro" />

           

            <telerik:RadButton ID="btnSavePdf" runat="server"
                Text=""
                CssClass="btn btn-icon btn-icon-save"
                AutoPostBack="true" />

              <div class="search-group">

            <asp:TextBox ID="tbSearch" runat="server" CssClass="input txttbsearch" placeholder="Rechercher (fournisseur, fichier, statut…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn btn-icon btn-icon-search" Text="" />
                   <asp:Button ID="btnClear" runat="server"
                    CssClass="btn btn-icon btn-icon-clear"
                       Text=""
                           ToolTip="Effacer"
                           CausesValidation="false" />



                  </div>


        </div>
    </div>

   <div class="full-grid">
    <div class="list-shell">


        <telerik:RadListView ID="RadScannedPDF" runat="server"
            Skin="Metro"
            DataKeyNames="imageGUID"
            AllowPaging="false"
            ItemPlaceholderID="itemPlaceholder"
          >

            <LayoutTemplate>
                <div class="listview-list">
                    <div class="listview-list-head">
                        <div class="colh-file">Fichier</div>
                        <div class="colh-status">Statut</div>
                        <div class="colh-actions">Actions</div>
                    </div>

                    <div class="listview-list-body">
                        <asp:PlaceHolder ID="itemPlaceholder" runat="server" />
                    </div>
                </div>
            </LayoutTemplate>

            <ItemTemplate>
                <div class="listview-row">
                    <div class="pdf-file">
                        <asp:Literal ID="litHtml"
                            runat="server"
                            Mode="PassThrough"
                            Text='<%# Server.HtmlDecode(CStr(Eval("SourceFileName"))) %>' />
                    </div>

                    <div class="field-status">
                        <%# Eval("ProcessingStatus") %>
                    </div>

                    <div class="listview-actions">
                        <asp:Button ID="btnDelete"
                            runat="server"
                            Text="Delete"
                            CssClass="btn"
                            CommandName="DeleteR"
                            CommandArgument='<%# Eval("imageGUID") %>' />

                        <asp:Button ID="btnProcess"
                            runat="server"
                            Text="Process AI"
                            CssClass="btn"
                            Enabled='<%# Eval("CanProcessAI") %>'
                            CommandName="Process"
                            CommandArgument='<%# Eval("imageGUID") %>' />

                        <asp:Button ID="btnVoirJSON"
                            runat="server"
                            Text="Voir JSON"
                            CssClass="btn"
                            Visible='<%# Eval("CanViewJSON") %>'
                            CommandName="VoirJSON"
                            CommandArgument='<%# Eval("imageGUID") %>' />

                        <asp:Button ID="btnProcessJSON"
                            runat="server"
                            Text="Process JSON"
                            CssClass="btn"
                            Visible='<%# Eval("CanViewJSON") %>'
                            CommandName="ProcessJSON"
                            CommandArgument='<%# Eval("imageGUID") %>' />
                    </div>
                </div>
            </ItemTemplate>

            <EmptyDataTemplate>
                <div class="listview-empty">
                    Aucun PDF trouvé.
                </div>
            </EmptyDataTemplate>

        </telerik:RadListView>
    </div>
</div>
         
   </telerik:RadAjaxPanel> 
    <uc1:jsonViewer runat="server" ID="jsonViewer" />

</asp:Content>
