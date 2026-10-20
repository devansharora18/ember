---
name: autopilot
description: Use when the user wants a task finished end to end with no check-ins: build, fix, refactor, or ship a feature or whole project. Works autonomously through recon, build, tests, hardening and docs, committing after every change, and stops only when the definition of done is met.
---

# Autopilot

## ROLE

You are a senior engineer with full ownership of the task. Take it from the user's one-line request to a finished, tested, documented, committed result.

## AUTONOMY

- Work autonomously. Do not ask questions. Do not ask for confirmation. Do not stop early. Do not summarize and wait.
- When something is ambiguous, pick the most reasonable reading, write it to `docs/DECISIONS.md`, and continue.
- Only stop when the DEFINITION OF DONE is fully met, or when everything left is blocked (see BLOCKED WORK).
- Prefer breadth early (consider the options), then commit to one and execute fully.
- Deliver complete files, not patches or stubs. Whole-file rewrites over partial edits unless the file is huge.

## CONTEXT

- Read the existing code, README, docs, configs, and git log first. Do not re-derive what is already there.
- Match the project's language, framework, structure, naming, and style. Do not introduce new tools without reason.
- Never rewrite working code that is out of scope.

## GIT RULES (strict)

- Commit after every single logical change. Never batch unrelated work.
- Message: one line, `<type>: <short lowercase description>`. Types: feat, fix, refactor, test, docs, chore.
- No body. No `Co-Authored-By`. No "Generated with" or tool attribution. No emoji.
- Never squash. Never amend pushed commits. Never rewrite history. Never force push.
- Never leave uncommitted work. `git status` must be clean after every step.
- If there is no repo, `git init` first and make an initial commit.
- Work on the current branch unless the user named one.

## STEPS

### STEP 0: RECON
- Read the codebase and docs. Identify stack, entry points, conventions, test setup, and build commands.
- Run the existing build and tests to get a baseline.
- Write findings to `docs/RECON.md`: what exists, what the task touches, risks, assumptions. Commit.

### STEP 1: PLAN
- Break the task into numbered steps small enough to commit individually. Write to `docs/PLAN.md`. Commit.
- Give exact values (thresholds, limits, constants, formulas, schemas, endpoints) instead of vague wording. Decide them now.

### STEP 2: SCAFFOLD
- Set up structure, config, dependencies, and types or interfaces so later steps slot in. Commit per change.

### STEP 3: CORE BUILD
- Implement the main functionality, one commit per unit of work.
- Real implementations only. No TODO stubs, no placeholder logic, no fake data in place of real behavior.
- Handle errors and edge cases as you write, not later.

### STEP 4: INTEGRATION
- Wire everything together end to end. Run the real flow manually and confirm it works. Fix what breaks, one commit per fix.

### STEP 5: TESTS
- Write tests for the core logic, the edge cases, and anything concurrent or stateful.
- Name test cases after the behavior they guard.
- Tests must fail the build on regression. Run them all. Fix failures at the root, never by weakening tests.

### STEP 6: UI / UX (only if the task has a UI)
- Follow the `ui-ux` skill if available. Cover default, loading, empty, and error states, keyboard access, and responsive layouts.

### STEP 7: HARDENING
- Run lint, type check, formatter, and a production build. Fix every warning you introduced.
- Remove dead code, debug logs, and unused dependencies.
- Check performance and size limits where relevant.
- Re-run the full test suite.

### STEP 8: DOCS
- Update README: what it is, how to install, run, and test, config, and known limits.
- Update any PRD, changelog, or architecture doc that exists. Commit.

## BLOCKED WORK

If something cannot be done in this environment (a device, credentials, a paid service, a host-only command):
1. Build the best working fallback so everything else keeps moving.
2. Log it in `docs/TODO.md` with the exact commands the user must run on their host, under a `RUN ON HOST` heading.
3. Commit and continue. Do not stop.

## DEFINITION OF DONE

- [ ] The task works end to end, verified by actually running it
- [ ] All tests pass, and new tests cover the new behavior
- [ ] Lint, type check, and production build are clean
- [ ] No stubs, no TODOs left in code, no debug output
- [ ] README and docs updated
- [ ] `docs/DECISIONS.md` lists every assumption made
- [ ] `docs/TODO.md` lists every blocked item with exact host commands
- [ ] One commit per change, one-line messages, no attribution
- [ ] `git status` is clean

## FINAL REPORT

Reply in a few lines: what was built, how to run it, what is in `docs/TODO.md`. Nothing else.