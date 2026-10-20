---
name: responsive-audit
description: Use to verify a UI at 360, 768, and 1440 — overflow, touch targets, sticky headers, safe areas, and layout breaks — with screenshots as proof. Not for judging visual direction (use design-critique).
---

# Responsive audit

Three widths, real content, screenshots. Not a vibe check.

## Matrix

| Width | Why |
|---|---|
| 360 | smallest common phone; everything that overflows does it here |
| 768 | tablet; the awkward middle where grids break |
| 1440 | desktop; catches over-wide text and stretched layouts |

Add 320 for old Android, 1920 for dashboards.

## Checks

- **Overflow**: `document.documentElement.scrollWidth === clientWidth`. Any horizontal scroll is a bug; find the element with `scrollWidth > clientWidth`.
- **Touch targets**: at least 44×44px with 8px spacing. Icon-only buttons are the usual offender.
- **Headers**: a sticky nav must not cover anchored content — `scroll-padding-top` equal to its height.
- **Text**: body at least 16px, line length 45–75ch, no 10px type as a design choice on mobile.
- **Tables**: a scroll container with a visible affordance, or a stacked layout — never a clipped table.
- **Media**: `max-width: 100%`, no fixed heights, art direction where the crop matters.
- **Safe areas**: `env(safe-area-inset-*)` for fixed bottom bars on iOS.
- **Keyboard on mobile**: a fixed footer must not cover the focused input.
- **Hover-only affordances**: every hover-revealed action needs a tap equivalent.

## Evidence

```bash
npx playwright screenshot --viewport-size=360,800 http://localhost:5199 360.png
```

Capture full-page and the broken region. Note the element and the computed width that overflows.

## Output

```
Blocker
- /checkout at 360: total row overflows 24px (grid-cols-3 with min-content).
  Fix: grid-cols-[1fr_auto], wrap the label.

High
- Nav height 64px; anchors land under it. Fix: scroll-padding-top: 5rem.

Pass
- 768 and 1440 have no overflow; tap targets 48px.
```
