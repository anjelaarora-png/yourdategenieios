// Google Places API validation

import type { OpeningPeriod } from "./schedule.ts";

interface PlaceValidationResult {
  isValid: boolean;
  isPermanentlyClosed?: boolean;
  isTemporarilyClosed?: boolean;
  rejectReason?: string;
  officialName?: string; // The verified name from Google Maps
  placeId?: string;
  formattedAddress?: string;
  latitude?: number;
  longitude?: number;
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  openingPeriods?: OpeningPeriod[];
  businessStatus?: string;
  googleTypes?: string[];
  /** Photo URL from Google Business Profile (Place Details photos) for cards and lists. */
  imageUrl?: string;
  /** Reservation platforms detected from the venue's website URL (e.g. ["opentable", "resy"]). */
  reservationPlatforms?: string[];
}

/** Google place types that must never appear on a date itinerary. */
const DISALLOWED_PLACE_TYPES = new Set([
  "storage",
  "moving_company",
  "car_dealer",
  "car_repair",
  "car_wash",
  "electrician",
  "general_contractor",
  "insurance_agency",
  "lawyer",
  "local_government_office",
  "locksmith",
  "plumber",
  "real_estate_agency",
  "roofing_contractor",
  "accounting",
  "post_office",
  "fire_station",
  "police",
  "funeral_home",
  "cemetery",
  "hospital",
  "doctor",
  "dentist",
  "veterinary_care",
  "gas_station",
  "parking",
  "warehouse",
  "storage",
]);

const SUSPICIOUS_VENUE_NAME =
  /\b(storage|warehouse|u-?haul|self[\s-]?storage|industrial|wholesale|distribution|fulfillment|logistics|freight|depot|mini[\s-]?storage)\b/i;

const SCREENING_TYPES = ["movie_theater"];
const THEATER_TYPES = ["performing_arts_theater", "movie_theater"];
const NIGHTLIFE_TYPES = ["bar", "night_club", "restaurant"];
const LIVE_SHOW_TYPES = ["night_club", "bar", "performing_arts_theater", "stadium"];
const DINING_TYPES = ["restaurant", "food", "meal_takeaway", "bar", "cafe"];
const CAFE_TYPES = ["cafe", "bakery", "restaurant", "food"];
const OUTDOOR_TYPES = ["park", "natural_feature", "campground", "tourist_attraction"];
const MUSEUM_TYPES = ["museum", "art_gallery", "tourist_attraction"];
const SHOP_TYPES = ["store", "shopping_mall", "clothing_store", "book_store", "jewelry_store", "home_goods_store"];

/**
 * Venue-type words → Google types the place must have. Checked in order, so specific
 * activities (screenings) win over the venue words around them ("rooftop bar screening").
 */
