---
name: rollback
description: Use before shipping anything irreversible — deploys, migrations, data backfills, feature flags. Defines and tests the way back, with criteria for taking it.
---

# Rollback

If you can't undo it, you're not ready to do it.

## 1. Name the failure

What does "this went wrong" look like, measurably? Error rate > 2%, p95 > 800ms, no orders for five minutes, a wrong number in a report. Write the threshold before deploy.

## 2. Pick the mechanism

| Change | Way back |
|---|---|
| Stateless app deploy | redeploy the previous image by digest |
| Config or flag | flip the flag; keep the old path until the new one is proven |
| Additive migration | leave the column; ship the reader behind a flag |
| Destructive migration | expand → migrate → contract, contract only after the old reader is gone |
| Data backfill | idempotent script plus a verified snapshot; rollback is a restore, not an inverse script |
| Third-party integration | kill switch, queue drain, replay from the log |

Never let "restore the backup" be the only plan for a schema change you could have made reversible.

## 3. Test the path before you need it

- Deploy the previous version in staging and confirm the app works against the new schema.
- Run the down migration on a copy with production-shaped data.
- Time it. A 40-minute rollback is an outage, not a rollback.

## 4. Write the runbook

```
Trigger: <threshold>
First 5 min: page owner, flip <flag>, post in #incidents
Rollback: <exact command or dashboard button>
Verify: <query or check that proves normal>
Data: <what happened to writes in the window, how reconciled>
```

## Rules

- Rollback is a decision with an owner, not a hope.
- A forward fix is legitimate only when it is faster and safer, and that is written down in advance.
- After any rollback, add the missing test or check that would have caught it.
