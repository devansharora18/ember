---
name: design-system
description: Use when screens have drifted apart — inconsistent spacing, colors, one-off components — and need tokens and primitives extracted into one source of truth. Not for choosing a visual direction (use ui-ux) or critiquing a screen (use design-critique).
---

# Design system

Extract what exists. Do not invent a system on top of a UI nobody uses yet.

## 1. Audit

Screenshot every distinct screen. Then inventory by frequency:

- colors (hex values sorted by count, not by taste)
- font sizes, weights, line heights
- spacing values, radii, shadows, borders
- button, input, and card variants that differ only slightly

The top eight of each is the system. The tail is mapped or deleted.

## 2. Tokens

CSS variables at `:root`, remapped in `.dark` — never per-component hex.

```css
:root {
  --bg: 250 250 249;
  --fg: 24 24 27;
  --muted: 113 113 122;
  --border: 228 228 231;
  --accent: 194 65 12;
  --radius: 6px;
  --space-1: 4px; --space-2: 8px; --space-4: 16px; --space-6: 24px;
}
```

Names describe role (`border`, `muted`), not color (`gray-200`). The scale is 4- or 8-based; no arbitrary 13px.

## 3. Primitives

Build only what repeats at least three times: Button, Input, Field, Card, Dialog, Badge. One file each, typed props, every state implemented (default, hover, focus-visible, active, disabled, loading, error).

## 4. Migrate

- One screen per commit, with a visual before and after.
- Replace, then delete the old class or component in the same commit.
- No new variants during migration. Log requests for later.

## 5. Govern

- Tokens are the only source of color and spacing. A raw hex in a component fails review.
- Adding a primitive requires two existing usages.
- Document one page: tokens, primitives, do and don't. Screenshots, not prose.

## Done when

A new screen can be built without introducing a single new color, font size, or spacing value.
