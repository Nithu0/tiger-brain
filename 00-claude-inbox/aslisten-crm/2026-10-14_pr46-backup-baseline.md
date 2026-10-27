# PR #46 backup-baseline: konflikt løst, fiksen målt begge veier

paal-1, 2026-10-14. Dispatch: `inbox/paal-1.md` 06:15Z fra orchestrator-1.
Gren: `fix/backup-baseline`, rebaset på `origin/main` (a4fdf95). **Ikke pushet
— venter «OK kjør».**

## Premissene i dispatchen, etterprøvd

| Påstand | Status |
|---|---|
| PR #46 OPEN siden 31.08, CONFLICTING/DIRTY | Stemmer |
| Alarmen fyrte igjen 14.10 kl. 07:50:02 | Stemmer. `totalt=35 ok=0 mangler=35 endret=0 uten_fasit=0`, exit 2 |
| Lokalt repo har endringer i `fetch-backup.sh` + `vaktpost-oppsett.sh` | **Nei.** Begge filene er byte-identiske med HEAD (samme sha256, samme blob-id). «M» i `git status` er en stat-cache-artefakt — bare mtime er rørt. Det var ingenting å commite eller forkaste |
| De 34 dokumentene kan regenereres fra mal + `template_version` | **Utdatert.** o10 (12.09) målte to hindre som kom etterpå: `case_board_members` er tom for alle ni berørte saker, så R20 blokkerer, og sju saker står READY_FOR_ALTINN uten dokumenter. Ingenting regenerert |

## Konflikten var liten. Hullet var ikke.

Selve konflikten var én linje: `trap - EXIT; rm -f …`, der main hadde lagt til
`$CURLRC_FILE` og PR-en `$MANIFEST_TMP`. Begge skal med.

Det som betyr noe er dette: **PR #46 ville ikke virket om den var landet.**
Etter 31.08 la `056cef2` til to nye grunner til exit 2, og den ene er
«ok=0 — ingen av filene lar seg verifisere». Det er det samme tapet lest fra en
annen kant. PR-ens baseline-sammenligning lå bare i `mangler/endret`-grenen, så
`ok=0` ville holdt jobben rød videre. Målt, ikke antatt (se R2 under).

Rettet ved å flytte sammenligningen ut FØR de tre sjekkene og la både `ok=0` og
`mangler/endret` spørre den. `totalt=0` er med vilje ikke baseline-styrt: er
radene borte også, er det en større feil. Funn teller nå alt som ikke er `ok`,
ikke bare mangler/endret — en ny `uten_fasit`-rad er heller ikke verifisert.

## Målt, begge veier

Lokal rigg som serverer DAGENS ekte prod-arkiv (`aslisten-20261014.zip`) med
ekte responsheader, mot ekte `scripts/fetch-backup.sh`:

| # | Scenario | Exit | Melding |
|---|---|---|---|
| R1 | `origin/main` i dag | 2 | tilstanden alarmen melder |
| R2 | naiv konfliktløsning (bare trap-linja) | **2** | fiksen ville ikke virket |
| R3 | denne grenen | **0** | «alle 35 står i baselinen» |
| R4 | baseline minus `documents:12` | 2 | «1 NYE avvik: documents:12» |
| R5 | manifest + 2 nye avvik (mangler + endret) | 2 | «documents:98, documents:99» |
| R6 | baselinefil fjernet | 2 | «alle avvik regnes som nye» |
| R7 | friskt arkiv (`ok=35 mangler=0`) | 0 | baseline-logikken rørt aldri |
| R8 | baselinefil ødelagt (ikke gyldig json) | 2 | «klarte ikke sammenligne» |
| R9 | manifest + ny `uten_fasit`-rad | 2 | «documents:97» |

**Ekte kjøring mot produksjon** (`auth=railway`, GET `/api/backup`, kopi skrevet
til scratchpad slik at ekte backup-katalog ikke ble rørt):

```
fetch-backup: totalt=35 ok=0 mangler=35 endret=0 uten_fasit=0
fetch-backup ADVARSEL: ingen av de 35 filene lar seg verifisere (ok=0).
fetch-backup: alle 35 står i baselinen — ok=0 er det kjente tapet, ikke et nytt funn.
fetch-backup: alle avvik står i baselinen — ingen nye.
EXIT=0
```

Baselinen er dessuten kontrollert mot dagens manifest: 35 id-er i lista, 35 i
manifestet, settene identiske. Ingen rad i lista som ikke finnes i prod, ingen i
prod som ikke står i lista. Lista er like gyldig i dag som 31.08.

## To ting lagt til utover konfliktløsningen

