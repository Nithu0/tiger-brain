---
title: Job-scrape feasibility — finn.no / arbeidsplassen.no / LinkedIn
date: 2026-05-14
author: claude (research subagent)
status: draft for operator review
tags: [career, automation, scraping, decision, feasibility]
domain: career
project: jobsoking-pipeline
related:
  - "[[04-career]]"
  - "[[reference_brain_structure]]"
---

# TL;DR

- **Arbeidsplassen.no (NAV)** er den eneste kilden hvor automatisert tilgang er **både offisielt tillatt og gratis**. `pam-stilling-feed` gir JSON-feed med ~1000 nye annonser/dag, bearer-token, ToS-godkjent. **Dette er kjernen i pipelinen.**
- **finn.no** har API kun for kommersielle partnere (du som privatperson kvalifiserer ikke). Scraping er teknisk mulig men i juridisk gråsone (ToS forbyr automatisert tilgang). Mange annonser dukker uansett opp i NAV-feeden fordi arbeidsgivere kryssposter. Anbefaling: hopp over som primær kilde, bruk evt. tredjepartsaktør (Apify finn-no-scraper) som tillegg hvis NAV-dekningen viser seg mangelfull.
- **LinkedIn**: klart fraråd. ToS forbyr scraping, LinkedIn saksøker aktivt (Proxycurl stengte juli 2026 etter LinkedIn-sak). Bruk LinkedIn manuelt + offisielle e-postvarsler.
- **Anbefalt stack**: pam-stilling-feed (offisielt) + manuell LinkedIn-trål + e-postvarsler fra finn.no som "fallback-radar". Eventuelt Adzuna API som aggregert tilleggssjekk.
- **Estimat**: MVP buildable på ~1 dags arbeid. Faktisk verdi avhenger av kvaliteten på keyword-scoringen og om operatøren faktisk åpner output-fila daglig.

---

# Per-kilde-analyse

## finn.no

**API-tilgang**: Nei for privatpersoner.
- API-en (`finn.no/api/`) er kun for "business parties": annonsører, eiendomsmeglere, bilforhandlere, jobb-annonsører.
- Sitat fra dokumentasjonen: *"We currently do not provide access to non-business parties, but we do hope to introduce some Open APIs in the future."*
- Krever forretningsforhold + dataeierskap + ToS-godkjenning. Du har ingenting av dette.

**RSS / e-postvarsling**:
- finn.no har **lagrede søk** med e-postvarsling — dette er ToS-godkjent og gratis. Lavfriksjon for å fange opp nye stillinger som matcher gitte søkeord, men output er e-post (ikke strukturert JSON).
- Ingen offentlig RSS-feed bekreftet.

**Scraping (ToS / robots.txt)**:
- ToS forbyr automatisert tilgang uten API-avtale. Brudd ≠ kriminelt (jf. hiQ vs. LinkedIn-presedens for offentlig data), men kan trigge IP-blokk, kontosperring, og i prinsippet sivilt søksmål for kontraktsbrudd.
- Realistisk risiko for privatperson som scraper noen hundre annonser/dag: lav, men ikke null.

**Eksisterende verktøy**:
- `hermansc/finnscraper` (GitHub) — enkel e-postvarsler, sannsynligvis ikke jobb-fokusert.
- `Lekesoldat/finn-scraper` — generelt finn.no, sannsynligvis utdatert.
- **Apify `unfenced-group/finn-no-scraper`** — kommersielt, betalt per kjøring, vedlikeholdt, jobbfokusert, inkluderer AI-genererte sammendrag og kontaktdata. Realistisk alternativ hvis NAV-feeden viser hull.
- JobFunnel (`PaulMcInnis/JobFunnel`) — multi-source men finn.no ikke i kjerne.

**Vurdering**: Hopp over som primær kilde. Sett opp lagrede søk → e-post som fallback. Hvis NAV-dekningen viser seg <60% av finn.no-volum (måles empirisk etter 2 uker), vurder Apify-aktør.

## arbeidsplassen.no (NAV)

