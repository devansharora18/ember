import Reveal from './Reveal'
import { baseUrl } from '../utils/baseUrl'

const PLAY_URL = 'https://play.google.com/store/apps/details?id=in.devansharora.ember'
const WEB_URL = 'https://ember.devansharora.in'

const colophon = [
  ['Price', 'Free'],
  ['Licence', 'GPLv3'],
  ['Platforms', 'Android, web'],
  ['Account', 'Not required'],
  ['Library', 'On your device'],
]

export default function Download() {
  return (
    <section id="download" className="py-20 md:py-28">
      <div className="mx-auto grid w-full max-w-[1180px] gap-12 px-5 md:px-8 lg:grid-cols-[1.15fr_0.85fr] lg:items-start lg:gap-20">
        <div>
          <Reveal>
            <p className="meta">04 — Download</p>
            <h2 className="mt-5 font-display text-[clamp(2.75rem,6vw,4.5rem)] leading-[0.98] tracking-[-0.025em]">
              Start with
              <br />
              one <span className="italic text-ember">book</span>.
            </h2>
            <p className="mt-5 max-w-[46ch] text-base leading-relaxed text-muted">
              Free on Android. If you would rather not use Google Play, the APK is here to download,
              and the web app runs in a browser tab.
            </p>
          </Reveal>

          <Reveal delay={0.08} className="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
            <a
              href={PLAY_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-12 items-center justify-center gap-2.5 bg-ink px-5 text-sm font-medium text-paper transition-opacity duration-200 hover:opacity-85"
            >
              <svg aria-hidden="true" className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3.609 1.814 13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92Zm10.89 10.893 2.302 2.302-10.937 6.333 8.635-8.635Zm3.199-3.199 2.807 1.626a1 1 0 0 1 0 1.732l-2.807 1.626L15.206 12l2.492-2.492ZM5.864 2.658 16.8 8.99l-2.302 2.302-8.635-8.634Z" />
              </svg>
              Get it on Google Play
            </a>
            <a
              href={`${baseUrl}ember.apk`}
              download
              className="inline-flex h-12 items-center justify-center gap-2 border border-rule px-5 text-sm font-medium transition-colors duration-200 hover:border-ink"
            >
              Download the APK
              <span className="font-mono text-[0.6875rem] text-muted">79 MB</span>
            </a>
            <a
              href={WEB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-12 items-center gap-1.5 px-1 text-sm text-muted underline decoration-rule underline-offset-4 transition-colors duration-200 hover:text-ink hover:decoration-ember"
            >
              Open the web app
              <svg aria-hidden="true" className="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth={1.4}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 11.5 11.5 4.5M5.5 4.5h6v6" />
              </svg>
            </a>
          </Reveal>
        </div>

        <Reveal delay={0.12}>
          <dl className="border-t border-rule">
            {colophon.map(([term, value]) => (
              <div
                key={term}
                className="flex items-baseline justify-between gap-6 border-b border-rule py-3.5"
              >
                <dt className="meta">{term}</dt>
                <dd className="text-sm">{value}</dd>
              </div>
            ))}
          </dl>
        </Reveal>
      </div>
    </section>
  )
}
