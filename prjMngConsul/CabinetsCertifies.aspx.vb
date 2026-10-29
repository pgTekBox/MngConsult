Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

''' <summary>
''' Mon cabinet comptable : l'écran du menu (Mon accompagnement › Mon cabinet
''' comptable), avec l'annuaire des cabinets comptables certifiés 60secondes
''' (T319, s0900), le même pour toutes les compagnies. Les onglets Mon cabinet,
''' Qui fait quoi et Cabinets certifiés viennent de js/cabinet-60s.js. Le mode
''' fenêtre (?popup=1 : ni menu ni en-tête, un bouton Fermer) reste disponible.
''' La recherche filtre les cartes sur place, sans renvoi au serveur.
''' </summary>
Public Class CabinetsCertifies
    Inherits clsData

    ''' <summary>Dans une fenêtre par-dessus une autre page (?popup=1).</summary>
    Private ReadOnly Property EnFenetre As Boolean
        Get
            Return Request.QueryString("popup") = "1"
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Les boîtes posent sur le fond de la page, sans cadre blanc autour (aussi dans la fenêtre).
        DirectCast(Master, SiteMaster).FondDePage = True
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If EnFenetre Then
            litPopupCss.Text = "<style>" &
                ".mc-sidebar, .mc-app > *:not(.mc-shell), .ia-flottant { display: none !important }" &
                ".mc-shell, .mc-maincol { padding: 0 !important; margin: 0 !important; display: block !important }" &
                ".mc-mainwrap { margin: 0 !important; padding: 0 !important; border: 0 !important; box-shadow: none !important; border-radius: 0 !important }" &
                ".cab-page { max-width: none; padding: 10px 16px 16px }" &
                "</style>"
            litFermer.Text = "<button type=""button"" class=""cab-fermer"" onclick=""if (window.parent && window.parent.fermerFenetreApp) { window.parent.fermerFenetreApp(); }"">" &
                             Server.HtmlEncode(T("Fermer", "Close", "Cerrar")) & " ✕</button>"
        End If
        Textes()
        If Not IsPostBack Then Charger()
    End Sub

    ''' <summary>Le mot de la langue de la session.</summary>
    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Cabinets certifiés", "Certified firms", "Despachos certificados"))
        litSous.Text = Server.HtmlEncode(T("Des cabinets comptables formés à 60secondes, qui travaillent en direct dans votre dossier.",
                                           "Accounting firms trained on 60secondes, working live in your file.",
                                           "Despachos contables formados en 60secondes, que trabajan en directo en su expediente."))
        litLede.Text = Server.HtmlEncode(T("Choisissez un cabinet et écrivez-lui : il vous dira comment il travaille et ce qu'il peut faire dans votre dossier — vous décidez ensemble de ses permissions. Vous pouvez aussi inviter votre propre comptable ; il pourra être certifié. Les honoraires, s'il y en a, relèvent du cabinet.",
                                           "Pick a firm and write to it: it will tell you how it works and what it can do in your file — you decide its permissions together. You can also invite your own accountant; they can become certified. Fees, if any, are the firm's own.",
                                           "Elija un despacho y escríbale: le dirá cómo trabaja y qué puede hacer en su expediente — deciden juntos sus permisos. También puede invitar a su propio contador; podrá certificarse. Los honorarios, si los hay, corresponden al despacho."))
        litOutils.Text = "<div class=""cab-outils"">" &
            "<label class=""cab-recherche""><i class=""ic ic-search"" aria-hidden=""true""></i>" &
            "<input type=""search"" id=""cabRecherche"" autocomplete=""off"" placeholder=""" &
            Server.HtmlEncode(T("Rechercher un cabinet, une ville, une spécialité…", "Search a firm, a city, a specialty…", "Buscar un despacho, una ciudad, una especialidad…")) & """ /></label>" &
            "<span class=""cab-compte"" id=""cabCompte"" data-un=""" & Server.HtmlEncode(T("{0} cabinet", "{0} firm", "{0} despacho")) &
            """ data-plusieurs=""" & Server.HtmlEncode(T("{0} cabinets", "{0} firms", "{0} despachos")) & """></span></div>"
        litVide.Text = Server.HtmlEncode(T("Aucun cabinet ne correspond à votre recherche.", "No firm matches your search.", "Ningún despacho coincide con su búsqueda."))
    End Sub

    ''' <summary>Le libellé d'un code de spécialité, dans la langue de la session.</summary>
    Private Function Specialite(code As String) As String
        Select Case code.Trim().ToLowerInvariant()
            Case "ta" : Return T("Travailleurs autonomes", "Self-employed", "Trabajadores autónomos")
            Case "soc" : Return T("Sociétés", "Corporations", "Sociedades")
            Case "paie" : Return T("Paie et employés", "Payroll and employees", "Nómina y empleados")
            Case "constr" : Return T("Construction", "Construction", "Construcción")
            Case "sante" : Return T("Santé et services", "Health and services", "Salud y servicios")
            Case Else : Return code.Trim()
        End Select
    End Function

    ''' <summary>Les initiales du cabinet, pour le rond de la carte.</summary>
    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In nom.Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return sb.ToString()
    End Function

    ''' <summary>Les cabinets actifs (s0900), une carte chacun.</summary>
    Private Sub Charger()
        Dim sb As New StringBuilder()
        Try
            Dim ds As DataSet = ExecuteSQLds("s0900ListCabinetsCertifies")
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    sb.Append(Carte(r))
                Next
            End If
        Catch ex As Exception
            sb.Append("<p class=""cab-vide"">").Append(Server.HtmlEncode(T("L'annuaire n'a pas pu être lu : ", "The directory could not be read: ", "No se pudo leer el directorio: ") & ex.Message)).Append("</p>")
        End Try
        litListe.Text = sb.ToString()
        RendreDemande()
    End Sub

    ''' <summary>
    ''' Flux entrant : bannière du statut de la demande de cabinet de la compagnie
    ''' (s0941) + script du bouton « Demander ce cabinet » (POST DemandeCabinet.ashx).
    ''' </summary>
    Private Sub RendreDemande()
        Dim sb As New StringBuilder()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0941GetMaDemande", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                Dim statut As String = Convert.ToString(r("Statut"))
                Dim cab As String = Convert.ToString(r("CabinetNom"))
                Dim cls As String = "dem-en", txt As String = ""
                Select Case statut
                    Case "EnAttente"
                        txt = T("Demande en attente auprès de ", "Request pending with ", "Solicitud pendiente con ") & cab & "."
                    Case "Acceptee"
                        cls = "dem-ok"
                        txt = cab & T(" a accepté votre demande. C'est votre cabinet.", " accepted your request. It is your firm.", " aceptó su solicitud. Es su despacho.")
                    Case "Refusee"
                        cls = "dem-no"
                        txt = T("Votre demande auprès de ", "Your request to ", "Su solicitud a ") & cab & T(" a été refusée.", " was declined.", " fue rechazada.")
                End Select
                If txt <> "" Then
                    sb.Append("<div class=""cab-demande-statut ").Append(cls).Append(""">").Append(Server.HtmlEncode(txt)).Append("</div>")
                End If
            End If
        Catch
        End Try

        ' Script du bouton « Demander ce cabinet »
        Dim envoyee As String = HttpUtility.JavaScriptStringEncode(T("✓ Demande envoyée", "✓ Request sent", "✓ Solicitud enviada"))
        Dim deja As String = HttpUtility.JavaScriptStringEncode(T("Déjà en attente", "Already pending", "Ya pendiente"))
        Dim erreur As String = HttpUtility.JavaScriptStringEncode(T("Réessayer", "Try again", "Reintentar"))
        sb.Append("<script type=""text/javascript"">(function(){var M={e:'").Append(envoyee).Append("',d:'").Append(deja).Append("',x:'").Append(erreur).Append("'};")
        sb.Append("Array.prototype.forEach.call(document.querySelectorAll('.cab-demander'),function(b){b.addEventListener('click',function(){var id=b.getAttribute('data-cab-id');b.disabled=true;")
        sb.Append("fetch('DemandeCabinet.ashx',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify({cabinetId:parseInt(id,10)})})")
        sb.Append(".then(function(r){return r.json().then(function(j){return {ok:r.ok,j:j};});})")
        sb.Append(".then(function(z){if(z.ok){b.textContent=M.e;}else if(z.j&&z.j.code===1){b.textContent=M.d;}else{b.textContent=M.x;b.disabled=false;}})")
        sb.Append(".catch(function(){b.textContent=M.x;b.disabled=false;});});});})();</script>")

        litDemande.Text = sb.ToString()
    End Sub

    Private Function Carte(r As DataRow) As String
        Dim nom As String = Convert.ToString(r("Nom"))
        Dim resp As String = Convert.ToString(r("Responsable"))
        Dim ville As String = Convert.ToString(r("Ville"))
        Dim province As String = Convert.ToString(r("Province"))
        Dim courriel As String = Convert.ToString(r("Courriel")).Trim()
        Dim tel As String = Convert.ToString(r("Telephone")).Trim()
        Dim site As String = Convert.ToString(r("SiteWeb")).Trim()
        Dim langues As String() = Convert.ToString(r("Langues")).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
        Dim specs As String() = Convert.ToString(r("Specialites")).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
        Dim desc As String = Convert.ToString(r("Description"))
        Dim depuis As String = ""
        If Not IsDBNull(r("CertifieDepuis")) Then depuis = Convert.ToDateTime(r("CertifieDepuis")).Year.ToString(CultureInfo.InvariantCulture)

        Dim lieu As String = ville
        If province <> "" AndAlso ville <> "" Then lieu = ville & " (" & province & ")"

        ' Le texte sur lequel la recherche filtre : tout ce que la carte montre.
        Dim txt As New StringBuilder()
        txt.Append(nom).Append(" ").Append(resp).Append(" ").Append(lieu).Append(" ").Append(String.Join(" ", langues)).Append(" ")
        For Each s As String In specs
            txt.Append(Specialite(s)).Append(" ")
        Next
        txt.Append(desc)

        Dim sb As New StringBuilder()
        sb.Append("<article class=""cab-carte"" data-cab-id=""").Append(Convert.ToString(r("Id"))).Append(""" data-txt=""").Append(Server.HtmlEncode(txt.ToString())).Append(""">")
        sb.Append("<div class=""cab-top""><div class=""cab-av"" aria-hidden=""true"">").Append(Server.HtmlEncode(Initiales(nom))).Append("</div><div>")
        sb.Append("<h2>").Append(Server.HtmlEncode(nom)).Append("</h2>")
        If resp <> "" Then sb.Append("<div class=""cab-resp"">").Append(Server.HtmlEncode(resp)).Append("</div>")
        sb.Append("</div>")
        sb.Append("<span class=""cab-cert""><i class=""ic ic-check-circle"" aria-hidden=""true""></i>").Append(Server.HtmlEncode(T("Certifié", "Certified", "Certificado")))
        If depuis <> "" Then sb.Append(" · ").Append(depuis)
        sb.Append("</span></div>")
        If desc <> "" Then sb.Append("<p class=""cab-desc"">").Append(Server.HtmlEncode(desc)).Append("</p>")
        sb.Append("<div class=""cab-badges"">")
        If lieu <> "" Then sb.Append("<span class=""lieu""><i class=""ic ic-pin"" aria-hidden=""true""></i>").Append(Server.HtmlEncode(lieu)).Append("</span>")
        If langues.Length > 0 Then
            Dim codes As New List(Of String)
            For Each l As String In langues
                codes.Add(l.Trim().ToUpperInvariant())
            Next
            sb.Append("<span class=""lang"">").Append(Server.HtmlEncode(String.Join(" · ", codes))).Append("</span>")
        End If
        For Each s As String In specs
            sb.Append("<span>").Append(Server.HtmlEncode(Specialite(s))).Append("</span>")
        Next
        sb.Append("</div>")
        sb.Append("<div class=""cab-actions"">")
        sb.Append("<button type=""button"" class=""cab-demander"" data-cab-id=""").Append(Convert.ToString(r("Id"))).Append(""">").Append(Server.HtmlEncode(T("Demander ce cabinet", "Request this firm", "Solicitar este despacho"))).Append("</button>")
        If courriel <> "" Then sb.Append("<a href=""mailto:").Append(Server.HtmlEncode(courriel)).Append("""><i class=""ic ic-mail"" aria-hidden=""true""></i>").Append(Server.HtmlEncode(T("Écrire", "Write", "Escribir"))).Append("</a>")
        If site <> "" Then sb.Append("<a class=""sec"" href=""").Append(Server.HtmlEncode(site)).Append(""" target=""_blank"" rel=""noopener""><i class=""ic ic-globe"" aria-hidden=""true""></i>").Append(Server.HtmlEncode(T("Site web", "Website", "Sitio web"))).Append("</a>")
        If tel <> "" Then sb.Append("<span class=""tel"">").Append(Server.HtmlEncode(T("Tél. ", "Tel. ", "Tel. ") & tel)).Append("</span>")
        sb.Append("</div>")
        sb.Append("</article>")
        Return sb.ToString()
    End Function

End Class
