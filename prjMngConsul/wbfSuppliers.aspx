<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="wbfSuppliers.aspx.vb" Inherits="MngConsul.wbfSuppliers" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Fournisseurs — MngConsul
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* Petites touches pour harmoniser avec le thème du Site.master */
        .page-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
            padding: 14px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            background: rgba(255,255,255,.75);
        }

        .page-title {
            font-weight: 900;
            font-size: 18px;
            line-height: 1.2;
        }

        .page-sub {
            color: var(--mc-muted);
            font-size: 13px;
            margin-top: 4px;
        }

        .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }

        .muted-note {
            color: var(--mc-muted);
            font-size: 12px;
            padding: 10px 16px 0 16px;
        }

        .grid-wrap {
            padding: 16px;
        }
.full-grid {
    height: calc(100vh - 220px);
    padding: 16px;
    box-sizing: border-box;
}

.supplier-cards-shell {
    height: 100%;
    background: #fff;
    border: 1px solid var(--mc-stroke);
    border-radius: 18px;
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(15,23,42,.06);
    display: flex;
    flex-direction: column;
    min-height: 0;
}

.supplier-scroll {
    flex: 1 1 auto;
    overflow: auto;
    min-height: 0;
}

.supplier-cards-list {
    padding: 16px;
   
    gap: 16px;
    align-content: start;
    box-sizing: border-box;
}

.supplier-card {
    background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%);
    border: 1px solid #e8edf5;
    border-radius: 18px;
    padding: 16px;
    box-shadow: 0 8px 24px rgba(15,23,42,.05);
    transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
}

.supplier-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 16px 34px rgba(15,23,42,.10);
    border-color: #d7e3f4;
}

.supplier-card-top {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;
}

.supplier-card-title-wrap {
    min-width: 0;
    flex: 1;
}

.supplier-card-title {
    font-size: 17px;
    font-weight: 900;
    color: #0f172a;
    line-height: 1.3;
    word-break: break-word;
}

.supplier-card-sub {
    margin-top: 4px;
    font-size: 12px;
    color: #64748b;
}

.supplier-card-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: flex-end;
}

.supplier-card-body {
    margin-top: 14px;
    padding-top: 14px;
    border-top: 1px solid #eef2f7;
}

.supplier-meta {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.supplier-meta-label {
    font-size: 12px;
    font-weight: 800;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: .04em;
}

.supplier-meta-value {
    font-size: 14px;
    font-weight: 700;
    color: #0f172a;
}

.supplier-empty {
    padding: 40px 20px;
    text-align: center;
    color: var(--mc-muted);
}

.supplier-pager {
    flex: 0 0 auto;
    padding: 12px 16px 16px 16px;
    border-top: 1px solid var(--mc-stroke);
    background: #fff;
}

.btn.danger {
    border-color: #fecaca !important;
    background: #fff5f5 !important;
    color: #b91c1c !important;
}

.btn.danger:hover {
    background: #fee2e2 !important;
}

@media (max-width: 700px) {
    .supplier-cards-list {
        grid-template-columns: 1fr;
        padding: 12px;
        gap: 12px;
    }

    .supplier-card {
        padding: 14px;
    }

    .supplier-card-top {
        flex-direction: column;
    }

    .supplier-card-actions {
        width: 100%;
        justify-content: flex-start;
    }
}

       

        .supplier-row:hover {
            background: #fafcff;
        }

       

        .supplier-empty {
            padding: 28px;
            text-align: center;
            color: var(--mc-muted);
        }
        .full-grid {
    min-height: calc(100vh - 220px);
    padding: 16px;
    box-sizing: border-box;
}

.supplier-cards-shell {
    min-height: 100%;
    background: #fff;
    border: 1px solid var(--mc-stroke);
    border-radius: 18px;
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(15,23,42,.06);
    display: flex;
    flex-direction: column;
}
 

.supplier-card {
    background: linear-gradient(180deg, #ffffff 0%, #fbfdff 100%);
    border: 1px solid #e8edf5;
    border-radius: 18px;
    padding: 16px;
    box-shadow: 0 8px 24px rgba(15,23,42,.05);
    transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
}

.supplier-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 16px 34px rgba(15,23,42,.10);
    border-color: #d7e3f4;
}

.supplier-card-top {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;
}

.supplier-card-title-wrap {
    min-width: 0;
    flex: 1;
}

.supplier-card-title {
    font-size: 17px;
    font-weight: 900;
    color: #0f172a;
    line-height: 1.3;
    word-break: break-word;
}

.supplier-card-sub {
    margin-top: 4px;
    font-size: 12px;
    color: #64748b;
}

.supplier-card-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: flex-end;
}

.supplier-card-body {
    margin-top: 14px;
    padding-top: 14px;
    border-top: 1px solid #eef2f7;
}

