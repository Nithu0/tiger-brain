# Sluttrapport: Knutepunkt (natt til 05.11)

Status kl. 06:56, målt av orchestrator-1 med `sc status`, `sc kost` og `gh`/`az`, med mindre annet står.

## Konklusjon

**Plattformen er bygget og i bruk, men ikke helt ferdig.** Fire av fem tjenester viser ekte data fullt ut. Google Workspace mangler brukere og 2FA til du gir én tilgang. Faktisk Azure-kost for testen er ikke målt.

Samlet status nå er **ADVARSEL**:

| Tjeneste | Status | Data |
|---|---|---|
| GitHub | ok | 7 repoer, 2 åpne PR-er, 385 Actions-minutter |
| Google Workspace | ukjent | mangler `admin.reports.usage.readonly` |
| Azure | ok | 2 ressursgrupper, 0 ressurser, 0 åpne varsler |
| Railway | advarsel | 9 prosjekter, 21 tjenester, 1 med avvik |
| Vercel | ok | 5 prosjekter, 2 domener |

Kost: Railway 30,40 USD i perioden (estimat 34,65). GitHub 0 USD, men det dekker bare Actions i organisasjonen. Azure, Google Workspace og Vercel er ukjent, så den reelle summen er høyere.

## Slik bruker du den

- **Terminal:** `sc status`, `sc kost`, `sc deploy-status`, `sc logg <tjeneste>`, `sc tilgang`
- **Claude på mobil:** `/plattform`
- **Cockpit:** fanen «Plattform» på http://localhost:3200
- **Hele teamet:** https://github.com/Solar-Consulting/drift/issues/217, oppdateres hver time

## Målt mot «ferdig når»

| # | Krav | Resultat |
|---|---|---|
| 1 | `sc status` viser ekte data fra alle fem | **Delvis.** Google Workspace mangler brukere og 2FA |
| 2 | Fanen viser det samme, også ved 390 px | **Ja**, i headless Chromium. Ikke testet på ekte mobil eller i Safari |
| 3 | Statusissuet oppdateres automatisk | **Ja**, med to forbehold under |
| 4 | Azure-test, ryddet, kost målt, OIDC og `what-if` | **Delvis.** Alt unntatt kosten |
| 5 | `/plattform` virker | **Delvis.** Lastes og gir data, men er ikke kjørt fra mobil |
| 6 | Tester grønne, QA, ingen hemmeligheter | **Ja.** 200 tester. Hemmeligheter er søkt med mønstre, så ukjente formater blir ikke funnet |

## Levert

