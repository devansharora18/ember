---
name: qa
description: Use when an app or feature needs to be exercised end to end — run it, click through the main flows, log bugs with reproduction steps, fix them, and add regression tests. Not a code review (use review); this drives the real product.
---

# QA

Reading code does not tell you whether the button works.

## 1. Run the real thing

Start the app the way a user does (dev server, built preview, or the real environment). Note the exact command and URL. If it cannot start, that is bug #1.

## 2. Inventory the flows

List every user-visible path before clicking: sign in, create, edit, delete, search, empty state, error state, logout, and the one flow the feature exists for. Five to ten paths is typical. Include the unhappy path for each.

## 3. Drive it

- Browser: Playwright for repeatability, screenshots at 360 / 768 / 1440.
- HTTP: `curl -i` for status, headers, cookies; assert bodies, not just 200s.
- State: reload mid-flow, double-click submit, back button, two tabs, expired session.

```bash
npx playwright test --headed     # watching it fail is the point
```

## 4. Log each bug

```
[B2] Saving a draft with an empty title returns 500
Steps: New draft -> clear title -> Save
Expected: 422 with a field error
Actual: 500, stack in console, draft lost
Repro: 100%   Viewport: 390 / 768 / 1440
```

Severity: blocker (flow dead or data lost), high (wrong result), medium (confusing state), low (cosmetic).

## 5. Fix loop

Fix blockers first, one commit each, then re-run the exact repro. Do not keep clicking with a blocker open — it hides the next bug. Add a regression test for every blocker and high.

## 6. Exit criteria

- Every inventoried flow exercised at 360 and 1440.
- No blocker or high left open.
- Console clean; network tab free of 4xx/5xx that were not deliberately asserted.
- Regression tests committed and green.
- Report: flows, bugs found and fixed, what remains with severity.
