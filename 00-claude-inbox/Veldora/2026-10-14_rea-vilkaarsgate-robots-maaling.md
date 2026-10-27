# Vilkårsgaten for rea-arbeidet: robots.txt målt på alle seks portaler

**Rolle:** learning-1 (motpart på `morluto/rea`, eier trading-1)
**Oppdrag:** orchestrator-1 10:55Z — «learning-1s vilkårsgate først av alt»
**Målt:** 2026-10-14, `curl -sS -m 12 https://<vert>/robots.txt`, User-Agent `learning-1 vilkaarssjekk (read-only, robots.txt)`
**Omfang:** kun `/robots.txt`. Ingen portalside hentet, ingen innlogging, ingenting installert.
**Lenketall:** fra egen måling `dokumentkilder-2026-10-13.txt` (commit `c4a0468`), hele basen, n=1184.

## Funnet i én setning

Innloggingsveggen var aldri hele historien. **For 342 av 1184 dokumentlenker (28,9 %) forbyr robots.txt kryping uansett om vi har konto** — og for EU-Supply er det nøyaktig dokumentstien som er forbudt.

## Per portal

| Vert | Lenker | Andel | robots.txt | Vurdering |
|---|---|---|---|---|
| `tendsign.com` | 215 | 18,2 % | `User-agent: *` / `Disallow: /` | **Eksplisitt totalforbud.** Nest største plattform. |
| Ivalua (4 verter) | 127 | 10,7 % | `Disallow: /` på **alle fire** | **Eksplisitt totalforbud, plattformdekkende.** Verifisert på `sykehusinnkjop`, `nav`, `statnett`, `vy`. |
| `eu.eu-supply.com` | 110 | 9,3 % | Generelt tillatt, men `Disallow: /app/docmgmt` | **Dokumentstien spesifikt forbudt.** Resten av siden er åpen. |
| `permalink.mercell.com` | 435 | 36,7 % | Ingen. SPA svarer HTML på `/robots.txt` | Taus — ikke tillatelse. Størst av alle. |
| `hyyr.no` | 149 | 12,6 % | Ingen. SPA svarer HTML | Taus. Den ene som er bevist ende-til-ende. |
| `app.artifik.no` | 137 | 11,6 % | 404, deretter SPA-HTML ved redirect | Taus. |

Sum eksplisitt forbudt: **342 lenker (28,9 %)**. Med EU-Supplys dokumentsti: **452 (38,2 %)** der robots sier nei helt eller på presis den stien en dokumentadapter trenger.

## Tre ting dette endrer

**1. Rangeringen av adaptere er feil premiss.** Marginalnytten vi regnet på (3 adaptere = 67,6 %, 5 = 89,9 %) antok at hindringen var innlogging, altså noe en operatørgate kan åpne. For TendSign og Ivalua er hindringen `Disallow: /`, som ingen konto opphever. En konto gir rett til å se; robots.txt sier at automaten ikke skal hente. Det er to ulike tillatelser, og vi har blandet dem.

**2. EU-Supply er det skarpeste funnet, ikke det største.** De tillater kryping av nettstedet og forbyr `/app/docmgmt`. Det er ikke en generell crawler-policy — det er en målrettet utestengelse av nøyaktig dokumenthåndteringen. Å bygge en adapter mot den stien er ikke en gråsone man kan argumentere seg rundt; den er navngitt.

**3. Taus robots.txt er en felle, ikke et grønt lys.** Mercell, hyyr og Artifik har ingen robots.txt — men de svarer **HTTP 200 med HTML** på `/robots.txt`, fordi SPA-ens catch-all serverer index. En naiv robots-parser leser den HTML-en, finner ingen `Disallow`, og konkluderer «tillatt». Det er samme feilmodus som har gått igjen hos oss i to dager: **statuskode forvekslet med innhold.** Enhver adapter vi bygger må behandle «200 med `content-type: text/html` på robots.txt» som *ingen robots.txt*, ikke som *tom robots.txt*.

## Hva som gjenstår i gaten — og hvorfor jeg stoppet her

robots.txt er maskinlaget. **Vilkårslaget (ToS per portal) er ikke lest**, og det er det som faktisk binder juridisk. robots.txt kan være taus mens vilkårene forbyr automatisert uttrekk, og den kombinasjonen er den farligste — den ser tillatt ut for en maskin.

Jeg har med vilje **ikke** hentet en eneste portalside, heller ikke på de tre tause. Begrunnelsen: min egen gate sier vilkårsavklaring før adapterarbeid, og å probe en portal for å se om den svarer *er* begynnelsen på adapterarbeidet. Rekkefølgen er ikke pedanteri — det er forskjellen på å avklare om vi har lov og å finne ut om det virker.

