import { useState } from 'react'
import { doc, setDoc, serverTimestamp } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Events } from '@/lib/analytics'
import {
  type BusinessVenueCategory,
  type BudgetRange,
  type PromotionInterest,
  legacyVenueType,
} from '@/lib/businessCategories'

export type BusinessListingEntry = {
  businessName: string
  contactName: string
  contactRole?: string
  email: string
  phone: string
  website?: string
  streetAddress: string
  city: string
  state: string
  zip?: string
  venueCategory: BusinessVenueCategory
  venueCategoryOther?: string
  aboutVenue: string
  coupleExperience: string
  promotionInterest: PromotionInterest
  promotionOther?: string
  budgetRange: BudgetRange
  additionalNotes?: string
  source: string
}

export type BusinessListingStatus = 'idle' | 'submitting' | 'success' | 'error' | 'duplicate'

export function useBusinessListing() {
  const [status, setStatus] = useState<BusinessListingStatus>('idle')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  async function submit(entry: BusinessListingEntry) {
    setStatus('submitting')
    setErrorMessage(null)

    try {
      const email = entry.email.toLowerCase().trim()

      const venueCategoryOther =
        entry.venueCategory === 'other' ? entry.venueCategoryOther?.trim() || null : null
      const promotionOther =
        entry.promotionInterest === 'other' ? entry.promotionOther?.trim() || null : null

      await setDoc(doc(db, 'business_listings', email), {
        businessName: entry.businessName.trim(),
        contactName: entry.contactName.trim(),
        contactRole: entry.contactRole?.trim() || null,
        email,
        phone: entry.phone.trim(),
        website: entry.website?.trim() || null,
        streetAddress: entry.streetAddress.trim(),
        city: entry.city.trim(),
        state: entry.state.trim(),
        zip: entry.zip?.trim() || null,
        venueCategory: entry.venueCategory,
        venueCategoryOther,
        venueType: legacyVenueType(entry.venueCategory),
        aboutVenue: entry.aboutVenue.trim(),
        coupleExperience: entry.coupleExperience.trim(),
        promotionInterest: entry.promotionInterest,
        promotionOther,
        budgetRange: entry.budgetRange,
        additionalNotes: entry.additionalNotes?.trim() || null,
        notes: entry.additionalNotes?.trim() || null,
        source: entry.source,
        status: 'new',
        applicationType: 'advertising',
        createdAt: serverTimestamp(),
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
      })

      Events.businessListingSignup(entry.source, entry.venueCategory)
      setStatus('success')
    } catch (err: unknown) {
      console.error('Business listing submission error:', err)
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
