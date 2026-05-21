---
tags: [command-center, prompts, agents, meta]
type: meta
created: 2026-05-16
---

# Prompts — command-center

Operator-edited overrides for the router + desk system prompts.

## Two layers

1. **Canonical persona** — `packages/agents/src/desks.ts` in the command-center repo. Source of truth for desk roles, default risk levels, tool allowlists. Ships with the code.
2. **Operator overrides** — this folder. Notes here let the operator tweak voice, add domain context, or pin temporary instructions without touching code.

Slice 6 wires the desks. Until then these are placeholders capturing intended shape.

## Desks

- [[desk-atlas]] — operations / status
- [[desk-cipher]] — code architecture
- [[desk-shield]] — safety / risk
- [[desk-prism]] — research / context
- [[desk-forge]] — implementation
- [[desk-blade]] — fast exec / debug

## Convention

Each desk note has frontmatter `{ name, role, default_risk, owned_by: agents-package }` and a body referencing the canonical persona in the repo. Keep these short — they augment, never replace.
