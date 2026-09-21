# Dream Payments POC — paying a supplier by EFT

A small Windows application (VB.NET, .NET 8, WinForms) that reproduces one
thing: **a MngConsul subscriber pays one of its suppliers by EFT**, through the
Dream Payments InsureTech API, showing in a log every request sent and every
response received.

On the website that is a single click on a supplier invoice. Behind it are four
chained calls, so the first tab here is that same click — one button, one set of
fields, the four calls in order, stopping at the first one that fails:

```
create the payee  →  attach its bank account  →  create the payment  →  accept it
   payeeId              bankAccountId               paymentId          money moves
```

It serves two purposes:

1. **Unblocking the ERP integration.** The `clsDreamPayments.vb` connector in
   MngConsul is held up by the `G00021 Multiple payers exist` error. This POC
   sends the same JSON bodies, but a setting can be changed and the whole
   payment retried in two seconds — and the log copied out for Dream.
2. **Trying the API without touching the website.** No database, no session,
   nothing to deploy: one executable and one settings file.

The screen is in English, and so is the main log, so the results can be sent to
Dream as they are. A second log, in French, runs alongside it for reading.

## Running it

```bash
dotnet run --project "C:\MesSources\MngConsul\DreamPaiement\POC\DreamPoc.vbproj"
```

Or open `DreamPoc.vbproj` in Visual Studio and run.

**There is nothing to type.** The sandbox client ID and secret are hard-coded in
`Settings.vb` (constants `SandboxClientId` and `SandboxClientSecret`, the same
values as the `DreamPayments.ClientId` and `DreamPayments.ClientSecret` keys in
the MngConsul `Web.config`): start it, press a button, it goes out. Credentials
typed in and saved take precedence over those defaults.

> These are real credentials, able to issue payments in the Dream sandbox.
> `Settings.vb` is excluded from the repository, and the constants must be
> cleared before any production use. A fresh clone therefore has no
> `Settings.vb` and will not build until it is recreated.

"Save settings" stores them in `%APPDATA%\60sec\DreamPoc\settings.json`. **The
secret is encrypted there with DPAPI for your Windows account**: unreadable from
another account or another machine. It never appears in the log, and the token
is masked.

## The screen

**1. Pay a supplier (EFT)** — the use case. The supplier, its contact, the bank
account to credit, the invoice being paid: the same fields as the website's
`wbfSupplierPaymentDream.aspx`, in the same sections. Then **Pay the supplier by
EFT**, which runs the four calls below in order.

| Step | Call | What it produces |
|---|---|---|
| 1 | `POST /payees/add` | `payeeId`, `payeeUserId` |
| 2 | `POST /payees/{id}/accounts` | `bankAccountId` |
| 3 | `POST /payments/add` | `paymentId` |
| 4 | `POST /payments/{id}/accept` | **this is the step that moves the money** |

The token is fetched automatically before the first call and reused for an hour.
The four identifiers stay visible at the top of the window as they arrive, and
the same four calls can be fired one at a time from the same fields — so when
the chain breaks you see exactly where, and can retry that one step alone.

The other tabs: **2. Connection** (credentials, and which payer is sending the
money), **3. Options** (everything the website leaves at its default, with a
button to put it all back), **4. Other calls** (Interac, cancel, account
verification), **5. Raw request** (any path at all).

**Two logs run side by side**, the same events in both. The English one is what
gets sent to Dream; the French one is for whoever is running the tool. What
travels on the wire — URLs, JSON bodies, Dream's own error text — appears
identically in both; only the narration and the hints are translated. Each box
has its own Copy and Save buttons.

## Does this match the website?

Yes — that is the point, and it was checked line by line against
`App_Code/clsDreamPayments.vb` and the two pages that drive it
(`wbfSupplierPaymentDream.aspx.vb`, `wbfSupplierPaymentInterac.aspx.vb`).
Same fields, same JSON types, same key order, same rule for leaving a field out,
same raw UTF-8 encoding, same base path and payer header. The defaults on screen
are the values the website actually sends, so pressing the buttons in order
reproduces a real supplier payment.

