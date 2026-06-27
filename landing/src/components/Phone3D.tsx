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

  return (
    <section
      id="home"
      ref={ref}
      className="relative h-[800vh] bg-black scroll-mt-16"
    >
      <div className="sticky top-0 h-screen w-full max-w-7xl mx-auto flex items-center">
        {/* Left — Hero text */}
        <div className="w-1/2 pl-8 pr-16">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: 'easeOut' }}
          >
            <h1 className="font-heading text-5xl md:text-6xl font-bold mb-4">
              Read smarter,<br />not harder.
            </h1>
            <p className="text-neutral-400 text-lg leading-relaxed max-w-md mb-8">
              Ember is a powerful EPUB reader with speed reading, bookmarks, highlights, and export — all in one beautiful app.
            </p>
            <div className="flex gap-4">
              <a
                href="#install"
                className="inline-flex items-center gap-2 px-6 py-3 bg-orange-500 text-white font-semibold rounded-xl hover:bg-orange-400 transition-colors duration-200 cursor-pointer"
              >
                Download Now
              </a>
              <a
                href="#features"
                className="inline-flex items-center gap-2 px-6 py-3 bg-neutral-900 text-white font-semibold rounded-xl border border-neutral-800 hover:border-neutral-700 transition-colors duration-200 cursor-pointer"
              >
                Learn More
              </a>
            </div>
          </motion.div>
        </div>

        {/* Right — Phone */}
        <div className="w-1/2 flex justify-center relative">
          <div className="relative select-none">
            <div className="w-[300px] h-[610px] rounded-[56px] bg-black p-[6px] shadow-[0_0_0_1px_#333,0_0_120px_rgba(249,115,22,0.1)]">
              <div className="w-full h-full rounded-[50px] bg-black p-[14px] ring-1 ring-white/10">
                <div className="w-full h-full rounded-[37px] bg-black flex items-center justify-center relative">
                  <div className="absolute top-[10px] left-1/2 -translate-x-1/2 w-[10px] h-[10px] bg-[#1a1a1a] rounded-full z-10 ring-1 ring-neutral-800" />

                  {/* Portrait: Logo + text */}
                  <motion.div
                    style={{ opacity: portraitOpacity }}
                    className="absolute flex flex-col items-center gap-4"
                  >
                    <img src="/icon.png" alt="Ember" className="w-24 h-24" />
                    <span className="block text-3xl font-bold font-heading text-white">Ember</span>
                    <span className="block text-sm text-neutral-400">EPUB Reader</span>
                  </motion.div>

                  {/* RSVP text */}
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
