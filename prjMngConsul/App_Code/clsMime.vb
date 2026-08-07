Imports System
Imports System.Collections.Generic
Imports System.Linq
Imports System.Text

''' <summary>
''' Parseur MIME minimaliste (sans dépendance) pour AFFICHER le corps d'un
''' courriel entrant stocké en MIME brut (T990SmtpInboundMessage.RawMessage).
''' Gère : single-part, multipart/* (alternative/mixed/related), encodages
''' base64 et quoted-printable, charset via Content-Type. Ignore les pièces
''' jointes pour le rendu du corps (retourne juste leurs noms).
''' Le corps HTML retourné est destiné à être affiché dans une IFRAME SANDBOX
''' (aucun script exécuté) — ne jamais l'injecter directement dans la page.
''' </summary>
Public Class clsMime

    Public Class MimeResult
        Public Body As String = ""
        Public IsHtml As Boolean = False
        Public Attachments As New List(Of String)
    End Class

    Private Shared ReadOnly Latin1 As Encoding = Encoding.GetEncoding(28591)

    ''' <summary>Extrait le corps affichable d'un message MIME brut.</summary>
    Public Shared Function ExtractBody(raw As Byte()) As MimeResult
        Dim res As New MimeResult()
        If raw Is Nothing OrElse raw.Length = 0 Then Return res
        Try
            Dim msg As String = Latin1.GetString(raw)
            ParsePart(msg, res)
        Catch ex As Exception
            ' Repli : afficher le brut décodé au mieux
            res.Body = SafeUtf8(raw)
            res.IsHtml = False
        End Try
        If res.Body Is Nothing Then res.Body = ""
        Return res
    End Function

    ' Analyse une "partie" MIME (texte Latin1) et remplit res avec le meilleur corps.
    Private Shared Sub ParsePart(part As String, res As MimeResult)
        Dim headersText As String = "", body As String = ""
        SplitHeadersBody(part, headersText, body)
        Dim headers As Dictionary(Of String, String) = ParseHeaders(headersText)

        Dim ct As String = GetHeader(headers, "content-type", "text/plain")
        Dim ctLower As String = ct.ToLowerInvariant()
        Dim cte As String = GetHeader(headers, "content-transfer-encoding", "").ToLowerInvariant().Trim()
        Dim disp As String = GetHeader(headers, "content-disposition", "").ToLowerInvariant()

        If ctLower.StartsWith("multipart/") Then
            Dim boundary As String = GetParam(ct, "boundary")
            If boundary = "" Then Return
            Dim segments As List(Of String) = SplitByBoundary(body, boundary)
            Dim htmlRes As MimeResult = Nothing
            Dim textRes As MimeResult = Nothing
            For Each seg As String In segments
                Dim sub_ As New MimeResult()
                ParsePart(seg, sub_)
                ' remonter les pièces jointes trouvées
                res.Attachments.AddRange(sub_.Attachments)
                If sub_.Body <> "" Then
                    If sub_.IsHtml AndAlso htmlRes Is Nothing Then
                        htmlRes = sub_
                    ElseIf Not sub_.IsHtml AndAlso textRes Is Nothing Then
                        textRes = sub_
                    End If
                End If
            Next
            ' Préférence : HTML puis texte
            Dim chosen As MimeResult = If(htmlRes, textRes)
            If chosen IsNot Nothing Then
                res.Body = chosen.Body
                res.IsHtml = chosen.IsHtml
            End If
            Return
        End If

        ' Feuille : pièce jointe ?
        Dim fileName As String = GetParam(disp, "filename")
        If fileName = "" Then fileName = GetParam(ct, "name")
        If disp.StartsWith("attachment") OrElse (fileName <> "" AndAlso Not ctLower.StartsWith("text/")) Then
            If fileName <> "" Then res.Attachments.Add(DecodeHeaderWord(fileName))
            Return
        End If

        ' Feuille texte : décoder
        Dim charset As String = GetParam(ct, "charset")
        Dim bytes As Byte() = DecodeContent(body, cte)
        res.Body = DecodeBytes(bytes, charset)
        res.IsHtml = ctLower.StartsWith("text/html")
    End Sub

    Private Shared Sub SplitHeadersBody(part As String, ByRef headers As String, ByRef body As String)
        Dim idx As Integer = part.IndexOf(vbCrLf & vbCrLf)
        Dim sep As Integer = 4
        If idx < 0 Then
            idx = part.IndexOf(vbLf & vbLf)
            sep = 2
        End If
        If idx < 0 Then
            headers = part : body = ""
        Else
            headers = part.Substring(0, idx)
            body = part.Substring(idx + sep)
        End If
    End Sub

    Private Shared Function ParseHeaders(text As String) As Dictionary(Of String, String)
        Dim d As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        If text Is Nothing Then Return d
        Dim lines As String() = text.Replace(vbCrLf, vbLf).Split(ChrW(10))
        Dim curName As String = "", curVal As New StringBuilder()
        For Each ln As String In lines
            If ln.Length > 0 AndAlso (ln(0) = " "c OrElse ln(0) = ChrW(9)) Then
                ' continuation
                curVal.Append(" "c).Append(ln.Trim())
            Else
                If curName <> "" Then d(curName) = curVal.ToString()
                Dim c As Integer = ln.IndexOf(":"c)
                If c > 0 Then
                    curName = ln.Substring(0, c).Trim()
                    curVal = New StringBuilder(ln.Substring(c + 1).Trim())
                Else
                    curName = "" : curVal = New StringBuilder()
                End If
            End If
        Next
        If curName <> "" Then d(curName) = curVal.ToString()
        Return d
    End Function

    Private Shared Function GetHeader(h As Dictionary(Of String, String), name As String, def As String) As String
        Dim v As String = ""
        If h.TryGetValue(name, v) Then Return v
        Return def
    End Function

    ' Extrait un paramètre d'un header type "text/html; charset="utf-8"; name=x"
    Private Shared Function GetParam(headerValue As String, param As String) As String
        If headerValue Is Nothing Then Return ""
        Dim parts As String() = headerValue.Split(";"c)
        For Each p As String In parts
            Dim kv As String = p.Trim()
            Dim eq As Integer = kv.IndexOf("="c)
            If eq > 0 Then
                Dim k As String = kv.Substring(0, eq).Trim().ToLowerInvariant()
                If k = param.ToLowerInvariant() Then
                    Dim val As String = kv.Substring(eq + 1).Trim()
                    If val.StartsWith("""") AndAlso val.EndsWith("""") AndAlso val.Length >= 2 Then
                        val = val.Substring(1, val.Length - 2)
                    End If
                    Return val
                End If
            End If
        Next
        Return ""
    End Function

    Private Shared Function SplitByBoundary(body As String, boundary As String) As List(Of String)
        Dim result As New List(Of String)
        Dim delim As String = "--" & boundary
        Dim chunks As String() = body.Split(New String() {delim}, StringSplitOptions.None)
        ' chunks(0) = préambule (avant 1re frontière) -> ignoré
        For i As Integer = 1 To chunks.Length - 1
            Dim c As String = chunks(i)
            ' terminateur "--" en fin
            If c.StartsWith("--") Then Continue For
            ' retirer le CRLF initial
            If c.StartsWith(vbCrLf) Then
                c = c.Substring(2)
            ElseIf c.StartsWith(vbLf) Then
                c = c.Substring(1)
            End If
            result.Add(c)
        Next
        Return result
    End Function

    Private Shared Function DecodeContent(body As String, cte As String) As Byte()
        Try
            If cte = "base64" Then
                Dim clean As String = New String(body.Where(Function(ch) Not Char.IsWhiteSpace(ch)).ToArray())
                Dim pad As Integer = clean.Length Mod 4
                If pad > 0 Then clean &= New String("="c, 4 - pad)
                Return Convert.FromBase64String(clean)
            ElseIf cte = "quoted-printable" Then
                Return DecodeQuotedPrintable(body)
            Else
                Return Latin1.GetBytes(body)
            End If
        Catch
            Return Latin1.GetBytes(body)
        End Try
    End Function

    Private Shared Function DecodeQuotedPrintable(s As String) As Byte()
        Dim outBytes As New List(Of Byte)
        Dim i As Integer = 0
        s = s.Replace(vbCrLf, vbLf)
        While i < s.Length
            Dim ch As Char = s(i)
            If ch = "="c AndAlso i + 1 < s.Length Then
                If s(i + 1) = ChrW(10) Then
                    i += 2 ' soft line break (=LF)
                ElseIf i + 2 < s.Length AndAlso IsHex(s(i + 1)) AndAlso IsHex(s(i + 2)) Then
                    outBytes.Add(Convert.ToByte(s.Substring(i + 1, 2), 16))
                    i += 3
                Else
                    outBytes.Add(AscW("="c)) : i += 1
                End If
            ElseIf ch = ChrW(10) Then
                outBytes.Add(13) : outBytes.Add(10) : i += 1
            Else
                outBytes.Add(CByte(AscW(ch) And &HFF)) : i += 1
            End If
        End While
        Return outBytes.ToArray()
    End Function

    Private Shared Function IsHex(c As Char) As Boolean
        Return (c >= "0"c AndAlso c <= "9"c) OrElse (c >= "A"c AndAlso c <= "F"c) OrElse (c >= "a"c AndAlso c <= "f"c)
    End Function

    Private Shared Function DecodeBytes(bytes As Byte(), charset As String) As String
        If bytes Is Nothing Then Return ""
        Try
            If charset <> "" Then Return Encoding.GetEncoding(charset).GetString(bytes)
        Catch
        End Try
        Return SafeUtf8(bytes)
    End Function

    Private Shared Function SafeUtf8(bytes As Byte()) As String
        Try
            Return New UTF8Encoding(False, False).GetString(bytes)
        Catch
            Return Latin1.GetString(bytes)
        End Try
    End Function

    ' Décodage minimal d'un mot encodé RFC2047 dans un nom de fichier (=?utf-8?B?..?=)
    Private Shared Function DecodeHeaderWord(s As String) As String
        Try
            Dim m As Text.RegularExpressions.Match =
                Text.RegularExpressions.Regex.Match(s, "=\?(?<cs>[^?]+)\?(?<enc>[BbQq])\?(?<txt>[^?]*)\?=")
            If m.Success Then
                Dim cs As String = m.Groups("cs").Value
                Dim enc As String = m.Groups("enc").Value.ToUpperInvariant()
                Dim txt As String = m.Groups("txt").Value
                Dim by As Byte()
                If enc = "B" Then
                    by = Convert.FromBase64String(txt)
                Else
                    by = DecodeQuotedPrintable(txt.Replace("_", " "))
                End If
                Return Encoding.GetEncoding(cs).GetString(by)
            End If
        Catch
        End Try
        Return s
    End Function

    ''' <summary>Une pièce jointe avec son contenu (pour téléchargement).</summary>
    Public Class MimeAttachment
        Public Property FileName As String
        Public Property ContentType As String
        Public Property Content As Byte()
    End Class

    ''' <summary>Extrait le CONTENU des pièces jointes du MIME brut.</summary>
    Public Shared Function ExtractAttachments(raw As Byte()) As List(Of MimeAttachment)
        Dim list As New List(Of MimeAttachment)()
        If raw Is Nothing OrElse raw.Length = 0 Then Return list
        Try
            CollectAttachments(Latin1.GetString(raw), list)
        Catch
        End Try
        Return list
    End Function

    Private Shared Sub CollectAttachments(part As String, list As List(Of MimeAttachment))
        Dim headersText As String = "", body As String = ""
        SplitHeadersBody(part, headersText, body)
        Dim headers = ParseHeaders(headersText)
        Dim ct As String = GetHeader(headers, "content-type", "text/plain")
        Dim ctLower = ct.ToLowerInvariant()
        Dim cte = GetHeader(headers, "content-transfer-encoding", "").ToLowerInvariant().Trim()
        Dim disp = GetHeader(headers, "content-disposition", "").ToLowerInvariant()

        If ctLower.StartsWith("multipart/") Then
            Dim boundary = GetParam(ct, "boundary")
            If boundary = "" Then Return
            For Each seg In SplitByBoundary(body, boundary)
                CollectAttachments(seg, list)
            Next
            Return
        End If

        Dim fileName As String = GetParam(disp, "filename")
        If fileName = "" Then fileName = GetParam(ct, "name")
        Dim isAtt As Boolean = disp.StartsWith("attachment") OrElse (fileName <> "" AndAlso Not ctLower.StartsWith("text/"))
        If isAtt Then
            list.Add(New MimeAttachment With {
                .FileName = DecodeHeaderWord(If(fileName <> "", fileName, "piece-jointe")),
                .ContentType = ct.Split(";"c)(0).Trim(),
                .Content = DecodeContent(body, cte)})
        End If
    End Sub

End Class
