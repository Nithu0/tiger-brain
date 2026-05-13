---
date: 2026-05-13
type: postmortem
project: nexus
status: fixed
parent: 2026-05-13_firm-launch-failure-diagnosis.md
---

# Firm launch failure diagnosis #2 — over-quoted inner command

Second launch-failure pattern hit after the first (heredoc/multiline → `0x80070002`) was fixed. Same `firm` entrypoint, different layer.

## 1. Symptom

Pane opened, sourced `nexus-bashrc.sh` and printed the banner ("Nexus shell ready..."), then died:

```
bash: /home/nithu/code/_bin/firm-tab-init.sh ai-4 nexus: No such file or directory
[process exited with code 127]
```

The pane closed itself before any agent could attach.

## 2. Root cause — literal single quotes wrapping the inner command

`firm-wt-split.sh` and `firm-wt-tabs.sh` were invoking `bash -lic` with the inner string wrapped in literal single quotes:

```bash
bash -lic "'$INIT ai-4 nexus'"   # WRONG
```

When `bash -c` parses `'firm-tab-init.sh ai-4 nexus'`, shell quote-removal strips the single quotes but the contents stay one word with embedded spaces. bash then tries to `execve()` a program literally named `firm-tab-init.sh ai-4 nexus` (spaces and all). No such file → 127 → exit.

## 3. Why the single quotes were there

A previous instruction said the inner command "MUST be one single-quoted single-line string". That was a confused requirement: the actual goal was **single-LINE** (so wt.exe doesn't split on newlines, which is what caused failure #1), not **single-quoted**. Wrapping the string in literal `'...'` was an over-correction that swapped one bug for another.

## 4. Fix — drop the literal quotes

```bash
bash -lic "$INIT ai-4 nexus"     # RIGHT
```

`bash -c` word-splits on whitespace and runs `firm-tab-init.sh` with `ai-4` and `nexus` as separate argv entries. The newline-split bug from failure #1 is still avoided because the string itself is single-line — no heredoc, no embedded `\n`.

## 5. Files touched

- `/home/nithu/code/_bin/firm-wt-split.sh` — 8 call sites de-quoted
- `/home/nithu/code/_bin/firm-wt-tabs.sh` — `inner=` line de-quoted
- `/home/nithu/code/_bin/firm-tab-init.sh` — added WARNING comment at top documenting both failure modes
- Runbook updated with this error mode (127 + "No such file or directory" containing spaces in the binary name)

## 6. Prevention

- `--dry-run` mode added to `firm-wt-split.sh` and `firm-wt-tabs.sh`. Use `firm --dry-run` to print the exact `wt.exe` argv array before launching, so the next launcher tweak can be inspected without spawning panes.
- Mental rule for `bash -lic "<CMD>"`: the outer double-quotes are the bash-arg wrapper. Don't add inner literal quotes "for safety" — `-c` already takes the whole string as one shell program.

## Cross-refs

- Parent: [[2026-05-13_firm-launch-failure-diagnosis]] (failure #1, heredoc/multiline → `0x80070002`)
- Both failures stacked in one diagnosis cycle today; fix #2 only made sense after fix #1 narrowed the failure surface.
