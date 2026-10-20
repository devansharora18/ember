# TODO

Nothing is blocked. Everything in the redesign builds, lints and was verified in a headless Chrome
session.

Before shipping, worth doing on a machine with a display:

```bash
cd landing
npm install
npm run dev      # open http://localhost:5173/ember/
npm run build
npm run preview  # open http://localhost:4173/ember/
```

- Check the RSVP demo pacing on a real phone (iOS Safari / Android Chrome).
- Confirm the GitHub Pages deploy picks up the new assets after merging to `main`.
- Optional: replace the 386×389 `favicon.png` with a 512×512 icon for sharper browser tabs.
