# Landing redesign plan

1. **Tokens and type** — warm paper/ink palette with one ember accent, light + dark remaps,
   Instrument Serif / Instrument Sans / JetBrains Mono loaded via `<link>`. Remove the old
   black/orange theme and the blocking font import.
2. **Navigation** — sticky hairline bar, scroll-spy active state, skip link, Play Store CTA.
3. **Hero** — editorial headline, one primary action (Google Play), one secondary (web app), and
   the signature element: a working RSVP reader with a real WPM control, punctuation timing and an
   ORP registration line.
4. **Feature index** — numbered hairline rows instead of cards, copy taken from the app code.
5. **Speed section** — explain ORP with a labelled alignment figure.
6. **Screens** — the three real screenshots as captioned plates; scroll-snap gallery under `md`.
7. **Download** — Play Store, APK, web app, plus a colophon of factual details.
8. **Cleanup** — delete the scroll-jacked `Phone3D` hero, the unused assets and the Vite boilerplate
   README; honour reduced motion in Lenis and the demo.
9. **Verification** — build + lint, Playwright run at 320/360/414/768/1024/1440/1920, interaction
   and reduced-motion checks, screenshots reviewed in light and dark.
