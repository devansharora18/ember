---
name: verify
description: Use after any task, before saying it is done. Proves the change works with commands and real output — build, tests, and the actual flow. Never claims success from reading code. Not for finding an unknown bug (use investigate).
---

# Verify

"Done" is a claim about observed behavior, not about the diff.

## Evidence ladder

1. **Ran it** — the real flow, real input, observed output. Strongest.
2. **Tested it** — an automated test that fails without the change.
3. **Compiled it** — type check and build pass.
4. **Read it** — weakest; not evidence on its own.

Report the highest rung reached, not the highest rung you intended.

## Minimum per change type

| Change | Required proof |
|---|---|
| UI | build plus screenshot or click path at 360 and 1440 |
| API | request and response with status and body |
| Data | migration up, down, and a query on real rows |
| Config/infra | a command that reads back the effective value |
| Refactor | full suite before and after, identical results |

## How to report

```
Build: npm run build — ok (2.4s)
Tests: 41 passed — 2 new
Flow: POST /api/orders -> 201, id returned; replay -> 200 same id
Not verified: email delivery (no SMTP in this environment)
```

Name what you did **not** verify. Silence about a gap reads as a pass.

## Rules

- Do not paste output you did not run.
- Do not report a passing test run from before your last edit.
- If verification fails, say so and keep working. Do not downgrade the claim.
