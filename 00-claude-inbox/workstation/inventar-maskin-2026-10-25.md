# Maskin-inventar NithuPC (WSL Ubuntu 24.04) — 2026-10-25

Read-only opptak. Ingen hemmeligheter; kun stier/variabelnavn. Kilde: ops-infra-pane.

Eksisterende verktoy som allerede dekker deler av dette (bruk, ikke bygg pa nytt):
`command-center/_bin/` preflight-old-machine.sh, capture-machine-manifest.sh, backup-local.sh (kryptert bundle: .env-filer, ~/.ssh, ~/.claude), bootstrap-new-machine.sh (idempotent), restore-local.sh.

## 1. CLI-er
- Node: to uavhengige. `~/.local/bin/node|npm|npx` -> `~/.local/opt/node` -> node-v24.21.0 (STAR FORST I PATH, dvs. `node` = 24.21.0). nvm (`~/.nvm`, default 24.15.0; ogsa v22.23.2) leverer `claude`. Systemd-units bruker nvm 24.15.0 (brain, executors, runner) unntatt omniroute (opt 24.21.0) og cc-api/cc-web (~/.local/bin/node).
- npm global, nvm 24.15.0: @anthropic-ai/*, @google/*, @openai/* (codex), firecrawl-cli, firecrawl-mcp, vercel. nvm 22.23.2: ingen.
- npm global, opt 24.21.0: @anthropic-ai/*, @googleworkspace/*, @openai/*, meta, omniroute, rea-agents, vercel. `meta` og `omniroute` er IKKE pa PATH (bin ligger i opt/bin); omniroute kalles med full sti fra unit.
- claude 2.1.301 (nvm npm). gh 2.92.0 (~/.local/bin, ikke apt-gh). railway 5.71.0 (/usr/local/bin + ~/.railway/bin). uv 0.11.8; uv tools: omnigent 0.18.0, open-webui 0.9.6. pipx: vastai, yt-dlp 2026.03.17. python3 = system 3.12.
- docker 29.1.3 (apt docker.io i WSL; Docker Desktop-sti ligger kun i Windows-PATH). ollama 0.30.8 (/usr/local/bin). zellij 0.44.1 (/usr/local/bin). oh-my-posh (~/.local/bin). litestream (.deb i ~/code/). 
- Andre ~/.local/bin: apify/actor (~/.apify), resend (~/.resend), slack (~/.slack), warp, hermes, heygen, muse, omni, rr, voicestudio, git-filter-repo.
- mise: snap (2026.10.19), `/snap/mise/273/bin` ligger FAST i PATH (rev 273, snap er na rev 283 -> PATH-linjen peker pa gammel rev; `.bashrc` bruker `/snap/bin/mise activate`, den fungerer). Ingen ~/.config/mise/config.toml. Ikke brukt av noe jeg fant.
- superset: ~/superset (bin/lib/share), PATH-linje sist i .bashrc. Skal droppes.
- apt manual (101 totalt, relevante): bash bat build-essential curl direnv docker.io eza fd-find ffmpeg gh git google-chrome-stable google-cloud-cli htop httpie jq litestream ocrmypdf pipx poppler-utils postgresql-client prometheus prometheus-node-exporter libreoffice-impress/writer ripgrep sqlite3 syncthing tree unzip xvfb zip zstd obsidian bubblewrap openssh-client + ubuntu-wsl/wsl. Pluss fonter og chrome/playwright-libs. (syncthing installert, men ingen config funnet.)
- Mangler pa PATH: nvm-funksjon i ikke-interaktive skall, starship (ikke brukt).

## 2. Shell
- ~/.bashrc (170 linjer, Ubuntu-standard + tillegg): nvm-init; `. ~/.local/bin/env`; PATH: ~/.railway/bin, ~/.opencode/bin, ~/.resend/bin, ~/superset/bin; `export NEXUS_REPO=/home/nithu/code/ai-assistent`; `source $NEXUS_REPO/tools/terminal/bash/nexus-bashrc.sh`; direnv-hook; `eval "$(/snap/bin/mise activate bash)"`.
- Prompt: oh-my-posh med tema `ai-assistent/tools/terminal/oh-my-posh/nexus-batman.omp.json` (init i nexus-bashrc.sh, som ogsa definerer firm-status/firm-talk/firm-start/firm-init). Tema + bashrc-snippet ligger i ai-assistent-repoet (sporet).
- Aliaser (alle i .bashrc): `firm-up`=ai-assistent/scripts/firm/firm-up.sh; `firm` og `nx` = command-center/_bin/firm-wt-split.sh; `firmt`=firm-wt-tabs.sh; `firmz`=firm-zellij.sh; `skole`=skole-wt-split.sh; `gull`=gull-wt-split.sh; `salg`=salg-wt-split.sh. (Alle = `/home/nithu/code/command-center/_bin/<script>`; hardkodet $HOME.)
- ~/.profile: Ubuntu-standard + `. ~/.local/bin/env`. Ingen ~/.bash_aliases.
- /etc/wsl.conf: systemd=true, default user nithu, interop pa. Windows: `C:\Users\nithu\.wslconfig` (12GB, 6 cpu, swap 8GB, mirrored networking, dnsTunneling, autoProxy).

## 3. systemd --user (~/.config/systemd/user)
Enabled: brain.target (-> brain-orchestrator, brain-worker; kjorer command-center/packages/*/dist, ExecStartPre brain-build.sh, EnvironmentFile command-center/.env), cockpit.target (-> cc-api :3100 tsx, cc-web :3200 next dev, cc-omnigent :6767 `omnigent server --agent command-center/omnigent/firm --database-uri sqlite:~/.omnigent/chat.db`, cc-omnigent-host), firm-remote-executor@{admin,data,infra,learning,orchestrator,paal,tools,trading}-1 (+ verdict-watch; EnvironmentFile .env og ~/.hermes/.env), anbud-vakt, anbud-modell-vakt (-> ~/.local/state/anbud-*/ + _bin), github-runner (~/actions-runner/run.sh, Solar-Consulting), hermes-gateway (~/.hermes/hermes-agent venv), litestream (-> ~/.config/litestream.yml, replikaer til ~/backups/litestream), omniroute (:20128, opt node), session-migration.service (enabled, men fil ikke i user-dir: sjekk hvor den ligger).
Timere: aslisten-crm-backup (03:30+12:30; kjorer aslisten-crm/scripts/fetch-backup.sh), ollama-keepwarm (10 min), gpu-roi-collect (hver time; ikke enabled i listen).
Sporet i git (command-center/docs/deploy/local-systemd/ + install-skript brain-/cockpit-/omnigent-install-systemd.sh): brain-*, cc-*, cockpit/brain.target, firm-remote-*, anbud-modell-vakt, gpu-roi-collect, brain-retention. 
IKKE sporet noe sted: omniroute, github-runner, hermes-gateway, anbud-vakt (+ ~/.local/state/anbud-vakt/vakt.sh), aslisten-crm-backup*(unit; skriptet er i aslisten-crm), ollama-keepwarm.service/timer (kun skriptet er sporet), litestream.service (kun docs/ nevner). Kopier disse inn i repoet.
Uncommitted i command-center na: _bin/firm-tab-init.sh, docs/deploy/local-systemd/cc-omnigent-host.service (branch orchestrator-1/omnigent-claude-path).

