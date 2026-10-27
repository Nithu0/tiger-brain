# Tre scopes — beslutningsnotat til 19.10

admin-1, 2026-10-17. Gjelder [`strategy/proposals/2026-10-12-tre-scopes.md`](../../../../code/Veldora/strategy/proposals/2026-10-12-tre-scopes.md) (PROPOSED, frist 19.10).
Tall: prod read-only 2026-10-17, `crm/scripts/baseline/tre-scopes-dev.sql` → `crm/eval/tre-scopes-dev-2026-10-17.txt` (branch `tre-scopes-tall`).
Bare **dev-rader**, altså beslutninger før 14.10, siste per mulighet: 121 rader. Testsettet ≥ 14.10 er ikke brukt ([ADR-0019](../../../../code/Veldora/decisions/ADR/ADR-0019-to-maalvariabler-og-tidsdelt-testsett.md)).

## Hva forslaget endrer i koden

`FACT` De tre scopene **finnes allerede som spor** i `crm/src/config/tracks.ts`: `fagsystem` («Kvalitets- og fagsystemer»), `rapportering` og `undersokelser`, blant 9 spor. Triage-vurdereren (#200) legger alle 9 sporene inn i prompten som «Fagområder», og `VERTICAL_CONFIGS` som «Nei-områder».
**Forslaget trenger derfor ingen kodeendring for å bli vedtatt.** Det blir bare en kodeendring hvis noen fjerner spor eller flytter dem til nei-områder. Da sier triagen og vurdereren «utenfor» om saker vi i dag sier ja til (se under). Hold de to fra hverandre: **hva vi utvikler** er én beslutning, og **hva vi vurderer i triagen** er en annen.

## Dekningen i dag (dev, ja / nei)

| | konkurranse (bid) | dialog/RFI (respond) |
|---|---|---|
| Alle | 17 / 45 | 13 / 34 |
| Treffer de 3 **sporene** (prod-beregnet, `FACT`) | **7 / 8** | **9 / 2** |
| Treffer de 3 **møtekategoriene** (våre nøkkelord, `ASSUMPTION`) | **2 / 2** | **1 / 2** |

Avviket på 16 mot 3 av 30 ja kommer av at sporet `fagsystem` er bredt. Av de 13 ja-ene der er **ett** et kvalitetssystem. Resten er (`FACT`, titlene i artefaktet):
- **konkurranse:** saksbehandlingsløsning, kundedialog/kontaktsenter, kommunalt innfordringssystem, møteverktøy, stoffkartotek.
- **dialog:** kommunale gebyrer, innkjøpsløsning, KGV/KAV, inkassosystem Bodø. Det er 4 anskaffelser, men 7 rader, fordi norsk og engelsk kunngjøring er tvillinger.

De tre foreslåtte har **ett ja hver** på møtenøkkelordene: «Kvalitetssystem» (konkurranse), «Medarbeiderundersøkelse og pulsmålinger» (konkurranse) og «RFI lekeplasskontroller» (dialog). `FACT` Med n = 1 kan de ikke rangeres mot hverandre.

## Ja som faller utenfor forslaget

- **Kommunale forvaltningssystemer** (gebyr, innfordring/inkasso, innkjøp, saksbehandling): 2 konkurranse-ja (saksbehandlingsløsning, innfordringssystem), 3 hvis kontaktsenter/saksbehandling regnes med, og 4 distinkte dialoger. Det er **den eneste klyngen med mer enn ett ja**.
- **IT-konsulent/bistand** (backend/full stack, bistand UiB ATLAS, KI-tilgang): 3 konkurranse-ja og 1 distinkt dialog (konsulentavtaler digitalisering, to tvillingrader). Dette er bemanning, ikke produkt.
- **Enkeltstående saker:** EPJ, lisenser, hotellsystem, HR/lønn, billedarkiv, møteverktøy, stoffkartotek, skolemiljøverktøy, oversettelse samisk og dialogene om timeregistrering og helseråd.

## Alternativer

1. **Vedta forslaget som det er.** Det er billigst. Men datagrunnlaget sier ingenting for eller mot det: 3 av 30 ja, og de tre kan ikke rangeres. `HYPOTHESIS` Det blir et valg på kriteriene i forslaget § 2, ikke på markedssignal. Si det rett ut i ADR-en.
2. **Bytt scope 1 til «kommunale forvaltningssystemer»** (gebyr, innfordring, innkjøp, smal saksbehandling) og behold rapportering (lekeplass). Det er den eneste klyngen med gjentatte ja. Felleskjernen i forslaget § 5 (skjema, arbeidsflyt, rapport) passer like godt.
   Forbehold:
   - `ASSUMPTION` Inkasso og innfordring kan ha regulatoriske krav. Ikke sjekket.
   - Saksbehandling kan treffe Noark-muren (forslaget § 3).
   - 4 av 7 ja er dialoger, altså ingen kontrakt ennå.
3. **Vedta kjernen nå og velg det tredje scopet etter 30 nye konkurranse-beslutninger.** Det er ærligst om usikkerheten, men utviklerne venter.

**Anbefaling: 2**, med to tillegg. (a) Ingen endring i `tracks.ts`/`VERTICAL_CONFIGS` som følge av beslutningen. Triagen skal fortsette å se det den ser i dag. (b) Valget prøves på bid-testsettet når det har ≥ 30 ja: dekker det nye scopet flere konkurranse-ja enn de tre foreslåtte? `TODO` eier: SC-04/data-1.

`UNKNOWN` Om kommunale forvaltningssystemer har små kontrakter (kriterium 3). 90 % av tildelingene mangler beløp (SCOPE-KATEGORIER-19OKT).
