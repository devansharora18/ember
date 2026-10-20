---
name: pr-describe
description: Use to write a pull request body from the diff — summary, risks, and a test plan a reviewer can execute. Not for writing the commits themselves (use commit) or user-facing changelogs (use release-notes).
---

# PR describe

The reviewer should understand the change before opening the diff.

## Gather

```bash
BASE=$(git merge-base HEAD origin/main)
git log --oneline $BASE..HEAD
git diff --stat $BASE..HEAD
```

Read the diff, not just the messages. If the branch does three things, say so and offer to split.

## Template

```
## What
One paragraph: the change and the user-visible effect.

## Why
The problem, linked to the issue. No restating "What".

## How
Only the non-obvious decisions: the trade-off, the rejected alternative,
the thing a reviewer would otherwise flag.

## Risks
- <area> — <what could break> — <mitigation>

## Test plan
- [ ] `npm test` — 41 passed, 2 new
- [ ] Manual: sign in -> create order -> 201 -> replay same key -> 200 same id
- [ ] Viewport 360: table scrolls, no horizontal overflow

## Screenshots
Before and after for anything visual.
```

## Rules

- A test plan is commands and observations, not "tested locally".
- Risks without a mitigation are fine — saying them out loud is the point.
- Never claim a clean run you did not execute.
- Breaking changes, migrations, flags, and the rollback path each get a line or an explicit "none".
- Under 400 words. Reviewers skim.
