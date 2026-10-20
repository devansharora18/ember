---
name: design-critique
description: Use to review a screenshot or live URL and return a prioritized fix list — hierarchy, typography, spacing, color, states, accessibility. Critique only, not implementation. Not for choosing the visual direction (use ui-ux), extracting tokens (use design-system), or viewport breakage (use responsive-audit).
---

# Design critique

Judge the screen against its job, not against taste.

## 1. Name the job

Before looking: what is the one action this screen drives, and for whom? Without that, "better" is meaningless.

## 2. Look in this order

1. **Hierarchy** — squint. Can you see the purpose and the primary action in two seconds? If three things compete, that is finding #1.
2. **Type** — is there a real scale (five or six sizes) or seven near-identical ones? Is body copy 45–75 characters? Are headings tracked tight and leaded 1.1–1.3?
3. **Spacing** — is it on a 4 or 8 scale, and does related content sit closer than unrelated content? Uneven section rhythm is the usual culprit.
4. **Color** — one accent used sparingly, semantic tokens, AA contrast (4.5:1 body, 3:1 large and UI). Check it, don't eyeball it.
5. **States** — default, hover, focus, active, disabled, loading, empty, error. A missing empty or error state is a blocker.
6. **Accessibility** — keyboard order, visible focus, labels bound to inputs, alt text, reduced motion.

## 3. Evidence

Screenshot at 360, 768, and 1440. Crop the actual problem area. Cite values, not adjectives: "16px gap between label and input, 40px to the next group" beats "spacing feels off".

## 4. Output

```
Verdict: ship | fix first

Blocker
1. [Checkout] Primary CTA has the same weight as "Cancel" — no hierarchy.
   Fix: one filled button; the other becomes a text link.

High
2. [Hero] Body copy runs 92ch at 1440 — cap at 65ch.

Keep
- The monochrome palette and single ember accent work; do not add a third color.
```

Always include what works and must survive the fix. A critique that only subtracts produces beige.

## Rules

- No redesign proposals. Point at the defect and the smallest fix.
- Do not critique copy tone unless asked; flag factual or UX copy problems only.
- If the screenshot is too small to judge, ask for a crop instead of inventing findings.
