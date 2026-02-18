

<%@ Page Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.master"
    CodeBehind="wbfReceipt.aspx.vb" Async="true" MaintainScrollPositionOnPostback="true" Inherits="MngConsul.wbfReceipt" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Reçus — MngConsul
</asp:Content>
<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
     
 
     
    <style>
/* Modal JSON - Theme clair */
.json-modal-overlay{
    position:fixed;
    inset:0;
    background:rgba(15, 23, 42, .45); /* overlay doux */
    display:flex;
    justify-content:center;
    align-items:center;
    z-index:99999;
}

.json-modal-box{
    width: min(1000px, 92vw);
    max-height: 85vh;
    background: #ffffff;
    border-radius: 16px;
    overflow: hidden;
    display:flex;
    flex-direction:column;
    box-shadow: 0 30px 80px rgba(0,0,0,.25);
    border: 1px solid rgba(0,0,0,.10);
}

.json-modal-header{
    padding: 14px 18px;
    background: #f8fafc;
    color: #0f172a;
    display:flex;
    justify-content:space-between;
    align-items:center;
    font-weight: 800;
    border-bottom: 1px solid rgba(0,0,0,.10);
}

.json-modal-close{
    border: 1px solid rgba(0,0,0,.14);
    background: #ffffff;
    color: #0f172a;
    font-size: 14px;
    cursor: pointer;
    border-radius: 10px;
    padding: 6px 10px;
    font-weight: 800;
}

.json-modal-close:hover{
    background:#f1f5f9;
}

.json-modal-content{
    flex:1;
    overflow:auto;
    padding: 18px;
    font-family: Consolas, ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
    font-size: 13px;
    color: #0f172a;
    background: #ffffff;
    white-space: pre-wrap;
    word-break: break-word;
}

/* JSON "code look" plus lisible */
.json-modal-content{
    border-top: 0;
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

            <telerik:RadGrid ID="RadReceipt" runat="server"
                CssClass="grid"
                AutoGenerateColumns="False"
                AllowPaging="True"
                Skin="Bootstrap"
                PageSize="20"
                AllowSorting="True"
                AllowFilteringByColumn="False"
                OnItemCommand="RadReceipt_ItemCommand"
                OnNeedDataSource="RadReceipt_NeedDataSource">

                <MasterTableView DataKeyNames="imageGUID" CommandItemDisplay="None">
                    <Columns>

                         
                        <telerik:GridTemplateColumn HeaderText="Action" UniqueName="Action">
                            <ItemTemplate>
                                <asp:Button ID="btnDelete"
                                    runat="server"
                                    Text="Delete"
                                    CssClass="btn"
                                    CommandName="DeleteR"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                        
                        <telerik:GridTemplateColumn HeaderText="Fichier" UniqueName="Fichier">
                            <ItemTemplate>
                                <asp:Literal ID="litHtml" runat="server" Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(CStr(Eval("SourceFileName"))) %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                         
                        <telerik:GridTemplateColumn HeaderText="Optimize for AI" UniqueName="Optimize">
                            <ItemTemplate>
                                <asp:Button ID="btnOptimize"
                                    runat="server"
                                    Text="Optimize"
                                    CssClass="btn"
                                    CommandName="Optimize"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                        
                        <telerik:GridTemplateColumn HeaderText="Fichier optimized" UniqueName="Optimized">
                            <ItemTemplate>
                                <asp:Literal ID="litHtmlOp" runat="server" Mode="PassThrough"
                                    Text='<%# Server.HtmlDecode(CStr(Eval("Optimized"))) %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                        
                        <telerik:GridTemplateColumn HeaderText="Optimize for AI" UniqueName="ProcessAI">
                            <ItemTemplate>
                                <asp:Button ID="btnProcess"
                                    runat="server"
                                    Text="Process AI"
                                    CssClass="btn"
                                    CommandName="Process"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                       
                        <telerik:GridTemplateColumn HeaderText="Voir JSON" UniqueName="VoirJSON">
                            <ItemTemplate>
                                <asp:Button ID="btnVoirJSON"
                                    runat="server"
                                    Text="Voir JSON"
                                    CssClass="btn"
                                    CommandName="VoirJSON"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                       
                        <telerik:GridTemplateColumn HeaderText="Optimize for AI" UniqueName="ProcessJSON">
                            <ItemTemplate>
                                <asp:Button ID="btnProcessJSON"
                                    runat="server"
                                    Text="Process JSON"
                                    CssClass="btn"
                                    CommandName="ProcessJSON"
                                    CommandArgument='<%# Eval("imageGUID") %>' />
                            </ItemTemplate>
                        </telerik:GridTemplateColumn>

                        
                        <telerik:GridBoundColumn DataField="ProcessingStatus" HeaderText="Statut" SortExpression="ProcessingStatus" UniqueName="ProcessingStatus" />

                    </Columns>
                </MasterTableView>

                <ClientSettings>
                    <Selecting AllowRowSelect="True" />
                </ClientSettings>

            </telerik:RadGrid>

        </div>
    </div>

    <!-- Modal JSON -->
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
