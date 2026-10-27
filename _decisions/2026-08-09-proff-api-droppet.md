# Beslutning: Proff Premium API — droppet for nå (2026-08-09)

**Beslutning (operatør):** Takker nei til Proff API-tilbudet. Ingen integrasjon, probe-skript slettet, testtoken aldri tatt i bruk.

**Tilbudet:** Startup-avtale 1 000 kall / 10 000 NOK per år (10 kr/kall). Testtoken var gyldig tom 20.08.2026 (passordbeskyttet Word-doc i `~/code/AS/Proff Premium API, Kukaraja Sikkerhet.zip` — zip-en beholdes).
Kontakter: Marit Foss (teknisk, marit.foss@proff.no, +47 988 01 132), Thomas Nylænder (produkteier, thomas.nylaender@proff.no, +47 918 87 750).

**Hvorfor droppet:**
- CRM-en er ikke i pilot ennå — betalt kvote ville stått ubrukt.
- Unik verdi vs. åpne Brønnøysund-API-er er reell men smal: aksjonærdata, pant/heftelser (Mortgage-skjemaer verifisert i swagger), Changes-feed, reelle rettighetshavere. Alt er due diligence-nice-to-have, ikke noe hovedløkka trenger; Pål gjør ~2 manuelle gratis-oppslag i uka i dag.
- Leadgen-sporet (formuesforvalter-kompis, kunder >20 mill) ble vurdert og frarådet: 1000-kalls kvote umuliggjør massescreening, tredjepartsdeling er utenfor testvilkårene, og GDPR-ansvaret ved utlevering av personlister er ikke verdt det. Riktig produkt for det behovet er Proff Forvalt, i eget navn.

**Revurderes når:** CRM-en standardiseres/kommersialiseres (flere regnskapsførere) — da er databerikelse en produktfunksjon og 10k/år trivielt. Auth-format er dokumentert: `Authorization: Token <jwt>`, spec på https://api.proff.no/swagger/1.0/swagger.json.
