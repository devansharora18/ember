---
name: adr
description: Use when a decision is expensive to reverse — stack, schema, auth, infra, public contract. Writes a short Architecture Decision Record to docs/adr/ with context, options, decision, and consequences. Not for session notes (use memory-notes).
---

# ADR

An ADR records why; the code only records what.

## When to write one

Before implementing, when the choice is costly to unwind: database engine, auth model, service boundary, queue versus cron, public API shape, hosting. Skip it for reversible local choices.

## File

`docs/adr/0007-postgres-over-sqlite.md` — sequential, kebab-case, never renumber.

```
# 0007 — Postgres over SQLite

Status: accepted    Date: 2026-05-14    Deciders: <names>

## Context
Two writers, concurrent jobs, and a reporting query that scans 2M rows.
Deploy target is a single VM today; managed Postgres is available.

## Options
1. SQLite + WAL — zero ops, one writer at a time, no concurrent writers.
2. Postgres managed — +$25/mo, concurrent writers, real types, pg_stat.
3. MySQL — the team has no production experience with it.

## Decision
Postgres. The concurrent-writer requirement is hard; the cost is trivial
against the reporting path it unblocks.

## Consequences
- Connection pooling must be handled (pgBouncer or the ORM pool).
- Local dev now needs a container: `docker compose up db`.
- Revisit if the monthly cost dominates revenue at <100 users.
```

## Rules

- One decision per record. If you need "and", write two.
- Options include the one rejected for cost and the one rejected for taste.
- Consequences list the bad ones. An ADR with only benefits is marketing.
- Never edit an accepted ADR. Supersede it with a new one and link both ways.
- Status: proposed → accepted → superseded or deprecated.
