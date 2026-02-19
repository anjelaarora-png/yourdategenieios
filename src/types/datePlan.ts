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
}

export interface ConversationStarter {
  question: string;
  category: string;
  emoji: string;
}

export interface DatePlan {
  optionLabel?: string;
  title: string;
  tagline: string;
  totalDuration: string;
  estimatedCost: string;
  stops: DatePlanStop[];
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
