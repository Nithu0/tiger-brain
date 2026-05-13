---
tags: [meta, moc, graph-view]
type: meta
created: 2026-05-13
---

# Graph-View-Curation

Vedlikeholdsnote for å holde Obsidians Graph View lesbar etter hvert som brain-vaulten vokser (~250+ noter på tvers av `01-nexus`, `02-thesis`, `_maps`, `_decisions`, `_runbooks`, ...).

## 1. Hvorfor Graph View betyr noe her

Graph View er ikke pynt — det er en helsesjekk:

- **Klynger** synliggjør domener (hver MOC danner sin egen klynge)
- **Orphans** (oransje, ulinkede noder) markerer stubs som mangler innkommende lenker
- **Tilfeldige hairballs** avslører noter som er blitt "kjøkkenvask"-hubber uten at jeg har ment det
- Når grafen blir uleselig, har brain-strukturen drevet — det er signal, ikke støy

## 2. Hva gjør grafen lesbar

- **Hub-and-spoke**: hvert domene har en MOC; atomiske noter lenker til MOC-en, MOC-en lenker utover
- **Type-tagget frontmatter** (`type: moc | atomic | meta | decision | runbook | strategy`) → fargekodes i Graph View-innstillinger
- **Toveis tetthet**: noter lenker tilbake til sin MOC OG fremover til naboer (ikke bare en retning)
- **Stub-lenker** (oransje noder) fungerer som synlige "to-write"-markører — ikke skjul dem, bruk dem

## 3. Hva gjør den til en hairball

- En enkelt note som lenkes fra 50+ steder → ser ut som en bevisst hub, men er ofte en uhellsmagnet
- Noter uten innkommende lenker (orphans) som ikke er MOC-er → roter periferien
- Selvlenker og sirkulære-bare-klynger uten utgang
- Long-tail single-link-noter utenfor noen MOC → "ensomme atomer" som ikke hører noe sted

## 4. Helsemetrikker (kjør fra vault root)

```bash
# innkommende lenker per note (top 10 hubber)
grep -rEo '\[\[[^]]+\]\]' --include='*.md' | sed -E 's|.*\[\[||;s|\]\]||' | sort | uniq -c | sort -rn | head -10

# utgående lenker per note (top 10 eiker)
for f in $(find . -name '*.md' -not -path './.git/*'); do
  n=$(grep -Eo '\[\[[^]]+\]\]' "$f" | wc -l)
  [ "$n" -gt 0 ] && echo "$n $f"
done | sort -rn | head -10

# orphans (ingen innkommende lenker) — tregere
# se full audit i scripts/brain_audit.py
```

Tommelfingerregler for tallene:
- Top-hub med >20 innkommende: vurder splitting
- Note med 0 innkommende og ikke MOC: kandidat for opprydning
- Note med >15 utgående og ikke MOC: enten gjør den til MOC eller del opp

## 5. Prunerregler (når man skal fikse)

| Symptom | Fix |
|---|---|
| Hub-overbelastning (>20 innkommende) | Splitt i sub-MOC-er (f.eks. `Nexus-Strategies-MOC` separat fra `Nexus-Ops-MOC`) |
| Orphan (ingen innkommende, ikke MOC) | Lenk fra en MOC, arkiver, eller slett hvis foreldet |
| Hairball-klynge | Identifiser hub-en som forårsaker det, splitt eller de-lenk |
| Sirkulær klynge | Legg til minst én utgang til en MOC |
| Long-tail enslig | Plasser i nærmeste MOC eller arkiver |

## 6. Graph View-innstillinger (anbefalt)

**Color groups**:
- `tag:#moc` → blå
- `tag:#strategy` → grønn
- `tag:#decision` → rød
- `path:90-archive/` → grå (falmet)

**Filters**:
- Skjul `90-archive/**`
- Skjul `_promote-candidates/`
- Skjul `00-claude-inbox/` (fokus på stabil kunnskap, ikke inbox-støy)

**Forces**:
- Høy repulsion (separerer klynger)
- Medium attraction (klynger holder sammen)
- Lav center force (lar grafen flyte fritt)

## 7. MOC-konvensjoner (kort reminder)

Se `[[_maps/_README]]` for full spec. Kjernen:

- MOC-er er **innholdsfortegnelser**, ikke avhandlinger
- Kort beskrivelse + mange lenker
- Hver MOC har `type: moc` i frontmatter
- Hver MOC lenker både ned (til atomer) og opp (til parent-MOC hvis relevant)

## 8. Frekvens

- **Ukentlig**: rask sanity-glans på Graph View — ser klyngene rene ut? Noen åpenbare hairballs?
- **Månedlig**: kjør helsemetrikker ovenfor, prun etter pruner-reglene
- **Ad hoc**: når Graph View ser "feil" ut etter en stor batch med nye noter → strukturen har drevet

## 9. Relaterte

- `[[_maps/_README]]` — MOC-konvensjoner og brain-struktur-oversikt
- `[[BRAIN-RULES]]` — overordnede regler for hva som hører hjemme hvor
- `[[When-Brain-Structure-Drifts]]` — symptomer og fix når strukturen sklir
- `[[Memory-MOC]]` — minne-domene
- `[[Tools-MOC]]` — MCP/tooling-domene

---

Sist oppdatert: 2026-05-13
