# Brain-synken: rotårsak og fiks (2026-10-27, infra-1)

## Rotårsak (målt)
- Windows-Obsidian har bare én vault registrert (`%APPDATA%\obsidian\obsidian.json`): `C:\Users\nithu\Personlig AI\MY AI`, med tre eksempelfiler. Den åpner ikke `~/Obsidian/Brain`.
- `obsidian-git` står i `.obsidian/community-plugins.json`, men `.obsidian/plugins/` har bare `obsidian-local-rest-api`. Pluginen er ikke installert.
- Følgen er at ingen plugin har committet i denne vaulten. Det er andre gang synken står: 10.06→13.07 (b31c8d1) og 13.07→27.10. Workspace-CLAUDE.md sier «auto-syncs via Obsidian Git plugin (2-5 min)», og det er feil.

## Engangssynk: Nithu0/tiger-brain#1
- 1 310 filer, +81 078 og −5 560 linjer. Laget med midlertidig indeks og commit-tree. Den delte checkouten er urørt (main, a90aaf7, 394 endringer står fortsatt).
- Hemmelighetsskann: gitleaks 8.21.2 fant 0 treff i 1 352 filer. Et ekstra mønstersøk ga 4 treff, og alle var postgres-plassholdere. Full historikk (`--all`, 69 commits) med repoets config: 0 lekkasjer.
- path-guard: 46 beskyttede filer, 36 i `90-archive/` og 10 andre (00-DASHBOARD.md, BRAIN-RULES.md, TEAMMATE-ONBOARDING.md, _decisions, _maps, 4 i _runbooks, claude-context/SYSTEM-MAP.md). Den trenger OPERATOR-APPROVED fra operatøren.
- Andre røde sjekker, som ikke gjelder innholdet:
  - `secrets-scan` har feilet i **hver kjøring siden mai**. Pinnen `gitleaks-action@a18b9de` finnes ikke upstream, så repoet har aldri blitt skannet.
  - `audit` kjører `--strict`, så 24 advarsler (0 feil) feiler den. De fleste er brutte wikilinks. I tillegg er det to filtyper: en `.zip` (anbudspakke, `00-claude-inbox/solar-consulting/rammeverk/ppt-anbud/`) og `00-firm-bus/inbox/orchestrator-1.md` på 1,2 MB.
  - `monthly-inbox-archive` har feilet 01.08, 01.09 og 01.10.
- Etter merge (merge commit anbefales) i `~/Obsidian/Brain`: `git fetch && git reset origin/main`. Det er en mixed reset, som ikke rører filene.

## gitleaks-fiks: venter på godkjenning
- Branchen `infra-1/fix-gitleaks-sha` i worktree `~/code/.wt/brain-gitleaks` låser til `ff98106e…` (v2.3.9). Den er committet lokalt, men **ikke pushet**: pre-push-hooken (`sanity.sh` → `path_guard.py`) stopper endringer i `.github/` uten OPERATOR-APPROVED, og jeg omgår den ikke.
- Funn i hooken: lokalt leter `path_guard.py` etter markøren i commitmeldinger når PR-tekst mangler. Pushen av #1 slapp gjennom på en gammel markør fra 13.07 («operatør ga 'ok kjør' 2026-07-13»), ikke på en ny godkjenning. CI path-guard leser derimot PR-teksten og stopper #1 riktig.

## Varig fiks: Nithu0/command-center#112 (ikke aktivert)
- `_bin/brain-sync.sh` og `brain-sync.{service,timer}` kjører hvert 15. minutt. Den lager et øyeblikksbilde av arbeidstreet til `sync/<host>`, med gitleaks før push. Ved treff stopper den og skriver fil og regel (aldri verdien) til feed.md. Den pusher bare fast-forward, aldri main og aldri force, og rører ikke checkouten. main blandes ikke inn (three-dot-merge beholder endringer på main).
- Testet mot et engangsrepo: lekkasjen stoppes, ren endring pushes, ingen endring gir ingen commit, og endringer på main overlever merge. Tørrkjørt mot den ekte vaulten: 3 s.
- Installasjon (gitleaks til `~/.local/bin`, symlinke unitene, enable timer) står i unit-headeren.

## Trenger beslutning
1. Operatøren: OPERATOR-APPROVED i tiger-brain#1, og merge med merge commit.
2. Push av gitleaks-fiksen. Enten legger operatøren markøren i en commit, eller orchestrator gir meg lov til `--no-verify` for akkurat den pushen. CI path-guard krever uansett OPERATOR-APPROVED i PR-en.
3. Om `.zip`-filen skal ut av vaulten (eller i `.gitignore`), og om `audit --strict` skal stoppe på advarsler.
4. Aktivere brain-sync.timer (#112).
5. Rette workspace-CLAUDE.md-påstanden om pluginen.
