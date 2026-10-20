---
name: plan-review
description: Use before building, when a plan or design needs a hard look at scope, architecture, edge cases, failure modes, and test coverage. Returns an explicit go/no-go with required changes. Not for implementing (use autopilot) or reviewing finished code (use review).
---

# Plan review

Find the reason this plan fails before it costs a day of implementation.

## Inputs

A plan is reviewable only if it states the user-visible outcome, the files or modules touched, the data model change, the failure behavior, and how it will be tested. Missing any of these is the first finding.

## Challenge in five passes

1. **Scope** — What is here that the request didn't ask for? What is implied but missing? Name the smallest version that still solves the problem (see `scope-cut`).
2. **Architecture** — Does it put logic where the codebase already puts it? A new dependency, service, or queue: what does each buy, and what does it cost to remove later? Can the boundary be tested without a network?
3. **Edge cases** — empty, one, many, duplicate, concurrent, unauthorized, offline, slow, retried, partial failure, clock skew, unicode. Which have a defined result?
4. **Failure modes** — What happens when a third-party call times out mid-write? Is the operation idempotent? Is there a rollback path (see `rollback`)? What does the user see?
5. **Tests** — Which test proves the main path? Which proves the riskiest edge? If the answer is "manual", define the manual script.

## Go/no-go rubric

- **Go** — outcome is testable, the riskiest assumption has a cheap check, no unresolved data-loss or auth question.
- **Go with changes** — list them; they are conditions, not suggestions.
- **No-go** — the plan rests on an unverified assumption that changes the design. Name the spike that would settle it.

## Output

```
Verdict: go | go with changes | no-go

Must change
1. ... (why, and what to do instead)

Should change
1. ...

Missing from the plan
- error path for ...
- test for ...

Riskiest assumption
- ... — cheapest way to check it: ...
```

Do not rewrite the plan wholesale. Say what stands and change what doesn't.