const VENUE_TYPE_KEYWORDS: [string, string[]][] = [
  ["screening", SCREENING_TYPES],
  ["movie", SCREENING_TYPES],
  ["film", SCREENING_TYPES],
  ["cinema", SCREENING_TYPES],
  ["theater", THEATER_TYPES],
  ["theatre", THEATER_TYPES],
  ["comedy", LIVE_SHOW_TYPES],
  ["concert", LIVE_SHOW_TYPES],
  ["live music", LIVE_SHOW_TYPES],
  ["jazz", LIVE_SHOW_TYPES],
  ["bowling", ["bowling_alley"]],
  ["arcade", ["amusement_center"]],
  ["aquarium", ["aquarium"]],
  ["zoo", ["zoo"]],
  ["spa", ["spa"]],
  ["museum", MUSEUM_TYPES],
  ["gallery", ["art_gallery", "museum"]],
  ["book", ["book_store", "library"]],
  ["coffee", CAFE_TYPES],
  ["cafe", CAFE_TYPES],
  ["tea", CAFE_TYPES],
  ["bakery", ["bakery", "cafe"]],
  ["dessert", ["bakery", "cafe", "restaurant", "food", "store"]],
  ["ice cream", ["bakery", "cafe", "restaurant", "food", "store"]],
  ["gelato", ["bakery", "cafe", "restaurant", "food", "store"]],
  ["rooftop", ["bar", "restaurant", "night_club", "tourist_attraction"]],
  ["speakeasy", NIGHTLIFE_TYPES],
  ["cocktail", NIGHTLIFE_TYPES],
  ["wine", NIGHTLIFE_TYPES],
  ["brewery", NIGHTLIFE_TYPES],
  ["pub", NIGHTLIFE_TYPES],
  ["lounge", NIGHTLIFE_TYPES],
  ["bar", NIGHTLIFE_TYPES],
  ["restaurant", DINING_TYPES],
  ["dining", DINING_TYPES],
  ["dinner", DINING_TYPES],
  ["brunch", DINING_TYPES],
  ["lunch", DINING_TYPES],
  ["bistro", DINING_TYPES],
  ["park", OUTDOOR_TYPES],
  ["garden", OUTDOOR_TYPES],
  ["stroll", OUTDOOR_TYPES],
  ["walk", OUTDOOR_TYPES],
  ["hike", OUTDOOR_TYPES],
  ["picnic", OUTDOOR_TYPES],
  ["beach", OUTDOOR_TYPES],
  ["sunset", OUTDOOR_TYPES],
  ["market", [...SHOP_TYPES, "supermarket", "tourist_attraction"]],
  ["shop", SHOP_TYPES],
  ["boutique", SHOP_TYPES],
];

/** For venue types we don't recognize, the place must still be a real date venue. */
const DATE_FRIENDLY_TYPES = new Set([
  "restaurant", "cafe", "bar", "night_club", "bakery", "food", "meal_takeaway",
  "park", "natural_feature", "campground", "tourist_attraction", "museum", "art_gallery",
  "movie_theater", "performing_arts_theater", "bowling_alley", "amusement_center", "amusement_park",
  "aquarium", "zoo", "spa", "book_store", "library", "store", "shopping_mall", "stadium",
]);

function normalizeVenueTypeKey(venueType: string): string {
  return venueType.trim().toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ");
}

function expectedGoogleTypes(venueType: string): string[] | null {
  const key = normalizeVenueTypeKey(venueType);
  if (!key) return null;
  for (const [needle, types] of VENUE_TYPE_KEYWORDS) {
    if (new RegExp(`\\b${needle}`).test(key)) return types;
  }
  return null;
}

function hasDisallowedPlaceType(types: string[] | undefined): boolean {
  if (!types?.length) return false;
  return types.some((t) => DISALLOWED_PLACE_TYPES.has(t));
}

export function placeTypesMatchVenue(googleTypes: string[] | undefined, venueType: string): boolean {
  if (!googleTypes?.length) return true; // Can't verify — allow if nothing else failed
  if (hasDisallowedPlaceType(googleTypes)) return false;

  const expected = expectedGoogleTypes(venueType);
  if (!expected) return googleTypes.some((t) => DATE_FRIENDLY_TYPES.has(t));

  const typeSet = new Set(googleTypes);
  return expected.some((t) => typeSet.has(t));
}

/** Copy that promises a film screening only fits a place Google lists as a cinema. */
const SCREENING_COPY = /\b(movies?|films?|cinemas?|screenings?)\b/i;

export function copyMatchesPlaceTypes(
  stop: { name?: string; venueType?: string; description?: string },
  googleTypes: string[] | undefined,
): boolean {
  const copy = [stop.name, stop.venueType, stop.description].filter(Boolean).join(" ");
  if (SCREENING_COPY.test(copy)) {
    return (googleTypes ?? []).some((t) => SCREENING_TYPES.includes(t));
  }
  return true;
}

function tokenizeName(name: string): Set<string> {
  const stopWords = new Set(["the", "and", "bar", "restaurant", "cafe", "grill", "kitchen", "house"]);
  return new Set(
    name
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter((w) => w.length > 2 && !stopWords.has(w)),
  );
}

/** Shortest name allowed to match by containment (avoids "Bar" matching everything). */
const MIN_CONTAINED_NAME_LENGTH = 4;
/** Share of the AI name's distinctive words that must appear in Google's name. */
const MIN_NAME_TOKEN_OVERLAP = 0.75;

