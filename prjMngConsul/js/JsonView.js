


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