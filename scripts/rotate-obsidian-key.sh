#!/usr/bin/env bash
# Rotate the Obsidian Local REST API key in ~/.claude.json
#
# Use case: after clicking "Re-generate API key" in Obsidian's Local REST
# API plugin, the new key is in .obsidian/plugins/obsidian-local-rest-api/
# data.json. This script reads it and updates the MCP config in
# ~/.claude.json so Claude Code's obsidian MCP server uses the new key.
#
# Idempotent. Backs up ~/.claude.json before modifying.
# Usage:
#   bash scripts/rotate-obsidian-key.sh
#   bash scripts/rotate-obsidian-key.sh --dry-run
#   bash scripts/rotate-obsidian-key.sh --vault /path/to/Brain --config ~/.claude.json

set -uo pipefail

VAULT="${BRAIN_VAULT:-$HOME/Obsidian/Brain}"
CONFIG="$HOME/.claude.json"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="$2"; shift 2 ;;
    --config)  CONFIG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

DATA_JSON="$VAULT/.obsidian/plugins/obsidian-local-rest-api/data.json"

if [[ ! -f "$DATA_JSON" ]]; then
  echo "ERROR: plugin data.json not found at $DATA_JSON" >&2
  echo "       Did you re-generate the key in Obsidian first?" >&2
  exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: claude config not found at $CONFIG" >&2
  exit 1
fi

# Pull the new key out of data.json (single python call — no shell interpolation)
NEW_KEY=$(python3 - "$DATA_JSON" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get("apiKey", ""))
PY
)

if [[ -z "$NEW_KEY" ]]; then
  echo "ERROR: could not read apiKey from $DATA_JSON" >&2
  exit 1
fi

echo "==> new key length: ${#NEW_KEY} chars (not printing the value)"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> dry-run: would update OBSIDIAN_API_KEY in $CONFIG"
  exit 0
fi

# Backup
BAK="${CONFIG}.bak-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG" "$BAK"
echo "==> backup: $BAK"

# Update OBSIDIAN_API_KEY in mcpServers.obsidian.env
python3 - "$CONFIG" "$NEW_KEY" <<'PY'
import json, sys
config_path, new_key = sys.argv[1], sys.argv[2]
with open(config_path) as f:
    d = json.load(f)
try:
    d["mcpServers"]["obsidian"]["env"]["OBSIDIAN_API_KEY"] = new_key
except KeyError as e:
    print(f"ERROR: missing key path in claude.json: {e}", file=sys.stderr)
    sys.exit(1)
with open(config_path, "w") as f:
    json.dump(d, f, indent=2)
print("==> updated mcpServers.obsidian.env.OBSIDIAN_API_KEY")
PY

echo "==> done. Restart Claude Code (or open a new firm tab) to pick up the new key."
