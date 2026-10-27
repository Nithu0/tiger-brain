# Klar for PC-flytting — 27.10.2026

_tools-1. Grunnlag: `preflight-old-machine.sh` i rapportmodus (startet 09:14Z, tok ~30 min inkludert backup-dry-run), og oppryddingen tidligere i dag (`worktrees-2026-10-27.md`). `--apply` er **ikke** kjørt._

## Grønt
- **Repoer med remote som er rene:** horizon, aurora, Terra/{aurora,nova,solar-consulting}, leadgen-{mvp,pipeline,platform}, workstation, nova-t1, Terra-infra-t1 og _refs-klonene.
- **Sikret på GitHub i dag:**
  - grossist-plattform: PR #1, venter på operatøren.
  - call-center-ai-demo: PR #1.
  - leadgen-pipeline og leadgen-platform: nye private repoer. Persondata ble holdt utenfor, og 1881-numrene er byttet med syntetiske.
- **Worktrees:** 84 ferdige er fjernet, alle grener beholdt.
- **Skann av Brain:** ingen hemmeligheter i de ~1 370 ucommittede filene. Treffene var 11-sifrede Actions-run-ID-er.
- **`--apply` er rettet før bruk** (#115, #116):
  - Den pusher ikke lenger `--all --tags`. Det ville gitt ~500 grener og hundrevis av Actions-kjøringer, pluss backup-tagger med persondata.
  - Stash og ucommittede filer i repoer med remote kommer nå med i den krypterte bundelen. Det gjorde de ikke før.
  - `horizon-patch` (Horizon-cutoveren) og `thesis-evaluator` er lagt til i backupen. Ingen av dem er git-repoer, og de var ikke dekket.
- **Backup-dry-run** gikk gjennom. AS, Søking fulltid, grossist-plattform, leadgen-*, lavera-site og refi-doc-agent stages med full .git. Krypteres med **gpg** (age er ikke installert).

## Gjenstår

| Hva | Eier |
|---|---|
| Kjør `bash ~/code/command-center/_bin/preflight-old-machine.sh --apply`. Krever passphrase; **noter den** (uten den er bundelen tapt). Regn med ~30 min eller mer. | operatør |
| Kopier `~/backups/cc-local-backup-*.tar.gz.gpg` til USB/OneDrive. Valgfritt: `wsl --export Ubuntu D:\backup\nithupc.tar` fra PowerShell. | operatør |
| **Brain:** 395 ucommittet, og siste push til tiger-brain var 13.07. `--apply` kjører `git add -A` + push. Det tar med 06-AS (3 filer) og 04-career (2) til det private tiger-brain-repoet. Er det greit? | operatør |
| **Veldora-hovedcheckout** står på `feat/secure-age` med 6 ucommittet. Eier er ukjent, og innholdet ser kryptert/sensitivt ut. Det tas nå med i den krypterte tar-en, men grenen bør avklares. | orchestrator-1 → operatør |
| **ai-assistent:** 22 ucommittet og 5 stash, og trading-1s forslag om hovedcheckouten venter på «OK kjør». | orchestrator-1 |
| **Lokale grener som ikke er på origin:** Veldora 299 (644 commits), ai-assistent 188 (63), command-center 22 (16), drift 4, Terra 2, Renseri 2, aslisten-crm 2, Master-oppgave 2. `--apply` legger dem i git-bundler uten å pushe. Eierne kan pushe det de vil beholde. | panene / orchestrator-1 |
| 19 grener med commits bare lokalt og ingen PR (liste i worktrees-rapporten, (c)). | panene |
| `horizon-import` har ingen remote. Den er tools-1s gjenskapbare filter-repo-kopi og tas ikke med med vilje. | — |
| Etter flytting: i hvert repo, `git fetch <bundle> 'refs/heads/*:refs/remotes/bundle/*' …` og `tar -xzf ~/backups/uncommitted/<repo>.tar.gz -C <repo>`. Instruksjonen står i Neste-teksten. | den som bootstrapper |

## Hva `--apply` gjør (etter #115/#116)
1. **Hvert repo med remote:** alt som ikke er på en remote (grener, tagger, stash) går til `~/backups/git-bundles/<repo>.bundle`, og endrede/usporede filer til `~/backups/uncommitted/<repo>.tar.gz`. **Ingen push.**
2. **Brain:** `git add -A` → commit «pre-migration snapshot» → push til tiger-brain.
3. **Workstation:** `workstation-sync.sh` → commit → push (maskinoppsett uten hemmeligheter).
4. **Machine-manifest** (fra 10.06): regenereres, committes og **pushes rett til command-center main** (ingen PR).
5. **`backup-local.sh`:** passphrase → `~/backups/cc-local-backup-<UTC>.tar.gz.gpg`. Den inneholder .env-filene, maskinfiler (HOME_EXTRA), full kilde for NO_REMOTE_REPOS, git-bundlene og uncommitted-tar-ene. Staging i /tmp shreddes etterpå.

## Rettet underveis i dag uten operatøren
- #115 og #116: se Grønt.
- **Plaintext-kopi i /tmp:** en avbrutt dry-run (min første kjøring traff 280 s-timeout) lot `/tmp/cc-local-backup.IukIZ7` ligge igjen. Den var 1,4 GB med 3 720 filer, inkludert stagede .env-kopier i klartekst. Den er nå shreddet og borte (bekreftet). 976 skrivebeskyttede git-objekter krevde chmod før shred. Samme feil fantes i backup-local sin egen opprydding og er rettet (PR tools-1/shred-skrivebeskyttet). Staging ligger nå i ~/.cache med opprydding ved start (#117).
- **Stub i ~/code:** `~/code/.git` er bare en løs `info/exclude`, ikke et repo. Preflight og firm-repos ignorerer den nå. Selve stubben er ikke slettet.
