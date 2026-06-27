import { useRef, useState } from 'react'
import { motion, useTransform, useMotionValueEvent } from 'framer-motion'
import { useLenisScroll } from '../hooks/useLenisScroll'
import { baseUrl } from '../utils/baseUrl'

const words = ['Introducing', 'the', 'best', 'eReader', 'app', 'for', 'you.']

function orpIndex(length: number) {
  if (length <= 1) return 0
  return Math.min(Math.floor((length - 1) / 3), 4)
}

export default function Phone3D() {
  const ref = useRef<HTMLDivElement>(null)
  const [focal, setFocal] = useState(0)
  const scrollYProgress = useLenisScroll(ref)

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
      className="relative h-[500vh] md:h-[800vh] bg-black scroll-mt-16"
    >
      <div className="sticky top-0 h-screen w-full max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-center md:justify-between px-6 md:px-0">
        {/* Mobile: phone first */}
        <div className="flex md:hidden justify-center relative mb-8">
          <PhoneFrame portraitOpacity={portraitOpacity} rsvpOpacity={rsvpOpacity} visible={visible} focalIdx={focalIdx} size="sm" />
        </div>
        

        {/* Left — Hero text */}
        <div className="md:w-1/2 md:pl-8 md:pr-16 text-center md:text-left">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: 'easeOut' }}
          >
            <h1 className="font-heading text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold mb-3 md:mb-4">
                Force yourself to read faster.
            </h1>
            <p className="text-neutral-400 text-base md:text-lg leading-relaxed max-w-md mx-auto md:mx-0 mb-6 md:mb-8">
              Ember is a powerful EPUB reader with speed reading, bookmarks, highlights, and export — all in one beautiful app.
            </p>
            <div className="flex gap-3 md:gap-4 justify-center md:justify-start">
              <a
                href="#install"
                className="inline-flex items-center gap-2 px-5 py-2.5 md:px-6 md:py-3 bg-orange-500 text-white text-sm md:text-base font-semibold rounded-xl hover:bg-orange-400 transition-colors duration-200 cursor-pointer"
              >
                Download Now
              </a>
              <a
                href="#features"
                className="inline-flex items-center gap-2 px-5 py-2.5 md:px-6 md:py-3 bg-neutral-900 text-white text-sm md:text-base font-semibold rounded-xl border border-neutral-800 hover:border-neutral-700 transition-colors duration-200 cursor-pointer"
              >
                Learn More
              </a>
            </div>
          </motion.div>
        </div>

        {/* Desktop: phone on right */}
        <div className="hidden md:flex w-1/2 justify-center relative">
          <PhoneFrame portraitOpacity={portraitOpacity} rsvpOpacity={rsvpOpacity} visible={visible} focalIdx={focalIdx} size="lg" />
        </div>
      </div>
    </section>
  )
}

function PhoneFrame({ portraitOpacity, rsvpOpacity, visible, focalIdx, size }: any) {
  const isLg = size === 'lg'
  const w = isLg ? 300 : 220
  const h = isLg ? 610 : 450

  return (
    <div className="relative select-none">
      <div
        className="bg-black p-[5px] shadow-[0_0_0_1px_#333,0_0_120px_rgba(249,115,22,0.1)]"
        style={{ width: w, height: h, borderRadius: isLg ? 56 : 42 }}
      >
        <div
          className="w-full h-full bg-black ring-1 ring-white/10 flex items-center justify-center relative"
          style={{ borderRadius: isLg ? 50 : 38, padding: isLg ? 14 : 10 }}
        >
          <div
            className="w-full h-full bg-black flex items-center justify-center relative"
            style={{ borderRadius: isLg ? 37 : 28 }}
          >
            <div className="absolute top-[8px] left-1/2 -translate-x-1/2 w-[8px] h-[8px] bg-[#1a1a1a] rounded-full z-10 ring-1 ring-neutral-800" />

            <motion.div
              style={{ opacity: portraitOpacity }}
              className="absolute flex flex-col items-center gap-3 md:gap-4"
            >
                <img src={`${baseUrl}icon.png`} alt="Ember" className={isLg ? 'w-24 h-24' : 'w-16 h-16'} />
              <span className={`block font-bold font-heading text-white ${isLg ? 'text-3xl' : 'text-2xl'}`}>Ember</span>
              <span className={`block text-neutral-400 ${isLg ? 'text-sm' : 'text-xs'}`}>EPUB Reader</span>
            </motion.div>

            <motion.div
              style={{ opacity: rsvpOpacity }}
              className="absolute inset-0 flex items-center justify-center overflow-hidden"
            >
              <div className="flex items-center gap-0">
                {visible.map(({ word, distance, index }: any) => {
                  const isFocal = index === focalIdx
                  const op = distance > 3 ? 0 : isFocal ? 1 : distance <= 1 ? 0.7 : distance <= 2 ? 0.45 : 0.25
                  const orp = isFocal ? orpIndex(word.length) : 0
                  const fs = isLg ? 26 : 18
                  return (
                    <span
                      key={index}
                      className="inline-flex items-baseline px-[3px] md:px-[5px]"
                      style={{
                        opacity: op,
                        fontFamily: 'Inter, sans-serif',
                        fontSize: fs,
                        fontWeight: isFocal ? 500 : 400,
                        lineHeight: 1,
                        transition: 'opacity 150ms ease-out',
                      }}
                    >
                      {isFocal && word.length > 1 ? (
                        word.includes('-') ? (
                          word.split('-').map((part: string, pi: number) => (
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
      <div className="absolute bottom-3 left-1/2 -translate-x-1/2 w-[100px] h-[4px] bg-neutral-500/40 rounded-full z-20" />

      {isLg && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[320px] h-[640px] rounded-[4rem] bg-orange-500/5 blur-[120px] pointer-events-none" />
      )}
    </div>
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
