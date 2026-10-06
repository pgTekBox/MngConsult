Imports Paie60Sec.Calcul

''' <summary>
''' Fournit au moteur les taux d'une année depuis la base (paie.ParametresAnnee),
''' tenue à jour dans la console Sec60Admin. Seule une ligne VALIDÉE compte : une
''' année en brouillon n'existe pas pour la paie.
'''
''' Branché une fois au démarrage (Global.asax) sur ParametresAnnee.Fournisseur.
''' Le résultat — trouvé ou non — est gardé cinq minutes : une validation faite
''' dans la console est visible ici dans ce délai, sans redémarrage. Une base
''' injoignable rend Nothing, et le moteur retombe sur les valeurs du code.
''' </summary>
Public NotInheritable Class ServiceParametres

    Private Const DureeCacheMinutes As Integer = 5
    Private Shared ReadOnly _verrou As New Object()
    Private Shared ReadOnly _cache As New Dictionary(Of Integer, Tuple(Of Date, ParametresAnnee))()

    Private Sub New()
    End Sub

    Public Shared Sub Brancher()
        ParametresAnnee.Fournisseur = AddressOf Charger
    End Sub

    Public Shared Function Charger(annee As Integer) As ParametresAnnee
        SyncLock _verrou
            Dim entree As Tuple(Of Date, ParametresAnnee) = Nothing
            If _cache.TryGetValue(annee, entree) AndAlso entree.Item1 > Date.UtcNow Then Return entree.Item2

            Dim p As ParametresAnnee = Nothing
            Try
                Dim r = Db.Ligne("EXEC paie.spParametresAnnee_Get @Annee = @a, @SeulementValide = 1", Db.P("@a", annee))
                p = ParametresAnnee.DepuisLigne(r)
                If p IsNot Nothing Then ChargerProvinces(p)
            Catch ex As Exception
                ' La base ne répond pas ou la ligne est illisible : on le note, et le
                ' moteur utilisera les valeurs du code s'il en a pour cette année.
                System.Diagnostics.Trace.TraceError("Taux de l'année " & annee.ToString() & " : " & ex.ToString())
                p = Nothing
            End Try

            _cache(annee) = Tuple.Create(Date.UtcNow.AddMinutes(DureeCacheMinutes), p)
            Return p
        End SyncLock
    End Function

    ''' <summary>
    ''' Les autres provinces et territoires de l'année (paie.ParametresProvince, script 06_provinces.sql).
    ''' Table absente, vide ou illisible : la liste reste vide et le moteur prend les valeurs du code
    ''' pour ces provinces — le Québec et l'Ontario de la même année restent ceux de la base.
    ''' </summary>
    Private Shared Sub ChargerProvinces(p As ParametresAnnee)
        Try
            Dim lignes = Db.Table("SELECT Province, EnVigueurLe, Tranches, MontantPersonnelBase, TauxCredits, Particularites, AccidentsMaxAssurable " &
                                  "FROM paie.ParametresProvince WHERE Annee = @a", Db.P("@a", p.Annee))
            Dim liste As New List(Of ParametresProvince)()
            For Each ligne As DataRow In lignes.Rows
                liste.Add(ParametresProvince.DepuisLigne(ligne))
            Next
            p.AutresProvinces = liste
        Catch ex As Exception
            System.Diagnostics.Trace.TraceError("Taux des provinces de l'année " & p.Annee.ToString() & " : " & ex.ToString())
            p.AutresProvinces = New List(Of ParametresProvince)()
        End Try
    End Sub

    ''' <summary>Oublie ce qui est en cache : la prochaine paie relira la base.</summary>
    Public Shared Sub Oublier()
        SyncLock _verrou
            _cache.Clear()
        End SyncLock
    End Sub

End Class
