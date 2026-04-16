Imports System.Collections.Specialized
Imports System.Xml.XmlLinkedNode
Imports System.IO

Imports System.Xml


Public Class clsXmlConfig



    Public pathofApp As String
    Public pathofErrorFile As String
    Private fullpathToXMLFile As String = ""

    Private xmlFIleName As String = "configSMTPServer.xml"


    Public ConnectionString As String = ""
    Public SocketPort As String = ""
    Public IpAdresse As String = ""
    Public UseDatabase As String = "1"

    Public Domaines As DataTable


    Sub New()

        pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)
        pathofErrorFile = pathofApp + "\\logApp.txt"
        fullpathToXMLFile = pathofApp + "\\" + xmlFIleName

        If Not System.IO.File.Exists(fullpathToXMLFile) Then
            saveAll()
        End If

        Dim doc As New System.Xml.XmlDocument()

        doc.Load(fullpathToXMLFile)

        Dim node_configuration As XmlNode = GetNode(doc, Nothing, "configuration")
        Dim node_appSettings As XmlNode = GetNode(doc, node_configuration, "appSettings")



        Me.ConnectionString = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "ConnectionString", ""))
        Me.SocketPort = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "SocketPort", ""))
        Me.IpAdresse = clsEncDec.Decrypt(GetNodeValueString(doc, node_appSettings, "IpAdresse", ""))
        Me.UseDatabase = GetNodeValueString(doc, node_appSettings, "UseDatabase", "1")

        Domaines = GetNewDataTableDomaine()

        Dim node_Domaines As XmlNode = GetNode(doc, node_appSettings, "Domaines")

        Dim sDomaine As String = ""
        Dim sUseUndefinedUser As String = ""


        For Each oNode As XmlNode In node_Domaines.ChildNodes
            sDomaine = oNode.Attributes("value").Value
            sUseUndefinedUser = oNode.Attributes("useundefineduser").Value
            SaveDomaine(sDomaine, sUseUndefinedUser)
        Next






    End Sub
    Public Sub SaveDomaine(Domainename As String, UseUndefinedUser As Boolean)


        For Each oRow As DataRow In Domaines.Rows
            If oRow("DomaineName").ToLower = Domainename.ToLower Then

                Return
            End If

        Next


        Dim Newrow As DataRow = Domaines.NewRow
        Newrow("DomaineName") = Domainename
        If UseUndefinedUser Then
            Newrow("UseUndefinedUser") = UseUndefinedUser
        Else
            Newrow("UseUndefinedUser") = UseUndefinedUser
        End If

        Domaines.Rows.Add(Newrow)
        Domaines.AcceptChanges()

    End Sub
    Public Sub SaveDomaine(Domainename As String, UseUndefinedUser As String)
        For Each oRow As DataRow In Domaines.Rows
            If oRow("DomaineName").ToLower = Domainename.ToLower Then
                Return
            End If

        Next


        Dim Newrow As DataRow = Domaines.NewRow
        Newrow("DomaineName") = Domainename
        If UseUndefinedUser = "1" Then
            Newrow("UseUndefinedUser") = True
        Else
            Newrow("UseUndefinedUser") = False
        End If

        Domaines.Rows.Add(Newrow)
        Domaines.AcceptChanges()

    End Sub

    Public Sub RemoveDomaine(Domainename As String)

        For Each oRow As DataRow In Domaines.Rows
            If oRow("DomaineName").ToLower = Domainename.ToLower Then
                Domaines.Rows.Remove(oRow)
                Domaines.AcceptChanges()
                Return
            End If

        Next





    End Sub

    Public Function GetNewDataTableDomaine() As DataTable
        Dim table As New DataTable
        table.TableName = "Domaines"
        '' Create four typed columns in the DataTable.
        table.Columns.Add("DomaineName", GetType(String))
        table.Columns.Add("UseUndefinedUser", GetType(Boolean))
        Return table
    End Function


    Function GetNode(Thedoc As XmlDocument, NodeParent As XmlNode, NodeName As String, value As String) As XmlNode
        Dim MyNode As XmlNode = NodeParent.SelectSingleNode(NodeName)
        If MyNode Is Nothing Then
            MyNode = Thedoc.CreateElement(NodeName)
            If NodeParent Is Nothing Then
                Thedoc.AppendChild(MyNode)
            Else
                NodeParent.AppendChild(MyNode)
            End If
        End If
        If value Is Nothing Then
            SaveAttribute(Thedoc, MyNode, "value", "")
        Else
            SaveAttribute(Thedoc, MyNode, "value", value)
        End If

        Return MyNode
    End Function

    Private Function iCheckBool(iVal As Integer) As Boolean
        If iVal = 1 Then
            Return True
        Else
            Return False
        End If
    End Function

    Private Function CheckBool(sVal As String) As Boolean
        If sVal.ToUpper.Trim = "TRUE" Then
            Return True
        Else
            Return False
        End If
    End Function

    Private Function CheckInt(sVal As String) As Boolean
        Try


            If sVal.ToUpper.Trim = "" Then
                Return 0
            Else
                Return sVal
            End If
        Catch ex As Exception
            Return 0
        End Try
    End Function

    Private Function ReadXMl(sNode As String) As String
        Dim XmlValue As String = ""
        Dim doc As XDocument = XDocument.Load(xmlFIleName)
        XmlValue = doc.Element("appSettings").Element(sNode).Value

        ReadXMl = XmlValue.Trim
    End Function

    Public Function GetXmlAttributeValue(xmlElement As String, xmlAttribute As String, Optional isOnlyFrist As Boolean = False)
        Dim DataXmlQueryGetAttribute
        Dim osource = XDocument.Load(fullpathToXMLFile).Descendants(xmlElement)



        If isOnlyFrist Then
            DataXmlQueryGetAttribute = (From datafromXml In osource
                                        Select datafromXml.Attribute(xmlAttribute).Value).First()

        Else
            DataXmlQueryGetAttribute = (From datafromXml In osource
                                        Select datafromXml.Attribute(xmlAttribute).Value).ToArray()
        End If

        GetXmlAttributeValue = DataXmlQueryGetAttribute

    End Function
    Sub SaveAttribute(Thedoc As XmlDocument, onode As XmlNode, AttributeName As String, AttirbuteValue As String)
        If onode.Attributes(AttributeName) Is Nothing Then
            Dim att As XmlAttribute = Thedoc.CreateAttribute(AttributeName)
            att.Value = AttirbuteValue
            onode.Attributes.Append(att)
        Else
            onode.Attributes(AttributeName).Value = AttirbuteValue
        End If
    End Sub

    Function GetNodeValueInt(Thedoc As XmlDocument, NodeParent As XmlNode, NodeName As String, DefaultValue As Integer) As Integer
        Try


            Dim MyNode As XmlNode = GetNode(Thedoc, NodeParent, NodeName)
            Dim retval As String = MyNode.Attributes("value").Value



            If retval Is Nothing Then
                Return DefaultValue
            Else
                Return retval
            End If
        Catch ex As Exception
            Return 0
        End Try

    End Function
    Function GetNodeValueBool(Thedoc As XmlDocument, NodeParent As XmlNode, NodeName As String, DefaultValue As Boolean) As Boolean
        Try


            Dim MyNode As XmlNode = GetNode(Thedoc, NodeParent, NodeName)
            Dim retval As String = MyNode.Attributes("value").Value
            If retval Is Nothing Then
                Return DefaultValue
            Else
                Return CheckBool(retval)
            End If
        Catch ex As Exception
            Return False
        End Try

    End Function

    Function GetNodeValueString(Thedoc As XmlDocument, NodeParent As XmlNode, NodeName As String, DefaultValue As String) As String
        Try


            Dim MyNode As XmlNode = GetNode(Thedoc, NodeParent, NodeName)
            Dim retval As String = MyNode.Attributes("value").Value
            If retval Is Nothing Then
                Return DefaultValue
            Else
                Return retval
            End If
        Catch ex As Exception
            Return ""
        End Try

    End Function
    Function GetNode(Thedoc As XmlDocument, NodeParent As XmlNode, NodeName As String) As XmlNode
        Dim MyNode As XmlNode
        If NodeParent Is Nothing Then
            MyNode = Thedoc.SelectSingleNode(NodeName)
            If MyNode Is Nothing Then
                MyNode = Thedoc.CreateElement(NodeName)
                If NodeParent Is Nothing Then
                    Thedoc.AppendChild(MyNode)
                Else
                    NodeParent.AppendChild(MyNode)
                End If
            End If
        Else
            MyNode = NodeParent.SelectSingleNode(NodeName)
            If MyNode Is Nothing Then
                MyNode = Thedoc.CreateElement(NodeName)
                If NodeParent Is Nothing Then
                    Thedoc.AppendChild(MyNode)
                Else
                    NodeParent.AppendChild(MyNode)
                End If
            End If
        End If





        Return MyNode
    End Function


    Public Sub saveAll()
        pathofApp = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)

        fullpathToXMLFile = pathofApp + "\\" + xmlFIleName

        Dim doc As New System.Xml.XmlDocument()
        If Not System.IO.File.Exists(fullpathToXMLFile) Then
            doc.AppendChild(doc.CreateXmlDeclaration("1.0", "UTF-8", Nothing))
        Else
            doc.Load(fullpathToXMLFile)
        End If

        Dim node_configuration As XmlNode = GetNode(doc, Nothing, "configuration")
        Dim node_appSettings As XmlNode = GetNode(doc, node_configuration, "appSettings")

        Dim node_ConnectionString As XmlNode = GetNode(doc, node_appSettings, "ConnectionString", clsEncDec.Encrypt(ConnectionString))
        Dim node_SocketPort As XmlNode = GetNode(doc, node_appSettings, "SocketPort", clsEncDec.Encrypt(SocketPort))
        Dim node_IpAdresse As XmlNode = GetNode(doc, node_appSettings, "IpAdresse", clsEncDec.Encrypt(IpAdresse))

        Dim node_UseDatabase As XmlNode = GetNode(doc, node_appSettings, "UseDatabase", UseDatabase)

        Dim node_Domaines As XmlNode = GetNode(doc, node_appSettings, "Domaines")
        node_Domaines.RemoveAll()

        For Each oRow As DataRow In Domaines.Rows
            Dim sDomaine As String = oRow("DomaineName")
            Dim bUseUndefinedUser As Boolean = oRow("UseUndefinedUser")
            Dim MyNode As XmlNode = doc.CreateNode(XmlNodeType.Element, "Domaine", "")
            SaveAttribute(doc, MyNode, "value", sDomaine)
            If bUseUndefinedUser Then
                SaveAttribute(doc, MyNode, "useundefineduser", "1")
            Else
                SaveAttribute(doc, MyNode, "useundefineduser", "0")
            End If

            node_Domaines.AppendChild(MyNode)
        Next

        doc.Save(fullpathToXMLFile)




    End Sub

End Class
