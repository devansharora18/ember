---
name: refactor
description: Use for behavior-preserving changes only — renaming, extracting, moving, splitting. Tests first, tiny commits, and a rule that the diff never changes behavior. Not for fixing bugs (use investigate) or removing unused code (use dead-code).
---

# Refactor

The diff must be boring. If a reviewer has to reason about behavior, it isn't a refactor.

## Preconditions

- A green suite, or characterization tests you write first, covers the area.
- The behavior is observable somewhere: tests, a recorded request/response, a screenshot.
- One goal: rename, extract, move, inline, or split. Not two.

## Process

1. **Pin behavior.** Run the tests. If coverage is thin, add characterization tests that assert the current output — quirks included. Do not fix the quirks here.
2. **Smallest mechanical step.** Rename in one commit, extract in the next. A rename commit contains only a rename.
3. **Move, don't rewrite.** Cut and paste, then adjust imports. Resist "while I'm here".
4. **Run the suite after every step.** Green between commits, always.
5. **Stop at the goal.** The urge to keep going is the main risk. Note the next opportunity in the PR or a ticket.

## Rules

- No behavior change means no behavior change: same errors, same ordering, same null handling, same log lines.
- A public API, URL, or column name changes only with a deprecation path — that is a migration, not a refactor.
- Never combine a refactor with a fix. Two commits, refactor first, so the fix diff is readable.
- Measure before claiming performance. If the goal is speed, prove it with a benchmark and keep that commit separate.

## Verify

Same test results before and after, byte-identical fixture outputs where possible, and a diff where every hunk is explainable as "same behavior, different shape".
