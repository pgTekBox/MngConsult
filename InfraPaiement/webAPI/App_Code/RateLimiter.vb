Imports System.Configuration

''' <summary>
''' Limiteur de débit par clé d'API — fenêtre fixe en mémoire (par processus).
''' Config Web.config : RateLimit.Enabled (true/false), RateLimit.PerMinute (int).
''' Note : compteur en mémoire (non partagé entre instances) ; suffisant pour
''' une instance unique. Pour du multi-instances, remplacer par un backend
''' partagé (Redis/SQL).
''' </summary>
Public Class RateLimiter

    Private Shared ReadOnly _lock As New Object()
    Private Shared ReadOnly _windows As New Dictionary(Of Integer, WindowState)()
    Private Const WindowSeconds As Long = 60

    Private Class WindowState
        Public WindowStartEpoch As Long
        Public Count As Integer
    End Class

    Public Structure RateResult
        Public Allowed As Boolean
        Public Limit As Integer
        Public Remaining As Integer
        Public ResetEpoch As Long
        Public RetryAfter As Integer
    End Structure

    Private Shared Function IsEnabled() As Boolean
        Dim v As String = ConfigurationManager.AppSettings("RateLimit.Enabled")
        If String.IsNullOrEmpty(v) Then Return True
        Dim b As Boolean
        If Boolean.TryParse(v, b) Then Return b
        Return True
    End Function

    Private Shared Function MaxPerMinute() As Integer
        Dim v As String = ConfigurationManager.AppSettings("RateLimit.PerMinute")
        Dim n As Integer
        If Integer.TryParse(v, n) AndAlso n > 0 Then Return n
        Return 120
    End Function

    ''' <summary>Enregistre une requête pour la clé et indique si elle est permise.</summary>
    Public Shared Function Check(apiKeyId As Integer) As RateResult
        Dim maxReq As Integer = MaxPerMinute()
        Dim now As Long = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
        Dim curWindow As Long = now - (now Mod WindowSeconds)

        Dim r As New RateResult()
        r.Limit = maxReq
        r.ResetEpoch = curWindow + WindowSeconds

        If Not IsEnabled() Then
            r.Allowed = True
            r.Remaining = maxReq
            Return r
        End If

        SyncLock _lock
            Dim w As WindowState = Nothing
            If Not _windows.TryGetValue(apiKeyId, w) OrElse w.WindowStartEpoch <> curWindow Then
                w = New WindowState With {.WindowStartEpoch = curWindow, .Count = 0}
                _windows(apiKeyId) = w
                ' Purge légère des fenêtres périmées si le dictionnaire grossit.
                If _windows.Count > 5000 Then PurgeStale(curWindow)
            End If
            w.Count += 1
            If w.Count > maxReq Then
                r.Allowed = False
                r.Remaining = 0
                r.RetryAfter = CInt(Math.Max(1, r.ResetEpoch - now))
            Else
                r.Allowed = True
                r.Remaining = maxReq - w.Count
            End If
        End SyncLock
        Return r
    End Function

    Private Shared Sub PurgeStale(curWindow As Long)
        Dim toRemove As New List(Of Integer)()
        For Each kv In _windows
            If kv.Value.WindowStartEpoch <> curWindow Then toRemove.Add(kv.Key)
        Next
        For Each k In toRemove
            _windows.Remove(k)
        Next
    End Sub

End Class
