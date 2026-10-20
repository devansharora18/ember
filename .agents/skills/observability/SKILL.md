---
name: observability
description: Use when a service needs health checks, metrics, alerts, and dashboards — before launch or after an incident — so failures are visible before users report them. Not for debugging a known failure (use investigate).
---

# Observability

If you can't answer "is it working, and why not?" in under a minute, you are not done.

## 1. Signals

- **Requests**: rate, errors, duration (p50/p95/p99) — per route, not just global.
- **Dependencies**: database, cache, queue, third party — latency and error rate.
- **Saturation**: CPU, memory, connections, queue depth, disk.
- **Business**: signups, orders, payments. A green dashboard with zero orders is an outage.

## 2. Logs

Structured JSON, one line per event, with `request_id`, `user_id` (hashed if sensitive), `route`, `status`, `duration_ms`. Never log tokens, passwords, card numbers, or full request bodies.

Levels: `error` means a human must look; `warn` is degraded but handled; `info` is a state change; `debug` is off in production.

## 3. Health

- `/healthz` — process alive, no dependency checks. Fast, for the load balancer.
- `/readyz` — dependencies reachable; used before routing traffic.
- A health check never writes to the database or calls a paid API.

## 4. Alerts worth waking up for

| Alert | Threshold | Why |
|---|---|---|
| 5xx rate | > 2% for 5 min | users failing |
| p95 latency | > 2× baseline for 10 min | degradation |
| Queue age | > 5 min | work not moving |
| Error budget burn | 14× in 1h | SLO at risk |
| Cert or disk expiry | < 7 days | predictable outage |

Every alert names an owner and a runbook link. If nobody would act at 3am, it is a dashboard, not an alert.

## 5. Traces

Spans at service boundaries and on every external call. Propagate `traceparent`. Sample 10% normally, 100% on error.

## 6. Verify

Trigger a failure on purpose — kill a dependency, return 500 from a canary — and confirm the alert fires and the dashboard points at the cause. An untested alert is a rumour.

## Done when

A new engineer can read the dashboard and say whether the service is healthy, and on-call can locate the failing dependency from the alert alone.
