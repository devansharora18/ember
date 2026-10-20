# Decisions

- **Sepia Press theme.** Chosen after previewing four directions (warm dark, cool dark, cobalt,
  sepia). Aged parchment, brown-black ink, one oxblood accent, Fraunces display over Lora prose.
  It reads as a book without becoming a costume; the black phone plates still carry the product.
- **Serif body copy is intentional.** Lora at 16px replaces the previous sans to make the page feel
  printed. Small labels and numbers stay in JetBrains Mono for legibility and contrast.
- **Dark mode is espresso, not a second look.** The remap keeps the same warm identity at night:
  `#1A1410` background, cream text, terracotta accent, all above AA.
- **The live RSVP demo is the hero.** It is the product's differentiator, so it runs on real timing
  instead of being a scroll animation. Words, punctuation pauses and WPM come from the app's rules
  (base `60000 / wpm`, longer pauses after punctuation).
- **50–600 wpm everywhere.** The README says 50–400, but `reader_rsvp_screen.dart` clamps to 600.
- **"Four screens" was dropped** in favour of naming library, reader, speed reading and stats, so the
  copy cannot drift from the app.
- **Dark mode is a token remap**, not a second design. The app ships dark/light, so the site follows
  `prefers-color-scheme` and reports the matching `theme-color`.
- **No third-party component libraries.** The few primitives needed (slider, buttons) are a hundred
  lines of CSS, cheaper than pulling in a UI kit and restyling it.
- **The 500vh scroll hero was removed.** It delayed the value proposition and fought Lenis; a static
  hero plus the working demo communicates faster.
- **No version numbers or star counts** on the page; they go stale and could not be verified.
- **APK size is "79 MB"** (decimal, matching the 78,951,435-byte file in `public/`).
- **Dictionary lookups leave the device**, so the privacy claim is "library on your device", not
  "nothing ever leaves your phone".
- **The screenshot gallery is a tab stop on mobile** because it scrolls horizontally; it is labelled
  so screen readers announce the list.
