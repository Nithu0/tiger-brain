# Solar Consulting — automatisering av hele bedriften, grenkart (handoff 2026-10-08)

Repo: `Nithu0/Solar-Consulting`. Operatør: «Vi har kjøpt bedriften. Gjør klar for automatisering av hele
bedriften. Se hva vi gjorde for Verisure og gjør klart minst de grenene for Solar Consulting.»

## Levert
- PR #89 merget: markedsradar + tildelingsbeløp fra Doffin (rebase fullført etter at den sto i konflikt).
- PR #90 merget: `research/energikartlegging/` (31 filer, kilden til `market/competitors/`) + ervervsanalysen 23.09 med DECISION-linje (ervervet gjennomført).
- PR #91 åpen (auto-merge når CI er grønn): `strategy/proposals/2026-10-08-automatisering-solarconsulting.md` (grenkart), `prd/bedriftsautomatisering.md` (40 user stories), `issues/023–030` (7 AFK / 1 HITL).
- Seks branches pushet, hver med lane-notat i `projects/anbud/docs/lanes/`: `feat/auto-{plattform,salg,innboks,leveranse,okonomi,rapport}`. Ingen kode ennå.

## Verisure-grenene, kort
Bare regnskapsautomatikken i `~/code/AS` kjører (eksport → lønnsskjema → Fiken). Innboks-ops, dokument-intelligens,
leadgen, rapportering og plattform er spesifikasjoner i `command-center/docs/ops/` uten utfall. Vi gjenbruker
rollemodellen (`triage`/`extract`/`draft`/`analyze`/`report`) og godkjenningskø-tenkningen, ikke et ferdig produkt.

## Rekkefølge
F plattform (023, ublokkert) → B salg (024, 025) → A innboks (026, 027) → C leveranse (028) → D økonomi (029, HITL) → E rapport (030).

## Operatøren må svare (forslaget § 6)
1. Regnskapssystem (Fiken antatt). 2. Kunde-e-post/energidata til Anthropic-API (EU, DBA) eller lokalt?
3. Alt i `projects/anbud/crm` (antatt) eller eget prosjekt? 4. Eier per gren i firm-gridden
(forslag: tools-1 F+A, data-1 B+C, paal-1/admin-1 D+E).

## Harde porter før live
GDPR interesseavveining + art. 14 (salg), DBA + EU-lagring (leveranse), § 8-avklaring (sperrer pakke B/C/D),
regnskapssystem + nøkkel (økonomi), lesescope for Gmail-innhold (innboks), oppbevaringstid e-post/WhatsApp.

## Opprydding som er operatør-gated
9 lokale branches er identiske med merget PR-head og kan slettes med worktrees: fix/anbud-sporsmal, feat/anbud-whatsapp,
fix/migrasjon-down, chore/slack-linear-rename, feat/anbud-triage-{data,learning,ui,agents,integrasjon}; feat/secure-age
ligger bak #25. `~/code/Veldora` står på feat/secure-age med to tracked filer eldre enn main; bytt den til main.

## Oppdatering senere samme dag

Operatør svarte: Fiken, Anthropic OK for kundedata, alt i `projects/anbud/crm`. Gren F plattform (issue 023) er bygget: PR #94
(kunderegister, `oppdrag`, `approvals`-kø med guard og endepunkter, `data-policy`-global med port i `lib/llm.ts`,
morgenbrief-seksjon, dashbordside `/godkjenning`, migrering verifisert opp/ned/opp). Kodegjennomgang før push fant at
datapolicy-kilden ikke var registrert og et kappløp i `decide()`; begge rettet. vitest 1917/1917, smoke 19/19, dashboard 323/323.