export function namesLikelyMatch(aiName: string, googleName: string): boolean {
  const aiLower = aiName.trim().toLowerCase();
  const googleLower = googleName.trim().toLowerCase();
  if (!aiLower || !googleLower) return false;

  const shorter = aiLower.length <= googleLower.length ? aiLower : googleLower;
  const longer = shorter === aiLower ? googleLower : aiLower;
  if (shorter.length >= MIN_CONTAINED_NAME_LENGTH && longer.includes(shorter)) return true;

  // Every distinctive word the AI used should be in the real name; a shared word like
  // "Rooftop" or "Starlight" is not enough to call two businesses the same place.
  const aiTokens = tokenizeName(aiName);
  const googleTokens = tokenizeName(googleName);
  if (aiTokens.size === 0) return false;

  let overlap = 0;
  for (const token of aiTokens) {
    if (googleTokens.has(token)) overlap++;
  }
  return overlap / aiTokens.size >= MIN_NAME_TOKEN_OVERLAP;
}

function hasSuspiciousVenueName(...names: string[]): boolean {
  return names.some((n) => n && SUSPICIOUS_VENUE_NAME.test(n));
}

interface Stop {
  order: number;
  name: string;
  venueType: string;
  timeSlot: string;
  duration: string;
  description: string;
  whyItFits: string;
  romanticTip: string;
  emoji: string;
  placeId?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  validated?: boolean;
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  /** Google's machine-readable hours, used to check the stop's time slot. */
  openingPeriods?: OpeningPeriod[];
  bookingUrl?: string;
  imageUrl?: string;
  /** Booking platforms this venue is confirmed to be on. */
  reservationPlatforms?: string[];
}

/** Detect reservation platforms from a restaurant's website URL or bookingUrl. */
function detectReservationPlatforms(websiteUrl?: string, bookingUrl?: string): string[] {
  const platforms: Set<string> = new Set();
  for (const url of [websiteUrl, bookingUrl]) {
    if (!url) continue;
    const lower = url.toLowerCase();
    if (lower.includes("opentable.com")) platforms.add("opentable");
    if (lower.includes("resy.com")) platforms.add("resy");
  }
  return Array.from(platforms);
}

// Extract state abbreviation from city string (e.g., "Newark, NJ" -> "NJ")
function extractStateFromCity(city: string): string | null {
  const match = city.match(/,\s*([A-Z]{2})$/i);
  return match ? match[1].toUpperCase() : null;
}

// Common city name variations (official name -> common names)
const cityNameVariations: Record<string, string[]> = {
  'bengaluru': ['bangalore', 'bengaluru'],
  'bangalore': ['bangalore', 'bengaluru'],
  'mumbai': ['mumbai', 'bombay'],
  'bombay': ['mumbai', 'bombay'],
  'chennai': ['chennai', 'madras'],
  'madras': ['chennai', 'madras'],
  'kolkata': ['kolkata', 'calcutta'],
  'calcutta': ['kolkata', 'calcutta'],
  'pune': ['pune', 'poona'],
  'thiruvananthapuram': ['thiruvananthapuram', 'trivandrum'],
  'kochi': ['kochi', 'cochin'],
  'varanasi': ['varanasi', 'benares', 'banaras'],
  'beijing': ['beijing', 'peking'],
  'guangzhou': ['guangzhou', 'canton'],
  'köln': ['köln', 'cologne'],
  'wien': ['wien', 'vienna'],
  'firenze': ['firenze', 'florence'],
  'roma': ['roma', 'rome'],
  'milano': ['milano', 'milan'],
  'napoli': ['napoli', 'naples'],
  'venezia': ['venezia', 'venice'],
  'münchen': ['münchen', 'munich'],
  'praha': ['praha', 'prague'],
  'moskva': ['moskva', 'moscow'],
};

