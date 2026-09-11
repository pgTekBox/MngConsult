Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks
Imports Newtonsoft.Json.Linq

''' <summary>
''' L'importation des clients, des fournisseurs ou des produits et services —
''' un même écran, trois usages. Chaque page (ImportClients, ImportFournisseurs,
''' ImportProduits) le pose avec son <see cref="Genre"/>.
'''
''' Le parcours :
'''   1. d'où viennent les données — logiciel, séparateur, encodage, marche à suivre ;
'''   2. le fichier, lu directement, ou extrait par l'IA quand il est mal formé ;
'''   3. ce qui a été lu, en préparation, ligne par ligne, avec ce qui existe
'''      déjà dans l'application ;
'''   4. la création pour de bon — de ce qui est nouveau, seulement.
'''
''' La chaîne en base est celle qui existait : staging.ImportFiles (s0600,
''' s0602), staging.PartyImport / ProductImport (s0604), puis l'application
''' (s0607, s0608). Tout ce qui lit, crée ou efface passe par la compagnie
''' (s0772 à s0775).
''' </summary>
Public Class ImportDonnees
    Inherits clsDataUC

    ''' <summary>CLIENTS, FOURNISSEURS ou PRODUITS.</summary>
    Public Property Genre As String = "CLIENTS"

    Private Const ModeleIA As String = "gpt-4.1-mini"
    Private Const LectureDirecte As String = "LECTURE"
    Private Const TailleMax As Integer = 10 * 1024 * 1024

    Private Shared ReadOnly Inv As Globalization.CultureInfo = Globalization.CultureInfo.InvariantCulture
    Private Shared ReadOnly Fr As Globalization.CultureInfo = Globalization.CultureInfo.GetCultureInfo("fr-CA")

#Region "Ce que l'on importe"

    Private Class Colonne
        Public Champ As String
        Public Libelle As String
        Public Description As String
        Public MotsCles As String()
        Public Longueur As Integer = 200
        Public EstMontant As Boolean
    End Class

    Private Class Definition
        Public TypeImport As String
        Public Titre As String
        Public Icone As String
        Public Un As String
        Public Des As String
        Public Nouveaux As String
        Public Prompt As String
        Public Liste As String
        Public Colonnes As List(Of Colonne)
    End Class

    Private _def As Definition

    Private ReadOnly Property Def As Definition
        Get
            If _def Is Nothing Then _def = Definir(Genre)
            Return _def
        End Get
    End Property

    Private ReadOnly Property EstProduit As Boolean
        Get
            Return Def.TypeImport = "Produit"
        End Get
    End Property

    Private Shared Function Definir(genre As String) As Definition
        Select Case If(genre, "").ToUpperInvariant()
            Case "FOURNISSEURS"
                Return New Definition With {
                    .TypeImport = "Fournisseur", .Titre = "Importer les fournisseurs", .Icone = "🏭",
                    .Un = "fournisseur", .Des = "fournisseurs", .Nouveaux = "nouveaux fournisseurs",
                    .Prompt = "PROMPT_IMPORT_FOURNISSEURS", .Liste = "~/wbfSuppliers.aspx",
                    .Colonnes = ColonnesTiers("fournisseur")}
            Case "PRODUITS"
                Return New Definition With {
                    .TypeImport = "Produit", .Titre = "Importer les produits et services", .Icone = "🏷️",
                    .Un = "produit ou service", .Des = "produits et services",
                    .Nouveaux = "nouveaux produits et services",
                    .Prompt = "PROMPT_IMPORT_PRODUITS", .Liste = "~/wbfProducts.aspx",
                    .Colonnes = ColonnesProduits()}
            Case Else
                Return New Definition With {
                    .TypeImport = "Client", .Titre = "Importer les clients", .Icone = "👥",
                    .Un = "client", .Des = "clients", .Nouveaux = "nouveaux clients",
                    .Prompt = "PROMPT_IMPORT_CLIENTS", .Liste = "~/wbfCustomers.aspx",
                    .Colonnes = ColonnesTiers("client")}
        End Select
    End Function

    ''' <summary>
    ''' Les colonnes d'une liste de tiers. L'ordre compte : c'est celui dans
    ''' lequel les champs choisissent leur colonne. Le courriel passe avant le
    ''' contact et l'adresse, sans quoi « Contact Email » ou « Email Address »
    ''' iraient au mauvais champ.
    ''' </summary>
    Private Shared Function ColonnesTiers(qui As String) As List(Of Colonne)
        Return New List(Of Colonne) From {
            New Colonne With {.Champ = "name", .Libelle = "Nom", .Longueur = 500,
                .Description = "Le nom du " & qui & " — la seule colonne indispensable",
                .MotsCles = {"display name", "customer", "client", "vendor", "supplier", "fournisseur",
                             "company", "compagnie", "entreprise", "raison sociale", "name", "nom"}},
            New Colonne With {.Champ = "email", .Libelle = "Courriel", .Description = "L'adresse courriel",
                .MotsCles = {"email", "e-mail", "courriel", "mail"}},
            New Colonne With {.Champ = "phone", .Libelle = "Téléphone", .Description = "Le numéro de téléphone",
                .MotsCles = {"phone", "téléphone", "telephone", "tél", "tel", "mobile", "cellulaire"}},
            New Colonne With {.Champ = "contact_name", .Libelle = "Contact", .Description = "La personne à joindre",
                .MotsCles = {"contact", "full name", "nom complet", "attention", "personne"}},
            New Colonne With {.Champ = "address2", .Libelle = "Adresse (suite)", .Longueur = 500,
                .Description = "Le complément d'adresse",
                .MotsCles = {"address 2", "address2", "adresse 2", "adresse2", "address line 2", "street 2"}},
            New Colonne With {.Champ = "address1", .Libelle = "Adresse", .Longueur = 500,
                .Description = "La rue — ou l'adresse entière, si elle tient dans une cellule",
                .MotsCles = {"billing address", "address 1", "address1", "adresse 1", "street", "address", "adresse", "rue"}},
            New Colonne With {.Champ = "city", .Libelle = "Ville", .Longueur = 50, .Description = "La ville",
                .MotsCles = {"city", "ville", "municipalité"}},
            New Colonne With {.Champ = "province", .Libelle = "Province", .Longueur = 50,
                .Description = "La province ou l'État",
                .MotsCles = {"province", "state", "état", "etat", "prov"}},
            New Colonne With {.Champ = "postal_code", .Libelle = "Code postal", .Longueur = 20, .Description = "Le code postal",
                .MotsCles = {"postal", "zip", "code postal"}},
            New Colonne With {.Champ = "tps", .Libelle = "No TPS", .Longueur = 20, .Description = "Le numéro de TPS ou de TVH",
                .MotsCles = {"tps", "gst", "hst", "tvh"}},
            New Colonne With {.Champ = "tvq", .Libelle = "No TVQ", .Longueur = 20, .Description = "Le numéro de TVQ",
                .MotsCles = {"tvq", "qst"}},
            New Colonne With {.Champ = "balance", .Libelle = "Solde", .EstMontant = True,
                .Description = "Le solde, s'il figure au fichier — lu pour contrôle, pas repris",
                .MotsCles = {"open balance", "balance", "solde"}}
        }
    End Function

    Private Shared Function ColonnesProduits() As List(Of Colonne)
        Return New List(Of Colonne) From {
            New Colonne With {.Champ = "name", .Libelle = "Nom", .Longueur = 500,
                .Description = "Le nom du produit ou du service — la seule colonne indispensable",
                .MotsCles = {"product/service name", "product/service", "product name", "item name",
                             "name", "nom", "produit", "service", "article", "item"}},
            New Colonne With {.Champ = "description", .Libelle = "Description", .Longueur = 2000,
                .Description = "La description de vente",
                .MotsCles = {"sales description", "description", "libellé", "libelle"}},
            New Colonne With {.Champ = "price", .Libelle = "Prix", .EstMontant = True,
                .Description = "Le prix de vente, ou le tarif",
                .MotsCles = {"sales price / rate", "sales price", "price", "rate", "prix", "tarif", "unit price"}},
            New Colonne With {.Champ = "taxable", .Libelle = "Taxable", .Longueur = 10,
                .Description = "Oui ou non — taxable par défaut",
                .MotsCles = {"taxable", "taxe", "tax"}}
        }
    End Function

