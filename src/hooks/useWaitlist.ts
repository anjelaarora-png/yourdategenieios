import { useState } from 'react'
import { doc, setDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Events } from '@/lib/analytics'

export type WaitlistEntry = {
  email: string
  fullName: string
  city: string
  phone?: string
  source: string
  partnerEmail?: string
}

export type WaitlistStatus = 'idle' | 'submitting' | 'success' | 'error' | 'duplicate'

export function useWaitlist() {
  const [status, setStatus] = useState<WaitlistStatus>('idle')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  async function submit(entry: WaitlistEntry) {
    setStatus('submitting')
    setErrorMessage(null)

    try {
      const email = entry.email.toLowerCase().trim()

      // Email is the document ID — Firestore rules enforce !exists() so we never need a client read.
      await setDoc(doc(db, 'waitlist', email), {
        email,
        fullName: entry.fullName.trim(),
        city: entry.city.trim(),
        phone: entry.phone?.trim() || null,
        source: entry.source,
        partnerEmail: entry.partnerEmail?.toLowerCase().trim() || null,
        createdAt: serverTimestamp(),
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
      })

      Events.waitlistSignup(entry.source)
      setStatus('success')
    } catch (err: unknown) {
      console.error('Waitlist submission error:', err)
      const code =
        err && typeof err === 'object' && 'code' in err
          ? String((err as { code: string }).code)
          : ''
      if (code === 'permission-denied') {
        setStatus('duplicate')
        return
      }
      setStatus('error')
      setErrorMessage(
        err instanceof Error ? err.message : 'Something went wrong. Please try again.'
      )
    }
  }

  return { status, errorMessage, submit }
}