Two places where the POC deliberately offers a choice the website does not,
because the website itself is unsure:

- **`amount.value`.** The website sends a **number of cents** (`1000`), with a
  "unit to be confirmed" comment still in the code. The POC defaults to that and
  can switch to a **string of dollars** (`"10.00"`) — so the question can finally
  be settled against Dream rather than argued about.
- **`payoutDate`.** The website never sends it. Off by default here, with a
  checkbox to try it.

Everything else is identical, including the details that are easy to get wrong:
`bankAccountType` is `CHEQUING` (not `CHECKING`), `autoAcceptPaymentMethod` is a
**method code string** and not a flag, `preferredLanguage` is `fr-CA`, the
address block is dropped entirely when the street is empty while `address2` is
always present when it is not, and `verify` / `acceptance` / `cancel` post an
empty object.

## Settled points — do not "fix" these again

These three cost a lot of time on the first attempt; they are the POC defaults.

- **`BasePath` must stay empty.** The docs mention a `/platform` prefix: on
  `insuretechv2` it returns 404.
- **`payeeType` is `INSURED`**, not `VENDOR`. This is the InsureTech API: a
  supplier is an "insured" there.
- **The token URL is `…/oauth2/token`**, on the `partner-userpool-test-insuretech`
  pool. The server listed in `openapi.json`
  (`paymenttech-dreampayments-com.auth…`) **does not resolve in DNS**: the
  request fails on "unknown host" before it even leaves. If Dream confirms a new
  pool, the field can be changed on screen.

## Where it stands, 16 September 2026

Pressing **Pay the supplier by EFT** gets as far as step 1 and stops:

- Token: **200**, Bearer, 3600 s.
- `GET /payees/zzz`: **404 `BA0002 Invalid business ID`** — a real Dream answer,
  so the route is live and the token accepted.
- `POST /payees/add`: **500 `G00021 Invalid state. Multiple payers exist`**.

That is the original blocker, now reproduced end to end on the real use case,
with the exact payload the website sends. Steps 2, 3 and 4 have never run.

The environment was unstable that morning, which is worth knowing when reading
older logs: first 503 HTML on every real route (while `GET /` still answered a
JSON 404 — the gateway was up, the service behind it was not), then a spell of
`G00002 Internal server error`, then back to `G00021`.

There is **no endpoint to list the payers**: `GET /payers`, `/payer` and
`/legalentities` all return 404. So the payer identifier cannot be discovered
from the API — Dream has to supply it. Logs kept in
`DreamPaiement\dream-log-en.txt` and `DreamPaiement\journal-dream-fr.txt`.

## Who are the payers?

Dream says "Multiple payers exist" without naming them, and **no endpoint lists
payers** — `/payers`, `/payer`, `/legalentities`, `/tenants` all return 404.

They can be found sideways: every payment carries its payer in `legalEntity`, and
`/payments` accepts a search. **List the payers**, in the Payer section of the
*Connection* tab, does exactly that and shows them in a grid — click a row and it
goes into `legalEntity`, the one in use shown in bold. As of 16 September 2026,
under tenant `MCPUSSB01`:

| legalEntity | clientBusinessName |
|---|---|
| MCPUSSB0100001, MCPUSSB0100002 | AcmeCorp |
| MCPUSSB0100003 | DreamSB |
| MCPUSSB0100006 | RevveMeOne |
| MCPUSSB0100007, MCPUSSB0100008 | BokoTech |
| MCPUSSB0100036 | PV |
| **MCPUSSB0100037** | **60Sec** <- ours |

Dream's own operator created a payment for 60Sec on 15 September 2026, so the
payer is provisioned. `MCPUSSB0100037` is the POC's default `legalEntity`.

Filling it in does **not** lift the `G00021`, which happens earlier, on
`/payees/add` — a call that has no payer field at all. Tried and refused:
`legalEntity` as a header, as `X-Legal-Entity`, as `X-Payer-Id`, in the body root
and inside `payeeAccountInfo`. Dream has to scope the credentials themselves.

### What those payments also settled

