---
name: scratch
description: Use when you need a throwaway prototype to answer a question — timeboxed, isolated, explicitly not production. Records what must be rewritten before it could ship. Not for real features, even small ones.
---

# Scratch

A prototype answers one question. If it answers none, it's a liability.

## Before starting

Write down the question, the timebox (≤ 4 hours), and the success signal. "Can we render 10k markers at 60fps?" — "A URL that proves yes or no."

## Rules

- Isolate it: `scratch/<name>/` or a throwaway branch. Never inside `src/`, never imported by production code.
- Delete the abstraction instinct. Hardcode, inline, copy-paste.
- No tests. No error handling beyond what the question needs. No auth.
- Real data shape, fake values. If the shape is wrong, the answer is worthless.
- Commit with `chore: scratch — <question>` so it is easy to find and delete.

## When it's done

```
Question: ...
Answer: ... (with the evidence)
What was faked: auth, persistence, pagination, error paths
To ship this for real: ... (roughly ordered)
Delete by: <date or ticket>
```

## Exit

- Answered → port the *lesson*, not the code. Rewrite the real version properly; 10–20% of scratch code usually survives.
- Not answered, timebox hit → write the finding, delete it, escalate.
- Never merge scratch into main. If someone asks to, that is a new feature with a real plan.
