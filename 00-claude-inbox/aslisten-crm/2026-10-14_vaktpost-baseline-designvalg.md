# Vaktposten og baselinen: ett designvalg operatøren må ta før noen skriver PR-en

paal-1, 2026-10-14. Bakgrunn: PR #46 gjør nattjobben baseline-kjent. Den
maskinuavhengige halvdelen — `.github/workflows/backup-integritet.yml` — er ikke
rørt, og operatøren har spurt om den skal tas i egen PR. Jeg skrev ikke PR-en,
fordi den opplagte varianten har en feilmodus som er verre enn problemet den løser.

## Hvorfor vaktposten ikke kan gjøre det nattjobben gjør

Nattjobben laster ned arkivet, pakker ut `manifest.json` og sammenligner
**`kilde:rad_id` per avvik** mot `scripts/backup-baseline.json`. Den vet derfor om
de 35 avvikene er de SAMME 35.

Vaktposten gjør med vilje noe annet (`backup-integritet.yml`, kommentaren øverst):
den kjører `curl -I`, altså HEAD, og leser bare `x-backup-sammendrag`. Ingen byte
kundedata forlater serveren. Det den har er fem tall:

```
totalt=35 ok=0 mangler=35 endret=0 uten_fasit=0
```

**Den har ingen id-er.** En baseline av id-er kan den ikke bruke.

## Variant A — tell-basert baseline. Billig, og den kan melde grønt på et nytt tap.

Regelen ville blitt: `mangler == 35 && endret == 0` → kjent, grønn.

Feilmodusen: regenererer vi én fil og mister en annen samtidig, er `mangler`
fortsatt 35, og vaktposten melder grønt på et NYTT tap. Det er ikke et teoretisk
scenario — regenerering av de 34 er nettopp det som ligger på bordet som
operatørbeslutning, og den vil endre settet mens antallet kan stå stille.

Dette er den klassen feil repoet har ryddet tre ganger denne måneden: `totalt=0`
som grønt, `ok=0` som grønt, `uten_fasit=35` som grønt. Jeg vil ikke legge inn en
fjerde.

## Variant B — én ny responsheader. Litt dyrere, og den kan ikke lyve.

`app/api/backup/route.ts:103` bygger sammendraget på ett sted. Legg til én header
ved siden av:

```
x-backup-avvik-digest: sha256( sortert liste av "kilde:rad_id" for alle rader med status != ok )
```

Da kan vaktposten regne samme digest over `kjente_avvik` i
`scripts/backup-baseline.json` (`jq -r '.kjente_avvik[]' | sort | sha256sum`) og
sammenligne. Lik digest = nøyaktig det kjente tapet, grønn. Ulik digest = noe har
endret seg i settet, rød — uansett om antallet står stille.

Det som forlater serveren er én sha256 av interne rad-id-er. Ingen filnavn, ingen
saksnummer, ingen kundedata — strengere enn manifestet nattjobben alt laster ned.

Kostnaden er at det er en **kodeendring i CRM-en som må deployes til prod** for å
virke, ikke bare en workflow-fil. Prod-deploy er operatørgatet.

## Variant C — la vaktposten stå rød, men gjør meldingen presis

Ingen baseline i CI. Bare skille teksten: «35 mangler — samme ANTALL som det
registrerte tapet, settet er ikke kontrollert i denne jobben; nattjobben
kontrollerer settet». Ærlig, null risiko, og den daglige e-posten fortsetter.

## Min anbefaling

**B, og ikke A.** C er bedre enn A: en vaktpost som fortsetter å rope er et kjent
problem, mens en vaktpost som kan melde grønt på et nytt tap er et nytt problem.
A ser ut som den løser e-postmasen, men den kjøper stillhet med den egenskapen
vaktposten finnes for.

Rekkefølgen jeg foreslår, hvis operatøren sier ja til B: header i samme PR som
workflow-endringen, deploy-gaten tas eksplisitt, og til den er deployet leser
vaktposten fortsatt bare tallene — altså C i mellomtiden, som koster ingenting
ekstra å skrive.

## Dagens komplikasjon, som ikke endrer valget

Vaktposten er i dag rød av en helt annen grunn: run `38556677122` (14.10 11:27:20Z)
døde på 2 sekunder på GitHub-faktureringsveggen — `The job was not started because
recent account payments have failed`. Gårsdagens run `38408163771` tok 9 sekunder og
målte ekte (`35 av 35 dokumentfiler mangler på disk`).

Så fram til i går var vaktposten rød OG målte; fra i dag er den rød og måler
ingenting. Det styrker B: når faktureringen løses, går den tilbake til å rope det
samme hver dag, og da har vi hatt to ulike grunner til samme røde e-post på én uke.
Ingen av dem kan en leser skille utenfra.
