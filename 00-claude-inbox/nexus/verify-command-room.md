# Verifisering: /command-room + /api/chief på LIVE prod

**Dato:** 2026-06-23
**Av:** code-1 (uavhengig prod-sjekk, READ-ONLY — kun curl mot live)
**Base:** https://dashboard-production-f342.up.railway.app
**Scope:** Kontrakt/HTTP/delta. Ikke browser (code-2 kjører Playwright parallelt). Ingen kode endret (ai-2 sin lane).

---

## TL;DR — verdikt

| Sjekk | Verdikt |
|---|---|
| `/command-room` health | **PASS** (med 1 falsk-positiv å ignorere) |
| `/api/chief` kontrakt | **DELVIS / FAIL i praksis** — ruter lever, men returnerer ALLTID `ok:false` fallback med `error:"empty text"` |
| Er Claude-reasoning live? | **NEI** — chief faller alltid tilbake. OG fallbacken er ødelagt (feil felt-navn mot jarvis) |

Kjernefunn: chief #183 produserer aldri et svar på prod. Den når aldri Claude (ANTHROPIC_API_KEY ser ut til å mangle på dashboard-tjenesten), OG den graceful-fallbacken til `/jarvis/ask` er feilkoblet — den sender feil request-felt, så jarvis svarer "I didn't get a question" → chief rapporterer `empty text`. Begge banene er døde. Dette er en ny regresjon i #183, ikke et nøkkel-problem alene.

---

## 1) /command-room — PASS

```
GET /command-room  →  HTTP 200 | 175 321 bytes | 0.67s
<title>Nexus — XAUUSD Investment Operating System</title>
```

**Innhold er ekte og rikt** (ikke en feilside):
- Command-Room-UI faktisk rendret i SSR: `Command Room`, `Listening` (x2), `Microphone`, `Speak`, `Voice`, samt `<h2>Your speech (private transcript)</h2>`.
- Boardroom-paneler tilstede som `<h3>`: Market, Strategy, Decision, Logs, Risk, System, Positions, Agents (full sett, duplisert = 2.5D spatial layout).
- Markør-treff i kilden: `agent` x15, `voice` x3, `command-room` x3, `orb` x2, `spatial` x1, `microphone` x1.

**Falsk-positiv å ignorere:** `"This page could not be found"` dukker opp 2x — MEN det ligger inni Next.js RSC-payloaden som standard `notFound`-boilerplate (`"notFound":[["$","title",...{"children":"404: This page could not be found."}]]`). Det er IKKE den rendrede body-en. Hver Next-app har dette. Siden returnerer 200 med ekte UI. **Ikke en reell feil.**

**WebGL canvas i SSR:** `<canvas>` = **0** i server-rendret HTML. Dette er forventet — vanilla three.js/WebGL-orben (#181) monteres client-side via JS etter hydrering, så 0 canvas i SSR sier ingenting om at orben er ødelagt. (Canvas-tellingen må bekreftes av code-2 sin Playwright-kjøring, ikke curl.)

---

## 2) /api/chief — FAIL i praksis

Ruter eksisterer og svarer:
```
GET  /api/chief                          → HTTP 405  (method routing OK)
POST /api/chief {"prompt":"..."}         → HTTP 200
```

**MEN responsen er alltid tom fallback**, uansett prompt:
```json
{"ok":false,"source":"fallback","decision":null,"error":"empty text"}
```

Testet med: `"why are we flat today?"`, `"what should I watch now?"`, `"give me a full briefing"`, `"summarize today"`, `{}` (tom), og med `context`-felt. **Alle** gir identisk `ok:false / source:fallback / error:"empty text"`.

### Forventet kontrakt vs faktisk
Spec'en (#183) lover strukturert output: `reasoning / answer / agents / zone / refined-prompt`. Faktisk shape på prod:
```
keys = ['ok', 'source', 'decision', 'error']
```
`decision` er null, ingen `reasoning/answer/agents/zone`. Den lovede strukturen materialiseres aldri fordi koden bailer i fallback-grenen før den fyller `decision`.

### Hvorfor — to lag som begge er nede

**Lag 1 (Claude):** `source:"fallback"` på hvert kall = ANTHROPIC_API_KEY er sannsynligvis IKKE satt på dashboard-tjenesten på Railway. Dette er den ventede no-key-oppførselen #183 beskriver. **Live reasoning er AV.**

**Lag 2 (graceful fallback til jarvis) — ødelagt:** Fallbacken skal kalle `/jarvis/ask` og returnere det deterministiske svaret. Den feiler med `"empty text"`. Rotårsak funnet ved å probe jarvis-backenden direkte:

`/api/proxy/jarvis/ask` leser input fra feltet **`text`**, ikke `prompt`/`question`/`q`/`message`/`input`/`query`:

```
POST /jarvis/ask {"prompt":"why are we flat today?"}  →  "I didn't get a question..."  (UNKNOWN)
POST /jarvis/ask {"text":"why are we flat today?"}     →   EKTE SVAR:
  {"action":{"type":"SHOW_EVIDENCE","topic":"no-trade",...},
   "answer":"We did trade — 1 trade today for $-554.",
   "evidence":[{"label":"Why no trade",...}], "source":"deterministic"}
```

Chief sender altså feil felt-navn til jarvis → jarvis returnerer UNKNOWN med tom `action.text` → chief tolker det som `empty text` og gir opp. **Fallbacken ville fungert hvis chief sendte `text` i stedet for `prompt`.** Dette er en ren kontraktbug i #183, uavhengig av API-nøkkelen.

---

## Anbefalte fikser til ai-2 (deres lane — kun forslag, ikke rørt)

1. **Fallback-felt-bug (høyest prioritet, rask):** I `/api/chief`-fallbacken, kall jarvis med `{"text": prompt}` (ikke `prompt`/`question`). Da blir minst den deterministiske banen levende og gir ekte live-data ($-554 / 1 trade i dag).
2. **Live reasoning:** Sett `ANTHROPIC_API_KEY` på dashboard-Railway-tjenesten for å aktivere Claude-grenen (modell claude-opus-4-8 per spec). Til da: `source` vil forbli `fallback`.
3. **Verifiser strukturert shape** etter (1)+(2): bekreft at `decision` fylles med `reasoning/answer/agents/zone/refined-prompt` som spec'et.

## Note til prior audit (DASHBOARD-AUDIT-REPORT)
- G2 `api.jarvisAsk()`: jarvis-backenden returnerer ekte live-data ("We did trade — 1 trade today for $-554") når riktig felt brukes — dataene ER tilgjengelige, det er kontrakt-koblingen som svikter i chief.
- R1/G1 home-briefing trust-bug: jarvis bekrefter fortsatt $-554 / no-trade på live. Ikke verifisert om home er wiret denne runden (utenfor scope; chief var fokus).
