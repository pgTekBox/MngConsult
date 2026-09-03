Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Calendrier des jours ouvrables bancaires (compensation ACSS).
'''
''' La norme 005 date le fichier et chaque échéance en jour JULIEN, sur un
''' calendrier bancaire : ni fin de semaine, ni jour férié, et jamais avant
''' la date de dépôt réelle. La plateforme raisonne donc en HEURE DE L'EST
''' (pas en UTC) et applique l'heure de tombée de l'institution.
'''
''' Les jours fériés viennent de T059BankHoliday (script 44), modifiable :
''' c'est le calendrier de la banque parraine qui fait foi.
'''
''' Réglages (Web.config / appSettings) :
'''   Eft.TimeZone      — fuseau, défaut « Eastern Standard Time »
'''   Eft.CutoffTime    — heure de tombée locale, défaut « 15:00 »
'''   Eft.HolidayScopes — portées retenues, défaut « CA,QC »
''' </summary>
Public Class clsBusinessCalendar

    Private Shared _holidays As HashSet(Of Date) = Nothing
    Private Shared _loadedUtc As DateTime = DateTime.MinValue
    Private Shared ReadOnly _lock As New Object()
    Private Const CacheHours As Integer = 6

    ' ---------------- Réglages ----------------

    Private Shared Function Cfg(key As String, dflt As String) As String
        Dim v As String = System.Configuration.ConfigurationManager.AppSettings(key)
        If String.IsNullOrWhiteSpace(v) Then Return dflt
        Return v.Trim()
    End Function

    ''' <summary>Fuseau horaire de référence de l'émetteur.</summary>
    Public Shared ReadOnly Property Zone() As TimeZoneInfo
        Get
            Try
                Return TimeZoneInfo.FindSystemTimeZoneById(Cfg("Eft.TimeZone", "Eastern Standard Time"))
            Catch
                Return TimeZoneInfo.Local
            End Try
        End Get
    End Property

    ''' <summary>Heure de tombée locale (dépôt du fichier à la banque).</summary>
    Public Shared ReadOnly Property Cutoff() As TimeSpan
        Get
            Dim ts As TimeSpan
            If TimeSpan.TryParse(Cfg("Eft.CutoffTime", "15:00"), ts) Then Return ts
            Return New TimeSpan(15, 0, 0)
        End Get
    End Property

    ' ---------------- Horloge ----------------

    ''' <summary>Maintenant, dans le fuseau de l'émetteur.</summary>
    Public Shared Function LocalNow() As DateTime
        Return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, Zone)
    End Function

    ''' <summary>Date du jour dans le fuseau de l'émetteur.</summary>
    Public Shared Function LocalToday() As Date
        Return LocalNow().Date
    End Function

    ' ---------------- Jours ouvrables ----------------

    ''' <summary>Vrai si la date est un jour de compensation (ni week-end, ni férié).</summary>
    Public Shared Function IsBusinessDay(d As Date) As Boolean
        If d.DayOfWeek = DayOfWeek.Saturday OrElse d.DayOfWeek = DayOfWeek.Sunday Then Return False
        Return Not Holidays().Contains(d.Date)
    End Function

    ''' <summary>La date elle-même si elle est ouvrable, sinon le prochain jour ouvrable.</summary>
    Public Shared Function EnsureBusinessDay(d As Date) As Date
        Dim x As Date = d.Date
        Dim guard As Integer = 0
        While Not IsBusinessDay(x) AndAlso guard < 60
            x = x.AddDays(1) : guard += 1
        End While
        Return x
    End Function

    ''' <summary>Ajoute n jours ouvrables (n = 0 renvoie le prochain jour ouvrable).</summary>
    Public Shared Function AddBusinessDays(d As Date, n As Integer) As Date
        Dim x As Date = EnsureBusinessDay(d)
        Dim i As Integer = 0
        While i < n
            x = EnsureBusinessDay(x.AddDays(1)) : i += 1
        End While
        Return x
    End Function

    ''' <summary>
    ''' Date de dépôt du fichier : aujourd'hui si nous sommes un jour ouvrable
    ''' avant l'heure de tombée, sinon le prochain jour ouvrable.
    ''' </summary>
    Public Shared Function FileBusinessDate() As Date
        Dim now As DateTime = LocalNow()
        Dim d As Date = now.Date
        If IsBusinessDay(d) AndAlso now.TimeOfDay < Cutoff Then Return d
        Return EnsureBusinessDay(d.AddDays(1))
    End Function

    ''' <summary>
    ''' Échéance valide pour un item : jamais avant la date de dépôt du fichier,
    ''' et toujours reportée au prochain jour ouvrable.
    ''' </summary>
    Public Shared Function SettlementDate(due As Date, fileDate As Date) As Date
        Dim d As Date = due.Date
        If d < fileDate Then d = fileDate
        Return EnsureBusinessDay(d)
    End Function

    ''' <summary>Vrai si l'heure de tombée du jour est passée (affichage UI).</summary>
    Public Shared Function CutoffPassed() As Boolean
        Dim now As DateTime = LocalNow()
        Return Not IsBusinessDay(now.Date) OrElse now.TimeOfDay >= Cutoff
    End Function

    ' ---------------- Chargement du calendrier ----------------

    ''' <summary>Vide le cache (après modification de T059BankHoliday).</summary>
    Public Shared Sub Invalidate()
        SyncLock _lock
            _holidays = Nothing
            _loadedUtc = DateTime.MinValue
        End SyncLock
    End Sub

    Private Shared Function Holidays() As HashSet(Of Date)
        SyncLock _lock
            If _holidays IsNot Nothing AndAlso DateTime.UtcNow.Subtract(_loadedUtc).TotalHours < CacheHours Then
                Return _holidays
            End If

            Dim set2 As New HashSet(Of Date)()
            Try
                Dim cs As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
                Using conn As New SqlConnection(cs)
                    Using cmd As New SqlCommand("s0122ListBankHolidays", conn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@FromDate", DateTime.UtcNow.Date.AddYears(-1))
                        cmd.Parameters.AddWithValue("@Scopes", Cfg("Eft.HolidayScopes", "CA,QC"))
                        Dim dt As New DataTable()
                        Dim da As New SqlDataAdapter(cmd)
                        da.Fill(dt)
                        For Each r As DataRow In dt.Rows
                            If Not IsDBNull(r("HolidayDate")) Then set2.Add(CDate(r("HolidayDate")).Date)
                        Next
                    End Using
                End Using
                _holidays = set2
                _loadedUtc = DateTime.UtcNow
            Catch ex As Exception
                ' Repli prudent : week-ends seulement, et on retentera au prochain appel.
                System.Diagnostics.Debug.WriteLine("BusinessCalendar: " & ex.Message)
                If _holidays Is Nothing Then _holidays = set2
            End Try

            Return _holidays
        End SyncLock
    End Function

End Class
