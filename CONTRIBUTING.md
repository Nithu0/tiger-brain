---
title: CONTRIBUTING
type: meta
tags: [meta, workflow, contributing]
created: 2026-05-11
---

# CONTRIBUTING — Brain vault

Kort guide for hvordan bidra til denne vaulten. Les [[BRAIN-RULES]] først, og [[TEAMMATE-ONBOARDING]] hvis du er ny.

## Hvem dette er for

- **Operator (Nithu)** — eier vaulten, gjør alle strukturelle endringer.
- **Teammate** — bidrar primært i Nexus-området (`01-nexus/`) og Claude-inboks (`00-claude-inbox/nexus/`).

Alle andre lesere kan se innholdet, men endringer går gjennom PR.

## Branching

- `feat/<short-slug>` — nytt innhold (notes, runbooks, decision drafts)
- `fix/<short-slug>` — bugfixes (broken links, typos, frontmatter)
- `chore/<short-slug>` — tooling, frontmatter sweeps, lenkeopprydding
- **Aldri push direkte til `main`.** Alt går gjennom PR.

## Local checks før push

Kjør disse i repo-roten før du pusher:

```bash
python scripts/brain_audit.py
python scripts/path_guard.py --base main --head HEAD
```

Hvis enten faller, fiks før du pusher. Ikke hopp over.

## Commit message style

Kort prosa med type-prefix. En linje er nok for de fleste commits.

- `note: add XAUUSD asia-session checklist`
- `fix: broken wikilink in nexus/runbooks/start-of-day`
- `chore: frontmatter sweep on 01-nexus/`
- `runbook: add EOD reconciliation steps`
- `decision: ratify ADR-014 on slippage budget`

Multi-line bodies er OK når "hvorfor" trenger forklaring. Hold subject under 72 tegn.

## PR workflow

1. Push branchen din.
2. Open PR mot `main`.
3. Fyll ut PR-templaten (alle seksjoner).
4. Vent på CODEOWNERS-godkjenning. Ikke merge selv før det er approved.
5. CI må være grønn (`brain_audit`, `path_guard`).
6. Hvis du har redigert beskyttede mapper, må operator legge til en `OPERATOR-APPROVED: <reason>` linje i PR-beskrivelsen.

## Folder rules

Se [[BRAIN-RULES]] for den kanoniske listen. TL;DR:

- Teammate kan fritt redigere: `01-nexus/**`, `00-claude-inbox/nexus/**`, `_promote-candidates/**`
- Alle andre mapper krever operator-OK.
- Aldri rename/move MOCs eller flytt mapper uten å spørre først.

## Secrets policy

- **Aldri** commit `.env`, `.env.local`, broker credentials, API keys, eller tokens.
- Hvis du ved et uhell committer en hemmelighet:
  1. Kontakt operator umiddelbart (Discord/email).
  2. Roter hemmeligheten på kilden (broker/exchange/API provider).
  3. Force-push fjerning skjer **kun** etter koordinering med operator — ikke gjør det alene.
- `.gitignore` dekker de vanlige tilfellene, men ansvar ligger hos commiter.

## Oppsett

- Se [[TEAMMATE-ONBOARDING]] for day-1 walkthrough.
- `scripts/setup-from-scratch.sh` (easy + advanced moduser) gir samme oppsett som operator bruker — kjør det hvis du vil ha full parity.

## Spørsmål

Pinger du operator på Discord eller email. Ikke gjett deg fram på beskyttede områder.
