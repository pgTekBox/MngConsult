Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Console d'administration : les demandes « Réserver ma place » de la page
''' d'accueil (T025LandingReservation, via s0869GetLandingReservations).
''' Lecture seule : la liste sert à rappeler les gens et à préparer le lancement.
''' </summary>
Public Class wbfReservations
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return
        Dim p As New Collection
        p.Add(New SqlParameter("@Top", 500))
        Dim ds As DataSet = ExecuteSQLds("s0869GetLandingReservations", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rpt.DataSource = dt
        rpt.DataBind()
        litNb.Text = dt.Rows.Count.ToString()
        pnlVide.Visible = dt.Rows.Count = 0
    End Sub

    Protected Function FormatDate(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return ""
        Return CDate(v).ToString("yyyy-MM-dd HH:mm")
    End Function

    ''' <summary>Les listes de la page arrivent sous la forme « valeur|libellé » : on montre le libellé.</summary>
    Protected Function Libelle(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return ""
        Dim s As String = v.ToString()
        Dim i As Integer = s.IndexOf("|"c)
        If i >= 0 Then s = s.Substring(i + 1)
        Return Server.HtmlEncode(s)
    End Function

    Protected Function Secteur(sect As Object, sous As Object, autre As Object) As String
        Dim parts As New List(Of String)
        For Each v In New Object() {sect, sous, autre}
            Dim l As String = Libelle(v)
            If l.Length > 0 AndAlso l <> "—" AndAlso Not l.StartsWith("Choisissez") Then parts.Add(l)
        Next
        Return String.Join(" › ", parts)
    End Function

    ''' <summary>Les champs propres au profil, en une ligne.</summary>
    Protected Function Details(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim parts As New List(Of String)
        Select Case Convert.ToString(r("Profil"))
            Case "ta"
                If Libelle(r("Taxes")).Length > 0 Then parts.Add("TPS/TVQ : " & Libelle(r("Taxes")))
            Case "c0"
                If Libelle(r("FinExercice")).Length > 0 Then parts.Add("Fin d'exercice : " & Libelle(r("FinExercice")))
            Case "c4"
                If Not IsDBNull(r("NbEmployes")) Then parts.Add(r("NbEmployes").ToString() & " employé(s)")
                If Libelle(r("FrequencePaie")).Length > 0 Then parts.Add("Paie : " & Libelle(r("FrequencePaie")))
            Case "cab"
                If Libelle(r("NbDossiers")).Length > 0 Then parts.Add("Dossiers : " & Libelle(r("NbDossiers")))
                If Libelle(r("Logiciel")).Length > 0 Then parts.Add("Logiciel : " & Libelle(r("Logiciel")))
                If Not IsDBNull(r("Pilote")) AndAlso Convert.ToBoolean(r("Pilote")) Then parts.Add("Projet pilote")
        End Select
        If Not IsDBNull(r("Fondateur")) AndAlso Convert.ToBoolean(r("Fondateur")) Then parts.Add("Client-fondateur")
        If Libelle(r("Estimation")).Length > 0 Then parts.Add("Estimation : " & Libelle(r("Estimation")))
        Return String.Join(" · ", parts)
    End Function

End Class
