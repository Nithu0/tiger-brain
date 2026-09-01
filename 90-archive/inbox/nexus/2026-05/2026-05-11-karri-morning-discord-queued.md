---
created: 2026-05-11T19:48+02:00
queued_for_send: 2026-05-12T09:00+02:00 (07:00 UTC)
target: Karri (Discord webhook)
status: QUEUED — DO NOT SEND BEFORE 09:00 CET 12.5
reason: 19:48 CET is outside work hours (09-17 CET per feedback_auto_send_karri.md)
---

# Karri morning Discord — kveldsoppdatering 11.5 → send 12.5 morgen

## Send-instruksjon

Fire av én av disse i morgen mellom 07:00–09:00 UTC (09:00–11:00 CET):

### Option A — single-line paste-bar

```bash
WEBHOOK="https://discordapp.com/api/webhooks/1502236192450547794/xq01VVj3h7P5fj3Uj3kDd9be57GYw16PBlcV_c9cCgM90QwBX5zXtwl9gAaJVsr_gUhE"; \
curl -sS -o /tmp/karri-morn.out -w "HTTP %{http_code}\n" -X POST -H "Content-Type: application/json" \
  --data @/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-karri-morning-discord-queued.json \
  "$WEBHOOK"
```

(Expect HTTP 204.)

### Option B — step-by-step (if payload split into 4 messages)

Discord webhooks accept up to 10 embeds per POST, so the 4 embeds below ship in **one** request. Bruk Option A.

---

## JSON-payload (4 embeds i én melding)

Skriv denne til `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-karri-morning-discord-queued.json` før send:

```json
{
  "content": "Yo Karri — kort kveldsoppdatering. Implementerte dine 5 TIER 1 proposals umiddelbart etter PR #1, alle env-gated default-off så ingen prod-impact før operator flipper. Sammendrag her:",
  "embeds": [
    {
      "title": "5 TIER 1 proposals: implementert + venter på operator-flipp",
      "color": 3066993,
      "fields": [
        {
          "name": "1. regime_direction_gate",
          "value": "Flag: `REGIME_DIRECTION_GATE_ENABLED=true`\nCommit: TBD (fyll inn morgen)\nEstimat: +$2-3k / 30d (counter-trend blokk)",
          "inline": false
        },
        {
          "name": "2. session_block_gate",
          "value": "Flag: `SESSION_BLOCK_ENABLED=true` + `SESSION_BLOCK_LIST` tunable\nCommit: TBD\nEstimat: -$3683 unngåtte tap",
          "inline": false
        },
        {
          "name": "3. sl_cooldown",
          "value": "Flag: `SL_COOLDOWN_ENABLED=true` + `SL_COOLDOWN_MINUTES=60`\nCommit: TBD\nEstimat: +$1023 / 30d",
          "inline": false
        },
        {
          "name": "4. scalp_overlap_observe_only",
          "value": "Flag: `SCALP_OVERLAP_ENABLED=false` (eksisterende, ingen kodendring)",
          "inline": false
        },
        {
          "name": "5. orb_observe_only",
          "value": "Flag: `ORB_ENABLED=false` (eksisterende, ingen kodendring)",
          "inline": false
        }
      ],
      "footer": { "text": "Alle endringer env-gated, default-OFF, rollback < 30s via Railway-flagg." }
    },
    {
      "title": "Anbefalt utrullings-rekkefølge",
      "color": 16776960,
      "description": "**1.** Først (stop bleeding): `scalp_overlap` + `orb` observe-only (env-flag flip, instant effekt)\n**2.** Etter 1-2t observasjon: `session_block_gate` (blokker tap-sessions)\n**3.** Etter 1 dag observasjon: `regime_direction_gate` (counter-trend blokk)\n**4.** Etter 1 dag observasjon: `sl_cooldown` (60-min cooldown)\n**5.** Hold `conviction_quartile` (Phase 1 widget only) + `vol_exp_throttle` (Phase 1 instrumentation) + `postmortem_streak` (Phase 1 table) — alle instrumentation, ingen behavioral effekt"
    },
    {
      "title": "Andre Phase 1-implementeringer (instrumentation only)",
      "color": 3447003,
      "description": "Også implementert i kveld som Phase 1 (instrumentation only, no behavior):\n• **postmortem_size_down_feedback Phase 1** — streak-table schema + tracking\n• **conviction_quartile_position_sizing Phase 1** — dashboard widget for distribution observation\n• **vol_expansion_throttle_review Phase 1** — 5-stage rejection-tagging"
    },
    {
      "title": "Spørsmål til deg når du er klar",
      "color": 15158332,
      "fields": [
        {
          "name": "regime_direction_gate",
          "value": "Trenger `TRENDING_UP`/`TRENDING_DOWN`-klassifisering — bekrefter du H4-EMA-slope er riktig metode?",
          "inline": false
        },
        {
          "name": "session_block_gate",
          "value": "Er `OVERLAP_ACTIVE` + `NY_OPENING_RANGE` riktig default-list, eller skal vi inkludere flere?",
          "inline": false
        },
        {
          "name": "sl_cooldown",
          "value": "60 min OK eller skal det være variabel per strategi?",
          "inline": false
        }
      ]
    }
  ]
}
```

---

## Pre-send checklist (i morgen tidlig)

1. **Bekreft commit-SHAer** for regime_direction_gate / session_block_gate / sl_cooldown og bytt ut `TBD` i payloaden. Hvis disse IKKE er implementert enda (sjekk `git log --oneline -20` i prosjektet) — IKKE send. Reframe meldingen som "venter på implementasjon" først.
2. **Bekreft webhook fungerer:** test curl returnerer HTTP 204.
3. **Sjekk tid:** 09:00 CET = 07:00 UTC. Ikke send før 09:00 CET.
4. **Etter send:** memo til inbox med "sent at HH:MM UTC".

## Override

Operator kan si "vent" / "hold" → ikke send i morgen heller. Eller "send nå" → fyrer av umiddelbart uten tids-gate.
