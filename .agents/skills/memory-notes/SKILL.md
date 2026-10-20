---
name: memory-notes
description: Use to keep a running docs/PROJECT.md of decisions, gotchas, and conventions that future sessions read first. Not for decisions with options (use adr) or end-of-session state (use handoff).
---

# Memory notes

Future you has no context. One file, read first, updated as you go.

## The file

`docs/PROJECT.md`, under 150 lines. Past that you are journaling, not remembering.

## Sections

```
# Project notes

## What this is
Two sentences: what it does, who uses it.

## Run it
Commands that actually work, in order, including the one that seeds data.

## Conventions
- Money in integer cents; never floats.
- All API errors go through apiError().
- Migrations are expand/contract; never edit a shipped one.

## Gotchas
- Tests are order-dependent until #142; run with --runInBand.
- The Stripe webhook needs a fresh tunnel URL after every restart.
- Do not touch src/legacy; frozen until Q3.

## Decisions
- Postgres over SQLite — docs/adr/0007.
- No global state library; server state lives in TanStack Query.

## Current state
- Working on: checkout retries. Next: idempotency keys.
- Known broken: CSV export on Safari.
```

## When to write

- A decision that took more than ten minutes.
- A trap that cost a debugging session.
- A convention a reviewer would otherwise flag.
- The exact command that starts the app.

## Rules

- Facts, not narrative. "X because Y" is a note; "we discussed X" is not.
- Date the volatile parts (versions, owners).
- Prune on every update: delete what the code now makes obvious, and anything stale.
- Never store secrets, tokens, or customer data.
- Link files by path and decisions by ADR number.

## At session start

Read it before running anything. If a note contradicts the code, the code wins — fix the note in the same commit.
