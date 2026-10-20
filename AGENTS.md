# AGENTS.md

## Process

- Default to **agile**: short iterate-and-adjust loops, for ~90% of work (85% is also fine — err toward this whenever requirements might shift).
- Use **waterfall** (requirements → design → implementation → test → review, in order, no skipping ahead) only for the ~10–15% of work that is well-defined upfront and benefits from locking scope before touching code — e.g. schema/migration changes, public API contracts, security-sensitive flows. State explicitly when switching modes and why.
- **No big-bang changes.** Every task is broken into the smallest reasonable steps (roughly 5–10% of the total work per step).
- After finishing one step, **stop**. Summarize what changed, then ask for approval before starting the next step. Do not chain multiple steps into one response.
- Treat each step like a single commit: one logical change, one clear message, easy to review or revert on its own. Suggested format:
  ```
  step 3/12: add auth middleware
  - validates JWT on protected routes
  - returns 401 on missing/expired token
  ```
- If a step turns out to be bigger than expected, split it further and say so instead of pushing through.
- **`/snap` is one-shot and non-sticky:** it applies only when the current message literally starts with `/snap` and expires immediately after that task. The next prompt reverts to this incremental process unless it also starts with `/snap`.

## Code

- Write the least code needed to solve the problem. No speculative abstractions, no unused config, no "just in case" flexibility.
- Comment only where the *why* isn't obvious from the code itself. No comments that restate what the line already says.
- No filler, no boilerplate scaffolding "for completeness," no AI-generated-feeling padding (no restating the obvious, no over-explaining, no unnecessary try/catch or defensive code for cases that can't happen here).
- Prefer editing existing files/functions over adding new ones unless a new file is genuinely warranted.
- Match the existing style of the codebase (naming, formatting, patterns) rather than introducing a new convention per step.

## Skills

Use this file for workflow/process rules. Use the relevant `.agents/skills/<name>/SKILL.md` for domain-specific technique — check its `description` frontmatter, but as a quick directory:

### Modes

| Skill | Use when |
|---|---|
| `snap` | **Only** when the *current* message starts with literal `/snap`. One-shot, non-sticky — never carries to the next prompt. Suspends the incremental workflow for one task only; standards still apply. |
| `autopilot` | **Only** when the *current* message starts with literal `/autopilot`. One-shot, non-sticky — never carries to the next prompt. Finishes the task end to end with no check-ins: recon, build, tests, hardening, docs, one commit per change. Suspends the incremental workflow for one task only; the `Code` rules and other skills still apply. |

### Core

| Skill | Use when |
|---|---|
| `architecture` | Starting a new project/module, or restructuring — folder structure, layering, file-size discipline. |
| `ui-ux` | Designing or reviewing any UI — visual direction, typography, spacing, color tokens, states, accessibility. |
| `frontend` | Writing frontend code — Vite/Next.js, TypeScript, Tailwind, component and state conventions. |
| `backend` | Writing server/API/DB code — stack evaluation, Postgres + FastAPI, security. |
| `docs` | Documentation — informal understanding or formal backend/architecture docs. Markdown first. |
| `pdf` | Generating a PDF from scratch in Python. Not for reading or merging PDFs. |

### Review and verification

| Skill | Use when |
|---|---|
| `review` | Reviewing a diff, branch, or PR before merge — bugs, security, tests, structure, by severity. |
| `investigate` | Something is broken and the cause is unknown — reproduce, confirm, minimal fix, regression test. |
| `qa` | Exercising the running app end to end — click the flows, log bugs, fix, add tests. |
| `verify` | Proving a finished change works with commands and real output. Never "done" from reading code. |
| `second-opinion` | A plan or diff is expensive to get wrong and needs a cold read from a fresh agent. |

### Planning

| Skill | Use when |
|---|---|
| `plan-review` | Challenging a plan before building — scope, architecture, edge cases, failure modes, tests. Go/no-go. |
| `scope-cut` | Cutting a plan to the smallest shippable version, with a cut list and a later list. |
| `prd` | Turning a one-liner into a PRD — users, scope, non-goals, metrics, acceptance criteria. |
| `spec` | Fixing an API contract or schema before code — endpoints, types, errors, examples. |
| `competitor-teardown` | Researching 3–5 comparable products for gaps and differentiation. |
| `adr` | Recording a costly-to-reverse decision in `docs/adr/`. |

### Workflow and safety

| Skill | Use when |
|---|---|
| `guard` | An agent runs unattended — block destructive commands, confine edits to a directory. |
| `commit` | Turning a messy tree into logical one-line commits without rewriting pushed history. |
| `pr-describe` | Writing a PR body from the diff — summary, risks, test plan. |
| `release-notes` | Turning commits into user-facing release notes. |
| `rollback` | Shipping anything irreversible — define and test the way back first. |
| `handoff` | Ending a session — state, decisions, open items, exact next command. |
| `memory-notes` | Maintaining `docs/PROJECT.md` — conventions, gotchas, decisions. |
| `scratch` | A throwaway, timeboxed prototype that answers one question. |

### Hygiene

| Skill | Use when |
|---|---|
| `refactor` | Behavior-preserving changes only — tests first, tiny commits. |
| `dead-code` | Removing unused files, exports, dependencies, or flags with proof. |
| `skill-audit` | Auditing SKILL.md files for overlapping triggers, conflicts, and bloat. |

### Frontend and design

| Skill | Use when |
|---|---|
| `design-system` | Extracting tokens and primitives from drifted screens into one source of truth. |
| `design-critique` | Reviewing a screenshot or URL for a prioritized fix list. |
| `motion` | GSAP, ScrollTrigger, Lenis, reduced motion, cleanup. |
| `seo-meta` | Titles, OG cards, sitemap, structured data, Core Web Vitals. |
| `responsive-audit` | Checking 360/768/1440 — overflow, touch targets, safe areas. |

### Backend and data

| Skill | Use when |
|---|---|
| `db-design` | Designing a schema — keys, constraints, indexes, migrations, query plans. |
| `api-review` | Reviewing endpoints for auth, validation, pagination, idempotency, errors. |
| `cost` | Finding and cutting expensive cloud or infra spend. |
| `observability` | Health checks, metrics, alerts, and dashboards. |

### Teaching

| Skill | Use when |
|---|---|
| `explain` | Teaching what was built, at the user's level — learning, interviews, onboarding. |

Apply skills together when a task spans domains (e.g. a new feature touches `architecture` + `frontend` + `backend`) rather than picking just one. Under `/autopilot`, apply the domain skills the same way inside its steps.