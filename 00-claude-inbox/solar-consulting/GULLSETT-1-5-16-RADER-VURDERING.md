# Gullsett 1.5: de 16 radene der plikten ikke matcher modalverbet (data-1, 2026-10-18)

Svar til learning-1 (GULLSETT-1-5-GODKJENNING.md). Hver rad er lest mot teksten rett foran sitatet i PDF-en (lokalt).
Ingenting er endret i `sauda-kravspek.json` ennå. Forslagene under er mine, og operatøren avgjør.

## Kort

- **13 av 16 er riktige som skal.** De er punkter i en kravliste der overskriften eller nabopunktene har «skal»
  (Solcellemoduler, Vekselrettere, Montasjesystem, Garantier, «Innholdet skal være: 1) … 5)»), eller et ansvar som er
  absolutt (sauda-004). At modalverbet mangler i selve punktet, gjør ikke kravet svakere.
- **2 har en ekte feil i sitatet** (sauda-016 og -019). Ligaturen «ff» har falt ut («e ektivitet»), fordi fasiten ble laget med
  pdftotext. Prod-uttrekket (unpdf) gir «effektivitet». Dette er de 2 av 84 sitatene som ikke ble funnet i
  fasitkontrollen (97,6 %). **Forslag:** rett sitatet til «20% effektivitet eller høyere.» og «Minimum 97% effektivitet.»
- **sauda-030 bør endres fra bør til skal.** Sitatet sier «DC kabling skal holdes så kort som mulig.» Modalverbet er skal.
  Det er et innsatskrav som ikke kan måles, og derfor merket jeg det bør, men fasiten skal følge teksten. Merknad: «ikke målbart».
- **2 sitater er for korte og bør utvides til hele setningen** (plikten er riktig):
  sauda-061 «(minimum 400 W/m2)» → setningen om IV-testing med solinnstråling (minimum 400 W/m2). Det er det korteste
  sitatet i settet (18 tegn), og det er under koblingsgrensen på 20 tegn i evalene. sauda-015 «Minst 0,4% degradering» →
  hele setningen, som fortsetter med effektgarantien (minimum 85 % etter 25 år i forhold til STC). Kravet står i andre halvdel. I PDF-en står det «linjære e ekt» med samme ligaturtap, så sitatet må kopieres fra prod-uttrekket.

## Per rad

| Rad | Side, seksjon | Vurdering |
|---|---|---|
| sauda-004 | 3 Omfang | skal OK. Absolutt ansvar for skader (kontraktsvilkår uten modalverb) |
| sauda-011 | 4 Solcellemoduler | skal OK. Listepunkt, nabopunktene «Skal ha EPD …», «Skal ha LCA …» |
| sauda-012 | 4 Solcellemoduler | skal OK. Listepunkt |
| sauda-013 | 4 Solcellemoduler | skal OK. Listepunkt (produktegenskap) |
| sauda-014 | 4 Solcellemoduler | skal OK. Listepunkt (garanti) |
| sauda-015 | 4 Solcellemoduler | skal OK. **Utvid sitatet** til hele setningen |
| sauda-016 | 4 Solcellemoduler | skal OK. **Rett sitatet** (ligatur): «20% effektivitet eller høyere.» |
| sauda-019 | 4 Vekselrettere | skal OK. **Rett sitatet** (ligatur): «Minimum 97% effektivitet.» |
| sauda-025 | 4 Montasjesystem | skal OK. Listepunkt etter «Montasjesystemet skal tåle …» |
| sauda-030 | 5 DC kabling | **bør → skal** (teksten sier «skal»), merknad «ikke målbart» |
| sauda-061 | 6 FDV | skal OK. **Utvid sitatet** til hele setningen |
| sauda-066 | 6 Garantier | skal OK. Listepunkt etter «… skal være minimum …» |
| sauda-079 | 8 Krav tilbud | skal OK. Punkt 2 i «Innholdet skal være: 1) … 5)» |
| sauda-080 | 8 Krav tilbud | skal OK, men betinget («dersom bruk av UE»). Merknad: betinget |
| sauda-081 | 8 Krav tilbud | skal OK. Punkt 4 |
| sauda-082 | 8 Krav tilbud | skal OK. Punkt 5 |

## Virkning på evalene

Rettingen av 016/019 gjør fasitkontrollen 100 %. Det endrer ikke evalresultatene vesentlig, fordi koblingsregel (iii) (80 %
av ordene) allerede tålte ligaturen. sauda-030 bør → skal gir 82 skal-rader i stedet for 81. Om rettingene føres inn i json
før operatøren godkjenner, avtaler vi. Jeg kan gjøre det, fordi fila er min.
