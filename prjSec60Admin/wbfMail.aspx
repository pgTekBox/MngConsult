<%@ Page Title="Courriel" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfMail.aspx.vb"
    Inherits="prjSec60Admin.wbfMail" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Courriel — Sec60Admin</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .mail-wrap { padding: 18px 20px; font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; color: #0f172a; }
        .mail-wrap h1 { font-size: 22px; font-weight: 900; margin: 0 0 14px; }
        .mail-tabs { display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap; align-items: center; }
        .mail-tab { padding: 9px 16px; border: 1px solid #e2e8f0; background: #fff; border-radius: 10px; font-weight: 800; font-size: 13px; color: #334155; text-decoration: none; cursor: pointer; }
        .mail-tab.active { background: #2563eb; color: #fff; border-color: #2563eb; }
        .mail-filter { margin-left: auto; font-size: 13px; color: #475569; }
        .mail-filter select { padding: 7px 10px; border: 1px solid #cbd5e1; border-radius: 8px; font: inherit; }
        .mail-cols { display: grid; grid-template-columns: 380px 1fr; gap: 16px; align-items: start; }
        .mail-list { border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background: #fff; max-height: 70vh; overflow-y: auto; }
        .mrow { display: block; width: 100%; text-align: left; padding: 11px 14px; border: none; border-bottom: 1px solid #f1f5f9; background: #fff; cursor: pointer; text-decoration: none; color: inherit; }
        .mrow:hover { background: #f8fafc; }
        .mrow .r1 { display: flex; justify-content: space-between; gap: 10px; }
        .mrow .who { font-weight: 800; font-size: 13px; color: #0f172a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 210px; }
        .mrow .when { font-size: 11px; color: #94a3b8; white-space: nowrap; }
        .mrow .subj { font-size: 13px; color: #475569; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .mrow .tag { font-size: 11px; font-weight: 700; padding: 1px 7px; border-radius: 999px; }
        .tag-ok { background: rgba(16,185,129,.12); color: #059669; }
        .tag-q { background: rgba(37,99,235,.12); color: #2563eb; }
        .tag-err { background: rgba(239,68,68,.12); color: #dc2626; }
        .mail-read { border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 0; min-height: 320px; }
        .read-head { padding: 14px 16px; border-bottom: 1px solid #eef2f7; }
        .read-subj { font-size: 17px; font-weight: 900; margin: 0 0 8px; }
        .read-meta { font-size: 12px; color: #475569; line-height: 1.6; }
        .read-meta b { color: #0f172a; }
        .mailframe { width: 100%; height: 55vh; border: 0; background: #fff; }
        .read-empty { padding: 40px; text-align: center; color: #94a3b8; font-size: 14px; }
        .attach { margin-top: 6px; font-size: 12px; color: #b45309; }
        /* Compose */
        .compose { max-width: 780px; border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 18px 20px; }
        .compose label { display: block; font-size: 12px; font-weight: 800; color: #334155; margin: 12px 0 4px; }
        .compose input[type=text], .compose textarea { width: 100%; padding: 9px 11px; border: 1px solid #cbd5e1; border-radius: 8px; font: inherit; box-sizing: border-box; }
        .compose textarea { min-height: 220px; resize: vertical; }
        .compose .from-note { font-size: 12px; color: #64748b; margin-top: 2px; }
        .compose .compose-file { margin-top: 4px; font: inherit; }
        .btn-send { margin-top: 16px; padding: 11px 22px; background: #2563eb; color: #fff; border: none; border-radius: 10px; font-weight: 800; font-size: 14px; cursor: pointer; }
        .btn-send:hover { background: #1d4ed8; }
        .send-msg { margin-top: 14px; padding: 10px 14px; border-radius: 10px; font-size: 13px; font-weight: 700; }
        .send-msg.ok { background: rgba(16,185,129,.12); color: #059669; border: 1px solid rgba(16,185,129,.3); }
        .send-msg.err { background: rgba(239,68,68,.1); color: #dc2626; border: 1px solid rgba(239,68,68,.3); }
        @media (max-width: 900px){ .mail-cols { grid-template-columns: 1fr; } }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="mail-wrap">
        <h1>✉️ Courriel — service 60Sec</h1>

        <div class="mail-tabs">
            <asp:LinkButton ID="lbInbox"   runat="server" CssClass="mail-tab" OnClick="lbInbox_Click"   CausesValidation="false">📥 Réception</asp:LinkButton>
            <asp:LinkButton ID="lbSent"    runat="server" CssClass="mail-tab" OnClick="lbSent_Click"    CausesValidation="false">📤 Envoyés</asp:LinkButton>
            <asp:LinkButton ID="lbCompose" runat="server" CssClass="mail-tab" OnClick="lbCompose_Click" CausesValidation="false">✍️ Composer</asp:LinkButton>

            <asp:Panel ID="pnlFilter" runat="server" CssClass="mail-filter">
                Boîte :
                <asp:DropDownList ID="ddlMailbox" runat="server" AutoPostBack="true"
                    OnSelectedIndexChanged="ddlMailbox_SelectedIndexChanged" />
            </asp:Panel>
        </div>

        <!-- ===== Vues liste + lecture ===== -->
        <asp:Panel ID="pnlBrowse" runat="server">
            <div class="mail-cols">
                <div class="mail-list">
                    <%-- Réception --%>
                    <asp:Repeater ID="rptInbox" runat="server" OnItemCommand="rptInbox_ItemCommand">
                        <ItemTemplate>
                            <asp:LinkButton runat="server" CssClass="mrow" CommandName="open"
                                CommandArgument='<%# Eval("Id") %>' CausesValidation="false">
                                <span class="r1">
                                    <span class="who"><%# Server.HtmlEncode(If(Eval("MailFrom") Is Nothing, "", Eval("MailFrom").ToString())) %></span>
                                    <span class="when"><%# FormatDate(Eval("ReceivedAtUtc")) %></span>
                                </span>
                                <span class="subj"><%# Server.HtmlEncode(SubjectOr(Eval("SubjectHeader"))) %></span>
                                <span class="subj" style="color:#94a3b8;font-size:11px;">→ <%# Server.HtmlEncode(If(Eval("RcptTo") Is Nothing, "", Eval("RcptTo").ToString())) %></span>
                            </asp:LinkButton>
                        </ItemTemplate>
                    </asp:Repeater>
                    <%-- Envoyés --%>
                    <asp:Repeater ID="rptSent" runat="server" OnItemCommand="rptSent_ItemCommand">
                        <ItemTemplate>
                            <asp:LinkButton runat="server" CssClass="mrow" CommandName="open"
                                CommandArgument='<%# Eval("Id") %>' CausesValidation="false">
                                <span class="r1">
                                    <span class="who">→ <%# Server.HtmlEncode(If(Eval("To") Is Nothing, "", Eval("To").ToString())) %></span>
                                    <span class="when"><%# FormatDate(Eval("Created")) %></span>
                                </span>
                                <span class="subj"><%# Server.HtmlEncode(SubjectOr(Eval("Subject"))) %></span>
                                <span><%# SentStatusTag(Eval("SendWithSuccess"), Eval("ToSend")) %></span>
                            </asp:LinkButton>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlListEmpty" runat="server" Visible="false">
                        <div class="read-empty">Aucun message.</div>
                    </asp:Panel>
                </div>

                <div class="mail-read">
                    <asp:Panel ID="pnlReadEmpty" runat="server">
                        <div class="read-empty">Sélectionnez un message pour le lire.</div>
                    </asp:Panel>
                    <asp:Panel ID="pnlRead" runat="server" Visible="false">
                        <div class="read-head">
                            <p class="read-subj"><asp:Literal ID="litSubject" runat="server" /></p>
                            <div class="read-meta">
                                <div><b>De :</b> <asp:Literal ID="litFrom" runat="server" /></div>
                                <div><b>À :</b> <asp:Literal ID="litTo" runat="server" /></div>
                                <div><b>Date :</b> <asp:Literal ID="litDate" runat="server" /></div>
                                <asp:Panel ID="pnlAttach" runat="server" Visible="false" CssClass="attach">
                                    📎 Pièces jointes : <asp:Literal ID="litAttach" runat="server" />
                                </asp:Panel>
                            </div>
                        </div>
                        <asp:Literal ID="litBody" runat="server" />
                    </asp:Panel>
                </div>
            </div>
        </asp:Panel>

        <!-- ===== Composer ===== -->
        <asp:Panel ID="pnlCompose" runat="server" Visible="false">
            <div class="compose">
                <label>De</label>
                <div class="from-note">noreply@60sec.ca (expéditeur du service — l'adresse ne peut pas être usurpée pour respecter SPF/DMARC)</div>

                <label for="<%= txtTo.ClientID %>">À <span style="color:#dc2626">*</span></label>
                <asp:TextBox ID="txtTo" runat="server" placeholder="destinataire@exemple.com" />

                <label for="<%= txtCc.ClientID %>">Cc</label>
                <asp:TextBox ID="txtCc" runat="server" placeholder="(optionnel)" />

                <label for="<%= txtSubject.ClientID %>">Sujet <span style="color:#dc2626">*</span></label>
                <asp:TextBox ID="txtSubject" runat="server" />

                <label>Message <span style="color:#dc2626">*</span></label>
                <telerik:RadEditor ID="reBody" runat="server"
                    RenderMode="Lightweight" Skin="Bootstrap"
                    Width="100%" Height="300px"
                    EditModes="Design"
                    ContentAreaMode="Iframe"
                    ToolbarMode="Default">
                    <Tools>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="Bold" />
                            <telerik:EditorTool Name="Italic" />
                            <telerik:EditorTool Name="Underline" />
                            <telerik:EditorTool Name="StrikeThrough" />
                        </telerik:EditorToolGroup>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="JustifyLeft" />
                            <telerik:EditorTool Name="JustifyCenter" />
                            <telerik:EditorTool Name="JustifyRight" />
                            <telerik:EditorTool Name="JustifyFull" />
                        </telerik:EditorToolGroup>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="Outdent" />
                            <telerik:EditorTool Name="Indent" />
                            <telerik:EditorTool Name="InsertUnorderedList" />
                            <telerik:EditorTool Name="InsertOrderedList" />
                        </telerik:EditorToolGroup>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="ForeColor" />
                            <telerik:EditorTool Name="BackColor" />
                        </telerik:EditorToolGroup>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="InsertTable" />
                        </telerik:EditorToolGroup>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="FontName" />
                            <telerik:EditorTool Name="RealFontSize" />
                        </telerik:EditorToolGroup>
                    </Tools>
                    <Content></Content>
                </telerik:RadEditor>

                <label for="<%= fuAttach.ClientID %>">Pièces jointes</label>
                <asp:FileUpload ID="fuAttach" runat="server" AllowMultiple="true" CssClass="compose-file" />
                <div class="from-note">Vous pouvez sélectionner plusieurs fichiers (50 Mo max au total).</div>

                <div id="composeErr" class="send-msg err" style="display:none;margin-top:10px;"></div>

                <asp:Button ID="btnSend" runat="server" CssClass="btn-send" Text="Envoyer"
                    OnClick="btnSend_Click" OnClientClick="return validateCompose();" />

                <asp:Panel ID="pnlSendMsg" runat="server" Visible="false">
                    <asp:Literal ID="litSendMsg" runat="server" />
                </asp:Panel>
            </div>
        </asp:Panel>
    </div>

    <script type="text/javascript">
        // Validation côté client : évite le postback (et donc la perte de la pièce
        // jointe) tant que destinataire / sujet / message ne sont pas remplis.
        function validateCompose() {
            var toEl = document.getElementById('<%= txtTo.ClientID %>');
            var subjEl = document.getElementById('<%= txtSubject.ClientID %>');
            var to = toEl ? toEl.value : '';
            var subj = subjEl ? subjEl.value : '';
            var txt = '';
            var ed = (typeof $find === 'function') ? $find('<%= reBody.ClientID %>') : null;
            if (ed && ed.get_text) { try { txt = ed.get_text(); } catch (e) { } }

            var miss = [];
            if (!to || !to.trim()) miss.push('destinataire');
            if (!subj || !subj.trim()) miss.push('sujet');
            if (!txt || !txt.trim()) miss.push('message');

            var box = document.getElementById('composeErr');
            if (miss.length > 0) {
                if (box) { box.style.display = ''; box.innerHTML = '✖ Champ(s) obligatoire(s) manquant(s) : ' + miss.join(', ') + '.'; }
                if (miss[0] === 'destinataire' && toEl) toEl.focus();
                return false;
            }
            if (box) box.style.display = 'none';
            return true;
        }
    </script>
</asp:Content>
