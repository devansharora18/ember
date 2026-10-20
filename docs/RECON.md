# Landing page recon

## What existed

- `landing/` — React 19 + TypeScript + Vite 8 site, Tailwind CSS v4, framer-motion 12, Lenis 1.3.
- Entry: `src/App.tsx` → `Navbar`, `Phone3D`, features, screenshots, install, footer.
- `Phone3D` was a 500–800vh scroll-jacked hero: a sticky phone that cross-faded from the app icon
  to a fake RSVP word stream driven by `useLenisScroll`.
- Palette: pure black with `orange-500`, headings in Outfit, body in Work Sans.
- Build output is served from `/ember/` on GitHub Pages; deploy workflow builds `landing/`.
- Assets: three 634×1328 phone screenshots (RGBA), app icon, 79 MB APK, `privacy.html`,
  `feedback.html`.

## Baseline

- `npm run build` passed with one CSS warning: the Google Fonts `@import` came after other rules.
- `npm run lint` passed.
- No tests.

## Problems with the old page

- Generic dark SaaS look: identical three-column feature cards, centred section headers, orange
  gradient glow — indistinguishable from other indie app sites.
- The hero hid the product behind ~8 screens of scroll; the RSVP demo was fake and abstract.
- Fonts loaded through a render-blocking CSS import.
- Lenis was always on, ignoring `prefers-reduced-motion`.

## Constraints for the redesign

- Keep the existing stack, base path, screenshots, APK and secondary pages.
- Copy must match the app: RSVP range is 50–600 wpm (`_maxWpm = 600`), four reader fonts
  (Inter, Lora, Merriweather, Space Mono), light/dark reader themes, dictionary, stats, export.
- No account system, no analytics, GPLv3.
- Must work at 360/768/1440, keyboard-only, and with reduced motion.
