#!/usr/bin/env bash
# brain-content-audit.sh — weekly hygiene scan of ~/Obsidian/Brain
# Reports issues only — does NOT fix anything (operator-decision)
#
# Exempt paths (intentionally without frontmatter — per H-2 cleanup-report-2026-05-25):
# - _library/ (raw content)
# - 90-archive/ (historical)
# - 00-claude-inbox/ (drafts)
# - 00-templates/ (uses placeholders)
# - README.md (subfolder intro)
# - HOW-TO-*.md (operator instructions)
#
# These exemptions apply to [1/7] frontmatter-presence and [2/7] YAML-validity
# checks. Real notes (decisions, runbooks, MOCs) remain in scope.
set -euo pipefail

BRAIN="${BRAIN:-$HOME/Obsidian/Brain}"
cd "$BRAIN"

# Color
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'; BLU='\033[0;34m'; NC='\033[0m'

ISSUES=0
WARN=0

issue() { echo -e "${RED}!${NC} $*"; ISSUES=$((ISSUES+1)); }
warn()  { echo -e "${YEL}!${NC} $*"; WARN=$((WARN+1)); }
ok()    { echo -e "${GRN}✓${NC} $*"; }
hdr()   { echo -e "${BLU}=== $* ===${NC}"; }

hdr "brain-content-audit"
echo "Brain: $BRAIN"
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# 1. Frontmatter presence — every .md should start with `---`
# (Exemptions: see header comment block for the intentionally-frontmatter-free paths.)
hdr "[1/7] Frontmatter presence"
missing_frontmatter=$(find . -name "*.md" \
  -not -path "./.git/*" \
  -not -path "./.obsidian/*" \
  -not -path "./_library/*" \
  -not -path "./90-archive/*" \
  -not -path "./00-claude-inbox/*" \
  -not -path "./00-templates/*" \
  -not -name "README.md" \
  -not -name "HOW-TO-*.md" \
  -exec sh -c 'head -1 "$1" | grep -q "^---$" || echo "$1"' _ {} \; 2>/dev/null | head -20 || true)
if [ -n "$missing_frontmatter" ]; then
  warn "Notes without frontmatter (first 20):"
  echo "$missing_frontmatter" | sed 's/^/    /'
else
  ok "All notes have frontmatter (---)"
fi

# 2. Frontmatter YAML validity — parse first --- ... --- block
hdr "[2/7] Frontmatter YAML validity"
if command -v python3 >/dev/null 2>&1; then
  invalid_yaml=$(python3 <<'PYEOF' 2>/dev/null || true
import os, re
try:
    import yaml
except ImportError:
    print("__NO_YAML__")
    raise SystemExit(0)
# Exempt paths (intentionally without frontmatter — see script header).
EXEMPT_DIRS = (".git", ".obsidian", "_library", "90-archive",
               "00-claude-inbox", "00-templates")
broken = []
for root, dirs, files in os.walk("."):
    if any(x in root.split(os.sep) for x in EXEMPT_DIRS):
        continue
    for f in files:
        if not f.endswith(".md"): continue
        if f == "README.md": continue
        if f.startswith("HOW-TO-") and f.endswith(".md"): continue
        p = os.path.join(root, f)
        try:
            with open(p) as fh:
                content = fh.read()
            m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
            if m:
                yaml.safe_load(m.group(1))
        except Exception as e:
            broken.append(f"{p}: {str(e)[:80]}")
            if len(broken) >= 20: break
    if len(broken) >= 20: break
print("\n".join(broken))
PYEOF
)
  if [ "$invalid_yaml" = "__NO_YAML__" ]; then
    warn "python3 yaml module not available — skipping YAML validity check"
  elif [ -n "$invalid_yaml" ]; then
    issue "Invalid YAML frontmatter (first 20):"
    echo "$invalid_yaml" | sed 's/^/    /'
  else
    ok "All frontmatter YAML valid"
  fi
else
  warn "python3 not available — skipping YAML validity check"
fi

# 3. Broken wikilinks — every [[X]] should resolve to a .md file
hdr "[3/7] Wikilinks"
# Extract all [[X]] (ignore [[X|alias]] alias part)
# Build set of known note names (basename without .md)
all_notes=$(find . -name "*.md" -not -path "./.git/*" -not -path "./.obsidian/*" -not -path "./_library/*" -exec basename {} .md \; | sort -u)

# Find all wikilinks
grep -rho '\[\[[^]]*\]\]' . --include="*.md" 2>/dev/null \
  | sort -u \
  | head -500 \
  | while read -r link; do
      # Extract target (strip [[, ]], and |alias)
      target=$(echo "$link" | sed 's/^\[\[//;s/\]\]$//;s/|.*$//;s/#.*$//')
      [ -z "$target" ] && continue
      # Skip if target is a folder path (contains /)
      case "$target" in
        */*) continue ;;
      esac
      if ! echo "$all_notes" | grep -qxF "$target"; then
        # Check if there's a documented stub elsewhere
        echo "$link"
      fi
    done > /tmp/broken-links.txt 2>/dev/null || true
broken_count=$(wc -l < /tmp/broken-links.txt 2>/dev/null || echo 0)
if [ "$broken_count" -gt 0 ]; then
  warn "$broken_count potentially-broken wikilinks (first 20):"
  head -20 /tmp/broken-links.txt | sed 's/^/    /'
  echo "    (See ~/Obsidian/Brain/08-system-architecture/wikilink-audit-*.md for documented stubs)"
else
  ok "No obviously-broken wikilinks"
fi

# 4. Markdown-style links inside vault (should be wikilinks only per OBSIDIAN_BRAIN_STRUCTURE)
hdr "[4/7] Markdown-link usage (should be wikilinks)"
# Find [text](path) where path doesn't have :// (not external URL)
md_links=$(grep -rln --include="*.md" --exclude-dir=".git" --exclude-dir=".obsidian" --exclude-dir="_library" -E '\]\([^)]*\.md\)' . 2>/dev/null | head -10 || true)
if [ -n "$md_links" ]; then
  warn "Markdown links to .md files (should be wikilinks) — first 10 files:"
  echo "$md_links" | sed 's/^/    /'
else
  ok "No markdown-style links to .md files"
fi

# 5. Date-stamped files — verify dates aren't future
hdr "[5/7] Future-dated files"
today=$(date -u +%Y-%m-%d)
future_files=""
# Pre-filter find output through head BEFORE the while-loop to avoid SIGPIPE
# under `set -euo pipefail` once we've collected enough hits. Pipe order
# (find | head | while) is the cleanest fix per option (c) of the bug report.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  d=$(basename "$f" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' 2>/dev/null || true)
  if [ -n "$d" ] && [ "$d" \> "$today" ]; then
    future_files="${future_files}${f} ($d)"$'\n'
  fi
done < <(find . -name "????-??-??-*.md" -not -path "./.git/*" 2>/dev/null | head -100 || true)
future_files=$(printf '%s' "$future_files" | head -10)
if [ -n "$future_files" ]; then
  warn "Future-dated files (first 10):"
  echo "$future_files" | sed 's/^/    /'
else
  ok "No future-dated files"
fi

# 6. Required folders present
hdr "[6/7] Required folders"
for folder in 00-DASHBOARD.md 00-CONTROL-PANEL.md 01-CURRENT-FOCUS.md \
              _maps _decisions _runbooks _library \
              00-firm-bus 00-claude-inbox 00-templates \
              03-skills 08-system-architecture 09-retrospectives 10-tasks \
              12-youtube 13-github-repos; do
  if [ -e "$folder" ]; then
    ok "$folder present"
  else
    issue "$folder MISSING"
  fi
done

# 7. Required README files
hdr "[7/7] Required folder READMEs"
for folder in 03-skills 09-retrospectives 10-tasks 12-youtube 13-github-repos 00-templates 00-firm-bus; do
  if [ -d "$folder" ] && [ ! -f "$folder/README.md" ]; then
    warn "$folder/ missing README.md"
  elif [ -d "$folder" ]; then
    ok "$folder/README.md present"
  fi
done

# Summary
hdr "Summary"
echo -e "  Issues: ${RED}$ISSUES${NC}"
echo -e "  Warnings: ${YEL}$WARN${NC}"

if [ "$ISSUES" -gt 0 ]; then
  echo -e "${RED}AUDIT FAILED${NC} — fix issues before next weekly cadence"
  exit 1
fi

if [ "$WARN" -gt 0 ]; then
  echo -e "${YEL}AUDIT WARNINGS${NC} — review at convenience"
fi

echo -e "${GRN}AUDIT OK${NC}"
exit 0
