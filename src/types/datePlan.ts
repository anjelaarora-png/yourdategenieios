export interface DatePlanStop {
  order: number;
  name: string;
  venueType: string;
  timeSlot: string;
  duration: string;
  description: string;
  whyItFits: string;
  romanticTip: string;
  emoji: string;
  // Travel info to this stop (from previous stop)
  travelTimeFromPrevious?: string;
  travelDistanceFromPrevious?: string;
  travelMode?: string;
  // Google Places validation fields
  validated?: boolean;
  placeId?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  // Enhanced venue info from Google Places
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  estimatedCostPerPerson?: string;
  /** Direct reservation URL (OpenTable, Resy, or venue booking page). Especially for dinner/restaurants. */
  bookingUrl?: string;
  /** When bookingUrl is set, preferred platform for the CTA label (e.g. "Reserve on OpenTable") */
  reservationPlatform?: 'opentable' | 'resy' | string;
}

export interface GenieSecretTouch {
  title: string;
  description: string;
  emoji: string;
}

export interface GiftSuggestion {
  name: string;
  description: string;
  priceRange: string;
  whereToBuy: string;
  purchaseUrl?: string;
  whyItFits: string;
  emoji: string;
  /** Direct URL to a product image when available; otherwise use emoji/placeholder */
  imageUrl?: string;
}

export interface ConversationStarter {
  question: string;
  category: string;
  emoji: string;
}

/** Starting point for the route (departure); not a step in the itinerary. */
export interface StartingPoint {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
}

export interface DatePlan {
  optionLabel?: string;
  title: string;
  tagline: string;
  totalDuration: string;
  estimatedCost: string;
  stops: DatePlanStop[];
  /** Departure location for the route; itinerary steps start at 1 (first venue). */
  startingPoint?: StartingPoint;
  genieSecretTouch: GenieSecretTouch;
  packingList: string[];
  weatherNote: string;
  // Phase 5: Relationship enhancers
  giftSuggestions?: GiftSuggestion[];
  conversationStarters?: ConversationStarter[];
}

export interface DatePlanOptions {
  plans: DatePlan[];
  selectedIndex: number;
}
