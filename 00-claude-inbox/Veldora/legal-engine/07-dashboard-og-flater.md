# Dashboard-flaten og CRM-kobling — kartlegging

Repo: `projects/anbud/dashboard` (Next.js App Router), i drift på `anbud-veldora.vercel.app`. Kun lest kode, ingen kall mot drift.

## 1. Ruteinventar (`src/app/**`)

Juridiske ruter markert **FET**. CRM-endepunkt = direkte `cmsJson`/`list()`-kall funnet i filen (grep, kan undervurdere kall gjort via lib-helpere).

| Rute | Fil | Hva den viser | CRM-endepunkt (grep-funn) |
|---|---|---|---|
| **/juridisk** | `(app)/juridisk/page.tsx:29` | Samlet kø: feilsjekk, klage, kontraktsflagg, nærmeste frist | `/anbud/legal/queue`, `/anbud/legal/feilsjekk`, `/anbud/legal/klage` |
| **/juridisk/kilder** | `(app)/juridisk/kilder/page.tsx:39` | Rettskildekorpus: lov/forskrift ledd for ledd, KOFA avsnitt for avsnitt, søk | `/anbud/legal/sources` |
| **/juridisk/assistent** | `(app)/juridisk/assistent/page.tsx:22` | «Spør rettskildene» — spørsmål med sitat-verifisering | `/anbud/legal/questions` + `findById("legal-flags"/"requirements")` |
| **/juridisk/feilsjekk/[id]** | `(app)/juridisk/feilsjekk/[id]/page.tsx:14` | Full feilsjekk for ett oppdrag, lovtekst ordrett + KI-forklaring | `/anbud/opportunity/{id}/feilsjekk?forklar=1` |
| **/juridisk/kommentarer** | `(app)/juridisk/kommentarer/page.tsx:35` | Juristvurdering av ekspertkommentarer (sekundærkilder) | `/anbud/kommentar` |
| **/jurist** | `(app)/jurist/page.tsx:4` | Redirect-stub → `/juridisk` (gammel rolle finnes ikke mer) | ingen |
| **/bevis** | `(app)/bevis/page.tsx:36` | Bevisarkiv: Brreg, dokumenter+attestasjon, kompetanse | `/anbud/evidence-vault` |
| /tenders, /tenders/triage(/historikk) | triage-flate | Kunngjøringer, triage-kø, swipe | `opportunities`, `/anbud/triage/queue`, `/anbud/triage/item/{pos}` |
| /opportunities/[id] | se §3 | Oppdragssiden m/ faner | se §3 |
| /pipeline, /godkjenning, /forventet(+[id]/ny) | — | Pipeline-board, godkjenningskø, forventede anbud | `opportunities`, `watch-items` |
| /salg(+[id]), /innboks(+[id]), /okonomi, /rapport | — | Salg/CRM-drift, henvendelser, økonomi, rapport | `salgstilbud`, `/anbud/prospekter/ringeliste`, `/anbud/henvendelser/ko` |
| /kompetanse(+person/referanse [id]) | — | Kompetansebank: referanser, CV, personer, kunder | `capability-facts`, `customers`, `people`, `references`, `cvs` |
| /marked(+kjoper/leverandor[id]), /statistikk, /nyheter, /agents, /ai, /calibration | — | Markedsinnsikt, KPIer, agent-/KI-bruk | `/anbud/buyer/{id}`, `/anbud/supplier/{id}`, `predictions` |
| /mote(+kjor/referat), /notater(+[id]), /intervju, /dokumenter(+[mappe]) | — | Møtemodus (ADR-0017), notater, intervjuspørsmål, interne dokumenter | `/anbud/opportunity/{id}/coverage`, `briefs`, `activities`, `notes`, `interview-questions`, `tender-decisions` |
| /oppdrag/[id] | — | Oppdrag i drift: energidata, faktura, leveranse | `/anbud/oppdrag/{id}/{energidata,faktura,leveranse}` |
| /innstillinger(+varsler), /chat | — | Varslingsoppsett, chat | — |
| /login | `app/login/page.tsx` | Innlogging | — |

Totalt ~45 `page.tsx`-filer under `(app)/`. Ingen egen `/klage`-toppnivårute — klage og innsyn ligger som fane på oppdragssiden (§3), ikke som egen flate i nav.

## 2. Navigasjon — `src/lib/nav.ts`

`NAV_GROUPS` (5 grupper) → `NAV_LINKS` = **25 lenker** flatet ut (telt fra kildekoden, linje 11-62): Møtemodus, Oversikt, Chat, Notater · Kunngjøringer, Triage, Pipeline, Til godkjenning, Forventede anbud · Salg, Innboks, Økonomi, Rapport · Intervju, Kompetanse, Bevis, Juridisk, Juristvurderinger, Interne dokumenter · Marked, Statistikk, Nyheter, Agenter, AI-bruk, Kalibrering. `MORE_LINKS` = NAV_LINKS + Innstillinger (26). Telefon-tab-bar (`TAB_LINKS`) har bare 5 faste + «Mer».

## 3. Oppdragssiden — `(app)/opportunities/[id]/`

Faner styrt av `page.tsx:42-50` (`TABS`), valgt via `?fane=`:

| Fane | Komponent | Viser | Data (hentes i page.tsx eller egen fane) |
|---|---|---|---|
| Oversikt | `OverviewTab.tsx` | Statusoppsummering | props fra page.tsx (ingen eget CRM-kall) |
| Krav | `KravTab.tsx:36` | Kravliste m/ dekning | `requirements`, `documents` |
| Kvalifikasjon | `KvalifikasjonTab.tsx:330` | ESPD/kvalifikasjonskrav, «Kan vi levere?» | `res`-prop = `/anbud/opportunity/{id}/qualification` (hentet i page.tsx:77) |
| Brief | `BriefTab.tsx:57` | AI-brief, feilsjekk, prising, rammeavtale | `briefs`, `documents`, `/anbud/opportunity/{id}/feilsjekk`, `/prising`, `/rammeavtale` |
| **Tilbud** | `TilbudTab.tsx:877` | Kontraktsflagg (juridisk vurdering), avklaringer, avvik, endringsklausuler §28-1, dokumentasjon fra kompetansebanken m/ sitat | `requirements`; flagg/seksjoner kommer fra `o` (opportunity, depth=1) — ingen eget kall i filen |
| **Klage og innsyn** | `KlageTab.tsx:95` | Klagesak KOFA, karensperiode, innsynsbegjæring | `/anbud/opportunity/{id}/klage` |
| Arbeid | `ArbeidTab.tsx:17` | Nyheter, signaler, aktivitetslogg | `news-items`, `signals`, `activities`, `users` |

## 4. Datalaget — `src/lib/cms.ts`

- **Base-URL:** env `CRM_URL` (fil:21-25); faller til `http://localhost:3000` i dev, kaster feil i prod hvis usatt.
- **Auth:** cookie `payload-token` (navngitt konstant `TOKEN_COOKIE`) sendes som `Authorization: JWT {token}` på hvert kall (fil:93-104) — Payloads egen access control gjelder akkurat som i browser.
- **401** → `redirect("/login")` direkte i `cmsFetch`. **403** → ekstra sjekk mot `/api/users/me` (cachet per request via React `cache()`) fordi Payload behandler utløpt/ugyldig token som anonym, ikke 401.
- Alt er **server-side fetch** (`cache: "no-store"`, ingen Next.js data-cache/revalidering) — ingen server actions i cms.ts selv; server actions i `actions-*.ts` bruker disse helperne.
- `settle()`/`optional()`-mønster: en feilende seksjon (manglende collection, 403 for viewer) feiler lokalt, ikke hele siden.

## 5. Innlogging

- `src/middleware.ts:5-13`: presence-check (har cookien `payload-token`?) — ikke gyldighetssjekk. Mangler cookie → redirect til `/login?next=<opprinnelig-path>`. Matcher alt unntatt `/login`, `/cms/`, statiske filer.
- `LoginForm.tsx:19-27` poster til `/cms/users/login` (samme-origin rewrite), Payload setter `Set-Cookie` på dashboard-domenet.
- `safeNext.ts`: whitelister `next` til kun egen-origin path (blokkerer `//evil`, `\evil`, kontrolltegn) — åpen redirect er forhindret.
- Roller funnet i kode: `admin`, `member` (brukt til `canDecide`/`canAsk`/`canVurder`/`canConfirm` gates flere steder, f.eks. `opportunities/[id]/page.tsx:82`, `bevis/page.tsx:39-40`). Ingen egen `jurist`-rolle (kommentar i `jurist/page.tsx:3`: «there is no jurist role any more»).

## 6. Hvor vises rettskilder i dag? (fil:linje + mangel-håndtering)

| Sted | Viser | Når hjemmel/kilde mangler |
|---|---|---|
| `components/Feilsjekk.tsx:71-101` | Lovreferanse m/ lenke, paragraftittel, Lovdata-lenke, sitat-utdrag (`withExcerpts`) | `l.found === false` → **«— mangler i rettskildekorpuset»** (linje 93); ingen paragraf i det hele → **«Ingen bestemt paragraf i anskaffelsesregelverket — en kommersiell vurdering.»** (linje 100) |
| `components/Feilsjekk.tsx:102-114` | KOFA-avgjørelser med utfall brudd | Ingen funn → **«Ingen KOFA-avgjørelser med utfall brudd i korpuset om dette.»** (linje 113) |
| `(app)/opportunities/[id]/TilbudTab.tsx:143-160` | Sitat fra kompetansebanken per seksjon (`Citations`) | Tom liste → komponenten returnerer `null`, ingen melding vises |
| `(app)/opportunities/[id]/TilbudTab.tsx:515-534` | Kontraktsflagg: sitat + «grunnlag» | `f.basis` mangler → linjen med «· grunnlag: …» uteblir stille, ingen advarsel |
| `(app)/juridisk/kilder/page.tsx` | Fulltekst lov/forskrift + KOFA, søkbart | `sources.missing` → `Empty`-boks (generisk, ikke juridisk spesifikk) |
| `(app)/juridisk/assistent/` | KI-svar med verifisert sitat | Ikke-verifiserbart svar → **«Usikkert»**, viser kildene i stedet (beskrevet i page.tsx:52, logikken selv ligger i `lib/legal-assistent.ts` — ikke lest i detalj her) |

## 7. Tester

- `ls test/ | wc -l` → **47 testfiler**. `grep -rc "it(\|test("` summert → **621 treff** (node:test, kjøres med `npm test`).
- Alle sjekket (f.eks. `legal.test.mjs`, `klage.test.mjs`, `feilsjekk.test.mjs`, `kommentar.test.mjs`, `kommentar-vurdering.test.mjs`, `bevis.test.mjs`, `legal-assistent.test.mjs`, `tilbud.test.mjs`) er **rene enhetstester av `src/lib/*.ts`-helperfunksjoner** (parsing, labels, tone-mapping). Ingen fant bruker `fetch(` eller `render(` — **FINNES IKKE (målt: `grep -rl "fetch(\|render(" test/` → 0 treff)**: ingen integrasjonstest mot CRM, ingen komponent-/sidetest av selve React-treet (faner, auth-redirect, nav).
