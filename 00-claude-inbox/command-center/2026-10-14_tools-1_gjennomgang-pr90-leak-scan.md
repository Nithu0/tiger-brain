# Gjennomgang av PR #90 (`infra-1/leak-scan`) — ikke klar for merge, to blokkerende

Dato: 2026-10-14 · gjennomgått av: tools-1 (adversarial agent + egen etterprøving)
PR: https://github.com/Nithu0/command-center/pull/90 — OPEN, MERGEABLE, CLEAN siden
2026-10-13T19:05:36Z, **null gjennomganger** på et døgn. 585+/39- over 11 filer.

## Hovedspørsmålet først: lekker skanneren det den finner? NEI.

Kjørt mot operatørens virkelige standardrøtter: 3930 filer, 2:01 veggtid, 302 MB topp-RSS,
exit 1 med ekte treff. Den skrev **ingen verdier** — bare sti, vertsklasse, brukernavn, port,
passord**lengde** og antall. Ingen rapportfil, ingen skriving, ingenting slettet. Den fant ekte
legitimasjon i agentlogger og holdt innholdet for seg selv. Ett forbehold: DB-**brukernavnet**
skrives ordrett (`_bin/leak-scan.py:139,155`), og for Supabase/Neon ligger prosjekt-refen i det.
Lav alvorlighet, men verdt å kjenne.

Og porten er reelt sterkere enn `871a291`: 15 push-stavemåter probet (`--paginate`, `-p`, `-P`,
`--bare`, `--literal-pathspecs`, `--no-optional-locks`, `--no-replace-objects`, `--attr-source`,
`--super-prefix`, `--namespace`, `--no-advice`, `-f`, `--mirror`, `--force-with-lease`, pluss en
remote lagt til midt i kjøringen) — alle blokkert. Global-opsjon/alias-parseren holdt.

## Blokkerende 1 — `engine_harden_env` brekker `git fetch`/`pull` i alle operatørens repoer

`_bin/firm-remote-executor.sh:63` (`credential.helper=`) + `:72` (`GIT_TERMINAL_PROMPT=0`,
`GIT_ASKPASS=/bin/false`). Målt:

```
error: unable to read askpass response from '/bin/false'
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

Kommentaren `:60-61` kaller dette en bivirkning for «PRIVATE repos». Jeg etterprøvde hvor stor
den mengden er — `git remote get-url origin` i alle fire repoene executoren kjører i:

| repo | origin |
|---|---|
| command-center | `https://github.com/Nithu0/command-center.git` |
| ai-assistent | `https://github.com/Nithu0/ai-assistent.git` |
| Veldora | `https://github.com/Nithu0/Veldora.git` |
| aslisten-crm | `https://github.com/Nithu0/aslisten-crm.git` |

Altså 100 % av repoene, ikke et kanttilfelle. Enhver remote-jobb som gjør `git fetch`, `git pull`
eller rebaser mot `origin/main` dør. Retning: dropp `credential.helper=` og len deg på full
`pushInsteadOf`-dekning + shimen, eller injiser et fetch-only token.

## Blokkerende 2 — `leak-scan.py` kan ikke oppdage OpenAI-nøkler i det hele tatt

To uavhengige defekter, begge etterprøvd i koden på PR-grenen:

1. `:68-70` — `SPOR`-forhåndsfilteret har ingen `sk-`-markør (bare `sk-ant-`). En fil hvis eneste
   legitimasjon er en OpenAI-nøkkel blir **hoppet over før noen detektor kjører**.
2. `:59` — `\bsk-[A-Za-z0-9]{32,}` kan ikke matche dagens former `sk-proj-…`, `sk-svcacct-…`,
   `sk-admin-…`, fordi de inneholder `-`/`_`.

