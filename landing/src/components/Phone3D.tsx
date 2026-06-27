import { useRef, useState, useCallback } from 'react'
import { motion, useScroll, useTransform, useMotionValueEvent, MotionValue } from 'framer-motion'

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

  const rotateZ = useTransform(scrollYProgress, [0, 0.2], [0, 90])
  const portraitOpacity = useTransform(scrollYProgress, [0, 0.1, 0.18], [1, 1, 0])
  const wordProgress = useTransform(scrollYProgress, [0.25, 1], [0, words.length - 1])
  const rsvpOpacity = useTransform(scrollYProgress, [0.2, 0.3], [0, 1])

  useMotionValueEvent(wordProgress, 'change', (v) => {
    setFocal(v)
  })

  const focalIdx = Math.floor(focal)

  const visible = []
  for (let i = focalIdx - 1; i <= focalIdx + 1; i++) {
    if (i < 0 || i >= words.length) continue
    visible.push({ word: words[i], distance: Math.abs(i - focal), index: i })
  }

  return (
    <section
      ref={ref}
      className="relative h-[800vh] bg-black flex items-start justify-center"
    >
      <div className="sticky top-0 h-screen w-full flex items-center justify-center" style={{ perspective: '1200px' }}>
        <motion.div
          style={{ rotateZ }}
          className="relative w-[280px] h-[580px] rounded-[3rem] border-4 border-neutral-700 bg-neutral-900 shadow-2xl shadow-orange-500/10"
        >
          <div className="absolute inset-[8px] rounded-[2.5rem] bg-black overflow-hidden flex items-center justify-center">
            <motion.p
              style={{ opacity: portraitOpacity }}
              className="absolute text-white text-center px-6"
            >
              <span className="block text-4xl font-bold font-heading">Ember</span>
              <span className="block text-sm text-neutral-400 mt-2">EPUB Reader</span>
            </motion.p>

            <motion.div
              style={{ rotate: useTransform(rotateZ, (v) => -v), opacity: rsvpOpacity }}
              className="absolute inset-0 flex items-center justify-center overflow-hidden"
            >
              <div className="flex items-center gap-0 select-none">
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
                        fontSize: 32,
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
          <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-[100px] h-[4px] bg-neutral-600 rounded-full z-20" />
        </motion.div>

        <motion.div
          style={{ rotateZ }}
          className="absolute flex items-center justify-center pointer-events-none"
        >
          <div className="w-[320px] h-[620px] rounded-[3.5rem] bg-orange-500/20 blur-[80px]" />
        </motion.div>
      </div>
    </section>
  )
}

function OrpSpan({ word, orp }: { word: string; orp: number }) {
  const focalColor = '#E05555'
  return (
    <span className="inline-flex">
      {word.split('').map((char, i) => (
        <span key={i} style={{ color: i === orp ? focalColor : 'white' }}>
          {char}
        </span>
      ))}
    </span>
  )
}
