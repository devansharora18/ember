import { useRef, useState, useEffect, useCallback } from 'react'
import { useTransform, MotionValue, useMotionValue } from 'framer-motion'
import Lenis from 'lenis'

export function useLenisScroll(targetRef: React.RefObject<HTMLElement | null>) {
  const progress = useMotionValue(0)

  useEffect(() => {
    const target = targetRef.current
    if (!target) return

    const lenis = (window as any).__lenis as Lenis | undefined
    if (!lenis) {
      const handleScroll = () => {
        const rect = target.getBoundingClientRect()
        const start = rect.top
        const total = rect.height - window.innerHeight
        if (total <= 0) {
          progress.set(0)
          return
        }
        const p = (-start / total)
        progress.set(Math.max(0, Math.min(1, p)))
      }
      window.addEventListener('scroll', handleScroll, { passive: true })
      handleScroll()
      return () => window.removeEventListener('scroll', handleScroll)
    }

    const handleScroll = ({ scroll }: { scroll: number }) => {
      const rect = target.getBoundingClientRect()
      const elTop = rect.top + scroll - window.scrollY
      const start = elTop - window.innerHeight
      const total = rect.height
      if (total <= 0) {
        progress.set(0)
        return
      }
      const p = (scroll - start) / total
      progress.set(Math.max(0, Math.min(1, p)))
    }

    lenis.on('scroll', handleScroll)
    return () => lenis.off('scroll', handleScroll)
  }, [targetRef, progress])

  return progress
}
