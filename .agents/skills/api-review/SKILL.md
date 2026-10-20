---
name: api-review
description: Use to review HTTP endpoints for auth, validation, pagination, idempotency, rate limits, consistent errors, and test coverage before shipping. Not for writing the contract up front (use spec) or reviewing a general diff (use review).
---

# API review

Check each endpoint against this list, in order. Stop at the first failure per endpoint.

## 1. Auth

- Authn on every route by default; public routes are listed explicitly, not accidentally unprotected.
- Authz is per object, not per role only: can user A read order B? Test it with a second account.
- Tokens: short-lived access, rotating refresh, a revocation path. No tokens in URLs or logs.
- Scopes and permissions are checked at the handler boundary, not in the UI.

## 2. Input

- Validate body, query, params, and headers at the boundary with a schema. Reject unknown fields where it matters.
- Bounds on every collection: `limit` default 20, max 100. No unbounded `findAll`.
- IDs are opaque; no sequential enumeration.
- Uploads: type, size, and content sniffing; store outside the webroot.

## 3. Semantics

| Concern | Rule |
|---|---|
| Status codes | 201 create, 204 delete, 409 conflict, 422 semantic, 429 throttled |
| Errors | one envelope: `{ error: { code, message, field? } }`, stable codes |
| Idempotency | mutating endpoints accept `Idempotency-Key`; a replay returns the first result |
| Pagination | cursor-based for growth; return `next_cursor` and `has_more` |
| Versioning | `/v1/`; additive changes only within a version |
| Timeouts | server timeout shorter than client timeout; return 504 explicitly |

## 4. Abuse

- Rate limit per key or IP on auth, search, and anything expensive.
- Payload size cap; query complexity cap for GraphQL.
- No stack traces, SQL, or internal hostnames in responses.
- CORS: explicit origins, never `*` with credentials.

## 5. Tests

- Happy path, validation failure, unauthorized, forbidden (another user's object), not found, conflict, rate limit.
- At least one integration test through the real router, not only the service function.

## Output

```
Blockers
- GET /v1/orders/:id has no ownership check — any authenticated user can read any order.
  Fix: scope the query by account_id; add a test with a second user.
```

Report only what is wrong, with the endpoint, the request that proves it, and the fix.
