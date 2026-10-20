import { motion, useReducedMotion } from 'framer-motion'
import RsvpDemo from './RsvpDemo'

const PLAY_URL = 'https://play.google.com/store/apps/details?id=in.devansharora.ember'
const WEB_URL = 'https://ember.devansharora.in'

const specs = ['EPUB 2 & 3', '50–600 wpm', 'Offline library', 'No account', 'GPLv3']

export default function Hero() {
  const reduce = useReducedMotion()
  const rise = (delay: number) => ({
    initial: reduce ? false : { opacity: 0, y: 22 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.7, delay, ease: [0.22, 1, 0.36, 1] as const },
  })

  return (
    <section id="top" className="pt-28 md:pt-36">
      <div className="mx-auto grid w-full max-w-[1180px] items-center gap-14 px-5 pb-16 md:px-8 md:pb-24 lg:grid-cols-[1.04fr_0.96fr] lg:gap-16">
        <div>
          <motion.p {...rise(0)} className="meta flex items-center gap-3">
            <span aria-hidden="true" className="h-px w-8 bg-ember" />
            EPUB reader for Android
          </motion.p>

          <motion.h1
            {...rise(0.08)}
            className="mt-6 font-display text-[clamp(3rem,7.4vw,5.5rem)] leading-[0.94] tracking-[-0.02em]"
          >
            One word.
            <br />
            Then the <span className="italic text-ember">next</span>.
          </motion.h1>

          <motion.p {...rise(0.16)} className="mt-6 max-w-[46ch] text-[1.0625rem] leading-relaxed text-muted">
            Ember is a full EPUB reader with a speed-reading mode that shows one word at a time, up to
            600 words a minute. Library, highlights, dictionary and stats, in one small app.
          </motion.p>

          <motion.div {...rise(0.24)} className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
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
              href={WEB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex h-12 items-center justify-center gap-2 border border-rule px-5 text-sm font-medium text-ink transition-colors duration-200 hover:border-ink"
            >
              Try the web app
              <svg aria-hidden="true" className="h-3.5 w-3.5" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth={1.4}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 11.5 11.5 4.5M5.5 4.5h6v6" />
              </svg>
            </a>
          </motion.div>

          <motion.p {...rise(0.3)} className="meta mt-5 normal-case tracking-normal">
            Free · No account · Works offline
          </motion.p>
        </div>

        <motion.div
          initial={reduce ? false : { opacity: 0, y: 28 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
          className="w-full max-w-[420px] justify-self-center lg:justify-self-end"
        >
          <RsvpDemo />
        </motion.div>
      </div>

      <div className="border-y border-rule bg-paper-deep">
        <ul className="mx-auto grid w-full max-w-[1180px] grid-cols-2 gap-x-6 gap-y-2 px-5 py-4 md:flex md:flex-nowrap md:items-center md:justify-between md:px-8">
          {specs.map((spec) => (
            <li key={spec} className="meta whitespace-nowrap max-md:last:hidden">
              {spec}
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
