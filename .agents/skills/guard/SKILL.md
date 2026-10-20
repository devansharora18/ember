---
name: guard
description: Use when an agent will run shell commands or edit files unattended. Blocks destructive operations (rm -rf, force push, DROP, truncate, credential changes) and confines writes to an approved directory. Pairs with /autopilot.
---

# Guard

Autonomy is safe only inside a fence. Define the fence before granting it.

## 1. Declare the fence

```
Writable:    ./            (the repo root)
Readable:    everything
Allowed net: package registries, documentation
Approval:    any command outside the allowlist
```

If the task names a directory, that directory is the fence. Everything outside is read-only.

## 2. Hard blocks

Never run, even with approval, unless the user pastes the target path themselves:

| Pattern | Why |
|---|---|
| `rm -rf /`, `rm -rf ~`, `rm -rf ..` | unrecoverable |
| `git push --force` on a shared branch | rewrites others' work |
| `git reset --hard` with uncommitted work | silent loss |
| `DROP DATABASE`, `TRUNCATE`, unqualified `DELETE` | data loss |
| `chmod -R 777`, `curl … \| sudo bash` | privilege escalation |
| writes outside the fence, `.env*`, `~/.ssh`, credentials | exfiltration |
| `pkill`, `kill -9` on system processes | host stability |
| publish, deploy, send email, charge a card | irreversible side effects |

## 3. Soft blocks — confirm first

`git clean`, major dependency upgrades, schema migrations, deleting a branch, rewriting history, changing CI secrets, global installs.

## 4. Implementation

- Prefer the harness's permission config over a wrapper: allow and deny lists in `opencode.json` or `.claude/settings.json`.
- Deny rules win over allow rules.
- Destructive commands get `--dry-run` first when the tool supports it.
- Every write outside the fence is a refusal with the attempted path, not a silent skip.

## 5. Recovery

Before any risky step: a branch or `git stash create`, a database snapshot, and the exact command to undo it. If you cannot state the undo command, do not run the command.

## 6. Report

List what was blocked and why. A blocked command is a successful guard, not an error.
