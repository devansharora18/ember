import { useState, useEffect } from 'react'
import EmberLogo from './EmberLogo'

const navLinks = [
  { label: 'Home', href: '#home' },
  { label: 'Features', href: '#features' },
  { label: 'Screenshots', href: '#screenshots' },
  { label: 'Install', href: '#install' },
]

function scrollTo(href: string) {
  const lenis = (window as any).__lenis
  const el = document.querySelector(href)
  if (el) {
    if (lenis) {
      lenis.scrollTo(el)
    } else {
      el.scrollIntoView({ behavior: 'smooth' })
    }
  }
}

export default function Navbar() {
  const [active, setActive] = useState('#home')

  useEffect(() => {
    const lenis = (window as any).__lenis
    const sections = navLinks.map((l) => document.querySelector(l.href)).filter(Boolean) as HTMLElement[]

    const onScroll = () => {
      const y = window.scrollY + window.innerHeight / 3
      for (let i = sections.length - 1; i >= 0; i--) {
        const el = sections[i]
        if (el && el.offsetTop <= y) {
          setActive(navLinks[i].href)
          return
        }
      }
    }

    if (lenis) {
      lenis.on('scroll', onScroll)
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    onScroll()

    return () => {
      if (lenis) lenis.off('scroll', onScroll)
      window.removeEventListener('scroll', onScroll)
    }
  }, [])

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-md border-b border-neutral-800/50">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#home" onClick={(e) => { e.preventDefault(); scrollTo('#home') }} className="flex items-center gap-2 cursor-pointer">
          <EmberLogo className="w-9 h-9" />
          <span className="font-heading font-semibold text-white text-lg">Ember</span>
        </a>

        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={(e) => { e.preventDefault(); scrollTo(link.href) }}
              className={`text-sm transition-colors duration-200 cursor-pointer ${
                active === link.href ? 'text-white' : 'text-neutral-400 hover:text-white'
              }`}
            >
              {link.label}
            </a>
          ))}
        </div>

        <a
          href="https://github.com"
          target="_blank"
          rel="noopener noreferrer"
          className="text-neutral-400 hover:text-white transition-colors duration-200 cursor-pointer"
          aria-label="GitHub"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
          </svg>
        </a>
      </div>
    </nav>
  )
}
