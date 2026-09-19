<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Accueil.aspx.vb" Inherits="Paie60Sec.Web.PagePresentation" %>
<!DOCTYPE html>
<html lang="<%= I18n.Langue %>">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>60secPaie — la paie du Québec, faite comme il faut</title>
    <meta name="description" content="Logiciel de paie pour les employeurs du Québec : retenues fédérales et provinciales, relevés T4 et RL-1, remises gouvernementales, dépôt direct et écritures au grand livre." />
    <link href="~/Content/site.css" rel="stylesheet" />
</head>
<body class="page-presentation">
<form runat="server">

    <%-- ============================================================ En-tête --%>
    <header class="pres-entete">
        <div class="pres-largeur pres-entete-contenu">
            <span class="logo">60sec<span translate="no">Paie</span></span>
            <div class="pres-entete-droite">
                <span class="langues"><asp:Literal ID="litLangues" runat="server" /></span>
                <asp:HyperLink ID="lnkEntree" runat="server" CssClass="bouton pres-bouton-contour" />
            </div>
        </div>
    </header>

    <%-- ============================================================ Héros --%>
    <section class="pres-heros">
        <div class="pres-largeur pres-heros-grille">

            <div class="pres-heros-texte">
                <p class="pres-surtitre">Paie canadienne, règles du Québec</p>
                <h1>Faire la paie ne devrait pas prendre l'après-midi.</h1>
                <p class="pres-promesse">
                    Vous entrez les heures. 60secPaie calcule les retenues, produit les talons,
                    prépare le dépôt direct, retient ce qui revient aux gouvernements et passe
                    l'écriture au grand livre. Vous vérifiez, vous confirmez.
                </p>
                <div class="pres-actions">
                    <asp:HyperLink ID="lnkAction" runat="server" CssClass="bouton pres-bouton-grand pres-bouton-clair" />
                    <a href="#ce-que-ca-fait" class="pres-lien-discret">Voir comment ça marche</a>
                </div>
                <p class="pres-note-heros">
                    Vous avez déjà un compte 60Sec ? C'est le même — rien à créer.
                </p>
            </div>

            <%-- Une maquette plutôt qu'une image : elle montre ce que l'outil produit
                 réellement, et elle reste lisible à l'impression comme au téléphone. --%>
            <div class="pres-heros-visuel" aria-hidden="true">
                <div class="maquette-talon">
                    <div class="maquette-entete">
                        <span class="maquette-titre">Talon de paie</span>
                        <span class="maquette-etiquette">Exemple</span>
                    </div>
                    <div class="maquette-employe">
                        <strong>Marie Gagnon</strong>
                        <span>Période du 1<sup>er</sup> au 14 juin · 70 h</span>
                    </div>
                    <table class="maquette-lignes">
                        <tr class="maquette-brut"><td>Salaire brut</td><td>1 500,00</td></tr>
                        <tr><td>RRQ</td><td>−89,28</td></tr>
                        <tr><td>RQAP</td><td>−7,41</td></tr>
                        <tr><td>Assurance-emploi</td><td>−19,65</td></tr>
                        <tr><td>Impôt fédéral</td><td>−139,50</td></tr>
                        <tr><td>Impôt du Québec</td><td>−165,20</td></tr>
                    </table>
                    <div class="maquette-net">
                        <span>Net à payer</span>
                        <strong>1 078,96 $</strong>
                    </div>
                    <div class="maquette-pied">Dépôt direct · 14 juin</div>
                </div>
            </div>

        </div>
    </section>

    <%-- ============================================================ Les 4 étapes --%>
    <section id="ce-que-ca-fait" class="pres-section">
        <div class="pres-largeur">
            <h2 class="pres-titre-section">Une paie, quatre étapes</h2>
            <p class="pres-intro">
                L'assistant ne vous laisse pas avancer avec un chiffre qui ne tient pas debout.
                Rien n'est transmis tant que vous n'avez pas confirmé.
            </p>

            <ol class="pres-etapes">
                <li>
                    <span class="pres-numero">1</span>
                    <h3>La période</h3>
                    <p>Hebdomadaire, aux deux semaines, bimensuelle ou mensuelle. La date de paie fixe les taux à appliquer.</p>
                </li>
                <li>
                    <span class="pres-numero">2</span>
                    <h3>La saisie</h3>
                    <p>Heures, salaires, primes, vacances. Les éléments récurrents de chaque employé sont déjà là.</p>
                </li>
                <li>
                    <span class="pres-numero">3</span>
                    <h3>La révision</h3>
                    <p>Le détail employé par employé, retenue par retenue. C'est ici qu'on corrige, pas après.</p>
                </li>
                <li>
                    <span class="pres-numero">4</span>
                    <h3>La confirmation</h3>
                    <p>La paie est scellée : talons, écritures comptables et montants à remettre aux gouvernements.</p>
                </li>
            </ol>
        </div>
    </section>

    <%-- ============================================================ Ce que ça produit --%>
    <section class="pres-section pres-section-pale">
        <div class="pres-largeur">
            <h2 class="pres-titre-section">Ce qui sort de chaque paie</h2>
            <p class="pres-intro">
                Le calcul n'est que la moitié du travail. L'autre moitié, ce sont les documents
                que réclament vos employés, vos gouvernements et votre comptabilité.
            </p>

            <div class="pres-grille">
                <article class="pres-carte">
                    <h3>Talons de paie</h3>
                    <p>Imprimables ou envoyés par courriel, dans la langue de l'employé.</p>
                </article>
                <article class="pres-carte">
                    <h3>Dépôt direct</h3>
                    <p>Le fichier des virements, prêt pour votre institution financière.</p>
                </article>
                <article class="pres-carte">
                    <h3>Remises gouvernementales</h3>
                    <p>Ce que vous devez à l'ARC et à Revenu Québec, avec l'historique des versements.</p>
                </article>
                <article class="pres-carte">
                    <h3>T4 et RL-1</h3>
                    <p>Les feuillets de fin d'année, bâtis à partir des cumulatifs de l'employé.</p>
                </article>
                <article class="pres-carte">
                    <h3>Écritures comptables</h3>
                    <p>Le grand livre reçoit la paie selon le plan comptable que vous avez choisi.</p>
                </article>
                <article class="pres-carte">
                    <h3>CNESST</h3>
                    <p>Les masses salariales assurables, par unité de classification.</p>
                </article>
            </div>
        </div>
    </section>

    <%-- ============================================================ Les sources --%>
    <section class="pres-section">
        <div class="pres-largeur pres-deux-colonnes">
            <div>
                <h2 class="pres-titre-section">Les taux viennent d'où ils doivent venir</h2>
                <p>
                    Les retenues à la source ne s'improvisent pas. 60secPaie applique les tables
                    publiées par les administrations elles-mêmes, et vous dit toujours quelle
                    année de taux a servi au calcul.
                </p>
                <ul class="pres-liste">
                    <li><strong>T4127</strong> — Formules pour le calcul informatisé des retenues sur la paie <span class="pres-source">Agence du revenu du Canada</span></li>
                    <li><strong>TP-1015.F</strong> — Table des retenues à la source d'impôt du Québec <span class="pres-source">Revenu Québec</span></li>
                    <li><strong>RRQ, RQAP, AE, FSS</strong> — cotisations de l'employé et de l'employeur</li>
                    <li><strong>CNESST</strong> — taux par unité, selon votre classification</li>
                </ul>
                <p class="pres-avertissement">
                    Un logiciel ne remplace pas votre jugement : vérifiez toujours une paie avant
                    de la confirmer.
                </p>
            </div>

            <div class="pres-encadre">
                <h3>Pour l'employeur</h3>
                <p>Une compagnie, ses employés, ses paies. Vous ouvrez, vous faites, vous fermez.</p>
                <h3>Pour le comptable</h3>
                <p>
                    Plusieurs compagnies sous le même compte, et un sélecteur pour passer de
                    l'une à l'autre sans se reconnecter.
                </p>
                <h3>En trois langues</h3>
                <p>
                    Français, anglais et espagnol — y compris les talons, que chaque employé
                    reçoit dans sa langue.
                </p>
            </div>
        </div>
    </section>

    <%-- ============================================================ Appel final --%>
    <section class="pres-appel">
        <div class="pres-largeur">
            <h2>Votre prochaine paie, sans le mal de tête</h2>
            <p>Connectez-vous avec votre compte 60Sec et lancez votre première période.</p>
            <asp:HyperLink ID="lnkAppel" runat="server" CssClass="bouton pres-bouton-grand pres-bouton-clair" />
        </div>
    </section>

    <footer class="pres-pied">
        <div class="pres-largeur">
            60sec<span translate="no">Paie</span> — un service de 60Sec.
            Les montants calculés demeurent sous la responsabilité de l'employeur.
        </div>
    </footer>

</form>
</body>
</html>
