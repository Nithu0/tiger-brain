# Dokumentkilder: hvor peker `documentsUrl`, og hva har vi faktisk lastet ned?

`FACT` Målt mot produksjon read-only 2026-10-13, kode `6cc89c2`. Bestilt fordi trading-1 er
blokkert. Rådata: [`dokumentkilder-2026-10-13.txt`](dokumentkilder-2026-10-13.txt), skript
`scripts/baseline/dokumentkilder.sql`.
Reproduser: `cd projects/anbud/crm && ./scripts/baseline/run-triage-baseline.sh --sql dokumentkilder.sql`

## Svaret kort

`FACT` **trading-1s funn holder for hele basen, ikke bare utvalget på 45.** Av 1184 `documentsUrl`
i basen ser **0** ut som en fil (ingen `.pdf`/`.docx`/`.xlsx`/`.zip`-endelse i stien). Alle peker
på en portal.

`FACT` **Nullmålingen er bokstavelig null:** `documents`-tabellen har **0 rader**. Ingen fil er
noensinne lastet ned, ingen tekst uttrukket. Av **742** køkvalifiserte muligheter har **0** minst
ett dokument med tekst.

`FACT` **Dekning:** 1184 av 1751 kunngjøringer har URL (67,6 %). Blant køkvalifiserte er dekningen
høyere: **625 av 742 (84,2 %)** — rimelig, siden køen er aktive konkurranser.

## Kostnaden: per plattform, ikke per vert

13 distinkte verter, men flere er samme plattform med ulik leietaker. Det er plattformen som
koster, siden adapteret er per innloggings- og lenkestruktur:

| Plattform | Lenker | Andel | Verter det dekker |
| --- | --- | --- | --- |
| **Mercell** | 436 | 36,8 % | `permalink.mercell.com` (435), `supplierportal.c1.app.mercell.com` (1) |
| **TendSign** | 215 | 18,2 % | `tendsign.com` |
| **hyyr** | 149 | 12,6 % | `hyyr.no` |
| **Artifik** | 137 | 11,6 % | `app.artifik.no` |
| **Ivalua** | **127** | **10,7 %** | `sykehusinnkjop.ivalua.app` (108), `nav.ivalua.app` (12), `ivalua-supplier.statnett.no` (4), `vy-supplier.ivalua.app` (3) |
| **EU-Supply** | 110 | 9,3 % | `eu.eu-supply.com` |
| Resten | 10 | 0,8 % | `tilbudsportal.miljodirektoratet.no` (5), `innkjopshuset.no` (3), `achilles.com` (2) |

**Ivalua er ett adapter, ikke fire.** Fire leietakere på samme plattform, til sammen 10,7 % — mer
enn EU-Supply. Grupperer man på vertsnavn alene undervurderer man gevinsten av det adapteret.

Kumulativt, sortert etter volum:

| Adaptere bygget | Dekning av lenkene |
| --- | --- |
| 1 (Mercell) | 36,8 % |
| 2 (+ TendSign) | 55,0 % |
| 3 (+ hyyr) | 67,6 % |
| 4 (+ Artifik) | 79,2 % |
| 5 (+ Ivalua) | 89,9 % |
| 6 (+ EU-Supply) | **99,2 %** |

Køen fordeler seg nesten likt (`KO_VERT`): Mercell 229, TendSign 112, hyyr 82, Artifik 66,
Ivalua 70, EU-Supply 63.

## Svar på spørsmålet «en uke eller et kvartal»

Tallene sier at det er **begge** — avhengig av ambisjon, og det er en beslutning, ikke et estimat:

- **hyyr alene er 12,6 %** av lenkene, og er den eneste som svarer uten innlogging (trading-1s
  måling). Det er pipen som allerede er bevist ende-til-ende. En uke, og den dekker en åttendedel.
- **99,2 % krever seks adaptere**, og fem av dem krever innlogging eller sesjon. Det er ikke én
  nedlaster, det er seks integrasjoner med hver sin autentisering — og `ASSUMPTION`: hver av dem
  kan ha vilkår som regulerer automatisert tilgang. Det bør avklares per portal før bygging,
  ikke etter (jf. CLAUDE.md § 7, teknisk mulighet ≠ juridisk rett).
- **Terskelen å merke seg er 3 adaptere = 67,6 %.** Mercell + TendSign + hyyr dekker to
  tredjedeler, og hyyr er alt bygget. Marginalnytten faller bratt etter nummer fem.

Det er også verdt å si hva målingen **ikke** svarer på: om en portal-URL i det hele tatt leder til
nedlastbare dokumenter for en innlogget bruker, og om vilkårene tillater det. Begge er
`UNKNOWN` og ingen av dem kan måles fra basen.

## Holdbarhet på tallene

`FACT` Kø-tallet var **758** i grunnlinjen kl. 08:42 og er **742** nå. Differansen er frister som
har passert i mellomtiden. Køtall har timer, ikke dager, som holdbarhet — derfor står tidspunktet
i hvert artefakt. Lenkefordelingen er stabil (den følger kilden, ikke frister).

## Kilder

Tagger i artefaktet: `URL_DEKNING` · `VERT` · `ANTALL_VERTER` · `KO_URL_DEKNING` · `KO_VERT` ·
`DOK_ARKIV` · `DOK_PER_FORMAAL` · `KO_MED_TEKST` · `FILENDELSE`.
Kø-predikatet speiler `crm/src/lib/triage.ts:queueWhere`. Dokumentarkivet er `documents`
(`opportunity_id`, `purpose`, `extracted_text`).
