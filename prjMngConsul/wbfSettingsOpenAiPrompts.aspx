<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    ValidateRequest="false"
    CodeBehind="wbfSettingsOpenAiPrompts.aspx.vb" Inherits="MngConsul.wbfSettingsOpenAiPrompts" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Prompts OpenAI — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .page-head{
            display:flex; align-items:flex-start; justify-content:space-between;
            gap:12px; flex-wrap:wrap;
            padding:14px 16px;
            border-bottom:1px solid var(--mc-stroke);
            background:rgba(255,255,255,.75);
        }
        .page-title{ font-weight:900; font-size:18px; line-height:1.2; }
        .page-sub{ color:var(--mc-muted); font-size:13px; margin-top:4px; }
        .actions{ display:flex; gap:8px; flex-wrap:wrap; align-items:center; }

        .wrap{ padding:16px; display:grid; grid-template-columns: 360px 1fr; gap:16px; }
        @media (max-width: 980px){ .wrap{ grid-template-columns:1fr; } }

        .card{
            background:#fff;
            border:1px solid var(--mc-stroke);
            border-radius:14px;
            box-shadow: 0 12px 30px rgba(2,6,23,.06);
            overflow:hidden;
        }
        .card-h{ padding:14px; border-bottom:1px solid var(--mc-stroke); }
        .card-title{ font-weight:900; font-size:14px; }
        .card-desc{ color:var(--mc-muted); font-size:12px; margin-top:4px; }
        .card-b{ padding:14px; }

        .status-ok{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px; border-radius:999px;
            background:rgba(22,163,74,.10);
            color:#166534; border:1px solid rgba(22,163,74,.20);
            font-size:12px;
        }
        .status-err{
            display:inline-flex; align-items:center; gap:8px;
            padding:8px 10px; border-radius:999px;
            background:rgba(220,38,38,.10);
            color:#991b1b; border:1px solid rgba(220,38,38,.20);
            font-size:12px;
        }

        .hint{ color:var(--mc-muted); font-size:12px; margin-top:8px; }
        .k-row{ display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-top:10px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="page-head">
        <div>
            <div class="page-title">Prompts OpenAI</div>
            <div class="page-sub">Textes envoyés à OpenAI pour extraire des données (PDF factures, reçus, etc.).</div>
        </div>

        <div class="actions">
            <telerik:RadButton ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary"
                AutoPostBack="true" OnClick="btnSave_Click" />
            <telerik:RadButton ID="btnReload" runat="server" Text="Recharger" CssClass="btn"
                AutoPostBack="true" OnClick="btnReload_Click" />

            <asp:PlaceHolder ID="phStatus" runat="server" Visible="false">
                <asp:Literal ID="litStatus" runat="server" />
            </asp:PlaceHolder>
        </div>
    </div>

    <div class="wrap">

        <!-- Liste des prompts -->
        <div class="card">
            <div class="card-h">
                <div class="card-title">Bibliothèque</div>
                <div class="card-desc">Choisis un prompt à modifier.</div>
            </div>
            <div class="card-b">
                <telerik:RadDropDownList ID="ddPromptKey" runat="server" Width="100%"
                    AutoPostBack="true"  />

               

                
            </div>
        </div>

        <!-- Éditeur -->
        <div class="card">
            <div class="card-h">
                <div>
                    <div class="card-title">Éditeur</div>
                    <div class="card-desc">Modifie le texte. Il sera utilisé tel quel lors des appels OpenAI.</div>
                </div>
            </div>
            <div class="card-b">

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                    <div>
                        <label class="page-sub" style="margin:0;">Clé (unique)</label><br />
                        <telerik:RadTextBox ReadOnly="true"  ID="tbKey" runat="server" Width="100%" />
                    </div>
                     
                </div>

                <div style="margin-top:12px;">
                    <label class="page-sub" style="margin:0;">Texte du prompt</label>
                    <telerik:RadTextBox ID="tbPromptText" runat="server" Width="100%"
                        TextMode="MultiLine" Rows="18" />

                    <div class="hint">
                        Recommandé: JSON strict + dates ISO + nombres sans symbole + null si absent.
                    </div>
                </div>

                <div style="margin-top:12px; display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                    <div>
                        <label class="page-sub" style="margin:0;">Modèle </label><br />
                        <telerik:RadTextBox ID="tbModel" runat="server" Width="100%" Text="gpt-4.1-mini" />
                    </div>
                    
                </div>

               <%-- <div class="k-row" style="margin-top:12px;">
                    <telerik:RadButton ID="btnLoadDefault" runat="server" Text="Charger défaut (STRICT_JSON)"
                        CssClass="btn" AutoPostBack="true" OnClick="btnLoadDefault_Click" />
                </div>--%>

            </div>
        </div>

    </div>
</asp:Content>