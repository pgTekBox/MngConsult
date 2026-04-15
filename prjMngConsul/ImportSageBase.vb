Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web.UI
Imports System.Web.UI.WebControls

''' <summary>
''' Classe de base pour toutes les pages d'import CSV Sage 50 → staging.
''' Chaque page hérite de cette classe et définit ses colonnes et sa table cible.
''' </summary>
Public MustInherit Class ImportSageBase
    Inherits clsData

    ' ──────────────────────────────────────────────
    '  Propriétés abstraites — à définir par chaque page
    ' ──────────────────────────────────────────────

    ''' <summary>Nom de la table staging cible (ex: "staging.SageComptes")</summary>
    Protected MustOverride ReadOnly Property StagingTableName As String

    ''' <summary>Titre affiché dans la page</summary>
    Protected MustOverride ReadOnly Property PageTitle As String

    ''' <summary>Sous-titre affiché dans la page</summary>
    Protected MustOverride ReadOnly Property PageSubTitle As String

    ''' <summary>Icône emoji de la page</summary>
    Protected MustOverride ReadOnly Property PageIcon As String

    ''' <summary>Instructions d'export Sage 50</summary>
    Protected MustOverride ReadOnly Property SageExportPath As String

    ''' <summary>
    ''' Définition des colonnes : clé = nom interne du champ,
    ''' valeur = ColumnDef avec les métadonnées
    ''' </summary>
    Protected MustOverride ReadOnly Property ColumnDefinitions As List(Of ColumnDef)

    ' ──────────────────────────────────────────────
    '  Contrôles — doivent exister dans chaque .aspx
    ' ──────────────────────────────────────────────

    Protected MustOverride ReadOnly Property FileUploadControl As FileUpload
    Protected MustOverride ReadOnly Property SeparatorDropDown As DropDownList
    Protected MustOverride ReadOnly Property EncodingDropDown As DropDownList
    Protected MustOverride ReadOnly Property HasHeaderCheckBox As CheckBox
    Protected MustOverride ReadOnly Property TruncateCheckBox As CheckBox

    Protected MustOverride ReadOnly Property PreviewGrid As GridView
    Protected MustOverride ReadOnly Property PreviewInfoLiteral As Literal
    Protected MustOverride ReadOnly Property PreviewPanel As Panel

    Protected MustOverride ReadOnly Property SuccessPanel As Panel
    Protected MustOverride ReadOnly Property ErrorPanel As Panel
    Protected MustOverride ReadOnly Property WarningPanel As Panel
    Protected MustOverride ReadOnly Property SuccessLiteral As Literal
    Protected MustOverride ReadOnly Property ErrorLiteral As Literal
    Protected MustOverride ReadOnly Property WarningLiteral As Literal

    Protected MustOverride ReadOnly Property ResultsPanel As Panel
    Protected MustOverride ReadOnly Property InsertedLiteral As Literal
    Protected MustOverride ReadOnly Property SkippedLiteral As Literal
    Protected MustOverride ReadOnly Property ErrorsLiteral As Literal
    Protected MustOverride ReadOnly Property ErrorDetailsPanel As Panel
    Protected MustOverride ReadOnly Property ErrorsGrid As GridView

    ' ──────────────────────────────────────────────
    '  Connexion DB
    ' ──────────────────────────────────────────────


#Region "Public Methods — appelées par les boutons des pages"

    ''' <summary>Aperçu des 10 premières lignes</summary>
    Public Sub DoPreview()
        HideMessages()
        If Not FileUploadControl.HasFile Then ShowError("Veuillez sélectionner un fichier CSV.") : Return
        If Not ValidateFile() Then Return

        Try
            Dim lines = ReadCsvLines(11)
            If lines.Count = 0 Then ShowError("Le fichier est vide.") : Return

            Dim dt = ParseCsvToDataTable(lines, 10)
            PreviewGrid.DataSource = dt
            PreviewGrid.DataBind()

            Dim totalLines = CountTotalLines()
            Dim dataLines = If(HasHeaderCheckBox.Checked, totalLines - 1, totalLines)
            PreviewInfoLiteral.Text = $"Affichage de {Math.Min(10, dt.Rows.Count)} lignes sur {dataLines} ({dt.Columns.Count} colonnes détectées)"
            PreviewPanel.Visible = True
        Catch ex As Exception
            ShowError($"Erreur lors de la lecture : {ex.Message}")
        End Try
    End Sub

    ''' <summary>Importer le CSV dans la table staging</summary>
    Public Sub DoImport()
        HideMessages()
        If Not FileUploadControl.HasFile Then ShowError("Veuillez sélectionner un fichier CSV.") : Return
        If Not ValidateFile() Then Return

        Try
            Dim lines = ReadCsvLines()
            If lines.Count = 0 Then ShowError("Le fichier est vide.") : Return

            Dim dt = ParseCsvToDataTable(lines)
            Dim result = ImportToDatabase(dt)

            InsertedLiteral.Text = result.Inserted.ToString()
            SkippedLiteral.Text = result.Skipped.ToString()
            ErrorsLiteral.Text = result.Errors.Count.ToString()

            If result.Errors.Count > 0 Then
                Dim errorDt As New DataTable()
                errorDt.Columns.Add("Ligne", GetType(Integer))
                errorDt.Columns.Add("Données", GetType(String))
                errorDt.Columns.Add("Erreur", GetType(String))
                For Each errs In result.Errors.Take(50)
                    errorDt.Rows.Add(errs.LineNumber, errs.KeyValue, errs.Message)
                Next
                ErrorsGrid.DataSource = errorDt
                ErrorsGrid.DataBind()
                ErrorDetailsPanel.Visible = True
            End If

            ResultsPanel.Visible = True

            If result.Errors.Count = 0 Then
                ShowSuccess($"{result.Inserted} lignes importées avec succès dans {StagingTableName}.")
            ElseIf result.Inserted > 0 Then
                ShowWarning($"{result.Inserted} lignes importées, mais {result.Errors.Count} erreur(s).")
            Else
                ShowError($"Aucune ligne importée. {result.Errors.Count} erreur(s).")
            End If
        Catch ex As Exception
            ShowError($"Erreur lors de l'importation : {ex.Message}")
        End Try
    End Sub

    ''' <summary>Réinitialiser pour un nouvel import</summary>
    Public Sub DoReset()
        ResultsPanel.Visible = False
        PreviewPanel.Visible = False
        ErrorDetailsPanel.Visible = False
        HideMessages()
    End Sub

    ''' <summary>Vider la table staging</summary>
    Public Sub DoTruncate()
        HideMessages()
        Try
            Using conn As New SqlConnection(ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand($"TRUNCATE TABLE {StagingTableName}", conn)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            ShowSuccess($"La table {StagingTableName} a été vidée.")
        Catch ex As Exception
            ShowError($"Erreur lors du vidage : {ex.Message}")
        End Try
    End Sub

#End Region

#Region "CSV Parsing"

    Private Function ReadCsvLines(Optional maxLines As Integer = 0) As List(Of String)
        Dim enc = GetSelectedEncoding()
        Dim lines As New List(Of String)

        Using reader As New StreamReader(FileUploadControl.FileContent, enc)
            Dim line As String = reader.ReadLine()
            Dim count As Integer = 0
            While line IsNot Nothing
                If Not String.IsNullOrWhiteSpace(line) Then
                    lines.Add(line)
                    count += 1
                    If maxLines > 0 AndAlso count >= maxLines Then Exit While
                End If
                line = reader.ReadLine()
            End While
        End Using
        Return lines
    End Function

    Private Function CountTotalLines() As Integer
        Dim enc = GetSelectedEncoding()
        Dim count As Integer = 0
        FileUploadControl.FileContent.Position = 0
        Using reader As New StreamReader(FileUploadControl.FileContent, enc)
            Dim line As String = reader.ReadLine()
            While line IsNot Nothing
                If Not String.IsNullOrWhiteSpace(line) Then count += 1
                line = reader.ReadLine()
            End While
        End Using
        FileUploadControl.FileContent.Position = 0
        Return count
    End Function

    Private Function ParseCsvToDataTable(lines As List(Of String), Optional maxRows As Integer = 0) As DataTable
        Dim dt As New DataTable()
        Dim separator = GetSelectedSeparator()
        If lines.Count = 0 Then Return dt

        Dim startIndex As Integer = 0
        Dim firstLine = ParseCsvLine(lines(0), separator)

        If HasHeaderCheckBox.Checked Then
            For Each col In firstLine
                Dim colName = col.Trim()
                If String.IsNullOrEmpty(colName) Then colName = $"Colonne_{dt.Columns.Count + 1}"
                Dim originalName = colName
                Dim suffix = 1
                While dt.Columns.Contains(colName)
                    colName = $"{originalName}_{suffix}"
                    suffix += 1
                End While
                dt.Columns.Add(colName)
            Next
            startIndex = 1
        Else
            For i = 0 To firstLine.Length - 1
                dt.Columns.Add($"Colonne_{i + 1}")
            Next
        End If

        Dim rowCount As Integer = 0
        For i = startIndex To lines.Count - 1
            Dim values = ParseCsvLine(lines(i), separator)
            Dim row = dt.NewRow()
            For j = 0 To Math.Min(values.Length, dt.Columns.Count) - 1
                row(j) = values(j).Trim()
            Next
            dt.Rows.Add(row)
            rowCount += 1
            If maxRows > 0 AndAlso rowCount >= maxRows Then Exit For
        Next
        Return dt
    End Function

    Private Function ParseCsvLine(line As String, separator As Char) As String()
        Dim fields As New List(Of String)
        Dim inQuotes As Boolean = False
        Dim current As New StringBuilder()
        Dim i As Integer = 0
        While i < line.Length
            Dim c = line(i)
            If inQuotes Then
                If c = """"c Then
                    If i + 1 < line.Length AndAlso line(i + 1) = """"c Then
                        current.Append(""""c) : i += 1
                    Else
                        inQuotes = False
                    End If
                Else
                    current.Append(c)
                End If
            Else
                If c = """"c Then
                    inQuotes = True
                ElseIf c = separator Then
                    fields.Add(current.ToString()) : current.Clear()
                Else
                    current.Append(c)
                End If
            End If
            i += 1
        End While
        fields.Add(current.ToString())
        Return fields.ToArray()
    End Function

#End Region

#Region "Database Import"

    Private Function ImportToDatabase(dt As DataTable) As ImportResult
        Dim result As New ImportResult()
        Dim columnMap = DetectColumnMapping(dt)
        Dim cols = ColumnDefinitions

        Using conn As New SqlConnection(ConnectionString)
            conn.Open()

            If TruncateCheckBox.Checked Then
                Using truncCmd As New SqlCommand($"TRUNCATE TABLE {StagingTableName}", conn)
                    truncCmd.ExecuteNonQuery()
                End Using
            End If

            ' Construire dynamiquement le SQL INSERT
            Dim colNames = String.Join(", ", cols.Select(Function(c) c.DbColumnName))
            Dim paramNames = String.Join(", ", cols.Select(Function(c) "@" & c.FieldName))
            Dim insertSql = $"INSERT INTO {StagingTableName} ({colNames}) VALUES ({paramNames})"

            Using cmd As New SqlCommand(insertSql, conn)
                ' Ajouter les paramètres
                For Each col In cols
                    cmd.Parameters.Add("@" & col.FieldName, col.SqlType, col.MaxLength)
                Next

                For i = 0 To dt.Rows.Count - 1
                    Dim row = dt.Rows(i)
                    Dim lineNumber = If(HasHeaderCheckBox.Checked, i + 2, i + 1)

                    Try
                        ' Obtenir la valeur de la première colonne pour le log d'erreurs
                        Dim keyValue = GetMappedValue(row, columnMap, cols(0).FieldName)

                        ' Vérifier le champ requis (première colonne)
                        If cols(0).IsRequired AndAlso String.IsNullOrWhiteSpace(keyValue) Then
                            result.Skipped += 1
                            Continue For
                        End If

                        ' Remplir les paramètres
                        For Each col In cols
                            Dim rawValue = GetMappedValue(row, columnMap, col.FieldName)

                            If col.SqlType = SqlDbType.Decimal Then
                                Dim decVal As Decimal = 0
                                If Not String.IsNullOrWhiteSpace(rawValue) Then
                                    rawValue = rawValue.Replace("$", "").Replace(" ", "").Replace(",", ".").Trim()
                                    If rawValue.StartsWith("(") AndAlso rawValue.EndsWith(")") Then
                                        rawValue = "-" & rawValue.Trim("("c, ")"c)
                                    End If
                                    If Not Decimal.TryParse(rawValue,
                                        Globalization.NumberStyles.Any,
                                        Globalization.CultureInfo.InvariantCulture, decVal) Then
                                        result.Errors.Add(New ImportError With {
                                            .LineNumber = lineNumber, .KeyValue = keyValue,
                                            .Message = $"Valeur numérique invalide pour {col.DbColumnName} : '{rawValue}'"
                                        })
                                        GoTo NextRow
                                    End If
                                End If
                                cmd.Parameters("@" & col.FieldName).Value = decVal

                            ElseIf col.SqlType = SqlDbType.Date OrElse col.SqlType = SqlDbType.DateTime Then
                                If String.IsNullOrWhiteSpace(rawValue) Then
                                    cmd.Parameters("@" & col.FieldName).Value = DBNull.Value
                                Else
                                    Dim dtVal As Date
                                    If Date.TryParse(rawValue, dtVal) Then
                                        cmd.Parameters("@" & col.FieldName).Value = dtVal
                                    Else
                                        result.Errors.Add(New ImportError With {
                                            .LineNumber = lineNumber, .KeyValue = keyValue,
                                            .Message = $"Date invalide pour {col.DbColumnName} : '{rawValue}'"
                                        })
                                        GoTo NextRow
                                    End If
                                End If
                            Else
                                ' VARCHAR
                                If String.IsNullOrEmpty(rawValue) Then
                                    cmd.Parameters("@" & col.FieldName).Value = DBNull.Value
                                Else
                                    ' Appliquer le normalizer si défini
                                    If col.Normalizer IsNot Nothing Then rawValue = col.Normalizer(rawValue)
                                    rawValue = Truncate(rawValue, col.MaxLength)
                                    cmd.Parameters("@" & col.FieldName).Value = rawValue
                                End If
                            End If
                        Next

                        cmd.ExecuteNonQuery()
                        result.Inserted += 1

                    Catch sqlEx As SqlException
                        result.Errors.Add(New ImportError With {
                            .LineNumber = lineNumber,
                            .KeyValue = GetMappedValue(row, columnMap, cols(0).FieldName),
                            .Message = $"SQL : {sqlEx.Message}"
                        })
                    Catch ex As Exception
                        result.Errors.Add(New ImportError With {
                            .LineNumber = lineNumber,
                            .KeyValue = GetMappedValue(row, columnMap, cols(0).FieldName),
                            .Message = ex.Message
                        })
                    End Try
NextRow:
                Next
            End Using
        End Using
        Return result
    End Function

    Private Function DetectColumnMapping(dt As DataTable) As Dictionary(Of String, Integer)
        Dim map As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)
        Dim cols = ColumnDefinitions

        ' Essayer par nom d'en-tête
        For i = 0 To dt.Columns.Count - 1
            Dim colName = dt.Columns(i).ColumnName.ToLower().Trim()
            For Each col In cols
                If map.ContainsKey(col.FieldName) Then Continue For
                For Each kw In col.DetectKeywords
                    If colName.Contains(kw.ToLower()) OrElse colName = kw.ToLower() Then
                        map(col.FieldName) = i
                        Exit For
                    End If
                Next
            Next
        Next

        ' Fallback par position
        If map.Count < Math.Min(3, cols.Count) Then
            map.Clear()
            For i = 0 To Math.Min(cols.Count, dt.Columns.Count) - 1
                map(cols(i).FieldName) = i
            Next
        End If

        Return map
    End Function

    Private Function GetMappedValue(row As DataRow, map As Dictionary(Of String, Integer), fieldName As String) As String
        If Not map.ContainsKey(fieldName) Then Return Nothing
        Dim colIndex = map(fieldName)
        If colIndex >= row.Table.Columns.Count Then Return Nothing
        Dim value = row(colIndex)
        If IsDBNull(value) Then Return Nothing
        Return value.ToString().Trim()
    End Function

#End Region

#Region "Helpers"

    Private Function Truncate(value As String, maxLength As Integer) As String
        If String.IsNullOrEmpty(value) OrElse maxLength <= 0 Then Return value
        Return If(value.Length <= maxLength, value, value.Substring(0, maxLength))
    End Function

    Private Function ValidateFile() As Boolean
        Dim fileName = FileUploadControl.FileName.ToLower()
        If Not fileName.EndsWith(".csv") AndAlso Not fileName.EndsWith(".txt") Then
            ShowError("Format invalide. Seuls .csv et .txt sont acceptés.") : Return False
        End If
        If FileUploadControl.FileBytes.Length > 10 * 1024 * 1024 Then
            ShowError("Fichier trop volumineux (max 10 Mo).") : Return False
        End If
        Return True
    End Function

    Private Function GetSelectedEncoding() As Encoding
        Select Case EncodingDropDown.SelectedValue
            Case "Windows-1252" : Return Encoding.GetEncoding(1252)
            Case "ISO-8859-1" : Return Encoding.GetEncoding("ISO-8859-1")
            Case Else : Return Encoding.UTF8
        End Select
    End Function

    Private Function GetSelectedSeparator() As Char
        Select Case SeparatorDropDown.SelectedValue
            Case "," : Return ","c
            Case vbTab : Return CChar(vbTab)
            Case Else : Return ";"c
        End Select
    End Function

    Protected Sub HideMessages()
        SuccessPanel.Visible = False
        ErrorPanel.Visible = False
        WarningPanel.Visible = False
    End Sub

    Protected Sub ShowSuccess(message As String)
        SuccessLiteral.Text = message : SuccessPanel.Visible = True
    End Sub

    Protected Sub ShowError(message As String)
        ErrorLiteral.Text = message : ErrorPanel.Visible = True
    End Sub

    Protected Sub ShowWarning(message As String)
        WarningLiteral.Text = message : WarningPanel.Visible = True
    End Sub

#End Region

#Region "Models"

    Public Class ColumnDef
        Public Property FieldName As String
        Public Property DbColumnName As String
        Public Property SqlType As SqlDbType = SqlDbType.VarChar
        Public Property MaxLength As Integer = 200
        Public Property IsRequired As Boolean = False
        Public Property CsvHeader As String
        Public Property DetectKeywords As String() = {}
        Public Property Description As String = ""
        Public Property Normalizer As Func(Of String, String) = Nothing
    End Class

    Private Class ImportResult
        Public Property Inserted As Integer = 0
        Public Property Skipped As Integer = 0
        Public Property Errors As New List(Of ImportError)
    End Class

    Private Class ImportError
        Public Property LineNumber As Integer
        Public Property KeyValue As String
        Public Property Message As String
    End Class

#End Region

End Class
