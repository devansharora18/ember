import { useEffect, useState } from 'react'
import EmberLogo from './EmberLogo'
import { baseUrl } from '../utils/baseUrl'

const links = [
  { label: 'Reading', href: '#reading' },
  { label: 'Speed', href: '#speed' },
  { label: 'Screens', href: '#screens' },
  { label: 'Download', href: '#download' },
]

const PLAY_URL = 'https://play.google.com/store/apps/details?id=in.devansharora.ember'

export default function Navbar() {
  const [active, setActive] = useState('')

  useEffect(() => {
    const sections = links
      .map((link) => document.getElementById(link.href.slice(1)))
      .filter((el): el is HTMLElement => el !== null)

    const visible = new Set<string>()
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) visible.add(entry.target.id)
          else visible.delete(entry.target.id)
        }
        const next = links
          .map((link) => link.href.slice(1))
          .find((id) => visible.has(id))
        setActive(next ?? '')
      },
      { rootMargin: '-45% 0px -50% 0px' },
    )

    sections.forEach((section) => observer.observe(section))
    return () => observer.disconnect()
  }, [])

  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-rule/70 bg-paper/85 backdrop-blur-md">
      <nav
        aria-label="Primary"
        className="mx-auto flex h-16 w-full max-w-[1180px] items-center justify-between px-5 md:px-8"
      >
        <a href="#top" className="flex items-center gap-2.5" aria-label="Ember, back to top">
          <EmberLogo className="h-7 w-7 rounded-md" />
          <span className="font-display text-[1.375rem] leading-none tracking-tight">Ember</span>
        </a>

        <div className="hidden items-center gap-7 md:flex">
          {links.map((link) => {
            const isActive = active === link.href.slice(1)
            return (
              <a
                key={link.href}
                href={link.href}
                aria-current={isActive ? 'location' : undefined}
                className={`group relative py-1 text-[0.8125rem] transition-colors duration-200 ${
                  isActive ? 'text-ink' : 'text-muted hover:text-ink'
                }`}
              >
                {link.label}
                <span
                  aria-hidden="true"
                  className={`absolute -bottom-0.5 left-0 h-px w-full bg-ember transition-transform duration-200 ${
                    isActive ? 'scale-x-100' : 'scale-x-0 group-hover:scale-x-100'
                  }`}
                />
              </a>
            )
          })}
        </div>

        <div className="flex items-center gap-3 md:gap-5">
          <a
            href={`${baseUrl}feedback.html`}
            className="hidden text-[0.8125rem] text-muted transition-colors hover:text-ink md:block"
          >
            Feedback
          </a>
          <a
            href="https://github.com/devansharora18/ember"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Ember on GitHub"
            className="hidden text-muted transition-colors duration-200 hover:text-ink md:block"
          >
            <svg aria-hidden="true" className="h-[18px] w-[18px]" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12Z" />
            </svg>
          </a>
          <a
            href={PLAY_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex h-9 items-center gap-2 bg-ink px-4 text-[0.8125rem] font-medium text-paper transition-opacity duration-200 hover:opacity-85"
          >
            Get the app
          </a>
        </div>
      </nav>
    </header>
  )
}
