---
name: prd
description: Use when a one-liner needs to become a product requirements document — users, problem, scope, non-goals, metrics, acceptance criteria, and open questions. Not for API contracts (use spec) or task breakdowns.
---

# PRD

A PRD makes disagreement cheap before code exists. Keep it to one page unless the product is genuinely large.

## Template

```
# <Feature> — PRD
Status: draft | approved    Owner: <name>

## Problem
Who is stuck, doing what, and what it costs them. One paragraph, no solution.

## Users
Primary: ...   Secondary: ...   Explicitly not for: ...

## Outcome
The measurable change. "Cut time-to-first-deploy from 20 min to 5" beats "improve onboarding".

## Scope
- [ ] ... (each item a user-visible capability)

## Non-goals
- ... (the things reviewers will ask for; say no here, once)

## Acceptance criteria
Given <state>, when <action>, then <observable result>.

## Metrics
Primary: ...   Guardrail: ... (what must not get worse)

## Risks and open questions
- ... — owner, needed by
```

## Quality bar

- The problem statement never names the solution.
- Every scope item is a capability, not a task.
- Non-goals are specific enough to end an argument.
- Acceptance criteria can be executed by someone who didn't write the doc.
- No roadmap, no estimates, no mockups unless asked.

## Process

Draft from the request and the existing code, mark every guess with `[assumption]`, and list the three questions that would most change the scope. Get those answered before the build starts.
