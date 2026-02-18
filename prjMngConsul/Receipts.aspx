<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.master"
    CodeBehind="Receipts.aspx.vb" Async="true" MaintainScrollPositionOnPostback="true" Inherits="MngConsul.Receipts" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Reçus — MngConsul
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <style>
.json-modal-overlay{
    position:fixed;
    inset:0;
    background:rgba(0,0,0,.7);
    display:flex;
    justify-content:center;
    align-items:center;
    z-index:99999;
}

.json-modal-box{
    width:80%;
    max-width:1000px;
    max-height:85vh;
    background:#0b0f16;
    border-radius:16px;
    overflow:hidden;
    display:flex;
    flex-direction:column;
    box-shadow:0 30px 80px rgba(0,0,0,.6);
}

.json-modal-header{
    padding:14px 18px;
    background:#111827;
    color:#fff;
    display:flex;
    justify-content:space-between;
    align-items:center;
    font-weight:700;
}

.json-modal-close{
    border:none;
    background:none;
    color:#fff;
    font-size:18px;
    cursor:pointer;
}

.json-modal-content{
    flex:1;
    overflow:auto;
    padding:20px;
    font-family:Consolas, monospace;
    font-size:13px;
    color:#00ff9c;
    background:#020617;
}
</style>

    <div class="toolbar">
        <div class="title">Reçus (T0001Receipt)</div>

        <div class="searchbox">
            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (fournisseur, fichier, statut…)" />
            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
        </div>
    </div>

    <div class="pad">
        <asp:Label ID="lblInfo" runat="server" CssClass="pill" Visible="false" />

        <div style="margin-top: 12px; overflow: auto;">
            <asp:GridView ID="gvReceipts" runat="server"
                CssClass="grid"
                AutoGenerateColumns="False"
                AllowPaging="True"
                PageSize="20"
                OnRowCommand="gvReceipts_RowCommand"
                AllowSorting="True">
                <Columns>

                    <asp:TemplateField HeaderText="Action">
                        <ItemTemplate>
                            <asp:Button ID="btnDelete"
                                runat="server"
                                Text="Delete"
                                CssClass="btn"
                                CommandName="DeleteR"
                                CommandArgument='<%# Eval("imageGUID") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>





                    <asp:TemplateField HeaderText="Fichier">
                        <ItemTemplate>
                            <asp:Literal ID="litHtml" runat="server" Mode="PassThrough"
                                Text='<%# Server.HtmlDecode(CStr(Eval("SourceFileName"))) %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Optimize for AI">

                        <ItemTemplate>
                            <asp:Button ID="btnOptimize"
                                runat="server"
                                Text="Optimize"
                                CssClass="btn"
                                CommandName="Optimize"
                                CommandArgument='<%# Eval("imageGUID") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Fichier optimized">
                        <ItemTemplate>
                            <asp:Literal ID="litHtmlOp" runat="server" Mode="PassThrough"
                                Text='<%# Server.HtmlDecode(CStr(Eval("Optimized"))) %>' />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Optimize for AI">

                        <ItemTemplate>
                            <asp:Button ID="btnProcess"
                                runat="server"
                                Text="Process AI"
                                CssClass="btn"
                                CommandName="Process"
                                CommandArgument='<%# Eval("imageGUID") %>' />
                        </ItemTemplate>
                    </asp:TemplateField>

                     <asp:TemplateField HeaderText="Voir JSON">

     <ItemTemplate>
         <asp:Button ID="btnVoirJSON"
             runat="server"
             Text="Voir JSON"
             CssClass="btn"
             CommandName="VoirJSON"
             CommandArgument='<%# Eval("imageGUID") %>' />
     </ItemTemplate>
 </asp:TemplateField>
                    <asp:TemplateField HeaderText="Optimize for AI">

    <ItemTemplate>
        <asp:Button ID="btnProcessJSON"
            runat="server"
            Text="Process JSON"
            CssClass="btn"
            CommandName="ProcessJSON"
            CommandArgument='<%# Eval("imageGUID") %>' />
    </ItemTemplate>
