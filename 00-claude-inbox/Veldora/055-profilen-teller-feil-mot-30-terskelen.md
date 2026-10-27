# 055: `profileN` teller rader profilen selv ekskluderer
Type: AFK
Status: open
Priority: laering
Eier: code-1-lanen (meldt videre av learning-1, ikke tatt — rører `endpoints/triage.ts`)

## Hvorfor

`FACT` `crm/src/endpoints/triage.ts:305`:

```ts
profileN: profile?.n ?? decidedCount,
```

`decidedCount` er `payload.count` over `opportunities` der `decision != 'UNDECIDED'`
(`endpoints/triage.ts:277-278`). `profile.n` er antallet **lærbare** rader den siste
profilbyggingen så (`crm/src/lib/learning/profile.ts:197` ← `learnableRecords`, `profile.ts:44`),
og `isLearnable` (`profile.ts:41`) ekskluderer rader med årsakskoden `not-a-tender`.

Fallbacken teller altså noe annet enn tallet den erstatter. Når `decision-profile`-globalen mangler,
er aldri bygget, eller avvises av `profileOf` (`crm/src/lib/triage.ts:514-517`), viser UI-et en
framgang mot 30-terskelen som er **for høy** — den inkluderer rader læringen kaster.

`FACT` (målt i prod 2026-10-13, `crm/eval/sakstype-kryss-2026-10-13.txt`, tag `LAERBAR`): 6 rader
har `not-a-tender` i dag. Avviket er altså 6 av 105, og det vokser med hver dialog som markeres
riktig. Terskelen er for lengst passert (105 beslutninger mot 30), så feilen er ikke akutt — men
den er en stille feilkilde i det ene tallet operatøren bruker for å vurdere om læringen er i gang.

Første gang meldt 2026-10-11 med feil linjenummer (120). Riktig linje er 305.

## What to build

Én linje: la fallbacken telle det samme som `profile.n` gjør, eller ikke falle tilbake i det hele
tatt. Forventet diff:

```ts
// før
profileN: profile?.n ?? decidedCount,
// etter — forslag A (ærlig ukjent)
profileN: profile?.n ?? null,   // ingen profil ⇒ vi vet ikke, ikke «like mange som besluttede»
```

Forslag A er å foretrekke framfor å reimplementere `isLearnable` i endepunktet: to kopier av
lærbarhetsregelen er nettopp feilklassen som skapte dette. `null` tvinger klienten
(`dashboard/src/lib/triage.ts:334-336`, `LearningStatus.tsx:47-51`) til å vise «profil ikke bygget»
i stedet for et oppdiktet framgangstall — men det krever at klienten håndterer `null`, så det er
to filer, ikke én.

## Acceptance criteria

- [ ] `profileN` er aldri et tall som stammer fra en annen populasjon enn profilen.
- [ ] Mangler profilen, sier UI-et det, i stedet for å vise framgang mot 30.
- [ ] Lærbarhetsregelen finnes fortsatt på **ett** sted (`profile.ts:41`), ikke kopiert inn i endepunktet.
- [ ] Test som skriver en `not-a-tender`-beslutning og sjekker at den ikke flytter `profileN`.

## Kilder

- `crm/src/endpoints/triage.ts:277-278,305` · `crm/src/lib/learning/profile.ts:41,44,197`
- `crm/src/lib/triage.ts:514-517` · `dashboard/src/lib/triage.ts:18,334-336`
- `crm/src/endpoints/triage.test.ts:144` (pinner dagens verdi — må oppdateres sammen med fiksen)
- `~/Obsidian/Brain/00-claude-inbox/Veldora/2026-10-11_triage-laering.md` (første melding, feil linjenr.)
