---
name: cost
description: Use when cloud or infrastructure spend needs cutting — inventory resources, attribute cost, find the expensive few, rightsize, and report savings with risk. Not for capacity planning before traffic exists.
---

# Cost

Spend is usually a handful of resources, not a hundred. Find them before optimizing anything small.

## 1. Inventory with prices

```bash
aws ce get-cost-and-usage --granularity DAILY --metrics UnblendedCost \
  --time-period Start=2026-04-01,End=2026-05-01 \
  --group-by Type=DIMENSION,Key=SERVICE
```

Or the provider's cost explorer exported to CSV. Group by service, then by resource or tag. If there are no tags, that is finding #1.

## 2. Attribute

Map the top ten line items to an owner and a workload. Untagged spend is either shared infra or waste — determine which.

## 3. The usual suspects

| Item | Check | Typical fix |
|---|---|---|
| Compute | average CPU under 15%, idle instances | rightsize, schedule off-hours, autoscale |
| Managed DB | oversized instance, unused replicas, long retention | downsize, drop replica, tune backups |
| Storage | orphaned volumes and snapshots, no lifecycle | delete unattached, lifecycle to cold |
| Egress | cross-AZ chatter, CDN bypass | co-locate, cache, compress |
| Logs | debug level in prod, infinite retention | level plus 14–30 day retention |
| Idle | dev and staging running 24/7 | schedule, ephemeral environments |
| Licenses | per-seat tools with inactive users | reclaim seats quarterly |

## 4. Act in risk order

1. Delete orphans — no risk, immediate.
2. Schedule non-production — low risk.
3. Rightsize — medium; needs a load check.
4. Architecture changes — high; needs a plan and a rollback.

Never delete a resource you cannot prove is unused. Tag it, check traffic, wait a week.

## 5. Report

```
Current: $4,210/mo
Quick wins (this week): $610/mo — orphaned EBS (12 volumes), staging off-hours
Next (30 days): $900/mo — DB rightsize after p95 check
Rejected: reserved instances — commitment exceeds runway
Guardrail: budget alert at 120% of forecast, tag enforcement in CI
```

Savings without a guardrail come back in three months.
