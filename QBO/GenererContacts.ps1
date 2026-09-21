# =============================================================================
# Génère un fichier de contacts fictifs prêt à importer dans QuickBooks Online,
# clients ou fournisseurs.
#
#   .\GenererContacts.ps1 -Type Clients
#   .\GenererContacts.ps1 -Type Fournisseurs -Nombre 200
#
# Ce qui rend les données crédibles, ce n'est pas le hasard : c'est la
# COHÉRENCE. Un contact de Rimouski doit avoir un code postal en G, un indicatif
# 418 ou 581, une rue qui s'appelle « rue » et non « Street ». Un générateur qui
# tire chaque colonne indépendamment produit des entreprises qui n'existent
# nulle part — et l'import ne sert alors qu'à compter des lignes.
#
# DEUX CHOIX DE SÛRETÉ, délibérés :
#   · les courriels sont en .example.com, domaine réservé par l'IANA à la
#     documentation et jamais routable — une facture partie par erreur de QBO
#     n'atteindra aucun inconnu ;
#   · les téléphones sont en 555-01xx, plage réservée à la fiction, avec le vrai
#     indicatif régional pour garder le repère géographique.
# Aucun numéro d'entreprise (NEQ, BN) n'est produit : un identifiant à neuf
# chiffres tiré au hasard peut être celui d'une société réelle.
# =============================================================================

[CmdletBinding()]
param(
  [ValidateSet('Clients','Fournisseurs')] [string] $Type = 'Clients',
  [int] $Nombre = 200,
  [string] $Dossier = 'C:\MesSources\MngConsul\QBO'
)

$ErrorActionPreference = 'Stop'

# --- Les régions, avec ce qui va ensemble -------------------------------------
# prefixes  : premières lettres de code postal réellement attribuées à la région
# indicatifs: indicatifs régionaux en service
# langue    : fr = odonymes et prénoms français, en = anglais
$Regions = @(
  @{ prov='NL'; villes=@('St. John''s','Corner Brook','Mount Pearl','Gander');            prefixes=@('A'); indicatifs=@('709'); langue='en' },
  @{ prov='NS'; villes=@('Halifax','Dartmouth','Sydney','Truro');                          prefixes=@('B'); indicatifs=@('902','782'); langue='en' },
  @{ prov='PE'; villes=@('Charlottetown','Summerside');                                    prefixes=@('C'); indicatifs=@('902','782'); langue='en' },
  @{ prov='NB'; villes=@('Moncton','Saint John','Fredericton','Dieppe','Bathurst');         prefixes=@('E'); indicatifs=@('506'); langue='fr' },
  @{ prov='QC'; villes=@('Montréal','Laval','Longueuil','Brossard');                        prefixes=@('H','J'); indicatifs=@('514','438','450','579'); langue='fr' },
  @{ prov='QC'; villes=@('Québec','Lévis','Saguenay','Rimouski','Trois-Rivières');          prefixes=@('G'); indicatifs=@('418','581','819'); langue='fr' },
  @{ prov='QC'; villes=@('Gatineau','Sherbrooke','Drummondville','Rouyn-Noranda');          prefixes=@('J'); indicatifs=@('819','873','450'); langue='fr' },
  @{ prov='ON'; villes=@('Toronto','Scarborough','Etobicoke','North York');                 prefixes=@('M'); indicatifs=@('416','647','437'); langue='en' },
  @{ prov='ON'; villes=@('Mississauga','Brampton','Hamilton','Oakville','Barrie');          prefixes=@('L'); indicatifs=@('905','289','365'); langue='en' },
  @{ prov='ON'; villes=@('Ottawa','Kingston','Belleville','Cornwall');                      prefixes=@('K'); indicatifs=@('613','343'); langue='en' },
  @{ prov='ON'; villes=@('London','Windsor','Kitchener','Waterloo','Guelph');               prefixes=@('N'); indicatifs=@('519','226','548'); langue='en' },
  @{ prov='ON'; villes=@('Sudbury','Thunder Bay','Sault Ste. Marie','North Bay');           prefixes=@('P'); indicatifs=@('705','249','807'); langue='en' },
  @{ prov='MB'; villes=@('Winnipeg','Brandon','Steinbach');                                 prefixes=@('R'); indicatifs=@('204','431'); langue='en' },
  @{ prov='SK'; villes=@('Saskatoon','Regina','Prince Albert','Moose Jaw');                 prefixes=@('S'); indicatifs=@('306','639'); langue='en' },
  @{ prov='AB'; villes=@('Calgary','Edmonton','Red Deer','Lethbridge','Fort McMurray');     prefixes=@('T'); indicatifs=@('403','587','780','825'); langue='en' },
  @{ prov='BC'; villes=@('Vancouver','Surrey','Burnaby','Richmond','Victoria','Kelowna');   prefixes=@('V'); indicatifs=@('604','778','236','250'); langue='en' },
  @{ prov='YT'; villes=@('Whitehorse');                                                     prefixes=@('Y'); indicatifs=@('867'); langue='en' },
  @{ prov='NT'; villes=@('Yellowknife','Hay River');                                        prefixes=@('X'); indicatifs=@('867'); langue='en' },
  @{ prov='NU'; villes=@('Iqaluit','Rankin Inlet');                                         prefixes=@('X'); indicatifs=@('867'); langue='en' }
)

