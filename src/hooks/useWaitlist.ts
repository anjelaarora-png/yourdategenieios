import { useState } from 'react'
import { collection, addDoc, serverTimestamp, query, where, getDocs } from 'firebase/firestore'
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
      const existing = await getDocs(
        query(collection(db, 'waitlist'), where('email', '==', entry.email.toLowerCase()))
      )
      if (!existing.empty) {
        setStatus('duplicate')
        return
      }

      // Match existing schema: email, fullName, city, phone, createdAt
      // Plus: source (attribution), userAgent (anti-fraud), partnerEmail (optional)
      await addDoc(collection(db, 'waitlist'), {
        email: entry.email.toLowerCase().trim(),
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
      setStatus('error')
      setErrorMessage(
        err instanceof Error ? err.message : 'Something went wrong. Please try again.'
      )
    }
  }

  return { status, errorMessage, submit }
}