- **Varselteksten.** `varsle-backupfeil.sh` er det eneste et menneske ser når
  alarmen fyrer, og den sa fortsatt «manifestet melder manglende eller endrede
  filer». Etter baselinen betyr exit 2 «avvik vi IKKE har sett på før». Sto
  teksten uendret, ville det ene varselet som gjaldt noe nytt lest som de 42
  forrige. Samme retting i `backup-status.sh`.
- **`project_state.md` blokker 1** beskrev august: at alle backuper var rene
  `.db`-filer (de er zip med manifest siden 11.09 — men inneholder null
  dokumentfiler, fordi prod ikke har noen), og at vaktposten feilet på
  manglende secrets (de ble lagt inn 07.09 kl. 17:44; den har målt det ekte
  tapet siden).

## Det som står igjen, og som ikke er mitt å bestemme

- **Vaktposten i `.github/workflows/backup-integritet.yml` blir rød også etter
  dette.** Den feiler på `mangler != 0` uten å kjenne baselinen, så
  GitHub-e-posten fortsetter daglig. Den er ikke rørt i denne PR-en — egen
  vurdering, egen PR. Uten den er halve alarmen fortsatt permanent rød, med
  samme blindhet som vi nettopp fjernet fra den andre halvdelen.
- **Regenerering av de 34 dokumentene.** Operatørbeslutning, blokkert av R20.
  Ingenting gjort.

---

# Dom over de fire PR-ene fra 28.08

Ingen av dem landet. Dommen er leveransen. Alle fire merger rent mot
`origin/main` (a4fdf95) — konflikt var ikke problemet i noen av dem.

## #38 «Katalogen: verktøyet som ikke kunne svare» — LANDBAR

`mergeable=MERGEABLE/CLEAN`. Innholdet er ikke på main: D-seksjonen stopper på
D4 der, og de to søskengrenene (`docs/moensteret`, `docs/moensteret-oppdatert`)
er begge forfedre til main — altså landet — men D5 kom ikke fra dem.
`tests/katalog-henvisninger.test.ts` 46 påstander grønne, full suite 1163
passerte = identisk med main-baseline.

Nitt ved landing: «i to PR-tekster og i en commit-melding» kan ikke slås opp —
ingen annen commit nevner `total_count`. Dropp tallet eller navngi PR-ene.

## #35 «Land antas ikke lenger» — TRENGER ARBEID

Merger rent, og 3-veismergen løser riktig: main byttet nabolinja til
`kanLagresSomFnr(...) ? krypter(...)`, og krypteringen beholdes OG `|| null`
påføres. Problemet lever fortsatt på main (`0003_kundeside.sql:41` har
`DEFAULT 'Norge'`, `orders.ts:556` har `|| 'Norge'`). PR-ens egne 8 prøver
grønne, `tsc` rent.

Men: nummeret **0012 er tatt** av `0012_woo_ordre.sql`, og to vaktprøver som
kom på main ETTER at grenen skilte lag går røde — dublett-nummerering, og
`DROP`-forbudet (SQLite kan ikke fjerne en `DEFAULT` uten tabell-ombygging).
`origin/main` alene er 7/7 grønn, så regresjonen er PR-ens egen.

Må gjøres: renummerer til 0019 **og** oppdater prøvens hardkodede filnavn
(`tests/land-ikke-antatt.test.ts:119,137`) i samme slengen, ellers går prøven
fra grønn til «kjører ikke det den tror»; avgjør DROP-policyen med operatør
(`migrasjoner.test.ts:172` har alt et unntak for `DROP TRIGGER`);
`CREATE INDEX IF NOT EXISTS`; tell foreldreløse `case_board_members`-rader før
migreringen kjøres (FK er på, en gjenopprettet backup kan bære slikt); juster
tittelen — ingenting på main setter `uten_norsk_id = 1`, så kontrollen kan
fortsatt ikke fyre.

## #36 «Foreldet kvalitetsvurdering» — TRENGER ARBEID

Alvorligst av de fire. Bygget er rødt: `agent-verktoy.ts:139` tilordner
`'foreldet'` til et felt som ikke har tilstanden — filen kom på main i
september, etter PR-en. Nummer 0013 er tatt av `0013_woo_status_asl.sql`.
2 prøver røde av 1180 (PR-teksten melder mot 704).

