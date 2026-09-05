''' <summary>
''' Etat observable du service, sur le meme principe que clsSMTPStatus du
''' service SMTP :
'''   1. les threads de travail le mettent a jour (sous SyncLock thisLock) ;
'''   2. GetAllParam le serialise en une ligne '|'-separee, poussee dans le
'''      pipe nomme vers l'interface ;
'''   3. RestoreParam le reconstruit cote interface (Form1).
'''
''' Toutes les proprietes sont des String pour que la serialisation reste une
''' simple concatenation. GetAllParam et RestoreParam doivent rester dans le
''' MEME ordre : c'est un Split('|') positionnel.
''' </summary>
Public Class clsExecutorStatus

    ''' <summary>Vrai des qu'une propriete a change depuis le dernier GetAllParam.</summary>
    Public HaveNewStatut As Boolean = True

    Private _Etape As String = "0"
    ''' <summary>Etape courante de la boucle : 0 arret, 1 demarrage, 2 attente, 3 execution.</summary>
    Public Property Etape As String
        Get
            Return _Etape
        End Get
        Set(value As String)
            _Etape = value
            HaveNewStatut = True
        End Set
    End Property

    Private _StatusText As String = "Arrêté"
    ''' <summary>Libelle lisible de ce que fait le service en ce moment.</summary>
    Public Property StatusText As String
        Get
            Return _StatusText
        End Get
        Set(value As String)
            _StatusText = value
            HaveNewStatut = True
        End Set
    End Property

    Private _ThreadStarted As String = "Jamais"
    Public Property ThreadStarted As String
        Get
            Return _ThreadStarted
        End Get
        Set(value As String)
            _ThreadStarted = value
            HaveNewStatut = True
        End Set
    End Property

    Private _LastRun As String = "Jamais"
    ''' <summary>Horodatage du dernier passage complet de la boucle.</summary>
    Public Property LastRun As String
        Get
            Return _LastRun
        End Get
        Set(value As String)
            _LastRun = value
            HaveNewStatut = True
        End Set
    End Property

    Private _LastJob As String = "Jamais"
    ''' <summary>Code de la derniere tache executee.</summary>
    Public Property LastJob As String
        Get
            Return _LastJob
        End Get
        Set(value As String)
            _LastJob = value
            HaveNewStatut = True
        End Set
    End Property

    Private _LastError As String = ""
    Public Property LastError As String
        Get
            Return _LastError
        End Get
        Set(value As String)
            _LastError = value
            HaveNewStatut = True
        End Set
    End Property

    Private _CounterDone As String = "0"
    Public Property CounterDone As String
        Get
            Return _CounterDone
        End Get
        Set(value As String)
            _CounterDone = value
            HaveNewStatut = True
        End Set
    End Property

    Private _CounterError As String = "0"
    Public Property CounterError As String
        Get
            Return _CounterError
        End Get
        Set(value As String)
            _CounterError = value
            HaveNewStatut = True
        End Set
    End Property

    Private _Queue As String = "0"
    ''' <summary>Executions restant a prendre au dernier passage.</summary>
    Public Property Queue As String
        Get
            Return _Queue
        End Get
        Set(value As String)
            _Queue = value
            HaveNewStatut = True
        End Set
    End Property

    Private _AApprouver As String = "0"
    ''' <summary>Occurrences en attente d'une decision de l'utilisateur.</summary>
    Public Property AApprouver As String
        Get
            Return _AApprouver
        End Get
        Set(value As String)
            _AApprouver = value
            HaveNewStatut = True
        End Set
    End Property

    Public Sub Reset()
        _Etape = "0"
        _StatusText = "Arrêté"
        _LastError = ""
        _Queue = "0"
        _AApprouver = "0"
        HaveNewStatut = True
    End Sub

    ''' <summary>
    ''' Serialise l'etat en une ligne. Le separateur '|' ne doit jamais
    ''' apparaitre dans une valeur : les textes libres (statut, erreur, nom de
    ''' tache) sont donc nettoyes ici. Les sauts de ligne aussi, sinon la ligne
    ''' serait coupee en deux a la lecture (StreamReader.ReadLine).
    ''' </summary>
    Public Function GetAllParam() As String
        HaveNewStatut = False

        Dim s As String = ""
        s &= Clean(_Etape) & "|"
        s &= Clean(_StatusText) & "|"
        s &= Clean(_ThreadStarted) & "|"
        s &= Clean(_LastRun) & "|"
        s &= Clean(_LastJob) & "|"
        s &= Clean(_LastError) & "|"
        s &= Clean(_CounterDone) & "|"
        s &= Clean(_CounterError) & "|"
        s &= Clean(_Queue) & "|"
        s &= Clean(_AApprouver)
        Return s
    End Function

    Private Shared Function Clean(value As String) As String
        If value Is Nothing Then Return ""
        Return value.Replace("|", "/").Replace(vbCr, " ").Replace(vbLf, " ")
    End Function

    ''' <summary>Reconstruit l'etat a partir d'une ligne produite par GetAllParam.</summary>
    Public Sub RestoreParam(allParam As String)
        If String.IsNullOrEmpty(allParam) Then Return

        Dim p As String() = allParam.Split("|"c)
        If p.Length < 10 Then Return

        _Etape = p(0)
        _StatusText = p(1)
        _ThreadStarted = p(2)
        _LastRun = p(3)
        _LastJob = p(4)
        _LastError = p(5)
        _CounterDone = p(6)
        _CounterError = p(7)
        _Queue = p(8)
        _AApprouver = p(9)
    End Sub

End Class