14 oppdiktede token-formede prøver bygget; bommet på: `sk-proj-`, `sk-svcacct-`, legacy `sk-<48>`
(forhåndsfilteret), `github_pat_` (fine-grained PAT), `glpat-`, og Telegram bot-token
(`<siffer>:AA…` — som er den levende Hermes-legitimasjonen i dette systemet).
`ENV` `:53` dekker tre Postgres-variabelnavn og ikke `AUTH_SECRET`, `OPENAI_API_KEY`,
`TELEGRAM_BOT_TOKEN`, `RAILWAY_TOKEN`.

For en skanner bygget etter en lekkasje, og hvis `exit 0` leses som «rent», er en falsk negativ
den verst mulige feilmodusen.

## Middels

3. **ReDoS-fiksen kommentaren beskriver finnes ikke i koden.** `leak-scan.py:41-46` sier at hver
   kvantifikator er begrenset til 256 og at dette fjernet en flerminutters henging. `:51` er
   fortsatt ubegrenset `+` (`[^@\s"'\\]+`). Målt på 855 KB `postgres://a:a:a…`: **48,7 s ubegrenset
   mot 0,053 s med `{1,256}`**, kvadratisk skalering (46 KB→0,27 s · 185 KB→3,4 s · 925 KB→64 s).
   `MAKS_FIL` tillater 400 MB. Bruk grensen kommentaren alt spesifiserer.
4. **`git http-push` ikke blokkert.** `_bin/firm-exec-guard/git:61` tar `push|send-pack`.
   `git-http-push` er installert og slipper gjennom (nådde binæren, feilet på URL, ikke på vakten).
   Samme klasse som `send-pack`, ett ord å legge til. Utnyttbarhet lav (krever WebDAV-endepunkt).
5. **Dybdeforsvaret kan fjernes med én env-variabel og mangler transporter.** `:65-69` dekker
   `https/http/ssh/git://git@`. Mot et lokalt bare-repo: `GIT_CONFIG_COUNT=0 /usr/bin/git push` →
   pushet · `env -u GIT_CONFIG_COUNT /usr/bin/git push` → pushet · `git push file:///…` → pushet ·
   `git push /bare/sti` → pushet. Ikke en regresjon (shimen er primærporten og den holdt), men
   `firm-remote-executor.sh:57-59` og testetiketten `_bin/tests/push-gate.sh:44` («makes a shim
   BYPASS fail too») **overdriver**. Legg til `file://` + scp-formen `user@host:`, og omformuler
   påstanden til «mot uhell, ikke mot motstander».
6. **17 av testsuitens nekt-assertions består med vakten slettet.** `_bin/tests/push-gate.sh:17-22`:
   `expect nz` kan ikke skille en nekt fra et vilkårlig ikke-null exit, og shimene kalles med
   absolutt sti (→ 127 når de mangler). Med alle fire shimene slettet rapporterte alle 14
   blokk-assertions i seksjon 1 og alle tre publiser-CLI-assertions fortsatt `ok`; bare de 5
   gjennomslipps-assertionene feilet. Fiks: `grep -q firm-exec-guard "$T/out"` etter hver `nz`.
7. **`MASKERT` brukes ikke på API-nøkkel-treff.** `leak-scan.py:148-150`. Både
   `sk-ant-api03-xxxxxxxx…` og `ghp_REDACTED…` havner i «SER EKTE UT — rotér verdien». Agentlogger
   er fulle av maskerte nøkler, så høyhastebøtta fylles med støy — nøyaktig det docstringen selv
   advarer mot («en port man slutter å lese er ingen port»).
8. **For store og uleselige filer hoppes over i stillhet.** `:105` (`st.st_size > MAKS_FIL` →
   `continue`) og `:127` (`except OSError: return {}`). Største fil under standardroten er alt
   **279 MB** (`~/.claude/projects/-home-nithu-code/state/memory.db`) og voksende; når den krysser
   400 MB fortsetter skanningen å gi exit 0 uten et hint om at den sluttet å se på det viktigste
   artefaktet. Én advarselslinje per hoppet fil.

## Lav