/** Distance in km between two points (Haversine). */
function distanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/** Normalize city for matching: lowercase, trim. Returns also known variations for that city. */
function cityMatchTerms(city: string): string[] {
  const c = city.trim().toLowerCase();
  if (!c) return [];
  const terms = [c];
  for (const [key, vals] of Object.entries(cityNameVariations)) {
    if (key === c || vals.some((v) => v === c)) {
      vals.forEach((v) => terms.push(v));
      break;
    }
  }
  return [...new Set(terms)];
}

/** Verify the place is in the requested city: address contains city (or variation) and/or within maxDistanceKm of city center. */
function isAddressInLocation(
  address: string,
  city: string,
  venueLat?: number,
  venueLon?: number,
  cityCenterLat?: number,
  cityCenterLon?: number,
  maxDistanceKm: number = 150
): boolean {
  const terms = cityMatchTerms(city);
  const addrLower = (address || "").trim().toLowerCase();
  const addressContainsCity = terms.some((t) => addrLower.includes(t));
  if (addressContainsCity) {
    console.log(`[Places API] Address in location: "${address}" contains city "${city}"`);
    return true;
  }
  if (
    typeof venueLat === "number" &&
    typeof venueLon === "number" &&
    typeof cityCenterLat === "number" &&
    typeof cityCenterLon === "number" &&
    Number.isFinite(venueLat) &&
    Number.isFinite(venueLon) &&
    Number.isFinite(cityCenterLat) &&
    Number.isFinite(cityCenterLon)
  ) {
    const km = distanceKm(cityCenterLat, cityCenterLon, venueLat, venueLon);
    if (km <= maxDistanceKm) {
      console.log(`[Places API] Venue within ${km.toFixed(0)} km of city center for "${city}"`);
      return true;
    }
    console.log(`[Places API] WRONG LOCATION: Venue at (${venueLat},${venueLon}) is ${km.toFixed(0)} km from "${city}" center (max ${maxDistanceKm} km). Address: "${address}"`);
    return false;
  }
  if (address) {
    console.log(`[Places API] Cannot verify city (no center); trusting address: "${address}" for "${city}"`);
    return true;
  }
  return false;
}

// Get full state name from abbreviation
function getStateName(abbr: string): string {
  const states: Record<string, string> = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
    'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia',
    'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
    'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri',
    'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
    'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
    'DC': 'District of Columbia'
  };
  return states[abbr.toUpperCase()] || abbr;
}

