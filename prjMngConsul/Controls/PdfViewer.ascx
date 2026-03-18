<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="PdfViewer.ascx.vb" Inherits="MngConsul.PdfViewer" %>



<%-- Overlay PDF --%>
<div id="pdfOverlay" style="display:none;
     position:fixed; inset:0; z-index:9999;
     background:rgba(15,23,42,.55);
     display:none;
     align-items:center;
     justify-content:center;">

    <div style="
         background:#fff;
         border-radius:16px;
         box-shadow:0 20px 60px rgba(0,0,0,.3);
         width:90vw; max-width:1000px;
         height:88vh;
         display:flex;
         flex-direction:column;
         overflow:hidden;">

        <%-- Barre du haut --%>
        <div style="
             display:flex;
             align-items:center;
             justify-content:space-between;
             padding:12px 16px;
             border-bottom:1px solid #e2e8f0;">
            <strong id="pdfOverlayTitle">Document PDF</strong>
            <button onclick="closePdfOverlay()"
                    style="border:1px solid #cbd5e1;
                           background:#fff;
                           border-radius:10px;
                           width:36px; height:36px;
                           font-size:18px;
                           cursor:pointer;">✕</button>
        </div>
        <%-- Bouton mobile (caché par défaut) --%>
<a id="pdfOpenBtn" href="#" target="_blank"
   style="display:none;
          align-items:center; gap:8px;
          padding:12px 20px; margin:20px auto;
          border:1px solid #e2e8f0; border-radius:12px;
          font-weight:700; font-size:15px;
          color:#0f172a; text-decoration:none;
          background:#f8fafc;">
    📄 Ouvrir vle PDF
</a>
        <%-- iframe --%>
        <iframe id="pdfFrame"
                src=""
                style="flex:1; border:none; width:100%;">
        </iframe>

    </div>
</div>

  <script type="text/javascript">
      function isMobile() {
          return /Mobi|Android|iPhone|iPad|iPod/i.test(navigator.userAgent)
              || ('ontouchstart' in window && window.innerWidth < 900);
      }

      function openPdfOverlay(id, title) {
          var overlay = document.getElementById("pdfOverlay");
          var frame = document.getElementById("pdfFrame");
          var btn = document.getElementById("pdfOpenBtn");
          var lbl = document.getElementById("pdfOverlayTitle");
          var url =   id;

          if (lbl && title) lbl.innerText = title;

          if (isMobile()) {
              // Mobile : masquer l'iframe, afficher le bouton
           //   frame.style.display = "none";
             // btn.href = url;
              //btn.style.display = "inline-flex";
              var pdfUrl = window.location.origin + "/" + id;
              frame.src = "https://docs.google.com/viewer?url="
                  + encodeURIComponent(pdfUrl)
                  + "&embedded=true";





          } else {
              // Desktop : afficher l'iframe normalement
              frame.src = url;
              frame.style.display = "block";
              btn.style.display = "none";
          }

          overlay.style.display = "flex";
          document.body.style.overflow = "hidden";
      }

      function closePdfOverlay() {
          var overlay = document.getElementById("pdfOverlay");
          var frame = document.getElementById("pdfFrame");
          overlay.style.display = "none";
          frame.src = "";
          document.body.style.overflow = "";
      }

     

      // Fermer avec Escape
      document.addEventListener("keydown", function (e) {
          if (e.key === "Escape") closePdfOverlay();
      });

      // Fermer en cliquant le fond sombre
      document.getElementById("pdfOverlay").addEventListener("click", function (e) {
          if (e.target === this) closePdfOverlay();
      });
      </script>