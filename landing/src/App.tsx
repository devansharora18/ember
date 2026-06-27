import { motion } from 'framer-motion'
import Navbar from './components/Navbar'
import Phone3D from './components/Phone3D'

const features = [
  { icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253', title: 'Read EPUBs', desc: 'Import any EPUB file. Clean, distraction-free reading with bold and italic formatting.' },
  { icon: 'M13 10V3L4 14h7v7l9-11h-7z', title: 'RSVP Speed Read', desc: 'Read at 300+ WPM with rapid serial visual presentation and focal letter highlighting.' },
  { icon: 'M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z', title: 'Bookmarks & Highlights', desc: 'Mark important passages and highlight text. All saved locally.' },
  { icon: 'M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01', title: 'Customizable', desc: 'Choose fonts, sizes, dark or light mode. Make reading truly yours.' },
  { icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z', title: 'Track Progress', desc: 'See how far you\'ve read. Pick up right where you left off.' },
  { icon: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4', title: 'Export & Backup', desc: 'Export your entire library with books, progress and settings in one file.' },
]

export default function App() {
  return (
    <div className="bg-black text-white font-body">
      <Navbar />

      {/* Home */}
      <Phone3D />

      {/* Features */}
      <section id="features" className="relative px-6 py-32 scroll-mt-16">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-20"
          >
            <h2 className="font-heading text-4xl md:text-5xl font-bold mb-4">
              Everything you need
            </h2>
            <p className="text-neutral-400 text-lg max-w-xl mx-auto">
              A powerful EPUB reader designed for readers who want more.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-80px' }}
                transition={{ duration: 0.6, delay: i * 0.1, ease: 'easeOut' }}
                className="p-8 rounded-2xl bg-neutral-900/50 border border-neutral-800 hover:border-orange-500/30 transition-colors duration-300 cursor-pointer group"
              >
                <div className="w-10 h-10 rounded-lg bg-neutral-900 border border-neutral-800 flex items-center justify-center mb-4 group-hover:border-orange-500/40 transition-colors duration-200">
                  <svg className="w-5 h-5 text-orange-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d={f.icon} />
                  </svg>
                </div>
                <h3 className="text-white font-semibold text-lg mb-2">{f.title}</h3>
                <p className="text-neutral-400 text-sm leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Screenshots */}
      <section id="screenshots" className="relative px-6 py-32 scroll-mt-16">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-20"
          >
            <h2 className="font-heading text-4xl md:text-5xl font-bold mb-4">
              See it in action
            </h2>
            <p className="text-neutral-400 text-lg max-w-xl mx-auto">
              A clean, focused reading experience on any device.
            </p>
          </motion.div>

          <div className="flex justify-center gap-6">
            {[
              { src: '/screenshots/library.png', label: 'Library' },
              { src: '/screenshots/reader.png', label: 'Reader' },
              { src: '/screenshots/rsvp.png', label: 'RSVP' },
            ].map((s, i) => (
              <motion.div
                key={s.label}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: i * 0.1 }}
                className="text-center"
              >
                <div className="overflow-hidden mb-3">
                  <img
                    src={s.src}
                    alt={s.label}
                    className="w-[280px] h-auto"
                  />
                </div>
                <p className="text-neutral-400 text-sm font-medium">{s.label}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Install */}
      <section id="install" className="relative px-6 py-32 scroll-mt-16">
        <div className="max-w-2xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="font-heading text-4xl md:text-5xl font-bold mb-6">
              Start reading better
            </h2>
            <p className="text-neutral-400 text-lg mb-10">
              Download Ember and transform your reading experience.
            </p>
            <div className="flex flex-wrap gap-4 justify-center">
              <a
                href="#"
                className="inline-flex items-center gap-2 px-8 py-4 bg-white text-black font-semibold rounded-xl hover:bg-neutral-200 transition-colors duration-200 cursor-pointer"
              >
                <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09z"/>
                </svg>
                App Store
              </a>
              <a
                href="#"
                className="inline-flex items-center gap-2 px-8 py-4 bg-orange-500 text-white font-semibold rounded-xl hover:bg-orange-400 transition-colors duration-200 cursor-pointer"
              >
                <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.807 1.626a1 1 0 0 1 0 1.732l-2.807 1.626L15.206 12l2.492-2.492zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.634z"/>
                </svg>
                Google Play
              </a>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="px-6 py-12 border-t border-neutral-900">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-neutral-600 text-sm">Ember — EPUB Reader</p>
          <p className="text-neutral-700 text-xs">Made with care</p>
        </div>
      </footer>
    </div>
  )
}
