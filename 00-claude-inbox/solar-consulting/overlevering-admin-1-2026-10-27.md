# Overlevering admin-1, 2026-10-27

## Gjort
- PR #327 (Nithu0/Solar-Consulting, gren adr-0023-organisasjon): ADR-0023 peker på organisasjonen Solar-Consulting, pakkene heter @solar-consulting/*, Aurora er app nr. 2 med Drizzle-unntak, og organisasjons-UNKNOWN er markert løst. TEAM-OPPGAVER.md har fått repolenker og `meta git clone https://github.com/Solar-Consulting/Terra.git`. Bare dokumentasjon. Auto-merge ved grønn CI.
- tre-scopes-tall: allerede på main via #207. Ingenting å pushe.

## Åpent (rekkefølge fra orchestrator-1 26.10)
1. drift PR #76 (juristens forslag om underdatabehandlere, USA og SSA). Ikke startet. Les diffen mot ARBEIDSFLYT.md og CLAUDE.md, review, og merge hvis den bare er dokumentasjon og stemmer.
2. Finansiering: drift #62–#66.
3. Noark: drift #53–#58.
4. Innhenting: drift #77, #79, #88.
Ikke rediger issue-beskrivelser i drift; kommenter, og legg utkast som filer/PR. «OK kjør» gjelder drift-PR-er som bare er dokumentasjon.
- Fra 22.10, fortsatt åpent: Tintuns intervju-YAML venter på at han godkjenner, og Alpers svar er ikke kommet. Prod-faktum id 28 er fortsatt feil.
- TODO i ADR-0023: Drizzle-unntaket skal føres inn i endringsloggen til ADR-0024 (teamet).

## Lærdom
- Innboksmeldinger fra 25.–26.10 kom aldri som monitor-hendelser, selv om offset-fila ble flyttet frem. Ved oppstart: les `inbox/admin-1.md` bakover fra offset (`grep -n "^## "`), ikke bare fremover.
- RETTELSE 2026-10-27T06:31:41Z: PR #327 er merget.
