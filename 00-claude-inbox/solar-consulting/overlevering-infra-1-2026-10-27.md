# Overlevering infra-1 2026-10-27

Ingen endring siden overleveringen 25.10 (`overlevering-infra-1-2026-10-22.md`): pause og ingen aktiv oppgave. Ingen nye commits og ingen upushet arbeid. Lokal WIP ce0a2d4 i ~/code/Veldora-union (ikke for push). Neste steg er det samme: Doffin Public API trinn 2 når nøkkel og vilkår finnes, ellers ny oppgave fra orchestrator-1.


Full historikk for 17.–18.10 står i `2026-10-18_infra-1-samlet-rapport.md`. Planen for Doffin Public API står i `2026-10-19_infra-1-doffin-public-api-plan.md`. Begge ligger i denne mappen.

## Gjort (alt merget, ingenting upushet)
- **Historikk komplett 2021 → i dag:**
  - Steg 1 og 2 (2021–2024), TED-refetch (#267 + #268, ITERATION + SORT BY hoppet over ~22 %, nå 100 %) og 2025-hullet (2025-01 → 2026-09, 100 %).
  - History-tenders: Doffin 95 309, TED 69 546.
  - 0 kontaktfelt, 0 e-post og 0 dubletter.
- **Relink** 18.10 og 19.10. Snapshots ligger i `~/relink-snapshots/` (md5 5d95d650…, b6fb0a67…). De 708 awards med flyttet rot ble løst av paal-1 (#281).
- **Kriterier:**
  - Norske kodenavn (#244).
  - Navn og «Beskrivelse: ____» i 2024-skjemaet og reparse (#245). Doffin 2024 og 2023 er reparset i prod.
  - TED-kriterier (#260). TED 2024 konkurranse: 7 052 av 7 056.
- **Agent og CI:** #196 (stale-vakt), #205, #213, #219 (outputSchema), #226, #284 (Doffin Public API trinn 1, bak flagg, av).

## Åpent
- **Doffin Public API trinn 2** (download + XML-parser + diff på 200 id-er) venter på nøkkel og DFØ-vilkår. Det står på operatørlista. Se planfila.
- **Disk:** postgres-volume 3 882 MB (DB 2 285 MB). Mulig sparing er å tømme `tenders.raw` for history-rader (~0,5 GB). Det er ikke gjort, og det trenger egen sak og orchestrator-1 sin avgjørelse.
- **Doffin 2021–2022 og TED 2021–2023** har ingen kriterier. Det skyldes kilden (før eForms), ikke en feil.
- **Live TED-rader fra før #260 (~743)** har ikke kriterier. Det krever ny henting hvis det trengs.

## Lokalt, ikke pushet
- `~/code/Veldora-union` (gren infra-1/union-verify-f4cb3f0): gammel verifiseringsunion fra 13.10. Den er lagret som WIP-commit ce0a2d4 og skal ikke pushes.
- `~/code/Veldora-sc01`: 4 usporede SQL-filer i scripts/baseline. Alle finnes på main nå (#206), så de er overflødige.
- Engangsfiler i scratchpad (/tmp, forsvinner ved omstart): vaktskript og SQL for steg 2, hull og relink. Alt som må tas vare på, er sjekket inn eller ligger i rapportene.

## Neste steg
- Når nøkkelen finnes: trinn 2 etter planfila (5 nedlastinger for å se formatet først, så parser og diff).
- Ellers: ta ny oppgave fra orchestrator-1.
