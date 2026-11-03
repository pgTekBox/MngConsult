''' <summary>
''' « Ma journée » du Portail comptable (maquette v2) : l'écran d'accueil du cabinet.
''' Liste d'actions priorisée (échéances gouvernementales, argent qui attend, client
''' qui attend, signalements de 60, reste), charge de l'équipe, « 60 a fait
''' aujourd'hui », échéances des 30 prochains jours, et une fenêtre de détail par
''' activité (pourquoi maintenant, étapes qui-fait-quoi, pièces, autorisation,
''' traitement en lot). Commutateur « connecté comme » (démo) pour voir la vue d'une
''' personne.
'''
''' Les données sont **illustratives** (bandeau de démo). Le nouveau modèle (types
''' d'actions riches : bloc, priorité, étapes, pièces, autorisation) ne correspond
''' pas aux tâches libres réelles (T339/s0956) de l'ancienne version ; le
''' branchement sur les vraies données reste à refaire. Tout le rendu +
''' l'interactivité vivent côté client. Réservé aux comptables (IsAccountant).
''' </summary>
Public Class wbfCabJournee
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True
    End Sub

End Class
