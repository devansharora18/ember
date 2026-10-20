---
name: dead-code
description: Use to find and remove unused files, exports, dependencies, and flags — with proof from grep, the build, and tests before deleting. Not for reorganizing live code (use refactor).
---

# Dead code

Deletion is a feature. Prove it's dead first.

## 1. Inventory

```bash
npx knip          # JS/TS: files, exports, dependencies, unused types
npx depcheck      # dependency-only view
npx ts-prune      # exports without importers
```

No tool? `grep -rn "<symbol>" --include='*.ts' .` plus a build.

## 2. Prove, per candidate

- No importer, not in `package.json` scripts, not referenced by config, not loaded dynamically (`import()`, string-built paths), not used by tests, not part of a public API.
- Build still succeeds after removal in a scratch commit.
- Tests pass.
- For a dependency: remove it and run install, build, and tests from a clean `node_modules`.

## 3. False positives to check

Dynamic imports and globs; reflection or DI containers; framework conventions (`pages/`, `app/`, migrations, seeds); CLI entry points; types consumed by external packages; anything referenced in docs or CI; env-driven feature flags.

## 4. Remove in order

1. Exports and functions — one commit.
2. Files.
3. Dependencies, including the lockfile.
4. Feature flags — only after the old path has been off in production for a full cycle.

## 5. Report

```
Removed:
- src/lib/date.ts — 0 importers, superseded by date-fns in #210
- lodash.get — replaced by optional chaining
Kept (looked dead):
- src/types/legacy.ts — imported by the external SDK
Verification: build ok, 41 tests pass, bundle -12.4 kB
```

Never delete code you don't understand because a tool called it unused. Read it first.
