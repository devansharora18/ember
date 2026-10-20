---
name: handoff
description: Use at the end of a session, or when another person or agent takes over. Produces state, decisions, open items, and the exact next command, verified to work. Not a running project notebook (use memory-notes).
---

# Handoff

The next session should not have to rediscover anything you already know.

## Before writing

Run `git status` and the test suite. A handoff that claims "tests pass" without a run is worse than none.

## Template

```
# Handoff — <date>

## State
Branch: feat/x (clean | 3 uncommitted files)
Done: ...
In progress: ... (file, what is missing)
Not started: ...

## Decisions
- Chose X over Y because ... (link docs/adr/0007)

## Open items
- [ ] ... — blocked by <what>, owner <who>
- [ ] ... — needs a product decision

## Next command
npm run dev -- --port 5199
Then: open /checkout, reproduce bug B2, see docs/BUGS.md

## Traps
- The seed script needs DATABASE_URL; without it the app boots empty.
- Tests are order-dependent until #142 is fixed.
```

## Rules

- The next command must have been run in this session. Paste its output or say it failed.
- Link files by path, not by description.
- Record what you tried that did not work — it saves the next person the same hour.
- No motivational summary. State and next action only.
- If the project keeps docs in-repo, commit it as `docs/HANDOFF.md`; otherwise post it where the team reads.
