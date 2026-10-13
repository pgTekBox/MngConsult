


Namespace Controls


    Public Class Footer
        Inherits clsDataUC

        ''' <summary>
        ''' Les mentions légales du pied de page, celles du gabarit 60secondes : la
        ''' raison sociale et la phrase « Vos données restent au Canada. », dans la
        ''' langue de la session. La raison sociale ne se traduit pas.
        ''' </summary>
        Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
            litCompany.Text = "60secondes — 9567-0048 Québec inc., Montréal."
            Select Case CurrentLang
                Case "en" : litDonnees.Text = "Your data stays in Canada."
                Case "es" : litDonnees.Text = "Sus datos permanecen en Canadá."
                Case Else : litDonnees.Text = "Vos données restent au Canada."
            End Select
        End Sub

    End Class
End Namespace
