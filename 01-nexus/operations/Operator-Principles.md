---
tags: [nexus, ops, operator-principles]
type: atomic
created: 2026-05-08
---

# Operator-Principles

Six binding prinsipper for any Claude session on any device. Established 2026-04-21 after the demo-mode auto-degrade incident. Source: `CLAUDE.md` + `_repo-docs/ops/operator-decisions.md`.

Override only with **explicit in-session operator OK** AND an entry under "Midlertidige unntak" in `_repo-docs/ops/phase-status.md`.

## The six prinsipper

1. **Ingen auto-disable** av strategier, gates eller flagg basert på anomali-deteksjon. Health-check RAPPORTERER via Discord / morgenbriefing. Operator beslutter handling.
2. **Data skal aldri stoppes.** Selv under opprydding av minne-lag: fact-agents, analysis-agents, persistence-tabeller fortsetter å skrive. Ryddingen skjer på hvilke typer som beholdes. See [[Module-Fact-And-Analysis-Agents]].
3. **Små ryddende justeringer kan være automatiske** — dedupe, TTL, retention, kuratering av lav-verdi minne-poster. Ingen atferdsendringer i trading-loopen uten operator-OK.
4. **Foundation-først:** før ny strategi legges til, må alle 5 regler i [[Foundation-Gate]] være grønne. Claude skal nekte å fortsette med strategi-arbeid hvis noen er røde.
5. **"OK kjør"-gate** før hver push. Ingen unntak. See [[OK-Kjor-Gate]].
6. **Selvfiks / autotune er langsiktig.** Ikke tidligere enn 30+ dagers data + eksplisitt operator-godkjenning. Frem til da: rapporter, ikke handle.

## Removed: prinsipp 5 (one change per session)

Removed 2026-05-03 after operator stacked 12 commits + 10 firm-agents in one session. Throttling rate of work disproportionately to risk. Stacking is OK when it makes sense. Original "OK kjør"-gate is now the new prinsipp 5.

## Why these exist

Codified after demo-mode auto-degrade put the system into `LEARNING_ONLY_DEMO` for 24h on a -$1,613 realized loss — the safety triggered without operator approval. Lesson: the system had agency it shouldn't have had. Prinsipper 1, 2, 5 directly address that class of failure.

## Related

- [[Foundation-Gate]] — prinsipp 4
- [[OK-Kjor-Gate]] — prinsipp 5
- [[Demo-Mode]] — prinsipp 1 in action: demo-mode now reports, doesn't auto-disable
- [[Module-Fact-And-Analysis-Agents]] — prinsipp 2 binding
- [[Strategy-Promotion-Workflow]] — prinsipp 4 + 5 binding
- [[Module-Agent-Bus]] — prinsipp 6 binding (autotune deferred 30+ days)
