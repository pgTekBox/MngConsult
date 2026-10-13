


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

            ' Les liens : le courriel du soutien (la même adresse que « Contacter le
            ' soutien » du tableau de bord), et les documents juridiques du site public
            ' (le site ouvre le document visé par le #), dans la langue de la session,
            ' dans un nouvel onglet.
            Dim lang As String = CurrentLang
            lnkSupport.HRef = "mailto:support@60sec.ca"
            lnkConfidentialite.HRef = ResolveUrl("~/LandingPage.aspx") & "?lang=" & lang & "#doc-confidentialite"
            lnkConditions.HRef = ResolveUrl("~/LandingPage.aspx") & "?lang=" & lang & "#doc-conditions"
            Select Case lang
                Case "en" : lnkSupport.InnerText = "Support" : lnkConfidentialite.InnerText = "Privacy" : lnkConditions.InnerText = "Terms"
                Case "es" : lnkSupport.InnerText = "Soporte" : lnkConfidentialite.InnerText = "Privacidad" : lnkConditions.InnerText = "Condiciones"
                Case Else : lnkSupport.InnerText = "Support" : lnkConfidentialite.InnerText = "Confidentialité" : lnkConditions.InnerText = "Conditions"
            End Select
        End Sub

    End Class
End Namespace
