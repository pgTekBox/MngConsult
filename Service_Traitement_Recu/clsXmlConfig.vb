Imports System.IO
Imports System.Xml

''' <summary>
''' Configuration du service, dans configTraitementRecu.xml a cote de
''' l'executable. Meme mecanique que le service SMTP : le fichier est cree avec
''' les valeurs par defaut au premier demarrage, et les valeurs sensibles
''' (chaine de connexion) sont chiffrees par clsEncDec.
'''
''' La cle OpenAI n'est PAS ici : elle est lue en base par s0000GetParameter
''' ('CHATGPT'), exactement comme le fait l'application web.
''' </summary>
Public Class clsXmlConfig

    Public pathofApp As String
    Private fullpathToXMLFile As String = ""
    Private xmlFIleName As String = "configTraitementRecu.xml"

    ''' <summary>Connexion a la base MngConsul (chiffree dans le fichier).</summary>
    Public ConnectionString As String = ""

    ''' <summary>Secondes entre deux passages de la boucle de traitement.</summary>
    Public IntervalSeconds As String = "60"

    ''' <summary>Nombre de recus traites au maximum a chaque passage.</summary>
    Public BatchSize As String = "5"

    ''' <summary>Tentatives avant d'abandonner un recu (evite de payer l'IA en boucle).</summary>
    Public MaxAttempts As String = "3"

    ''' <summary>Duree du verrou pose sur un recu pendant son traitement (secondes).</summary>
    Public LockSeconds As String = "300"

    ''' <summary>"1" = le service traite ; "0" = il tourne mais ne fait rien (mode observation).</summary>
    Public Actif As String = "1"

    ''' <summary>Largeur maximale de l'image envoyee a l'IA (pixels).</summary>
    Public ImageMaxWidth As String = "1024"

    ''' <summary>Qualite JPEG de l'image optimisee (20-95).</summary>
    Public ImageJpegQuality As String = "55"

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

        Me.IntervalSeconds = GetNodeValueString(doc, node_appSettings, "IntervalSeconds", "60")
        Me.BatchSize = GetNodeValueString(doc, node_appSettings, "BatchSize", "5")
        Me.MaxAttempts = GetNodeValueString(doc, node_appSettings, "MaxAttempts", "3")
        Me.LockSeconds = GetNodeValueString(doc, node_appSettings, "LockSeconds", "300")
        Me.Actif = GetNodeValueString(doc, node_appSettings, "Actif", "1")
        Me.ImageMaxWidth = GetNodeValueString(doc, node_appSettings, "ImageMaxWidth", "1024")
        Me.ImageJpegQuality = GetNodeValueString(doc, node_appSettings, "ImageJpegQuality", "55")

        ' Un fichier edite a la main peut contenir n'importe quoi : on retombe
        ' sur des valeurs utilisables plutot que de planter au demarrage.
        If ToInt(Me.IntervalSeconds, 0) < 5 Then Me.IntervalSeconds = "60"
        If ToInt(Me.BatchSize, 0) < 1 Then Me.BatchSize = "5"
        If ToInt(Me.MaxAttempts, 0) < 1 Then Me.MaxAttempts = "3"
        If ToInt(Me.LockSeconds, 0) < 30 Then Me.LockSeconds = "300"
        If ToInt(Me.ImageMaxWidth, 0) < 200 Then Me.ImageMaxWidth = "1024"
        If ToInt(Me.ImageJpegQuality, 0) < 20 Then Me.ImageJpegQuality = "55"
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
        GetNode(doc, node_appSettings, "IntervalSeconds", IntervalSeconds)
        GetNode(doc, node_appSettings, "BatchSize", BatchSize)
        GetNode(doc, node_appSettings, "MaxAttempts", MaxAttempts)
        GetNode(doc, node_appSettings, "LockSeconds", LockSeconds)
        GetNode(doc, node_appSettings, "Actif", Actif)
        GetNode(doc, node_appSettings, "ImageMaxWidth", ImageMaxWidth)
        GetNode(doc, node_appSettings, "ImageJpegQuality", ImageJpegQuality)

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
