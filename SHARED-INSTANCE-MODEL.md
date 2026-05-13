---
tags: [meta, architecture, sync]
type: meta
created: 2026-05-13
---

# SHARED-INSTANCE-MODEL

## 1. The vision

"One skeleton (GitHub), one brain (Obsidian vault), one Claude engine — both operator and Karri logged in from different locations. With aggressive auto-sync, it feels like working side-by-side on the same local PC."

The point: two physical machines, two human operators, but one logical workstation. Anything one party writes shows up on the other's screen within a few minutes, with no manual coordination overhead.

## 2. The 3 shared layers

| Layer | Where it lives | How it stays in sync |
|---|---|---|
| **Skeleton (code+brain repos)** | github.com/Nithu0/tiger-brain, github.com/Nithu0/ai-assistent | git push/pull |
| **Brain (Obsidian vault)** | `~/Obsidian/Brain/` on both machines | Obsidian Git plugin: auto-pull 2min, auto-commit 2min, auto-push 5min |
| **Claude engine** | claude.com account `Nithu0` | Both `claude login` with same credentials → shared billing + limits |

## 3. Per-machine separation (NOT shared)

- `~/.claude.json` (MCP config — each has their own keys for their own Obsidian instance)
- `~/.bashrc` (local aliases, FIRM_ROSTER setting)
- `git config user.name` (operator = "Nithu0" or real name, Karri = "Karri")
- SSH keys (each has their own keypair, both added to Nithu0 GitHub account)

## 4. How sync feels in practice

- Operator writes a note in `01-nexus/`, saves
- Within 2 min: Obsidian Git plugin commits + pushes
- Within 2 min after: Karri's plugin pulls, note appears in his vault
- Both can see firm-bus updates in `00-firm-bus/feed.md` live
- Worst-case end-to-end latency: ~5 min (commit interval + push interval + remote pull interval)
- Best-case: ~30 sec if either party triggers manual "Commit all and push" / "Pull"
- Neither operator nor Karri needs to think about git — the plugin handles it on a timer
- The graph view, backlinks, and tag panel all update on Karri's side as the file arrives, so it really does feel like a shared workspace

## 5. Conflict resolution

- **Trivial conflicts (different files)**: git merge resolves automatically, no human action required
- **Same file, different lines**: git auto-merges using standard three-way merge
- **Same file, same lines**: merge conflict — Obsidian Git plugin surfaces it in the source-control panel. Either:
  - Resolve in Obsidian's diff view (clicking the conflict markers, pick one side or hand-merge)
  - Or open terminal, `cd ~/Obsidian/Brain`, `git status` shows conflicted files, edit, `git add`, `git commit`
- **Strategy**: avoid simultaneous edits to the same paragraph. Use firm-bus inbox to coordinate ownership of hot files.
- **When in doubt**: pull before editing, especially after a long break. The plugin's "Pull" command is one click.
- **Last-resort**: if local state diverges badly, `git stash` your work, pull cleanly, then re-apply manually.

## 6. The "feels live" pattern

- Operator: "Karri, jeg legger inn en TODO i 01-CURRENT-FOCUS" → writes → saves
- Auto-sync within 2-5 min
- Karri's vault updates → he sees the new TODO in graph view
- He responds via inbox: `~/Obsidian/Brain/00-firm-bus/inbox/<operator-role>.md` → saves → syncs back

## 7. What's NOT live

- Claude conversations (each session is local to one machine — transcripts don't sync)
- Memory files (`~/.claude/projects/...` per-machine — each Claude instance builds its own working memory)
- Code repos changes (still git push/pull manually for ai-assistent — the brain auto-sync only covers tiger-brain)
- Local `.env` files and secrets (deliberately gitignored, never sync)
- Open Obsidian tabs / window layout (each operator has their own workspace state)
- The 5-minute lag means it's "near-real-time", not "instant" — don't use the brain for sub-minute coordination, use Discord/chat for that

## 8. Manual sync for urgency

When you need a note to land on the other machine within seconds, not minutes:

```bash
# In Obsidian: Cmd-P → "Obsidian Git: Commit all changes and push"
# In terminal:
cd ~/Obsidian/Brain && git pull && git add -A && git commit -m "manual sync" && git push
```

Then on the receiving side, either wait for the 2-min auto-pull or trigger `Cmd-P → "Obsidian Git: Pull"`.

## 9. CI cost concern

Aggressive auto-push triggers brain-checks + path-guard + secrets-scan on every push. With auto-commit every 2 min and auto-push every 5 min, that's potentially ~12 CI runs per hour per machine — multiplied by two machines, runner minutes add up fast.

Mitigations:
- Configure Obsidian Git plugin's commit message template to include `[skip ci]` for routine auto-commits
- Keep manual `git commit -m "..."` (without skip marker) for milestone commits that SHOULD run CI
- Periodically run a full CI pass on `main` via a scheduled workflow rather than on every push
- See `_runbooks/Runbook-Obsidian-Git-Sync.md` for plugin config details

## 10. Related

- [[Runbook-Obsidian-Git-Sync]] — plugin config, intervals, troubleshooting
- [[WHAT-IS-THE-BRAIN]] — what the vault is for
- [[BRAIN-RULES]] — rules of engagement for shared editing
- `00-firm-bus/README.md` (real-time coordination layer)
- `00-firm-bus/feed.md` (chronological event log both operators can append to)

---

Sist oppdatert: 2026-05-13
