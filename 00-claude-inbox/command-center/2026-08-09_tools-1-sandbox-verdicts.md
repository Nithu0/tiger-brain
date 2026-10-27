# tools-1: sandbox-verdicts topp-3-kandidatene (2026-08-09)

Oppfølging av F1-anbefalingene (28.07). Alle tre testet i container/uvx-sandbox, read-only/ephemeral, ingen ekte creds, ingen instanser provisjonert, ingen vedvarende state utover: `~/.sky/` (448K, harmløs), image `openfga/openfga` (111 MB, sletting = operatørvalg).

## Verdicts

| Kandidat | F1-rangering | Sandbox-verdict | Endring |
|---|---|---|---|
| telegram-mcp (chigwell) | 2 | **PILOT nå** (m/dedikert konto) | ↑ beste kandidat |
| SkyPilot | 1 | **AVVENT** | ↓ nedgradert etter test |
| OpenFGA | 3 | **VENT-TIL-FØRSTE-KUNDE** (bekreftet) | uendret |

## 1. telegram-mcp — PILOT med dedikert intake-konto

Sikkerhetsbevisst over gjennomsnittet: `TELEGRAM_EXPOSED_TOOLS=read-only` fjerner verifisert alle 71 write-tools (51 read-only igjen — inkl. alt intake trenger: `list_messages`, `search_global`, `wait_for_new_message`); typo i allowlist → høylytt exit; session-string logges aldri; prompt-injection-sanitering på alt brukerinnhold; dummy-cred-test ga kontrollert feil. Docker-image 186 MB non-root, aktivt vedlikeholdt (1430★, pushet 07.08).

Kjente svakheter for 24/7 (fra issues, håndterbare med dedikert konto med få chats): #169 update-flom ved restart etter nedetid; #180 FloodWait-blindhet <60s. Forbeholdet står: Telethon = full kontoautoritet i prosessen — read-only beskytter mot LLM-en, ikke mot prosess-kompromittering. Derfor ALDRI hovedkonto. NB: PyPI-pakken `telegram-mcp` er et ANNET prosjekt — installer kun fra repo.

**Operatør-gates for pilot:** (1) opprette intake-konto + kjøre session-generatoren (interaktiv login), (2) session-string inn i `.env` (nano-prinsippet), (3) enhver utvidelse forbi read-only, (4) systemd-unit-beslutning.

## 2. SkyPilot — AVVENT (nedgradert fra topp-1)

Teknisk PASS hele veien: 0.13.0 via uvx, `sky check vast` grønn mot samme nøkkelfil som vast-job.sh, offer-listing korrekt (RTX4090 $0.40/t matcher vår `--max-dph 0.50`). Men adopsjonsanalysen snur bildet:

- `vast-job.sh` har **sterkere** garantier for vår ephemeral-batch-livssyklus: trap-destroy også ved feil, orphan-jakt via label, hard 4t-cap — mot SkyPilots idle-heuristikk (bygget for langlivede dev-bokser vi ikke har).
- Direkte besparelse mot ~$270/mnd: **~$0** — begge velger billigste offer fra samme marked. Spot-kolonnen for Vast så ut som katalog-hull ($0.000 over hele linja) — ikke stol på den.
- SkyPilot er klient-server (auto-startet lokal API-daemon under test — stoppet igjen); flere bevegelige deler, community-tier Vast-støtte.

Revurder ved: multi-cloud-behov (RunPod/Lambda-arbitrasje), langlivede GPU-bokser, eller jobbkø m/preemption-retry.

## 3. OpenFGA — VENT-TIL-FØRSTE-KUNDE (bekreftet, nå avrisikert)

Teknisk alt grønt: 6/6 isolasjonssjekker korrekte (kryss-tenant false by default — ingen relasjonssti finnes), 16 MiB RAM, 4-7 ms checks, og **sqlite-backend verifisert native** (v1.18.3) — Postgres-blockeren finnes ikke. Integrasjonssnitt skissert: preHandler-hook etter `registerAuth` i apps/api, approval-rights som første FGA-relasjon; egen DB-fil, HTTP-snitt (ADR-001-kompatibelt). Adopsjon nå gir kun en ekstra 24/7-prosess + tuple-sync-flate uten brukere. Ved kunde nr. 2: 1-2 dagers jobb. Modell + testskript arkivert: `2026-08-09_openfga-sandbox-test.sh` (samme mappe).

## Netto anbefaling til orchestrator-1

Eneste aksjonerbare nå er **telegram-mcp-piloten** — den styrker telegram-intake-målet direkte og venter kun på operatør-gatene over. SkyPilot og OpenFGA er dokumentert med konkrete revurderingstriggere i CAPABILITY-REGISTRY §9.

— tools-1, 2026-08-09
