Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Orchestration Interac e-Transfer (rail parallèle, SIMULÉ). Réutilise la
''' machinerie de paiement (s0020/s0038 avec Method='Interac') et journalise
''' les évènements Interac (T056). Le règlement est individuel (s0097), le
''' refus/expiration contre-passe (s0049). Le vrai Interac est gaté par le
''' partenaire ; ici les étapes « envoi »/« dépôt »/« refus » sont simulées.
''' </summary>
Public Class clsInterac

    Private Shared ReadOnly Property ConnStr() As String
        Get
            Return System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    ''' <summary>Encaissement Interac (demande d'argent à un client).</summary>
    Public Shared Function CreateEncaissement(abonneId As Integer, clientId As Integer, amountCents As Long, feeCents As Long,
                                              interacEmail As String, description As String, reference As String, adminId As Integer) As Long
        Dim pid As Long = InitiateClient(abonneId, clientId, amountCents, feeCents, interacEmail, description, reference, adminId)
        SaveEvent(pid, "Requested", "Demande d'argent envoyée à " & interacEmail)
        Return pid
    End Function

    ''' <summary>Décaissement Interac (virement à un fournisseur).</summary>
    Public Shared Function CreatePayout(abonneId As Integer, fournId As Integer, amountCents As Long, feeCents As Long,
                                        interacEmail As String, description As String, reference As String, adminId As Integer) As Long
        Dim pid As Long = InitiatePayout(abonneId, fournId, amountCents, feeCents, interacEmail, description, reference, adminId)
        SaveEvent(pid, "Sent", "Virement Interac envoyé à " & interacEmail)
        Return pid
    End Function

    ''' <summary>Le bénéficiaire dépose / la demande est acquittée -> règlement.</summary>
    Public Shared Sub Deposit(paymentId As Long, adminId As Integer)
        ExecPaymentProc("s0097SettleInteracPayment", paymentId, adminId)
        SaveEvent(paymentId, "Deposited", "Transfert déposé / encaissé (réglé).")
    End Sub

    ''' <summary>Le bénéficiaire refuse ou le transfert expire -> contre-passation.</summary>
    Public Shared Sub Decline(paymentId As Long, reason As String)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0049ProcessReturn", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@PaymentId", paymentId)
            cmd.Parameters.AddWithValue("@Reason", If(reason.Length > 100, reason.Substring(0, 100), reason))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
        SaveEvent(paymentId, "Declined", reason)
    End Sub

    ' -------- Acces BD --------

    Private Shared Function InitiateClient(abonneId As Integer, clientId As Integer, amountCents As Long, feeCents As Long,
                                           interacEmail As String, description As String, reference As String, adminId As Integer) As Long
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0020InitiateClientPayment", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@AbonneId", abonneId)
            cmd.Parameters.AddWithValue("@ClientId", clientId)
            cmd.Parameters.AddWithValue("@AmountCents", amountCents)
            cmd.Parameters.AddWithValue("@FeeCents", feeCents)
            cmd.Parameters.AddWithValue("@Description", Nz(description))
            cmd.Parameters.AddWithValue("@Reference", Nz(reference))
            cmd.Parameters.AddWithValue("@SettlementDays", 0)   ' Interac = quasi-instantané
            cmd.Parameters.AddWithValue("@AdminId", If(adminId = 0, CObj(DBNull.Value), adminId))
            cmd.Parameters.AddWithValue("@Method", "Interac")
            cmd.Parameters.AddWithValue("@InteracEmail", Nz(interacEmail))
            Dim outP As New SqlParameter("@PaymentId", SqlDbType.BigInt) With {.Direction = ParameterDirection.InputOutput, .Value = DBNull.Value}
            cmd.Parameters.Add(outP)
            conn.Open() : cmd.ExecuteNonQuery()
            Return If(outP.Value Is Nothing OrElse IsDBNull(outP.Value), 0L, Convert.ToInt64(outP.Value))
        End Using : End Using
    End Function

    Private Shared Function InitiatePayout(abonneId As Integer, fournId As Integer, amountCents As Long, feeCents As Long,
                                           interacEmail As String, description As String, reference As String, adminId As Integer) As Long
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0038InitiatePayout", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@AbonneId", abonneId)
            cmd.Parameters.AddWithValue("@FournisseurId", fournId)
            cmd.Parameters.AddWithValue("@AmountCents", amountCents)
            cmd.Parameters.AddWithValue("@FeeCents", feeCents)
            cmd.Parameters.AddWithValue("@Description", Nz(description))
            cmd.Parameters.AddWithValue("@Reference", Nz(reference))
            cmd.Parameters.AddWithValue("@SettlementDays", 0)
            cmd.Parameters.AddWithValue("@AdminId", If(adminId = 0, CObj(DBNull.Value), adminId))
            cmd.Parameters.AddWithValue("@Method", "Interac")
            cmd.Parameters.AddWithValue("@InteracEmail", Nz(interacEmail))
            Dim outP As New SqlParameter("@PaymentId", SqlDbType.BigInt) With {.Direction = ParameterDirection.InputOutput, .Value = DBNull.Value}
            cmd.Parameters.Add(outP)
            conn.Open() : cmd.ExecuteNonQuery()
            Return If(outP.Value Is Nothing OrElse IsDBNull(outP.Value), 0L, Convert.ToInt64(outP.Value))
        End Using : End Using
    End Function

    Private Shared Sub ExecPaymentProc(proc As String, paymentId As Long, adminId As Integer)
        Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand(proc, conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@PaymentId", paymentId)
            cmd.Parameters.AddWithValue("@AdminId", If(adminId = 0, CObj(DBNull.Value), adminId))
            conn.Open() : cmd.ExecuteNonQuery()
        End Using : End Using
    End Sub

    Private Shared Sub SaveEvent(paymentId As Long, eventType As String, message As String)
        Try
            Using conn As New SqlConnection(ConnStr) : Using cmd As New SqlCommand("s0098SaveInteracEvent", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@PaymentId", paymentId)
                cmd.Parameters.AddWithValue("@EventType", eventType)
                cmd.Parameters.AddWithValue("@Message", If(String.IsNullOrEmpty(message), CObj(DBNull.Value), If(message.Length > 300, message.Substring(0, 300), message)))
                conn.Open() : cmd.ExecuteNonQuery()
            End Using : End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Interac SaveEvent: " & ex.Message)
        End Try
    End Sub

    Private Shared Function Nz(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

End Class
