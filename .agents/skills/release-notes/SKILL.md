---
name: release-notes
description: Use to turn commits into user-facing release notes. Groups changes by type, leads with what users can now do, and calls out breaking changes and migrations. Not for PR descriptions (use pr-describe).
---

# Release notes

Users don't care what changed. They care what they can now do.

## Range

```bash
git log --no-merges --format='%h %s' v1.3.0..HEAD
```

Drop `chore`, `test`, `ci`, and internal refactors unless they change behavior.

## Structure

```
## v1.4.0 — 2026-05-14

### Added
- Export any report as CSV from the report header.

### Changed
- Search now matches partial words (`ord` finds "order").

### Fixed
- Saving a draft with an empty title shows a field error instead of failing.

### Breaking
- `GET /v1/users` returns a cursor instead of `page`. Migration below.
```

## Voice

- Lead with the verb in the user's words: "Export any report as CSV", not "CSV export support added".
- One line per item. Link to docs for details.
- Describe observable behavior. "Faster" only with a number.
- No emoji, no exclamation marks, no "we're excited".

## Rules

- Every breaking change has a migration line and a deadline.
- Security fixes are named without publishing the exploit.
- If the release has nothing user-visible, say that in one line. Don't pad.
- Keep `CHANGELOG.md` in Keep-a-Changelog order when the repo has one.
