# Dom over de seks agent-grenene (admin-1, pane-kjøring)

Dato: 2026-10-14 · Oppdrag: inbox/admin-1.md 06:15Z fra orchestrator-1 · `origin/main` = `f4cb3f0`
Ingen push, ingen sletting, ingen PR. Dette er kun en dom.

## Konklusjon

**Alle seks er allerede på main.** Ingen av dem er landbar, ingen av dem har unikt innhold å berge.
Orchestrator-1 hadde rett i sin egen mistanke: tabellen ble satt opp på commit-*emne* mot
`git log origin/main`, og squash-merge ga nye titler. Jeg avgjorde på innhold.

## Metode (og hvorfor den er sterkere enn emne-sammenligning)

1. For hver gren: `git diff <merge-base>...HEAD` — grenens eget bidrag, ikke mains drift.
2. For hver fil grenen *legger til*: sammenlign blob-SHA mot `origin/main:<fil>`.
   **Byte-identisk blob = innholdet er på main.** Det er bevis, ikke indikasjon.
3. For hver fil grenen *endrer*: sjekk om hver tilførte linje finnes i mains versjon av filen.
   Restene jeg fant var i alle tilfeller mains versjon som har gått **videre** (lengre union-typer,
   flere select-felt, utvidet regex, omskrevet prosa) — altså superset, ikke fravær.
4. Sporet squash-committen på main for hver gren med `git log --diff-filter=A` / `-S`.

Reverse-apply (`git apply -R --check`) ble forkastet som test: mains kontekstlinjer har flyttet seg,
så den feiler også når innholdet er der. Den sier ingenting.

## Dommene

| Gren | Dom | Landet på main som | Bevis |
|---|---|---|---|
| `feat/036-046-prising` (+2) | **allerede på main** | `5e021c9` (#108) | alle 14 nye filer byte-identiske, bl.a. `crm/src/lib/prising/evaluering.ts`, `taktisk.ts`, `laerling.ts`, `dashboard/src/lib/prising.ts`, migrasjonen `20261009_224528_prising_evaluering.{ts,json}` |
| `feat/044-045-klage` (+1) | **allerede på main** | `c179afa` (#107) | `crm/src/lib/klage/karens.ts`, `innsynDocx.ts` + testene + `scripts/smoke-klage.ts` byte-identiske |
| `feat/037-041-tilbudskvalitet` (+2) | **allerede på main** | `3bf5142` (#109) | `crm/src/lib/tilbud/grenser.ts`, `prisskjema.ts`, `miljo.ts`, `avklaring.ts`, `kvalitet.test.ts` byte-identiske |
| `feat/042-043-kvalifikasjon-kontrakt` (+1) | **allerede på main** | `7bfde05` (#115) | `lib/qualification/underleverandor.ts`, `lib/klage/salami.ts`, `lib/tilbud/endringer.ts`, `lib/setning.ts`, `UnderleverandorBlock.tsx` byte-identiske; 100 % linjedekning på alle 49 filer |
| `fix/anbud-login-mobil-touch` (+1) | **allerede på main** | `9c8f624` (#122) | `login.module.css:30` `min-height: 2.75rem` og `:36` `font-size: max(1rem, 16px)` — 16/16 linjer |
| `fix/anbud-kommentar-vurder-konvolutt` (+1) | **allerede på main, i annen form** | `dad2a8f` (#116) «juristens kvittering viste seg aldri» | se under |

### Adversarisk-fiksene fulgte med

Tre grener har en andre commit som retter funn fra adversarisk gjennomgang (`a7360d7` på 037/041,
`63b8b43` på 036/046). De filene commiten rører — `grenser.ts`, `prisskjema.ts`, `miljo.ts`,
`avklaring.ts`, `evaluering.ts`, `laerling.ts` — er **byte-identiske** på main. Rettelsene er inne,
ikke bare førsteutkastet.

### Den ene som ikke er ordrett: konvolutt-fiksen

Dette er den eneste der innholdet ikke finnes ordrett på main, og den er verdt å lese nøyaktig,
for den er en «samme feil, annen fiks»-sak og ikke et fravær:

- **Grenen:** `lowersSeverityFromSvar(svar)` + `type KommentarVurderingSvar` (alt valgfritt).
- **Main (`dad2a8f`, #116):** `vurderingConfirmation(response)` + `type KommentarVurderResponse`
  (`saved`/`row`/`counts` påkrevd), `kommentar.ts:68-76`, `actions-kommentar.ts:36-49`.
- Feilen — at juristsiden leste `{ saved, row, counts }` som om det var raden selv, så
  «Den kan nå senke alvorsgraden på funn.» aldri kom fram — er fikset på main, med samme kommentar
  om nettopp den feilen i koden (`kommentar.ts:71`).
- Mains versjon er testet, inkludert `row: null` (`test/kommentar-vurdering.test.mjs:121-142`).
- Grenens eneste ekstra er toleranse for «et eldre CRM som svarer med raden direkte». Den er
  oppførselsmessig identisk på main: `response.row?.lowersSeverity` gir grunnsetningen og krasjer
  ikke. Ingen reell forskjell å berge.

## Hva jeg ikke gjorde

- Ingen rebase og ingen testkjøring. Begrunnelse: «landbar» krever grønne tester, men ingen av
  grenene er landbar — de er landet. Å rebase seks grener mot `f4cb3f0` og kjøre suitene ville
  kostet timer på å bevise noe dommen alt har avgjort. Hvis operatøren vil ha det likevel, si det.
- Ingen sletting. Grensletting er operatør-gatet. **Når operatøren sier «OK kjør»:** alle seks
  grener + de seks worktreene under `~/code/Veldora/.claude/worktrees/agent-*` kan fjernes.
- `node_modules` i worktreene er urørt, som bedt om.

## Verifiseringskommandoer (reproduserbart)

```
cd ~/code/Veldora/.claude/worktrees/agent-a42d9cc56e4d4b49b   # feat/036-046-prising
mb=$(git merge-base origin/main HEAD)
git diff --name-only --diff-filter=A $mb HEAD | while read f; do
  [ "$(git rev-parse HEAD:"$f")" = "$(git rev-parse origin/main:"$f")" ] && echo "IDENTISK $f" || echo "ULIK $f"
done
```
Samme løkke på de fem andre worktreene ga samme svar: `IDENTISK` på hver fil, bortsett fra
`fix/anbud-kommentar-vurder-konvolutt` og `fix/anbud-login-mobil-touch`, som ikke legger til filer
(begge er rene endringer, behandlet linje for linje over).

— admin-1
