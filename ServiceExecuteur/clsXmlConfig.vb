Imports System.IO
Imports System.Xml

''' <summary>
''' Configuration du service, dans configExecuteur.xml a cote de l'executable.
''' Meme mecanique que les autres services 60Sec : le fichier est cree avec les
''' valeurs par defaut au premier demarrage, et les valeurs sensibles (les deux
''' chaines de connexion) sont chiffrees par clsEncDec.
'''
''' Deux bases, parce que l'executeur traverse la frontiere que l'application
''' web traverse deja : MngConsul porte les taches et les donnees metier,
''' MailService porte la file d'envoi (T400Mails) que SrvAI vide.
''' </summary>
Public Class clsXmlConfig

    Public pathofApp As String
    Private fullpathToXMLFile As String = ""
    Private xmlFIleName As String = "configExecuteur.xml"

    ''' <summary>Connexion a la base MngConsul (chiffree dans le fichier).</summary>
    Public ConnectionString As String = ""

    ''' <summary>Connexion a la base MailService, pour deposer les courriels (chiffree).</summary>
    Public ConnectionStringMail As String = ""

    ''' <summary>Secondes entre deux passages de la boucle d'execution.</summary>
    Public IntervalSeconds As String = "60"

    ''' <summary>Nombre de taches executees au maximum a chaque passage.</summary>
    Public BatchSize As String = "5"

    ''' <summary>Duree du verrou pose sur une execution pendant son traitement (secondes).</summary>
    Public LockSeconds As String = "900"

    ''' <summary>"1" = le service execute ; "0" = il tourne mais ne fait rien (mode observation).</summary>
    Public Actif As String = "1"

    ''' <summary>Adresse d'expedition des courriels deposes dans T400Mails.</summary>
    Public MailSender As String = "noreply@60sec.ca"

    ''' <summary>Rappel preventif : jours AVANT l'echeance ou l'on relance deja (0 = jamais).</summary>
    Public RelanceJoursAvant As String = "0"

    ''' <summary>Jusqu'a combien de jours APRES l'echeance on continue de relancer.</summary>
    Public RelanceJoursApres As String = "30"

    Sub New()
        pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)
        fullpathToXMLFile = pathofApp & "\" & xmlFIleName

        If Not File.Exists(fullpathToXMLFile) Then
            saveAll()
        End If

        Dim doc As New XmlDocument()
        doc.Load(fullpathToXMLFile)

        Dim node_configuration As XmlNode = GetNode(doc, Nothing, "configuration")
        Dim node_appSettings As XmlNode = GetNode(doc, node_configuration, "appSettings")

        Me.ConnectionString = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "ConnectionString", ""))
        Me.ConnectionStringMail = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "ConnectionStringMail", ""))

        Me.IntervalSeconds = GetNodeValueString(doc, node_appSettings, "IntervalSeconds", "60")
        Me.BatchSize = GetNodeValueString(doc, node_appSettings, "BatchSize", "5")
        Me.LockSeconds = GetNodeValueString(doc, node_appSettings, "LockSeconds", "900")
        Me.Actif = GetNodeValueString(doc, node_appSettings, "Actif", "1")
        Me.MailSender = GetNodeValueString(doc, node_appSettings, "MailSender", "noreply@60sec.ca")
        Me.RelanceJoursAvant = GetNodeValueString(doc, node_appSettings, "RelanceJoursAvant", "0")
        Me.RelanceJoursApres = GetNodeValueString(doc, node_appSettings, "RelanceJoursApres", "30")

        ' Un fichier edite a la main peut contenir n'importe quoi : on retombe
        ' sur des valeurs utilisables plutot que de planter au demarrage.
        If ToInt(Me.IntervalSeconds, 0) < 5 Then Me.IntervalSeconds = "60"
        If ToInt(Me.BatchSize, 0) < 1 Then Me.BatchSize = "5"
        If ToInt(Me.LockSeconds, 0) < 30 Then Me.LockSeconds = "900"
        If ToInt(Me.RelanceJoursAvant, -1) < 0 Then Me.RelanceJoursAvant = "0"
        If ToInt(Me.RelanceJoursApres, 0) < 1 Then Me.RelanceJoursApres = "30"
        If String.IsNullOrWhiteSpace(Me.MailSender) Then Me.MailSender = "noreply@60sec.ca"
    End Sub

    Public Shared Function ToInt(value As String, fallback As Integer) As Integer
        Dim n As Integer
        If Integer.TryParse(value, n) Then Return n
        Return fallback
    End Function

    Public Sub saveAll()
        pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)
        fullpathToXMLFile = pathofApp & "\" & xmlFIleName

        Dim doc As New XmlDocument()
        If Not File.Exists(fullpathToXMLFile) Then
            doc.AppendChild(doc.CreateXmlDeclaration("1.0", "UTF-8", Nothing))
        Else
            doc.Load(fullpathToXMLFile)
        End If

        Dim node_configuration As XmlNode = GetNode(doc, Nothing, "configuration")
        Dim node_appSettings As XmlNode = GetNode(doc, node_configuration, "appSettings")

        GetNode(doc, node_appSettings, "ConnectionString", clsEncDec.Encrypt(ConnectionString))
        GetNode(doc, node_appSettings, "ConnectionStringMail", clsEncDec.Encrypt(ConnectionStringMail))
        GetNode(doc, node_appSettings, "IntervalSeconds", IntervalSeconds)
        GetNode(doc, node_appSettings, "BatchSize", BatchSize)
        GetNode(doc, node_appSettings, "LockSeconds", LockSeconds)
        GetNode(doc, node_appSettings, "Actif", Actif)
        GetNode(doc, node_appSettings, "MailSender", MailSender)
        GetNode(doc, node_appSettings, "RelanceJoursAvant", RelanceJoursAvant)
        GetNode(doc, node_appSettings, "RelanceJoursApres", RelanceJoursApres)

        doc.Save(fullpathToXMLFile)
    End Sub

#Region "Acces XML"

    Private Function GetNode(theDoc As XmlDocument, nodeParent As XmlNode, nodeName As String) As XmlNode
        Dim myNode As XmlNode
        If nodeParent Is Nothing Then
            myNode = theDoc.SelectSingleNode(nodeName)
            If myNode Is Nothing Then
                myNode = theDoc.CreateElement(nodeName)
                theDoc.AppendChild(myNode)
            End If
        Else
            myNode = nodeParent.SelectSingleNode(nodeName)
            If myNode Is Nothing Then
                myNode = theDoc.CreateElement(nodeName)
                nodeParent.AppendChild(myNode)
            End If
        End If
        Return myNode
    End Function

    Private Function GetNode(theDoc As XmlDocument, nodeParent As XmlNode, nodeName As String, value As String) As XmlNode
        Dim myNode As XmlNode = GetNode(theDoc, nodeParent, nodeName)
        SaveAttribute(theDoc, myNode, "value", If(value, ""))
        Return myNode
    End Function

    Private Sub SaveAttribute(theDoc As XmlDocument, onode As XmlNode, attributeName As String, attributeValue As String)
        If onode.Attributes(attributeName) Is Nothing Then
            Dim att As XmlAttribute = theDoc.CreateAttribute(attributeName)
            att.Value = attributeValue
            onode.Attributes.Append(att)
        Else
            onode.Attributes(attributeName).Value = attributeValue
        End If
    End Sub

    Private Function GetNodeValueString(theDoc As XmlDocument, nodeParent As XmlNode, nodeName As String, defaultValue As String) As String
        Try
            Dim myNode As XmlNode = GetNode(theDoc, nodeParent, nodeName)
            If myNode Is Nothing OrElse myNode.Attributes("value") Is Nothing Then Return defaultValue
            Dim retval As String = myNode.Attributes("value").Value
            If retval Is Nothing Then Return defaultValue
            Return retval
        Catch
            Return defaultValue
        End Try
    End Function

#End Region

End Class
