<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="ucJournalList.ascx.vb" Inherits="MngConsul.ucJournalList" %>

 <link href='css/listvew.css?v=<%=DateTime.Now.Ticks %>' rel="stylesheet" />

 <style>
     .badge-validee {
         display: inline-flex;
         padding: 4px 10px;
         border-radius: 999px;
         background: #ecfdf5;
         color: #059669;
         font-size: 11px;
         font-weight: 700;
         border: 1px solid #a7f3d0;
     }

     .badge-brouillon {
         display: inline-flex;
         padding: 4px 10px;
         border-radius: 999px;
         background: #fef3c7;
         color: #d97706;
         font-size: 11px;
         font-weight: 700;
         border: 1px solid #fde68a;
     }

     .badge-extournee {
         display: inline-flex;
         padding: 4px 10px;
         border-radius: 999px;
         background: #fee2e2;
         color: #dc2626;
         font-size: 11px;
         font-weight: 700;
         border: 1px solid #fecaca;
     }

     .badge-source {
         display: inline-flex;
         padding: 2px 8px;
         border-radius: 999px;
         background: #eff6ff;
         color: #1e40af;
         font-size: 10px;
         font-weight: 600;
         border: 1px solid #bfdbfe;
         margin-left: 6px;
         vertical-align: middle;
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

     .filterbar {
         display: flex;
         gap: 10px;
         align-items: end;
         flex-wrap: wrap;
     }

     .filter-field label {
         display: block;
         font-size: 11px;
         font-weight: 700;
         color: var(--muted);
         margin-bottom: 4px;
     }

     .content {
         flex: 1;
         overflow: auto;
         padding: 14px;
         padding-bottom: 90px;
     }

     .container {
         max-width: 1400px;
         margin: 0 auto;
     }

     .grid-wrap {
         background: #fff;
         border: 1px solid var(--line);
         border-radius: var(--r-xl);
         box-shadow: var(--shadow);
         overflow: hidden;
     }

     .grid-header {
         display: grid;
         grid-template-columns: 110px 100px 140px 1fr 110px 110px 110px 70px;
         padding: 12px 14px;
         font-size: 12px;
         font-weight: 900;
         color: var(--muted);
         background: #f8fafc;
         border-bottom: 1px solid var(--line);
     }

     .grid-row {
         display: grid;
         grid-template-columns: 110px 100px 140px 1fr 110px 110px 110px 70px;
         padding: 12px 14px;
         border-bottom: 1px solid #f1f5f9;
         align-items: center;
         gap: 6px;
     }

         .grid-row:hover {
             background: #f8fafc;
         }

     .ecriture-no {
         font-weight: 700;
         color: #0f172a;
     }

     .ecriture-amount {
         text-align: right;
         font-weight: 700;
     }

     .empty {
         padding: 40px;
         text-align: center;
         color: var(--muted);
     }

     .actions-cell {
         display: flex;
         gap: 4px;
         justify-content: center;
     }

     .btn-icon-edit {
         width: 30px;
         height: 30px;
         border: 1px solid #cbd5e1;
         border-radius: 8px;
         background-color: #fff;
         background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%232563eb' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7'/%3E%3Cpath d='M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z'/%3E%3C/svg%3E");
         background-repeat: no-repeat;
         background-position: center;
         background-size: 17px 17px;
         cursor: pointer;
     }

     .btn-icon-delete {
         width: 30px;
         height: 30px;
         border: 1px solid #cbd5e1;
         border-radius: 8px;
         background-color: #fff;
         background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23ef4444' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='3 6 5 6 21 6'/%3E%3Cpath d='M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6'/%3E%3Cpath d='M10 11v6'/%3E%3Cpath d='M14 11v6'/%3E%3Cpath d='M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2'/%3E%3C/svg%3E");
         background-repeat: no-repeat;
         background-position: center;
         background-size: 17px 17px;
         cursor: pointer;
     }
    /* ── La signature du gabarit « Portail du client » par-dessus la mise en page existante. ── */
    .fc-tete { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px; margin-bottom: 16px }
    .fc-tete .txt { flex: 1 1 260px }
    .fc-rubrique { font-size: 14px; font-weight: 800; color: #1B4F9C; text-transform: uppercase; letter-spacing: .06em }
    .fc-tete h1 { margin: 2px 0 0; font-size: 30px; font-weight: 800; line-height: 1.15; color: #0E1F3D }
    .fc-tete p { margin: 4px 0 0; font-size: 17px; color: #44536E }
    .fc-tete .btns { display: flex; flex-wrap: wrap; gap: 8px }
    .fc-btn { min-height: 44px; padding: 0 16px; border: 1px solid #AEBBCD; border-radius: 999px; background: #fff; color: #0E1F3D; font-weight: 700; font-size: 14px; font-family: inherit; cursor: pointer }
    .fc-btn:hover { background: #F2F5F9 }
    .fc-btn.primaire { padding: 0 20px; border-color: #1B4F9C; background: #1B4F9C; color: #fff; font-weight: 800 }
    .fc-btn.primaire:hover { background: #143A73 }
    .rw-page { height: auto }
    .rw-page .topbar { position: static; padding: 16px 18px; border: 0; border-radius: 24px; background: #fff; margin-bottom: 16px }
    .filter-field label { font-size: 13px; font-weight: 800; color: #5B6B86 }
    .rw-page .content { padding: 0; margin: 0; width: auto; max-width: none; overflow: visible }
    .rw-page .container { max-width: none; width: auto; margin: 0; padding: 0 }
    .grid-wrap { border: 0; border-radius: 24px; box-shadow: none; padding: 6px 12px 12px; overflow-x: auto }
    .grid-header { background: transparent; border: 0; color: #5B6B86; font-size: 14px; font-weight: 800; padding: 10px 6px; min-width: 900px }
    .grid-row { border: 0; border-top: 1px solid #E3E9F1; font-size: 15px; padding: 10px 6px; min-width: 900px }
    .grid-row:hover { background: #FAFCFF }
    .ecriture-no, .template-code { font-weight: 800; color: #0E1F3D }
    .badge-validee, .badge-actif { background: #E3F3EA; color: #0F5A3A; border: 0; font-size: 13px; font-weight: 800; padding: 3px 10px }
    .badge-brouillon { background: #FBF1DC; color: #7A5200; border: 0; font-size: 13px; font-weight: 800; padding: 3px 10px }
    .badge-extournee { background: #FDECEA; color: #A3261C; border: 0; font-size: 13px; font-weight: 800; padding: 3px 10px }
    .badge-inactif { background: #F2F5F9; color: #5B6B86; border: 0; font-size: 13px; font-weight: 800; padding: 3px 10px }
    .badge-source, .badge-prefilled { background: #E3EBF7; color: #143A73; border: 0; font-size: 12px; font-weight: 800 }
    .btn-icon-edit, .btn-icon-delete { width: 40px; height: 40px; border: 0; border-radius: 10px; background-size: 22px 22px }
    .btn-icon-edit:hover, .btn-icon-delete:hover { background-color: #F2F5F9 }
    .empty { padding: 20px 6px; color: #44536E; font-weight: 700 }
    .fc-pied-carte { margin-top: 12px; padding: 14px 18px; background: #fff; border-radius: 24px; color: #44536E; font-size: 14px }


    

 </style>

  
 <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>

 <telerik:RadAjaxManager ID="Ram1" runat="server">
     <AjaxSettings>
         <telerik:AjaxSetting AjaxControlID="btnFilter">
             <UpdatedControls>
                 <telerik:AjaxUpdatedControl ControlID="rpEcritures" />
                 <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                 <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                 <telerik:AjaxUpdatedControl ControlID="lblCount" />
                 <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
             </UpdatedControls>
         </telerik:AjaxSetting>
         <telerik:AjaxSetting AjaxControlID="rpEcritures">
             <UpdatedControls>
                 <telerik:AjaxUpdatedControl ControlID="rpEcritures" />
                 <telerik:AjaxUpdatedControl ControlID="lblTotalDebit" />
                 <telerik:AjaxUpdatedControl ControlID="lblTotalCredit" />
                 <telerik:AjaxUpdatedControl ControlID="lblCount" />
                 <telerik:AjaxUpdatedControl ControlID="pnlEmpty" />
             </UpdatedControls>
         </telerik:AjaxSetting>
     </AjaxSettings>
 </telerik:RadAjaxManager>

 <%-- Le titre pose sur le fond de la page, comme dans le gabarit : la rubrique,
      le titre, le sous-titre, et à droite le bouton de création en pastille bleue. --%>
 <div class="fc-tete">
     <div class="txt">
         <div class="fc-rubrique"><asp:Literal ID="litRubrique" runat="server" /></div>
         <h1><asp:Literal ID="litTitre" runat="server" /></h1>
         <p><asp:Literal ID="litSousTitre" runat="server" /></p>
     </div>
     <div class="btns">
         <button type="button" class="fc-btn primaire" onclick="openEcriture(0); return false;">+ <asp:Literal ID="litBtnNouveau" runat="server" /></button>
     </div>
 </div>

 <asp:Panel ID="pnlMain" runat="server" CssClass="rw-page">

     <%-- BARRE DE FILTRES --%>
     <div class="topbar">
         <div class="filterbar">
             <div class="filter-field" style="width: 140px">
                 <label><asp:Literal ID="litLblDateFrom" runat="server" /></label>
                 <telerik:RadDatePicker ID="dpDateFrom" runat="server" />
             </div>
             <div class="filter-field" style="width: 140px">
                 <label><asp:Literal ID="litLblDateTo" runat="server" /></label>
                 <telerik:RadDatePicker ID="dpDateTo" runat="server" />
             </div>
             <div class="filter-field" style="width: 200px">
                 <label><asp:Literal ID="litLblJournal" runat="server" /></label>
                 <telerik:RadComboBox ID="cbJournalFilter" runat="server" Width="200px"
                     DataTextField="DisplayName" DataValueField="Id">
                     <Items>
                         <telerik:RadComboBoxItem Text="(Tous)" Value="" />
                     </Items>
                 </telerik:RadComboBox>
             </div>
             <div class="filter-field" style="width: 160px">
                 <label><asp:Literal ID="litLblStatus" runat="server" /></label>
                 <telerik:RadComboBox ID="cbStatusFilter" runat="server" Width="160px">
                     <Items>
                         <telerik:RadComboBoxItem Text="(Tous)" Value="" Selected="true" />
                         <telerik:RadComboBoxItem Text="Brouillon" Value="BROUILLON" />
                         <telerik:RadComboBoxItem Text="Validée" Value="VALIDEE" />
                         <telerik:RadComboBoxItem Text="Extournée" Value="EXTOURNEE" />
                     </Items>
                 </telerik:RadComboBox>
             </div>
             <div class="filter-field" style="flex: 1; min-width: 200px">
                 <label><asp:Literal ID="litLblSearch" runat="server" /></label>
                 <telerik:RadTextBox ID="txtSearch" runat="server" EmptyMessage="Rechercher..." Width="100%" />
             </div>
             <div class="filter-field">
                 <label>&nbsp;</label>
                 <telerik:RadButton ID="btnFilter" runat="server" Text="Filtrer" />
             </div>
         </div>
     </div>

     <%-- LISTE --%>
     <div class="content">
         <div class="container">
             <div class="grid-wrap">
                 <div class="grid-header">
                     <div><asp:Literal ID="litColNoPiece" runat="server" /></div>
                     <div><asp:Literal ID="litColDate" runat="server" /></div>
                     <div><asp:Literal ID="litColJournal" runat="server" /></div>
                     <div><asp:Literal ID="litColLibelle" runat="server" /></div>
                     <div style="text-align: right"><asp:Literal ID="litColDebit" runat="server" /></div>
                     <div style="text-align: right"><asp:Literal ID="litColCredit" runat="server" /></div>
                     <div style="text-align: center"><asp:Literal ID="litColStatut" runat="server" /></div>
                     <div style="text-align: center"><asp:Literal ID="litColActions" runat="server" /></div>
                 </div>

                 <asp:Repeater ID="rpEcritures" runat="server">
                     <ItemTemplate>
                         <div class="grid-row">
                             <div class="ecriture-no" onclick='<%# "openEcriture(" & Eval("Id") & ")" %>' style="cursor: pointer;">
                                 <%# Eval("NumeroPiece") %>
                             </div>
                             <div><%# Eval("DateEcriture", "{0:yyyy-MM-dd}") %></div>
                             <div>
                                 <strong><%# Eval("JournalCode") %></strong>
                                 <div style="font-size: 11px; color: var(--muted);"><%# Eval("JournalLibelle") %></div>
                             </div>
                             <div>
                                 <%# Eval("Libelle") %>
                                 <%# RenderSourceBadge(Eval("SourceType")) %>
                             </div>
                             <div class="ecriture-amount"><%# Eval("TotalDebit", "{0:N2}") %></div>
                             <div class="ecriture-amount"><%# Eval("TotalCredit", "{0:N2}") %></div>
                             <div style="text-align: center">
                                 <span class='<%# GetStatutCssClass(Eval("Statut")) %>'>
                                     <%# GetStatutLabel(Eval("Statut")) %>
                                 </span>
                             </div>
                             <div class="actions-cell">
                                 <button type="button" class="btn-icon-edit" title='<%# L("edit") %>'
                                     onclick='<%# "openEcriture(" & Eval("Id") & "); return false;" %>'></button>
                                 <asp:LinkButton ID="btnDelete" runat="server"
                                     CssClass="btn-icon-delete"
                                     CommandName="DeleteEcriture"
                                     CommandArgument='<%# Eval("Id") %>'
                                     OnClientClick='<%# "return confirm(" & Chr(39) & L("confirmDelete") & Chr(39) & ");" %>'
                                     Visible='<%# CanDelete(Eval("Statut")) %>'
                                     ToolTip='<%# L("delete") %>'>&nbsp;</asp:LinkButton>
                             </div>
                         </div>
                     </ItemTemplate>
                 </asp:Repeater>

                 <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="empty">
                     <asp:Literal ID="litEmpty" runat="server" />
                 </asp:Panel>
             </div>

             <%-- PIED DE PAGE TOTAUX --%>
             <div class="fc-pied-carte">
                 <div style="display: grid; grid-template-columns: 1fr auto auto; gap: 30px; align-items: center;">
                     <div>
                         <strong>
                             <asp:Label ID="lblCount" runat="server" Text="0" /></strong> <asp:Literal ID="litFtEntries" runat="server" />
                     </div>
                     <div><asp:Literal ID="litFtTotalDebit" runat="server" /> <strong>
                         <asp:Label ID="lblTotalDebit" runat="server" Text="0.00" /></strong></div>
                     <div><asp:Literal ID="litFtTotalCredit" runat="server" /> <strong>
                         <asp:Label ID="lblTotalCredit" runat="server" Text="0.00" /></strong></div>
                 </div>
             </div>
         </div>
     </div>

     <%-- FAB NOUVELLE ÉCRITURE --%>
     <div class="fab-add">
         <a id="fabNew" runat="server" href="javascript:openEcriture(0)" title="">
             <img id="imgFabNew" runat="server" src="Images/rondplus45.png" alt="" />
         </a>
     </div>

 </asp:Panel>

 <%-- POPUP D'ÉDITION --%>
 <telerik:RadWindowManager ID="RadWindowManager1" runat="server" Skin="Metro"
     EnableShadow="true" Behaviors="Close, Move, Resize" />

 <script type="text/javascript">

     function openEcriture(id) {
         var oManager = GetRadWindowManager();
         var oWnd = oManager.open("wbfJournalEntryEdit.aspx?Id=" + id, "wndEcriture");
         oWnd.setSize(1100, 750);
         oWnd.set_modal(true);
         oWnd.set_title(id > 0 ? "<%= L("editEntry") %>" : "<%= L("newEntry") %>");
         oWnd.center();
         oWnd.add_close(function () {
             /* Recharger la liste à la fermeture */
             __doPostBack('<%= btnFilter.UniqueID %>', '');
         });
         return false;
     }

     function GetRadWindowManager() {
         return $find("<%= RadWindowManager1.ClientID %>");
     }

 </script>

