<%@ Page Language="vb" AutoEventWireup="true" %>

<%@ Import Namespace="BCrypt.Net" %>

<!DOCTYPE html>
<html>
<head>
    <title>Générer un hash bcrypt</title>
    <style>
        body { font-family: system-ui, sans-serif; padding: 30px; max-width: 700px; margin: 0 auto; background: #f6f7fb; }
        h1 { color: #2563eb; }
        .box { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,.08); margin-bottom: 16px; }
        label { display: block; font-weight: 700; margin-bottom: 6px; }
        input[type=text] { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 8px; font-size: 14px; box-sizing: border-box; }
        button { background: #2563eb; color: white; border: none; padding: 10px 20px; border-radius: 8px; font-weight: 700; cursor: pointer; font-size: 14px; }
        pre { background: #0f172a; color: #06b6d4; padding: 14px; border-radius: 8px; overflow-x: auto; font-size: 12px; white-space: pre-wrap; word-break: break-all; }
        .warning { background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px; border-radius: 8px; margin-bottom: 16px; }
    </style>
</head>
<body>
    <form runat="server">

        <h1>🔐 Générateur de hash bcrypt</h1>

        <div class="warning">
            ⚠️ <strong>SUPPRIMEZ CETTE PAGE après avoir créé votre premier admin.</strong>
            Elle ne doit pas rester accessible en production.
        </div>

        <div class="box">
            <label>Mot de passe à hasher</label>
            <input type="text" id="tbPassword" runat="server" value="Admin123!" />
            <br /><br />
            <button type="submit" runat="server" id="btnHash" onserverclick="btnHash_Click">
                Générer le hash
            </button>
        </div>

        <asp:Panel ID="pnlResult" runat="server" Visible="false" CssClass="box">
            <label>Hash bcrypt généré :</label>
            <pre id="preHash" runat="server"></pre>

            <label style="margin-top:16px;">SQL à exécuter pour créer l'admin :</label>
            <pre id="preSql" runat="server"></pre>
        </asp:Panel>

    </form>

    <script runat="server">
        Protected Sub btnHash_Click(sender As Object, e As EventArgs)
            Dim password As String = tbPassword.Value
            If String.IsNullOrEmpty(password) Then Return

            Dim hash As String = BCrypt.Net.BCrypt.HashPassword(password, 11)

            preHash.InnerText = hash

            Dim sql As String =
                "INSERT INTO dbo.T015User" & vbCrLf &
                "    (CompanyGUID, Email, PasswordHash, FirstName, LastName, IsAdmin, IsActive)" & vbCrLf &
                "VALUES" & vbCrLf &
                "    ('87893D29-6D64-40C8-8E45-A3492B4FBB91'," & vbCrLf &
                "     'admin@60sec.ca'," & vbCrLf &
                "     '" & hash & "'," & vbCrLf &
                "     'Admin', 'Principal', 1, 1);"

            preSql.InnerText = sql
            pnlResult.Visible = True
        End Sub
    </script>

</body>
</html>
