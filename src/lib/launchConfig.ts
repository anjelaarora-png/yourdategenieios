export type LaunchMode = 'prelaunch' | 'launched'

// Allow ?launchMode=launched (or =prelaunch) URL param to override env var for testing.
// Works in browser only; falls back to env var in SSR/build contexts.
const urlMode =
  typeof window !== 'undefined'
    ? new URLSearchParams(window.location.search).get('launchMode')
    : null

export const launchMode: LaunchMode =
  urlMode === 'launched' ? 'launched' :
  urlMode === 'prelaunch' ? 'prelaunch' :
  (import.meta.env.VITE_LAUNCH_MODE as LaunchMode) === 'launched' ? 'launched' : 'prelaunch'

export const appStoreUrl: string =
  import.meta.env.VITE_APP_STORE_URL ?? 'https://apps.apple.com/app/your-date-genie'

export const isLaunched = launchMode === 'launched'
