# SANDBOX-TEST: sqlite-utils 4.2.1 (simonw/sqlite-utils) — 2026-08-19

Testet per docs/ops/SANDBOX-TEST-PROTOCOL.md (F2-kull #6). Utført av subagent m/rammene i prompt; kopier i scratchpad, uvx (null install), ingen skriv mot levende db-er.

## (a) Verdict: PILOT — med to navngitte gates

Fungerer utmerket som lese-inspeksjons-CLI (raskt, JSON-default, null install via uvx). Men premisset røk delvis, og verktøyet har ingen read-only-modus — derfor PILOT, ikke ADOPTER.

Premiss-funn (fase 1):
1. sqlite3-CLI finnes faktisk ikke (bekreftet). ✓
2. MEN: Python 3.12 stdlib (`python3 -c "import sqlite3"` + interaktiv `python3 -m sqlite3`) dekker ad-hoc-reads i dag — inkludert EKTE read-only via `file:...?immutable=1`-URI, som sqlite-utils IKKE kan. Premisset «ingen CLI finnes» er halvfeil.
3. «4 laner gjør engangs node-scripts» er overdrevet: better-sqlite3-mønstrene ligger primært i VEDLIKEHOLDTE _bin-scripts (brain-doctor.sh:108, brain-status.sh:105, global-session-context.sh:226,311) som allerede kjører {readonly: true} — de er load-bearing og skal IKKE erstattes. Ekte engangs-scripts finnes (scripts/redistill-0613.mjs, audit-dump.ts, migrate-sqlite-to-pg.ts).

Reell gevinst over python3-stdlib: JSON-default rett i jq, `tables --counts`, `schema`, bedre UX — komfort-gevinst (~siste 30 %), ikke kapabilitets-gevinst.

Gates:
- G1: KUN via read-only-wrapper (`_bin/db-query.sh` — levert 19.08) mot levende db-er; verktøyet gater ingenting selv.
- G2: Eksisterende better-sqlite3-blokker i _bin røres ikke.

## (b) Måletall
| Måling | Verdi |
|---|---|
| Versjon (uvx) | 4.2.1 (9 pakker, 32 ms install) |
| Kaldstart / varmstart | 0.83 s / 0.16 s |
| GROUP BY over 14 371 rader, 320 MB-kopi | 0.15 s wall, peak-RSS 45 MB |
| Kryssjekk counts vs python3 stdlib | Identisk (verbatim=14 371, distilled=14 289) |
| integrity_check memory.db-kopi | ok |
| Db-er (alle WAL) | command-center.db 1.9 MB (+2.5 wal) · brain-orchestrator.db 127 KB (+3.2 wal) · ~/.claude/projects/-home-nithu-code/state/memory.db 227 MB (+92 wal) |

## (c) Verifisert funksjonalitet
tables --counts, schema, vilkårlig SELECT (gyldig JSON default → jq); realistiske lane-spørringer (agent_tasks status-counts, firm_state heartbeats, verbatim/distillert-aggregat, integrity_check); WAL-kopier (.db+-wal+-shm sammen) leses korrekt.

## (d) Sikkerhetsflater (aktivt testet)
- INGEN read-only-modus. UPDATE via `query` gikk gjennom (rows_affected: 6 mot kopi); `insert` la inn rad. Write-veien helt åpen.
- `file:...?immutable=1` støttes IKKE — lager bokstavelig 0-byte søppelfil med URI-navnet. Skarp kant.
- chmod 444: reads OK, writes blokkert — men -wal/-shm fortsatt skrivbare (WAL-skjørt).
- python3 stdlib m/immutable=1 er eneste ekte read-only-håndhever på maskinen (verifisert begge veier).
- Ingen creds, ingen nettverk.

## (e) Integrasjonsskisse → LEVERT 19.08
_bin/db-query.sh: alias (cc|orch|memory|path) + SQL → konsistent snapshot via python3 sqlite3.backup (source åpnes mode=ro) til mktemp -d → uvx sqlite-utils query mot snapshoten → opprydding via trap. Ikke chmod-trikset (WAL-skjørt), ikke immutable (støttes ikke av sqlite-utils). Registry §9b-rad oppdatert; FIRM-TOOLBOX har python3 -m sqlite3-fallback-notat. Ingen 24/7-prosesser, ingen MCP, ingen repo-deps.

## (f) Risikoer / vedlikehold
- Hovedrisiko: lane som kjører uvx sqlite-utils DIREKTE mot levende WAL-db kan mutere prod-state (orchestrator/worker 24/7). Wrapperen er ikke valgfri (G1).
- URI-fellen kan legge igjen søppelfiler ved feilbruk.
- Moden (2 153★, Apache-2.0, push 14.08); uvx pinner ingenting.
- Re-vurderingstrigger: sqlite-MCP med ekte read-only-modus dukker opp → re-evaluer (DBHub §9b #7 har read-only-modus — test hvis MCP-flate trengs).

## (g) Etterlatt state
Scratchpad-kopier (320 MB) + URI-søppelfil: slettet, verifisert. uv-cache: sqlite-utils+8 deps, få MB delta (aksepteres; `uv cache clean sqlite-utils` fjerner). Levende db-er kun lest. Netto: ingenting utenom uvx-cache.

## (h) Eksakte kommandoer
```bash
S=<scratchpad>/sqlite-test; mkdir -p "$S"
cp ~/code/command-center/data/{command-center,brain-orchestrator}.db* "$S/"
cp ~/.claude/projects/-home-nithu-code/state/memory.db{,-wal,-shm} "$S/"
time uvx sqlite-utils --version                     # 2x: kald/varm
uvx sqlite-utils tables "$S/brain-orchestrator.db" --counts
uvx sqlite-utils query "$S/brain-orchestrator.db" "SELECT status, COUNT(*) c FROM agent_tasks GROUP BY status" | jq -c .
uvx sqlite-utils query "$S/memory.db" "PRAGMA integrity_check" | jq -c .
/usr/bin/time -v uvx sqlite-utils query "$S/memory.db" "SELECT date(created_at) d, COUNT(*) n FROM verbatim_exchanges GROUP BY d ORDER BY d DESC LIMIT 5"
# Fase 4 (writes mot KOPI): UPDATE via query GÅR; insert GÅR; chmod 444 = WAL-skjørt; immutable-URI = søppelfil
python3 -c "import sqlite3; sqlite3.connect('file:...?immutable=1', uri=True)"  # ekte read-only
rm -rf "$S"
```

— tools-1 (subagent-test, rammer per SANDBOX-TEST-PROTOCOL)
