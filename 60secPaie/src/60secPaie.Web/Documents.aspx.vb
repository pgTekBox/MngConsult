''' <summary>
''' Les documents de la plateforme offerts à toutes les compagnies, servis tels quels :
''' ?doc=instructions-t4&amp;annee=AAAA — les instructions T4 de l'ARC de l'année, téléversées dans la
''' console d'administration (paie.FormulaireFeuillet, type TI, compagnie 0). Le PDF s'ouvre dans le navigateur.
''' </summary>
Public Class PageDocuments
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim annee = IdRequete("annee")
        If Request.QueryString("doc") = "instructions-t4" AndAlso annee > 0 Then
            Dim document = FormulaireOfficiel.InstructionsT4(annee)
            If document IsNot Nothing Then
                EnvoyerFichier(document.Txt("NomFichier"), CType(document("Contenu"), Byte()), "application/pdf", True)
                Return
            End If
        End If
        Response.StatusCode = 404
        Response.End()
    End Sub

End Class
