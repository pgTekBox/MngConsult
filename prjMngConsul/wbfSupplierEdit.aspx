<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="wbfSupplierEdit.aspx.vb" Inherits="MngConsul.wbfSupplierEdit" %>

 
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
        :root{
            --font: "Inter", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
            --bg:#f6f7fb; --card:#fff; --text:#0f172a; --muted:#64748b;
            --line:#e2e8f0; --primary:#2563eb; --danger:#dc2626; --ok:#16a34a;
            --shadow:0 12px 28px rgba(15,23,42,.08);
            --radius:16px;
        }
        html,body{height:100%}
        body{
            margin:0; font-family:var(--font); color:var(--text);
            background: radial-gradient(1200px 600px at 20% 0%, #eef2ff 0%, transparent 45%),
                        radial-gradient(1200px 600px at 80% 0%, #ecfeff 0%, transparent 45%),
                        var(--bg);
        }
        .wrap{max-width:1100px;margin:20px auto;padding:0 16px 28px;}
        .top{
            display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap;
            margin-bottom:14px;
        }
        .title{font-size:22px;font-weight:900;letter-spacing:-.02em}
        .sub{font-size:13px;color:var(--muted);margin-top:3px}
        .bar{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
        .card{
            background:var(--card); border:1px solid rgba(226,232,240,.9);
            border-radius:var(--radius); box-shadow:var(--shadow); overflow:hidden;
            margin-bottom:14px;
        }
        .cardHead{
            padding:14px 16px; border-bottom:1px solid var(--line);
            display:flex; justify-content:space-between; align-items:center; gap:10px; flex-wrap:wrap;
        }
        .cardHead .h{font-weight:900}
        .cardBody{padding:16px}
        .grid{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:12px;
        }
        @media (max-width: 800px){ .grid{grid-template-columns:1fr;} }

        .field label{display:block;font-size:12px;color:#334155;margin-bottom:6px;font-weight:700}
        .field input{
            width:100%;
            padding:10px 12px;
            border:1px solid var(--line);
            border-radius:12px;
            outline:none;
            background:#fff;
        }
        .field input:focus{
            border-color: rgba(37,99,235,.5);
            box-shadow: 0 0 0 4px rgba(37,99,235,.12);
        }

        .btn{
            appearance:none;
            border:1px solid rgba(148,163,184,.7);
            background:#fff;
            color:#0f172a;
            padding:9px 12px;
            border-radius:12px;
            font-weight:800;
            cursor:pointer;
        }
        .btn.primary{border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color:#1d4ed8;}
        .btn.danger{border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger);}
        .btn:disabled{opacity:.6;cursor:not-allowed}

        .msg{
            margin: 0;
            padding: 10px 12px;
            border-radius: 12px;
            font-weight: 700;
            font-size: 13px;
            border: 1px solid var(--line);
            background: #fff;
        }
        .msg.ok{border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: var(--ok);}
        .msg.bad{border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: var(--danger);}

        table{width:100%;border-collapse:collapse}
        th{
            text-align:left; font-size:12px; color:#334155; background:#f8fafc;
            padding:10px 12px; border-bottom:1px solid var(--line); white-space:nowrap;
        }
        td{padding:10px 12px;border-bottom:1px solid var(--line);vertical-align:top}
        tr:hover td{background:#f8fafc}

        .small{font-size:12px;color:var(--muted)}
        .right{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
        .mono{font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;}
    </style>
</head>

<body>
<form id="form1" runat="server">
    <div class="wrap">

        <div class="top">
            <div>
                <div class="title">Édition — Party</div>
                <div class="sub">Modifier l’entité + gérer ses adresses</div>
            </div>
            <div class="bar">
                <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn" NavigateUrl="PartyList.aspx">← Retour à la liste</asp:HyperLink>
                <asp:Button ID="btnSave" runat="server" Text="Enregistrer" CssClass="btn primary"  />
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
                    <div class="small">Id: <asp:Literal ID="litId" runat="server" /></div>
                </div>
                <div class="right">
                    <span class="small mono"><asp:Literal ID="litGuid" runat="server" /></span>
                </div>
            </div>
            <div class="cardBody">
                <div class="grid">
                    <div class="field">
                        <label>Nom</label>
                        <asp:TextBox ID="txtName" runat="server" />
                    </div>
                    <div class="field">
                        <label>Website</label>
                        <asp:TextBox ID="txtWebsite" runat="server" />
                    </div>
                    <div class="field">
                        <label>No TPS</label>
                        <asp:TextBox ID="txtNoTPS" runat="server" />
                    </div>
                    <div class="field">
                        <label>No TVQ</label>
                        <asp:TextBox ID="txtNoTVQ" runat="server" />
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
                    <asp:Button ID="btnNewAddress" runat="server" Text="Ajouter une adresse" CssClass="btn primary"   />
                </div>
            </div>

            <asp:GridView ID="gvAddr" runat="server"
                AutoGenerateColumns="False"
                DataKeyNames="Id"
                 
                CssClass="gv"
                GridLines="None">
                <Columns>
                    <asp:BoundField DataField="Id" HeaderText="Id" />
                    <asp:BoundField DataField="Address1" HeaderText="Adresse 1" />
                    <asp:BoundField DataField="Address2" HeaderText="Adresse 2" />
                    <asp:BoundField DataField="City" HeaderText="Ville" />
                    <asp:BoundField DataField="Province" HeaderText="Province" />
                    <asp:BoundField DataField="PostalCode" HeaderText="Code postal" />
                    <asp:BoundField DataField="Country" HeaderText="Pays" />

                    <asp:TemplateField HeaderText="">
                        <ItemTemplate>
                            <asp:LinkButton runat="server" CommandName="EditAddr" CommandArgument='<%# Eval("Id") %>' CssClass="btn" Text="Modifier" />
                            <asp:LinkButton runat="server" CommandName="DelAddr" CommandArgument='<%# Eval("Id") %>'
                                CssClass="btn danger" Text="Supprimer"
                                OnClientClick="return confirm('Supprimer cette adresse ?');" />
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>

            <!-- Editor -->
            <asp:Panel ID="pnlAddrEdit" runat="server" Visible="false">
                <div class="cardBody" style="border-top:1px solid var(--line); background:#fbfdff;">
                    <div style="display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;align-items:center;margin-bottom:10px;">
                        <div style="font-weight:900;">Édition adresse</div>
                        <div class="right">
                            <asp:Button ID="btnAddrSave" runat="server" Text="Enregistrer adresse" CssClass="btn primary"   />
                            <asp:Button ID="btnAddrCancel" runat="server" Text="Annuler" CssClass="btn"   />
                        </div>
                    </div>

                    <asp:HiddenField ID="hfAddrId" runat="server" />

                    <div class="grid">
                        <div class="field">
                            <label>Adresse 1</label>
                            <asp:TextBox ID="txtA1" runat="server" />
                        </div>
                        <div class="field">
                            <label>Adresse 2</label>
                            <asp:TextBox ID="txtA2" runat="server" />
                        </div>
                        <div class="field">
                            <label>Ville</label>
                            <asp:TextBox ID="txtCity" runat="server" />
                        </div>
                        <div class="field">
                            <label>Province</label>
                            <asp:TextBox ID="txtProv" runat="server" />
                        </div>
                        <div class="field">
                            <label>Code postal</label>
                            <asp:TextBox ID="txtPostal" runat="server" />
                        </div>
                        <div class="field">
                            <label>Pays</label>
                            <asp:TextBox ID="txtCountry" runat="server" />
                        </div>
                    </div>
                </div>
            </asp:Panel>

        </div>

    </div>
</form>

<%--<script runat="server">

    ' --- CONFIG ---
    Private ReadOnly Property Cs As String
        Get
            ' ✅ Mets ton nom de connectionString ici (Web.config)
            Return ConfigurationManager.ConnectionStrings("Sql").ConnectionString
        End Get
    End Property

    Private ReadOnly Property PartyId As Integer
        Get
            Dim s = Request.QueryString("id")
            Dim id As Integer
            If Not Integer.TryParse(s, id) Then Return 0
            Return id
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If PartyId <= 0 Then
            ShowMsg("Paramètre manquant: ?id=123", False)
            btnSave.Enabled = False
            btnNewAddress.Enabled = False
            Return
        End If

        If Not IsPostBack Then
            LoadParty()
            BindAddresses()
        End If
    End Sub

    Private Sub LoadParty()
        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String =
"SELECT Id, PartyGUID, Name, NoTVQ, NoTPS, Website
  FROM dbo.T050Party
 WHERE Id = @Id;"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.Add("@Id", SqlDbType.Int).Value = PartyId

                Using r = cmd.ExecuteReader()
                    If Not r.Read() Then
                        ShowMsg("Party introuvable (Id=" & PartyId & ")", False)
                        btnSave.Enabled = False
                        btnNewAddress.Enabled = False
                        Return
                    End If

                    litId.Text = PartyId.ToString()
                    litGuid.Text = If(IsDBNull(r("PartyGUID")), "", r("PartyGUID").ToString())

                    txtName.Text = If(IsDBNull(r("Name")), "", r("Name").ToString())
                    txtNoTVQ.Text = If(IsDBNull(r("NoTVQ")), "", r("NoTVQ").ToString())
                    txtNoTPS.Text = If(IsDBNull(r("NoTPS")), "", r("NoTPS").ToString())
                    txtWebsite.Text = If(IsDBNull(r("Website")), "", r("Website").ToString())
                End Using
            End Using
        End Using
    End Sub

    Private Sub BindAddresses()
        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String =
"SELECT Id, PartyId, Address1, Address2, City, Province, PostalCode, Country
   FROM dbo.T054PartyAddress
  WHERE PartyId = @PartyId
  ORDER BY Id DESC;"

            Using da As New SqlDataAdapter(sql, cn)
                da.SelectCommand.Parameters.Add("@PartyId", SqlDbType.Int).Value = PartyId
                Dim dt As New DataTable()
                da.Fill(dt)
                gvAddr.DataSource = dt
                gvAddr.DataBind()
            End Using
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String =
"UPDATE dbo.T050Party
    SET Name = @Name,
        NoTVQ = @NoTVQ,
        NoTPS = @NoTPS,
        Website = @Website
  WHERE Id = @Id;"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.Add("@Name", SqlDbType.NVarChar, 200).Value = CType(If(String.IsNullOrWhiteSpace(txtName.Text), DBNull.Value, txtName.Text.Trim()), Object)
                cmd.Parameters.Add("@NoTVQ", SqlDbType.NVarChar, 60).Value = CType(If(String.IsNullOrWhiteSpace(txtNoTVQ.Text), DBNull.Value, txtNoTVQ.Text.Trim()), Object)
                cmd.Parameters.Add("@NoTPS", SqlDbType.NVarChar, 60).Value = CType(If(String.IsNullOrWhiteSpace(txtNoTPS.Text), DBNull.Value, txtNoTPS.Text.Trim()), Object)
                cmd.Parameters.Add("@Website", SqlDbType.NVarChar, 300).Value = CType(If(String.IsNullOrWhiteSpace(txtWebsite.Text), DBNull.Value, txtWebsite.Text.Trim()), Object)
                cmd.Parameters.Add("@Id", SqlDbType.Int).Value = PartyId

                Dim rows = cmd.ExecuteNonQuery()
                ShowMsg("Enregistré (" & rows & ")", True)
            End Using
        End Using
    End Sub

    ' --- Address UI ---
    Protected Sub btnNewAddress_Click(sender As Object, e As EventArgs)
        hfAddrId.Value = ""
        txtA1.Text = ""
        txtA2.Text = ""
        txtCity.Text = ""
        txtProv.Text = ""
        txtPostal.Text = ""
        txtCountry.Text = ""
        pnlAddrEdit.Visible = True
    End Sub

    Protected Sub gvAddr_RowCommand(sender As Object, e As GridViewCommandEventArgs)
        Dim addrId As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), addrId) Then Return

        If e.CommandName = "EditAddr" Then
            LoadAddress(addrId)
            pnlAddrEdit.Visible = True
        ElseIf e.CommandName = "DelAddr" Then
            DeleteAddress(addrId)
            pnlAddrEdit.Visible = False
            BindAddresses()
            ShowMsg("Adresse supprimée.", True)
        End If
    End Sub

    Private Sub LoadAddress(addrId As Integer)
        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String =
"SELECT Id, PartyId, Address1, Address2, City, Province, PostalCode, Country
   FROM dbo.T054PartyAddress
  WHERE Id = @Id AND PartyId = @PartyId;"

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.Add("@Id", SqlDbType.Int).Value = addrId
                cmd.Parameters.Add("@PartyId", SqlDbType.Int).Value = PartyId

                Using r = cmd.ExecuteReader()
                    If Not r.Read() Then
                        ShowMsg("Adresse introuvable.", False)
                        pnlAddrEdit.Visible = False
                        Return
                    End If

                    hfAddrId.Value = addrId.ToString()
                    txtA1.Text = If(IsDBNull(r("Address1")), "", r("Address1").ToString())
                    txtA2.Text = If(IsDBNull(r("Address2")), "", r("Address2").ToString())
                    txtCity.Text = If(IsDBNull(r("City")), "", r("City").ToString())
                    txtProv.Text = If(IsDBNull(r("Province")), "", r("Province").ToString())
                    txtPostal.Text = If(IsDBNull(r("PostalCode")), "", r("PostalCode").ToString())
                    txtCountry.Text = If(IsDBNull(r("Country")), "", r("Country").ToString())
                End Using
            End Using
        End Using
    End Sub

    Protected Sub btnAddrSave_Click(sender As Object, e As EventArgs)
        Dim isUpdate As Boolean = Not String.IsNullOrWhiteSpace(hfAddrId.Value)
        Dim addrId As Integer = 0
        Integer.TryParse(hfAddrId.Value, addrId)

        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String

            If isUpdate Then
                sql =
"UPDATE dbo.T054PartyAddress
    SET Address1 = @A1,
        Address2 = @A2,
        City = @City,
        Province = @Prov,
        PostalCode = @Postal,
        Country = @Country
  WHERE Id = @Id AND PartyId = @PartyId;"
            Else
                sql =
"INSERT INTO dbo.T054PartyAddress (PartyId, Address1, Address2, City, Province, PostalCode, Country)
 VALUES (@PartyId, @A1, @A2, @City, @Prov, @Postal, @Country);"
            End If

            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.Add("@PartyId", SqlDbType.Int).Value = PartyId

                cmd.Parameters.Add("@A1", SqlDbType.NVarChar, 200).Value = CType(If(String.IsNullOrWhiteSpace(txtA1.Text), DBNull.Value, txtA1.Text.Trim()), Object)
                cmd.Parameters.Add("@A2", SqlDbType.NVarChar, 200).Value = CType(If(String.IsNullOrWhiteSpace(txtA2.Text), DBNull.Value, txtA2.Text.Trim()), Object)
                cmd.Parameters.Add("@City", SqlDbType.NVarChar, 100).Value = CType(If(String.IsNullOrWhiteSpace(txtCity.Text), DBNull.Value, txtCity.Text.Trim()), Object)
                cmd.Parameters.Add("@Prov", SqlDbType.NVarChar, 100).Value = CType(If(String.IsNullOrWhiteSpace(txtProv.Text), DBNull.Value, txtProv.Text.Trim()), Object)
                cmd.Parameters.Add("@Postal", SqlDbType.NVarChar, 30).Value = CType(If(String.IsNullOrWhiteSpace(txtPostal.Text), DBNull.Value, txtPostal.Text.Trim()), Object)
                cmd.Parameters.Add("@Country", SqlDbType.NVarChar, 100).Value = CType(If(String.IsNullOrWhiteSpace(txtCountry.Text), DBNull.Value, txtCountry.Text.Trim()), Object)

                If isUpdate Then
                    cmd.Parameters.Add("@Id", SqlDbType.Int).Value = addrId
                End If

                cmd.ExecuteNonQuery()
            End Using
        End Using

        pnlAddrEdit.Visible = False
        BindAddresses()
        ShowMsg(If(isUpdate, "Adresse mise à jour.", "Adresse ajoutée."), True)
    End Sub

    Protected Sub btnAddrCancel_Click(sender As Object, e As EventArgs)
        pnlAddrEdit.Visible = False
    End Sub

    Private Sub DeleteAddress(addrId As Integer)
        Using cn As New SqlConnection(Cs)
            cn.Open()

            Dim sql As String = "DELETE FROM dbo.T054PartyAddress WHERE Id = @Id AND PartyId = @PartyId;"
            Using cmd As New SqlCommand(sql, cn)
                cmd.Parameters.Add("@Id", SqlDbType.Int).Value = addrId
                cmd.Parameters.Add("@PartyId", SqlDbType.Int).Value = PartyId
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Private Sub ShowMsg(text As String, ok As Boolean)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = If(ok, "msg ok", "msg bad")
    End Sub

</script>--%>

</body>
</html>

