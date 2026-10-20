---
name: db-design
description: Use when designing or changing a relational schema — tables, keys, constraints, indexes, migrations, and query plans for hot paths. Not for API shapes (use spec) or query performance debugging without a schema change (use investigate).
---

# Database design

The schema outlives the code. Design for the queries you will run, then constrain what must never be true.

## Model

- Start from access patterns: the five queries that matter, with expected row counts.
- Normalize to 3NF first. Denormalize only with a measured read problem and a written plan for keeping copies consistent.
- Every table: `id` (opaque, e.g. UUID/ULID), `created_at`, `updated_at`. Soft delete only if the product needs recovery; otherwise delete.
- Money as integer minor units plus a currency code. Never float.
- Timestamps `timestamptz` in UTC; store the user's timezone separately if it changes behavior.

## Constraints are the spec

```sql
email citext NOT NULL UNIQUE,
status text NOT NULL CHECK (status IN ('pending','paid','refunded')),
order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
qty int NOT NULL CHECK (qty > 0)
```

NOT NULL, FK, UNIQUE, CHECK — in the database, not only in the ORM. The ORM is one client; the database is the contract.

## Indexes

- FK columns get an index; Postgres does not create one automatically.
- Composite: equality columns first, then range or sort. `(tenant_id, created_at DESC)` serves `WHERE tenant_id = ? ORDER BY created_at DESC`.
- Partial indexes for hot subsets: `WHERE status = 'pending'`.
- Every index costs write throughput. Justify each with a query.

## Migrations

- **Expand → migrate → contract** for anything that breaks old readers: add a nullable column → dual-write and backfill in batches → switch reads → drop the old one.
- One concern per migration. Never edit a migration that has run in production.
- Reversible, or explicitly marked irreversible with a tested restore.
- Backfills batched (1k–10k rows), throttled, resumable, idempotent.
- Test on production-shaped data and check lock behavior; a `DEFAULT` can rewrite the table on old engines.

## Verify with a plan

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

No sequential scan on a table expected to pass ~100k rows without a stated reason. Watch for N+1s from the ORM.

## Done when

Every constraint is enforced, every hot query has a plan, every migration has a way back, and seed data proves the shape.
