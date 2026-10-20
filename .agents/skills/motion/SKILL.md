---
name: motion
description: Use when adding animation to a marketing page or app UI — GSAP timelines, ScrollTrigger, Lenis smooth scroll, reduced-motion handling, and cleanup. The code side of visual direction. Not for choosing the aesthetic (use ui-ux).
---

# Motion

Motion explains a state change or a spatial relationship. Anything else is decoration with a performance cost.

## Choose the tool

| Need | Use |
|---|---|
| State transitions, hovers | CSS transitions (150–250ms) |
| Orchestrated page load, timeline | GSAP |
| Scroll-linked, pinned, parallax | GSAP + ScrollTrigger |
| Smooth scroll | Lenis, wired into GSAP's ticker |
| Enter/exit of React components | Motion (framer-motion) |
| Layout reflow (FLIP) | Motion `layout` or GSAP Flip |

Don't ship GSAP for a fade. Don't hand-roll scroll math.

## Rules

- Animate `transform` and `opacity`. Never `top`, `left`, `width`, `height`, or `margin` in a loop.
- One orchestrated load sequence per page, then reveals on section heads only. Not everything.
- Duration 0.5–0.9s for entrances, 0.15–0.25s for interactions. Ease out, never linear.
- Stagger small (0.05–0.1s). A long stagger feels slow, not considered.
- ScrollTrigger: `once: true` for reveals, `invalidateOnRefresh` for responsive timelines.

## Reduced motion

```ts
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
```

Skip the timeline entirely — don't just shorten it. Content must be fully visible with zero JS animation. CSS: `@media (prefers-reduced-motion: reduce) { * { animation-duration: .01ms !important; transition-duration: .01ms !important } }`.

## Cleanup

```ts
const ctx = gsap.context(() => { /* ... */ })
document.fonts.ready.then(() => ScrollTrigger.refresh())
return () => ctx.revert()
```

- `ctx.revert()` on unmount; kill triggers created outside the context.
- Kill Lenis and remove its RAF from `gsap.ticker` on unmount.
- Smooth scroll must not break anchors, focus scrolling, or keyboard paging.

## Verify

Check the Performance panel for layout thrash, test at 360px (mobile stutters first), and confirm the page is fully readable with JS disabled.
