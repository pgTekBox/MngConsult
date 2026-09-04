' =============================================================================
' Etat global partage entre le service, le controleur et l'interface.
' Meme role que le Module1 du service SMTP dont ce projet s'inspire.
' =============================================================================
Module Module1

    ''' <summary>Verrou unique protegeant l'objet de statut partage (ReceiptStatus).</summary>
    Public thisLock As New Object

    ''' <summary>Nombre de recus traites avec succes depuis le demarrage du service.</summary>
    Public CounterReceiptDone As Integer = 0

    ''' <summary>Nombre de recus en echec depuis le demarrage du service.</summary>
    Public CounterReceiptError As Integer = 0

    ''' <summary>Statut publie sur le pipe nomme et lu par l'interface (Form1).</summary>
    Public ReceiptStatus As New clsReceiptStatus

End Module
