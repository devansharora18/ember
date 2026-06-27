import { useRef, useState } from 'react'
import { motion, useScroll, useTransform, useMotionValueEvent } from 'framer-motion'

const words = ['Introducing', 'the', 'best', 'eReader', 'app', 'for', 'you.']

function orpIndex(length: number) {
  if (length <= 1) return 0
  return Math.min(Math.floor((length - 1) / 3), 4)
}

export default function Phone3D() {
  const ref = useRef<HTMLDivElement>(null)
  const [focal, setFocal] = useState(0)
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start start', 'end end'],
  })

  const portraitOpacity = useTransform(scrollYProgress, [0, 0.1, 0.18], [1, 1, 0])
  const wordProgress = useTransform(scrollYProgress, [0.25, 1], [0, words.length - 1])
  const rsvpOpacity = useTransform(scrollYProgress, [0.2, 0.3], [0, 1])

  useMotionValueEvent(wordProgress, 'change', (v) => setFocal(v))

  const focalIdx = Math.floor(focal)

  const visible = []
  for (let i = focalIdx - 1; i <= focalIdx + 1; i++) {
    if (i < 0 || i >= words.length) continue
    visible.push({ word: words[i], distance: Math.abs(i - focal), index: i })
  }

  const features = [
    { icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253', title: 'Read EPUBs', desc: 'Import any EPUB file. Clean, distraction-free reading with bold and italic formatting.' },
    { icon: 'M13 10V3L4 14h7v7l9-11h-7z', title: 'RSVP Speed Read', desc: 'Read at 300+ WPM with rapid serial visual presentation and focal letter highlighting.' },
    { icon: 'M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z', title: 'Bookmarks & Highlights', desc: 'Mark important passages and highlight text. All saved locally.' },
    { icon: 'M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01', title: 'Customizable', desc: 'Choose fonts, sizes, dark or light mode. Make reading truly yours.' },
    { icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z', title: 'Track Progress', desc: 'See how far you\'ve read. Pick up right where you left off.' },
    { icon: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4', title: 'Export & Backup', desc: 'Export your entire library with books, progress and settings in one file.' },
  ]

  return (
    <section
      ref={ref}
      className="relative h-[800vh] bg-black"
    >
      <div className="sticky top-0 h-screen w-full max-w-7xl mx-auto flex items-center">
        {/* Left — Static content */}
        <div className="w-1/2 pl-8 pr-16">
          <div className="mb-16">
            <h1 className="font-heading text-5xl md:text-6xl font-bold mb-4">
              Read smarter,<br />not harder.
            </h1>
            <p className="text-neutral-400 text-lg leading-relaxed max-w-md">
              Ember is a powerful EPUB reader with speed reading, bookmarks, highlights, and export — all in one beautiful app.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-8">
            {features.map((f) => (
              <div key={f.title} className="group">
                <div className="w-10 h-10 rounded-lg bg-neutral-900 border border-neutral-800 flex items-center justify-center mb-3 group-hover:border-orange-500/40 transition-colors duration-200">
                  <svg className="w-5 h-5 text-orange-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d={f.icon} />
                  </svg>
                </div>
                <h3 className="text-white font-semibold mb-1">{f.title}</h3>
                <p className="text-neutral-500 text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Right — Phone */}
        <div className="w-1/2 flex justify-center relative">
          <div className="relative select-none">
            <div className="w-[300px] h-[610px] rounded-[56px] bg-black p-[6px] shadow-[0_0_0_1px_#333,0_0_120px_rgba(249,115,22,0.1)]">
              <div className="w-full h-full rounded-[50px] bg-black p-[14px] ring-1 ring-white/10">
                <div className="w-full h-full rounded-[37px] bg-black flex items-center justify-center relative">
                  <div className="absolute top-[10px] left-1/2 -translate-x-1/2 w-[10px] h-[10px] bg-[#1a1a1a] rounded-full z-10 ring-1 ring-neutral-800" />

                  <motion.p style={{ opacity: portraitOpacity }} className="absolute text-white text-center px-4">
                    <span className="block text-4xl font-bold font-heading">Ember</span>
                    <span className="block text-sm text-neutral-400 mt-2">EPUB Reader</span>
                  </motion.p>

                  <motion.div
                    style={{ opacity: rsvpOpacity }}
                    className="absolute inset-0 flex items-center justify-center overflow-hidden"
                  >
                    <div className="flex items-center gap-0">
                      {visible.map(({ word, distance, index }) => {
                        const isFocal = index === focalIdx
                        const op = distance > 3 ? 0 : isFocal ? 1 : distance <= 1 ? 0.7 : distance <= 2 ? 0.45 : 0.25
                        const orp = isFocal ? orpIndex(word.length) : 0
                        return (
                          <span
                            key={index}
                            className="inline-flex items-baseline px-[5px]"
                            style={{
                              opacity: op,
                              fontFamily: 'Inter, sans-serif',
                              fontSize: 26,
                              fontWeight: isFocal ? 500 : 400,
                              lineHeight: 1,
                              transition: 'opacity 150ms ease-out',
                            }}
                          >
                            {isFocal && word.length > 1 ? (
                              word.includes('-') ? (
                                word.split('-').map((part, pi) => (
                                  <span key={pi} className="inline-flex">
                                    {pi > 0 && <span style={{ color: 'rgba(255,255,255,0.7)' }}>-</span>}
                                    <OrpSpan word={part} orp={orpIndex(part.length)} />
                                  </span>
                                ))
                              ) : (
                                <OrpSpan word={word} orp={orp} />
                              )
                            ) : (
                              <span style={{ color: 'white' }}>{word}</span>
                            )}
                          </span>
                        )
                      })}
                    </div>
                  </motion.div>
                </div>
              </div>
            </div>

            <div className="absolute right-[-3px] top-[130px] w-[3px] h-[28px] bg-black rounded-r-sm ring-1 ring-neutral-800" />
            <div className="absolute right-[-3px] top-[172px] w-[3px] h-[52px] bg-black rounded-r-sm ring-1 ring-neutral-800" />
            <div className="absolute right-[-3px] top-[236px] w-[3px] h-[52px] bg-black rounded-r-sm ring-1 ring-neutral-800" />
            <div className="absolute left-[-3px] top-[150px] w-[3px] h-[22px] bg-black rounded-l-sm ring-1 ring-neutral-800" />
            <div className="absolute left-[-3px] top-[182px] w-[3px] h-[38px] bg-black rounded-l-sm ring-1 ring-neutral-800" />
            <div className="absolute bottom-3 left-1/2 -translate-x-1/2 w-[120px] h-[4px] bg-neutral-500/40 rounded-full z-20" />
          </div>

          <div className="absolute w-[320px] h-[640px] rounded-[4rem] bg-orange-500/10 blur-[120px] pointer-events-none" />
        </div>
      </div>
    </section>
  )
}

function OrpSpan({ word, orp }: { word: string; orp: number }) {
  return (
    <span className="inline-flex">
      {word.split('').map((char, i) => (
        <span key={i} style={{ color: i === orp ? '#E05555' : 'white' }}>
          {char}
        </span>
      ))}
    </span>
  )
}