</asp:TemplateField>
                    <asp:BoundField DataField="ProcessingStatus" HeaderText="Statut" SortExpression="ProcessingStatus" />
                </Columns>
            </asp:GridView>
        </div>
    </div>
    <div id="jsonModal" class="json-modal-overlay" style="display:none;">
    <div class="json-modal-box">

        <div class="json-modal-header">
            <div>🤖 Résultat Analyse AI (JSON)</div>
            <button type="button" class="json-modal-close" onclick="closeJsonModal()">✖</button>
        </div>

        <pre id="jsonModalContent" class="json-modal-content"></pre>

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
  html,body{height:100%;margin:0;background:#0b0f16;color:#fff;font-family:system-ui,Segoe UI,Roboto,Arial;}
  .topbar{
    position:fixed; left:0; right:0; top:0; height:54px;
    display:flex; align-items:center; justify-content:space-between;
    padding:0 12px; background:rgba(10,14,22,.78); backdrop-filter: blur(8px);
    border-bottom:1px solid rgba(255,255,255,.08);
    z-index:10;
  }
  .btn{
    appearance:none; border:1px solid rgba(255,255,255,.18);
    background:rgba(255,255,255,.08); color:#fff;
    padding:8px 10px; border-radius:10px; cursor:pointer;
    font-weight:600; font-size:13px;
  }
  .btn:hover{background:rgba(255,255,255,.14);}
  .btn:active{transform: translateY(1px);}
  .group{display:flex;gap:8px;align-items:center;}
  .hint{opacity:.75;font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:55vw}
  .stage{
    position:fixed; inset:54px 0 0 0;
    overflow:hidden; cursor:grab;
    display:block;
  }
  .stage.grabbing{cursor:grabbing;}
  img{
    position:absolute;
    left:0; top:0;
    user-select:none; -webkit-user-drag:none;
    transform-origin: 0 0;
    will-change: transform;
    max-width:none; max-height:none;
    box-shadow: 0 18px 60px rgba(0,0,0,.55);
    border-radius:14px;
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

  // ✅ centrage parfait à l'échelle actuelle
  function centerImage() {
    const sw = stage.clientWidth;
    const sh = stage.clientHeight;
    const iw = img.naturalWidth * scale;
    const ih = img.naturalHeight * scale;

    x = (sw - iw) / 2;
    y = (sh - ih) / 2;
    apply();
  }

  // ✅ fit + centre
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

  // Zoom autour d’un point (molette / dblclick)
  function zoomAt(clientX, clientY, factor) {
    const rect = stage.getBoundingClientRect();
    const px = clientX - rect.left;
    const py = clientY - rect.top;

    // point monde avant zoom
    const wx = (px - x) / scale;
    const wy = (py - y) / scale;

    const next = clampScale(scale * factor);

    // garder le point sous la souris stable
    x = px - wx * next;
    y = py - wy * next;
    scale = next;
    apply();
  }

  function zoomCenter(factor) {
    const rect = stage.getBoundingClientRect();
    zoomAt(rect.left + stage.clientWidth/2, rect.top + stage.clientHeight/2, factor);
  }

  // Load
  img.addEventListener('load', () => {
    imgLoaded = true;
    fitAndCenter();
  });

  // Drag
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

  // Zoom molette (smooth)
  stage.addEventListener('wheel', (e) => {
    if (!imgLoaded) return;
    e.preventDefault();
    const factor = e.deltaY < 0 ? 1.12 : 1/1.12;
    zoomAt(e.clientX, e.clientY, factor);
  }, { passive:false });

  // Double clic
  stage.addEventListener('dblclick', (e) => {
    if (!imgLoaded) return;
    // si on est proche du fit -> zoom in, sinon refit
    if (scale < 1.05) zoomAt(e.clientX, e.clientY, 2.0);
    else fitAndCenter();
  });

  // Buttons
  document.getElementById('btnClose').onclick = () => window.close();
  document.getElementById('btnFit').onclick = () => fitAndCenter();
  document.getElementById('btnReset').onclick = () => { scale = 1; centerImage(); };
  document.getElementById('btnZoomIn').onclick = () => zoomCenter(1.2);
  document.getElementById('btnZoomOut').onclick = () => zoomCenter(1/1.2);

  // Keys
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') window.close();
    if (e.key === ' ') { e.preventDefault(); centerImage(); }
  });

  // Resize -> refit proprement
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
