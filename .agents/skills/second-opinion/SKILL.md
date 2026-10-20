---
name: second-opinion
description: Use when a plan or diff is expensive to get wrong and needs a cold read. Briefs a fresh agent with no prior context, asks for decision-changing findings only, and reconciles them with the first opinion. Not a substitute for plan-review or review on their own.
---

# Second opinion

Familiarity is bias. A reviewer who watched the plan being written will defend it.

## 1. Build a context packet

Give the fresh reviewer only what a new engineer would get:

- the goal in one paragraph;
- the plan, or `git diff base..HEAD` — not the whole repo;
- constraints (deadline, compatibility, compliance);
- what was already rejected and why.

Do **not** include your preferred answer, your reasoning trail, or "I think X is fine, right?".

## 2. Ask specific questions

1. What here is most likely to break in production?
2. What is being assumed that nobody verified?
3. What would you cut?
4. What would you do differently, and what does it cost?
5. Is there a simpler design that meets the same requirement?

## 3. Rules for the reviewer

- Findings must change a decision, not restate the plan.
- Every finding names a file, line, or step.
- "Looks good" is acceptable only with a statement of what was checked.

## 4. Reconcile

Compare both opinions in a table. For each disagreement, decide and say why. Agreement on a weak point is not evidence — check it yourself.

```
Agreement: ...
Disagreement: ... -> decided X because ...
New risk raised: ... -> mitigation ...
Verdict: ship | change first
```

Do not average the two opinions. Pick one and own it.