#End Region

#Region "Cycle de vie"

    ''' <summary>Le fichier affiché, conservé entre les allers-retours.</summary>
    Private Property FichierCourant As Integer
        Get
            Dim v = ViewState("FichierCourant")
            Return If(v Is Nothing, 0, CInt(v))
        End Get
        Set(value As Integer)
            ViewState("FichierCourant") = value
        End Set
    End Property

    Protected Sub Page_Init(sender As Object, e As EventArgs) Handles Me.Init
        ' Avant le chargement du bloc : il en a besoin pour choisir sa marche à suivre.
        ucSource.Donnees = If(Genre, "CLIENTS").ToUpperInvariant()
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ucSource.ColonnesHtml = TableauColonnes()

        If IsPostBack Then Return

        litIcone.Text = Def.Icone
        litTitre.Text = H(Def.Titre)
        litSousTitre.Text = "Reprise des données — " & H(Def.Des)
        litUn.Text = H(Def.Un)
        litIntro.Text = "Déposez la liste des " & H(Def.Des) & " de votre ancien logiciel. Elle est lue, " &
                        "rapprochée de ce qui existe déjà et mise en préparation. <b>Rien n'est créé tant " &
                        "que vous ne l'avez pas décidé</b>, et ce qui existe déjà n'est jamais recréé."

        ' En revenant sur l'écran, on retrouve le dernier fichier déposé : il
        ' est en base, l'écran n'a qu'à le montrer.
        Dim dernier = ChargerFichiers()
        If dernier > 0 Then Afficher(dernier)
    End Sub

    Protected Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        Dim garde = FichierGarde()
        pnlEnMemoire.Visible = (garde IsNot Nothing)
        If garde IsNot Nothing Then
            litEnMemoire.Text = "📄 <b>" & H(garde.Nom) & "</b> (" &
                                (garde.Octets.Length / 1024.0).ToString("N0", Fr) &
                                " Ko) est gardé depuis votre dernier dépôt : les boutons ci-dessous s'en servent. " &
                                "Déposez-en un autre pour le remplacer."
        End If
    End Sub

#End Region

#Region "Les boutons"

    Protected Sub btnApercu_Click(sender As Object, e As EventArgs) Handles btnApercu.Click
        Cacher()
        Dim f = Fichier()
        If f Is Nothing Then Return

        Try
            Dim l = LireDirectement(LireTexte(f.Octets), 10)
            If l Is Nothing Then
                ShowErreur(AucunEntete())
                Return
            End If
            litApercu.Text = RendreApercu(l)
            pnlApercu.Visible = True
        Catch ex As Exception
            ShowErreur("Lecture du fichier : " & H(ex.Message))
        End Try
    End Sub

    Protected Sub btnLire_Click(sender As Object, e As EventArgs) Handles btnLire.Click
        Cacher()
        Dim f = Fichier()
        If f Is Nothing Then Return

        Try
            Dim l = LireDirectement(LireTexte(f.Octets))
            If l Is Nothing Then
                ShowErreur(AucunEntete())
                Return
            End If
            If l.Lignes.Count = 0 Then
                ShowErreur("L'en-tête a été reconnu, mais aucune ligne ne porte de nom. " &
                           "Vérifiez le séparateur, ou essayez <b>Extraire avec l'IA</b>.")
                Return
            End If

            Dim lignes As New JArray()
            For Each o In l.Lignes
                lignes.Add(o)
            Next

            Dim id = Preparer(f, lignes, LectureDirecte, 0, 0, 0D)
            Session.Remove(CleSession)

            Dim msg = l.Lignes.Count & " ligne(s) lue(s) et mise(s) en préparation."
            If l.Ecartees > 0 Then msg &= " " & l.Ecartees & " ligne(s) sans nom — titres, totaux, pied de page — ont été écartées."
            ShowSucces(msg & " Rien n'est encore créé : vérifiez ci-dessous, puis décidez.")

            ChargerFichiers()
            Afficher(id)
        Catch ex As Exception
            ShowErreur("Lecture du fichier : " & H(ex.Message))
        End Try
    End Sub

    Protected Async Sub btnIA_Click(sender As Object, e As EventArgs) Handles btnIA.Click
        Cacher()
        Dim f = Fichier()
        If f Is Nothing Then Return

        Try
            Await Extraire(f)
        Catch ex As Exception
            ShowErreur("Extraction par l'IA : " & H(ex.Message))
        End Try
    End Sub

    Protected Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Cacher()
        If FichierCourant = 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@ImportFileId", FichierCourant))
            Dim ds As DataSet = ExecuteSQLds("s0774AppliquerImportFichier", p)

            Dim crees = 0, ecartes = 0, erreurs = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r = ds.Tables(0).Rows(0)
                crees = Ent(r("Migrated"))
                ecartes = Ent(r("Skipped"))
                erreurs = Ent(r("Errors"))
            End If

            Dim msg = If(crees = 0, "Rien n'a été créé.",
                         If(crees = 1, "1 " & H(Def.Un) & " créé", crees & " " & H(Def.Des) & " créés") & " dans l'application.")
            If ecartes > 0 OrElse crees = 0 Then
                msg &= " Ce qui existait déjà, ou que le fichier répétait, a été laissé de côté : le tableau dit ce qu'il est advenu de chaque ligne."
            End If
            If erreurs > 0 Then
                ShowAvert(msg & " " & erreurs & " ligne(s) en erreur : voir le détail dans le tableau.")
            Else
                ShowSucces(msg)
            End If
        Catch ex As Exception
            ShowErreur("Création : " & H(ex.Message))
        End Try

        ChargerFichiers()
        Afficher(FichierCourant)
    End Sub

    Protected Sub btnAbandonner_Click(sender As Object, e As EventArgs) Handles btnAbandonner.Click
        Cacher()
        If FichierCourant > 0 Then Abandonner(FichierCourant)
    End Sub

    Protected Sub gvFichiers_RowCommand(sender As Object, e As GridViewCommandEventArgs) Handles gvFichiers.RowCommand
        Dim id As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) OrElse id <= 0 Then Return

        Cacher()
        Select Case e.CommandName
            Case "Voir" : Afficher(id)
            Case "Supprimer" : Abandonner(id)
        End Select
    End Sub

    Private Sub Abandonner(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@ImportFileId", id))
            Dim ds As DataSet = ExecuteSQLds("s0775SupprimerImportFichier", p)

            Dim n = 0
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                n = Ent(ds.Tables(0).Rows(0)("LignesSupprimees"))
            End If

            ShowSucces("Fichier abandonné : " & n & " ligne(s) retirée(s) de la préparation. " &
                       "Ce qui avait déjà été créé dans l'application reste en place.")
            If id = FichierCourant Then
                FichierCourant = 0
                pnlResultat.Visible = False
            End If
        Catch ex As Exception
            ShowErreur("Abandon du fichier : " & H(ex.Message))
        End Try

        ChargerFichiers()
    End Sub

#End Region

#Region "Le fichier déposé"

    ''' <summary>
    ''' Le fichier est gardé en session au premier dépôt : un aller-retour vide
    ''' le champ de dépôt, et il serait absurde de redemander le fichier entre
    ''' l'aperçu et la lecture.
    ''' </summary>
    <Serializable>
    Private Class FichierDepose
        Public Nom As String
        Public Octets As Byte()
    End Class

    Private ReadOnly Property CleSession As String
        Get
            Return "ImportDonnees_" & Def.TypeImport
        End Get
    End Property

    Private Function FichierGarde() As FichierDepose
        Return TryCast(Session(CleSession), FichierDepose)
    End Function

    Private Function Fichier() As FichierDepose
        If fuFichier.HasFile Then
            Dim nom = Path.GetFileName(fuFichier.FileName)
            Dim ext = Path.GetExtension(nom).ToLowerInvariant()

            If ext <> ".csv" AndAlso ext <> ".txt" Then
                ShowErreur("Seuls les fichiers .csv et .txt sont acceptés. Un fichier Excel s'enregistre en CSV " &
                           "depuis Excel : <b>Fichier ▸ Enregistrer sous ▸ CSV UTF-8</b>.")
                Return Nothing
            End If

            If fuFichier.FileBytes.Length > TailleMax Then
                ShowErreur("Le fichier dépasse 10 Mo.")
                Return Nothing
            End If

            Dim f As New FichierDepose With {.Nom = nom, .Octets = fuFichier.FileBytes}
            Session(CleSession) = f
            Return f
        End If

        Dim garde = FichierGarde()
        If garde IsNot Nothing Then Return garde

        ShowErreur("Déposez d'abord un fichier.")
        Return Nothing
    End Function

    ''' <summary>Le texte du fichier, dans l'encodage choisi — sauf si le fichier dit le sien.</summary>
    Private Function LireTexte(octets As Byte()) As String
        Using ms As New MemoryStream(octets)
            Using r As New StreamReader(ms, ucSource.Encodage, True)
                Return r.ReadToEnd()
            End Using
        End Using
    End Function

#End Region

#Region "Lecture directe"

    Private Class Lecture
        Public Entetes As String()
        Public LigneEntete As Integer
        Public Separateur As Char
        Public Carte As Dictionary(Of String, Integer)
        Public Lignes As New List(Of JObject)
        Public Ecartees As Integer
    End Class

    ''' <summary>
    ''' Ce qui clôt un rapport exporté : les totaux, et la date d'impression que
    ''' QuickBooks met au pied de page (« Monday, September 11, 2026 09:12 AM GMT-04:00 »).
    ''' </summary>
    Private Shared ReadOnly PiedDePage As New Regex(
        "^(total|totaux|sous-total|subtotal)\b" &
        "|\d{1,2}:\d{2}.*\b(am|pm|gmt|utc)\b" &
        "|^(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*,",
        RegexOptions.IgnoreCase)

    ''' <summary>
    ''' Lit le fichier tel qu'il est : cherche la ligne d'en-tête dans les
    ''' trente premières (les rapports commencent par des lignes de titre),
    ''' reconnaît les colonnes par leur en-tête, et lit chaque ligne qui porte
    ''' un nom. Le séparateur choisi d'abord ; s'il ne fait apparaître aucun
    ''' en-tête, les autres. Rend Nothing si rien n'a été reconnu.
    ''' </summary>
    Private Function LireDirectement(texte As String, Optional max As Integer = 0) As Lecture
        Dim essais As New List(Of Char) From {ucSource.Separateur}
        For Each c In New Char() {","c, ";"c, ControlChars.Tab}
            If Not essais.Contains(c) Then essais.Add(c)
        Next

        For Each sep In essais
            Dim enregistrements = DecouperEnregistrements(texte, sep)
            Dim entete As Integer = -1
            Dim carte As Dictionary(Of String, Integer) = Nothing

            For i = 0 To Math.Min(enregistrements.Count, 30) - 1
                Dim cellules = enregistrements(i)
                If cellules.Length < 2 Then Continue For

                Dim c = Associer(cellules)
                If c.ContainsKey("name") AndAlso c.Count >= 2 Then
                    entete = i
                    carte = c
                    Exit For
                End If
            Next

            If entete < 0 Then Continue For

            Dim l As New Lecture With {
                .Entetes = enregistrements(entete), .LigneEntete = entete,
                .Separateur = sep, .Carte = carte
            }

            For i = entete + 1 To enregistrements.Count - 1
                Dim cellules = enregistrements(i)
                Dim nom = Cellule(cellules, carte("name"))
                If nom = "" OrElse PiedDePage.IsMatch(nom) Then
                    l.Ecartees += 1
                    Continue For
                End If

                Dim o As New JObject()
                For Each col In Def.Colonnes
                    If Not carte.ContainsKey(col.Champ) Then Continue For
                    Dim v = Cellule(cellules, carte(col.Champ))
                    If v = "" Then Continue For

                    If col.EstMontant Then
                        Dim m = LireMontant(v)
                        If m.HasValue Then o(col.Champ) = New JValue(m.Value.ToString(Inv))
                    Else
                        o(col.Champ) = New JValue(Tronquer(v, col.Longueur))
                    End If
                Next

                l.Lignes.Add(o)
                If max > 0 AndAlso l.Lignes.Count >= max Then Exit For
            Next

            Return l
        Next

        Return Nothing
    End Function

    ''' <summary>
    ''' Découpe le fichier en enregistrements CSV. Un saut de ligne entre
    ''' guillemets fait partie de la valeur : QuickBooks écrit ainsi les
    ''' adresses et les téléphones sur plusieurs lignes (« Boveney↵Windsor
    ''' SL4 6QP »). Il y devient une virgule, pour que la valeur tienne sur une
    ''' ligne. Les enregistrements entièrement vides sont omis.
    ''' </summary>
    Private Shared Function DecouperEnregistrements(texte As String, sep As Char) As List(Of String())
        Dim tous As New List(Of String())
        Dim champs As New List(Of String)
        Dim courant As New StringBuilder()
        Dim entreGuillemets As Boolean = False
        Dim i As Integer = 0

        While i < texte.Length
            Dim ch = texte(i)
            Dim finDeLigne = (ch = ControlChars.Cr OrElse ch = ControlChars.Lf)
            If ch = ControlChars.Cr AndAlso i + 1 < texte.Length AndAlso texte(i + 1) = ControlChars.Lf Then i += 1

            If entreGuillemets Then
                If ch = """"c Then
                    If i + 1 < texte.Length AndAlso texte(i + 1) = """"c Then
                        courant.Append(""""c) : i += 1
                    Else
                        entreGuillemets = False
                    End If
                ElseIf finDeLigne Then
                    If courant.Length > 0 Then courant.Append(", ")
                Else
                    courant.Append(ch)
                End If
            ElseIf ch = """"c Then
                entreGuillemets = True
            ElseIf ch = sep Then
                champs.Add(courant.ToString()) : courant.Clear()
            ElseIf finDeLigne Then
                champs.Add(courant.ToString()) : courant.Clear()
                If champs.Exists(Function(x) x.Trim() <> "") Then tous.Add(champs.ToArray())
                champs = New List(Of String)
            Else
                courant.Append(ch)
            End If

            i += 1
        End While

        champs.Add(courant.ToString())
        If champs.Exists(Function(x) x.Trim() <> "") Then tous.Add(champs.ToArray())
        Return tous
    End Function

    ''' <summary>
    ''' Donne à chaque champ sa colonne : d'abord les en-têtes identiques à un
    ''' mot-clé, puis ceux qui en contiennent un. Une colonne ne sert qu'une
    ''' fois — « Email Address » ne peut pas être à la fois le courriel et
    ''' l'adresse.
    ''' </summary>
    Private Function Associer(entetes As String()) As Dictionary(Of String, Integer)
        Dim carte As New Dictionary(Of String, Integer)
        Dim prises As New HashSet(Of Integer)
        Dim norm = entetes.Select(Function(h) h.Trim().Trim(""""c).Trim().ToLowerInvariant()).ToArray()

        For Each col In Def.Colonnes
            For j = 0 To norm.Length - 1
                If prises.Contains(j) OrElse norm(j) = "" Then Continue For
                If col.MotsCles.Contains(norm(j)) Then
                    carte(col.Champ) = j
                    prises.Add(j)
                    Exit For
                End If
            Next
        Next

        For Each col In Def.Colonnes
            If carte.ContainsKey(col.Champ) Then Continue For
            For j = 0 To norm.Length - 1
                Dim entete = norm(j)
                If prises.Contains(j) OrElse entete = "" OrElse entete.Length > 40 Then Continue For
                If col.MotsCles.Any(Function(k) entete.Contains(k)) Then
                    carte(col.Champ) = j
                    prises.Add(j)
                    Exit For
                End If
            Next
        Next

        Return carte
    End Function

    Private Function AucunEntete() As String
        Return "Aucune ligne d'en-tête reconnue : il faut au moins une colonne de nom et une autre colonne " &
               "reconnaissable (voir « Les colonnes attendues »). Si le fichier est mal formé, " &
               "<b>Extraire avec l'IA</b> saura sans doute le lire."
    End Function

#End Region

#Region "Extraction par l'IA"

    ''' <summary>
    ''' Confie la lecture à ChatGPT, pour les fichiers que la lecture directe ne
    ''' sait pas démêler. Un modèle peut rendre un nom plausible qui n'est pas
    ''' dans le fichier : chaque nom rendu doit s'y retrouver, sinon la ligne est
    ''' refusée. Un montant qu'on n'y retrouve pas est retiré de la ligne.
    ''' </summary>
    Private Async Function Extraire(f As FichierDepose) As Task
        Dim texte = LireTexte(f.Octets)

        If texte.Length > 150000 Then
            ShowErreur("Le fichier est trop volumineux pour une extraction par l'IA (plus de 150 000 caractères). " &
                       "Utilisez <b>Lire le fichier</b>, ou découpez-le.")
            Return
        End If

        Dim cle = Parametre("s0000GetParameter", "CHATGPT", "Value")
        If cle = "" Then
            ShowErreur("La clé d'accès à l'IA n'est pas configurée.")
            Return
        End If

        Dim prompt = Parametre("s0032GetPromptOpenAPI", Def.Prompt, "Prompt")
        If prompt = "" Then
            ShowErreur("Le prompt " & Def.Prompt & " n'est pas configuré.")
            Return
        End If

        Dim rep = Await New OpenAiReceiptReader(cle).ParseInvoiceEmailAsync(texte, prompt)

        Dim jo = LireObjetJson(rep.JsonText)
        Dim rows = If(jo Is Nothing, Nothing, TryCast(jo("rows"), JArray))
        If rows Is Nothing Then
            ShowErreur("L'IA n'a pas rendu une réponse exploitable. Réessayez, ou vérifiez le contenu du fichier.")
            Return
        End If

        Dim cherche = Aplatir(texte)
        Dim montants = MontantsDuFichier(texte)
        Dim retenues As New JArray()
        Dim refusees As New List(Of String)
        Dim montantsRetires As Integer = 0

        For Each t In rows
            Dim o = TryCast(t, JObject)
            If o Is Nothing Then Continue For

            Dim nom = Chaine(o("name"))
            If nom = "" Then Continue For

            ' Le garde-fou : un nom que le fichier ne contient pas est une invention.
            If Not cherche.Contains(Aplatir(nom)) Then
                refusees.Add(nom)
                Continue For
            End If

            Dim propre As New JObject()
            For Each col In Def.Colonnes
                Dim v = o(col.Champ)
                If v Is Nothing OrElse v.Type = JTokenType.Null Then Continue For

                If col.EstMontant Then
                    Dim m = MontantJson(v)
                    If Not m.HasValue Then Continue For
                    If montants.Contains(Math.Abs(m.Value)) Then
                        propre(col.Champ) = New JValue(m.Value.ToString(Inv))
                    Else
                        montantsRetires += 1
                    End If
                ElseIf v.Type = JTokenType.Boolean Then
                    propre(col.Champ) = New JValue(If(v.Value(Of Boolean)(), "true", "false"))
                Else
                    Dim s = Chaine(v)
                    If s <> "" Then propre(col.Champ) = New JValue(Tronquer(s, col.Longueur))
                End If
            Next

            retenues.Add(propre)
        Next

        If retenues.Count = 0 Then
            ShowErreur("L'IA n'a rendu aucune ligne dont le nom se retrouve dans le fichier.")
            Return
        End If

        Dim id = Preparer(f, retenues, ModeleIA, rep.InputTokens, rep.OutputTokens, rep.EstimatedCostUsd)
        Session.Remove(CleSession)

        Dim msg = retenues.Count & " ligne(s) extraite(s) par l'IA et mise(s) en préparation — coût estimé " &
                  rep.EstimatedCostUsd.ToString("N4", Fr) & " US$. Rien n'est encore créé : vérifiez ci-dessous, puis décidez."
        If refusees.Count > 0 OrElse montantsRetires > 0 Then
            Dim avert As New StringBuilder(msg)
            If refusees.Count > 0 Then
                avert.Append("<br />").Append(refusees.Count).Append(" ligne(s) refusée(s), leur nom ne figurant pas dans le fichier : ")
                avert.Append(H(String.Join(", ", refusees.Take(8))))
                If refusees.Count > 8 Then avert.Append("…")
                avert.Append(".")
            End If
            If montantsRetires > 0 Then
                avert.Append("<br />").Append(montantsRetires).Append(" montant(s) retiré(s), introuvable(s) dans le fichier.")
            End If
            ShowAvert(avert.ToString())
        Else
            ShowSucces(msg)
        End If

        ChargerFichiers()
        Afficher(id)
    End Function

    ''' <summary>Pour comparer un nom au fichier : minuscules, espaces et guillemets aplatis.</summary>
    Private Shared Function Aplatir(s As String) As String
        Return Regex.Replace(If(s, "").ToLowerInvariant(), "[\s""]+", " ").Trim()
    End Function

    ''' <summary>Tous les nombres du fichier, en valeur absolue, quel que soit leur format.</summary>
    Private Shared Function MontantsDuFichier(texte As String) As HashSet(Of Decimal)
        Dim ens As New HashSet(Of Decimal)
        Dim motif As New Regex("\(?-?\$?\d{1,3}(?:[ ,. ]\d{3})*(?:[.,]\d{1,2})?\)?|\(?-?\$?\d+(?:[.,]\d{1,2})?\)?")

        For Each m As Match In motif.Matches(texte)
            Dim v = LireMontant(m.Value)
            If v.HasValue Then ens.Add(Math.Abs(v.Value))
        Next

        Return ens
    End Function

    Private Shared Function LireObjetJson(brut As String) As JObject
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim debut = brut.IndexOf("{"c)
        Dim fin = brut.LastIndexOf("}"c)
        If debut < 0 OrElse fin <= debut Then Return Nothing

        Try
            Return JObject.Parse(brut.Substring(debut, fin - debut + 1))
        Catch
            Return Nothing
        End Try
    End Function

    Private Shared Function MontantJson(t As JToken) As Decimal?
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return Nothing
        If t.Type = JTokenType.Integer OrElse t.Type = JTokenType.Float Then Return t.Value(Of Decimal)()
        Return LireMontant(Chaine(t))
    End Function

    Private Function Parametre(proc As String, valeur As String, colonne As String) As String
        Dim p As New Collection
        p.Add(New SqlParameter("@Parameter", valeur))
        Dim ds As DataSet = ExecuteSQLds(proc, p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return ""
        Return Txt(ds.Tables(0).Rows(0)(colonne))
    End Function

#End Region

#Region "En préparation"

    ''' <summary>
    ''' Range le fichier et ce qui en a été lu, puis le met en préparation —
    ''' par la chaîne existante, pour la compagnie. Rend l'identifiant du fichier.
    ''' </summary>
    Private Function Preparer(f As FichierDepose, lignes As JArray, modele As String,
                              jetonsEntree As Integer, jetonsSortie As Integer, cout As Decimal) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@TypeImport", Def.TypeImport))
        p.Add(New SqlParameter("@OriginalName", f.Nom))
        p.Add(New SqlParameter("@FileExtension", Path.GetExtension(f.Nom).ToLowerInvariant()))
        p.Add(New SqlParameter("@FileSize", CObj(CLng(f.Octets.Length))))
        p.Add(New SqlParameter("@ContentType", "text/csv"))
        p.Add(New SqlParameter("@FileContent", f.Octets))
        p.Add(New SqlParameter("@UploadedBy", CObj(UserId)))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0600InsertImportFile", p)
        Dim id = Convert.ToInt32(ds.Tables(0).Rows(0)(0))

        Dim json As New JObject(New JProperty("rows", lignes))

        Dim p2 As New Collection
        p2.Add(New SqlParameter("@Id", CObj(id)))
        p2.Add(New SqlParameter("@JsonResult", json.ToString(Newtonsoft.Json.Formatting.None)))
        p2.Add(New SqlParameter("@InputTokens", CObj(jetonsEntree)))
        p2.Add(New SqlParameter("@OutputTokens", CObj(jetonsSortie)))
        p2.Add(New SqlParameter("@EstimatedCostUsd", CObj(cout)))
        p2.Add(New SqlParameter("@ModelUsed", modele))
        p2.Add(New SqlParameter("@Status", "Done"))
        p2.Add(New SqlParameter("@ErrorMessage", DBNull.Value))
        ExecuteSQL("s0602UpdateImportFileResult", p2)

        Dim p3 As New Collection
        p3.Add(New SqlParameter("@ImportFileId", CObj(id)))
        ExecuteSQLds("s0604ProcessImportJson", p3)

        Return id
    End Function

    ''' <summary>La liste des fichiers déposés. Rend le plus récent, ou 0.</summary>
    Private Function ChargerFichiers() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@TypeImport", Def.TypeImport))
            Dim ds As DataSet = ExecuteSQLds("s0772GetImportFichiers", p)
            Dim dt = ds.Tables(0)

            dt.Columns.Add("Lecture", GetType(String))
            For Each r As DataRow In dt.Rows
                Dim m = Txt(r("ModelUsed"))
                r("Lecture") = If(m = LectureDirecte, "lecture directe", If(m = "", "—", "IA"))
            Next

            gvFichiers.DataSource = dt
            gvFichiers.DataBind()
            pnlFichiers.Visible = dt.Rows.Count > 0

            Return If(dt.Rows.Count > 0, Convert.ToInt32(dt.Rows(0)("Id")), 0)
        Catch ex As Exception
            ShowErreur("Liste des fichiers : " & H(ex.Message))
            pnlFichiers.Visible = False
            Return 0
        End Try
    End Function

    ''' <summary>
    ''' Montre un fichier : d'où il vient, ce qu'on en a lu, et pour chaque
    ''' ligne ce qu'il en adviendra — créée, laissée parce qu'elle existe déjà,
    ''' écartée parce que le fichier la répète.
    ''' </summary>
    Private Sub Afficher(id As Integer)
        pnlResultat.Visible = False

        Dim ds As DataSet
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@ImportFileId", id))
            ds = ExecuteSQLds("s0773GetImportLignes", p)
        Catch ex As Exception
            FichierCourant = 0
            ShowErreur(H(ex.Message))
            Return
        End Try

        If ds Is Nothing OrElse ds.Tables.Count < 2 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        FichierCourant = id
        Dim r = ds.Tables(0).Rows(0)
        Dim lignes = ds.Tables(1)

        Dim nouveaux = Ent(r("Nouveaux"))
        Dim existants = Ent(r("Existants"))
        Dim doublons = Ent(r("Doublons"))
        Dim crees = Ent(r("Crees"))
        Dim ecartes = Ent(r("Ecartes"))
        Dim erreurs = Ent(r("Erreurs"))

        ' ── D'où il vient ───────────────────────────────────────────────────
        Dim modele = Txt(r("ModelUsed"))
        Dim quand = Convert.ToDateTime(r("UploadDate")).ToString("d MMMM yyyy 'à' HH:mm", Fr)
        Dim o As New StringBuilder("<p class='idn-origine'>« ")
        o.Append(H(Txt(r("OriginalName")))).Append(" », déposé le ").Append(H(quand)).Append(" — ")
        If modele = LectureDirecte Then
            o.Append("lecture directe.")
        ElseIf modele = "" Then
            o.Append("lecture inconnue.")
        Else
            o.Append("extrait par l'IA")
            If Not IsDBNull(r("EstimatedCostUsd")) Then
                o.Append(", coût estimé ").Append(Convert.ToDecimal(r("EstimatedCostUsd")).ToString("N4", Fr)).Append(" US$")
            End If
            o.Append(".")
        End If
        o.Append("</p>")
        litOrigine.Text = o.ToString()

        ' ── Les comptes ─────────────────────────────────────────────────────
        Dim c As New StringBuilder("<div class='idn-chips'>")
        c.Append("<span class='idn-chip'>").Append(Ent(r("Lignes"))).Append(" ligne(s)</span>")
        c.Append("<span class='idn-chip new'>").Append(nouveaux).Append(" à créer</span>")
        If existants > 0 Then c.Append("<span class='idn-chip ex'>").Append(existants).Append(" déjà dans l'application</span>")
        If doublons > 0 Then c.Append("<span class='idn-chip wa'>").Append(doublons).Append(" doublon(s) du fichier</span>")
        If crees > 0 Then c.Append("<span class='idn-chip ok'>").Append(crees).Append(" créé(s)</span>")
        If ecartes > 0 Then c.Append("<span class='idn-chip'>").Append(ecartes).Append(" écarté(s)</span>")
        If erreurs > 0 Then c.Append("<span class='idn-chip ko'>").Append(erreurs).Append(" en erreur</span>")
        c.Append("</div>")
        litChips.Text = c.ToString()

        litResTitre.Text = If(nouveaux > 0, "Ce qui a été lu — à vérifier avant de créer", "Ce qui a été lu")
        litLignes.Text = RendreLignes(lignes)

        ' ── La suite ────────────────────────────────────────────────────────
        btnCreer.Visible = nouveaux > 0
        If nouveaux > 0 Then
            btnCreer.Text = "✅ Créer " & If(nouveaux = 1, "le nouveau " & Def.Un, "les " & nouveaux & " " & Def.Nouveaux)
            btnCreer.OnClientClick = "if (!confirm('Créer " & nouveaux & " " & Def.Nouveaux &
                                     " dans l\'application ? Ce qui existe déjà ne sera pas touché.')) { return false; }"
        End If

        hlListe.Visible = crees > 0
        hlListe.NavigateUrl = Def.Liste
        hlListe.Text = "Voir vos " & Def.Des & " →"

        pnlResultat.Visible = True
    End Sub

    Private Function RendreLignes(lignes As DataTable) As String
        If lignes.Rows.Count = 0 Then Return "<p class='idn-origine'>Aucune ligne n'a été lue dans ce fichier.</p>"

        Dim sb As New StringBuilder("<div class='idn-tbl'><table class='idn-g'><thead><tr><th>Ligne</th><th>Nom</th>")
        If EstProduit Then
            sb.Append("<th>Description</th><th class='num'>Prix</th><th>Taxable</th>")
        Else
            sb.Append("<th>Contact</th><th>Courriel</th><th>Téléphone</th><th>Adresse</th><th>Taxes</th>")
        End If
        sb.Append("<th>Ce qu'il en adviendra</th></tr></thead><tbody>")

        For Each r As DataRow In lignes.Rows
            sb.Append("<tr><td>").Append(Ent(r("LineNumber"))).Append("</td>")
            sb.Append("<td><b>").Append(H(Txt(r("Name")))).Append("</b></td>")

            If EstProduit Then
                Dim d = Txt(r("Description"))
                If d.Length > 140 Then d = d.Substring(0, 140) & "…"
                sb.Append("<td>").Append(H(d)).Append("</td>")
                sb.Append("<td class='num'>")
                If Not IsDBNull(r("Price")) Then sb.Append(Convert.ToDecimal(r("Price")).ToString("N2", Fr)).Append(" $")
                sb.Append("</td><td>")
                sb.Append(If(IsDBNull(r("Taxable")), "—", If(Convert.ToBoolean(r("Taxable")), "Oui", "Non")))
                sb.Append("</td>")
            Else
                Dim adresse = String.Join(", ", New String() {
                    Txt(r("Address1")), Txt(r("Address2")), Txt(r("City")), Txt(r("Province")), Txt(r("PostalCode"))
                }.Where(Function(x) x <> ""))
                Dim taxes = String.Join(" · ", New String() {
                    If(Txt(r("TPS")) <> "", "TPS " & Txt(r("TPS")), ""),
                    If(Txt(r("TVQ")) <> "", "TVQ " & Txt(r("TVQ")), "")
                }.Where(Function(x) x <> ""))

                sb.Append("<td>").Append(H(Txt(r("Attention")))).Append("</td>")
                sb.Append("<td>").Append(H(Txt(r("Email")))).Append("</td>")
                sb.Append("<td>").Append(H(Txt(r("Phone")))).Append("</td>")
                sb.Append("<td>").Append(H(adresse)).Append("</td>")
                sb.Append("<td>").Append(H(taxes)).Append("</td>")
            End If

            sb.Append("<td>").Append(Verdict(r)).Append("</td></tr>")
        Next

        sb.Append("</tbody></table></div>")
        Return sb.ToString()
    End Function

    Private Function Verdict(r As DataRow) As String
        Select Case Txt(r("Status"))
            Case "Migrated" : Return Pastille("p-ok", "Créé")
            Case "Skipped" : Return Pastille("p-gr", "Écarté") & Detail(Txt(r("ErrorMessage")))
            Case "Error" : Return Pastille("p-ko", "Erreur") & Detail(Txt(r("ErrorMessage")))
        End Select

        If Not IsDBNull(r("ExistantId")) Then
            Dim sorte = Txt(r("ExistantType")).ToLowerInvariant()
            Return Pastille("p-ex", "Existe déjà") &
                   Detail("Déjà dans l'application" & If(sorte <> "", " (" & sorte & ")", "") & " : ne sera pas recréé.")
        End If

        If Ent(r("Doublon")) = 1 Then
            Return Pastille("p-wa", "Doublon du fichier") & Detail("Seule la première ligne de ce nom sera créée.")
        End If

        Return Pastille("p-new", "À créer")
    End Function

    Private Function Pastille(cls As String, texte As String) As String
        Return "<span class='idn-pill " & cls & "'>" & H(texte) & "</span>"
    End Function

    Private Function Detail(texte As String) As String
        If texte = "" Then Return ""
        Return "<span class='idn-det'>" & H(texte) & "</span>"
    End Function

#End Region

#Region "Ce qu'on montre avant de lire"

    ''' <summary>
    ''' Le tableau des colonnes, bâti sur la définition réelle : écrit à la
    ''' main, il finirait par mentir sur ce que l'écran cherche vraiment.
    ''' </summary>
    Private Function TableauColonnes() As String
        Dim sb As New StringBuilder()
        sb.Append("<table class='sd-coltbl'><thead><tr><th>Colonne</th><th>À quoi elle sert</th><th>En-têtes reconnus</th></tr></thead><tbody>")

        For Each c In Def.Colonnes
            sb.Append("<tr><td><b>").Append(H(c.Libelle)).Append("</b>")
            If c.Champ = "name" Then sb.Append("<span class='sd-req'>obligatoire</span>")
            sb.Append("</td><td>").Append(H(c.Description)).Append("</td><td class='sd-kw'>")
            sb.Append(H(String.Join(", ", c.MotsCles))).Append("</td></tr>")
        Next

        sb.Append("</tbody></table>")
        Return sb.ToString() &
            "<p class='sd-p'>L'ordre des colonnes n'a pas d'importance : elles sont reconnues par leur en-tête, " &
            "en français comme en anglais. Les lignes de titre avant l'en-tête, les totaux et le pied de page " &
            "sont écartés. Un fichier que rien de tout ça ne décrit se lit avec <b>Extraire avec l'IA</b>.</p>"
    End Function

    Private Function RendreApercu(l As Lecture) As String
        Dim sb As New StringBuilder()

        sb.Append("<p class='idn-origine'>En-tête trouvé à la ")
        sb.Append(If(l.LigneEntete = 0, "première ligne", (l.LigneEntete + 1) & "e ligne non vide"))
        sb.Append(", séparateur « ").Append(NomSeparateur(l.Separateur)).Append(" »")
        If l.Separateur <> ucSource.Separateur Then
            sb.Append(" — pas celui choisi, mais c'est celui qui fait apparaître les colonnes")
        End If
        sb.Append(". Voici les ").Append(l.Lignes.Count).Append(" premières lignes, telles qu'elles seront lues.</p>")

        sb.Append("<table class='idn-map'><thead><tr><th>Ce que nous cherchons</th><th>Colonne du fichier</th></tr></thead><tbody>")
        For Each c In Def.Colonnes
            sb.Append("<tr><td>").Append(H(c.Libelle)).Append("</td><td>")
            If l.Carte.ContainsKey(c.Champ) AndAlso l.Carte(c.Champ) < l.Entetes.Length Then
                sb.Append("<b>").Append(H(l.Entetes(l.Carte(c.Champ)).Trim().Trim(""""c))).Append("</b>")
            Else
                sb.Append("<span class='none'>absente</span>")
            End If
            sb.Append("</td></tr>")
        Next
        sb.Append("</tbody></table>")

        Dim presentes = Def.Colonnes.Where(Function(c) l.Carte.ContainsKey(c.Champ)).ToList()

        sb.Append("<div class='idn-tbl' style='margin-top:14px'><table class='idn-g'><thead><tr>")
        For Each c In presentes
            sb.Append("<th>").Append(H(c.Libelle)).Append("</th>")
        Next
        sb.Append("</tr></thead><tbody>")

        For Each o In l.Lignes
            sb.Append("<tr>")
            For Each c In presentes
                sb.Append("<td>").Append(H(Chaine(o(c.Champ)))).Append("</td>")
            Next
            sb.Append("</tr>")
        Next

        sb.Append("</tbody></table></div>")
        Return sb.ToString()
    End Function

    Private Shared Function NomSeparateur(c As Char) As String
        If c = ControlChars.Tab Then Return "tabulation"
        If c = ";"c Then Return "point-virgule"
        Return "virgule"
    End Function

#End Region

#Region "Outils"

    Private Sub Cacher()
        pnlSucces.Visible = False
        pnlAvert.Visible = False
        pnlErreur.Visible = False
        pnlApercu.Visible = False
    End Sub

    Private Sub ShowSucces(html As String)
        litSucces.Text = html
        pnlSucces.Visible = True
    End Sub

    Private Sub ShowAvert(html As String)
        litAvert.Text = html
        pnlAvert.Visible = True
    End Sub

    Private Sub ShowErreur(html As String)
        litErreur.Text = html
        pnlErreur.Visible = True
    End Sub

    Private Function H(s As String) As String
        Return Server.HtmlEncode(If(s, ""))
    End Function

    Private Shared Function Txt(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToString(v).Trim()
    End Function

    Private Shared Function Ent(v As Object) As Integer
        If v Is Nothing OrElse IsDBNull(v) Then Return 0
        Return Convert.ToInt32(v)
    End Function

    Private Shared Function Chaine(t As JToken) As String
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return ""
        Dim v = TryCast(t, JValue)
        If v IsNot Nothing Then Return Convert.ToString(v.Value, Inv).Trim()
        Return t.ToString().Trim()
    End Function

    Private Shared Function Tronquer(s As String, longueur As Integer) As String
        If s Is Nothing OrElse longueur <= 0 OrElse s.Length <= longueur Then Return s
        Return s.Substring(0, longueur)
    End Function

    Private Shared Function Cellule(c As String(), idx As Integer) As String
        If idx < 0 OrElse idx >= c.Length Then Return ""
        Return c(idx).Trim()
    End Function

    ''' <summary>
    ''' Un montant, quel que soit son format : « 1 234,56 », « 1,234.56 »,
    ''' « $107,449.98 », « (366.63) ». Le dernier séparateur est le décimal.
    ''' </summary>
    Private Shared Function LireMontant(brut As String) As Decimal?
        If String.IsNullOrWhiteSpace(brut) Then Return Nothing

        Dim v = brut.Replace("$", "").Replace(" ", "").Replace(ChrW(160), "").Trim()
        Dim negatif As Boolean = False

        If v.StartsWith("(") AndAlso v.EndsWith(")") Then
            negatif = True
            v = v.Trim("("c, ")"c)
        End If

        Dim dernierPoint = v.LastIndexOf("."c)
        Dim derniereVirgule = v.LastIndexOf(","c)

        If dernierPoint >= 0 AndAlso derniereVirgule >= 0 Then
            If derniereVirgule > dernierPoint Then
                v = v.Replace(".", "").Replace(",", ".")
            Else
                v = v.Replace(",", "")
            End If
        ElseIf derniereVirgule >= 0 Then
            v = v.Replace(",", ".")
        End If

        Dim d As Decimal
        If Not Decimal.TryParse(v, Globalization.NumberStyles.Any, Inv, d) Then Return Nothing

        Return If(negatif, -d, d)
    End Function

#End Region

End Class
