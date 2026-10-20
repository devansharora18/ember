---
name: commit
description: Use to turn a messy working tree into logical commits without rewriting pushed history. Groups by intent, stages hunks, writes one-line messages. Not for writing PR descriptions (use pr-describe) or release notes (use release-notes).
---

# Commit

History is read far more often than it is written.

## 1. Survey

```bash
git status --short
git diff --stat
git log --oneline -10        # match the project's message style
```

Never commit files you did not intend: lockfile churn from an unrelated install, build artifacts, `.env`.

## 2. Group by intent, not by file

A commit answers one question: why did this change? Typical groups are the feature, its test, the migration, the doc, and the drive-by fix. If two groups need different sentences, they are two commits.

## 3. Stage hunks

```bash
git add -p
git diff --cached          # read it before writing the message
```

Do not use `git add .` unless the tree contains exactly one intent.

## 4. Message

```
<type>: <lowercase imperative summary, <= 72 chars>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`. One line, no body unless the *why* is genuinely non-obvious. No attribution, no emoji, no "update files".

Name the behavior: `fix: reject expired reset tokens`, not `fix: auth bug`.

## 5. Verify

```bash
git status                      # clean
git log --oneline -n <count>    # reads as a changelog
git show --stat HEAD
```

Run the tests after the final commit, not only before the first. The tree that matters is the one you leave.

## Hard rules

- Never rewrite pushed history (`rebase -i`, `commit --amend`) on a shared branch.
- Never squash someone else's commits.
- Never commit secrets, even briefly. If one lands, rotate it and say so.
- One commit per logical change. If the message needs "and", split it.