- **Plattformkjernen (`packages/platform`):** adaptere for alle fem tjenestene, cache, lastgrenser, `/api/platform`, fanen og `sc`.
- **Antall PR-er siden start:** 20 i command-center, 4 i Terra, 5 i drift og 1 i Solar-Consulting. Ingen åpne PR-er står igjen i disse fire. Tallet for horizon fikk jeg ikke lest fordi nettet falt ut.
- **Azure:**
  - Hele `main.bicep` ble rullet ut på 11 minutter uten feil, også Postgres i Norway East. Appen svarte 200, og databasebrukeren fikk nei på `CREATE TABLE`, som den skal.
  - Alt er slettet, og `rg-terra-test` har 0 ressurser.
  - Innlogging fra GitHub uten lagrede hemmeligheter og `what-if` i CI er grønne (Terra #31).
  - Regionsperre gjelder `rg-terra-test` (Terra #32).
- **Horizon:** overgangen til `Solar-Consulting/horizon` er ferdig, inkludert steg 6–7 (#359, Terra #34, #146).
- **Også levert:**
  - PPT-måling for fylkeskommuner (drift #218). Visma Flyt har vunnet alle, første åpning er Trøndelag før 2028-08-01.
  - Agent-relé på GitHub (drift #219). Ikke testet fra start til slutt, for det krever en secret.
  - Måling av minnesøket: forbedringene holder, MRR 0,373 mot 0,333.

## Funnet og rettet i natt

- **DNS:** det så ut som nettet var nede, men det var WSLs DNS-tunnel som timet ut. Rettingen er midlertidig og forsvinner ved `wsl --shutdown`.
- **Sikkerhetshull i cockpit:** nettsider åpnet på maskinen kunne koble seg til websocketen og lese feed, innbokser og kommandoer (#157). Hullet har stått åpent lenge. Vi vet ikke om det er misbrukt, for loggen kan ikke vise det.
- **Plattformen tok ned maskinen:** 25 CLI-er samtidig ga load 54–70. Grenser er satt (#148, #149), og load er nå under 2.
- **Statusissuet viste falske feil** på Azure og Vercel i omtrent én time (#154). Teamet kan ha sett det.
- **Seks feil fra QA** (#156), blant annet at svar med feil form tok ned cockpit, og hull i sladdingen.

## Det som gikk galt

- **Fire paner sto stille i starten.** tools-1, admin-1, data-1 og paal-1 hadde stoppet etter API-feil, tools-1 helt siden 31.10. De så ikke oppdraget på 2,5 timer, og feeden skjulte det, fordi den viste «received dispatch». Jeg oppdaget det først da trading-1 sa fra. Det betyr også at eldre oppgaver jeg omtalte som i gang, ikke var det. De er levert nå. Jeg har ikke laget noen automatisk vekker for dette ennå.
- **Force push:** learning-1 forsøkte en force push på sin egen PR-gren, noe spesifikasjonen forbød. Den feilet på nettet, og ingenting ble overskrevet.
- **Cockpit var nede flere ganger,** 5–7 minutter under omstarter. En omstart tar opptil 6 minutter under last, fordi alle pakkene bygges.
- **Uforklart:** én kjøring av statusissuet feilet kl. 01:56, og én `what-if` feilet og gikk gjennom ved neste forsøk. Hvorfor embedding tar 2–8 sekunder under last, er heller ikke funnet ut.

## Fortsatt ikke løst

- **Standardruten faller ut:** 39 ganger på én time, 5 sekunder hver, også ved lav last. Årsaken er ukjent. Det gir enkeltfeil på tilkobling (rundt 1 av 40).
- **Anbud-vakten leser ikke Railway-logg.** Den melder at CLI-en ikke er lenket, så den sjekker bare HTTP.
- **Azure-kost:** anslått til under 0,50 USD ut fra listepris (antakelse). Budsjettet viser 0, men tallene henger etter. learning-1 sjekker igjen kl. 13:00.
- **Rester i Azure:** en Key Vault i soft delete til 11.11, som trolig må tømmes før ny utrulling før den datoen.
- **Tom fil `9`** i `~/code/command-center`. Ufarlig, men ingen har eid den.

## Det du må gjøre

**Raskt:**
1. Gi Google Workspace-tilgangen: `gws auth login` som admin, med `admin.reports.usage.readonly`.
2. Sett `AUTH_SECRET` i cockpit. Uten den kan alle prosesser på maskinen lese og skrive mot API-et. Den må på plass før Tailscale.
3. Test med kabel i stedet for wifi. Det krever ingen omstart, og viser om rutefeilen kommer av wifi.

**Avgjørelser:**
4. Railway-tjenesten `command-center` (prosjekt `acceptable-adaptation`) kjører kode fra 24.05, og hver merge starter en deploy som feiler. Fjern den, fiks den eller koble fra autodeploy?
5. `anbud-veldora` og de andre Vercel-prosjektene kjører funksjoner i USA (iad1), og alle står på Hobby. Skal `anbud-veldora` flyttes til Stockholm? Kommersiell bruk på Hobby bør sjekkes mot Vercels vilkår. Det har ingen gjort.
6. GitHub-organisasjonen bruker 4 seter på en plan som oppgir 2. Ikke undersøkt hva det betyr.
7. Senk Azure-budsjettet fra 500 til noe lavere? Abonnementet har ingen bruksgrense. learning-1 foreslår 50 USD, men budsjettet er oppgitt i kroner. Velg tall.
8. Regionsperre for hele abonnementet: skal Sweden Central med, som reserve for Azure OpenAI?

**Når det passer:**
9. Avtal et omstartsvindu for varig DNS-retting (`dnsTunneling=false`) og `wsl --update`.
10. Sett secret for agent-reléet, så det kan testes. Se #126.
11. Skal `horizon/CLAUDE.md` §6 rettes? Den peker fortsatt på Veldora-worktrees.

Avkrysningslisten for resten er https://github.com/Solar-Consulting/drift/issues/126 (33 åpne punkter).

## Rapporter

- QA: `00-claude-inbox/solar-consulting/KNUTEPUNKT-QA-paal-1.md`
- Nett: `00-claude-inbox/command-center/2026-11-05_nettutfall-wsl.md`
- Spesifikasjon: `00-claude-inbox/solar-consulting/KNUTEPUNKT-SPEC-2026-11-04.md`
