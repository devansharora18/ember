---
name: ui-ux
description: Use when designing or reviewing any UI: new screens, components, layouts, landing pages, or visual polish passes. Uses the Vercel-style minimal theme only when the user asks for it. In every other case, including unclear ones, research references (Dribbble, Pinterest) first, then build with GSAP/Lenis and curated component libraries.
---

# UI/UX

## Mode selection (decide first)

**Default mode: Vercel-style minimal.** Use it ONLY when the user explicitly asks for it: "default style", "Vercel style", "minimal", "clean", "keep it simple", "no research", or similar.
- Do NOT research references. Do NOT browse Dribbble/Pinterest. Go straight to the brief and build.
- Follow "Default aesthetic" below.

**Custom mode: research first.** Use it in every other case, including when it's unclear which mode applies. Don't ask, just use custom mode.
- Typical triggers: a named style (editorial brutalist, retro-futurist, glassmorphism, etc.), a vibe, a brand, a reference site or screenshot, "bolder", "redesign it", or simply no style specified.
- Do the full research step below before designing.
- If the user supplies their own references (screenshots, links), use those as the primary source and research only to fill gaps.

## Process

1. **Research (custom mode only):** collect 3-5 references for the type of screen being built.
   - Search Dribbble and Pinterest (and Awwwards, Mobbin, Godly, Land-book if useful) with specific queries, e.g. "dark developer tool landing page", "editorial portfolio", "brutalist ecommerce".
   - Use WebSearch/WebFetch or the browser tools. Pinterest often needs a login and may block fetching. If a source is blocked, say so and ask the user for screenshots or links instead of guessing.
   - Extract patterns, not pixels: layout structure, type pairing, spacing rhythm, color, motion behavior. Never copy a design, assets, or branding. Reinterpret.
2. **Design brief (max 10 lines), then commit to it:**
   - Purpose and the one action the screen must drive
   - Aesthetic direction: Vercel-style minimal (default mode) or the direction chosen from research/user request (custom mode)
   - Custom mode only: references used and what was taken from each
   - One signature element: a hero treatment, an unusual layout, or a precise interaction that makes it memorable. In minimal work this is usually typography, spacing, or one well-crafted detail.
3. Build complete, working code. Nothing stubbed. Realistic content and data.
4. Run the anti-slop and review checklists before calling it done. Reject your own output if it fails.

## Default aesthetic: minimal, Vercel-style

- Neutral base (black/white/gray), one sharp accent used sparingly.
- Generous whitespace over density. When in doubt, remove an element rather than add one.
- Typography does the work most decoration would. Dramatic size contrast, not timid.
- Borders (hairline) over shadows for separation. Shadow only for true elevation (modals, popovers, dropdowns).
- Minimal does not mean generic. It needs a point of view: a precise grid, a striking type pairing, a confident empty space, a considered detail.
- Atmosphere is allowed when subtle: faint grain, a barely-there gradient or grid pattern. No decorative gradient blobs.
- Default mode motion and components stay restrained: CSS transitions for state changes, shadcn/ui-style primitives, at most one subtle statement effect.
- **Never use emojis in UI.** Use proper vector icons.

## Typography

- Pick a distinctive font from Google Fonts or a considered stack (e.g. Geist, Instrument Sans, Space Grotesk, Fraunces, JetBrains Mono). **Never Inter, Roboto, Arial, or bare system defaults** as the design choice.
- Default: one family for everything. Add a second (display + body, or monospace for code) only for a real distinction.
- Type scale: ~5-6 sizes, reused everywhere (e.g. 12/14/16/20/28/40). Fluid with `clamp()` for headlines on marketing pages.
- Line height 1.4-1.6 body, 1.1-1.3 large headings. Tight tracking on headlines.
- Weight does more work than color: prefer 400/500/600.

## Spacing & layout

- 4px or 8px spacing scale, never arbitrary pixel values. Consistent radii and border treatment.
- Align to a grid with consistent gutters and margins across breakpoints.
- Max readable width ~65-75 characters for body copy.
- Break the grid on purpose (asymmetry, overlap, large negative space, dense editorial columns) when it serves the direction. Not three identical cards in a row. Vary section rhythm.
- Mobile first. Verify 360px, 768px, 1440px.

## Color

- Semantic tokens as CSS variables (background, foreground, muted, border, accent, destructive). No hardcoded hex in components.
- 1 dominant, 1 sharp accent, neutrals. No purple-to-blue gradients on white. No rainbow.
- WCAG AA contrast (4.5:1 body, 3:1 large text/UI components). Check it, don't eyeball it.
- Dark mode is a token remap, not a separate design. Support `prefers-color-scheme` where it fits.

## Depth & detail

- Hairline borders, custom focus rings, custom `::selection` color, styled scrollbar.
- Layered shadows only for true elevation.
- Generate SVG or CSS art instead of broken image links.

## Motion

