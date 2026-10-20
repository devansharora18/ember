import Navbar from './components/Navbar'
import Hero from './components/Hero'
import FeatureIndex from './components/FeatureIndex'
import SpeedSection from './components/SpeedSection'
import Screens from './components/Screens'
import Download from './components/Download'
import Footer from './components/Footer'
import useLenis from './hooks/useLenis'

export default function App() {
  useLenis()

  return (
    <div className="grain min-h-screen bg-paper text-ink">
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[70] focus:bg-ink focus:px-4 focus:py-2 focus:text-sm focus:text-paper"
      >
        Skip to content
      </a>

      <Navbar />

      <main id="main">
        <Hero />
        <FeatureIndex />
        <SpeedSection />
        <Screens />
        <Download />
      </main>

      <Footer />
    </div>
  )
}