9. **Omfang mot påstand.** Tittel og docstring sier «minne-substratet»; standardrøttene `:159-161`
   er `~/.claude/projects` + `/tmp/claude-$UID`. `~/Obsidian/Brain` skannes aldri som standard, og
   memory.db-en den treffer er dekket bare fordi den tilfeldigvis ligger under `~/.claude/projects/…`.
10. **Korte ekte hemmeligheter gir exit 0.** `MIN_EKTE=16` er et forsvarlig valg, men et ekte
    12-tegns DB-passord havner i «ser ut som eksempel — ingen handling». Skriv det som en kjent
    blindsone i stedet for «Exit 0 = ingenting».
11. **Asymmetri i env-bæreren.** `firm-remote-executor.sh:75-89` bruker robuste
    `GIT_CONFIG_PARAMETERS` for codex, men beholder `GIT_CONFIG_KEY_n` for claude — navn som
    matcher nøyaktig det `*KEY*`-filteret kommentaren frykter. Feilen er hard når den inntreffer:
    `GIT_CONFIG_COUNT=7` uten `GIT_CONFIG_KEY_0` → `fatal: unable to parse command-line config` på
    **hvert** git-kall. Bruk PARAMETERS for begge; da forsvinner grenen.
12. **Rollelåsen holdes gjennom 60 s preflight-venting.** `firm-tab-init.sh:91,123,163` /
    `codex-tab-init.sh:38,51,71`. Operatøren fikser PATH, relanserer innen 60 s, får «already
    running». Slipp låsen før ventingen.
13. **`.nvmrc` er omfangssprik og divergerer fra CI.** `20` → `24.15.0`, men
    `.github/workflows/test.yml:18,52` og `audit-dump.yml:19` hardkoder `node-version: '20'`; den
    pinner også 24.15.0 mens maskinen kjører 24.21.0. (`better-sqlite3` 11.10.0 laster på node 24 —
    verifisert, ingen native-modul-brekk.) Oppdater CI også, eller dropp filen.
14. **`push-gate.sh` er ikke koblet til CI** — ingen referanse i `.github/workflows/` eller
    `package.json`. Portens eneste regresjonstest er manuell.
15. **`gh`-shimen blokkerer også lesing** (`gh pr view`, `gh api`), så en remote-jobb kan ikke
    inspisere PR-/CI-tilstand. Designvalg — gjør det bevisst. Og ærlig: shimene blokkerer CLI-ene,
    ikke legitimasjonen. En motor som kjører med tillatelses-sperren av kan lese
    `~/.config/gh/hosts.yml` og curle API-et direkte. Dette er et gjerde mot uhell, ikke en
    sandkasse, og dokumentasjonen bør si det.

## Dom

**Ikke klar for merge som den står — trenger forfatteren (infra-1), to blokkerende.**
Ingen sikkerhetshull innføres, skanneren lekker ikke, og push-porten er en reell forbedring. Men
(1) brekker levende remote-jobber første gang en av dem trenger `git fetch`, og (2) betyr at et
verktøy bygget etter en legitimasjonslekkasje er blindt for hele OpenAI-nøkkelklassen pluss
fine-grained GitHub-PAT-er og Telegram bot-tokenet — mens `exit 0` leses som «rent».

Fiks 1 og 2, bruk regex-grensen i 3 (kommentaren spesifiserer den alt) og énlinjes-herdingen i 6;
resten kan landes som oppfølging.

Suitestatus som den står: `bash _bin/tests/push-gate.sh` → 47 bestått, 0 feilet. `bash -n` rent på
alle berørte skallskript.

## Hva jeg etterprøvde selv (ikke bare videreformidlet)

Blokkerende 1: lest `firm-remote-executor.sh:55-95` på PR-grenen + målt origin-skjema i alle fire
repoene. Blokkerende 2: lest `NOKLER["openai"]` `:59` og `SPOR` `:68-70` — begge defektene står i
koden. Funn 3: `URL`-regexen `:51` er ubegrenset `+` mens kommentaren `:41-46` hevder 256-grense.
Funn 6: `expect()` `:17-22` tester bare `rc -ne 0`. Alle fire holder.