- **Default mode / app UI:** subtle and fast (150-250ms), only to clarify state. `cubic-bezier` easing, never linear. CSS-first.
- **Custom mode, or marketing/landing/portfolio pages where the direction calls for it:** use real motion libraries.
  - **GSAP** (+ ScrollTrigger) for orchestrated load sequences, staggered reveals, scroll-linked and pinned sections, text splitting, timelines.
  - **Lenis** for smooth scrolling, wired into GSAP's ticker so ScrollTrigger stays in sync (`lenis.on('scroll', ScrollTrigger.update)`, drive `lenis.raf` from `gsap.ticker`).
  - **Motion (framer-motion)** for React layout/presence/gesture animation when the project is React.
- One orchestrated page-load sequence, then scroll reveals on key elements only. Never animate everything.
- Animate `transform` and `opacity` only. No layout-thrashing properties.
- Always respect `prefers-reduced-motion`: disable Lenis smoothing and skip or shorten GSAP timelines. Clean up ScrollTriggers and Lenis on unmount.
- Smooth scroll must never break anchor links, keyboard scrolling, or focus behavior.

## Component libraries

- Default mode: shadcn/ui primitives, restyled to the minimal tokens. Reach for other libraries only if a component is genuinely needed.
- Custom mode: draw from **React Bits**, **Aceternity UI**, **Magic UI**, and **shadcn/ui** (also Origin UI, Cult UI, HeroUI where they fit) instead of hand-rolling complex effects: text animations, backgrounds, spotlight/beam effects, bento grids, marquees, tabs, command menus.
- Pick components that serve the brief. Use one or two statement components per screen at most. A page that is a showcase of effects fails the anti-slop checklist.
- Always restyle to the project's tokens (colors, radii, fonts, spacing). Library defaults must not show through.
- Strip decoration that fights the direction (rainbow glows, heavy gradients, emoji, mixed icon sets).
- Verify every pulled-in component for keyboard access, focus states, contrast, and reduced-motion support. Fix what the library skipped.
- Check each library's current docs for install steps and license before using. Prefer copy-in components over adding heavy dependencies.
- Respect the project's stack: React/Next.js + Tailwind for these libraries. For vanilla HTML deliverables, use GSAP/Lenis via CDN and reimplement the effect rather than forcing React components in.

## Interaction & state

- Every interactive element has visible hover, focus, active, and disabled states.
- Never `outline: none` without a visible replacement.
- Design default/loading/empty/error states up front. A screen isn't done until all four exist.
- Optimistic UI where latency is noticeable. Skeletons over spinners for content-shaped loading.

## Copy (UX writing)

- Real, specific copy. No lorem ipsum, no "Welcome to our platform," no "Revolutionize your workflow."
- Buttons/CTAs: verb + object ("Create project", not "Submit" or "OK").
- Errors say what happened and what to do next.
- Direct tone in system/utility copy. No exclamation-mark marketing voice.
- Realistic placeholder data and numbers.

## Accessibility (non-negotiable)

- Semantic HTML first (`button`, `nav`, `label`) before ARIA.
- Every form input has a real `<label>`.
- Everything keyboard-operable in a logical tab order.
- Meaningful `alt` text, or `alt=""` if purely decorative.
- Motion and smooth scroll never block access to content.

## Iconography

- One icon set for the whole product (e.g. Lucide / `lucide-react`, or inline SVG). No mixing styles, including icons that ship inside pulled-in components.
- Outline, 1.5-2px stroke, 16-20px default. Fill only for active/selected states.
- Meaningful icons get `aria-label`. Decorative icons get `aria-hidden="true"`.
- No emojis for status, decoration, or illustration. Replace with the nearest semantic vector icon.

## Engineering

- Vanilla HTML deliverables: single self-contained file, with only fonts and pinned-version CDN scripts (GSAP, ScrollTrigger, Lenis) as external dependencies.
- React projects: follow the existing structure, install only what is used, tree-shake, and keep bundle impact in mind.
- Commented CSS variables at the top. No inline-style spaghetti.
- Opens and runs with zero console errors.
- Output the full file, ready to paste and run.

## Anti-slop checklist (reject your output if any are true)

- Looks like a default Tailwind or shadcn template
- Centered hero + gradient blob + three feature cards
- Overused fonts (Inter/Roboto/Arial) or purple gradients
- Generic stock-sounding copy
- Every section has the same layout rhythm
- Motion missing, or motion on everything
- Library components left with default styling, or a page that is just a pile of effects
- Copied a reference instead of reinterpreting it
- No signature element

## Review checklist before calling a screen done

- Correct mode used? (Default = only if the user asked for it, no research, Vercel-style. Custom = everything else, references gathered and reflected in the brief.)
- Works at 360px, 768px, and 1440px?
- All 4 states exist (default/loading/empty/error)?
- Every interactive element keyboard-accessible with a visible focus state?
- Contrast checked against AA?
- `prefers-reduced-motion` honored, including Lenis and GSAP?
- Animations only on `transform`/`opacity`, with no jank on scroll?
- Could any element be removed without losing meaning? If yes, remove it.
- Zero emojis? All icons from a single set?
- Could a stranger name the aesthetic direction in 2 seconds?
- Is there one distinctive, intentional signature element?