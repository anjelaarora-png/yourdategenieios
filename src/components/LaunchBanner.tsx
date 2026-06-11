import { isLaunched, appStoreUrl } from '@/lib/launchConfig'
import { Events } from '@/lib/analytics'

export function LaunchBanner() {
  if (!isLaunched) return null

  return (
    <div className="bg-gradient-to-r from-purple-600 to-pink-500 px-4 py-2 text-center text-sm font-medium text-white">
      Now live on the App Store —{' '}
      <a
        href={appStoreUrl}
        target="_blank"
        rel="noopener noreferrer"
        onClick={() => Events.appStoreClick('banner')}
        className="underline underline-offset-2 hover:no-underline"
      >
        Download free
      </a>
    </div>
  )
}
