---
date: 2026-05-13
type: postmortem
project: nexus
---

# firm.sh launch failure — wt.exe ERROR_FILE_NOT_FOUND on multi-line tab cmd

## Symptom

Several of the 8 Windows Terminal tabs spawned by `/home/nithu/code/_bin/firm.sh` failed to start, each showing:

```
[error 2147942402 (0x80070002) when launching `"
                                                echo "- $FIRM_TAB_OPENED_AT thesis-1 online in master-oppgave" >> "$HOME/Obsidian/Brain/00-firm-bus/feed.md""']
```

`2147942402 == 0x80070002 == ERROR_FILE_NOT_FOUND` — Windows is reporting that it could not find a program/file named (literally) the orphaned fragment `"\n echo "- ... feed.md""`.

## Where it breaks

`build_cmd()` (lines 43–54) emits a **multi-line** heredoc:

```bash
build_cmd() {
  local role="$1" project="$2" path="$3"
  cat <<EOF
export FIRM_ROLE='$role';
export FIRM_PROJECT='$project';
export FIRM_TAB_OPENED_AT="\$(date -u +%FT%TZ)";
mkdir -p "\$HOME/Obsidian/Brain/00-firm-bus/inbox";
touch "\$HOME/Obsidian/Brain/00-firm-bus/inbox/$role.md";
echo "- \$FIRM_TAB_OPENED_AT $role online in $project" >> "\$HOME/Obsidian/Brain/00-firm-bus/feed.md";
exec claude --dangerously-skip-permissions
EOF
}
```

That string (with embedded `\n` between every statement) is stuffed into `cmd_string` on line 73 and then passed as a single argv element to `wt.exe` on line 75/78:

```bash
args+=( new-tab --title "$role" wsl.exe --cd "$path" -- bash -lic "$cmd_string" )
…
"$WT" "${args[@]}"
```

## The pipeline failure, stage by stage

1. **Bash builds the argv correctly.** From bash's perspective, `cmd_string` is one argument containing literal newlines. `wsl.exe --cd ... -- bash -lic <cmd_string>` is the intent.
2. **WSL hands argv to `wt.exe` as a Win32 command line.** Crossing the WSL→Win32 boundary, the argv list is flattened back into a single command-line string. Win32 has no real argv — only `GetCommandLineW()` — so each argument is re-quoted by the interop layer using Win32's quoting rules (CRT/MSVCRT style), which only know about spaces and double-quotes, **not newlines**.
3. **`wt.exe` parses its own command line as a mini-DSL.** `wt.exe` does not just exec the rest; it tokenises its arguments looking for the subcommand (`new-tab`), flags, and `;` action separators, then re-assembles the trailing tokens into the **commandline** that the new tab should run. This re-tokeniser treats unescaped newlines as token terminators.
4. **The newline inside `cmd_string` splits the commandline.** After the first `\n`, everything before the newline (`export FIRM_ROLE='ai-1'; … FIRM_TAB_OPENED_AT="$(date …)";`) is consumed as the tab's `commandline`. The remainder (`mkdir …;\ntouch …;\necho …;\nexec claude …`) is left over on `wt`'s argv as if it were *more* `wt.exe` arguments.
5. **wt.exe tries to interpret the leftover as a new command/program.** The first leftover token starts with a stray closing `"` (from the broken `"$(date -u +%FT%TZ)"` quote pair that got bisected), then a newline, then `echo "- … feed.md""`. wt.exe attempts to *launch a program* whose path is that literal string. Windows' `CreateProcessW` fails with `ERROR_FILE_NOT_FOUND` (2 → 0x80070002 → 2147942402), and `wt` surfaces that verbatim in the error banner — which is exactly the message we see, including the leading lone `"` and the embedded newline.

So the root cause is **not** missing claude, missing PATH, or missing Obsidian path. The newlines emitted by the `build_cmd` heredoc survive WSL→Win32 marshalling and get re-interpreted by `wt.exe`'s own argument parser, fragmenting one bash command into "first-line-as-commandline + remaining-lines-as-bogus-program-name".

The reason some tabs "open but error" and others appear to succeed is just that the first line of the heredoc happens to be a valid no-op-ish bash statement (`export FIRM_ROLE='code-1';`) — the tab opens, runs that, then bash exits because there is no `exec bash` fallback inside the truncated half, and the operator sees the wt-level error from the leftover tokens.

## Why the previous quoting tricks won't save it

- Adding `\\` line continuations inside the heredoc doesn't help — bash already collapses `\<newline>`; the string we hand to wt still has newlines after every `;`-terminated statement.
- Joining with `; ` instead of `\n` would work, but only if the heredoc itself is single-line. As long as `cat <<EOF` spans multiple source lines, the output has `\n` separators.
- Wrapping `cmd_string` in extra `"…"` does nothing because wt's parser strips that layer before re-tokenising.

## Structural fix (one sentence)

Factor the per-tab init into a standalone script (e.g. `/home/nithu/code/_bin/firm-tab-init.sh`) that takes `role`, `project`, `path` as positional args, and invoke wt with a single-line single-quoted bash command — e.g. `bash -lic 'exec /home/nithu/code/_bin/firm-tab-init.sh ai-1 nexus /home/nithu/code/ai-assistent'` — so no newlines ever cross the WSL→wt.exe boundary.

## Suggested follow-ups (operator-gated, not auto-applied)

1. Create `firm-tab-init.sh` containing the body of `build_cmd` verbatim, reading `$1 $2 $3`.
2. Replace lines 71–80 of `firm.sh` so each tab passes a single-quoted one-liner: `bash -lic 'exec /home/nithu/code/_bin/firm-tab-init.sh "$@"' _ "$role" "$project" "$path"`.
3. Smoke-test with 2 tabs first (`--here` mode) before doing the full 8.
4. Add a sanity assert at the top of `firm.sh`: `[[ "$cmd_string" != *$'\n'* ]] || { echo "[firm] cmd_string contains newlines — abort"; exit 2; }` to catch regressions.
