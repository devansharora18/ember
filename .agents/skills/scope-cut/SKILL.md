---
name: scope-cut
description: Use when a plan is too big to ship in the available time or before feedback. Produces the smallest shippable version, a cut list, and a later list with reasons. Not for challenging the plan's soundness (use plan-review).
---

# Scope cut

Shipping the right half beats shipping nothing, but only if it's the right half.

## The test

For every item ask: **if this is missing on day one, does the core user still get the value?** If yes, it moves to Later. If no, it stays.

## Buckets

- **Ship** — required for the one job the feature exists to do. Must be end-to-end and tested.
- **Manual** — do it by hand behind the scenes for the first N users. The cheapest way to learn whether it's needed.
- **Later** — real, but not now. Keep a one-line reason so it isn't re-litigated.
- **Never** — nobody asked; removing it simplifies something else.

## Rules

- Cut whole vertical slices, not half of every slice. A complete small flow beats five half-flows.
- Never cut error handling, auth, or the migration path. Those are not features.
- If the cut version still takes more than a week, cut by audience instead: serve one user type well.
- Name the trigger that brings something back ("when >10% of users hit X").

## Output

```
Smallest shippable version
- ... (3-6 bullets, each user-visible)

Cut to Later
- ... — because ...

Cut entirely
- ...

What the cut version explicitly cannot do
- ...

Revisit when
- ...
```

Show the cut to the person who asked. Silence is not approval for a smaller scope.
