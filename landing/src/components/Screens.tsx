import Reveal from './Reveal'
import { baseUrl } from '../utils/baseUrl'

const plates = [
  {
    src: `${baseUrl}screenshots/library.png`,
    label: 'Library',
    caption: 'Everything you own, the newest read first.',
  },
  {
    src: `${baseUrl}screenshots/reader.png`,
    label: 'Reader',
    caption: 'Page turns, four typefaces, highlights that stay.',
  },
  {
    src: `${baseUrl}screenshots/rsvp.png`,
    label: 'RSVP',
    caption: 'One word at a time, 260 words a minute here.',
  },
]

export default function Screens() {
  return (
    <section id="screens" className="border-b border-rule py-20 md:py-28">
      <div className="mx-auto w-full max-w-[1180px] px-5 md:px-8">
        <Reveal className="md:grid md:grid-cols-[1.05fr_0.95fr] md:items-end md:gap-16">
          <div>
            <p className="meta">03 — Screens</p>
            <h2 className="mt-5 font-display text-[clamp(2.25rem,4.4vw,3.5rem)] leading-[1.04] tracking-[-0.02em]">
              Three screens,
              <br />
              nothing in the way.
            </h2>
          </div>
          <p className="mt-5 max-w-[46ch] text-base leading-relaxed text-muted md:mb-2 md:mt-0">
            Library, reader, RSVP. Settings exist, but you will not need them often.
          </p>
        </Reveal>

        <ul
          aria-label="App screenshots"
          tabIndex={0}
          className="-mx-5 mt-12 flex snap-x snap-mandatory scroll-pl-5 gap-5 overflow-x-auto px-5 pb-4 md:mx-0 md:mt-16 md:grid md:grid-cols-3 md:gap-8 md:overflow-visible md:px-0 md:pb-0"
        >
          {plates.map((plate, i) => (
            <li
              key={plate.label}
              className={`w-[72vw] shrink-0 snap-start sm:w-[44vw] md:w-auto ${
                i === 1 ? 'md:mt-14' : ''
              }`}
            >
              <Reveal delay={i * 0.08}>
                <figure className="mx-auto max-w-[300px]">
                  <div className="overflow-hidden">
                    <img
                      src={plate.src}
                      alt={`Ember ${plate.label} screen`}
                      width={634}
                      height={1328}
                      loading="lazy"
                      decoding="async"
                      className="h-auto w-full"
                    />
                  </div>
                  <figcaption className="mt-4 border-t border-rule pt-3">
                    <span className="meta text-ember">Fig. 0{i + 1}</span>
                    <p className="mt-1.5 text-sm font-medium">{plate.label}</p>
                    <p className="mt-1 text-[0.875rem] leading-relaxed text-muted">{plate.caption}</p>
                  </figcaption>
                </figure>
              </Reveal>
            </li>
          ))}
        </ul>
        <p className="meta mt-2 md:hidden">Swipe for reader and RSVP</p>
      </div>
    </section>
  )
}
