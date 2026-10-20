import Reveal from './Reveal'

const features = [
  {
    title: 'Library',
    body: 'Import any EPUB. Covers with pinch-to-zoom, search, custom artwork, and the book you were reading first.',
  },
  {
    title: 'Reader',
    body: 'Swipe pages, pick from four typefaces, switch light or dark, jump with the table of contents, double-tap a word for its definition.',
  },
  {
    title: 'Speed reading',
    body: '50 to 600 words per minute with the focal letter held still. Punctuation timing, breath pauses, and an auto-pause every few sentences.',
  },
  {
    title: 'Bookmarks',
    body: 'Mark passages as you read. They stay on your device, attached to the place in the book where you left them.',
  },
  {
    title: 'Stats',
    body: 'Words read, daily goal, current and best streak, badges for the long runs, and per-book progress.',
  },
  {
    title: 'Export',
    body: 'One file holds every book, your progress, stats and settings. Restore it on a new phone and pick up mid-sentence.',
  },
]

export default function FeatureIndex() {
  return (
    <section id="reading" className="border-b border-rule py-20 md:py-28">
      <div className="mx-auto w-full max-w-[1180px] px-5 md:px-8">
        <Reveal className="md:grid md:grid-cols-[1.05fr_0.95fr] md:items-end md:gap-16">
          <div>
            <p className="meta">01 — The app</p>
            <h2 className="mt-5 font-display text-[clamp(2.25rem,4.4vw,3.5rem)] leading-[1.04] tracking-[-0.02em]">
              Built like a book,
              <br />
              not a feed.
            </h2>
          </div>
          <p className="mt-5 max-w-[46ch] text-base leading-relaxed text-muted md:mb-2 md:mt-0">
            No store, no recommendations, no account. Library, reader, speed reading and stats — each
            does its job and returns you to the page.
          </p>
        </Reveal>

        <ul className="mt-12 border-t border-rule md:mt-16">
          {features.map((feature, i) => (
            <li
              key={feature.title}
              className="group grid gap-x-8 gap-y-2 border-b border-rule py-6 transition-colors duration-200 hover:bg-paper-deep/60 md:grid-cols-[3.5rem_16rem_1fr] md:items-baseline md:py-7"
            >
              <span className="meta tabular-nums text-ember">
                {String(i + 1).padStart(2, '0')}
              </span>
              <h3 className="font-display text-[1.6rem] leading-tight tracking-[-0.01em] transition-transform duration-200 group-hover:translate-x-1 md:text-[1.75rem]">
                {feature.title}
              </h3>
              <p className="max-w-[58ch] text-base leading-relaxed text-muted">
                {feature.body}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
