<%@ Page Title="Courriel" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master" CodeBehind="wbfMailbox.aspx.vb"
    Inherits="MngConsul.wbfMailbox" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">Courriel</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* ── Courriel : la signature du gabarit « Portail du client ». Le titre pose sur le fond,
           l'adresse et « + Composer » à droite, quatre indicateurs, la carte des dossiers,
           puis la liste et la lecture (ou la rédaction) en cartes blanches. ── */
        .mail-wrap { color: #0E1F3D }
        .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
        .fc-tete .txt { flex: 1 1 260px }
        .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
        .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
        .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
        .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px; align-items: center }
        .mail-addr { display: inline-flex; align-items: center; min-height: 44px; padding: 0 16px; border-radius: 999px; background: #E3EBF7; color: #143A73; font-weight: 800; font-size: 14px }
        .fc-btn, a.fc-btn { display: inline-flex; align-items: center; min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer; text-decoration: none }
        .fc-btn.primaire, a.fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
        .fc-btn.primaire:hover, a.fc-btn.primaire:hover { background: #143A73; color: #fff }
        .fc-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 16px }
        .fc-kpi { padding: 14px 16px; border-radius: 22px; display: flex; flex-direction: column; gap: 2px; background: #fff; color: #0E1F3D }
        .fc-kpi .lab { display: flex; align-items: center; gap: 8px; font-weight: 700; color: #44536E; font-size: 14px }
        .fc-kpi .lab i { width: 10px; height: 10px; border-radius: 50%; flex: none }
        .fc-kpi .val { font-size: 24px; font-weight: 800; line-height: 1.15 }
        .fc-kpi .sub { font-size: 14px; color: #44536E }
        .fc-filtres { padding: 16px 18px; border-radius: 24px; background: #fff; display: flex; flex-wrap: wrap; gap: 10px 24px; align-items: flex-end; margin-bottom: 16px }
        .fc-groupe { display: flex; flex-direction: column; gap: 6px; font-size: 13px; font-weight: 800; color: #5B6B86 }
        .fc-pills { display: flex; flex-wrap: wrap; gap: 4px; padding: 4px; background: #E8EDF5; border-radius: 999px }
        .fc-pill, a.fc-pill { display: inline-flex; align-items: center; min-height: 36px; padding: 0 14px; border: 0; border-radius: 999px; font-weight: 700; font-size: 14px; font-family: inherit; background: transparent; color: #0E1F3D; cursor: pointer; text-decoration: none }
        .fc-pill:hover, a.fc-pill:hover { background: rgba(255,255,255,.6); color: #0E1F3D }
        .fc-pill.on, a.fc-pill.on { background: #fff; box-shadow: 0 1px 2px rgba(14,31,61,.12) }
        .mail-cols { display: grid; grid-template-columns: 400px minmax(0, 1fr); gap: 16px; align-items: start }
        .mail-list { border: 0; border-radius: 24px; background: #fff; padding: 6px 12px 12px; max-height: 70vh; overflow-y: auto }
        .mrow { display: block; width: 100%; text-align: left; padding: 12px 6px; border: 0; border-top: 1px solid #E3E9F1; background: #fff; cursor: pointer; text-decoration: none; color: inherit; font-family: inherit }
        .mrow:first-child { border-top: 0 }
        .mrow:hover { background: #FAFCFF; color: inherit }
        .mrow .r1 { display: flex; justify-content: space-between; gap: 10px }
        .mrow .who { font-weight: 800; font-size: 15px; color: #0E1F3D; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 230px }
        .mrow .when { font-size: 13px; color: #44536E; white-space: nowrap }
        .mrow .subj { font-size: 14px; color: #44536E; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
        .fc-pay { display: inline-block; margin-top: 4px; padding: 3px 10px; border-radius: 999px; font-size: 13px; font-weight: 800; white-space: nowrap }
        .mail-read { border: 0; border-radius: 24px; background: #fff; padding: 0; min-height: 320px; overflow: hidden }
        .read-head { padding: 18px 20px; border-bottom: 1px solid #E3E9F1 }
        .read-subj { font-size: 19px; font-weight: 800; margin: 0 0 8px }
        .read-meta { font-size: 14px; color: #44536E; line-height: 1.6 }
        .read-meta b { color: #0E1F3D }
        .mailframe { width: 100%; height: 55vh; border: 0; background: #fff }
        .read-empty { padding: 40px 20px; text-align: center; color: #44536E; font-size: 15px; font-weight: 700 }
        .attach { margin-top: 6px; font-size: 14px; color: #7A5200 }
        .compose { max-width: 820px; border: 0; border-radius: 24px; background: #fff; padding: 18px 20px }
        .compose label { display: block; font-size: 13px; font-weight: 800; color: #5B6B86; margin: 12px 0 4px }
        .compose input[type=text], .compose textarea { width: 100%; min-height: 44px; padding: 9px 14px; border: 1px solid #AEBBCD; border-radius: 12px; font: inherit; box-sizing: border-box }
        .compose textarea { min-height: 220px; resize: vertical }
        .compose .from-note { font-size: 14px; color: #0E1F3D; margin-top: 2px; font-weight: 700 }
        .compose .compose-file { margin-top: 4px; font: inherit }
        .btn-send { margin-top: 16px; min-height: 44px; padding: 0 22px; background: #1B4F9C; color: #fff; border: 1px solid #1B4F9C; border-radius: 999px; font-weight: 800; font-size: 14px; font-family: inherit; cursor: pointer }
        .btn-send:hover { background: #143A73 }
        .send-msg { margin-top: 14px; padding: 12px 16px; border-radius: 16px; font-size: 14px; font-weight: 700 }
        .send-msg.ok { background: #E3F3EA; color: #0F5A3A }
        .send-msg.err { background: #FDECEA; color: #A3261C }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="mail-wrap">
        <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique, le titre,
             le sous-titre ; à droite l'adresse de la boîte et « + Composer » en pastille bleue. --%>
        <div class="fc-tete">
            <div class="txt">
                <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
                <h1><asp:Literal ID="litTitre" runat="server" /></h1>
                <p><asp:Literal ID="litSousTitre" runat="server" /></p>
            </div>
            <div class="btns">
                <span class="mail-addr"><asp:Literal ID="litAddr" runat="server" /></span>
                <asp:LinkButton ID="lbCompose" runat="server" CssClass="fc-btn primaire" OnClick="lbCompose_Click" CausesValidation="false">+ Composer</asp:LinkButton>
            </div>
        </div>

        <%-- Les quatre indicateurs : reçus, envoyés, en file, non envoyés. --%>
        <div class="fc-kpis"><asp:Literal ID="litKpis" runat="server" /></div>

        <%-- Les dossiers en pastilles : Réception, Envoyés. --%>
        <section class="fc-filtres">
            <div class="fc-groupe"><asp:Literal ID="litDossier" runat="server" /><div class="fc-pills" role="group">
                <asp:LinkButton ID="lbInbox" runat="server" CssClass="fc-pill on" OnClick="lbInbox_Click" CausesValidation="false">Réception</asp:LinkButton>
                <asp:LinkButton ID="lbSent" runat="server" CssClass="fc-pill" OnClick="lbSent_Click" CausesValidation="false">Envoyés</asp:LinkButton>
            </div></div>
        </section>

        <asp:Panel ID="pnlBrowse" runat="server">
            <div class="mail-cols">
                <div class="mail-list">
                    <asp:Repeater ID="rptInbox" runat="server" OnItemCommand="rptInbox_ItemCommand">
                        <ItemTemplate>
                            <asp:LinkButton runat="server" CssClass="mrow" CommandName="open"
                                CommandArgument='<%# Eval("Id") %>' CausesValidation="false">
                                <span class="r1">
                                    <span class="who"><%# Server.HtmlEncode(If(Eval("MailFrom") Is Nothing, "", Eval("MailFrom").ToString())) %></span>
                                    <span class="when"><%# FormatDate(Eval("ReceivedAtUtc")) %></span>
                                </span>
                                <span class="subj"><%# Server.HtmlEncode(SubjectOr(Eval("SubjectHeader"))) %></span>
                           </asp:LinkButton>
                        </ItemTemplate>
                    </asp:Repeater>
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
                        <div class="read-empty"><asp:Literal ID="litListEmpty" runat="server" /></div>
                    </asp:Panel>
                </div>

                <div class="mail-read">
                    <asp:Panel ID="pnlReadEmpty" runat="server">
                        <div class="read-empty"><asp:Literal ID="litReadEmpty" runat="server" /></div>
                    </asp:Panel>
                    <asp:Panel ID="pnlRead" runat="server" Visible="false">
                        <div class="read-head">
                            <p class="read-subj"><asp:Literal ID="litSubject" runat="server" /></p>
                            <div class="read-meta">
                                <div><b>De :</b> <asp:Literal ID="litFrom" runat="server" /></div>
                                <div><b>À :</b> <asp:Literal ID="litTo" runat="server" /></div>
                                <div><b>Date :</b> <asp:Literal ID="litDate" runat="server" /></div>
                                <asp:Panel ID="pnlAttach" runat="server" Visible="false" CssClass="attach">
                                    <i class="ic ic-paperclip" aria-hidden="true"></i> Pièces jointes : <asp:Literal ID="litAttach" runat="server" />
                                </asp:Panel>
                            </div>
                        </div>
                        <asp:Literal ID="litBody" runat="server" />
                    </asp:Panel>
                </div>
            </div>
        </asp:Panel>

        <asp:Panel ID="pnlCompose" runat="server" Visible="false">
            <div class="compose">
                <label>De</label>
                <div class="from-note"><asp:Literal ID="litComposeFrom" runat="server" /></div>

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
                <div class="from-note" style="font-weight:600;color:#44536E;">Vous pouvez sélectionner plusieurs fichiers (50 Mo max au total).</div>

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
                if (box) { box.style.display = ''; box.innerHTML = '<i class="ic ic-x-circle" aria-hidden="true"></i> Champ(s) obligatoire(s) manquant(s) : ' + miss.join(', ') + '.'; }
                if (miss[0] === 'destinataire' && toEl) toEl.focus();
                return false;
            }
            if (box) box.style.display = 'none';
            return true;
        }
    </script>
</asp:Content>
