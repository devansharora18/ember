import Reveal from './Reveal'

const claims = [
  {
    title: 'Anchored',
    body: 'Every word aligns on its optimal recognition point, so the focal letter never shifts between words.',
  },
  {
    title: 'Paced',
    body: 'One slider, 50 to 600 words a minute. Change the pace mid-sentence without losing your place.',
  },
  {
    title: 'Punctuated',
    body: 'Commas get a beat, full stops get two. Sentences still land the way they were written.',
  },
]

const WORD = 'recognition'
const FOCAL = 3

export default function SpeedSection() {
  return (
    <section id="speed" className="border-b border-rule bg-paper-deep py-20 md:py-28">
      <div className="mx-auto w-full max-w-[1180px] px-5 md:px-8">
        <div className="grid gap-12 lg:grid-cols-[1fr_0.85fr] lg:items-start lg:gap-16">
          <div>
            <Reveal>
              <p className="meta">02 — Speed</p>
              <h2 className="mt-5 max-w-[18ch] font-display text-[clamp(2.25rem,4.4vw,3.5rem)] leading-[1.04] tracking-[-0.02em]">
                Your eye stays. The words move.
              </h2>
              <p className="mt-5 max-w-[52ch] text-[0.9375rem] leading-relaxed text-muted">
                Most reading time is spent sweeping your eyes along a line. RSVP — rapid serial visual
                presentation — removes the sweep: one word, pinned to one point, at the pace you choose.
              </p>
            </Reveal>

            <dl className="mt-10">
              {claims.map((claim, i) => (
                <Reveal
                  key={claim.title}
                  delay={i * 0.06}
                  className="grid gap-1 border-t border-rule py-4 sm:grid-cols-[8rem_1fr] sm:gap-6"
                >
                  <dt className="text-[0.9375rem] font-medium">{claim.title}</dt>
                  <dd className="max-w-[48ch] text-sm leading-relaxed text-muted">{claim.body}</dd>
                </Reveal>
              ))}
            </dl>
          </div>

          <Reveal delay={0.1} className="lg:sticky lg:top-24">
            <figure className="border border-rule bg-paper">
              <div className="flex items-center justify-between border-b border-rule px-5 py-3">
                <span className="meta">Optimal recognition point</span>
                <span className="meta normal-case tracking-normal">1 word</span>
              </div>

              <div className="relative flex items-center justify-center overflow-hidden py-14">
                <div aria-hidden="true" className="absolute inset-y-4 left-1/2 w-px -translate-x-1/2 bg-ember/60" />
                <div
                  aria-hidden="true"
                  className="relative z-10 grid w-full grid-cols-[1fr_auto_1fr] items-baseline bg-paper px-3 font-display text-[clamp(2.25rem,6vw,3.5rem)] leading-none tracking-[-0.01em]"
                >
                  <span className="justify-self-end">{WORD.slice(0, FOCAL)}</span>
                  <span className="text-ember">{WORD.charAt(FOCAL)}</span>
                  <span className="justify-self-start">{WORD.slice(FOCAL + 1)}</span>
                </div>
              </div>

              <figcaption className="border-t border-rule px-5 py-4 text-[0.75rem] leading-relaxed text-muted">
                The placement is fixed for every word. Your eye reads; it does not hunt.
              </figcaption>
            </figure>
          </Reveal>
        </div>
      </div>
    </section>
  )
}