# Le Canada n'est pas réparti uniformément : l'Ontario et le Québec doivent
# dominer, sinon la liste ne ressemble à aucun carnet d'adresses réel.
$Poids = @(2,4,1,3, 10,6,5, 9,8,6,5,3, 4,3, 9,9, 1,1,1)

# --- Vocabulaire ---------------------------------------------------------------
# Clients et fournisseurs ne portent pas les mêmes noms : on achète à des
# grossistes et à des manufacturiers, on vend à des cliniques et à des ateliers.
# Deux vocabulaires distincts, sinon les deux listes se ressemblent trop.
$Vocab = @{
  Clients = @{
    teteFr  = @('Groupe','Les Entreprises','Construction','Ateliers','Solutions','Technologies','Clinique','Cabinet','Boulangerie','Épicerie','Quincaillerie','Menuiserie','Plomberie','Toiture','Paysagement','Garage','Studio','Pharmacie','Restaurant','Services')
    teteEn  = @('Northern','Maple','Summit','Riverstone','Cedar','Granite','Harbour','Prairie','Lakeside','Ironwood','Blackrock','Westbridge','Redwood','Stonebridge','Clearwater','Highland','Timberline','Beacon','Copper Creek','Silverpine')
    metierFr= @('Électrique','Mécanique','Dentaire','Vétérinaire','Alimentaire','Numérique','Sportif','Familial','Urbain','Régional')
    metierEn= @('Roofing','Consulting','Electrical','Automotive','Outfitters','Foods','Systems','Contracting','Mechanical','Landscaping','Dental','Veterinary','Fitness','Bakery','Optical')
  }
  Fournisseurs = @{
    teteFr  = @('Distribution','Manufacture','Grossiste','Fonderie','Papeterie','Métaux','Emballages','Produits','Matériaux','Approvisionnement','Fournitures','Aciers','Plastiques','Textiles','Transport','Entrepôts','Lubrifiants','Outillage','Peintures','Câbles')
    teteEn  = @('Continental','Dominion','Atlantic','Pacific','Meridian','Cascade','Frontier','Keystone','Vanguard','Sentinel','Bluewater','Great Lakes','Trans-Canada','Northgate','Sterling','Pioneer','Apex','Titan','Crestline','Ridgeway')
    metierFr= @('Industriels','du Nord','Métalliques','Sanitaires','de Bureau','Électriques','Alimentaires','Forestiers','Chimiques','d''Emballage')
    metierEn= @('Wholesale','Supply Co.','Industries','Distributors','Manufacturing','Freight','Packaging','Fasteners','Abrasives','Hydraulics','Bearings','Adhesives','Lumber','Steel','Chemicals')
  }
}

$QueueFr = @('inc.','enr.','ltée','et Fils inc.','du Nord inc.','Québec inc.','Canada inc.')
$QueueEn = @('Inc.','Ltd.','Corp.','Group Inc.','Holdings Ltd.','& Sons Ltd.','Canada Inc.')

