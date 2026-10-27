#!/usr/bin/env python3
"""enqueue.py — firm-bus jobbkø-hjelper for Hermes-sandboxen (Telegram-styring).

Finnes fordi Hermes' approval-allowlist bare matcher ENKLE kommandolinjer
(ingen heredoc/pipes/nylinjer). Skillen firm-remote skriver prompten til fil
med fil-verktøyet og kaller så denne med én flat linje som er allowlistet i
~/.hermes/config.yaml (`command_allowlist`).

Bruk (fra sandbox — /firm-bus er mountpunktet):
  python3 /firm-bus/jobs/enqueue.py enqueue <role> --prompt-file /firm-bus/jobs/intake/<x>.txt
  python3 /firm-bus/jobs/enqueue.py enqueue <role> <prompt-ord ...>
  python3 /firm-bus/jobs/enqueue.py verdict <job-id> approve
  python3 /firm-bus/jobs/enqueue.py verdict <job-id> reject <grunn-ord ...>

Skriver atomisk (tmp + rename) så host-executoren aldri ser halvskrevne filer.
Kanoniserer v1-rollenavn til v2 (speiler _bin/firm-roles.sh — hold i synk).
"""

import json
import os
import random
import re
import sys
import datetime

BUS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # …/00-firm-bus
JOBS = os.path.join(BUS, "jobs")

V1_TO_V2 = {
    "code-2": "orchestrator-1", "code-1": "infra-1",
    "ai-1": "trading-1", "ai-2": "learning-1",
    "as-1": "paal-1", "thesis-1": "tools-1",
    "soking-1": "data-1", "personal-1": "admin-1",
}
CLAUDE_ROLES = {
    "orchestrator-1", "infra-1", "trading-1", "learning-1",
    "paal-1", "tools-1", "data-1", "admin-1",
}
CODEX_ROLES = {f"codex-{i}" for i in range(1, 9)}
PII_ROLES = {"paal-1", "admin-1", "codex-6", "codex-7", "codex-8"}


def fail(msg: str) -> None:
    print(f"enqueue.py: {msg}", file=sys.stderr)
    sys.exit(2)


def do_enqueue(argv):
    if not argv:
        fail("enqueue krever <role>")
    role = V1_TO_V2.get(argv[0], argv[0])
    rest = argv[1:]
    if role not in CLAUDE_ROLES | CODEX_ROLES:
        fail(f"ukjent rolle '{role}' — gyldige: {' '.join(sorted(CLAUDE_ROLES | CODEX_ROLES))}")

    if rest and rest[0] == "--prompt-file":
        if len(rest) < 2:
            fail("--prompt-file krever en sti")
        try:
            with open(rest[1], encoding="utf-8") as f:
                prompt = f.read().strip()
        except OSError as e:
            fail(f"kan ikke lese prompt-fil: {e}")
    else:
        prompt = " ".join(rest).strip()
    if not prompt:
        fail("tom prompt")

    now = datetime.datetime.now(datetime.timezone.utc)
    jid = "job-{}-{}-{}".format(
        now.strftime("%Y%m%d-%H%M%S"),
        re.sub(r"[^A-Za-z0-9]", "", role),
        random.randint(1000, 99999),
    )
    qdir = os.path.join(JOBS, "queue", role)
    os.makedirs(qdir, exist_ok=True)
    engine = "codex" if role in CODEX_ROLES else "claude"
    stamp = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    rec = {
        "id": jid, "role": role, "engine": engine, "project": "", "cwd": "",
        "pii": role in PII_ROLES, "prompt": prompt, "prompt_raw": prompt,
        "origin": "telegram", "reply_to": "telegram",
        "status": "queued", "created": stamp, "updated": stamp,
        "result_path": "", "branch": "", "summary": "", "exit_code": None,
    }
    tmp = os.path.join(qdir, f".{jid}.json.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(rec, f, ensure_ascii=False, indent=2)
    os.replace(tmp, os.path.join(qdir, f"{jid}.json"))
    print(jid)


def do_verdict(argv):
    if len(argv) < 2:
        fail("verdict krever <job-id> approve|reject [grunn]")
    jid, action = argv[0], argv[1]
    if not re.fullmatch(r"job-[A-Za-z0-9-]+", jid):
        fail(f"ugyldig job-id '{jid}'")
    if action not in ("approve", "reject"):
        fail("verdict-handling må være approve eller reject")
    vdir = os.path.join(JOBS, "verdicts")
    os.makedirs(vdir, exist_ok=True)
    body = " ".join(argv[2:]) if len(argv) > 2 else ""
    tmp = os.path.join(vdir, f".{jid}.{action}.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(body)
    os.replace(tmp, os.path.join(vdir, f"{jid}.{action}"))
    print(f"{jid} -> {action}")


def main():
    if len(sys.argv) < 2:
        fail("bruk: enqueue.py enqueue|verdict …")
    cmd, argv = sys.argv[1], sys.argv[2:]
    if cmd == "enqueue":
        do_enqueue(argv)
    elif cmd == "verdict":
        do_verdict(argv)
    else:
        fail(f"ukjent kommando '{cmd}'")


if __name__ == "__main__":
    main()
