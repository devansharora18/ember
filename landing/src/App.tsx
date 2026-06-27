import { motion } from 'framer-motion'
import Navbar from './components/Navbar'
import Phone3D from './components/Phone3D'
import useLenis from './hooks/useLenis'
import { baseUrl } from './utils/baseUrl'

const features = [
  { icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253', title: 'Read EPUBs', desc: 'Import any EPUB file. Clean, distraction-free reading with bold and italic formatting.' },
  { icon: 'M13 10V3L4 14h7v7l9-11h-7z', title: 'RSVP Speed Read', desc: 'Read at 300+ WPM with rapid serial visual presentation and focal letter highlighting.' },
  { icon: 'M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z', title: 'Bookmarks & Highlights', desc: 'Mark important passages and highlight text. All saved locally.' },
  { icon: 'M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01', title: 'Customizable', desc: 'Choose fonts, sizes, dark or light mode. Make reading truly yours.' },
  { icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z', title: 'Track Progress', desc: 'See how far you\'ve read. Pick up right where you left off.' },
  { icon: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4', title: 'Export & Backup', desc: 'Export your entire library with books, progress and settings in one file.' },
]

export default function App() {
  useLenis()

  return (
    <div className="bg-black text-white font-body">
      <Navbar />

      {/* Home */}
      <Phone3D />

      {/* Features */}
      <section id="features" className="relative px-4 md:px-6 py-20 md:py-32 scroll-mt-16">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12 md:mb-20"
          >
            <h2 className="font-heading text-3xl md:text-4xl lg:text-5xl font-bold mb-3 md:mb-4">
              Everything you need
            </h2>
            <p className="text-neutral-400 text-base md:text-lg max-w-xl mx-auto">
              A powerful EPUB reader designed for readers who want more.
            </p>
          </motion.div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-80px' }}
                transition={{ duration: 0.6, delay: i * 0.1, ease: 'easeOut' }}
                className="p-5 md:p-8 rounded-2xl bg-neutral-900/50 border border-neutral-800 hover:border-orange-500/30 transition-colors duration-300 cursor-pointer group"
              >
                <div className="w-9 h-9 md:w-10 md:h-10 rounded-lg bg-neutral-900 border border-neutral-800 flex items-center justify-center mb-3 md:mb-4 group-hover:border-orange-500/40 transition-colors duration-200">
                  <svg className="w-4 h-4 md:w-5 md:h-5 text-orange-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d={f.icon} />
                  </svg>
                </div>
                <h3 className="text-white font-semibold text-base md:text-lg mb-1 md:mb-2">{f.title}</h3>
                <p className="text-neutral-400 text-xs md:text-sm leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Screenshots */}
      <section id="screenshots" className="relative px-4 md:px-6 py-20 md:py-32 scroll-mt-16">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12 md:mb-20"
          >
            <h2 className="font-heading text-3xl md:text-4xl lg:text-5xl font-bold mb-3 md:mb-4">
              See it in action
            </h2>
            <p className="text-neutral-400 text-base md:text-lg max-w-xl mx-auto">
              A clean, focused reading experience on any device.
            </p>
          </motion.div>

          <div className="flex justify-center gap-3 md:gap-6 flex-wrap">
            {[
              { src: `${baseUrl}screenshots/library.png`, label: 'Library' },
              { src: `${baseUrl}screenshots/reader.png`, label: 'Reader' },
              { src: `${baseUrl}screenshots/rsvp.png`, label: 'RSVP' },
            ].map((s, i) => (
              <motion.div
                key={s.label}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: i * 0.1 }}
                className="text-center w-[28%] min-w-[160px] md:w-[280px]"
              >
                <div className="overflow-hidden mb-2 md:mb-3">
                  <img
                    src={s.src}
                    alt={s.label}
                    className="w-full h-auto"
                  />
                </div>
                <p className="text-neutral-400 text-xs md:text-sm font-medium">{s.label}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Install */}
      <section id="install" className="relative min-h-screen flex items-center justify-center scroll-mt-16 px-4">
        <div className="max-w-2xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="font-heading text-3xl md:text-4xl lg:text-5xl font-bold mb-4 md:mb-6">
              Download Ember
            </h2>
            <p className="text-neutral-400 text-base md:text-lg mb-8 md:mb-12">
              Available on Android. More platforms coming soon.
            </p>
            <div className="flex flex-col items-center gap-6 md:gap-8">
              <div className="flex flex-col sm:flex-row gap-3 md:gap-4 justify-center w-full max-w-xs sm:max-w-none">
                <a
                  href={`${baseUrl}ember.apk`}
                  download
                  className="inline-flex items-center justify-center gap-3 px-6 md:px-8 py-3.5 md:py-4 bg-orange-500 text-white text-sm md:text-base font-semibold rounded-xl hover:bg-orange-400 transition-colors duration-200 cursor-pointer"
                >
                  <svg className="w-5 h-5 md:w-6 md:h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.807 1.626a1 1 0 0 1 0 1.732l-2.807 1.626L15.206 12l2.492-2.492zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.634z"/>
                  </svg>
                  Download APK
                </a>
                <a
                  href="https://ember.devansharora.in"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center gap-3 px-6 md:px-8 py-3.5 md:py-4 bg-white text-black text-sm md:text-base font-semibold rounded-xl hover:bg-neutral-200 transition-colors duration-200 cursor-pointer"
                >
                  <svg className="w-4 h-4 md:w-5 md:h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                  </svg>
                  Open Web App
                </a>
              </div>

              <div className="inline-flex items-center gap-2 px-5 md:px-6 py-2.5 md:py-3 bg-neutral-900 border border-neutral-800 rounded-xl">
                <svg className="w-5 h-5 md:w-6 md:h-6 text-neutral-400" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.807 1.626a1 1 0 0 1 0 1.732l-2.807 1.626L15.206 12l2.492-2.492zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.634z"/>
                </svg>
                <span className="text-neutral-500 text-xs md:text-sm">Play Store — Coming soon</span>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="px-4 md:px-6 py-8 md:py-12 border-t border-neutral-900">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row justify-between items-center gap-3 md:gap-4">
          <p className="text-neutral-600 text-xs md:text-sm">Ember — EPUB Reader</p>
          <p className="text-neutral-700 text-[10px] md:text-xs">Made with care</p>
        </div>
      </footer>
    </div>
  )
}
