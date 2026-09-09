Imports System.IO
Imports System.Xml

''' <summary>
''' Configuration du service, dans configExecuteur.xml a cote de l'executable.
''' Meme mecanique que les autres services 60Sec : le fichier est cree avec les
''' valeurs par defaut au premier demarrage, et les valeurs sensibles (chaine de
''' connexion et cle partagee) sont chiffrees par clsEncDec.
'''
''' Rien ici ne decrit ce que font les taches : le service ne le sait pas. Il
''' lui faut seulement de quoi lire la file (MngConsul) et de quoi joindre la
''' console d'administration, qui execute.
''' </summary>
Public Class clsXmlConfig

    Public pathofApp As String
    Private fullpathToXMLFile As String = ""
    Private xmlFIleName As String = "configExecuteur.xml"

    ''' <summary>Connexion a la base MngConsul (chiffree dans le fichier).</summary>
    Public ConnectionString As String = ""

    ''' <summary>
    ''' Adresse de la console d'administration, par exemple
    ''' http://alfred/60secadmin. C'est elle qui execute les taches : le service
    ''' ne fait que lui passer la main.
    ''' </summary>
    Public AdminBaseUrl As String = ""

    ''' <summary>
    ''' Cle partagee avec JobRunner.ashx (parametre JobRunnerKey de son
    ''' Web.config). Le service n'a pas de session : c'est elle qui
    ''' l'authentifie. Chiffree dans le fichier.
    ''' </summary>
    Public AdminApiKey As String = ""

    ''' <summary>Secondes entre deux passages de la boucle d'execution.</summary>
    Public IntervalSeconds As String = "60"

    ''' <summary>Nombre de taches executees au maximum a chaque passage.</summary>
    Public BatchSize As String = "5"

    ''' <summary>Duree du verrou pose sur une execution pendant son traitement (secondes).</summary>
    Public LockSeconds As String = "900"

    ''' <summary>"1" = le service execute ; "0" = il tourne mais ne fait rien (mode observation).</summary>
    Public Actif As String = "1"

    ' L'expediteur des courriels et la fenetre de relance ont demenage cote
    ' console : ce sont des particularites de tache, elles se reglent dans les
    ' parametres de la tache ou dans le Web.config de 60secadmin. Le service ne
    ' connait plus rien du contenu de ce qu'il declenche.

    ''' <summary>
    ''' Minutes entre deux regarnissages du planning (sp_GenererPlanningJobs).
    ''' 0 = jamais : a mettre si le planning est genere ailleurs.
    ''' </summary>
    Public PlanningRefreshMinutes As String = "15"

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
        Me.AdminBaseUrl = GetNodeValueString(doc, node_appSettings, "AdminBaseUrl", "")
        Me.AdminApiKey = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "AdminApiKey", ""))

        Me.IntervalSeconds = GetNodeValueString(doc, node_appSettings, "IntervalSeconds", "60")
        Me.BatchSize = GetNodeValueString(doc, node_appSettings, "BatchSize", "5")
        Me.LockSeconds = GetNodeValueString(doc, node_appSettings, "LockSeconds", "900")
        Me.Actif = GetNodeValueString(doc, node_appSettings, "Actif", "1")
        Me.PlanningRefreshMinutes = GetNodeValueString(doc, node_appSettings, "PlanningRefreshMinutes", "15")

        ' Un fichier edite a la main peut contenir n'importe quoi : on retombe
        ' sur des valeurs utilisables plutot que de planter au demarrage.
        If ToInt(Me.IntervalSeconds, 0) < 5 Then Me.IntervalSeconds = "60"
        If ToInt(Me.BatchSize, 0) < 1 Then Me.BatchSize = "5"
        If ToInt(Me.LockSeconds, 0) < 30 Then Me.LockSeconds = "900"
        If ToInt(Me.PlanningRefreshMinutes, -1) < 0 Then Me.PlanningRefreshMinutes = "15"
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
        GetNode(doc, node_appSettings, "AdminBaseUrl", AdminBaseUrl)
        GetNode(doc, node_appSettings, "AdminApiKey", clsEncDec.Encrypt(AdminApiKey))
        GetNode(doc, node_appSettings, "IntervalSeconds", IntervalSeconds)
        GetNode(doc, node_appSettings, "BatchSize", BatchSize)
        GetNode(doc, node_appSettings, "LockSeconds", LockSeconds)
        GetNode(doc, node_appSettings, "Actif", Actif)
        GetNode(doc, node_appSettings, "PlanningRefreshMinutes", PlanningRefreshMinutes)

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
