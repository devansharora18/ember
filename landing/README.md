# Ember landing page

The marketing site for [Ember](https://github.com/devansharora18/ember), a free EPUB reader for
Android with RSVP speed reading. React + TypeScript + Vite, styled with Tailwind CSS v4.

## Run it

```bash
npm install
npm run dev      # http://localhost:5173/ember/
npm run build    # type-check + production build into dist/
npm run preview  # serve dist/ at http://localhost:4173/ember/
npm run lint     # oxlint
```

The Vite base path is `/ember/`, matching the GitHub Pages URL. Local links use
`import.meta.env.BASE_URL` through `src/utils/baseUrl.ts`, so keep that in mind instead of
hardcoding `/ember/`.

## Structure

```
src/
  App.tsx                    page composition
  index.css                  design tokens, base styles, slider + grain
  components/
    Hero.tsx                 headline, calls to action, spec strip
    RsvpDemo.tsx             live RSVP reader (the hero instrument)
    FeatureIndex.tsx         numbered feature list
    SpeedSection.tsx         how ORP/RSVP works + alignment figure
    Screens.tsx              screenshot plates (scroll-snap gallery on mobile)
    Download.tsx             Play Store, APK, web app, colophon
    Navbar.tsx / Footer.tsx  navigation and footer
    Reveal.tsx               one scroll reveal, disabled for reduced motion
  hooks/useLenis.ts          smooth scrolling, skipped under reduced motion
public/
  ember.apk, icon.png, favicon.png, privacy.html, feedback.html, screenshots/
```

## Design rules

- Warm paper background, ink text, one ember accent. Colours are CSS variables in `src/index.css`
  and flip automatically under `prefers-color-scheme: dark`.
- Instrument Serif for display, Instrument Sans for body, JetBrains Mono for labels and numbers.
- Hairline rules instead of cards; square buttons; no decorative gradients.
- Motion: the hero demo, one load sequence, and scroll reveals on section headers. Everything is
  disabled or paused when the visitor asks for reduced motion.

## Deploy

Pushing to `main` with changes under `landing/` triggers
`.github/workflows/deploy-landing.yml`, which builds the site and publishes `dist/` to GitHub Pages.
