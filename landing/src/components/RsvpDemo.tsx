import { useEffect, useState } from 'react'

const SENTENCE =
  'The average reader moves at about two hundred words a minute. Ember shows you one word at a time, so the page never has to move.'
const WORDS = SENTENCE.split(' ')

/** Optimal recognition point, kept stable so the eye never travels. */
function orpIndex(word: string) {
  const letters = word.replace(/[^\p{L}]/gu, '').length
  if (letters <= 1) return 0
  if (letters <= 5) return 1
  if (letters <= 9) return 2
  if (letters <= 13) return 3
  return 4
}

function prefersReducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

export default function RsvpDemo() {
  const [index, setIndex] = useState(0)
  const [wpm, setWpm] = useState(260)
  const [playing, setPlaying] = useState(() => !prefersReducedMotion())

  useEffect(() => {
    if (!playing) return

    const word = WORDS[index]
    const base = 60_000 / wpm
    const delay = /[.!?]$/.test(word) ? base * 2.2 : /[,;:]$/.test(word) ? base * 1.6 : base

    const timer = window.setTimeout(() => {
      setIndex((current) => (current + 1) % WORDS.length)
    }, delay)

    return () => window.clearTimeout(timer)
  }, [index, playing, wpm])

  const word = WORDS[index]
  const focal = orpIndex(word)
  const before = word.slice(0, focal)
  const focus = word.charAt(focal)
  const after = word.slice(focal + 1)
  const progress = ((index + 1) / WORDS.length) * 100

  return (
    <figure className="relative border border-rule bg-panel">
      <div className="flex items-center justify-between gap-4 border-b border-rule/80 px-4 py-3 md:px-5">
        <span className="meta flex items-center gap-2">
          <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-ember" />
          RSVP · live demo
        </span>
        <output htmlFor="rsvp-speed" aria-live="polite" className="font-mono text-xs tabular-nums text-ink">
          {wpm} <span className="text-muted">wpm</span>
        </output>
      </div>

      <div className="relative flex h-[164px] items-center justify-center overflow-hidden md:h-[188px]">
        <div aria-hidden="true" className="pointer-events-none absolute inset-y-4 left-1/2 w-px -translate-x-1/2 bg-rule" />
        <div aria-hidden="true" className="pointer-events-none absolute left-1/2 top-4 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-ember" />

        <p aria-hidden="true" className="relative z-10 w-full overflow-hidden bg-panel px-3 py-2">
          <span className="grid w-full grid-cols-[1fr_auto_1fr] items-baseline font-display text-[clamp(2.25rem,7.5vw,3.5rem)] leading-none tracking-[-0.01em]">
            <span className="justify-self-end whitespace-pre">{before}</span>
            <span className="text-ember">{focus}</span>
            <span className="justify-self-start whitespace-pre">{after}</span>
          </span>
        </p>
        <span className="sr-only">{SENTENCE}</span>
      </div>

      <div className="flex items-center gap-3 border-t border-rule/80 px-4 py-3 md:px-5">
        <button
          type="button"
          onClick={() => setPlaying((value) => !value)}
          aria-label={playing ? 'Pause demo' : 'Play demo'}
          className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-rule text-ink transition-colors duration-200 hover:border-ember hover:text-ember"
        >
          {playing ? (
            <svg aria-hidden="true" className="h-3.5 w-3.5" viewBox="0 0 12 12" fill="currentColor">
              <rect x="1.5" y="1.5" width="3" height="9" />
              <rect x="7.5" y="1.5" width="3" height="9" />
            </svg>
          ) : (
            <svg aria-hidden="true" className="ml-0.5 h-3.5 w-3.5" viewBox="0 0 12 12" fill="currentColor">
              <path d="M2 1.2 10.2 6 2 10.8z" />
            </svg>
          )}
        </button>

        <label className="flex min-w-0 flex-1 items-center">
          <span className="sr-only">Reading speed, words per minute</span>
          <input
            id="rsvp-speed"
            type="range"
            min={100}
            max={600}
            step={10}
            value={wpm}
            onChange={(event) => setWpm(Number(event.target.value))}
            className="slider"
          />
        </label>

        <button
          type="button"
          onClick={() => setIndex(0)}
          aria-label="Restart demo from the first word"
          className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-muted transition-colors duration-200 hover:text-ember"
        >
          <svg aria-hidden="true" className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.6}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 5v5h5M4.6 14a8 8 0 1 0 .5-6.4" />
          </svg>
        </button>
      </div>

      <div className="flex items-center gap-4 border-t border-rule/80 px-4 py-2.5 md:px-5">
        <span className="meta whitespace-nowrap tabular-nums">
          word {index + 1} / {WORDS.length}
        </span>
        <span aria-hidden="true" className="h-px flex-1 bg-rule">
          <span className="block h-px bg-ember transition-[width] duration-200 ease-out" style={{ width: `${progress}%` }} />
        </span>
      </div>

      <figcaption className="border-t border-rule/80 px-4 py-3 text-[0.8125rem] leading-relaxed text-muted md:px-5">
        The ember letter is the optimal recognition point. Every word is pinned to the same column, so
        your eye stops jumping across the line.
      </figcaption>
    </figure>
  )
}