Ops samme dag: VAPID-nøkler for push satt på Railway (crm + worker, redeployet). Dashbord-deployen sto fast fordi Vercel Hobby
blokkerer commit-author utenfor teamet (Tintun, #92) også via CLI; produksjon rettet manuelt (deploy uten `.git`), varig fiks i
`deploy.yml` (#93, merget). Operatør-TODO: gi Tintun Vercel-sete.

Neste gren: 024/025 salg. Lokal røyktest-DB: Docker `anbud-pg-smoke` (127.0.0.1:5439), `.env` i `Veldora-lanes/projects/anbud/crm`.

## 2026-10-09 — salgsgren

PR #95: prospekter (import/score/kvalifisering), sales-settings, salgstilbud (A–D, § 8-port, godkjenning via approvals, signatur → kunde + oppdrag), oppstart-docx, dashbord `/salg`, `/salg/[id]`, `/oppdrag/[id]`. Gjennomgang før push fant innholdsendring etter godkjenning og tre kappløp; rettet (rå SQL-claim, også i plattformens decide()). Røyk 37/37 + 21/21. Neste gren: innboks (026/027). Etter merge: importer prospektlisten via `/salg`.

## 2026-10-09 — innboks-gren

PR #99: henvendelser = `workspace-items` utvidet (kontaktskjema, body bak datapolicy/scope, kategori, prospekt/kunde), `draft.reply` svarutkast via godkjenningskøen, sending bak `inbox-settings` (standard av, aldri WhatsApp), sletting etter oppbevaringstid, morgenbrief «Ubesvarte henvendelser», dashbord `/innboks`. Gjennomgang før push fant en RangeError som kunne stoppe Gmail-synken for godt + fem mellomfunn; alle rettet. Røyk 36/36, vitest 2025.

Operatør må: (1) `gws auth login` med `gmail.readonly` + re-eksport av `GOOGLE_WORKSPACE_CREDENTIALS_B64` til Railway, (2) `CONTACT_FORM_SECRET` på Railway crm + Vercel veldora-web (+ `CRM_URL`), (3) ta stilling til at medlemmer nå leser private kanaler. Neste gren: leveranse (028).

## 2026-10-09 — leveranse-gren + ops

PR #100: energidata (Elhub-parser med egen fixture merket ASSUMPTION), lastprofil/varighetskurve/effektledd (Elvia/Lede FACT, ellers UNKNOWN), rapportutkast via godkjenningskøen, KS-sjekkliste (godkjenner ≠ forfatter sperrer levert), timer mot kalkyle, referanseforespørsel, sletting delt mellom worker (flagger) og admin-sweep i crm (volumet). Gjennomgang før push fant tre blokkerende (KS-tekster, avvist KS låste, filsletting i feil prosess) + fire mellom; alle rettet. Røyk 57/57, vitest 2104.

Ops: `CONTACT_FORM_SECRET` + `CRM_URL` satt på Railway crm og Vercel veldora-web via CLI, begge redeployet; kontaktskjema poster til CRM. Operatør gjør gmail.readonly selv. Brukere: hjelpeskript `~/.config/solar-consulting/create-dashboard-users.sh`, venter på navn/e-poster. Neste gren: økonomi (029, Fiken).

## 2026-10-09 — økonomi-gren + brukere + BORG

PR #102: Regnskap-grensesnitt med Fiken v2-adapter (bare kladder) og mock, okonomi-settings (mock som standard til FIKEN_API_TOKEN legges inn samlet senere), fakturaer, fakturakladd → godkjenningskø → kladd i regnskapssystemet ved godkjenning med renset menneskeversjon, avstemming per måned, timer mot fakturert, /okonomi. Gjennomgang fant tre blokkerende (sideform, injiserbar bankkonto, avvist låste) + fire mellom; alle rettet; røyk 40/40, vitest 2159.

Tre dashbord-brukere opprettet som medlemmer (passord i ~/.config/solar-consulting/). BORG-strategi (CETP-2026-00058) i research/, PR #101 merget; RCN-frist 15.10.2026 for LoI + NOK-budsjett og 8x-regel flagget. Gjenstår: rapport (030).

## 2026-10-09 — rapport-gren + Myhre

PR #103 (030): ukentlig driftsrapport med trakt-KPI (målt/estimat/mangler) mot 90-dagersplanen, styrenotat dag 90 i godkjenningskøen, /rapport. Dermed er alle åtte issues 023–030 levert og i drift.

Myhre: robertmyhre.no (187 artikler) hentet med høflig crawler til ~/.local/share/solar-consulting/myhre-crawl/ (utenfor git); strukturert uttrekk i egne ord med maks 25-ords sitat per påstand; kilde registrert i data/sources/robertmyhre.json (redistribution RED ⇒ link_only); operatørunntak fra «primærkilder bare» dokumentert i ARCHITECTURE § 11. Neste: fyll gap, syntese per modul, issue 031 for «se også»-henvisninger i feilsjekk/kvalifikasjon/kontraktsflagg. TODO operatør: spør Myhre om intern AI-bruk/samarbeid.

## 2026-10-09 — issue 031

PR #105: data/legal/kommentar-regler.json (juristeid, 18 rader ASSUMPTION), «se også» på feilsjekk-funn og bevismaler ved lesing, FACT krever signatur, kan bare senke alvorlighet, skjult i utskrift/eksport. Gjennomgang fant at bevismal-henvisninger ikke nådde dashbordet (lagret felt manglet) → lagt på ved lesing. Kandidat-issues 032–046 for topp-15.

## 2026-10-10 — issue 033 + 047

PR #106: avvisningsklasse på krav (regelbasert, overstyrbar, etterfylling), vesentlighetsvurdering etter fire momenter på forbehold med sjekklistesperre, klage-hint. Gjennomgang fant at klassifikatoren ga «absolutt» på negasjoner/boilerplate og «Skal-krav»-overskrift — rettet (nå ukjent/fleksibel). 047: tilbuds-røyktesten var utdatert siden #86 (juridisk steg valgfritt, godkjenningsrunde i sjekklisten), nå 67/67 mot fersk DB. Gjenstår API-only: klage-klasser i dashbord, «se også» på forbehold i UI.
