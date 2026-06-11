import { isLaunched, appStoreUrl } from '@/lib/launchConfig'
import { WaitlistForm } from './waitlist/WaitlistForm'
import { Events } from '@/lib/analytics'

interface PrimaryCTAProps {
  /** Waitlist analytics: which surface the user came from (e.g. "landing_hero") */
  source: string
  /** App Store click analytics: placement label (e.g. "hero", "footer") */
  appStorePlacement: string
  className?: string
}

export function PrimaryCTA({ source, appStorePlacement, className = '' }: PrimaryCTAProps) {
  if (isLaunched) {
    return (
      <a
        href={appStoreUrl}
        target="_blank"
        rel="noopener noreferrer"
        onClick={() => Events.appStoreClick(appStorePlacement)}
        className={`inline-flex items-center gap-3 rounded-xl bg-black px-6 py-4 text-white font-semibold hover:bg-zinc-900 transition-all hover:scale-105 ${className}`}
      >
        <AppleLogo />
        Download on App Store
      </a>
    )
  }

  return <WaitlistForm source={source} className={className} />
}

function AppleLogo() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6 flex-shrink-0" fill="currentColor" aria-hidden="true">
      <path d="M17.05 20.28c-.98.95-2.05.86-3.08.43-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.43C2.79 15.5 3.51 7.71 9.05 7.41c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 3.99l.01-.01M12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25" />
    </svg>
  )
}