.supplier-meta {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.supplier-meta-label {
    font-size: 12px;
    font-weight: 800;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: .04em;
}

.supplier-meta-value {
    font-size: 14px;
    font-weight: 700;
    color: #0f172a;
}

.supplier-empty {
    padding: 40px 20px;
    text-align: center;
    color: var(--mc-muted);
}

.supplier-pager {
    padding: 12px 16px 16px 16px;
    border-top: 1px solid var(--mc-stroke);
    background: #fff;
}

.btn.danger {
    border-color: #fecaca !important;
    background: #fff5f5 !important;
    color: #b91c1c !important;
}

.btn.danger:hover {
    background: #fee2e2 !important;
}

@media (max-width: 700px) {
    .supplier-cards-list {
        grid-template-columns: 1fr;
        padding: 12px;
        gap: 12px;
    }

    .supplier-card {
        padding: 14px;
    }

    .supplier-card-top {
        flex-direction: column;
    }

    .supplier-card-actions {
        width: 100%;
        justify-content: flex-start;
    }
}
        @media (max-width: 900px) {
            .supplier-list-head {
                display: none;
            }

            .supplier-row {
                grid-template-columns: 1fr;
                gap: 10px;
            }

            .supplier-created::before {
                content: "Créé le : ";
                font-weight: 800;
                color: #0f172a;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadWindowManager ID="rwmSuppliers" runat="server" EnableShadow="true">
    </telerik:RadWindowManager>

    <telerik:RadWindow ID="rwSupplier" runat="server"
        Modal="true"
        VisibleOnPageLoad="false"
        Behaviors="Close,Move,Resize"
        DestroyOnClose="true"
        Width="1100px"
        Height="720px"
        Title="Ajouter / Modifier un fournisseur"
        OnClientClose="rwSupplier_OnClientClose">
    </telerik:RadWindow>

    <div class="page-head">
        <div>
            <div class="page-title">Fournisseurs</div>
            <div class="page-sub">Liste des fournisseurs (RadListView Telerik)</div>
        </div>

        <div class="actions">
            <asp:Button ID="btnAddSupplier" runat="server"
                CssClass="btn primary"
                Text="Ajouter Supplier"
                CausesValidation="false"
                OnClientClick="openSupplierWindow(0); return false;" />

            <asp:TextBox ID="tbSearch" runat="server" CssClass="input" placeholder="Rechercher (nom, email, téléphone…)" />

            <asp:Button ID="btnSearch" runat="server" CssClass="btn" Text="Rechercher" />
            <asp:Button ID="btnClear" runat="server" CssClass="btn" Text="Effacer" CausesValidation="false" />
        </div>
    </div>
 <div class="full-grid">
    <div class="supplier-cards-shell">
        <div class="supplier-scroll">
            <telerik:RadListView ID="rgFournisseurs" runat="server"
                DataKeyNames="Id"
                AllowPaging="True"
                ItemPlaceholderID="itemPlaceholder"
                RenderItemWrapper="false">

                <LayoutTemplate>
                    <div class="supplier-cards-list">
                        <asp:PlaceHolder ID="itemPlaceholder" runat="server"></asp:PlaceHolder>
                    </div>
                </LayoutTemplate>

                <ItemTemplate>
                    
                       
                            <div class="supplier-card-title-wrap">
                                <div class="supplier-card-title">
                                    <%# Eval("NameAllAdddress") %>
                                </div>
                                <div class="supplier-card-sub">
                                    Fournisseur #<%# Eval("Id") %>
                                </div>
                            </div>

                            <div class="supplier-card-actions">
                                <asp:Button ID="btnEdit" runat="server"
                                    CssClass="btn"
                                    Text="Edit"
                                    OnClientClick='<%# "openSupplierWindow(" & Eval("Id") & "); return false;" %>' />

                                <asp:Button ID="btnDelete" runat="server"
                                    CssClass="btn danger"
                                    Text="Delete"
                                    CommandName="DeleteSupplier"
                                    CommandArgument='<%# Eval("Id") %>' />
                            </div>
                        

                        <div class="supplier-card-body">
                            <div class="supplier-meta">
                                <span class="supplier-meta-label">Créé le</span>
                                <span class="supplier-meta-value"><%# Eval("Created", "{0:yyyy-MM-dd}") %></span>
                            </div>
                        </div>
                     
                </ItemTemplate>

                <EmptyDataTemplate>
                    <div class="supplier-empty">
                        Aucun fournisseur trouvé.
                    </div>
                </EmptyDataTemplate>
            </telerik:RadListView>
        </div>

       
    </div>
</div>


    <script type="text/javascript">
        function openSupplierWindow(id) {
            var wnd = $find("<%= rwSupplier.ClientID %>");
            var url = "wbfSupplierEdit.aspx";

            if (id && id > 0) {
                url += "?SupplierId=" + id;
                wnd.set_title("Modifier un fournisseur");
            } else {
                url += "?SupplierId=0";
                wnd.set_title("Ajouter un fournisseur");
            }

            wnd.setUrl(url);
            wnd.show();
        }

        function rwSupplier_OnClientClose(sender, args) {
            __doPostBack("<%= rgFournisseurs.UniqueID %>", "Rebind");
        }
    </script>
</asp:Content>