## 4. Claude Code
- ~/.claude/settings.json (kun nokkelnavn): model, hooks (SessionStart -> _bin/firm-hook-session-start.sh; Stop -> _bin/firm-hook-stop.sh), statusLine (node _bin/firm-statusline.mjs), enabledPlugins, extraKnownMarketplaces, tui, theme, skipDangerousModePermissionPrompt, remoteControlAtStartup. Ingen env/permissions-blokk, ingen hemmeligheter. Installeres av _bin/install-claude-hooks.sh / install-claude-statusline.sh.
- Plugins (marketplaces: claude-code-plugins, hyperframes): superpowers, frontend-design, feature-dev, commit-commands, skill-creator, claude-md-management, session-report, hyperframes (aktivert); installert i tillegg: ralph-wiggum, context7.
- ~/.claude/agents (10 stk, lokale): backend-api, brain-engineer, code-reviewer, data-pipeline, frontend-craft, ml-scientist, ops-infra, refactor-simplifier, researcher, test-engineer. Ingen ~/.claude/commands. ~/.claude/hooks tom.
- ~/.claude/skills lokale: finn-sok, grill-me, heygen-avatar/-translate/-video, humanizer, improve-codebase-architecture, prd-to-issues, tdd, trading-knowledge, use-railway, write-a-prd. Synket fra claude.ai (skills/synced/<uuid>/, genereres, ikke kopier): built-in-browser, chrome-browser, computer-use, deep-research, docs, docx, google-workspace, import-memory, morning, pdf, pptx, skill-creator, xlsx.
- MCP (user, ~/.claude.json): fetch (uvx mcp-server-fetch), fetch-docker (docker mcp gateway run), filesystem (npx server-filesystem /home/nithu/code), obsidian (npx obsidian-mcp-server; env-navn OBSIDIAN_API_KEY, OBSIDIAN_BASE_URL, OBSIDIAN_VERIFY_SSL), playwright (npx), railway (railway mcp). Per prosjekt: playwright (code, callcenter.js-mcp, ai-assistent), nexus-pg-rw (bash, ai-assistent). Repo-sporet: ai-assistent/.mcp.json.example, _bin/wire-secret-mcps.sh, mcp-pg.sh.
- Git: ~/.claude er IKKE et git-repo. Kun ai-assistent/.claude/settings.json og command-center/.claude/settings.json er sporet. Agents, lokale skills, settings.json og ~/.claude/CLAUDE.md er ikke sikret noe sted (utenom backup-local.sh-bundle).
- Memory (~/.claude/projects/*/memory): code 328K, ai-assistent 328K, Master-oppgave 68K, AS 52K, command-center 48K, aslisten-crm 48K, Personlig 28K, Soking 24K. projects/ totalt 1.7G (mest transkripter; ikke bar over).
- Auth: ~/.claude/.credentials.json (subscription OAuth) -> re-login pa ny maskin.

## 5. Firm / Omnigent / Hermes
- ~/.firm/state (132K), ~/.cache/firm (offset-filer per rolle, logger; kan gjenskapes). command-center/_bin: 116 filer (launchere, hooks, executors, backup, bootstrap, brain-*).
- Omnigent: server :6767, config `~/.omnigent/config.yaml` (host NithuPC, providers claude/codex subscription + ollama), data `~/.omnigent/chat.db` (8 MB sesjonshistorikk, artifacts/), agent-harness `command-center/omnigent/firm` (sporet). Installert via uv tool.
- Hermes: ~/.hermes (2.0G; .env, auth.json, config.yaml, SOUL.md, kanban.db, hermes-agent/ venv+kilde, skills). Telegram: TELEGRAM_BOT_TOKEN i ~/.hermes/.env; operator-ID i config.yaml. Docker-sandbox-container hermes-37d43b08 (stoppet).
- command-center/.env variabelnavn: API_HOST API_PORT WEB_PORT NEXT_PUBLIC_API_URL DB_PATH BRAIN_ROOT FIRM_BUS_DIR WORKSPACE_ROOT ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY ROUTER_MODEL ENFORCE_APPROVAL_GATE AUDIT_DUMP_DIR OLLAMA_BASE_URL LIVEAVATAR_API_KEY LIVEAVATAR_AVATAR_ID LIVEAVATAR_CONTEXT_ID HEYGEN_STAR_AVATAR_ID HEYGEN_STAR_VOICE_ID.
- ~/.hermes/.env variabelnavn: GPU_LLM_TOKEN ANTHROPIC_API_KEY TELEGRAM_BOT_TOKEN + TERMINAL_*/BROWSER*/ *_TOOLS_DEBUG.

## 6. Legitimasjon (kun sti/navn)
USB (filer): ~/.ssh/ (finnes, ikke lest); .env-filer: AS/.env, call-center-ai-demo/.env, aslisten-crm/.env.local, Veldora/.env, Veldora/website/.env.local, Veldora-lanes/website/.env.local, ai-assistent/.env + .env.local + .envrc, Renseri/.env.local, leadgen-mvp/.env, callcenter.js-mcp/.env, command-center/.env + .envu, research-os/.env, Master-oppgave/battery-electrolyte-predictor/.env, jarvis-wt/.envrc, .wt/ai-fsc/.envrc; ~/.hermes/.env + auth.json; ~/.gnupg; ~/.aws; ~/.docker/config.json; ~/.nexus-ops/ (cron-skript, ikke i git).
Re-autentiseres (gjenskap heller enn kopier): gh (~/.config/gh/hosts.yml), railway (~/.railway/config.json), claude (~/.claude/.credentials.json), gcloud (~/.config/gcloud), gws (~/.config/gws), slack (~/.slack), vastai (~/.config/vastai), resend (~/.resend), apify (~/.apify), heygen (~/.heygen; IKKE kjor heygen auth login), omniroute (~/.omniroute, provider-nokler), codex (~/.omnigent/codex-native), Google Chrome-profil (~/.config/google-chrome). Hermes/Telegram bot-token.
Docker: 179 volumer (de fleste anonyme). Containere med data: sc13-pg18 (kjorer, postgres:18), sc02-pg18, sc02-pg, mig-pg18, anbud-pg(-049, -smoke). Disse er lokale test/dev-DB-er; avgjor per container om innhold trengs (pg_dump) — jeg har ikke tatt dump.
Obsidian vault ~/Obsidian/Brain (65M, uten .obsidian-plugins-sjekk): git-repo, origin tiger-brain (SSH), branch main, MED usporede/uncommittede endringer (00-DASHBOARD.md, feed.md, inbox/ai-1.md, m.fl.) -> commit/sync for flytting. Autosync via Obsidian Git-plugin.
Lokale DB-er utenfor git: command-center/data/*.db (litestream -> ~/backups/litestream, SAMME disk), memory.db (~26k objekter; embeddinger regenerert via bge-m3), ~/.omnigent/chat.db, ~/.hermes/kanban.db, ~/backups/aslisten-crm.

## 7. Cron + Windows
- crontab: CRON_TZ=UTC; `*/30 6-21 * * 1-5` og `35 4 * * *` -> ~/.nexus-ops/nexus-watch.sh (log watch.log); `30 7 * * *` -> command-center/_bin/morgenbrief.sh. cron-demonen ma vaere pa (systemd-wsl).
- Windows: Windows Terminal (profil Ubuntu-24.04 er default); launcherne bruker `wt.exe` fra /mnt/c/Users/nithu/AppData/Local/Microsoft/WindowsApps/wt.exe, og noen /mnt/c/Users/-sti (14 treff i _bin, bl.a. firm-config.sh, firm-tab-init.sh, install-claude-*.sh). WT settings.json ligger i %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState. Windows-side verktoy i PATH: Git, Docker Desktop, VS Code, GitHub Desktop, Warp, PowerToys, winget age. Obsidian-app (REST API-plugin) er Windows-side; WSL nar den via mirrored networking pa 127.0.0.1.
- Usikkert: om Windows-hjemmemappen /mnt/c/Users/nithu har ting skripter leser (14 treff, ikke gatt gjennom en for en).

## Foreslatt layout
Nytt privat repo `workstation-bootstrap` (ingen hemmeligheter):
- dotfiles/: .bashrc-tillegg (uten superset/snap-mise-linjen), .profile, aliaser, ~/.wslconfig, /etc/wsl.conf, litestream.yml, ~/.omnigent/config.yaml (host_id fjernes/regenereres), WT settings.json-profil.
- systemd/: ALLE user-units (inkl. de usporede: omniroute, github-runner, hermes-gateway, anbud-vakt, aslisten-crm-backup*, ollama-keepwarm, litestream, session-migration) + enable-liste; stier gjort $HOME-relative.
- claude/: settings.json, ~/.claude/CLAUDE.md, agents/, lokale skills/ (ikke skills/synced), plugin- + marketplace-liste, mcp-servers.json uten env-verdier (kun navn), memory/ (kun MEMORY.md-filene, evt. som tarball siden hele memory er ~900K).
- manifest/: apt-mark showmanual, npm-global-lister for begge node, uv tool list, pipx list, crontab, ~/.nexus-ops/ skript, docker-containerliste. Bruk capture-machine-manifest.sh + bootstrap-new-machine.sh som ryggrad (sjekk at de dekker opt-node, pipx, snap og de usporede units).
USB (kryptert, via backup-local.sh): .env-listen over, ~/.ssh, ~/.gnupg, ~/.hermes/.env + auth.json, ~/.aws, ~/.docker/config.json, Obsidian-vault (eller push forst), pg_dump av beholdte docker-DB-er, ~/backups/aslisten-crm + litestream-replikaer, ~/.omnigent/chat.db, ~/.hermes/kanban.db + hermes-agent-konfig, lokale memory.db.
Manuell re-auth: gh auth login, railway login, claude (subscription), codex, gcloud, gws, slack, vastai, resend, apify, omniroute-providere, Chrome-profil/Google-innlogging, Telegram-bot (token fra USB-.env), Obsidian REST API-nokkel, GitHub runner-registrering (ny token), Windows Terminal + wt.exe-sti sjekk, Docker-bilder pulles pa nytt.
Frafall: ~/superset, snap-mise PATH-linje, `docker`-volumer anonyme (179, rydd ikke automatisk), gamle Veldora-* worktrees (~100 mapper i ~/code er sannsynlig worktrees; sjekk `git worktree list` for upushet arbeid for flytting).
