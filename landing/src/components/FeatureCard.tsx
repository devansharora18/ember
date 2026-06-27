import { motion } from 'framer-motion'

interface Props {
  icon: string
  title: string
  description: string
  delay?: number
}

export default function FeatureCard({ icon, title, description, delay = 0 }: Props) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 40 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.6, delay, ease: 'easeOut' }}
      className="p-8 rounded-2xl bg-neutral-900/50 border border-neutral-800 hover:border-orange-500/30 transition-colors duration-300 cursor-pointer"
    >
      <span className="text-3xl mb-4 block">{icon}</span>
      <h3 className="text-white font-semibold text-lg mb-2">{title}</h3>
      <p className="text-neutral-400 text-sm leading-relaxed">{description}</p>
    </motion.div>
  )
}
