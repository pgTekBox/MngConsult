Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports System.Web.Script.Serialization

''' <summary>
''' Connecteur KYB (Know Your Business) — copie alignee sur PortailMaster.
''' Interface abstraite IKybProvider + fournisseur SANDBOX simule (regles
''' deterministes). Le vrai fournisseur (Trulioo/Onfido) implementerait la
''' meme interface, gate par le contrat. clsKyb.RunCheck orchestre :
''' rassemble les donnees de l'abonne, appelle le fournisseur, enregistre la
''' verification (T057), pilote le StatutKYB et journalise l'action (audit).
''' </summary>

''' <summary>Résultat d'une vérification KYB.</summary>
Public Class KybResult
    Public Status As String = "Review"      ' Verified / Rejected / Review / Error
    Public Score As Integer
    Public RegistryMatch As Boolean
    Public WatchlistClear As Boolean
    Public AddressValid As Boolean
    Public Message As String = ""
    Public ProviderRef As String = ""
End Class

Public Interface IKybProvider
    ReadOnly Property Name() As String
    Function Verify(details As Dictionary(Of String, Object)) As KybResult
End Interface

''' <summary>Fournisseur SANDBOX : résultat déterministe selon les données.</summary>
Public Class SandboxKybProvider
    Implements IKybProvider

    Public ReadOnly Property Name() As String Implements IKybProvider.Name
        Get
            Return "sandbox"
        End Get
    End Property

    Public Function Verify(details As Dictionary(Of String, Object)) As KybResult Implements IKybProvider.Verify
        Dim r As New KybResult()
        Dim raison As String = S(details, "RaisonSociale")
        Dim neq As String = S(details, "NumeroEntreprise")
        Dim ville As String = S(details, "Ville")
        Dim cp As String = S(details, "CodePostal")

        r.RegistryMatch = (neq.Trim().Length > 0)
        r.AddressValid = (ville.Trim().Length > 0 AndAlso cp.Trim().Length > 0)
        r.WatchlistClear = Not (raison.ToUpperInvariant().Contains("REJECT") OrElse neq.Trim().EndsWith("0000"))
        r.ProviderRef = "SBX-" & Guid.NewGuid().ToString("N").Substring(0, 10).ToUpperInvariant()

        If Not r.WatchlistClear Then
            r.Status = "Rejected" : r.Score = 10
            r.Message = "Correspondance sur une liste de surveillance / registre défavorable (simulation)."
        ElseIf r.RegistryMatch AndAlso r.AddressValid Then
            r.Status = "Verified" : r.Score = 92
            r.Message = "Entreprise vérifiée : registre + adresse concordants, aucune alerte."
        Else
            r.Status = "Review" : r.Score = 55
            r.Message = "Revue requise : informations incomplètes (" &
                        If(r.RegistryMatch, "", "n° d'entreprise ") &
                        If(r.AddressValid, "", "adresse ") & "manquant(es))."
        End If
        Return r
    End Function

    Private Shared Function S(d As Dictionary(Of String, Object), key As String) As String
        If d.ContainsKey(key) AndAlso d(key) IsNot Nothing Then Return d(key).ToString()
        Return ""
    End Function
End Class

