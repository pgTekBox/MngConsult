<%@ Page Language="vb" AutoEventWireup="false" EnableViewState="true"
    CodeBehind="wbfSupplierEdit.aspx.vb" Inherits="MngConsul.wbfSupplierEdit" %>


<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<!DOCTYPE html>
<html lang="fr">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Party — Édition</title>

    <style>
        :root {
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg: #f6f7fb;
            --card: #fff;
            --text: #0f172a;
            --muted: #64748b;
            --line: #e2e8f0;
            --primary: #2563eb;
            --danger: #dc2626;
            --ok: #16a34a;
            --shadow: 0 12px 28px rgba(15,23,42,.08);
            --radius: 16px;
        }

        html, body {
            height: 100%
        }

        body {
            margin: 0;
            font-family: var(--font);
            color: var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%), radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%), var(--bg);
        }

        .wrap {
            max-width: 1100px;
            margin: 20px auto;
            padding: 0 16px 28px;
        }

        .top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }

        .title {
            font-size: 22px;
            font-weight: 900;
            letter-spacing: -.02em
        }

        .sub {
            font-size: 13px;
            color: var(--muted);
            margin-top: 3px
        }

        .bar {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap
        }

        .card {
            background: var(--card);
            border: 1px solid rgba(226,232,240,.9);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 14px;
        }

        .cardHead {
            padding: 14px 16px;
            border-bottom: 1px solid var(--line);
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

            .cardHead .h {
                font-weight: 900
            }

        .cardBody {
            padding: 16px
        }

        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        @media (max-width: 800px) {
            .grid {
                grid-template-columns: 1fr;
            }
        }




        .field label {
            display: block;
            font-size: 12px;
            color: #334155;
            margin-bottom: 6px;
            font-weight: 700
        }



        .field input {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 12px;
            outline: none;
            background: #fff;
        }

            .field input:focus {
                border-color: rgba(37,99,235,.5);
                box-shadow: 0 0 0 4px rgba(37,99,235,.12);
            }

        .btn {
            appearance: none;
            border: 1px solid rgba(148,163,184,.7);
            background: #fff;
            color: #0f172a;
            padding: 9px 12px;
            border-radius: 12px;
            font-weight: 800;
            cursor: pointer;
        }

            .btn.primary {
                border-color: rgba(37,99,235,.4);
                background: rgba(37,99,235,.08);
                color: #1d4ed8;
            }

            .btn.danger {
                border-color: rgba(220,38,38,.35);
                background: rgba(220,38,38,.08);
                color: var(--danger);
            }

            .btn:disabled {
                opacity: .6;
                cursor: not-allowed
            }

        .msg {
            margin: 0;
            padding: 10px 12px;
            border-radius: 12px;
            font-weight: 700;
            font-size: 13px;
            border: 1px solid var(--line);
            background: #fff;
        }

            .msg.ok {
                border-color: rgba(22,163,74,.35);
                background: rgba(22,163,74,.08);
                color: var(--ok);
            }

            .msg.bad {
                border-color: rgba(220,38,38,.35);
                background: rgba(220,38,38,.08);
                color: var(--danger);
            }

        table {
            width: 100%;
            border-collapse: collapse
        }

        th {
            text-align: left;
            font-size: 12px;
            color: #334155;
            background: #f8fafc;
            padding: 10px 12px;
            border-bottom: 1px solid var(--line);
            white-space: nowrap;
        }

        td {
            padding: 10px 12px;
            border-bottom: 1px solid var(--line);
            vertical-align: top
        }

        tr:hover td {
            background: #f8fafc
        }

        .small {
            font-size: 12px;
            color: var(--muted)
        }

        .right {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap
        }

        .mono {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
        }


        /* RadTextBox look "TextBox" */
        .field .rtbLike {
            width: 100%;
        }

            .field .rtbLike .riTextBox,
            .field .rtbLike input.riTextBox {
                width: 100% !important;
                box-sizing: border-box;
                padding: 10px 12px !important;
                border: 1px solid var(--line) !important;
                border-radius: 12px !important;
                outline: none;
                background: #fff !important;
                font-family: var(--font);
                color: var(--text);
            }

                .field .rtbLike .riTextBox:focus,
                .field .rtbLike input.riTextBox:focus,
                .field .rtbLike .riFocused .riTextBox {
                    border-color: rgba(37,99,235,.5) !important;
                    box-shadow: 0 0 0 4px rgba(37,99,235,.12) !important;
                }
    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- ⭐ TERTELIK GLOBAL -->
        <telerik:RadScriptManager
            ID="RadScriptManager1"
            runat="server"
            EnablePartialRendering="true"
            AsyncPostBackTimeout="300" />
          <telerik:RadAjaxManager ID="ram1" runat="server">
      <AjaxSettings>
          <telerik:AjaxSetting AjaxControlID="rgAddr">
              <UpdatedControls>
                  <telerik:AjaxUpdatedControl ControlID="rgAddr" />
                  <telerik:AjaxUpdatedControl ControlID="pnlMsg" />

                  <telerik:AjaxUpdatedControl ControlID="pnlAddrEditor" />


              </UpdatedControls>
          </telerik:AjaxSetting>

          <telerik:AjaxSetting AjaxControlID="btnNewAddress">
              <UpdatedControls>
                  <telerik:AjaxUpdatedControl ControlID="rgAddr" />
              </UpdatedControls>
          </telerik:AjaxSetting>

          <telerik:AjaxSetting AjaxControlID="btnAddrRefresh">
              <UpdatedControls>
                  <telerik:AjaxUpdatedControl ControlID="rgAddr" />
              </UpdatedControls>
          </telerik:AjaxSetting>
      </AjaxSettings>
  </telerik:RadAjaxManager>
        <div class="wrap">

            <div class="top">
                <div>
                    <div class="title">Édition — Party</div>
                    <div class="sub">Modifier l’entité + gérer ses adresses</div>
                </div>
                <div class="bar">
                    <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn" NavigateUrl="PartyList.aspx">← Retour à la liste</asp:HyperLink>
                    <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                </div>
            </div>

            <asp:Panel ID="pnlMsg" runat="server" Visible="false">
                <p id="pMsg" runat="server" class="msg"></p>
            </asp:Panel>

            <!-- PARTY -->
            <div class="card">
                <div class="cardHead">
                    <div>
                        <div class="h">Informations Party</div>
                        <div class="small">
                            Id:
                            <asp:Literal ID="litId" runat="server" />
                        </div>
                    </div>
                    <div class="right">
                        <span class="small mono">
                            <asp:Literal ID="litGuid" runat="server" /></span>
                    </div>
                </div>
                <div class="cardBody">
                    <div class="grid">
                        <div class="field">
                            <label>Nom</label>
                            <telerik:RadTextBox ID="txtName" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>

                        <div class="field">
                            <label>Website</label>
                            <telerik:RadTextBox ID="txtWebsite" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>

                        <div class="field">
                            <label>No TPS</label>
                            <telerik:RadTextBox ID="txtNoTPS" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>

                        <div class="field">
                            <label>No TVQ</label>
                            <telerik:RadTextBox ID="txtNoTVQ" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- ADDRESSES -->
            <div class="card">
                <div class="cardHead">
                    <div>
                        <div class="h">Adresses</div>
                        <div class="small">Une Party peut avoir plusieurs adresses</div>
                    </div>
                    <div class="right">
                        <asp:Button ID="btnNewAddress" runat="server" Text="Ajouter une adresse" CssClass="btn primary" />
                    </div>
                </div>


                <telerik:RadGrid ID="rgAddr" runat="server"
                    Skin="Metro"
                    AutoGenerateColumns="False"
                    AllowPaging="True"
                    PageSize="25"
                    AllowSorting="True"
                    Height="200px">
                    <ClientSettings>
                        <Scrolling AllowScroll="true" UseStaticHeaders="true" />
                    </ClientSettings>
                    <MasterTableView DataKeyNames="Id" CommandItemDisplay="Top">
                        <CommandItemSettings
                            ShowAddNewRecordButton="False"
                            ShowRefreshButton="False"
                            ShowExportToCsvButton="False"
                            ShowExportToExcelButton="False"
                            ShowExportToPdfButton="False" />

                        <Columns>
                            <telerik:GridTemplateColumn HeaderText="Actions" UniqueName="Actions" AllowFiltering="False">
                                <ItemTemplate>
                                    <asp:Button ID="btnEdit" runat="server" CssClass="btn" Text="Edit" CommandName="EditAddress" />
                                    <asp:Button ID="btnDelete" runat="server" CssClass="btn" Text="Delete" CommandName="DeleteAddress" />
                                </ItemTemplate>
                            </telerik:GridTemplateColumn>
                            <telerik:GridBoundColumn DataField="Address1" HeaderText="Address1" UniqueName="Address1" />
                            <telerik:GridBoundColumn DataField="Address2" HeaderText="Address2" UniqueName="Address2" />

                        </Columns>
                    </MasterTableView>

                    <ClientSettings AllowColumnsReorder="True" ReorderColumnsOnClient="True">
                        <Selecting AllowRowSelect="True" />
                        <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                    </ClientSettings>

                    <PagerStyle Mode="NextPrevAndNumeric" />
                </telerik:RadGrid>

                <!-- Editor -->
                <telerik:RadWindowManager ID="rwm1" runat="server" EnableShadow="true" />

                <telerik:RadWindow ID="rwAddr"  runat="server"
                    Modal="true"
                    VisibleOnPageLoad="false"
                    Behaviors="Close,Move"
                    DestroyOnClose="false"
                    Width="820px"
                    Height="520px"
                    Title="Édition adresse"
                    OnClientClose="rwAddr_OnClientClose">
                    <ContentTemplate>

                        <asp:Panel ID="pnlAddrEditor" runat="server">


                            <asp:HiddenField ID="hfAddrId" runat="server" />

                            <div style="padding: 14px;">
                                <div class="grid">
                                    <div class="field">
                                        <label>Adresse 1</label>
                                        <telerik:RadTextBox ID="txtA1" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                                    </div>

                                    <div class="field">
                                        <label>Adresse 2</label>
                                        <telerik:RadTextBox ID="txtA2" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                                    </div>

                                    <div class="field">
                                        <label>Ville</label>
                                        <telerik:RadTextBox ID="txtCity" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                                    </div>

                                    <div class="field">
                                        <label>Province</label>
                                        <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlProvince" runat="server"
                                            DefaultMessage="Select.." DropDownHeight="110px">
                                        </telerik:RadDropDownList>
                                    </div>
                                    <div class="field">
                                        <label>Pays</label>
                                        <telerik:RadDropDownList RenderMode="Lightweight" ID="rddlPays" runat="server"
                                            DefaultMessage="Select.." DropDownHeight="110px">
                                        </telerik:RadDropDownList>
                                    </div>
                                    <div class="field">
                                        <label>Code postal</label>
                                        <telerik:RadTextBox ID="txtPostal" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                                    </div>

                                    <div class="field">
                                        <label>Pays</label>
                                        <telerik:RadTextBox ID="txtCountry" runat="server" RenderMode="Lightweight" CssClass="rtbLike" />
                                    </div>
                                </div>

                                <div style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 14px; flex-wrap: wrap;">
                                    <asp:Button ID="btnAddrSave" runat="server" Text="Enregistrer" CssClass="btn primary" />
                                    <asp:Button ID="btnAddrCancel" runat="server" Text="Annuler" CssClass="btn"
                                        CausesValidation="false"
                                        OnClientClick="closeAddrWindow(false); return false;" />
                                </div>
                            </div>
                        </asp:Panel>
                    </ContentTemplate>

                </telerik:RadWindow>









            </div>

        </div>
        <!-- bouton caché pour refresh après fermeture -->
        <asp:Button ID="btnAddrRefresh" ClientIDMode="Static" runat="server" Style="display: none" />
      


        <script type="text/javascript">
            function closeAddrWindow(saved) {
                // On met un flag dans "argument" pour savoir s'il faut refresh
                var wnd = $find("rwAddr");
                wnd.close({ saved: saved === true });
            }

            function rwAddr_OnClientClose(sender, args) {
                var a = args.get_argument();
                if (a && a.saved) {



                    // provoque un postback vers un bouton caché pour rebind
                    __doPostBack("btnAddrRefresh", "");
                }
            }

            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function closeWin() {
                //get a reference to the current RadWindow
                var oWnd = GetRadWindow();
                //Close the RadWindow and send the argument to the parent page

                oWnd.close();
            }



        </script>


    </form>

</body>
</html>