**API-tilgang**: Ja, offisielt og gratis.
- `pam-stilling-feed` (https://navikt.github.io/pam-stilling-feed/) er det aktuelle API-et. Gammelt `pam-public-feed` ble avviklet 1. mai 2025.
- Endpoint: `GET https://pam-stilling-feed.nav.no/api/v1/feed`
- Auth: `Authorization: Bearer <token>`
  - **Public token**: hentes fra `https://pam-stilling-feed.nav.no/api/publicToken`. Roterer på irregulære intervaller, kan brukes til eksperiment.
  - **Privat token**: send e-post til `nav.team.arbeidsplassen@nav.no` med kontaktinfo og bekreftelse av ToS. Mer stabilt, anbefales for produksjon.
- Volum: ~1000 nye annonser per dag.
- Anbefalt polling: 2-minutters intervaller ved endt feed, bruk `ETag` og `Last-Modified` for å minimere data.
- ToS: Inkluderer plikt til å fjerne inaktive annonser fra eget system.

**Coverage**: NAV-databasen inneholder de fleste offentlig utlyste stillinger i Norge fordi arbeidsgivere ofte kryssposter (lovpålagt for offentlig sektor, vanlig praksis for privat). finn.no-annonser er **ikke** automatisk i feeden, men en stor andel arbeidsgivere annonserer på begge.

**Vurdering**: Kjernen i pipelinen. Ingen juridisk risiko, gratis, godt dokumentert, JSON.

## LinkedIn

**API-tilgang**: Praktisk talt nei.
- Offisiell Jobs API krever Partner-status. Akseptrate <5%, ventetid 6+ måneder. Ikke realistisk for én bruker.

**Scraping**: Klart fraråd.
- ToS forbyr eksplisitt automatisert tilgang.
- LinkedIn saksøker aktivt: **Proxycurl (nubela.co) ble stengt juli 2026** etter LinkedIn-søksmål — tydelig signal.
- hiQ-saken etablerte at scraping av offentlig data **ikke** bryter CFAA (straffeloven i US), men LinkedIn kan fortsatt:
  - sperre kontoen din
  - saksøke for kontraktsbrudd (ToS-brudd)
  - kreve copyright-erstatning
- JobSpy støtter LinkedIn-scraping men:
  - "LinkedIn is the most restrictive and usually rate limits around the 10th page with one IP. Proxies are a must."
  - Kontosperring meget sannsynlig over tid. Du vil tape kontoen din — som er din viktigste karriereverktøy.

**Realistiske alternativer**:
- Manuell søk + LinkedIn sine offisielle **Job Alerts** (e-post).
- LinkedIn EasyApply for selve søknadsprosessen.
- Eksterne aggregatorer (Adzuna, Indeed) henter ofte de samme stillingene.

**Vurdering**: Aldri scrape. Risiko-til-verdi-forhold er elendig: du risikerer kontoen din (som er karrierekapital) for en pipeline som blir overflødig så snart LinkedIn endrer noe.

---

# Eksisterende verktøy — oversikt

| Verktøy | Kilder | Status | Vurdering |
|---|---|---|---|
| `pam-stilling-feed` (NAV) | arbeidsplassen.no | Offisielt, aktivt | **Bruk** |
| JobSpy (python-jobspy) | LinkedIn, Indeed, Glassdoor, Google, ZipRecruiter | Aktivt vedlikeholdt | Indeed-delen er trygg; LinkedIn-delen ToS-brudd. Vurder Indeed/Glassdoor for internasjonale søk. |
| Apify `finn-no-scraper` | finn.no | Kommersielt, vedlikeholdt | Reservevalg hvis NAV-dekning er mangelfull |
| `hermansc/finnscraper` | finn.no | Hobby, sannsynligvis utdatert | Skip |
| Adzuna API | Aggregert (inkl. Norge) | Aktivt, gratis-tier finnes | **Vurder** som tillegg, krever sjekk av no-dekning |
| JobFunnel | Multi-source | Aktivt | Indeed primært, mindre relevant her |

---

# Anbefalt stack (MVP)

**Datakilder**:
1. **Primær**: `pam-stilling-feed` API (NAV) — daglig pull.
2. **Sekundær**: lagrede søk på finn.no → e-postvarsel til operatørens innboks (manuelt oppsett, ikke kode).
3. **Sekundær**: LinkedIn Job Alerts → e-post (manuelt oppsett).
4. **Vurder senere**: Adzuna API for Norden/EU-remote-dekning.
5. **Reserveplan**: Apify `finn-no-scraper` hvis NAV-dekning under forventet.

**Lokasjon**:
- Repo: `/home/nithu/code/Søking fulltid/` (eksisterer eller opprettes — bekreft først).
- `leads/raw/<YYYY-MM-DD>.json` — rådata per dag fra hver kilde.
- `leads/raw/<YYYY-MM-DD>.md` — markdown-render for hurtig lesing.
- `leads/triage/` — operatør flytter lovende leads hit manuelt.
- `leads/applied/` — etter søknad sendt.
- `leads/archive/` — avslag eller bortfilter.

**Pipeline**:
- Språk: Python (matcher resten av operatørens stack).
- Bibliotek: `requests`, `pydantic` (skjema-validering), `python-frontmatter` (markdown-rendering).
- Trigger: cron @ 07:00 lokal, eller Claude Code Stop-hook (gjenbruk eksisterende auto-push-mønster).
- Output: markdown-fil + Discord-ping hvis ≥3 leads med score > terskel.

---

# MVP-skisse (pseudokode)

```python
# fetch_arbeidsplassen.py
def fetch_nav_feed(since: datetime, token: str) -> list[JobAd]:
    url = "https://pam-stilling-feed.nav.no/api/v1/feed"
    headers = {"Authorization": f"Bearer {token}"}
    # paginer med ETag / Last-Modified
    # returner liste av JobAd-objekter
    ...

# scoring.py
KEYWORDS = {
    # vekt → liste av (term, regex)
    10: ["machine learning", "ml engineer", "data scientist", "ai engineer"],
    8:  ["materials informatics", "computational materials", "dft", "ab initio"],
    7:  ["battery", "batteri", "electrolyte", "elektrolytt", "energy storage"],
    6:  ["python", "pytorch", "tensorflow", "jax"],
    5:  ["energy", "energi", "renewable", "fornybar", "hydrogen"],
    3:  ["research engineer", "phd", "postdoc"],
    -5: ["sales", "salg", "rekrutterer", "consultant" (uten ML-context)],
}
LOCATIONS_WEIGHT = {
    "trondheim": 10, "oslo": 7, "bergen": 5, "stavanger": 5,
    "remote": 8, "hybrid": 6,
    "stockholm": 4, "copenhagen": 4, "helsinki": 3,
}

def score(ad: JobAd) -> int:
    title_text = ad.title.lower()
    desc_text = ad.description.lower()
    s = 0
    for weight, terms in KEYWORDS.items():
        for term in terms:
            if term in title_text: s += weight * 2
            elif term in desc_text: s += weight
    for loc, w in LOCATIONS_WEIGHT.items():
        if loc in ad.location.lower(): s += w
    return s

# dedupe.py
def dedupe(new: list[JobAd], seen_ids_path: Path) -> list[JobAd]:
    # hold seen_ids.json som persistent state
    # nøkkel: ad.source_id ELLER hash(title + employer + location)
    ...

# render.py
def render_markdown(ad: JobAd, score: int) -> str:
    return f"""---
score: {score}
title: {ad.title}
employer: {ad.employer}
location: {ad.location}
deadline: {ad.deadline}
source: {ad.source}
url: {ad.url}
tags: {ad.tags}
---

# {ad.title} — {ad.employer}

**Score**: {score}  |  **Frist**: {ad.deadline}  |  **Sted**: {ad.location}

## Beskrivelse
{ad.description[:1500]}...

## Triage-handlinger
- [ ] Les hele annonsen
- [ ] Vurder fit
- [ ] Generer søknadsutkast (AI)
- [ ] Send / arkiver
"""

# main.py
def daily_run():
    token = os.environ["NAV_FEED_TOKEN"]  # eller hent public-token dynamisk
    today = date.today()
    raw_dir = Path(f"/home/nithu/code/Søking fulltid/leads/raw/{today.isoformat()}")
    raw_dir.mkdir(parents=True, exist_ok=True)

    ads = fetch_nav_feed(since=today - timedelta(days=1), token=token)
    ads = dedupe(ads, seen_ids_path=Path(".../seen_ids.json"))
    scored = [(ad, score(ad)) for ad in ads]
    scored = [s for s in scored if s[1] >= THRESHOLD]  # f.eks. 15
    scored.sort(key=lambda x: -x[1])

    for ad, s in scored:
        path = raw_dir / f"{s:04d}-{slugify(ad.title)}.md"
        path.write_text(render_markdown(ad, s))

    if len(scored) >= 3:
        notify_discord(f"{len(scored)} nye jobb-leads ({today})")
```

**Cron / Stop-hook**:
```bash
# crontab -e (alternativ A)
0 7 * * * cd "/home/nithu/code/Søking fulltid" && uv run python -m jobpipeline.main

# eller Stop-hook i ~/.claude/settings.json (alternativ B, etter operatør-godkjenning)
```

---

# Juridisk note

| Kilde | Lovlig automatisering | Risiko |
|---|---|---|
| arbeidsplassen.no (NAV) | **Ja** via offisielt API | Ingen, så lenge ToS overholdes (fjerne inaktive ads) |
| finn.no | API-tilgang krever forretningsforhold du ikke har. Scraping bryter ToS. | Lav-medium: IP-blokk, teoretisk sivilt søksmål. Lagrede søk + e-postvarsel er trygt. |
| LinkedIn | Praktisk talt nei. Scraping bryter ToS klart. | **Høy**: kontosperring, presedens for søksmål (Proxycurl-saken juli 2026). |

**hiQ vs. LinkedIn (9th Circuit)**: scraping av offentlig data bryter ikke CFAA (US straffelov), men er fortsatt brudd på ToS → sivilt søksmål eller kontosperring mulig. Norske/EU-regler (GDPR, åndsverkloven) gir egne begrensninger på behandling av personopplysninger fra annonser.

**Konkret regel**: Ikke scrape LinkedIn. Ikke scrape finn.no aggressivt. Bygg på NAV-API + offisielle varsler.

---

# Risikoer

1. **Anti-bot / IP-blokking** — irrelevant for NAV-API (auth med token, ingen anti-bot). Stor risiko hvis vi går utenfor.
2. **DOM-endringer** — irrelevant for API. Stor risiko ved scraping. Mitigeres ved å unngå scraping.
3. **Falske positiver** — vekt-tabellen er gjettverk i V1. Krever 2 ukers kalibrering. Operatør markerer relevante/irrelevante leads → vi justerer vekter.
4. **Falske negativer** — viktig stilling mangler keyword (f.eks. "scientific computing" istedenfor "ML"). Mitigeres ved bred keyword-liste + manuell triage av middels-score leads (score 8-15).
5. **NAV-dekning er ufullstendig** — noen private arbeidsgivere annonserer kun på finn.no eller LinkedIn. Mål empirisk: i 2 uker, sammenlign NAV-output mot operatørens manuelle finn/LinkedIn-funn. Justér deretter.
6. **Token-rotasjon (public NAV-token)** — fanges av error-håndtering. På sikt: be om privat token via e-post.
7. **Output-overflod** — for mange treff = ingen leses. Sett aggressiv terskel i starten (score ≥ 20) og senk gradvis.
8. **Operatør-fatigue** — pipelinen er verdiløs hvis output-fila ikke åpnes daglig. Bygg inn Discord-ping eller integrer i morgenbrief-rutinen.

---

# Neste skritt

1. **Bekreft mappestruktur**: finnes `/home/nithu/code/Søking fulltid/` allerede? Hvis ikke, opprette den (forutsetter operatør-OK).
2. **Hent public-token fra NAV** (`curl https://pam-stilling-feed.nav.no/api/publicToken`) → verifiser at vi får data ut.
3. **Sett opp lagrede søk på finn.no** (manuelt, operatør gjør selv) med søkeord: "machine learning", "ML engineer", "materials informatics", "batteri", "data scientist", lokasjon Trondheim/Oslo/Remote. Aktiver e-postvarsling.
4. **Sett opp LinkedIn Job Alerts** tilsvarende.
5. **Skissér V1 kode** i `~/code/Søking fulltid/jobpipeline/` (etter operatør-godkjenning av denne planen).
6. **Be om privat NAV-token** parallelt (e-post til `nav.team.arbeidsplassen@nav.no`).
7. **Kalibreringsperiode 2 uker**: sammenlign NAV-output mot operatørens manuelle funn på finn/LinkedIn. Beslutt om Apify finn-no-scraper eller Adzuna trengs.
8. **AI-søknadsgenerator** (separat decision-tree senere): tar lead-markdown + operatørens CV/profil → utkast i triage/. Ikke i scope for denne fila.

---

## Operatør-spørsmål før build

- Faktisk eksisterende mappe `~/code/Søking fulltid/`? Eller skal opprettes?
- Discord-notifikasjoner ønskelig, eller skal vi heller skrive til `~/Obsidian/Brain/04-career/inbox/`?
- Hvilken `score`-terskel passer best? Foreslår start på 20, justere etter uke 1.
- OK å sende e-post til NAV for privat token, eller skal vi starte med public-token først?