$PrenomFr = @('Marie','Pierre','Sophie','Jean','Isabelle','Luc','Nathalie','François','Julie','Martin','Catherine','Éric','Chantal','Sylvain','Geneviève','Mathieu','Caroline','Denis','Josée','Simon')
$NomFr = @('Tremblay','Gagnon','Roy','Côté','Bouchard','Gauthier','Morin','Lavoie','Fortin','Ouellet','Pelletier','Bélanger','Lévesque','Bergeron','Girard','Nadeau','Caron','Cloutier','Poirier','Dubé')
$PrenomEn = @('James','Sarah','Michael','Emily','David','Jessica','Robert','Laura','Daniel','Amanda','Kevin','Rachel','Brian','Megan','Andrew','Nicole','Steven','Hannah','Jason','Karen')
$NomEn = @('Smith','Brown','Wilson','Taylor','Campbell','MacDonald','Anderson','Thompson','Reid','Murray','Fraser','Stewart','Clarke','Hughes','Bennett','Patel','Singh','Nguyen','Chen','Kowalski')

# Les fournisseurs siègent en zone industrielle, les clients sur rue commerçante.
$RueFr = @{
  Clients      = @('rue Principale','avenue du Parc','boulevard Laurier','rue Notre-Dame','chemin Saint-Louis','rue Sainte-Catherine','avenue Cartier','boulevard Taschereau','rue de l''Église','avenue des Pins','rue Wellington','rue Saint-Jean')
  Fournisseurs = @('boulevard Industriel','rue de l''Industrie','avenue Manufacturiers','boulevard des Entreprises','rue du Parc-Industriel','chemin du Tremblay','boulevard Hymus','rue Cousineau','avenue Marien','boulevard Dagenais')
}
$RueEn = @{
  Clients      = @('Main Street','King Street','Queen Street West','Bay Street','Portage Avenue','Jasper Avenue','Granville Street','Water Street','Yonge Street','Broadway','Albert Street','Robson Street')
  Fournisseurs = @('Industrial Drive','Commerce Court','Logistics Way','Foundry Road','Enterprise Boulevard','Dixie Road','Steeles Avenue East','Kennedy Road','Burnhamthorpe Road','Airport Road')
}

# Les conditions d'un fournisseur sont plus serrées que celles d'un client.
$Conditions = @{
  Clients      = @('Net 30','Net 30','Net 30','Net 15','Due on receipt','Net 60')
  Fournisseurs = @('Net 30','Net 30','Net 15','Net 15','Due on receipt','2% 10 Net 30')
}

# --- Outils --------------------------------------------------------------------
# Les lettres écartées (D, F, I, O, Q, U) ne sont jamais attribuées par Postes
# Canada : elles se confondent avec des chiffres à la lecture optique.
$LettresPostales = 'ABCEGHJKLMNPRSTVWXYZ'.ToCharArray()

function Tirer($liste) { $liste[(Get-Random -Maximum $liste.Count)] }

function CodePostal($prefixe) {
  $l = { $LettresPostales[(Get-Random -Maximum $LettresPostales.Count)] }
  "{0}{1}{2} {3}{4}{5}" -f $prefixe, (Get-Random -Maximum 10), (& $l),
                           (Get-Random -Maximum 10), (& $l), (Get-Random -Maximum 10)
}

function Slug($texte) {
  $t = $texte.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $t.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne 'NonSpacingMark') { [void]$sb.Append($c) }
  }
  ($sb.ToString() -replace "[^A-Za-z0-9]+", "-").Trim('-').ToLowerInvariant()
}

$v = $Vocab[$Type]
$Urne = @()
for ($i = 0; $i -lt $Regions.Count; $i++) { for ($k = 0; $k -lt $Poids[$i]; $k++) { $Urne += $i } }

# --- Génération ----------------------------------------------------------------
$vus = New-Object 'System.Collections.Generic.HashSet[string]'
$contacts = New-Object 'System.Collections.Generic.List[object]'

# « Partout au Canada » veut dire partout : avec des poids seuls, l'Île-du-Prince-
# Édouard et le Yukon tombent à zéro une fois sur deux. On sème donc une région à
# la fois avant de remplir le reste au prorata démographique.
$semis = 0