/** Geocode an address string using Google Geocoding API. Returns formatted address and coordinates or null. */
export async function geocodeAddress(
  address: string,
  apiKey: string
): Promise<{ formatted_address: string; latitude: number; longitude: number } | null> {
  const trimmed = address?.trim();
  if (!trimmed || !apiKey) return null;

  try {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(trimmed)}&key=${apiKey}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
    let response: Response;
    try {
      response = await fetch(url, { signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
    if (!response.ok) return null;
    const data = await response.json();
    if (data.status !== "OK" || !data.results?.length) return null;
    const first = data.results[0];
    const formatted_address = first.formatted_address;
    const lat = first.geometry?.location?.lat;
    const lng = first.geometry?.location?.lng;
    if (typeof lat !== "number" || typeof lng !== "number") return null;
    return { formatted_address, latitude: lat, longitude: lng };
  } catch {
    return null;
  }
}

export type CityCenter = { latitude: number; longitude: number };

export async function validateVenue(
  venueName: string,
  city: string,
  apiKey: string,
  cityCenter?: CityCenter,
  venueType?: string,
): Promise<PlaceValidationResult> {
  // Input validation
  if (!venueName || typeof venueName !== 'string' || venueName.trim() === '') {
    console.error("[Places API] Invalid venue name provided");
    return { isValid: false };
  }
  
  if (!city || typeof city !== 'string' || city.trim() === '') {
    console.error("[Places API] Invalid city provided");
    return { isValid: false };
  }
  
  if (!apiKey || typeof apiKey !== 'string') {
    console.error("[Places API] Invalid API key");
    return { isValid: false };
  }

  try {
    // Step 1: Find the place (include name and business_status). Bias results to city area.
    const sanitizedVenue = venueName.trim().slice(0, 200); // Limit length
    const sanitizedCity = city.trim().slice(0, 100);
    const query = encodeURIComponent(`${sanitizedVenue} ${sanitizedCity}`);
    let findUrl = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${query}&inputtype=textquery&fields=place_id,name,formatted_address,geometry,business_status,types&key=${apiKey}`;
    if (cityCenter && Number.isFinite(cityCenter.latitude) && Number.isFinite(cityCenter.longitude)) {
      const radiusM = 50000; // 50 km - prefer results near the city
      findUrl += `&locationbias=circle:${radiusM}@${cityCenter.latitude},${cityCenter.longitude}`;
      console.log(`[Places API] Using location bias: circle ${radiusM}m around city center`);
    }
    console.log(`[Places API] Finding venue: ${sanitizedVenue} in ${sanitizedCity}`);
    
    // Add timeout to prevent hanging requests
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
    
    let findResponse;
    try {
      findResponse = await fetch(findUrl, { signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
    
    if (!findResponse.ok) {
      console.error("[Places API] Find error:", findResponse.status);
      return { isValid: false };
    }

    const findData = await findResponse.json();
    console.log(`[Places API] Find response status: ${findData.status}`);
    
    if (findData.status !== "OK" || !findData.candidates?.length) {
      console.log(`[Places API] No candidates found for: ${venueName}`);
      return { isValid: false, rejectReason: "not_found" };
    }

    for (const candidate of findData.candidates.slice(0, 3)) {
      const place = candidate;
      const placeId = place.place_id;
      const officialName = place.name;
      const formattedAddress = place.formatted_address;
      const businessStatus = place.business_status;
      const candidateTypes: string[] = Array.isArray(place.types) ? place.types : [];
      const placeLat = place.geometry?.location?.lat;
      const placeLon = place.geometry?.location?.lng;
      console.log(`[Places API] Candidate: "${officialName}" at "${formattedAddress}" (searched: "${venueName}"), types: ${candidateTypes.join(",")}`);

      if (hasSuspiciousVenueName(venueName, officialName)) {
        console.log(`[Places API] Rejected suspicious name: "${officialName}"`);
        continue;
      }

      if (businessStatus === "CLOSED_PERMANENTLY") {
        console.log(`[Places API] Venue is PERMANENTLY CLOSED: ${officialName}`);
        continue;
      }
      if (businessStatus === "CLOSED_TEMPORARILY") {
        console.log(`[Places API] Venue is TEMPORARILY CLOSED: ${officialName}`);
        continue;
      }

      if (hasDisallowedPlaceType(candidateTypes)) {
        console.log(`[Places API] Rejected disallowed types for "${officialName}": ${candidateTypes.join(",")}`);
        continue;
      }

      if (venueType && !placeTypesMatchVenue(candidateTypes, venueType)) {
        console.log(`[Places API] Types mismatch for "${officialName}" vs venueType "${venueType}"`);
        continue;
      }

      if (!namesLikelyMatch(venueName, officialName)) {
        console.log(`[Places API] Name mismatch: searched "${venueName}" vs Google "${officialName}"`);
        continue;
      }

      const inLocation = isAddressInLocation(
        formattedAddress,
        city,
        placeLat,
        placeLon,
        cityCenter?.latitude,
        cityCenter?.longitude,
        150,
      );
      if (!inLocation) {
        console.log(`[Places API] WRONG LOCATION! Venue "${officialName}" at "${formattedAddress}" is not in "${city}"`);
        continue;
      }

      const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,photos,types,formatted_address,geometry&key=${apiKey}`;

      const detailsResponse = await fetch(detailsUrl);
      let websiteUrl: string | undefined;
      let phoneNumber: string | undefined;
      let openingHours: string[] | undefined;
      let openingPeriods: OpeningPeriod[] | undefined;
      let imageUrl: string | undefined;
      let confirmedName = officialName;
      let googleTypes = candidateTypes;

      if (detailsResponse.ok) {
        const detailsData = await detailsResponse.json();
        console.log(`[Places API] Details response status: ${detailsData.status}`);
        if (detailsData.status === "OK" && detailsData.result) {
          if (detailsData.result.business_status === "CLOSED_PERMANENTLY") {
            console.log(`[Places API] Venue confirmed PERMANENTLY CLOSED from details: ${venueName}`);
            continue;
          }
          if (detailsData.result.business_status === "CLOSED_TEMPORARILY") {
            console.log(`[Places API] Venue confirmed TEMPORARILY CLOSED from details: ${venueName}`);
            continue;
          }

          if (detailsData.result.name) {
            confirmedName = detailsData.result.name;
          }

          googleTypes = Array.isArray(detailsData.result.types) ? detailsData.result.types : googleTypes;
          if (hasDisallowedPlaceType(googleTypes)) {
            console.log(`[Places API] Details rejected disallowed types for "${confirmedName}"`);
            continue;
          }
          if (venueType && !placeTypesMatchVenue(googleTypes, venueType)) {
            console.log(`[Places API] Details types mismatch for "${confirmedName}" vs "${venueType}"`);
            continue;
          }
          if (hasSuspiciousVenueName(confirmedName)) {
            console.log(`[Places API] Details rejected suspicious name: "${confirmedName}"`);
            continue;
          }
          if (!namesLikelyMatch(venueName, confirmedName)) {
            console.log(`[Places API] Details name mismatch: "${venueName}" vs "${confirmedName}"`);
            continue;
          }

          websiteUrl = detailsData.result.website;
          phoneNumber = detailsData.result.formatted_phone_number;
          openingHours = detailsData.result.opening_hours?.weekday_text;
          openingPeriods = detailsData.result.opening_hours?.periods;
          const photos = detailsData.result.photos;
          if (Array.isArray(photos) && photos.length > 0 && photos[0].photo_reference) {
            const ref = encodeURIComponent(photos[0].photo_reference);
            imageUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${ref}&key=${apiKey}`;
            console.log(`[Places API] Photo URL set for "${confirmedName}"`);
          }
          console.log(`[Places API] Details for "${confirmedName}": website=${websiteUrl}, phone=${phoneNumber}, hours=${openingHours?.length || 0} entries, photo=${!!imageUrl}`);
        }
      } else {
        console.error("[Places API] Details fetch failed:", detailsResponse.status);
      }

      const reservationPlatforms = detectReservationPlatforms(websiteUrl);

      return {
        isValid: true,
        officialName: confirmedName,
        placeId: placeId,
        formattedAddress: place.formatted_address,
        latitude: place.geometry?.location?.lat,
        longitude: place.geometry?.location?.lng,
        websiteUrl,
        phoneNumber,
        openingHours,
        openingPeriods,
        businessStatus,
        googleTypes,
        imageUrl,
        reservationPlatforms: reservationPlatforms.length > 0 ? reservationPlatforms : undefined,
      };
    }

    console.log(`[Places API] All candidates rejected for: ${venueName}`);
    return { isValid: false, rejectReason: "failed_validation" };
  } catch (error) {
    console.error("[Places API] Error validating venue:", error);
    return { isValid: false };
  }
}

// Helper function to delay execution
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Validate venue with retry logic. An unfound venue is dropped, never substituted.
async function validateVenueWithRetry(
  venueName: string,
  venueType: string,
  city: string,
  apiKey: string,
  cityCenter?: CityCenter,
  maxRetries = 2
): Promise<PlaceValidationResult> {
  let lastError: Error | null = null;
  
  // First, try to find the specific venue
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      if (attempt > 0) {
        await delay(500 * attempt);
        console.log(`[Places API] Retry attempt ${attempt} for: ${venueName}`);
      }
      
      const result = await validateVenue(venueName, city, apiKey, cityCenter, venueType);
      if (result.isValid) {
        return result;
      }
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.error(`[Places API] Attempt ${attempt + 1} failed for ${venueName}:`, lastError.message);
    }
  }
  
  // No substitution: a stand-in business would inherit copy written for a different venue.
  console.error(`[Places API] All attempts exhausted for: ${venueName}`);
  return { isValid: false };
}

export async function validateAllStops(
  stops: Stop[],
  city: string,
  apiKey: string
): Promise<Stop[]> {
  // Input validation
  if (!Array.isArray(stops)) {
    console.error("[Validation] Invalid stops array");
    return [];
  }
  
  if (!city || !apiKey) {
    console.error("[Validation] Missing city or API key — cannot verify venues");
    return [];
  }

  // Geocode city once so we can bias and verify all venues are in the right place (avoid e.g. Dubai when user asked Chennai)
  let cityCenter: CityCenter | undefined;
  try {
    const geo = await geocodeAddress(city.trim().slice(0, 200), apiKey);
    if (geo) {
      cityCenter = { latitude: geo.latitude, longitude: geo.longitude };
      console.log(`[Validation] City center for "${city}": ${geo.latitude}, ${geo.longitude}`);
    }
  } catch (e) {
    console.warn("[Validation] Could not geocode city for location bias:", e);
  }

  // Validate all stops concurrently with a cap of 4 in-flight Google Places requests.
  const CONCURRENCY = 4;
  const validStops = stops.filter(
    (s) => s && s.name && typeof s.name === "string"
  );
  const skipped = stops.length - validStops.length;
  if (skipped > 0) console.warn(`[Validation] Skipped ${skipped} stops with invalid names`);

  async function validateOne(stop: Stop): Promise<Stop | null> {
    const { imageUrl: _aiImageUrl, ...stopWithoutAiImage } = stop;
    try {
      const result = await validateVenueWithRetry(
        stop.name,
        stop.venueType || "",
        city,
        apiKey,
        cityCenter,
      );

      if (result.isPermanentlyClosed || result.isTemporarilyClosed) {
        console.log(`[Validation] Excluding closed venue: ${stop.name}`);
        return null;
      }
      if (!result.isValid) {
        console.log(`[Validation] Excluding unverified venue (failed triple-check): ${stop.name}`);
        return null;
      }
      if (!copyMatchesPlaceTypes(stop, result.googleTypes)) {
        console.log(`[Validation] Excluding venue whose copy doesn't fit the place: ${stop.name} (${result.googleTypes?.join(",")})`);
        return null;
      }

      const originalName = stop.name;
      const updatedName = result.officialName || stop.name;
      if (originalName !== updatedName) {
        console.log(`[Validation] Updated venue name: "${originalName}" → "${updatedName}"`);
      }

      const mergedPlatforms = (() => {
        const fromPlaces = result.reservationPlatforms ?? [];
        const fromAi = stop.reservationPlatforms ?? [];
        const fromBooking = detectReservationPlatforms(stop.bookingUrl);
        const combined = new Set([...fromPlaces, ...fromBooking, ...fromAi]);
        return combined.size > 0 ? Array.from(combined) : undefined;
      })();

      return {
        ...stopWithoutAiImage,
        name: updatedName,
        validated: true,
        placeId: result.placeId,
        address: result.formattedAddress,
        latitude: result.latitude,
        longitude: result.longitude,
        websiteUrl: result.websiteUrl ?? stop.websiteUrl,
        phoneNumber: result.phoneNumber ?? stop.phoneNumber,
        openingHours: result.openingHours ?? stop.openingHours,
        openingPeriods: result.openingPeriods,
        imageUrl: result.imageUrl,
        reservationPlatforms: mergedPlatforms,
      };
    } catch (err) {
      console.error(`[Validation] Unexpected error validating ${stop.name}:`, err);
      return null;
    }
  }

  // Process in batches to respect CONCURRENCY limit without losing ordering context.
  const resultSlots: (Stop | null)[] = [];
  for (let i = 0; i < validStops.length; i += CONCURRENCY) {
    const batch = validStops.slice(i, i + CONCURRENCY);
    const batchResults = await Promise.all(batch.map(validateOne));
    resultSlots.push(...batchResults);
  }

  const validatedStops: Stop[] = resultSlots.filter((s): s is Stop => s !== null);

  console.log(`[Validation] Kept ${validatedStops.length}/${stops.length} validated venues`);
  
  // Re-number the stops after filtering
  return validatedStops.map((stop, index) => ({
    ...stop,
    order: index + 1,
  }));
}
