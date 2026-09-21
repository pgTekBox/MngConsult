# Courriel à Dream Payments — 16 septembre 2026

Rien n'a été envoyé. Version refaite après lecture de la documentation officielle
(docs.dreampayments.com) : les questions déjà résolues par la doc ont été
retirées, celles qui restent sont devenues beaucoup plus précises.

Le texte anglais est celui à transmettre ; la version française suit, pour
relecture. Joindre `dream-log-en.txt`.

---

## English

**Subject:** InsureTech API — multi-payer model, payer onboarding, and G00021

Hello,

At 60sec we are integrating the InsureTech API into our accounting application
(MngConsul), so that our subscribers can pay their suppliers by EFT. We now have
access to the developer portal, and the documentation answered most of our
questions. Three remain, and the first one blocks us.

Sandbox context: client ID `3osp12in…hbk1`, tenant `MCPUSSB01`,
legal entity `MCPUSSB0100037` ("J.P. Morgan Limited DDA Payment\*\*\*\*\*\*\*1000").

### 1. Blocking: G00021 "Invalid state. Multiple payers exist"

`POST /payees/add` and `POST /payments/add` both return HTTP 500 with that code.
**It does not appear on your Error Codes page** — the list goes from `G00015`
straight to `GIP001`.

Everything else we have tried works: `POST /payees/{payeeId}/accounts` attached a
bank account (`a896565a4440473d80db42f418f293b4`, status ACTIVE) to the payee your
team created (`4eb6229938b14308abe4bddbc42c0b48`); the documented searches
(`POST /payees`, `POST /payeeUsers`) and `POST /queryRecords` all answer normally.

To resolve the payer we tried, all returning G00021:

- `legalEntity` = `MCPUSSB0100037`;
- `legalEntityLabel` = the exact label returned by `queryRecords`
  (`databaseId: PcoNumber`), alone and together with `legalEntity`;
- `legalEntityLabel` = `60Sec`, the `clientBusinessName` shown on payments;
- request headers `X-Payer-Id`, `X-Legal-Entity`, `X-Tenant-Id` and `legalEntity`;
- on `/payees/add`, also in the body root and inside `payeeAccountInfo`.

**What is this state, and how do we resolve it?**

### 2. Does your model support several payers?

Your documentation describes a single partner — an insurer — with its own funding
accounts. Our model is different: **each subscriber to our platform is a separate
business, paying its own suppliers with its own funds.**

A concrete example: a new subscriber, ABN001, signs up to our application and has
to pay its supplier F001. The funds are ABN001's, the supplier is ABN001's, and
the invoice is in ABN001's books. 60sec provides the software, not the money.

Can one partner have several payers? If so, how is the payer designated on each
call? And how is a new payer provisioned? We found no API for it, and we
understand `MCPUSSB0100037` was created by your team.

We are planning for several hundred subscribers, then a few thousand. We are
therefore trying to understand how a payer is onboarded at that scale.

Is there an onboarding API, or a hosted onboarding page, that would let us collect
a subscriber's details and pass them to you? That is the mechanism offered by
Stripe Connect and Square, which we already integrate. If a KYB check is required,
can it go through that same channel?

If onboarding goes through your teams, could you describe the process, the usual
lead time for one subscriber, and what each of them has to provide or sign?

### 3. Funding

From `queryRecords` (`PcoNumber`) we understand that `legalEntity` identifies a
J.P. Morgan DDA account, and that this account is the source of funds. Could you
confirm, and tell us:

- whose account is debited when a subscriber pays a supplier, and when?
- how is such an account registered for a new payer?

Our subscribers enter their banking details in our application. We need to know
what to collect, what to transmit to you, and what to tell them about timing.

### 4. Three details

- **Interac method.** The enum lists `JPM_ETRAN`, but the payment your team
  created (`f862db561e2d4034ab404813a1290505`) carries
  `allowablePaymentMethods: ["JPM_ET"]`. Which value should we send?
- **Bank account identifier.** `POST /payees/{id}/accounts` returns
  `bankAccountId`, while `GET /payees/{id}/accounts` returns the same value under
  `genAccountDbId`. Is that intentional?