while ($contacts.Count -lt $Nombre) {
  if ($semis -lt $Regions.Count) { $r = $Regions[$semis]; $semis++ }
  else { $r = $Regions[(Tirer $Urne)] }

  $fr = ($r.langue -eq 'fr')

  if ($fr) {
    $nom = if ((Get-Random -Maximum 2) -eq 0) { "{0} {1} {2}" -f (Tirer $v.teteFr), (Tirer $NomFr), (Tirer $QueueFr) }
           else                                { "{0} {1} {2}" -f (Tirer $v.teteFr), (Tirer $v.metierFr), (Tirer $QueueFr) }
  } else {
    $nom = if ((Get-Random -Maximum 2) -eq 0) { "{0} {1} {2}" -f (Tirer $v.teteEn), (Tirer $v.metierEn), (Tirer $QueueEn) }
           else                                { "{0} {1} {2}" -f (Tirer $NomEn), (Tirer $v.metierEn), (Tirer $QueueEn) }
  }

  if (-not $vus.Add($nom)) {
    # Le semis doit repasser par cette région, sinon elle serait sautée.
    if ($semis -gt 0 -and $semis -le $Regions.Count -and $r -eq $Regions[$semis - 1]) { $semis-- }
    continue   # QBO refuse deux contacts de même nom
  }

  $prenom  = if ($fr) { Tirer $PrenomFr } else { Tirer $PrenomEn }
  $famille = if ($fr) { Tirer $NomFr } else { Tirer $NomEn }
  $ville   = Tirer $r.villes
  $ind     = Tirer $r.indicatifs

  $domaine = (Slug $nom) + ".example.com"
  if ($domaine.Length -gt 60) { $domaine = $domaine.Substring(0, 48).Trim('-') + ".example.com" }

  $civique = Get-Random -Minimum 15 -Maximum 4800
  $rue = if ($fr) { Tirer $RueFr[$Type] } else { Tirer $RueEn[$Type] }
  $suite = if ((Get-Random -Maximum 4) -eq 0) { ", bureau " + (Get-Random -Minimum 100 -Maximum 950) } else { "" }

  $mobile = ""
  if ((Get-Random -Maximum 3) -eq 0) { $mobile = "({0}) 555-{1:0000}" -f $ind, (Get-Random -Minimum 100 -Maximum 200) }

  $ligne = [ordered]@{
    'Name'                = $nom
    'Company'             = $nom
    'First Name'          = $prenom
    'Last Name'           = $famille
    'Email'               = "{0}.{1}@{2}" -f (Slug $prenom), (Slug $famille), $domaine
    'Phone'               = "({0}) 555-{1:0000}" -f $ind, (Get-Random -Minimum 100 -Maximum 200)
    'Mobile'              = $mobile
    'Website'             = "https://www." + $domaine
    'Billing Street'      = "$civique $rue$suite"
    'Billing City'        = $ville
    'Billing Province'    = $r.prov
    'Billing Postal Code' = CodePostal (Tirer $r.prefixes)
    'Billing Country'     = 'Canada'
    'Terms'               = Tirer $Conditions[$Type]
  }

  # Propre au fournisseur : le numéro de compte que VOUS avez chez lui, et le nom
  # à imprimer sur le chèque. Aucun numéro d'entreprise : voir l'en-tête.
  if ($Type -eq 'Fournisseurs') {
    $ligne['Account No.']        = "{0}-{1:00000}" -f (Slug $nom).Substring(0, [Math]::Min(3, (Slug $nom).Length)).ToUpperInvariant(), (Get-Random -Minimum 1000 -Maximum 99999)
    $ligne['Print on Cheque As'] = $nom
  }

  $ligne['Notes'] = if ($fr) { "$Type — jeu d'essai" } else { "$Type - test data" }

  $contacts.Add([pscustomobject]$ligne)
}

# --- Écriture -------------------------------------------------------------------
if (-not (Test-Path $Dossier)) { New-Item -ItemType Directory -Path $Dossier | Out-Null }
$nomFichier = if ($Type -eq 'Clients') { 'clients-qbo-200.csv' } else { 'fournisseurs-qbo-200.csv' }
$chemin = Join-Path $Dossier $nomFichier

# BOM UTF-8 : Excel affiche alors correctement « Montréal » et « Trois-Rivières ».
[IO.File]::WriteAllLines($chemin, ($contacts | ConvertTo-Csv -NoTypeInformation), (New-Object Text.UTF8Encoding($true)))

"$chemin  —  $($contacts.Count) $($Type.ToLowerInvariant())"
