# Dokumentdekning — oppfølging av tools-1 sin rapport, 2026-10-11

**Fra:** anbud-lane (overtok `fix/anbud-dokumentdekning`, aldri pushet fra `~/code/Veldora-dok`)

## 1. Gren fra tools-1
`abfd123` på `fix/anbud-dokumentdekning` er god: ~10 linjer i triage-kortet som viser
`documentsUrl` som egen lenke når den peker et annet sted enn `sourceUrl`, pluss et
read-only måleskript. Cherry-picket rent på `origin/main` (ingen konflikt med #124s
læringsstatus-endring i samme fil), `tsc --noEmit` rent i crm+dashboard, `npm test`
238/238 filer · 2418/2418 grønt. **PR #130.**

## 2. Utvalg på 20 — hva lenkene faktisk peker på
Første forsøk (ordnet på id) ga 20/20 TED — ikke representativt, la om til `ORDER BY random()`.

Tilfeldig utvalg på 20 av 629 i køen med `documentsUrl` (read-only mot prod,
`BEGIN READ ONLY … ROLLBACK`):

| Portal | Antall i utvalget |
|---|---|
| permalink.mercell.com / tendsign.com (samme konsern) | 11/20 |
| sykehusinnkjop.ivalua.app / nav.ivalua.app | 3/20 |
| app.artifik.no | 3/20 |
| hyyr.no | 2/20 |
| achilles.com (leverandørregister, ikke anbuds-portal) | 1/20 |

**0/20 peker rett på en fil.** Alle 20 er app-URL-er til en anskaffelsesportal.

## 3. Hele populasjonen (629, ikke bare utvalget) — domenehistogram
Kjørte samme måling mot alle 629 (samme filter som §2, litt strammere enn tools-1s 675
fordi fristfilteret fra `queueWhere` ikke var med — forskjellen er ventet, ikke en feil):

| Host | n | Direkte fil (.pdf/.zip/.docx/.xlsx) |
|---|---|---|
| permalink.mercell.com | 231 | 0 |
| tendsign.com | 117 | 0 |
| hyyr.no | 78 | 0 |
| app.artifik.no | 72 | 0 |
| sykehusinnkjop.ivalua.app | 59 | 0 |
| eu.eu-supply.com (TED eSender) | 56 | 0 |
| nav.ivalua.app | 8 | 0 |
| www.achilles.com | 2 | 0 |
| tilbudsportal.miljodirektoratet.no | 2 | 0 |
| ivalua-supplier.statnett.no | 2 | 0 |
| vy-supplier.ivalua.app | 1 | 0 |
| supplierportal.c1.app.mercell.com | 1 | 0 |

**`FACT`: 0 av 629 (0 %) peker rett på en fil.** Mercell/TendSign-familien er 348/629 (55 %).
Ivalua-familien (statnett/vy/nav/sykehusinnkjop) er alltid et kunde-spesifikt, innloggingskrevende
leverandørportal-instans. eu-supply er TED sitt eSender-system og krever registrering per konkurranse.
`achilles.com` er ikke en anbudsportal i det hele tatt — det er leverandørkvalifiseringsregisteret
Achilles; `documentsUrl` her er sannsynligvis en datakvalitetsfeil i kilde-parsingen (TED), ikke en
ekte dokumentlenke. Verdt en separat liten sjekk i `ted.ts:263`, men ikke gjort her.

## 4. Konklusjon for nedlastingsarbeidet (steg 3 i oppdraget)
Ingen bygget nedlasting i denne omgangen. **Ingen** av de 629 kvalifiserer for automatisk
nedlasting — alle er portal-URL-er, ikke direkte filer. Å bygge en nedlastingsjobb nå ville være
spekulativ kode mot null faktiske mål i dagens data. Alle 629 logges derfor som
**«krever manuell nedlasting»** — ingen innlogging eller registrering er forsøkt omgått, ingen
portal-URL er hentet (kun domenet er lest ut av `documents_url`-strengen i databasen, ingen
utgående HTTP mot portalene).

Når/hvis et direkte filformat dukker opp (f.eks. doffin.no sin egen vedleggs-URL, som tools-1
foreslo som den minste ærlige første versjonen), er `mangelFor()`/`dokumentdekning.ts` fra
tools-1s branch allerede der for å måle effekten — en nedlasterfunksjon kan limes inn bak et
enkelt filter (`documentsUrl` matcher doffin.no + filendelse) uten arkitekturendring.

Billigste neste skritt er fortsatt det tools-1 pekte på i §5.3 i sin rapport: ærlighets-fiksen i
`endpoints/triage.ts` — si fra i UI at ingen dokumenter er lest, i stedet for å antyde
dokument-verifiserte sitater. Det er `code-1`s fil.

*Ingen skriv mot produksjon. Ingen hemmeligheter lest. Ingen portal-URL hentet.*
