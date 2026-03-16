<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" 
    Async="true" MaintainScrollPositionOnPostback="true" CodeBehind="wbfScannedPDF.aspx.vb" 
    Inherits="MngConsul.wbfScannedPDF" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Pdf Factures clients — MngConsul
</asp:Content>


<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">

      <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

      <style>
      /* Modal JSON - Theme clair */
      .json-modal-overlay {
          position: fixed;
          inset: 0;
          background: rgba(15, 23, 42, .45); /* overlay doux */
          display: flex;
          justify-content: center;
          align-items: center;
          z-index: 99999;
      }






      .json-modal-box {
          width: min(1000px, 92vw);
          max-height: 85vh;
          background: #ffffff;
          border-radius: 16px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          box-shadow: 0 30px 80px rgba(0,0,0,.25);
          border: 1px solid rgba(0,0,0,.10);
      }

      .json-modal-header {
          padding: 14px 18px;
          background: #f8fafc;
          color: #0f172a;
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-weight: 800;
          border-bottom: 1px solid rgba(0,0,0,.10);
      }

      .json-modal-close {
          border: 1px solid rgba(0,0,0,.14);
          background: #ffffff;
          color: #0f172a;
          font-size: 14px;
          cursor: pointer;
          border-radius: 10px;
          padding: 6px 10px;
          font-weight: 800;
      }

          .json-modal-close:hover {
              background: #f1f5f9;
          }

      .json-modal-content {
          flex: 1;
          overflow: auto;
          padding: 18px;
          font-family: Consolas, ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
          font-size: 13px;
          color: #0f172a;
          background: #ffffff;
          white-space: pre-wrap;
          word-break: break-word;
      }

      /* JSON "code look" plus lisible */
      .json-modal-content {
          border-top: 0;
      }

      /* Petites touches pour harmoniser avec le thème du Site.master */
    /*  .page-head {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 12px;
          flex-wrap: wrap;
          padding: 14px 16px;
          border-bottom: 1px solid var(--mc-stroke);
          background: rgba(255,255,255,.75);
      }*/


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

        .listview-row:hover {
            background: #fafcff;
        }


    .txttbsearch{
        max-width:350px;
    }  
    .search-group{
          justify-content: flex-end;
          flex-grow:0;
      }

      .page-title {
          font-weight: 900;
          font-size: 18px;
          line-height: 1.2;
      }
      .colh-actions{
          text-align:center;
      }
     
      .page-sub {
          color: var(--mc-muted);
          font-size: 13px;
          margin-top: 4px;
      }

      .actions {
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
          align-items: center;
      }

      .muted-note {
          color: var(--mc-muted);
          font-size: 12px;
          padding: 10px 16px 0 16px;
      }

      .grid-wrap {
          padding: 16px;
      }

      .full-grid {
          height: calc(100vh - 220px);
      }

      .grid .btn,
      .RadGrid .btn,
      .RadGrid input[type=submit],
      .RadGrid input[type=button] {
          border-radius: 10px !important;
      }

      /* ===== ÉTAT DISABLED PRO ===== */
.btn:disabled,
.btn[disabled],
.RadGrid .btn:disabled,
.RadGrid input[type=submit]:disabled,
.RadGrid input[type=button]:disabled{

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
.list-shell {
    height: 100%;
    padding: 16px;
    box-sizing: border-box;
}

.pdf-list {
    height: 100%;
    display: flex;
    flex-direction: column;
    background: #fff;
    border: 1px solid var(--mc-stroke);
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(15, 23, 42, .06);
}

.pdf-list-head {
    display: grid;
    grid-template-columns: minmax(280px, 1.7fr) 180px minmax(320px, 1fr);
    gap: 16px;
    padding: 14px 16px;
    font-weight: 800;
    font-size: 13px;
    color: #0f172a;
    background: #f8fafc;
    border-bottom: 1px solid var(--mc-stroke);
    position: sticky;
    top: 0;
    z-index: 2;
}
.col-actions {
    text-align: right;
}
.pdf-list-body {
    flex: 1;
    overflow: auto;
}

.pdf-row {
    display: grid;
    grid-template-columns: minmax(280px, 1.7fr) 180px minmax(320px, 1fr);
    gap: 16px;
    align-items: center;
    padding: 14px 16px;
    border-bottom: 1px solid #eef2f7;
    background: #fff;
}

.pdf-row:hover {
    background: #fafcff;
}

.pdf-file {
    min-width: 0;
    word-break: break-word;
    color: #0f172a;
    font-weight: 600;
}

.pdf-status {
    color: #475569;
    font-weight: 700;
}

.pdf-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: flex-start;
    align-items: center;
}