- **`amount.value` is in cents.** The real payments read `100` for 1.00 CAD and
  `2000` for 20.00 CAD. The website's `CLng(amount * 100)` is right.
- **`paymentType` is `Expense`**, capitalised that way — the website sends
  `EXPENSE`. Worth checking with Dream before production.
- **The Interac method is `JPM_ET`**, not `ETRAN`: that is what the 60Sec payment
  carries in `allowablePaymentMethods`. The website's Web.config still says
  `ETRAN`. The POC now defaults to `JPM_ET`.
- `payoutDate` **is** used by Dream, in full ISO form (`2026-06-04T00:00:00Z`).
- The search body that works is the bare `{"query":{"size":100,"startIndex":0}}`.
  The documented one, with its filters and sort fields, is rejected with `HBE006`.

## How to get a payeeId while /payees/add is blocked

Normally `POST /payees/add` returns it — and that is exactly the call `G00021`
refuses. `POST /payees` (the listing) is no help either: it answers `G00002`.

A payee can still be recovered, because a payment names the one it went to:

1. `POST /payments` with `{"query":{"size":100,"startIndex":0}}` — the payments,
   each with its `legalEntity`, so they can be filtered by payer.
2. `GET /payments/{paymentId}` — the detail carries **`payment.payeeId`**.
3. `GET /payees/{payeeId}` — the record carries **`primaryPayeeUserId`**, which
   is the `payeeUserId` the later calls need, plus the name and status.
4. `GET /payees/{payeeId}/accounts` — its bank accounts, if any.

**Find the payees of this payer**, on the *Other calls* tab, does all four and
shows the result in a grid. Click a row and `payeeId` and `payeeUserId` are
filled in at the top of the window — so steps 2, 3 and 4 of the flow can be run
against a payee that already exists, without creating one.

As of 16 September 2026 the 60Sec payer has one payee: `Huy Nguyen`,
`4eb6229938b14308abe4bddbc42c0b48`, user `384fe4f685cc4f26bc978022d1622c1b`,
**no bank account yet** — created by Dream's own operator on 15 September.

## The `G00021 Multiple payers exist` blocker

The credentials are attached to several payers and Dream cannot tell which one
to use. Two calls need to know, and both are refused:

| Call | Result |
|---|---|
| `POST /payees/add` | `G00021` |
| `POST /payments/add` | `G00021` |
| `POST /payees/{id}/accounts` | **works** — the payee already exists, so no payer to guess |

**The two configurable hooks do not lift it.** This was worth knowing before
changing anything in the ERP, and it has now been tested on both calls:

- payer header, tried as `X-Payer-Id`, `X-Legal-Entity`, `X-Tenant-Id` and
  `legalEntity`, carrying `MCPUSSB0100037`;
- `legalEntity` and `legalEntityLabel` in the body, alone and together, as the
  code `MCPUSSB0100037` and as the business name `60Sec`;
- on `/payees/add`, also in the body root and inside `payeeAccountInfo`.

Every one answers `G00021`. So the hooks in `clsDreamPayments` — the payer header
and the legal-entity pair — **will not solve this**, whatever value goes in them.

Only Dream can: by scoping the credentials to a single payer, `MCPUSSB0100037`.
That is the one sentence to send them, with the log attached.

## Interac instead of EFT

Accepting a payment over Interac uses the `ETRAN` method and **needs no bank
account**: the money goes to the payee's email address. The Payment tab has a
button for each of the two routes.

## The files

| File | Role |
|---|---|
| `Program.vb` | entry point |
| `Settings.vb` | persisted settings, secret encrypted with DPAPI |
| `DreamClient.vb` | token, request sending, reading Dream's errors |
| `Payloads.vb` | the JSON bodies, modelled on the ERP's `clsDreamPayments.vb` |
| `JsonPath.vb` | reading a value by dotted path out of the response |
| `FrmPoc.vb` | the screen and the log |

Nothing in `Payloads.vb` is invented: every field comes from the production
connector or from the InsureTech docs. That is the condition for what is
observed here to hold true for the website.