Og hovedtilfellet PR-en er skrevet for slipper fortsatt gjennom: foreldet med
ren forrige vurdering gir `blokkerende: []` → `kan: true`, og saksvisningen
har ingen `foreldet`-gren, så panelet rendrer ingenting. «Ren vurdering →
styret redigeres → godkjennes» oppdages internt, blokkeres ikke, vises ikke.
De 12 prøvene dekker bare foreldet MED funn. Fingeravtrykket mangler dessuten
`p.representative` (kom i `0015_fullmektig.sql`) — samme feilklasse PR-en
skulle lukke.

Det som holder: avvisningen av `cases.updated_at`, og avtrykk over lagrede
rader framfor `ctx` (midnatt-fella). Begge riktig resonnert og prøvd.

## #37 «Hva vi kan love et regnskapsbyrå» — TRENGER ARBEID

Merger rent, 61/61 grønne, `tsc` rent. Men dette er et dokument som LOVER noe
til en kunde, og for mange av løftene er usanne i koden i dag:

- «R09, R10 og R12 hindrer direkte retur — vi nekter å levere en som kommer i
  retur»: alle tre kaller `varsel(...)`. Det finnes fire blokkerende funn
  (R01, R02, R19a, R20). Vi nekter ikke å levere på noen av de tre.
- «20 regler» tre steder: 21 implementerte regel-ID-er, main sier 25, og R20
  (landet 08.09, elleve dager etter at dokumentet ble skrevet) mangler i lista
  — enda den er den eneste som blokkerer flaggskip-saken styreendring uten
  styredata.
- Steg 6 «Signering | timer til dager» leses som drift. `document_signatures`
  er tom i hele basen, `esign.ts:491` sier selv at ingenting er prøvd mot
  Posten, og det finnes ingen `fetch` i fila.
- Betaling er ikke nevnt i det hele tatt, men gater dokumentgenerering
  (`payments.ts:243`), og prod kjører `manuell`.
- «Byråets egne maler — allerede bygget»: `doc_templates` har ingen eier- eller
  tenant-kolonne, `users` har ingen rolle. To byråer ville overskrevet
  hverandre.
- PR-en senker dessuten testgulvet fra `>= 20` på katalogen til `>= 1` per
  dokument. Mister `moensteret.md` 22 av 23 henvisninger, blir prøven grønn —
  som er D1 i dokumentet den vokter.
- Den blir kilde nummer seks på et spørsmål main nettopp samlet i én
  (`hva-vi-leverer-i-dag.md`, og PR #60 «Duplisert sannhet»).

Ikke DØD: byrå-vinklingen, returtallene og de fem rangerte hullene finnes ikke
andre steder, og metodedisiplinen i dokumentet (brreg-årsrapporten, nektet
addisjon av to prosenttall) er det beste i PR-en. Men teksten er sju uker
gammel mot 86 commits, og feilene er nøyaktig den typen et byrå slår opp.

---

## Etterskrift 15.10: baselinen er nå målt på SETTET over hele retensjonen

Nattjobben fyrte igjen 15.10 kl. 03:32 — ventet, fordi arbeidskopien står på
`feat/jobbko-saksloft` uten fiksen og #46 ikke er merget. Samme anledning ga en
gratis gyldighetssjekk, og jeg utvidet den til alle arkivene som finnes:

| arkiv | totalt | ok | mangler | digest | settet |
|---|---|---|---|---|---|
| aslisten-20260912.zip | 35 | 0 | 35 | `0d385a890bb0` | identisk med baselinen |
| aslisten-20261003…15 (14 arkiv) | 35 | 0 | 35 | `0d385a890bb0` | identisk med baselinen |

Digesten er regnet over `kilde:rad_id` for hvert avvik, sortert — samme kanoniske
form som `avvikDigest` i serveren og som jq-varianten i vaktposten. Null avvik
uten `rad_id` i noen av arkivene, så digesten er regnbar overalt.

**Settet har stått bit for bit stille fra 12.09 til 15.10.** Tidligere kunne jeg
bare vise at ANTALLET sto stille (journalen melder `totalt=35 ok=0 mangler=35`),
og det er en svakere påstand — det var nettopp forskjellen mellom referert og
målt som denne PR-en handler om. Nå er den målt.

Konsekvens for de tre åpne beslutningene:
- Baselinen trenger ingen oppdatering før merge av #46.
- Nattjobben går grønn første natt etter at #46 er merget og `main` er sjekket ut
  i arbeidskopien.
- Vaktposten går grønn den dagen serverendringen i #62 er deployet.

Begge PR-ene står `MERGEABLE/CLEAN` etter at CI kom tilbake 19:40Z den 14.10.
De to røde sjekkene på #46 var faktureringsveggen fra 12:57Z (2 sekunder,
annotasjon ordrett), ikke innhold; de er kjørt om og er grønne.