Public Class clsKyb

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>Fournisseur KYB configuré (Web.config Kyb.Provider ; sandbox par défaut).</summary>
    Public Shared Function GetProvider() As IKybProvider
        Dim name As String = If(System.Configuration.ConfigurationManager.AppSettings("Kyb.Provider"), "sandbox").Trim().ToLowerInvariant()
        Select Case name
            Case Else : Return New SandboxKybProvider()
        End Select
    End Function

    ''' <summary>Lance une vérification KYB pour un abonné, enregistre le résultat,
    ''' met à jour le StatutKYB et journalise l'action.</summary>
    Public Shared Function RunCheck(abonneId As Integer, adminId As Integer, actorEmail As String, ip As String) As KybResult
        Dim ab As DataRow = GetAbonne(abonneId)
        If ab Is Nothing Then Throw New Exception("Abonné introuvable.")

        Dim details As New Dictionary(Of String, Object) From {
            {"RaisonSociale", V(ab, "RaisonSociale")},
            {"NumeroEntreprise", V(ab, "NumeroEntreprise")},
            {"Ville", V(ab, "Ville")},
            {"CodePostal", V(ab, "CodePostal")},
            {"Pays", V(ab, "Pays")}
        }

        Dim prov As IKybProvider = GetProvider()
        Dim res As KybResult = prov.Verify(details)

        Dim js As New JavaScriptSerializer()
        Dim reqJson As String = js.Serialize(details)
        Dim resJson As String = js.Serialize(New Dictionary(Of String, Object) From {
            {"status", res.Status}, {"score", res.Score},
            {"registryMatch", res.RegistryMatch}, {"watchlistClear", res.WatchlistClear},
            {"addressValid", res.AddressValid}, {"providerRef", res.ProviderRef}, {"message", res.Message}})

        SaveCheck(abonneId, prov.Name, res, reqJson, resJson, adminId)

        Dim statutKyb As String = MapStatut(res.Status)
        SetKybStatus(abonneId, statutKyb, adminId)

        Try
            clsAudit.Write(adminId, actorEmail, "KybCheck", "Abonne", abonneId, V(ab, "RaisonSociale"),
                           prov.Name & " -> " & res.Status & " (score " & res.Score & ", " & statutKyb & ")", ip)
        Catch
        End Try

        Return res
    End Function

    Private Shared Function MapStatut(status As String) As String
        Select Case status
            Case "Verified" : Return "Verifie"
            Case "Rejected" : Return "Rejete"
            Case Else : Return "EnCours"
        End Select
    End Function

    ' -------- Acces BD --------

    Private Shared Function GetAbonne(id As Integer) As DataRow
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0005GetAbonne", conn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddWithValue("@Id", id)
            Dim dt As New DataTable() : Dim da As New SqlDataAdapter(cmd) : da.Fill(dt)
            If dt.Rows.Count = 0 Then Return Nothing
            Return dt.Rows(0)
        End Using : End Using
    End Function

    Private Shared Sub SaveCheck(abonneId As Integer, provider As String, r As KybResult, reqJson As String, resJson As String, adminId As Integer)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0101SaveKybCheck", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@AbonneId", abonneId)
            cmd.Parameters.AddWithValue("@Provider", provider)
            cmd.Parameters.AddWithValue("@ProviderRef", If(String.IsNullOrEmpty(r.ProviderRef), CObj(DBNull.Value), r.ProviderRef))
            cmd.Parameters.AddWithValue("@Status", r.Status)
            cmd.Parameters.AddWithValue("@Score", r.Score)
            cmd.Parameters.AddWithValue("@RegistryMatch", r.RegistryMatch)
            cmd.Parameters.AddWithValue("@WatchlistClear", r.WatchlistClear)
            cmd.Parameters.AddWithValue("@AddressValid", r.AddressValid)
            cmd.Parameters.AddWithValue("@Message", If(String.IsNullOrEmpty(r.Message), CObj(DBNull.Value), r.Message))
            cmd.Parameters.AddWithValue("@RequestJson", If(String.IsNullOrEmpty(reqJson), CObj(DBNull.Value), reqJson))
            cmd.Parameters.AddWithValue("@ResultJson", If(String.IsNullOrEmpty(resJson), CObj(DBNull.Value), resJson))
            cmd.Parameters.AddWithValue("@AdminId", If(adminId = 0, CObj(DBNull.Value), adminId))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Sub SetKybStatus(abonneId As Integer, statutKyb As String, adminId As Integer)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0103SetAbonneKybStatus", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@AbonneId", abonneId)
            cmd.Parameters.AddWithValue("@StatutKYB", statutKyb)
            cmd.Parameters.AddWithValue("@AdminId", If(adminId = 0, CObj(DBNull.Value), adminId))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Function V(r As DataRow, col As String) As String
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

End Class
