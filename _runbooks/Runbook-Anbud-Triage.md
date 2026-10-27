---
title: Runbook — Anbud-triage
type: runbook
created: 2026-10-11
status: v1.0
audience: operator
purpose: Kjøre triage-køen i anbud-dashbordet uten å huske noe på forhånd
tags: [runbook, anbud, triage, solar-consulting]
---

# Runbook — Anbud-triage

`/tenders/triage` på `https://anbud-veldora.vercel.app`, eller `npm run dev` i `projects/anbud/dashboard` for `localhost:3100`. Kunngjøringen til venstre, beslutningen til høyre, ett anbud om gangen. Du må ha rollen medlem eller admin; lesetilgang gir kø og historikk uten knapper. Proveniensfargene, stegvisningen og utkast-lagringen er ukommittert arbeid på `feat/anbud-triage-veiledning` og ligger ikke på `main` ennå.

## Køen

Med i køen når alle tre holder: beslutning er `UNDECIDED`, status er `spotted` eller `screening`, og fristen er i framtiden eller ukjent. Ingen fit-terskel, så dårlig match (fit under 20) er med, men havner sist. Rekkefølge: dårlig fit sist, så høyest score (prioritet, ellers fit), så nærmeste frist, så id. Besluttede forsvinner ved neste henting.

Fire filtre i toppen: vertikal, minste fit (20/40/60/80), kilde (Doffin/TED) og frist (7/14/30 dager). **Fristfilteret fjerner også anbud med ukjent frist**, som ellers er med.

## De fem stegene

| # | Steg | Krav | Hva du gjør |
|---|---|---|---|
| 1 | Beslutning | Må fylles ut | Klart tilby, Tilby, Undersøk eller Ikke tilby |
| 2 | Hvorfor | Må fylles ut | Minst én årsak (15 på avslag, 10 på tilby). Bytter du side, nullstilles valgte |
| 3 | Oppfølging | Valgfritt | Tilleggsspørsmål for årsakene dine. Skjules når det ikke er noen |
| 4 | Begrunnelse | Må fylles ut | Minst 10 tegn, egne ord. Dette lærer systemet av |
| 5 | Kvalitetssjekk | Valgfritt | Var systemets vurdering for høy, riktig eller for lav, og hvor sikker du er |

Over lagreknappen står det hva som mangler, ellers «Klar til å lagre». Steg flagges som manglende først når du har prøvd å lagre, eller fylt ut noe lenger ned. I sveipemodus er høyre Tilby og venstre Ikke tilby, men et sveip lagrer ingenting — det forvelger beslutningen og åpner skjemaet. «Hopp over» registrerer ingenting.

## Fargekoden

Messing er systemet, blått er oss. Messing: systemet har funnet det, les og vurder. Blått: menneskelig kilde, og det er dette systemet lærer av.

Blått dekker både felt du skal fylle ut og det vi alt har besluttet, merket «Fra oss». Messingmerke inne i en blå seksjon betyr forhåndsfylt av systemet — rett det om det er feil. Forslagsboksen «Lært av våre beslutninger» er messing fordi systemet regnet den ut, og den vises først når teamet har tatt 30 beslutninger. Grønt og gult er tilstand, ikke kilde.

## Angre

To steder, og begge legger på en ny rad istedenfor å slette.

I køen: «Angre forrige» eller tasten `u`. Gjelder bare anbudet du nettopp besluttet, og du sendes tilbake til det. Ingen tidsgrense, men omfanget ligger i URL-en og forsvinner hvis du navigerer bort. I historikken: «Angre» per rad, men bare på første side uten filter, fordi en nyere beslutning ellers kan ligge utenfor listen. Angrer du et «Ikke tilby», går anbudet tilbake i køen.

Ulagret skjema lagres i nettleseren etter 0,4 sekunder og holdes i 30 dager. Du får tilbud om å gjenopprette eller forkaste.

## Historikken

`/tenders/triage/historikk`, lenke «Historikk» i toppen av køen. Nyeste først, med filtre på beslutning og årsak. Kolonnen «Grunnlaget» åpner snapshotet beslutningen ble tatt på: fit, vinnsjanse, verdi, dager til frist, fylke, kontroller som feilet, systemets forslag med om det ble fulgt, og våre egne årsaker og begrunnelse.

Loggen er append-only: rader endres aldri, en angring blir en ny rad med begrunnelsen «angret», og anbudet viser bare siste verdi. Beslutninger tatt utenfor triage havner også her, merket «Mulighetssiden» eller «Admin». **Telleren «besluttet i dag» teller rader**, så angre og beslutte på nytt teller to ganger.

## Hurtigtaster

| Tast | Handling |
|---|---|
| `1` | Klart tilby |
| `2` | Tilby |
| `3` | Undersøk |
| `4` eller `x` | Ikke tilby |
| `a`–`p` | Velg årsak (når en beslutning er valgt) |
| `t` | Skriv begrunnelse |
| `Ctrl/Cmd + Enter` | Lagre og gå til neste |
| `j` eller `→` | Neste anbud |
| `k` eller `←` | Forrige anbud |
| `s` | Hopp over |
| `o` | Åpne kunngjøringen |
| `u` | Angre forrige beslutning |
| `Esc` | Ut av feltet, eller nullstill beslutningen |
| `?` | Vis eller skjul oversikten |

Skriver du i et felt, virker bare `Ctrl/Cmd + Enter` og `Esc`. Er en beslutning valgt, går bokstavene til årsakene, så `j`, `k` og `o` er opptatt — `Esc` gir dem tilbake.
