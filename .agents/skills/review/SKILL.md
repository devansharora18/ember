---
name: review
description: Use when asked to review a diff, branch, or pull request before merge. Diffs against the base branch, hunts bugs, security holes, missing tests, and structural problems, reports by severity, and fixes only the obvious ones. Not for reviewing a plan (use plan-review) or exercising a running app (use qa).
---

# Review

Review the change, not the codebase. Every finding must be caused by this diff or make this diff unsafe.

## 1. Establish the base

```bash
git fetch origin
BASE=$(git merge-base HEAD origin/main)
git diff --stat $BASE..HEAD
```

If the user names a branch or PR, use that. Never review the working tree when a branch was meant.

## 2. Read in this order

1. The diff file by file — not whole files first.
2. Any file the diff touches that is missing from its context.
3. The tests that should have changed and didn't.

## 3. Hunt in priority order

**Correctness** — off-by-one, null/nil paths, unhandled rejection, wrong comparison, shared mutable state, timezone/encoding, integer overflow.
**Security** — injection (SQL/shell/template), missing authz on a new route, secrets in code or logs, unbounded input, SSRF, unsafe deserialization, permissive CORS, path traversal, missing rate limit on a costly endpoint.
**Data** — migration not reversible, missing index on a new hot query, constraint dropped, nullable column written without a reader default.
**Tests** — new branch without a test, test asserting the mock instead of the behavior, snapshot updated without reading it.
**Structure** — business logic in a controller, a rule duplicated, an abstraction with one caller, a file that doubled in size.

## 4. Severity

| Level | Meaning | Action |
|---|---|---|
| Blocker | data loss, auth bypass, crash on the happy path | must fix before merge |
| High | wrong result in a realistic case, missing authz | fix now |
| Medium | edge case, missing test, leaky abstraction | fix or ticket |
| Nit | naming, formatting, preference | mention once, never block |

## 5. Fix, don't rewrite

- Fix blockers and highs directly when the fix is obvious and local (≤ ~20 lines, one file).
- Leave mediums as findings. Do not refactor unrelated code.
- Never "fix" a test by weakening it. If the test is wrong, say why and change the code or the assertion deliberately.
- One commit per fix, named after the defect.

## 6. Report

```
Verdict: block | approve with fixes | approve

Blocker
- src/auth/session.ts:42 — token compared with ==, allows type juggling.
  Fixed in a1b2c3. Regression test: "rejects numeric token".

Not fixed (needs a decision)
- ...
```

If there is nothing to report, say so in one line and name what you checked.