## Neste skive, hvis orchestrator vil ha den

ToS for de tre tause (Mercell, hyyr, Artifik) + de to forbudte (TendSign, Ivalua), lest på det punktet som gjelder automatisert tilgang og uttrekk. Det avgjør om «offentlige portalsider først» i det hele tatt er en lovlig kategori på disse fem, eller om hyyr er den eneste porten som finnes — juridisk, ikke bare teknisk.

---

# ToS-skiven (godkjent 11:20Z) — DELVIS LEVERT, stoppet på operatørordre

**Status: ikke fullført.** Operatøren ba om oppsummering av alt levert mens denne pågikk. Det som står under er målt; resten er ikke gjort, og jeg markerer det som åpent heller enn å la det se komplett ut.

## Ny robots-måling på `www.*`-vertene (de er ANDRE verter enn de jeg målte 12:22)

Dette var en reell mangel i min egen første runde: robots.txt gjelder per vert, og vilkårssidene ligger på markedsføringsvertene, ikke på portalvertene.

| Vert | robots.txt | Konsekvens |
|---|---|---|
| `www.mercell.com` | `User-agent: *` + lang liste `Disallow` på **navngitte konkurransesider** (ser ut som fjerningsforespørsler for enkeltanbud). Ingen generell sperre. Sitemap oppgitt. | Vilkårsside kan hentes |
| `www.artifik.no` | Squarespace-oppsett. Sperrer `/config`, `/search`, `/account`, `/api/`, `/static/` og query-varianter | Vilkårsside kan hentes |
| `www.eu-supply.com` | HTTP 301, ingen robots-kropp på denne verten | Uavklart; `eu.eu-supply.com` gjelder fortsatt (`Disallow: /app/docmgmt`) |

**Nær-bom jeg nesten gjorde, og som er verdt å skrive ned:** `www.artifik.no` lister `anthropic-ai`, `ClaudeBot`, `GPTBot` og 25 andre AI-agenter rett over `User-agent: *`. Førsteinntrykket er «AI-agenter er utestengt» — og det gjelder i så fall meg, ikke bare en framtidig adapter. **Men alle `User-agent`-linjene stabler seg i én gruppe**, og reglene som følger er de samme for alle. Det er ikke et AI-forbud. Å lese det som forbud ville vært speilbildet av feilen jeg selv advarte mot tre timer tidligere: taushet lest som samtykke i én retning, fellesregler lest som ban i den andre. Begge er å gjette på en fil man ikke har lest ferdig.

## Vilkårssider: hva jeg fant og hva jeg ikke fant

- **`app.artifik.no/terms-and-conditions`** — hentet. Siden serverer **personvernerklæring**, ikke brukervilkår: GDPR-rettigheter, dataportabilitet, «det vil ikke bli foretatt automatisert behandling, herunder profilering». Søk på `automat|robot|crawl|scrap|skrap|uttrekk|systematisk|kopier|mining` traff **bare** GDPR-teksten. **Ingen klausul om automatisert uttrekk funnet — men fraværet er fra ett søk på én side, og det er ikke et funn.** Brukervilkårene kan ligge et annet sted.
- **`hyyr.no/privacy`** — hentet. Også personvern, ikke vilkår. «Automatisk innsamlet informasjon» handler om **deres** innsamling fra besøkende, ikke om vår tilgang. Ingen vilkårsside lokalisert; `/privacy` var den eneste juridiske lenken i markup-en.
- **`www.mercell.com`** — vilkårsside **ikke lokalisert**. Ingen treff på `vilkar|terms|betingelser|legal` i rot-markup-en (SPA, lenkene ligger antakelig i JS). Neste steg er `SitemapIndex.ashx`, som robots.txt selv oppgir — altså sanksjonert vei. **Ikke gjort.** Mercell er størst (435 lenker, 36,7 %), så dette er det viktigste hullet.
- **`eu.eu-supply.com` / `www.eu-supply.com`** — vilkårsside **ikke lokalisert**. **Ikke gjort.**

**Netto på ToS-skiven: 2 av 4 sider hentet, og begge to viste seg å være personvernerklæringer, ikke brukervilkår.** Spørsmålet orchestrator ba meg svare på — forbyr vilkårene automatisert uttrekk, også med lovlig konto — er **fortsatt ubesvart for alle fire.**

## TendSign og Ivalua: operatør-oppgaven (ferdig spesifisert)

Per ordre henter jeg ingenting her, fordi `Disallow: /` dekker vilkårssiden like mye som alt annet. Et menneske som åpner en offentlig vilkårsside i en nettleser er ikke en automat.

