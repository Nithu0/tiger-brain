# tools-1: telegram-mcp-piloten forberedt til operatør-gatene (2026-08-14)

Oppfølging av sandbox-verdicten 09.08 (PILOT nå, m/dedikert konto), bestilt av
orchestrator-1 (job-20260814-161612). **Ingen gater krysset:** ingen konto
opprettet, ingen session-string generert, ingenting startet eller enablet.
Alt ligger på branch `tools-1/telegram-mcp-pilot` (commits `26d94f2` + `5ebee7b`),
upushet — venter verdict-flyt.

## Leveranser

| # | Hva | Hvor |
|---|---|---|
| 1 | Compose-utkast: build fra pinnet klon (`dc8c8555`, ALDRI PyPI), `TELEGRAM_EXPOSED_TOOLS=read-only` HARDKODET (ikke .env-lesbar), non-root, 127.0.0.1:8765, eget docker-nett, read-only fs, cap_drop ALL, `restart: "no"` | `docs/deploy/telegram-mcp/docker-compose.yml` |
| 2 | systemd --user unit-UTKAST (ikke installert/enablet): docker-venteloop + SHA-pin-håndhevelse i ExecStartPre, --env-file på både up og down | `docs/deploy/local-systemd/telegram-mcp.service` (+ README-rad) |
| 3 | Variabelnavn (aldri verdier): `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`, `TELEGRAM_SESSION_STRING` | `.env.example` |
| 4 | Runbook: de fire operatør-stegene + fire eksplisitte forbehold | `docs/ops/RUNBOOK-telegram-mcp-pilot.md` |

Støtte: upstream klonet til `/home/nithu/code/vendor/telegram-mcp` på den
sandbox-testede SHA-en; imaget prøvebygget derfra (`telegram-mcp-pilot:dc8c8555`,
169 MB, aldri startet). Compose validert (`config`), unit validert
(`systemd-analyze --user verify`), alle upstream-fakta (env-navn, port 8765,
/mcp-path, non-root appuser, read-only-prune-semantikk) verifisert mot kildekoden
på pinnet SHA.

## De fire operatør-stegene (kortversjon — full detalj i runbooken)

1. **Dedikert intake-konto** — nytt nummer, **2FA-skypassord obligatorisk**
   (se under), få chats; api_id/api_hash fra my.telegram.org → nano inn i .env.
2. **Interaktiv session-generator** — `uv run --env-file .../command-center/.env
   session_string_generator.py` i vendor-klonen; svar N på generatorens tilbud
   om å skrive .env selv.
3. **Session-string via nano** inn i command-center/.env (gitignored).
4. **systemd-enable-beslutning** — foreground-test med `--build` først (4a);
   enable (4b) er valgfritt utfall.

## Forbeholdet (gjentatt, viktigst først)

**Telethon = full kontoautoritet i prosessen.** Read-only-gaten begrenser bare
hva LLM-en får kalle — ikke hva prosessen (eller noen med docker-tilgang) kan
gjøre. Derfor aldri hovedkonto. Code-reviewen skjerpet dette til fire konkrete
forbehold i runbooken: (2) uten 2FA kan read-only-flaten ALENE gi
kontoovertakelse (login-koder er lesbare meldinger); (3) `docker inspect` viser
session-stringen for alle lokale docker-prosesser etter start; (4) endepunktet
er uautentisert på loopback — alle lokale agenter kan lese intake-flaten, og
den aksepten er en del av steg 1-beslutningen (lav-verdi-konto).

## Code-review (high, 8 finder-agenter) — 4 blockere funnet og lukket

1. `compose down` uten `--env-file` feilet på `:?`-interpolasjonen → kill-switch
   og ExecStop var ødelagt som skrevet (reprodusert empirisk). Fikset.
2. Runbook-steg 2 feilet: generatoren spør ikke om api_id/hash (leser env).
   Stegene omorganisert. Fikset.
3. `restart: unless-stopped` lot dockerd gjenopplive containeren etter
   systemd-disable → `restart: "no"`, systemd er eneste restart-autoritet. Fikset.
4. Boot-race: `network-online.target` finnes ikke i user-manageren → unit-en
   kunne strande i failed etter hver treg boot. Docker-venteloop + RestartSec=30. Fikset.

Pluss herdinger: SHA-pin gjort til mekanisme (ExecStartPre-sjekk), eget
docker-nett (default-bridge-eksponering lukket), `MCP_ALLOWED_HOSTS` hardkodet
(DNS-rebinding-vern på), 2FA-krav i steg 1, `docker rm -f` som ubetinget
kill-fallback, forventet read-only-fs-WARNING dokumentert i verify-stegene.

**Åpent (bevisst ikke gjort):** docs/SECURITY.md nevner ikke den nye
agent-tilgjengelige flaten — aksept-beslutningen står i runbooken; om den skal
speiles i SECURITY.md er operatørvalg ved enable.

— tools-1, 2026-08-14
