#!/usr/bin/env bash
# brain-link-graph.sh — dump brain wikilink graph as JSON
#
# Purpose: read-only scan of all [[wikilinks]] across brain, output node-edge
# graph for visualization (D3, gephi, etc.) or analytics.
#
# Usage:
#   brain-link-graph.sh [output_file]
#   BRAIN=/custom/path brain-link-graph.sh
#
# Default output: stdout (operator pipes to file).
# Optional arg: output file path.
#
# Output JSON schema:
#   {
#     "generated_at": ISO-8601 UTC timestamp,
#     "brain_root": absolute path,
#     "total_notes": int,
#     "total_links": int,
#     "node_count_by_type": { "<type>": count, ..., "untyped": count },
#     "top_hub_nodes": [ { id, in_degree, out_degree, path } x20 ],
#     "nodes": [ { id, path, tags[], type, out_degree, in_degree } ],
#     "edges": [ { from, to, context } ]
#   }
#
# Read-only. No brain mutation.
set -euo pipefail

BRAIN="${BRAIN:-$HOME/Obsidian/Brain}"
OUTPUT="${1:-/dev/stdout}"

cd "$BRAIN"

# Pre-conditions
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

# Use python for the heavy lifting (file walk + regex + json)
python3 <<'PYEOF' > "$OUTPUT"
import os, re, json, datetime
from collections import defaultdict

BRAIN = os.path.expanduser(os.environ.get("BRAIN", "~/Obsidian/Brain"))
SKIP = {".git", ".obsidian", "_library", "node_modules", "__pycache__"}

nodes = {}
edges = []

# Pass 1: collect all .md files as nodes
for root, dirs, files in os.walk(BRAIN):
    dirs[:] = [d for d in dirs if d not in SKIP]
    for f in files:
        if not f.endswith(".md"):
            continue
        name = f[:-3]  # strip .md
        path = os.path.relpath(os.path.join(root, f), BRAIN)

        # Parse frontmatter for tags + type
        tags = []
        type_ = None
        try:
            with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
                content = fh.read()
            fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
            if fm_match:
                fm = fm_match.group(1)
                tags_match = re.search(r'tags:\s*\[(.*?)\]', fm)
                if tags_match:
                    tags = [t.strip().strip('"\'') for t in tags_match.group(1).split(',') if t.strip()]
                type_match = re.search(r'type:\s*(\w+)', fm)
                if type_match:
                    type_ = type_match.group(1)
        except Exception:
            pass

        nodes[name] = {
            "id": name,
            "path": path,
            "tags": tags,
            "type": type_,
            "out_degree": 0,
            "in_degree": 0,
        }

# Pass 2: collect all wikilinks as edges
link_pattern = re.compile(r'\[\[([^\]|]+)(\|[^\]]+)?\]\]')

def strip_code_blocks_and_spans(text):
    """Remove fenced code blocks and inline code-spans so wikilinks cited
    inside markdown code don't get counted as real edges (meta-leakage)."""
    # Fenced code blocks ```...``` (non-greedy, multiline)
    text = re.sub(r'```.*?```', '', text, flags=re.DOTALL)
    # Indented code blocks: lines starting with 4+ spaces or tab
    # (handled coarsely — only strip the lines, not full blocks)
    text = re.sub(r'(?m)^(?: {4,}|\t).*$', '', text)
    # Inline code spans `...` (single backticks; non-greedy, single-line)
    text = re.sub(r'`[^`\n]*`', '', text)
    return text

for root, dirs, files in os.walk(BRAIN):
    dirs[:] = [d for d in dirs if d not in SKIP]
    for f in files:
        if not f.endswith(".md"):
            continue
        src_name = f[:-3]
        try:
            with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except Exception:
            continue
        # Strip code-blocks/spans to suppress meta-leakage from audit reports
        # citing wikilinks as content. Real wikilinks live in prose + frontmatter.
        content = strip_code_blocks_and_spans(content)
        for match in link_pattern.finditer(content):
            target = match.group(1).strip()
            # Skip folder-path-style links
            if '/' in target:
                continue
            # Strip optional heading anchor (#section) and block-ref (^id)
            target = re.split(r'[#^]', target, 1)[0].strip()
            if not target:
                continue
            edges.append({
                "from": src_name,
                "to": target,
                "context": None,  # could parse surrounding heading if needed
            })
            if src_name in nodes:
                nodes[src_name]["out_degree"] += 1
            if target in nodes:
                nodes[target]["in_degree"] += 1

# Aggregate type counts
type_counts = defaultdict(int)
for n in nodes.values():
    type_counts[n.get("type") or "untyped"] += 1

# Output
output = {
    "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "brain_root": BRAIN,
    "total_notes": len(nodes),
    "total_links": len(edges),
    "node_count_by_type": dict(type_counts),
    "top_hub_nodes": sorted(
        [{"id": n["id"], "in_degree": n["in_degree"], "out_degree": n["out_degree"], "path": n["path"]}
         for n in nodes.values()],
        key=lambda x: x["in_degree"] + x["out_degree"],
        reverse=True
    )[:20],
    "nodes": list(nodes.values()),
    "edges": edges,
}

print(json.dumps(output, indent=2))
PYEOF
