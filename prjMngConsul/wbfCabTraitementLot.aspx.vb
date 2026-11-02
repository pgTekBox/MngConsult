''' <summary>
''' « Traitement en lot » du Portail comptable : faire la même action pour
''' plusieurs clients d'un seul geste (ou une à la fois), regroupée par activité,
''' client, urgence ou échéance, avec exclusion ligne par ligne et confirmation.
''' Calqué exactement sur la maquette d'Yves (puces de synthèse, barre « Regrouper
''' par », lots pliables avec table des transactions, barre globale « Lancer tous
''' les lots », fenêtre de confirmation, bandeau « Faits aujourd'hui », annulation).
'''
''' Les données affichées sont **illustratives** (démonstration) : le moteur réel
''' de traitement en lot n'est pas encore branché. Un bandeau le signale et tout
''' le contenu + l'interactivité vivent côté client. Réservé aux comptables
''' (IsAccountant), en mode Portail comptable.
''' </summary>
Public Class wbfCabTraitementLot
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True
    End Sub

End Class
