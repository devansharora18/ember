---
name: skill-audit
description: Use to review a set of SKILL.md files for overlapping triggers, conflicting instructions, bloat, and weak descriptions an agent will never match. Keeps the library sharp as it grows. Not for writing new skills.
---

# Skill audit

A skill library fails two ways: the agent never finds the skill, or it finds two that disagree.

## 1. Inventory

Build a table: name, description verbatim, line count, and the concrete artifact it produces. Read every description the way the agent does — descriptions are the only routing signal.

## 2. Trigger collisions

Two skills collide if the same prompt plausibly matches both. For each pair decide:

- **Merge** — same job, different vocabulary.
- **Disambiguate** — add a negative clause to both: "Not for X (use Y)."
- **Keep separate** — genuinely different artifacts, such as a plan versus a diff.

Every description needs the trigger ("Use when…"), the output, and the nearest neighbour it is not.

## 3. Instruction conflicts

Look for rules that can both fire and disagree: commit versus autopilot, review versus verify, ui-ux versus design-critique. Resolve by making one skill defer explicitly: "Follow the `ui-ux` skill for X; this skill covers Y."

## 4. Bloat

- Over ~150 lines: cut examples, keep rules.
- Code samples that restate the rule: delete.
- Process the model already follows by default: delete.
- Anything project-specific that belongs in AGENTS.md, not a portable skill.

## 5. Description quality

Bad: "Helps with testing."

Good: "Use when an app needs to be exercised end to end — run it, click the main flows, log bugs, fix them, add regression tests. Not a code review (use review)."

## 6. Output

```
Verdict per skill: keep | trim | merge into <x> | rewrite description | delete

Collisions
- review vs qa — both claim "check the feature". Fix: review = diff, qa = running app.

Trim
- <skill>: lines 40-88 duplicate <other>; remove.

Missing
- No skill covers <gap>; prompts about it currently hit <wrong skill>.
```

Keep the library portable: no repo-specific paths, no secrets, no versions that rot in a month.
