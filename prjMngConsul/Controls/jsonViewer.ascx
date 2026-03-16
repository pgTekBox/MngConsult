<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="jsonViewer.ascx.vb" Inherits="MngConsul.jsonViewer" %>

<link href="../css/JsonViewer.css" rel="stylesheet" />


    <!-- Modal JSON -->
    <div id="jsonModal" runat="server" class="json-modal-overlay" clientidmode="Static" style="display: none;">
        <div class="json-modal-box">
            <div class="json-modal-header">
                <div>🤖 Résultat Analyse AI (JSON)</div>
                <button type="button" class="json-modal-close" onclick="closeJsonModal()">✖</button>
            </div>
            <pre id="jsonModalContent" runat="server" clientidmode="Static" class="json-modal-content"></pre>
        </div>
    </div>

<script src="js/JsonView.js"></script>