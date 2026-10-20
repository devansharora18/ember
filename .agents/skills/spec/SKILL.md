---
name: spec
description: Use before implementation when an API contract or data schema must be fixed — endpoints, payloads, types, status codes, error cases, examples, and compatibility. Pairs with the waterfall rule for public contracts. Not for product scope (use prd).
---

# Spec

Write the contract before the code. If two teams can't implement from the document without talking, it isn't a spec.

## Shape

```
POST /v1/orders
Auth: bearer, scope orders:write
Idempotency-Key: required
Request:      { items: [{ sku: string, qty: int >= 1 }], currency: "usd" }
Response 201: { id, status: "pending", total, created_at }
Errors:       400 invalid_body | 401 missing_token | 409 duplicate_key
              422 unknown_sku (field: items[i].sku) | 429 rate_limited
```

## Rules

- **Version in the path** (`/v1/`) for public APIs. A breaking change is a new version, never a silent edit.
- **One error envelope** everywhere: `{ "error": { "code", "message", "field?" } }`. Codes are stable and machine-readable; messages are for humans.
- **Status codes mean one thing each.** 400 malformed, 401 unauthenticated, 403 unauthorized, 404 absent, 409 conflict, 422 semantically invalid, 429 throttled, 500 unknown.
- **Nullability is explicit.** Optional is not nullable. Say which.
- **Timestamps** ISO-8601 UTC. **IDs** opaque strings, never exposed sequential integers.
- **Pagination** cursor-based for anything that can grow; state the page-size limits.
- **Examples are valid** — real values, not `"string"`.

## Before signing off

- Every error case has a request that produces it.
- Every field has a type, a bound, and a reason to exist.
- A client can be written from this document alone.
- The migration path for existing consumers is stated.
- The schema change is additive, or the expand/migrate/contract plan is written (see `db-design`).
