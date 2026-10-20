import EmberLogo from './EmberLogo'
import { baseUrl } from '../utils/baseUrl'

const links = [
  { label: 'Privacy', href: `${baseUrl}privacy.html`, external: false },
  { label: 'Feedback', href: `${baseUrl}feedback.html`, external: false },
  { label: 'GitHub', href: 'https://github.com/devansharora18/ember', external: true },
  { label: 'Google Group', href: 'https://groups.google.com/g/ember-closed-testing', external: true },
]

export default function Footer() {
  return (
    <footer className="border-t border-rule">
      <div className="mx-auto w-full max-w-[1180px] px-5 py-10 md:px-8 md:py-12">
        <div className="flex flex-col gap-8 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <a href="#top" className="flex items-center gap-2.5" aria-label="Ember, back to top">
              <EmberLogo className="h-6 w-6 rounded" />
              <span className="font-display text-[1.25rem] leading-none tracking-tight">Ember</span>
            </a>
            <p className="mt-3 max-w-[34ch] text-sm leading-relaxed text-muted">
              An EPUB reader for Android, with speed reading built in.
            </p>
          </div>

          <nav aria-label="Footer" className="grid grid-cols-2 gap-x-10 gap-y-2.5 text-sm">
            {links.map((link) => (
              <a
                key={link.label}
                href={link.href}
                {...(link.external ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
                className="text-muted transition-colors duration-200 hover:text-ink"
              >
                {link.label}
              </a>
            ))}
          </nav>
        </div>

        <div className="mt-10 flex flex-col gap-2 border-t border-rule pt-5 text-xs text-muted sm:flex-row sm:items-center sm:justify-between">
          <p>© {new Date().getFullYear()} Ember · GPLv3</p>
          <p className="font-mono">Made with Flutter</p>
        </div>
      </div>
    </footer>
  )
}
