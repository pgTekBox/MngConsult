' =============================================================================
' Etat global partage entre le service, le controleur et l'interface.
' Meme role que le Module1 du service SMTP dont ce projet s'inspire.
' =============================================================================
Module Module1

    ''' <summary>Verrou unique protegeant l'objet de statut partage.</summary>
    Public thisLock As New Object

    ''' <summary>Statut publie sur le pipe nomme et lu par l'interface (Form1).</summary>
    Public ExecStatus As New clsExecutorStatus

    ''' <summary>Taches executees avec succes depuis le demarrage du service.</summary>
    Public CounterSucces As Integer = 0

    ''' <summary>Taches en echec depuis le demarrage du service.</summary>
    Public CounterEchec As Integer = 0

    ''' <summary>
    ''' Dernier appel a sp_GenererPlanningJobs (UTC). Ici et pas dans
    ''' clsTaskExecutor : celui-ci est reconstruit a chaque tour de boucle et
    ''' oublierait aussitot la date.
    ''' </summary>
    Public DernierPlanning As Date = Date.MinValue

End Module
