---
name: investigate
description: Use when something is broken and the cause is unknown. Reproduces it, forms ranked hypotheses, confirms with evidence, then makes a minimal fix plus a regression test. Never patches a symptom on a guess. Not for reviewing changes (use review) or testing known flows (use qa).
---

# Investigate

A fix without a confirmed cause is a second bug.

## 1. Reproduce, in writing

Get the smallest command, request, or click path that fails. Record expected, actual, frequency, environment, and the first commit where it appears.

```bash
git bisect start HEAD <known-good>
git bisect run <test command>
```

If it cannot be reproduced, stop and say so. Gather the missing evidence (logs, input, version) instead of guessing.

## 2. Hypothesize

Write 3–5 candidate causes, ranked by likelihood × cheapness to test. For each, the observation that would confirm it and the one that would rule it out.

| # | Hypothesis | Confirm by | Rule out by |
|---|---|---|---|

Three good hypotheses beat one guess plus a patch.

## 3. Confirm before touching code

Add a failing test, a log line, a breakpoint, or a query. The output must point at the cause, not the symptom. Delete diagnostic code afterwards.

- Never change behavior to make the symptom disappear.
- Never disable a check or catch-and-ignore to get green.
- If the evidence contradicts the hypothesis, discard it and return to step 2.

## 4. Minimal fix

Fix only the confirmed cause. If it is structural, fix the boundary (validation, type, invariant), not every call site. Note adjacent instances of the same defect but do not fix them in the same commit.

## 5. Regression test

The test must fail on the old code and pass on the new one. Name it after the behavior: `rejects expired reset token`, not `fix bug`.

## 6. Write-up

```
Cause: <one sentence>
Evidence: <command and output that proved it>
Fix: <file:line, one line>
Test: <name>
Still open: <same defect elsewhere, if any>
```
