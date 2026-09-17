Imports System.Globalization
Imports System.Runtime.CompilerServices

''' <summary>Erreur de saisie à afficher telle quelle à l'utilisateur.</summary>
Public Class SaisieInvalideException
    Inherits Exception

    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class

''' <summary>Conversion des saisies, mise en forme et lecture des DataRow.</summary>
Public Module Outils

    Public ReadOnly FrCa As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

    ' ---------- Saisie ----------

    Private Function Nettoyer(texte As String) As String
        If texte Is Nothing Then Return ""
        Return texte.Replace(ChrW(160), "").Replace(ChrW(8239), "").Replace(" ", "").Replace("$", "").Replace("%", "").Replace(",", ".").Trim()
    End Function

    ''' <summary>Nombre décimal ; accepte la virgule ou le point. Vide = Nothing.</summary>
    Public Function DecN(texte As String, champ As String) As Decimal?
        Dim t = Nettoyer(texte)
        If t.Length = 0 Then Return Nothing
        Dim v As Decimal
        If Not Decimal.TryParse(t, NumberStyles.Number, CultureInfo.InvariantCulture, v) Then
            Throw New SaisieInvalideException("« " & champ & " » : nombre invalide.")
        End If
        If v < 0D Then Throw New SaisieInvalideException("« " & champ & " » ne peut pas être négatif.")
        Return v
    End Function

    ''' <summary>Nombre décimal ; vide = 0.</summary>
    Public Function Dec(texte As String, champ As String) As Decimal
        Return If(DecN(texte, champ), 0D)
    End Function

    Public Function EntierN(texte As String, champ As String) As Integer?
        Dim t = Nettoyer(texte)
        If t.Length = 0 Then Return Nothing
        Dim v As Integer
        If Not Integer.TryParse(t, NumberStyles.Integer, CultureInfo.InvariantCulture, v) OrElse v < 0 Then
            Throw New SaisieInvalideException("« " & champ & " » : nombre entier invalide.")
        End If
        Return v
    End Function

    ''' <summary>Date au format AAAA-MM-JJ. Vide = Nothing.</summary>
    Public Function DateN(texte As String, champ As String) As Date?
        If String.IsNullOrWhiteSpace(texte) Then Return Nothing
        Dim d As Date
        If Not Date.TryParseExact(texte.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then
            Throw New SaisieInvalideException("« " & champ & " » : date invalide (format AAAA-MM-JJ).")
        End If
        Return d
    End Function

    Public Function Requis(texte As String, champ As String) As String
        If String.IsNullOrWhiteSpace(texte) Then Throw New SaisieInvalideException("« " & champ & " » est requis.")
        Return texte.Trim()
    End Function

    Public Function Chiffres(texte As String) As String
        If texte Is Nothing Then Return ""
        Return New String(texte.Where(Function(c) Char.IsDigit(c)).ToArray())
    End Function

    ''' <summary>Validation du NAS par l'algorithme de Luhn.</summary>
    Public Function NasValide(nas As String) As Boolean
        If nas Is Nothing OrElse nas.Length <> 9 Then Return False
        Dim somme = 0
        For i = 0 To 8
            Dim n = AscW(nas(i)) - AscW("0"c)
            If i Mod 2 = 1 Then
                n *= 2
                If n > 9 Then n -= 9
            End If
            somme += n
        Next
        Return somme Mod 10 = 0
    End Function

    ' ---------- Mise en forme ----------

    Public Function Argent(valeur As Object) As String
        If valeur Is Nothing OrElse valeur Is DBNull.Value Then Return ""
        Return Convert.ToDecimal(valeur).ToString("N2", FrCa) & " $"
    End Function

    Public Function Nombre(valeur As Object) As String
        If valeur Is Nothing OrElse valeur Is DBNull.Value Then Return ""
        Return Convert.ToDecimal(valeur).ToString("0.##", FrCa)
    End Function

    ''' <summary>Valeur pour un champ de saisie numérique (vide si NULL).</summary>
    Public Function Champ(valeur As Object) As String
        If valeur Is Nothing OrElse valeur Is DBNull.Value Then Return ""
        Return Convert.ToDecimal(valeur).ToString("0.####", FrCa)
    End Function

    Public Function TexteDate(valeur As Object) As String
        If valeur Is Nothing OrElse valeur Is DBNull.Value Then Return ""
        Return Convert.ToDateTime(valeur).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function

    Public Function LibellePeriodes(periodes As Object) As String
        If periodes Is Nothing OrElse periodes Is DBNull.Value Then Return ""
        Select Case Convert.ToInt32(periodes)
            Case 52 : Return "Hebdomadaire (52)"
            Case 26 : Return "Aux 2 semaines (26)"
            Case 24 : Return "Bimensuel (24)"
            Case 12 : Return "Mensuel (12)"
            Case Else : Return Convert.ToInt32(periodes).ToString() & " périodes"
        End Select
    End Function

    Public Function LibelleStatut(statut As Object) As String
        Select Case Convert.ToString(statut)
            Case "B" : Return "Brouillon"
            Case "C" : Return "Confirmé"
            Case "A" : Return "Annulé"
            Case Else : Return ""
        End Select
    End Function

    ' ---------- Lecture des DataRow ----------

    <Extension>
    Public Function Txt(r As DataRow, colonne As String) As String
        Return If(r.IsNull(colonne), "", Convert.ToString(r(colonne)).Trim())
    End Function

    <Extension>
    Public Function Dcm(r As DataRow, colonne As String) As Decimal
        Return If(r.IsNull(colonne), 0D, Convert.ToDecimal(r(colonne)))
    End Function

    <Extension>
    Public Function DcmN(r As DataRow, colonne As String) As Decimal?
        If r.IsNull(colonne) Then Return Nothing
        Return Convert.ToDecimal(r(colonne))
    End Function

    <Extension>
    Public Function Ent(r As DataRow, colonne As String) As Integer
        Return If(r.IsNull(colonne), 0, Convert.ToInt32(r(colonne)))
    End Function

    <Extension>
    Public Function Bln(r As DataRow, colonne As String) As Boolean
        Return Not r.IsNull(colonne) AndAlso Convert.ToBoolean(r(colonne))
    End Function

    <Extension>
    Public Function DtN(r As DataRow, colonne As String) As Date?
        If r.IsNull(colonne) Then Return Nothing
        Return Convert.ToDateTime(r(colonne))
    End Function

End Module
