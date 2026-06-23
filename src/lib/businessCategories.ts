export const BUSINESS_VENUE_CATEGORIES = [
  { value: 'restaurant', label: 'Restaurant' },
  { value: 'bar_lounge', label: 'Bar & lounge' },
  { value: 'cafe_bakery', label: 'Café / bakery' },
  { value: 'wine_tasting', label: 'Wine bar / tasting room' },
  { value: 'activity', label: 'Activity / experience' },
  { value: 'entertainment', label: 'Entertainment (comedy, jazz, live music)' },
  { value: 'spa_wellness', label: 'Spa / wellness' },
  { value: 'hotel_stay', label: 'Hotel / boutique stay' },
  { value: 'retail_gifts', label: 'Retail / gifts' },
  { value: 'event_venue', label: 'Event venue' },
  { value: 'other', label: 'Other (describe below)' },
] as const

export type BusinessVenueCategory = (typeof BUSINESS_VENUE_CATEGORIES)[number]['value']

export const PROMOTION_INTERESTS = [
  { value: 'featured_itinerary', label: 'Featured stop inside AI date itineraries' },
  { value: 'sponsored_plan', label: 'Sponsored date plan / takeover night' },
  { value: 'event_promo', label: 'Promote a specific event or special' },
  { value: 'ongoing_ads', label: 'Ongoing local advertising' },
  { value: 'other', label: 'Other (describe below)' },
] as const

export type PromotionInterest = (typeof PROMOTION_INTERESTS)[number]['value']

export const BUDGET_RANGES = [
  { value: 'under_200', label: 'Under $200 / month' },
  { value: '200_500', label: '$200 – $500 / month' },
  { value: '500_plus', label: '$500+ / month' },
  { value: 'unsure', label: 'Not sure yet — send options' },
] as const

export type BudgetRange = (typeof BUDGET_RANGES)[number]['value']

/** Legacy Firestore field — derived from category for older admin views. */
export function legacyVenueType(category: BusinessVenueCategory): string {
  switch (category) {
    case 'restaurant':
    case 'cafe_bakery':
      return 'restaurant'
    case 'bar_lounge':
    case 'wine_tasting':
      return 'bar'
    case 'activity':
    case 'entertainment':
    case 'event_venue':
      return 'activity'
    case 'retail_gifts':
      return 'retail'
    default:
      return 'other'
  }
}
