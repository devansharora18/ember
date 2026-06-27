import { baseUrl } from '../utils/baseUrl'

export default function EmberLogo({ className = '' }: { className?: string }) {
  return <img src={`${baseUrl}icon.png`} alt="Ember" className={className} />
}