.pdf-empty {
    padding: 24px;
    text-align: center;
    color: #64748b;
}

.pdf-actions .btn,
.pdf-actions input[type=submit],
.pdf-actions input[type=button] {
    border-radius: 10px !important;
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
    .pdf-list-head {
        display: none;
    }

    .pdf-row {
        grid-template-columns: 1fr;
        gap: 10px;
        padding: 14px;
    }

    .pdf-status::before {
        content: "Statut : ";
        font-weight: 800;
        color: #0f172a;
    }

    .pdf-actions {
        margin-top: 4px;
    }
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
    <!-- Modal JSON -->
    <div id="jsonModal" class="json-modal-overlay"  ClientIDMode="Static"  style="display: none;">
        <div class="json-modal-box">
            <div class="json-modal-header">
                <div>🤖 Résultat Analyse AI (JSON)</div>
                <button type="button" class="json-modal-close" onclick="closeJsonModal()">✖</button>
            </div>
            <pre id="jsonModalContent"  ClientIDMode="Static"  class="json-modal-content"></pre>
        </div>
    </div>

    <script>
        function showJsonModal(jsonText) {
            document.getElementById("jsonModalContent").textContent = jsonText;
            document.getElementById("jsonModal").style.display = "flex";
        }
        function closeJsonModal() {
            document.getElementById("jsonModal").style.display = "none";
        }


        function openPdfViewer(src)
        {


        }


        function openImageViewer(src) {
            const w = window.open("", "_blank", "width=1100,height=800,resizable=yes,scrollbars=no");
            if (!w) return alert("Popup bloquée. Autorise les popups pour ce site.");

            w.document.write(`<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Image Viewer</title>
<style>
  html,body{height:100%;margin:0;background:#f6f7fb;color:#0f172a;font-family:system-ui,Segoe UI,Roboto,Arial;}
  .topbar{
    position:fixed; left:0; right:0; top:0; height:54px;
    display:flex; align-items:center; justify-content:space-between;
    padding:0 12px; background:rgba(255,255,255,.82); backdrop-filter: blur(10px);
    border-bottom:1px solid rgba(0,0,0,.10);
    z-index:10;
  }
  .btn{
    appearance:none; border:1px solid rgba(0,0,0,.14);
    background:#fff; color:#0f172a;
    padding:8px 10px; border-radius:10px; cursor:pointer;
    font-weight:700; font-size:13px;
  }
  .btn:hover{background:#f1f5f9;}
  .btn:active{transform: translateY(1px);}
  .group{display:flex;gap:8px;align-items:center;}
  .hint{opacity:.75;font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:55vw}
  .stage{
    position:fixed; inset:54px 0 0 0;
    overflow:hidden; cursor:grab;
    display:block;
    background:#f6f7fb;
  }
  .stage.grabbing{cursor:grabbing;}
  img{
    position:absolute;
    left:0; top:0;
    user-select:none; -webkit-user-drag:none;
    transform-origin: 0 0;
    will-change: transform;
    max-width:none; max-height:none;
    box-shadow: 0 18px 60px rgba(0,0,0,.18);
    border-radius:14px;
    background:#fff;
  }
</style>

</head>
<body>
  <div class="topbar">
    <div class="group">
      <button class="btn" id="btnClose">Fermer (Esc)</button>
      <button class="btn" id="btnFit">Ajuster</button>
      <button class="btn" id="btnReset">Reset</button>
      <button class="btn" id="btnZoomOut">-</button>
      <button class="btn" id="btnZoomIn">+</button>
      <span class="hint">Molette: zoom • Drag: déplacer • Double-clic: zoom • Espace: recentrer</span>
    </div>
    <div class="group">
      <a class="btn" id="btnDl" href="${src}" download>Télécharger</a>
    </div>
  </div>

  <div class="stage" id="stage">
    <img id="img" src="${src}" alt="image" />
  </div>

<script>
(() => {
  const img = document.getElementById('img');
  const stage = document.getElementById('stage');

  let scale = 1;
  let x = 0, y = 0;
  let dragging = false;
  let startX = 0, startY = 0;
  let imgLoaded = false;

  function apply() {
    img.style.transform = \`translate(\${x}px,\${y}px) scale(\${scale})\`;
  }

  function clampScale(s) {
    return Math.min(10, Math.max(0.05, s));
  }

  function centerImage() {
    const sw = stage.clientWidth;
    const sh = stage.clientHeight;
    const iw = img.naturalWidth * scale;
    const ih = img.naturalHeight * scale;

    x = (sw - iw) / 2;
    y = (sh - ih) / 2;
    apply();
  }

  function fitAndCenter() {
    const sw = stage.clientWidth;
    const sh = stage.clientHeight;
    const iw = img.naturalWidth;
    const ih = img.naturalHeight;
    if (!iw || !ih) return;

    const s = Math.min(sw / iw, sh / ih) * 0.98;
    scale = clampScale(s);
    centerImage();
  }

  function zoomAt(clientX, clientY, factor) {
    const rect = stage.getBoundingClientRect();
    const px = clientX - rect.left;
    const py = clientY - rect.top;

    const wx = (px - x) / scale;
    const wy = (py - y) / scale;

    const next = clampScale(scale * factor);

    x = px - wx * next;
    y = py - wy * next;
    scale = next;
    apply();
  }

  function zoomCenter(factor) {
    const rect = stage.getBoundingClientRect();
    zoomAt(rect.left + stage.clientWidth/2, rect.top + stage.clientHeight/2, factor);
  }

  img.addEventListener('load', () => {
    imgLoaded = true;
    fitAndCenter();
  });

  stage.addEventListener('mousedown', (e) => {
    if (!imgLoaded) return;
    dragging = true;
    stage.classList.add('grabbing');
    startX = e.clientX - x;
    startY = e.clientY - y;
  });

  window.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    x = e.clientX - startX;
    y = e.clientY - startY;
    apply();
  });

  window.addEventListener('mouseup', () => {
    dragging = false;
    stage.classList.remove('grabbing');
  });

  stage.addEventListener('wheel', (e) => {
    if (!imgLoaded) return;
    e.preventDefault();
    const factor = e.deltaY < 0 ? 1.12 : 1/1.12;
    zoomAt(e.clientX, e.clientY, factor);
  }, { passive:false });

  stage.addEventListener('dblclick', (e) => {
    if (!imgLoaded) return;
    if (scale < 1.05) zoomAt(e.clientX, e.clientY, 2.0);
    else fitAndCenter();
  });

  document.getElementById('btnClose').onclick = () => window.close();
  document.getElementById('btnFit').onclick = () => fitAndCenter();
  document.getElementById('btnReset').onclick = () => { scale = 1; centerImage(); };
  document.getElementById('btnZoomIn').onclick = () => zoomCenter(1.2);
  document.getElementById('btnZoomOut').onclick = () => zoomCenter(1/1.2);

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') window.close();
    if (e.key === ' ') { e.preventDefault(); centerImage(); }
  });

  window.addEventListener('resize', () => {
    if (!imgLoaded) return;
    fitAndCenter();
  });
})();
<\/script>
</body>
</html>`);

            w.document.close();
        }
    </script>


</asp:Content>