- **Bank branch validation.** Invented numbers are rejected with `BK0037` ("bank
  branch is not found") or `BK0036` ("bank number provided is incorrect"). Is
  there a dictionary or an endpoint to validate an institution and transit number
  before submitting, so we can flag the error while the supplier is still typing?

### 5. Access

- Could we have access to the **Payee Portal** and the **Operations Portal**
  mentioned in the documentation? Seeing how payers and payees are managed there
  would probably answer several of the questions above.
- What do you need from us to obtain **production credentials**, and which token
  URL and API base apply in production? The `openapi.json` we were given lists
  `https://paymenttech-dreampayments-com.auth.us-east-1.amazoncognito.com`, which
  does not resolve in DNS. We use
  `https://partner-userpool-test-insuretech.auth.us-east-1.amazoncognito.com/oauth2/token`
  and `https://fapi-test-insuretechv2.npe.dreampayments.com/v1`, with no
  `/platform` prefix.

A full request/response log is attached. We are ready to test any change as soon
as you make it.

Best regards,

---

## Français

**Objet :** API InsureTech — modèle multi-payeurs, inscription d'un payeur et G00021

Bonjour,

Chez 60sec, nous intégrons l'API InsureTech à notre application comptable
(MngConsul), afin que nos abonnés puissent payer leurs fournisseurs par virement
bancaire. Nous avons maintenant accès au portail développeur, et la documentation
a répondu à la plupart de nos questions. Il en reste trois, et la première nous
bloque.

Contexte du bac à sable : identifiant client `3osp12in…hbk1`,
locataire `MCPUSSB01`, entité légale `MCPUSSB0100037`
(« J.P. Morgan Limited DDA Payment\*\*\*\*\*\*\*1000 »).

### 1. Blocage : G00021 « Invalid state. Multiple payers exist »

`POST /payees/add` et `POST /payments/add` renvoient tous deux un HTTP 500 avec ce
code. **Il ne figure pas dans votre page des codes d'erreur** — la liste passe de
`G00015` directement à `GIP001`.

Tout le reste de ce que nous avons essayé fonctionne :
`POST /payees/{payeeId}/accounts` a rattaché un compte bancaire
(`a896565a4440473d80db42f418f293b4`, statut ACTIVE) au bénéficiaire créé par votre
équipe (`4eb6229938b14308abe4bddbc42c0b48`) ; les recherches documentées
(`POST /payees`, `POST /payeeUsers`) et `POST /queryRecords` répondent normalement.

Pour désigner le payeur, nous avons essayé — tout renvoie G00021 :

- `legalEntity` = `MCPUSSB0100037` ;
- `legalEntityLabel` = le libellé exact rendu par `queryRecords`
  (`databaseId: PcoNumber`), seul puis combiné avec `legalEntity` ;
- `legalEntityLabel` = `60Sec`, le `clientBusinessName` affiché sur les paiements ;
- les en-têtes `X-Payer-Id`, `X-Legal-Entity`, `X-Tenant-Id` et `legalEntity` ;
- sur `/payees/add`, aussi dans la racine du corps et dans `payeeAccountInfo`.

**Qu'est-ce que cet état, et comment le résoudre ?**

### 2. Votre modèle admet-il plusieurs payeurs ?

Votre documentation décrit un partenaire unique — un assureur — avec ses propres
comptes sources. Notre modèle est différent : **chaque abonné de notre plateforme
est une entreprise distincte, qui paie ses propres fournisseurs avec ses propres
fonds.**

Un exemple concret : un nouvel abonné, ABN001, s'inscrit à notre application et
doit payer son fournisseur F001. Les fonds sont ceux de ABN001, le fournisseur est
celui de ABN001, et la facture est dans les livres de ABN001. 60sec fournit le
logiciel, pas l'argent.

Un partenaire peut-il avoir plusieurs payeurs ? Si oui, comment désigne-t-on le
payeur à chaque appel ? Et comment inscrit-on un nouveau payeur ? Nous n'avons
trouvé aucune API pour cela, et nous comprenons que `MCPUSSB0100037` a été créé
par votre équipe.

Nous prévoyons plusieurs centaines d'abonnés, puis quelques milliers. Nous
cherchons donc à comprendre comment l'inscription d'un payeur se fait à cette
échelle.

Existe-t-il une API d'inscription, ou une page d'inscription hébergée, qui nous
permettrait de recueillir les informations de l'abonné et de vous les transmettre ?
C'est le mécanisme qu'offrent Stripe Connect et Square, que nous intégrons déjà.
Si une vérification d'entreprise (KYB) est requise, peut-elle passer par ce canal ?

Si l'inscription passe par vos équipes, pouvez-vous décrire le processus, le délai
habituel pour un abonné, et ce que chacun doit fournir ou signer ?

### 3. Financement

D'après `queryRecords` (`PcoNumber`), nous comprenons que `legalEntity` identifie
un compte DDA chez J.P. Morgan, et que ce compte est la source des fonds.
Pouvez-vous le confirmer et nous préciser :

- quel compte est débité lorsqu'un abonné paie un fournisseur, et quand ?
- comment un tel compte est-il enregistré pour un nouveau payeur ?

Nos abonnés saisissent leurs coordonnées bancaires dans notre application. Nous
devons savoir quoi recueillir, quoi vous transmettre, et quels délais leur
annoncer.

### 4. Trois détails

- **Méthode Interac.** L'énumération indique `JPM_ETRAN`, mais le paiement créé
  par votre équipe (`f862db561e2d4034ab404813a1290505`) porte
  `allowablePaymentMethods: ["JPM_ET"]`. Quelle valeur devons-nous envoyer ?
- **Identifiant du compte bancaire.** `POST /payees/{id}/accounts` renvoie
  `bankAccountId`, tandis que `GET /payees/{id}/accounts` renvoie la même valeur
  sous `genAccountDbId`. Est-ce voulu ?
- **Validation de la succursale.** Des numéros inventés sont refusés par `BK0037`
  (« bank branch is not found ») ou `BK0036` (« bank number provided is
  incorrect »). Existe-t-il un dictionnaire ou un appel permettant de valider un
  couple institution/transit avant l'envoi, afin de signaler l'erreur pendant que
  le fournisseur saisit encore ?

### 5. Accès

- Pourrions-nous obtenir un accès au **Payee Portal** et à l'**Operations Portal**
  mentionnés dans la documentation ? Voir comment les payeurs et les bénéficiaires
  y sont gérés répondrait sans doute à plusieurs des questions ci-dessus.
- Que vous faut-il de notre part pour obtenir des **identifiants de production**,
  et quelles URL de jeton et base d'API s'appliquent en production ?
  L'`openapi.json` qui nous a été fourni indique
  `https://paymenttech-dreampayments-com.auth.us-east-1.amazoncognito.com`, qui ne
  se résout pas dans le DNS. Nous utilisons
  `https://partner-userpool-test-insuretech.auth.us-east-1.amazoncognito.com/oauth2/token`
  et `https://fapi-test-insuretechv2.npe.dreampayments.com/v1`, sans préfixe
  `/platform`.

Le journal complet des requêtes et des réponses est joint. Nous sommes prêts à
tester tout changement dès que vous l'aurez fait.

Cordialement,