**HVOR — TendSign:** åpne `https://tendsign.com` i nettleser. Vilkårslenken ligger etter alt å dømme i fotnoten («Vilkår» / «Terms» / «Användarvillkor» — plattformen er svensk, eid av Visma/Opic). **Jeg kan ikke oppgi den eksakte stien, fordi å verifisere den krever nettopp det hentet jeg ikke har lov til.** Det er en ærlig begrensning, ikke slurv.

**HVOR — Ivalua:** åpne `https://sykehusinnkjop.ivalua.app` (største leietaker, 108 lenker). Vilkår ligger typisk ved innloggingsboksen eller i fotnoten. **Merk:** `ivalua.com` (leverandørens eget nettsted) er en **annen vert** med egen robots.txt som jeg **ikke har sjekket og ikke har hentet** — hvis orchestrator vil, kan den klareres separat, og den har sannsynligvis plattformvilkårene samlet.

**HVA svaret skal gi — samme tre spørsmål for begge:**
1. Forbyr vilkårene **automatisert nedlasting eller uttrekk** av konkurransedokumenter — også for en innlogget bruker med lovlig konto?
2. Står det at kontoen er **personlig**, eller at tilgang ikke kan deles med systemer, roboter eller tredjeparter? (Det er klausulen som gjør «vår egen autentiserte økt» ulovlig selv når mennesket har lov.)
3. Finnes det en **eksplisitt unntaksvei** — API, dataavtale, tilgang på forespørsel — vi kan søke om i stedet for å krype?

Svarer punkt 1 eller 2 ja, er dokumentstrategien for 342 lenker (28,9 %) ikke en teknisk oppgave i det hele tatt. Svarer punkt 3 ja, er den en e-post.

---

# ToS-skiven, fullført så langt den kan fullføres (14.10, etter push-gaten)

**Mercell:** `www.mercell.com/SitemapIndex.ashx` — hentet (robots.txt oppgir den selv, altså sanksjonert vei). Den inneholder **bare per-språk `ApplicationIndex.ashx`**, altså SEO-indekser over konkurransesider. **Ingen vilkårsside.** Fotnotelenkene ligger i JS, og rot-markup-en har ingen juridisk lenke.

**EU-Supply:** `www.eu-supply.com` **301-er til `eu.eu-supply.com`** — det er samme vert, så den styrende regelen er fortsatt `Disallow: /app/docmgmt`. Rotsiden har ingen vilkårslenke i markup (innloggingsside).

## Konklusjonen, og den er ubehagelig på en nyttig måte

**Vilkårssidene til de to største portalene er ikke lesbare uten enten (a) JS-rendering eller (b) å gjette stier.** Og:

- **å gjette stier er å probe en portal** — nøyaktig det gaten min forbyr før vilkår er avklart, altså sirkulært
- **JS-rendering er det `rea` gjør** — altså verktøyet som er under vurdering, og som ikke skal installeres før orchestrator har sett forslaget

**Gaten på rea kan dermed ikke lukkes helt uten enten noe rea-aktig, eller et menneske med en nettleser.** Det er ikke en blindvei: det gjør bare operatør-sporet til hovedsporet i stedet for reserveløsningen. Fire portaler, ikke to.

## Operatør-oppgaven, utvidet til fire

Samme form og samme tre spørsmål som for TendSign og Ivalua:

| Portal | HVOR operatøren åpner | Hvorfor manuelt |
|---|---|---|
| TendSign | `https://tendsign.com` → fotnote | `Disallow: /` dekker også vilkårssiden |
| Ivalua | `https://sykehusinnkjop.ivalua.app` → fotnote/innloggingsboks | `Disallow: /` på alle fire verter |
| **Mercell** | `https://www.mercell.com/nb-no/` → fotnote | Robots tillater, men lenken finnes bare i JS |
| **EU-Supply** | `https://eu.eu-supply.com` → fotnote | Robots tillater utenfor `/app/docmgmt`, men ingen lenke i markup |

**De tre spørsmålene (uendret):** (1) forbys automatisert nedlasting/uttrekk også for innlogget bruker med lovlig konto · (2) er kontoen personlig / forbys deling med systemer og tredjeparter · (3) finnes en eksplisitt unntaksvei (API, dataavtale, tilgang på forespørsel).

**Status på skiven: lukket fra min side.** Robots-laget er fullt målt på alle seks. ToS-laget er avklart så langt det kan avklares uten nytt verktøy eller et menneske — og det er nå spesifisert som en firedelt operatøroppgave med eksakt HVOR og HVA.
